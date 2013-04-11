/*
 Copyright 2010 Microsoft Corp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "WATweetBlobHandler.h"
#import "WABlobTweet.h"
#import "WABitlyHandler.h"
#import "WABitlyCredential.h"
#import "WABitlyResponse.h"

@implementation WATweetBlobHandler

-(void)postImageToBlob:(WABlobTweet *)blobTweet withAuthenticationCredential:(WAAuthenticationCredential *)authenticationCredential bitylyHandler:(WABitlyCredential *)bitlyCredential usingCompletionHandler:(WATweetBlobResponseHandler)block
{
    WACloudStorageClient *addContainerClient = [WACloudStorageClient storageClientWithCredential:authenticationCredential];
    
    WABlobContainer *containerToAdd = [[WABlobContainer alloc] initContainerWithName:blobTweet.containerName];
    containerToAdd.isPublic = blobTweet.makeContainerPublic;
    containerToAdd.createIfNotExists = YES;
    [addContainerClient addBlobContainer:containerToAdd withCompletionHandler:^(NSError *error) {
        if (error != nil) {
            // check to see that the blob is not already created. This only matters in a direct connection scenario
            NSString *code = [[error userInfo] objectForKey:WAErrorReasonCodeKey];
            if ([code isEqualToString:@"ContainerAlreadyExists"] == NO) {
                block(error);
                return;
            }
        }
        
        WACloudStorageClient *fetchContainerClient = [WACloudStorageClient storageClientWithCredential:authenticationCredential];
        [fetchContainerClient fetchBlobContainerNamed:containerToAdd.name withCompletionHandler:^(WABlobContainer *container, NSError *error) {
            if (error != nil) {
                block(error);
                return;
            }
            
            WABlob *blob = [[WABlob alloc] initBlobWithName:blobTweet.blobName  URL:nil containerName:container.name];
            blob.contentType = @"image/jpeg";
            blob.contentData = UIImageJPEGRepresentation(blobTweet.image, 1.0); 
            if (blobTweet.includeLocationData) {
                [blob setValue:blobTweet.bingLocation forMetadataKey:@"ContentLocation"];
            }
            [blob setValue:@"image/jpeg" forMetadataKey:@"ImageType"];
            WACloudStorageClient *addBlobClient = [WACloudStorageClient storageClientWithCredential:authenticationCredential];
            [addBlobClient addBlob:blob toContainer:container withCompletionHandler:^(NSError *error) {
                if (error != nil) {
                    block(error);
                    return;
                }
                
                WABlobFetchRequest *request = [WABlobFetchRequest fetchRequestWithContainer:container resultContinuation:nil];
                request.prefix = blob.name;
                WACloudStorageClient *fetchBlobClient = [WACloudStorageClient storageClientWithCredential:authenticationCredential];
                [fetchBlobClient fetchBlobsWithRequest:request usingCompletionHandler:^(NSArray *blobs, WAResultContinuation *resultContinuation, NSError *error){
                    if (error != nil) {
                        block(error);
                        return;
                    }
                    WABlob *blobToShorten = [blobs objectAtIndex:0];
                    WABitlyHandler *bitlyHandler = [[WABitlyHandler alloc] initWithLongURL:blobToShorten.URL username:bitlyCredential.login apiKey:bitlyCredential.apiKey];
                    [bitlyHandler shortenUrlWithCompletionHandler:^(WABitlyResponse *response, NSError *error) {
                        if (error != nil) {
                            [bitlyCredential clear];
                            block(error);
                            return;
                        }
                        
                        blobTweet.shortUrl = response.shortURL;
                        block(nil);
                    }];
                    
                }];
            }];
        }];
    }];
}

@end

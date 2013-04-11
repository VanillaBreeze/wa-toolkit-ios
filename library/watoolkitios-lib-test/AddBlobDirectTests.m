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

#import "AddBlobDirectTests.h"
#import "WAToolkit.h"

@implementation AddBlobDirectTests

#ifdef INTEGRATION_DIRECT

- (void)setUp
{
    [super setUp];
    
    WABlobContainer *container = [[[WABlobContainer alloc] initContainerWithName:randomContainerNameString] autorelease];
    [directClient addBlobContainer:container withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addBlobContainer: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
}

- (void)tearDown
{
    WABlobContainer *container = [[[WABlobContainer alloc] initContainerWithName:randomContainerNameString] autorelease];
    [directClient deleteBlobContainer:container withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from deleteBlobContainerNamed: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    [super tearDown];
}

-(void)testShouldAddBlobWithCompletionHandler
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"cloud" ofType:@"jpg"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    __block WABlobContainer *mycontainer;
    [directClient fetchBlobContainerNamed:randomContainerNameString withCompletionHandler:^(WABlobContainer *container, NSError *error) {
        [directDelegate markAsComplete];
        WABlob *blob = [[[WABlob alloc] initBlobWithName:@"cloud.jpg" URL:nil] autorelease];
        blob.contentType = @"image/jpeg";
        blob.contentData = data;
        [directClient addBlob:blob toContainer:container withCompletionHandler:^(NSError *error) {
            mycontainer = [container retain];
            STAssertNil(error, @"Error returned by addBlobToContainer: %@", [error localizedDescription]);
            [directDelegate markAsComplete];
        }];
        [directDelegate waitForResponse];
    }];
    [directDelegate waitForResponse];
    
    
    WABlobFetchRequest *fetchRequest = [WABlobFetchRequest fetchRequestWithContainer:mycontainer];
    [directClient fetchBlobsWithRequest:fetchRequest usingCompletionHandler:^(NSArray *blobs, WAResultContinuation *resultContinuation, NSError *error) {
        STAssertNil(error, @"Error returned by fetchBlobs: %@", [error localizedDescription]);
        STAssertTrue([blobs count] == 1, @"%i blobs were returned instead of 1",[blobs count]);         
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    [mycontainer release];
}

#endif

@end

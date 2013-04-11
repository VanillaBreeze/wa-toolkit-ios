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

#import "WABlobTweet.h"

static NSString * const kContainerName = @"containername";

@implementation WABlobTweet

@synthesize containerName = _containerName;
@synthesize blobName;
@synthesize shortUrl;
@synthesize image;
@synthesize includeLocationData;
@synthesize makeContainerPublic = _makeContainerPublic;
@synthesize location;

- (id)init 
{
    self = [super init];
    if (self) {
        _containerName = [[NSUserDefaults standardUserDefaults] valueForKey:kContainerName];
        _makeContainerPublic = YES;
    }
    return self;
}

- (NSString *)bingLocation
{
    if ([self validLocation]) {
        return [NSString stringWithFormat:@"http://www.bing.com/maps/?v=2&cp=%f~%f&lvl=16&dir=0&sty=h", self.location.latitude, self.location.longitude];
    }
    
    return nil;
}

- (void)setContainerName:(NSString *)contanerName
{
    _containerName = [contanerName copy];
    [[NSUserDefaults standardUserDefaults] setValue:_containerName forKey:kContainerName];
}

- (BOOL)isValid
{
    if (self.containerName.length == 0 || 
        self.blobName.length == 0 ||
        self.image == nil) {
        return NO;
    }
    return YES;
}

- (BOOL)validLocation
{
    return CLLocationCoordinate2DIsValid(self.location);
}

- (BOOL)isReadyToTweet
{
    return (self.shortUrl != nil);
}

- (void)clear
{
    self.blobName = nil;
    self.image = nil;
    self.shortUrl = nil;
}

@end

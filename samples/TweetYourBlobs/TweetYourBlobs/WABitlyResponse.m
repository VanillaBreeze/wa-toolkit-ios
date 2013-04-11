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

#import "WABitlyResponse.h"

@implementation WABitlyResponse

@synthesize longURL = _longURL;
@synthesize shortURL = _shortURL;
@synthesize responseData = _responseData;

- (id)init 
{
    return [self initWithShortUrl:nil longURL:nil responseData:nil];
}

- (id)initWithShortUrl:(NSURL *)shortURL longURL:(NSURL *)longURL responseData:(NSDictionary *)responseData 
{
    self = [super init];
    if (self) {
        _longURL = longURL;
        _shortURL = shortURL;
        _responseData = responseData;
    }
    return self;
}

@end

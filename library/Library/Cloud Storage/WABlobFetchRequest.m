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

#import "WABlobFetchRequest.h"
#import "WAResultContinuation.h"
#import "WABlobContainer.h"

@implementation WABlobFetchRequest

@synthesize container = _container;
@synthesize prefix = _prefix;
@synthesize resultContinuation = _resultContinuation;
@synthesize useFlatListing = _useFlatListing;
@synthesize maxResult = _maxResult;

- (id)initWithContainer:(WABlobContainer *)container resultContinuation:(WAResultContinuation *)resultContinuation
{
    if ((self = [super init])) {
        _container = [container retain];
        _resultContinuation = [resultContinuation retain];
    }
    
    return self;
}

- (void)dealloc 
{
    [_container release];
    [_prefix release];
    [_resultContinuation release];
    
    [super dealloc];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"BlobFetchRequest { container = %@, prefix = %@, resultContinuation = %@, useFlatListing = %c, maxResut = %u }", _container, _prefix, _resultContinuation, _useFlatListing, _maxResult];
}

+ (WABlobFetchRequest *)fetchRequestWithContainer:(WABlobContainer *)container;
{
    return [[[WABlobFetchRequest alloc] initWithContainer:container resultContinuation:nil] autorelease];
}

+ (WABlobFetchRequest *)fetchRequestWithContainer:(WABlobContainer *)container resultContinuation:(WAResultContinuation *)resultContinuation
{
    return [[[WABlobFetchRequest alloc] initWithContainer:container resultContinuation:resultContinuation] autorelease];
}
@end

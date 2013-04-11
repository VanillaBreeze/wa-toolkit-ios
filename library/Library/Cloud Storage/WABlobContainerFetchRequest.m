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

#import "WABlobContainerFetchRequest.h"

@implementation WABlobContainerFetchRequest

@synthesize containerName = _containerName;
@synthesize prefix = _prefix;
@synthesize resultContinuation = _resultContinuation;
@synthesize maxResult = _maxResult;

- (id)initWithResultContinuation:(WAResultContinuation *)resultContinuation
{
    if ((self = [super init])) {
        _resultContinuation = [resultContinuation retain];
    }
    
    return self;
}

- (void)dealloc 
{
    [_containerName release];
    [_prefix release];
    [_resultContinuation release];
    
    [super dealloc];
}

+ (WABlobContainerFetchRequest *)fetchRequest
{
    return [[[WABlobContainerFetchRequest alloc] initWithResultContinuation:nil] autorelease];
}

+ (WABlobContainerFetchRequest *)fetchRequestWithResultContinuation:(WAResultContinuation *)resultContinuation
{
    return [[[WABlobContainerFetchRequest alloc] initWithResultContinuation:resultContinuation] autorelease];
}


@end

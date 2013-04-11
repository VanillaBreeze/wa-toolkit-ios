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

#import "WAResultContinuation.h"

@interface WAResultContinuation()

- (id)initWithNextParitionKey:(NSString*)nextParitionKey nextRowKey:(NSString*)nextRowKey nextTableKey:(NSString*)nextTableKey nextMarker:(NSString *)nextMarker continuationType:(WAContinuationType)continuationType;

@end

@implementation WAResultContinuation

@synthesize nextRowKey = _nextRowKey;
@synthesize nextPartitionKey = _nextParitionKey;
@synthesize nextTableKey = _nextTableKey;
@synthesize nextMarker = _nextMarker;
@synthesize continuationType = _continuationType;

#pragma mark - Memory management

- (id)init
{
    return [self initWithNextParitionKey:nil nextRowKey:nil nextTableKey:nil nextMarker:nil continuationType:WAContinuationNone];
}

- (id)initWithNextParitionKey:(NSString*)nextParitionKey nextRowKey:(NSString*)nextRowKey nextTableKey:(NSString*)nextTableKey nextMarker:(NSString *)nextMarker continuationType:(WAContinuationType)continuationType;
{
    self = [super init];
    if (self) {
        _nextParitionKey = [nextParitionKey copy];
        _nextRowKey = [nextRowKey copy];
        _nextTableKey = [nextTableKey copy];
        _nextMarker = [nextMarker copy];
        _continuationType = continuationType;
    }
    return self;
}

- (id)initWithNextParitionKey:(NSString*)nextParitionKey nextRowKey:(NSString*)nextRowKey
{
    return [self initWithNextParitionKey:nextParitionKey nextRowKey:nextRowKey nextTableKey:nil nextMarker:nil continuationType:WAContinuationEntity];
}


- (id)initWithNextTableKey:(NSString*)nextTableKey
{
    return [self initWithNextParitionKey:nil nextRowKey:nil nextTableKey:nextTableKey nextMarker:nil continuationType:WAContinuationTable];
}

- (id)initWithContainerMarker:(NSString*)marker continuationType:(WAContinuationType)continuationType
{
    return [self initWithNextParitionKey:nil nextRowKey:nil nextTableKey:nil nextMarker:marker continuationType:continuationType];
}

- (void)dealloc 
{
    [_nextTableKey release];
    [_nextParitionKey release];
    [_nextRowKey release];
    [_nextMarker release];
    
    [super dealloc];
}

- (BOOL)hasContinuation
{
    if (self.nextPartitionKey == nil &&
        self.nextRowKey == nil) {
        return self.nextTableKey != nil;
    }
    return true;
}


@end

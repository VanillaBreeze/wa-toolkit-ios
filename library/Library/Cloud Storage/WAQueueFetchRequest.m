//
//  WAQueueFetchRequest.m
//  watoolkitios-lib
//
//  Created by Scott Densmore on 11/23/11.
//  Copyright 2011 Scott Densmore. All rights reserved.
//

#import "WAQueueFetchRequest.h"

@implementation WAQueueFetchRequest

@synthesize queueName = _queueName;
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
    [_queueName release];
    [_prefix release];
    [_resultContinuation release];
    
    [super dealloc];
}

+ (WAQueueFetchRequest *)fetchRequest
{
    return [[[WAQueueFetchRequest alloc] initWithResultContinuation:nil] autorelease];
}

+ (WAQueueFetchRequest *)fetchRequestWithResultContinuation:(WAResultContinuation *)resultContinuation
{
    return [[[WAQueueFetchRequest alloc] initWithResultContinuation:resultContinuation] autorelease];
}

@end

//
//  WAQueueMessageFetchRequest.m
//  watoolkitios-lib
//
//  Created by Scott Densmore on 11/23/11.
//  Copyright 2011 Scott Densmore. All rights reserved.
//

#import "WAQueueMessageFetchRequest.h"

@implementation WAQueueMessageFetchRequest

@synthesize queueName = _queueName;
@synthesize fetchCount = _fetchCount;
@synthesize visibilityTimeout = _visibilityTimeout;

- (id) initWithQueueName:(NSString *)queueName
{
    if ((self = [super init])) {
        _queueName = [queueName copy];
        _fetchCount = 1;
        _visibilityTimeout = 60;
    }
    
    return self;
}

- (void)dealloc 
{
    [_queueName release];
    
    [super dealloc];
}

+ (WAQueueMessageFetchRequest *)fetchRequestWithQueueName:(NSString *)queueName
{
    return [[[WAQueueMessageFetchRequest alloc] initWithQueueName:queueName] autorelease];
}
@end

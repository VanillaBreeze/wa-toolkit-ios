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

#import "DeleteQueueMessageDirectTests.h"
#import "WAToolkit.h"

@implementation DeleteQueueMessageDirectTests

#ifdef INTEGRATION_DIRECT

- (void)setUp
{
    [super setUp];
    
    [directClient addQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    [directClient addMessageToQueue:@"Hello" queueName:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
}

- (void)tearDown
{
    [directClient deleteQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    [_queueMessage release];
    
    [super tearDown];
}

-(void)testShouldDeleteQueueWithCompletionHandlerDirect
{       
    WAQueueMessageFetchRequest *fetchRequest = [WAQueueMessageFetchRequest fetchRequestWithQueueName:randomQueueNameString];
    [directClient fetchQueueMessagesWithRequest:fetchRequest usingCompletionHandler:^(NSArray *queueMessages, NSError *error) {
        __block BOOL foundQueue = NO;
        [queueMessages enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
            WAQueueMessage *queueMessage = (WAQueueMessage*)object;
            if ([queueMessage.messageText isEqualToString:@"Hello"]) {
                _queueMessage = [queueMessage retain];
                foundQueue = YES;
                *stop = YES;
            }
        }];
        STAssertTrue(foundQueue, @"Did not find the queue message that was just added.");
        
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    
    [directClient deleteQueueMessage:_queueMessage queueName:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    fetchRequest = [WAQueueMessageFetchRequest fetchRequestWithQueueName:randomQueueNameString];
    [directClient fetchQueueMessagesWithRequest:fetchRequest usingCompletionHandler:^(NSArray *queueMessages, NSError *error) {
        __block BOOL foundQueue = NO;
        [queueMessages enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
            WAQueueMessage *queueMessage = (WAQueueMessage*)object;
            if ([queueMessage.messageText isEqualToString:@"Hello"]) {
                _queueMessage = [queueMessage retain];
                foundQueue = YES;
                *stop = YES;
            }
        }];
        STAssertFalse(foundQueue, @"Should not find the queue message that was just added.");
        
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
}

#endif

@end

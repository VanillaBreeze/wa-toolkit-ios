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

#import "DeleteContainerProxyTests.h"
#import "WAToolkit.h"

@implementation DeleteContainerProxyTests

#ifdef INTEGRATION_PROXY

- (void)setUp
{
    [super setUp];
    WABlobContainer *container = [[[WABlobContainer alloc] initContainerWithName:randomContainerNameString] autorelease];
    [proxyClient addBlobContainer:container withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addBlobContainerNamed: %@",[error localizedDescription]);
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
}

- (void)tearDown
{
    [super tearDown];
}

-(void)testShouldDeleteQueueWithCompletionHandlerDirect
{       
    WABlobContainer *container = [[WABlobContainer alloc] initContainerWithName:randomContainerNameString];
    [proxyClient deleteBlobContainer:container withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from deleteBlobContainerNamed: %@",[error localizedDescription]);
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
    
    WABlobContainerFetchRequest *fetchRequest = [WABlobContainerFetchRequest fetchRequest];
    [proxyClient fetchBlobContainersWithRequest:fetchRequest usingCompletionHandler:^(NSArray *containers, WAResultContinuation *resultContinuation, NSError *error) {
        __block BOOL foundContainer = NO;
        [containers enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
            WABlobContainer *container = (WABlobContainer*)object;
            if ([container.name isEqualToString:randomContainerNameString]) {
                foundContainer = YES;
                *stop = YES;
            }
        }];
        STAssertFalse(foundContainer, @"Did not delete the container that was added.");
        
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
}

#endif

@end

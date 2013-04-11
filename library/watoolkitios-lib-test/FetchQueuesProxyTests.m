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

#import "FetchQueuesProxyTests.h"
#import "WAToolkit.h"

@implementation FetchQueuesProxyTests

#ifdef INTEGRATION_PROXY

- (void)setUp
{
    [super setUp];
    
    [proxyClient addQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
        [proxyDelegate markAsComplete];
        
    }];
    [proxyDelegate waitForResponse];
}

- (void)tearDown
{
    [proxyClient deleteQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
    
    [super tearDown];
}

-(void)testShouldFetchQueuesWithCompletionHandler
{
    WAQueueFetchRequest *fetchRequest = [WAQueueFetchRequest fetchRequest];
    [proxyClient fetchQueuesWithRequest:fetchRequest usingCompletionHandler:^(NSArray *queues, WAResultContinuation *resultContinuation, NSError *error) {
        STAssertNil(error, @"Error returned from fetchQueuesWithCompletionHandler: %@",[error localizedDescription]);
        STAssertTrue([queues count] > 0, @"No queues were found under this account");
        [proxyDelegate markAsComplete];
    }];
	
	[proxyDelegate waitForResponse];
}

#endif

@end

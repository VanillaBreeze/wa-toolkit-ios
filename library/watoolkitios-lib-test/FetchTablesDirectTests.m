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

#import "FetchTablesDirectTests.h"
#import "WAToolkit.h"

@implementation FetchTablesDirectTests

#ifdef INTEGRATION_DIRECT

- (void)setUp
{
    [super setUp];
    
    [directClient createTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testShouldFetchTablesWithContinuationUsingCompletionHandlerDirect
{
    [directClient fetchTablesWithContinuation:nil usingCompletionHandler:^(NSArray *tables, WAResultContinuation *resultContinuation, NSError *error) {
        STAssertNil(error, @"Error returned by fetchTablesWithContinuation: %@", [error localizedDescription]);
        STAssertNotNil(tables, @"fetchTablesWithContinuation: returned nil");
        STAssertTrue(tables.count > 0, @"fetchTablesWithContinuation: returned no tables");
        [directDelegate markAsComplete];
    }];
	
	[directDelegate waitForResponse];	
}

-(void)testShouldFetchTablesWithCompletionHandlerDirect
{   
    [directClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) {
        STAssertNil(error, @"Error returned by fetchTablesWithCompletionHandler: %@", [error localizedDescription]);
        STAssertNotNil(tables, @"fetchTablesWithCompletionHandler: returned nil");
        STAssertTrue(tables.count > 0, @"fetchTablesWithCompletionHandler: returned no tables");
        [directDelegate markAsComplete];
    }];
	
	[directDelegate waitForResponse];	
}

#endif

@end

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

#import "FetchEntityProxyTests.h"
#import "WAToolkit.h"

@implementation FetchEntityProxyTests

#ifdef INTEGRATION_PROXY

- (void)setUp
{
    [super setUp];
    
    [proxyClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
    
    WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
    [testEntity setObject:@"Steve" forKey:@"Name"];
    
    [proxyClient insertEntity:testEntity withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
}

- (void)tearDown
{
    [proxyClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
    
    [super tearDown];
}

-(void)testShouldFetchTableEntitiesWithCompletionHandler
{
    WATableFetchRequest *fetchRequest = [WATableFetchRequest fetchRequestForTable:randomTableNameString];
    [proxyClient fetchEntitiesWithRequest:fetchRequest usingCompletionHandler:^(NSArray *entities, WAResultContinuation *resultContinuation, NSError *error) {
        STAssertNil(error, @"Error returned by fetchEntities: %@", [error localizedDescription]);
        STAssertTrue([entities count] > 0, @"No entities were found under this account");
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
}

-(void)testShouldFetchTableEntitiesUsingPredicateWithCompletionHandler
{   
    NSError *error = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Name = 'Steve' || Name = 'Eric' || Name = 'Ling'"];
    WATableFetchRequest* fetchRequest = [WATableFetchRequest fetchRequestForTable:randomTableNameString predicate:predicate error:&error];
	STAssertNil(error, @"Predicate parser error: %@", [error localizedDescription]);
    
    [proxyClient fetchEntitiesWithRequest:fetchRequest usingCompletionHandler:^(NSArray *entities, WAResultContinuation *resultContinuation, NSError *error) {
        STAssertNil(error, @"Error returned by fetchEntities: %@", [error localizedDescription]);
        STAssertNotNil(entities, @"fetchEntities returned nil");
        STAssertEquals(entities.count, (NSUInteger)1, @"fetchEntities returned incorrect number of entities");
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
}

#endif

@end

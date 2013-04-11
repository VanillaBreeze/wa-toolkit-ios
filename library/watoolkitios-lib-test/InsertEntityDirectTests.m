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

#import "InsertEntityDirectTests.h"
#import "WAToolkit.h"

@implementation InsertEntityDirectTests

#ifdef INTEGRATION_DIRECT

- (void)setUp
{
    [super setUp];
    
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
}

- (void)tearDown
{
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    [super tearDown];
}

- (void)testShouldInsertEntity
{
    WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
    
    [directClient insertEntity:testEntity withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    
    WATableFetchRequest *fetchRequest = [WATableFetchRequest fetchRequestForTable:randomTableNameString];
    [directClient fetchEntitiesWithRequest:fetchRequest usingCompletionHandler:^(NSArray *entities, WAResultContinuation *resultContinuation, NSError *error) {
        STAssertNil(error, @"Error returned by getEntities: %@", [error localizedDescription]);
        __block BOOL foundEntity = NO;
        [entities enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
            WATableEntity *table = (WATableEntity *)object;
            if ([table.partitionKey isEqualToString:@"a"] && [table.rowKey isEqualToString:@"01021972"]) {
                foundEntity = YES;
                *stop = YES;
            }
        }];
        STAssertTrue(foundEntity, @"Did not find entity that we just inserted.");
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
}

#endif

@end

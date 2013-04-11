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

#import "AddTableDirectTests.h"
#import "WAToolkit.h"

@implementation AddTableDirectTests

#ifdef INTEGRATION_DIRECT

- (void)setUp
{
    [super setUp];
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

-(void)testShouldCreateTableWithCompletionHandlerDirect
{   
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    [directClient fetchTablesWithCompletionHandler:^(NSArray *tables, NSError *error) {
        __block BOOL foundTable = NO;
        [tables enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
            NSString *table = (NSString *)object;
            if ([table isEqualToString:randomTableNameString]) {
                foundTable = YES;
                *stop = YES;
            }
        }];
        STAssertTrue(foundTable, @"Did not find the table that was just added.");
         
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
}

#endif

@end

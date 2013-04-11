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

#import "WATableFetchRequest.h"
#import "WAAzureFilterBuilder.h"
#import "WACloudURLRequest.h"
#import "NSString+URLEncode.h"
#import "WAResultContinuation.h"
#import "Logging.h"

@implementation WATableFetchRequest

@synthesize tableName = _tableName;
@synthesize partitionKey = _partitionKey;
@synthesize rowKey = _rowKey;
@synthesize filter = _filter;
@synthesize topRows = _topRows;
@synthesize resultContinuation = _resultContinuation;

- (id) initWithTable:(NSString *)tableName
{
    if ((self = [super init])) {
        _tableName = [tableName copy];
    }
    
    return self;
}

- (void)dealloc
{
    [_tableName release];
    [_partitionKey release];
    [_rowKey release];
    [_filter release];
    [_resultContinuation release];
    
    [super dealloc];
}


+ (WATableFetchRequest *)fetchRequestForTable:(NSString *)tableName
{
    return [[[WATableFetchRequest alloc] initWithTable:tableName] autorelease];
}

+ (WATableFetchRequest *)fetchRequestForTable:(NSString *)tableName predicate:(NSPredicate *)predicate error:(NSError **)error
{
    NSString *filter = [WAAzureFilterBuilder filterStringWithPredicate:predicate error:error];
    if (!filter) {
        return nil;
    }

	WA_BEGIN_LOGGING
		NSLog(@"Filter=%@", filter);
	WA_END_LOGGING
    
    WATableFetchRequest *request = [[[WATableFetchRequest alloc] initWithTable:tableName] autorelease];
    
    request.filter = filter;
    
    return request;
}

- (NSString *)endpoint
{
    NSMutableString *ep = [NSMutableString stringWithString:_tableName];
    
    if (_partitionKey || _rowKey) {
        if (_partitionKey && _rowKey) {
            [ep stringByAppendingFormat:@"(PartitionKey=\'%@\',RowKey=\'%@\')", [_partitionKey URLEncode], [_rowKey URLEncode]];
        } else if (_partitionKey) {
            [ep stringByAppendingFormat:@"(PartitionKey=\'%@\')", [_partitionKey URLEncode]];
        } else if (_rowKey) {
            return [ep stringByAppendingFormat:@"(RowKey=\'%@\')", [_rowKey URLEncode]];
        }
    } else {
        [ep appendString:@"()"];
    }
    
    if (_filter || _topRows || _resultContinuation) {
        [ep appendString:@"?"];
        if (_filter) {
            [ep appendFormat:@"$filter=%@", [_filter URLEncode]];
        }
        if (_topRows) {
            [ep appendFormat:@"$top=%d", _topRows];
        }
        if (_resultContinuation) {
            [ep appendFormat:@"&NextPartitionKey=%@&NextRowKey=%@", [_resultContinuation.nextPartitionKey URLEncode], [_resultContinuation.nextRowKey URLEncode]];
        }
    }
    
    WA_BEGIN_LOGGING
        NSLog(@"endpoint = %@", ep);
	WA_END_LOGGING
    
    return ep;
}


@end


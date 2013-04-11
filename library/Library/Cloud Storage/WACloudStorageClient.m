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

#import "WACloudStorageClient.h"
#import <CommonCrypto/CommonHMAC.h>
#import "WACloudStorageClientDelegate.h"
#import "WACloudURLRequest.h"
#import "WAContainerParser.h"
#import "WABlobParser.h"
#import "WABlob.h"
#import "WAAuthenticationCredential+Private.h"
#import "NSString+URLEncode.h"
#import "WAXMLHelper.h"
#import "WATableEntity.h"
#import "WAQueueParser.h"
#import "WAQueueMessageParser.h"
#import "WASimpleBase64.h"
#import "WAResultContinuation.h"
#import "WAAuthenticationCredential.h"
#import "WABlob.h"
#import "WABlobContainer.h"
#import "WATableEntity.h"
#import "WATableFetchRequest.h"
#import "WABlobFetchRequest.h"
#import "WABlobContainerFetchRequest.h"
#import "WAQueueFetchRequest.h"
#import "WAQueueMessageFetchRequest.h"
#import "WAQueueMessage.h"
#import "Logging.h"
#import "WAAtomPubEntry.h"

NSString * const WAErrorReasonCodeKey = @"AzureReasonCode";

void ignoreSSLErrorFor(NSString* host);

static NSString *CREATE_TABLE_REQUEST_STRING = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><entry xmlns:d=\"http://schemas.microsoft.com/ado/2007/08/dataservices\" xmlns:m=\"http://schemas.microsoft.com/ado/2007/08/dataservices/metadata\" xmlns=\"http://www.w3.org/2005/Atom\"><title /><updated>$UPDATEDDATE$</updated><author><name/></author><id/><content type=\"application/xml\"><m:properties><d:TableName>$TABLENAME$</d:TableName></m:properties></content></entry>";
static NSString *TABLE_INSERT_ENTITY_REQUEST_STRING = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><entry xmlns:d=\"http://schemas.microsoft.com/ado/2007/08/dataservices\" xmlns:m=\"http://schemas.microsoft.com/ado/2007/08/dataservices/metadata\" xmlns=\"http://www.w3.org/2005/Atom\"><title /><updated>$UPDATEDDATE$</updated><author><name /></author><id /><content type=\"application/xml\"><m:properties>$PROPERTIES$</m:properties></content></entry>";
static NSString *TABLE_UPDATE_ENTITY_REQUEST_STRING = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><entry xmlns:d=\"http://schemas.microsoft.com/ado/2007/08/dataservices\" xmlns:m=\"http://schemas.microsoft.com/ado/2007/08/dataservices/metadata\" xmlns=\"http://www.w3.org/2005/Atom\"><title /><updated>$UPDATEDDATE$</updated><author><name /></author><id>$ENTITYID$</id><content type=\"application/xml\"><m:properties>$PROPERTIES$</m:properties></content></entry>";

@interface WACloudStorageClient (Private)

- (void)privateGetQueueMessages:(WAQueueMessageFetchRequest *)fetchRequest useBlockError:(BOOL)useBlockError peekOnly:(BOOL)peekOnly withBlock:(void (^)(NSArray *, NSError *))block;
- (void)prepareTableRequest:(WACloudURLRequest*)request;

@end

@interface WATableEntity (Private)

- (id)initWithDictionary:(NSMutableDictionary*)dictionary fromTable:(NSString*)tableName;
- (NSString*)propertyString;
- (NSString*)endpoint;

@end

@interface WATableFetchRequest (Private)

- (NSString*)endpoint;

@end

@interface WABlob (Private)

- (void)setContainerName:(NSString *)containerName;

@end

@implementation WACloudStorageClient

@synthesize delegate = _delegate;

#pragma mark Creation

- (id)initWithCredential:(WAAuthenticationCredential *)credential
{
	if ((self = [super init])) {
		_credential = [credential retain];
	}
	
	return self;
}

+ (WACloudStorageClient *) storageClientWithCredential:(WAAuthenticationCredential *)credential
{
	return [[[self alloc] initWithCredential:credential] autorelease];
}

+ (void) ignoreSSLErrorFor:(NSString*)host
{
	ignoreSSLErrorFor(host);
}

- (void)prepareTableRequest:(WACloudURLRequest *)request
{
    [request setValue:@"2.0;NetFx" forHTTPHeaderField:@"MaxDataServiceVersion"];
    [request setValue:@"application/atom+xml,application/xml" forHTTPHeaderField:@"Accept"];
    [request setValue:@"NativeHost" forHTTPHeaderField:@"User-Agent"];
}

#pragma mark -
#pragma mark Queue API methods

- (void)fetchQueuesWithRequest:(WAQueueFetchRequest *)fetchRequest
{
    [self fetchQueuesWithRequest:fetchRequest usingCompletionHandler:nil];
}

- (void)fetchQueuesWithRequest:(WAQueueFetchRequest *)fetchRequest usingCompletionHandler:(void (^)(NSArray *queues, WAResultContinuation *resultContinuation, NSError *error))block
{
    NSMutableString *endpoint = [NSMutableString stringWithString:@"?comp=list"];
    if (fetchRequest.prefix != nil) {
        [endpoint appendFormat:@"&prefix=%@", fetchRequest.prefix];
    }
    if (fetchRequest.maxResult > 0) {
        [endpoint appendFormat:@"&maxresults=%d", fetchRequest.maxResult];
    }
    if (fetchRequest.resultContinuation.nextMarker != nil) {
        [endpoint appendFormat:@"&marker=%@", fetchRequest.resultContinuation.nextMarker];
    }
        
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue", nil];
    
    [request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
        if (error) {
            if (block) {
                block(nil, nil, error);
            } else if ([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
        
        NSArray* queues = [WAQueueParser loadQueues:doc];
        NSString *marker = [WAContainerParser retrieveMarker:doc];
        WAResultContinuation *continuation = [[[WAResultContinuation alloc] initWithContainerMarker:marker continuationType:WAContinuationBlob] autorelease];
        
        if (block) {
            block(queues, continuation, nil);
        } else if ([_delegate respondsToSelector:@selector(storageClient:didFetchQueues:withResultContinuation:)]) {
            [_delegate storageClient:self didFetchQueues:queues withResultContinuation:continuation];
        }
    }];
}

- (void)addQueueNamed:(NSString *)queueName
{
    [self addQueueNamed:queueName withCompletionHandler:nil];
}

- (void)addQueueNamed:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block
{
    queueName = [queueName lowercaseString];
    NSString* endpoint = [NSString stringWithFormat:@"/%@", [queueName URLEncode]];
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue" httpMethod:@"PUT" contentData:[NSData data] contentType:nil, nil];
    
    
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error) {
        if (error) {
            if(block) {
                block(error);
            } else if ([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
         }
         
         if (block) {
            block(nil);
         } else if ([_delegate respondsToSelector:@selector(storageClient:didAddQueueNamed:)]) {
             [_delegate storageClient:self didAddQueueNamed:queueName];
         }
    }];
}

- (void)deleteQueueNamed:(NSString *)queueName
{
    [self deleteQueueNamed:queueName withCompletionHandler:nil];
}

- (void)deleteQueueNamed:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block
{
    queueName = [queueName lowercaseString];
    NSString* endpoint = [NSString stringWithFormat:@"/%@", [queueName URLEncode]];
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue" httpMethod:@"DELETE" contentData:[NSData data] contentType:nil, nil];
    
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
        if (error) {
            if (block) {
                block(error);
            } else if ([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
         }
         
         if (block) {
             block(nil);
         } else if ([_delegate respondsToSelector:@selector(storageClient:didDeleteQueueNamed:)]) {
             [_delegate storageClient:self didDeleteQueueNamed:queueName];
         }
    }];
}

- (void)fetchQueueMessage:(NSString *)queueName
{
    [self fetchQueueMessage:queueName withCompletionHandler:nil];
}

- (void)fetchQueueMessage:(NSString *)queueName withCompletionHandler:(void (^)(WAQueueMessage *, NSError *))block
{
    WAQueueMessageFetchRequest *fetchRequest = [WAQueueMessageFetchRequest fetchRequestWithQueueName:queueName];
    fetchRequest.fetchCount = 1;
	[self privateGetQueueMessages:fetchRequest useBlockError:!!block peekOnly:NO withBlock:^(NSArray *items, NSError *error) {
        if (error) {
            if (block) {
                block(nil, error);
			} else if ([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
				[_delegate storageClient:self didFailRequest:nil withError:error];
			}
			return;
		}
		
		if (block) {
			if (items.count >= 1) {
				block([items objectAtIndex:0], nil);
			} else {
				block(nil, nil);
			}
		} else if (![_delegate respondsToSelector:@selector(storageClient:didFetchQueueMessage:)]) {
			if(items.count >= 1) {
				[_delegate storageClient:self didFetchQueueMessage:[items objectAtIndex:0]];
			} else {
				[_delegate storageClient:self didFetchQueueMessage:nil];
			}
		}
    }];
}

- (void)fetchQueueMessagesWithRequest:(WAQueueMessageFetchRequest *)fetchRequest
{
    [self fetchQueueMessagesWithRequest:fetchRequest usingCompletionHandler:nil];
}


- (void)fetchQueueMessagesWithRequest:(WAQueueMessageFetchRequest *)fetchRequest usingCompletionHandler:(void (^)(NSArray *messages, NSError *error))block
{
    [self privateGetQueueMessages:fetchRequest useBlockError:!!block peekOnly:NO withBlock:^(NSArray *items, NSError *error) {
        if (error) {
            if (block) {
                block(nil, error);
            } else if ([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:nil withError:error];
            }
            return;
        }
        
        if (block) {
            block(items, nil);
        } else if ([_delegate respondsToSelector:@selector(storageClient:didFetchQueueMessages:)]) {
            [_delegate storageClient:self didFetchQueueMessages:items];
        }
    }];
}

- (void)peekQueueMessage:(NSString *)queueName
{
    [self peekQueueMessage:queueName withCompletionHandler:nil];
}

- (void)peekQueueMessage:(NSString *)queueName withCompletionHandler:(void (^)(WAQueueMessage *, NSError *))block
{
    WAQueueMessageFetchRequest *fetchRequest = [WAQueueMessageFetchRequest fetchRequestWithQueueName:queueName];
    fetchRequest.fetchCount = 1;
	[self privateGetQueueMessages:fetchRequest useBlockError:!!block peekOnly:YES withBlock:^(NSArray  *items, NSError *error) {
        if (error) {
            if (block) {
                block(nil, error);
            } else if ([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:nil withError:error];
            }
            return;
        }
		 
        if (block) {
            if (items.count >= 1) {
                block([items objectAtIndex:0], nil);
            } else {
                block(nil, nil);
            }
		 } else if (![_delegate respondsToSelector:@selector(storageClient:didPeekQueueMessage:)]) {
            if (items.count >= 1) {
                [_delegate storageClient:self didPeekQueueMessage:[items objectAtIndex:0]];
            } else {
                [_delegate storageClient:self didPeekQueueMessage:nil];
            }
        }
    }];
}

- (void)peekQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount
{
    WAQueueMessageFetchRequest *fetchRequest = [WAQueueMessageFetchRequest fetchRequestWithQueueName:queueName];
    fetchRequest.fetchCount = fetchCount;
	[self privateGetQueueMessages:fetchRequest useBlockError:NO peekOnly:YES withBlock:^(NSArray *items, NSError *error) {
        if (![_delegate respondsToSelector:@selector(storageClient:didPeekQueueMessages:)]) {
            return;
        }
		 
        [_delegate storageClient:self didPeekQueueMessages:items];
    }];
}

- (void)peekQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount withCompletionHandler:(void (^)(NSArray *, NSError *))block
{
    WAQueueMessageFetchRequest *fetchRequest = [WAQueueMessageFetchRequest fetchRequestWithQueueName:queueName];
    fetchRequest.fetchCount = fetchCount;
    
	[self privateGetQueueMessages:fetchRequest useBlockError:!!block peekOnly:YES withBlock:^(NSArray *items, NSError *error) {
        if (error) {
            if  (block) {
                block(nil, error);
            } else if ([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:nil withError:error];
            }
            return;
        }
		 
        if (block) {
            block(items, nil);
        } else if (![_delegate respondsToSelector:@selector(storageClient:didPeekQueueMessages:)]) {
            [_delegate storageClient:self didPeekQueueMessages:items];
        }
    }];
}



- (void)deleteQueueMessage:(WAQueueMessage *)queueMessage queueName:(NSString *)queueName
{
    [self deleteQueueMessage:queueMessage queueName:queueName withCompletionHandler:nil];
}

- (void)deleteQueueMessage:(WAQueueMessage *)queueMessage queueName:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block
{
    queueName = [queueName lowercaseString];
    NSString *endpoint = [NSString stringWithFormat:@"/%@/messages/%@?popreceipt=%@", [queueName URLEncode], queueMessage.messageId, queueMessage.popReceipt];
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue" httpMethod:@"DELETE" contentData:[NSData data] contentType:nil, nil];
    
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
        if (error) {
            if (block) {
                block(error);
            } else if ([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        if (block) {
            block(nil);
        } else if([_delegate respondsToSelector:@selector(storageClient:didDeleteQueueMessage:queueName:)]) {
            [_delegate storageClient:self didDeleteQueueMessage:queueMessage queueName:queueName];
        }
    }];
}

- (void)addMessageToQueue:(NSString *)message queueName:(NSString *)queueName
{
    [self addMessageToQueue:message queueName:queueName withCompletionHandler:nil];

}

- (void)addMessageToQueue:(NSString *)message queueName:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block
{
    NSString *endpoint = [NSString stringWithFormat:@"/%@/messages", [queueName URLEncode]];
    NSString *queueMsgStart = @"<QueueMessage><MessageText>";
	NSString *queueMsgEnd = @"</MessageText></QueueMessage>";
    NSMutableString *escapedString = [NSMutableString stringWithString:message];
    [escapedString replaceOccurrencesOfString:@"&"  withString:@"&amp;"  options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
    [escapedString replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
    [escapedString replaceOccurrencesOfString:@"'"  withString:@"&#39;" options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
    [escapedString replaceOccurrencesOfString:@">"  withString:@"&gt;"   options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
    [escapedString replaceOccurrencesOfString:@"<"  withString:@"&lt;"   options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	NSData *encodedData = [escapedString dataUsingEncoding:NSUTF8StringEncoding]; 
    NSString *encodedString = [encodedData stringWithBase64EncodedData];
	NSString *queueMsg = [NSString stringWithFormat:@"%@%@%@", queueMsgStart, encodedString, queueMsgEnd];
	NSData *contentData = [queueMsg dataUsingEncoding:NSUTF8StringEncoding];
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue" httpMethod:@"POST" contentData:contentData contentType:@"text/xml", nil];
    
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest *request, NSError *error) {
        if (error) {
            if (block) {
                block(error);
            } else if ([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        if (block) {
            block(nil);
        } else if ([_delegate respondsToSelector:@selector(storageClient:didAddMessageToQueue:queueName:)]) {
            [_delegate storageClient:self didAddMessageToQueue:message queueName:queueName];
        }
    }];
}

#pragma mark -
#pragma mark Blob API methods

- (void)fetchBlobContainersWithRequest:(WABlobContainerFetchRequest *)fetchRequest
{
    [self fetchBlobContainersWithRequest:fetchRequest usingCompletionHandler:nil];
}


- (void)fetchBlobContainersWithRequest:(WABlobContainerFetchRequest *)fetchRequest usingCompletionHandler:(void (^)(NSArray *containers, WAResultContinuation *resultContinuation, NSError *error))block
{
    WACloudURLRequest *request = nil;
    NSArray*(^containerBlock)(xmlDocPtr) = nil;
    
    if (_credential.usesProxy) {
        NSMutableString *endpoint = [NSMutableString stringWithString:@"/SharedAccessSignatureService/containers"];
        if (fetchRequest.prefix != nil) {
            [endpoint appendFormat:@"&containerPrefix=%@", fetchRequest.prefix];
        }
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob", nil];
        containerBlock = ^(xmlDocPtr doc) {
            return [WAContainerParser loadContainersForProxy:doc];
        };
    } else {
        NSMutableString *endpoint = [NSMutableString stringWithString:@"?comp=list&include=metadata"];
        if (fetchRequest.prefix != nil) {
            [endpoint appendFormat:@"&prefix=%@", fetchRequest.prefix];
        }
        if (fetchRequest.maxResult > 0) {
            [endpoint appendFormat:@"&maxresults=%d", fetchRequest.maxResult];
        }
        if (fetchRequest.resultContinuation.nextMarker != nil) {
            [endpoint appendFormat:@"&marker=%@", fetchRequest.resultContinuation.nextMarker];
        }
        
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob",
                   @"x-ms-blob-type", @"BlockBlob", nil];
        
        containerBlock = ^(xmlDocPtr doc) {
            return [WAContainerParser loadContainers:doc];
        };
    }
    
    [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error) {
        if (error) {
            if (block) {
                block(nil, nil, error);
            } else if ([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
        
        NSArray *containers = containerBlock(doc);
        NSString *marker = [WAContainerParser retrieveMarker:doc];
        WAResultContinuation *continuation = [[[WAResultContinuation alloc] initWithContainerMarker:marker continuationType:WAContinuationContainer] autorelease];
        
        if (block) {
            block(containers, continuation, nil);
        } else if ([_delegate respondsToSelector:@selector(storageClient:didFetchBlobContainers:withResultContinuation:)]) {
            [_delegate storageClient:self didFetchBlobContainers:containers withResultContinuation:continuation];
        }
    }];
}


- (void)fetchBlobContainerNamed:(NSString *)containerName 
{
    [self fetchBlobContainerNamed:containerName withCompletionHandler:nil];
}

- (void)fetchBlobContainerNamed:(NSString *)containerName withCompletionHandler:(void (^)(WABlobContainer *, NSError *))block
{
    WACloudURLRequest *request = nil;
    NSArray*(^containerBlock)(xmlDocPtr) = nil;
    
    if (_credential.usesProxy) {
        NSString *endpoint = [NSString stringWithFormat:@"/SharedAccessSignatureService/containers?containerPrefix=%@", [[containerName lowercaseString] URLEncode]];
        
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob", nil];
        containerBlock = ^(xmlDocPtr doc) {
            return [WAContainerParser loadContainersForProxy:doc];
        };
    } else {
        request = [_credential authenticatedRequestWithEndpoint:@"?comp=list&include=metadata" forStorageType:@"blob",
                                      @"x-ms-blob-type", @"BlockBlob", nil];
        containerBlock = ^(xmlDocPtr doc) {
            return [WAContainerParser loadContainers:doc];
        };
    }
    
    [request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
        if (error) {
            if (block) {
                block(nil, error);
            } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        NSArray *containers = containerBlock(doc);
        WABlobContainer *container = nil;
        for (WABlobContainer *tempContainer in containers) {
            if ([tempContainer.name isEqualToString:[containerName lowercaseString]]) {
                container = tempContainer;
                break;
            }
        }
         
        if (block) {
            block(container, nil);
        } else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobContainer:)]) {
            [_delegate storageClient:self didFetchBlobContainer:container];
        }   
    }];
}

- (BOOL)addBlobContainer:(WABlobContainer *)container
{
    return [self addBlobContainer:container withCompletionHandler:nil];
}

- (BOOL)addBlobContainer:(WABlobContainer *)container withCompletionHandler:(void (^)(NSError*))block
{
    WACloudURLRequest *request = nil;
    NSString *containerName = [[container.name lowercaseString] URLEncode];
    NSMutableString *endpoint = [NSMutableString string];
	if(_credential.usesProxy) {
        [endpoint appendFormat:@"/SharedAccessSignatureService/container/%@?createIfNotExists=%@&isPublic=%@", containerName, container.createIfNotExists ? @"true" : @"false", container.isPublic ? @"true" : @"false"];
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob" httpMethod:@"PUT" contentData:[NSData data] contentType:nil metadata:container.metadata, nil];
    } else {
        [endpoint appendFormat:@"/%@?restype=container", containerName];
        if (container.isPublic) {
            request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob" httpMethod:@"PUT" contentData:[NSData data] contentType:nil metadata:container.metadata, @"x-ms-blob-public-access", @"container", nil];
        } else {
            request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob" httpMethod:@"PUT" contentData:[NSData data] contentType:nil metadata:container.metadata, nil];
        }
    }
    
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error) {
        if (error) {
            if (block) {
                block(error);
            } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
        
        if (block) {
            block(nil);
        } else if([_delegate respondsToSelector:@selector(storageClient:didAddBlobContainer:)]) {
            [_delegate storageClient:self didAddBlobContainer:container];
        }
    }];
    
    return YES;
}

- (BOOL)deleteBlobContainer:(WABlobContainer *)container
{
    return [self deleteBlobContainer:container withCompletionHandler:nil];
}

- (BOOL)deleteBlobContainer:(WABlobContainer *)container withCompletionHandler:(void (^)(NSError *))block
{
    //return [self deleteBlobContainerNamed:container.name withCompletionHandler:block];
    WACloudURLRequest *request = nil;
    NSString *containerName = [[container.name lowercaseString] URLEncode];
    NSMutableString *endpoint = [NSMutableString string];
    
	if(_credential.usesProxy) {
        [endpoint appendFormat:@"/SharedAccessSignatureService/container/%@", containerName];
    } else {
        [endpoint appendFormat:@"/%@?restype=container", containerName];
    }
    
    request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob" httpMethod:@"DELETE" contentData:[NSData data] contentType:nil, nil];
    
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
        if (error) {
            if (block) {
                block(error);
            } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
        
        if (block) {
            block(nil);
        } else if([_delegate respondsToSelector:@selector(storageClient:didDeleteBlobContainerNamed:)]) {
            [_delegate storageClient:self didDeleteBlobContainerNamed:container.name];
        }
    }];
    
    return YES;
}

- (void)fetchBlobsWithRequest:(WABlobFetchRequest *)fetchRequest
{
    [self fetchBlobsWithRequest:fetchRequest usingCompletionHandler:nil];
}

- (void)fetchBlobsWithRequest:(WABlobFetchRequest *)fetchRequest usingCompletionHandler:(void (^)(NSArray *blobs, WAResultContinuation *resultContinuation, NSError *error))block
{
    WACloudURLRequest* request = nil;
    NSArray*(^blobBlock)(xmlDocPtr, WABlobContainer *) = nil;
    NSString *containerName = [[fetchRequest.container.name lowercaseString] URLEncode];
    if (_credential.usesProxy) {
        NSMutableString *endpoint = [NSMutableString stringWithFormat:@"/SharedAccessSignatureService/blob?containerName=%@", containerName];
        if (fetchRequest.useFlatListing == YES) {
            [endpoint appendString:@"&useFlatBlobListing=true"];
        }
        if (fetchRequest.prefix != nil) {
            [endpoint appendFormat:@"&blobPrefix=%@", fetchRequest.prefix];
        }
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob",
                   @"x-ms-blob-type", @"BlockBlob", nil];
        blobBlock = ^(xmlDocPtr doc, WABlobContainer *container) {
            return [WABlobParser loadBlobsForProxy:doc forContainerName:container.name];
        };
    } else {
        NSMutableString *endpoint = [NSMutableString stringWithFormat:@"/%@?comp=list&restype=container&include=metadata", containerName];
        if (fetchRequest.maxResult > 0) {
            [endpoint appendFormat:@"&maxresults=%d", fetchRequest.maxResult];
        }
        if (fetchRequest.useFlatListing == YES) {
            [endpoint appendString:@"delimiter=%2F"];
        }
        if (fetchRequest.prefix != nil) {
            [endpoint appendFormat:@"&prefix=%@", fetchRequest.prefix];
        }
        if (fetchRequest.resultContinuation.nextMarker != nil) {
            [endpoint appendFormat:@"&marker=%@", fetchRequest.resultContinuation.nextMarker];
        }
        
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob",
                   @"x-ms-blob-type", @"BlockBlob", nil];
        blobBlock = ^(xmlDocPtr doc, WABlobContainer *container) {
            return [WABlobParser loadBlobs:doc forContainerName:container.name];
        };
    }
    
    [request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
        if (error) {
            if (block) {
                block(nil, nil, error);
            } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
        
        NSArray *items = blobBlock(doc, fetchRequest.container);
        NSString *marker = [WAContainerParser retrieveMarker:doc];
        WAResultContinuation *continuation = [[[WAResultContinuation alloc] initWithContainerMarker:marker continuationType:WAContinuationBlob] autorelease];
        
        if (block) {
            block(items, continuation, nil);
        } else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobs:inContainer:withResultContinuation:)]) {
            [_delegate storageClient:self didFetchBlobs:items inContainer:fetchRequest.container withResultContinuation:continuation];
        }
    }];
}

- (void)fetchBlobData:(WABlob *)blob
{
    [self fetchBlobData:blob withCompletionHandler:nil];
}

- (void)fetchBlobData:(WABlob *)blob withCompletionHandler:(void (^)(NSData*, NSError*))block
{
    WACloudURLRequest *request;
	if (_credential.usesProxy) {
        NSString *endpoint = [NSString stringWithFormat:@"/SharedAccessSignatureService/blob?containerName=%@&blobPrefix=%@", [blob.containerName URLEncode], [blob.name URLEncode]]; 
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob", nil];

        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
            if (error) {
                if (block) {
                    block(nil, error);
                } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                    [_delegate storageClient:self didFailRequest:request withError:error];
                }
                return;
            }
			 
            NSArray *items = [WABlobParser loadBlobsForProxy:doc forContainerName:blob.containerName];
            WABlob *toBeDisplayedBlob = nil;
            for (WABlob *item in items) {
                if ([item.name isEqualToString:blob.name]) {
                    toBeDisplayedBlob = item;
                    break;
                }
            }
            NSString *endpoint = [NSString stringWithFormat:@"%@", toBeDisplayedBlob.URL];
            NSURL *serviceURL = [NSURL URLWithString:endpoint];
            WACloudURLRequest *blobRequest = [WACloudURLRequest requestWithURL:serviceURL];
            [blobRequest fetchDataWithCompletionHandler:^(WACloudURLRequest *request, NSData *data, NSError *error) {
                if (error) {
                    if (block) {
                        block(nil, error);
                    } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                        [_delegate storageClient:self didFailRequest:request withError:error];
                    }
                    return;
                }
                  
                if (block) {
                    block(data, nil);
                } else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobData:blob:)]) {
                    [_delegate storageClient:self didFetchBlobData:data blob:blob];
                }
            }];
        }];
    } else {
        NSString *endpoint = [NSString stringWithFormat:@"/%@/%@", blob.containerName, blob.name];
		request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob", nil];
        
        [request fetchDataWithCompletionHandler:^(WACloudURLRequest *request, NSData *data, NSError *error) {
            if (error) {
                if (block) {
                    block(nil, error);
                } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                    [_delegate storageClient:self didFailRequest:request withError:error];
                }
                return;
            }
             
            if (block) {
                block(data, nil);
            } else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobData:blob:)]) {
                [_delegate storageClient:self didFetchBlobData:data blob:blob];
            }
        }];
    }
}

- (BOOL)fetchBlobDataFromURL:(NSURL *)URL
{
    return [self fetchBlobDataFromURL:URL withCompletionHandler:nil];
}

- (BOOL)fetchBlobDataFromURL:(NSURL *)URL withCompletionHandler:(void (^)(NSData *data, NSError *error))block 
{   
    if (!_credential.usesProxy) {
        return NO;
    }
    
    WACloudURLRequest* blobRequest = [WACloudURLRequest requestWithURL:URL];
    [blobRequest fetchDataWithCompletionHandler:^(WACloudURLRequest *request, NSData *data, NSError *error) {
        if (error) {
            if (block) {
                block(nil, error);
            } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        if (block) {
            block(data, nil);
        } else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobData:URL:)]) {
            [_delegate storageClient:self didFetchBlobData:data URL:URL];
        }
    }];
    
    return YES;
}

- (void)addBlob:(WABlob *)blob toContainer:(WABlobContainer *)container
{
    [self addBlob:blob toContainer:container withCompletionHandler:nil];
}

- (void)addBlob:(WABlob *)blob toContainer:(WABlobContainer *)container withCompletionHandler:(void (^)(NSError *error))block
{
    WACloudURLRequest *request;
    if (_credential.usesProxy) {
        NSString *endpoint = [NSString stringWithFormat:@"/SharedAccessSignatureService/container/%@", [container.name URLEncode]];
		request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob", nil];
        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error) {
            if (error) {
                if (block) {
                    block(error);
                } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                    [_delegate storageClient:self didFailRequest:request withError:error];
                }
                return;
            }
            
            WABlobContainer *retrievedContainer = [WAContainerParser retrieveContainerWithSharedAccessSigniture:doc];
            NSString *endpoint = [NSString stringWithFormat:@"%@/%@?%@", retrievedContainer.URL, [blob.name URLEncode], retrievedContainer.sharedAccessSigniture];
            NSURL *serviceURL = [NSURL URLWithString:endpoint]; 
            WACloudURLRequest *blobRequest = [WACloudURLRequest requestWithURL:serviceURL];
            [blobRequest setHTTPMethod:@"PUT"];
            [blobRequest addValue:blob.contentType forHTTPHeaderField:@"Content-Type"];
            [blobRequest addValue:@"BlockBlob" forHTTPHeaderField:@"x-ms-blob-type"];
            [blobRequest setHTTPBody:blob.contentData];
            
            [blobRequest fetchNoResponseWithCompletionHandler:^(WACloudURLRequest *request, NSError *error) {
                if (error) {
                    if (block) {
                        block(error);
                    } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                        [_delegate storageClient:self didFailRequest:request withError:error];
                    }
                    return;
                }
                
                if (block) {
                    block(nil);
                } else if([_delegate respondsToSelector:@selector(storageClient:didAddBlob:toContainer:)]) {
                    [_delegate storageClient:self didAddBlob:blob toContainer:container];
                }
            }];
        }];
	} else {
        NSString *containerName = [container.name lowercaseString];
        NSString *endpoint = [NSString stringWithFormat:@"/%@/%@", [containerName URLEncode], [blob.name URLEncode]]; 
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob" httpMethod:@"PUT" contentData:blob.contentData contentType:blob.contentType metadata:blob.metadata, @"x-ms-blob-type", @"BlockBlob", nil];
        
        [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest *request, NSError *error) {
            if (error) {
                if (block) {
                    block(error);
                } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                    [_delegate storageClient:self didFailRequest:request withError:error];
                }
                return;
            }
            
            if (block) {
                block(nil);
            } else if([_delegate respondsToSelector:@selector(storageClient:didAddBlob:toContainer:)]) {
                [_delegate storageClient:self didAddBlob:blob toContainer:container];
            }
        }];
    }
}

- (void)deleteBlob:(WABlob *)blob 
{
    [self deleteBlob:blob withCompletionHandler:nil];
}

- (void)deleteBlob:(WABlob *)blob withCompletionHandler:(void (^)(NSError*))block
{
    WACloudURLRequest *request;
    if (_credential.usesProxy) {
        NSString *endpoint = [NSString stringWithFormat:@"/SharedAccessSignatureService/container/%@", [blob.containerName URLEncode]];
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob", nil];

        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
            if (error) {
                if (block) {
                    block(error);
                } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                    [_delegate storageClient:self didFailRequest:request withError:error];
                }
                return;
            }
             
            WABlobContainer *retrievedContainer = [WAContainerParser retrieveContainerWithSharedAccessSigniture:doc];
            NSString *endpoint = [NSString stringWithFormat:@"%@/%@?%@", retrievedContainer.URL, [blob.name URLEncode], retrievedContainer.sharedAccessSigniture];
            NSURL *serviceURL = [NSURL URLWithString:endpoint]; 
             
            WACloudURLRequest *blobRequest = [WACloudURLRequest requestWithURL:serviceURL];
            [blobRequest setHTTPMethod:@"DELETE"];
			 
            [blobRequest fetchNoResponseWithCompletionHandler:^(WACloudURLRequest *request, NSError *error) {
                if (error) {
                    if (block) {
                        block(error);
                    } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                        [_delegate storageClient:self didFailRequest:request withError:error];
                    }
                    return;
                }
                  
                if (block) {
                    block(nil);
                } else if([_delegate respondsToSelector:@selector(storageClient:didDeleteBlob:)]) {
                    [_delegate storageClient:self didDeleteBlob:blob];
                }
            }];
        }];
    } else {
        NSString *endpoint = [NSString stringWithFormat:@"/%@/%@", [blob.containerName URLEncode], [blob.name URLEncode]];
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob" httpMethod:@"DELETE" contentData:[NSData data] contentType:nil, nil];

        [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest *request, NSError *error) {
            if (error) {
                if (block) {
                    block(error);
                } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                    [_delegate storageClient:self didFailRequest:request withError:error];
                }
                return;
            }
             
            if (block) {
                block(nil);
            } else if([_delegate respondsToSelector:@selector(storageClient:didDeleteBlob:)]) {
                [_delegate storageClient:self didDeleteBlob:blob];
            }
        }];
    }
}

#pragma mark -
#pragma mark Table API methods

- (void)fetchTables
{
    [self fetchTablesWithCompletionHandler:nil];
}

- (void)fetchTablesWithCompletionHandler:(void (^)(NSArray *, NSError *))block
{
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:@"Tables" forStorageType:@"table" httpMethod:@"GET", nil];
    [self prepareTableRequest:request];
    
    [request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
        if (error) {
            if (block) {
                block(nil, error);
            } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        NSMutableArray *tables = [NSMutableArray arrayWithCapacity:20];
         
        [WAXMLHelper parseAtomPub:doc block:^(WAAtomPubEntry *entry) {
            [entry processContentPropertiesWithBlock:^(NSString *name, NSString *value) {
                if ([name isEqualToString:@"TableName"]) {
                    [tables addObject:value];
                }
            }];
        }];
         
        if (block) {
            block(tables, nil);
        } else if([_delegate respondsToSelector:@selector(storageClient:didFetchTables:)]) {
            [_delegate storageClient:self didFetchTables:tables];
        }
    }];
}

- (void)fetchTablesWithContinuation:(WAResultContinuation *)resultContinuation
{
    [self fetchTablesWithContinuation:resultContinuation usingCompletionHandler:nil];
}

- (void)fetchTablesWithContinuation:(WAResultContinuation *)resultContinuation usingCompletionHandler:(void (^)(NSArray *, WAResultContinuation *, NSError *))block
{
    NSMutableString *endpoint = [NSMutableString stringWithString:@"Tables"];
    if (resultContinuation.nextTableKey != nil) {
        [endpoint appendFormat:@"?NextTableKey=%@", [resultContinuation.nextTableKey URLEncode]];
    }
    
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"table" httpMethod:@"GET", nil];
    [self prepareTableRequest:request];
    
    WA_BEGIN_LOGGING
        NSDictionary *headers = [request allHTTPHeaderFields];
        NSLog(@"headers - %@", headers);
    WA_END_LOGGING
    
    [request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
        if (error) {
            if (block) {
                block(nil, nil, error);
            } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        NSMutableArray *tables = [NSMutableArray arrayWithCapacity:20];
         
        [WAXMLHelper parseAtomPub:doc block:^(WAAtomPubEntry *entry) {
            [entry processContentPropertiesWithBlock:^(NSString *name, NSString *value) {
                if ([name isEqualToString:@"TableName"]) {
                    [tables addObject:value];
                }
            }];
        }];
         
        WAResultContinuation *continuation = [[[WAResultContinuation alloc] initWithNextTableKey:request.nextTableKey] autorelease];
         
        if (block) {
            block(tables, continuation, nil);
        } else if([_delegate respondsToSelector:@selector(storageClient:didFetchTables:withResultContinuation:)]) {
            [_delegate storageClient:self didFetchTables:tables withResultContinuation:continuation];
        }
    }];
}

- (void)createTableNamed:(NSString *)newTableName
{
    [self createTableNamed:newTableName withCompletionHandler:nil];
}

- (void)createTableNamed:(NSString *)newTableName withCompletionHandler:(void (^)(NSError *))block
{
    NSString *requestDataString;
    NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
	NSString *dateString = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
    
    [dateFormatter release];
    
	requestDataString = [[CREATE_TABLE_REQUEST_STRING stringByReplacingOccurrencesOfString:@"$UPDATEDDATE$" withString:dateString] stringByReplacingOccurrencesOfString:@"$TABLENAME$" withString:newTableName];
    
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:@"Tables" 
                                                              forStorageType:@"table" 
                                                                  httpMethod:@"POST"
                                                                 contentData:[requestDataString dataUsingEncoding:NSUTF8StringEncoding]
                                                                 contentType:@"application/atom+xml", nil];    
    [self prepareTableRequest:request];

    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest *request, NSError *error) {
        if (error) {
            if (block) {
                block(error);
            } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }

		if (block) {
			block(nil);
		} else if ([(id)_delegate respondsToSelector:@selector(storageClient:didCreateTableNamed:)]) {
			[_delegate storageClient:self didCreateTableNamed:newTableName];
        }
    }];
}

- (void)deleteTableNamed:(NSString *)tableName
{
    [self deleteTableNamed:tableName withCompletionHandler:nil];
}

- (void)deleteTableNamed:(NSString *)tableName withCompletionHandler:(void (^)(NSError *))block
{
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:[@"Tables" stringByAppendingFormat:@"(\'%@\')", tableName] forStorageType:@"table" httpMethod:@"DELETE", nil];
	[self prepareTableRequest:request];
	
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest *request, NSError *error) {
        if (error) {
            if (block) {
                block (error);
            } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        if (block) {
            block (nil);
        } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didDeleteTableNamed:)]) {
            [_delegate storageClient:self didDeleteTableNamed:tableName];
        }
    }];
}

- (void)fetchEntitiesWithRequest:(WATableFetchRequest*)fetchRequest
{
    [self fetchEntitiesWithRequest:fetchRequest usingCompletionHandler:nil];
}

- (void)fetchEntitiesWithRequest:(WATableFetchRequest*)fetchRequest usingCompletionHandler:(void (^)(NSArray *, WAResultContinuation *, NSError *))block
{
    NSString* endpoint = [fetchRequest endpoint];
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"table" httpMethod:@"GET", nil];
    
    [self prepareTableRequest:request];
    
    WA_BEGIN_LOGGING
    NSDictionary *dictionary = [request allHTTPHeaderFields];
    NSLog(@"Request Headers: %@", [dictionary description]);
    WA_END_LOGGING
    
    
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
        if (error) {
            if (block) {
                block (nil, nil, error);
            } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
        
        NSMutableArray *entities = [NSMutableArray arrayWithCapacity:50];
        [WAXMLHelper parseAtomPub:doc block:^(WAAtomPubEntry *entry) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
            
            [entry processContentPropertiesWithBlock:^(NSString *name, NSString *value) {
                [dict setObject:value forKey:name];
            }];
            
            WATableEntity *entity = [[WATableEntity alloc] initWithDictionary:dict fromTable:fetchRequest.tableName];
            [entities addObject:entity];
            [entity release];
        }];
        WA_BEGIN_LOGGING
        NSLog(@"NextPartitionKey: %@", request.nextPartitionKey);
        NSLog(@"NextRowKey: %@", request.nextRowKey);
        WA_END_LOGGING
        
        WAResultContinuation *continuation = [[[WAResultContinuation alloc] initWithNextParitionKey:request.nextPartitionKey nextRowKey:request.nextRowKey] autorelease];
        
        if (block) {   
            block(entities, continuation, nil);
        } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFetchEntities:fromTableNamed:withResultContinuation:)]) {
            [_delegate storageClient:self didFetchEntities:entities fromTableNamed:fetchRequest.tableName withResultContinuation:continuation  ];
        }
    }];
}

- (BOOL)insertEntity:(WATableEntity *)newEntity
{
    return [self insertEntity:newEntity withCompletionHandler:nil];
}

- (BOOL)insertEntity:(WATableEntity *)newEntity withCompletionHandler:(void (^)(NSError *))block
{
    NSString *requestDataString = nil;
	NSString *properties = [newEntity propertyString];
    
    if (!properties) {
        if (block) {
            block([NSError errorWithDomain:@"com.microsoft.WAToolkit" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]);
		} else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
            [_delegate storageClient:self didFailRequest:nil withError:[NSError errorWithDomain:@"com.microsoft.WAToolkit" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]];
		}
        return NO;
    }
    
	// Construct the date in the right format
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc]init] autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
	NSString *dateString = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
	
	requestDataString = [[TABLE_INSERT_ENTITY_REQUEST_STRING stringByReplacingOccurrencesOfString:@"$UPDATEDDATE$" withString:dateString] stringByReplacingOccurrencesOfString:@"$PROPERTIES$" withString:properties];
	
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:newEntity.tableName 
                                                                forStorageType:@"table" 
                                                                    httpMethod:@"POST" 
                                                                   contentData:[requestDataString dataUsingEncoding:NSASCIIStringEncoding] 
                                                                   contentType:@"application/atom+xml", nil];
    [self prepareTableRequest:request];
    
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest *request, NSError *error) {
        if (error) {
            if (block) {
                block(error);
            } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        if (block) {
            block(nil);
        } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didInsertEntity:)]) {
            [_delegate storageClient:self didInsertEntity:newEntity];
        }
    }];
    
    return YES;
}

- (BOOL)updateEntity:(WATableEntity *)existingEntity
{
    return [self updateEntity:existingEntity withCompletionHandler:nil];
}

- (BOOL)updateEntity:(WATableEntity *)existingEntity withCompletionHandler:(void (^)(NSError *))block
{
	NSString *properties = [existingEntity propertyString];
    
    if (!properties) {
		if (block) {
			block([NSError errorWithDomain:@"com.microsoft.WAToolkit" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]);
		} else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
			[_delegate storageClient:self didFailRequest:nil withError:[NSError errorWithDomain:@"com.microsoft.WAToolkit" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]];
		}
		return NO;
    }

    NSString *requestDataString = nil;
	NSString *endpoint = [existingEntity endpoint];
	
    // Construct the date in the right format
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc]init] autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
	NSString *dateString = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
    
    NSURL *serviceURL = [_credential URLforEndpoint:endpoint forStorageType:@"table"];
    
	requestDataString = [[[TABLE_UPDATE_ENTITY_REQUEST_STRING stringByReplacingOccurrencesOfString:@"$UPDATEDDATE$" withString:dateString] stringByReplacingOccurrencesOfString:@"$PROPERTIES$" withString:properties] stringByReplacingOccurrencesOfString:@"$ENTITYID$" withString:[serviceURL absoluteString]];
	
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:endpoint 
                                                                forStorageType:@"table" 
                                                                    httpMethod:@"PUT"
                                                                   contentData:[requestDataString dataUsingEncoding:NSASCIIStringEncoding]
                                                                   contentType:@"application/atom+xml", nil];
    [self prepareTableRequest:request];
	[request setValue:@"*" forHTTPHeaderField:@"If-Match"];
	
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest *request, NSError *error) {
        if (error) {
            if (block) {
                block(error);
            } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        if (block) {
            block(nil);
        } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didUpdateEntity:)]) {
            [_delegate storageClient:self didUpdateEntity:existingEntity];
        }
    }];
    
    return YES;
}

- (BOOL)mergeEntity:(WATableEntity *)existingEntity 
{
    return [self mergeEntity:existingEntity withCompletionHandler:nil];
}

- (BOOL)mergeEntity:(WATableEntity *)existingEntity withCompletionHandler:(void (^)(NSError *))block
{
	NSString *properties = [existingEntity propertyString];
    
    if (!properties) {
        if (block) {
			block ([NSError errorWithDomain:@"com.microsoft.WAToolkit" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]);
		} else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
			[_delegate storageClient:self didFailRequest:nil withError:[NSError errorWithDomain:@"com.microsoft.WAToolkit" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]];
		}
		return NO;
    }
    
    NSString *requestDataString = nil;
	NSString *endpoint = [existingEntity endpoint];

	// Construct the date in the right format
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
	NSString *dateString = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
	
    NSURL *serviceURL = [_credential URLforEndpoint:endpoint forStorageType:@"table"];
	requestDataString = [[[TABLE_UPDATE_ENTITY_REQUEST_STRING stringByReplacingOccurrencesOfString:@"$UPDATEDDATE$" withString:dateString] stringByReplacingOccurrencesOfString:@"$PROPERTIES$" withString:properties] stringByReplacingOccurrencesOfString:@"$ENTITYID$" withString:[serviceURL path]];
    
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:endpoint 
                                                              forStorageType:@"table" 
                                                                  httpMethod:@"MERGE"
                                                                 contentData:[requestDataString dataUsingEncoding:NSASCIIStringEncoding]
                                                                 contentType:@"application/atom+xml", nil];
    [self prepareTableRequest:request];
	[request setValue:@"*" forHTTPHeaderField:@"If-Match"];
	
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest *request, NSError *error) {
        if (error) {
            if (block) {
                block(error);
            } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        if (block) {
            block(nil);
        } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didMergeEntity:)]) {
            [_delegate storageClient:self didMergeEntity:existingEntity];
        }
    }];
    
    return YES;
}

- (BOOL)deleteEntity:(WATableEntity *)existingEntity
{
    return [self deleteEntity:existingEntity withCompletionHandler:nil];
}

- (BOOL)deleteEntity:(WATableEntity *)existingEntity withCompletionHandler:(void (^)(NSError *))block
{
	NSString *endpoint = [existingEntity endpoint];
	
	if (!endpoint)
    {
		if (block) {
			block([NSError errorWithDomain:@"com.microsoft.WAToolkit" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"No endpoint defined" forKey:NSLocalizedDescriptionKey]]);
		} else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
			[_delegate storageClient:self didFailRequest:nil withError:[NSError errorWithDomain:@"com.microsoft.WAToolkit" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"No endpoint defined" forKey:NSLocalizedDescriptionKey]]];
		}
		return NO;
    }
    
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:endpoint 
                                                                forStorageType:@"table" 
                                                                    httpMethod:@"DELETE", nil];
    [self prepareTableRequest:request];

	[request setValue:@"*" forHTTPHeaderField:@"If-Match"];
	
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest *request, NSError *error) {
        if (error) {
            if (block) {
                block(error);
            } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        if (block) {
            block (nil);
        } else if ([(id)_delegate respondsToSelector:@selector(storageClient:didDeleteEntity:)]) {
            [_delegate storageClient:self didDeleteEntity:existingEntity];
        }
    }];
    
    return YES;
}

#pragma mark -
#pragma mark Private methods

- (void)privateGetQueueMessages:(WAQueueMessageFetchRequest *)fetchRequest useBlockError:(BOOL)useBlockError peekOnly:(BOOL)peekOnly withBlock:(void (^)(NSArray *, NSError *))block
{
	if (fetchRequest.fetchCount > 32) {
		// apply Azure queue fetch limit...
		fetchRequest.fetchCount = 32;
	}
	
	NSString *queueName = [fetchRequest.queueName lowercaseString];
    NSMutableString *endpoint = [NSMutableString stringWithFormat:@"/%@/messages?numofmessages=%d", [queueName URLEncode], fetchRequest.fetchCount];
	if (peekOnly) {
		[endpoint appendString:@"&peekonly=true"];
	} else {
		// allow 60 seconds to turn around and delete the message
        if (fetchRequest.visibilityTimeout == 0) {
            fetchRequest.visibilityTimeout = 60;
        }
		[endpoint appendFormat:@"&visibilitytimeout=%d", fetchRequest.visibilityTimeout];
	}
	
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue", nil];

    [request fetchXMLWithCompletionHandler:^(WACloudURLRequest *request, xmlDocPtr doc, NSError *error) {
        if (error) {
            if (useBlockError) {
                block(nil, error);
            } else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)]) {
                [_delegate storageClient:self didFailRequest:request withError:error];
            }
            return;
        }
         
        NSArray *queueMessages = [WAQueueMessageParser loadQueueMessages:doc];
        block(queueMessages, nil);
    }];
}

- (void) dealloc 
{
    _delegate = nil;
    [_credential release];

    [super dealloc];
}

#pragma mark -

@end

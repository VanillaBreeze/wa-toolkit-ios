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

#import "WABaseTestCase.h"
#import "WAToolkit.h"

NSString * const WAAccount = @"<your account>";
NSString * const WAAccessKey = @"<your access key>";
NSString * const WAProxyURL = @"https://<proxyhost>.cloudapp.net";
NSString * const WAProxyNamespace = @"<your proxy host>";
NSString * const WAProxyUsername = @"<proxy user name>";
NSString * const WAProxyPassword = @"<proxy password>";

// Used for container and table cleanup
NSString * const unitTestContainerName = @"unitestcontainer";
NSString * const unitTestQueueName = @"unittestqueue";
NSString * const unitTestTableName = @"unittesttable";

@implementation WABaseTestCase

- (void)setUp;
{
    [super setUp];

    // Setup direct
    account = [NSString stringWithString:WAAccount];
    accessKey = [NSString stringWithString:WAAccessKey];
    directCredential = [WAAuthenticationCredential credentialWithAzureServiceAccount:account accessKey:accessKey];
    directClient = [WACloudStorageClient storageClientWithCredential:directCredential];
    directDelegate = [WATestCloudStorageClientDelegate createDelegateForClient:directClient];
    
    // Setup proxy
    [WACloudStorageClient ignoreSSLErrorFor:WAProxyNamespace];
    NSError *error = nil;
    proxyURL = [NSString stringWithString:WAProxyURL];
    proxyUsername = [NSString stringWithString:WAProxyUsername];
    proxyPassword = [NSString stringWithString:WAProxyPassword];
    proxyCredential = [WAAuthenticationCredential authenticateCredentialSynchronousWithProxyURL:[NSURL URLWithString:proxyURL] user:proxyUsername password:proxyPassword error:&error];
    STAssertNil(error, @"There was an error authenticating against the proxy server: %@",[error localizedDescription]);
    proxyClient = [WACloudStorageClient storageClientWithCredential:proxyCredential];
    proxyDelegate = [WATestCloudStorageClientDelegate createDelegateForClient:proxyClient];
    
    // Setup some random strings for unit tests tables, containers, and queues
    randomTableNameString = [NSString stringWithFormat:@"%@%d",unitTestTableName,arc4random() % 1000];
    randomContainerNameString = [NSString stringWithFormat:@"%@%d",unitTestContainerName,arc4random() % 1000];
    randomQueueNameString = [NSString stringWithFormat:@"%@%d",unitTestQueueName,arc4random() % 1000];
    
    containerCount = 0;
    tableCount = 0;
}

- (void)tearDown
{
    [super tearDown];
}

@end

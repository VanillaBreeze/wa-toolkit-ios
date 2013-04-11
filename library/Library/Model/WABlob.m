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
#import "WABlob.h"
#import "WABlobContainer.h"

NSString * const WABlobPropertyKeyBlobType = @"BlobType";
NSString * const WABlobPropertyKeyCacheControl = @"Cache-Control";
NSString * const WABlobPropertyKeyContentEncoding = @"Content-Encoding";
NSString * const WABlobPropertyKeyContentLanguage = @"Content-Language";
NSString * const WABlobPropertyKeyContentLength = @"Content-Length";
NSString * const WABlobPropertyKeyContentMD5 = @"Content-MD5";
NSString * const WABlobPropertyKeyContentType = @"Content-Type";
NSString * const WABlobPropertyKeyEtag = @"Etag";
NSString * const WABlobPropertyKeyLastModified = @"Last-Modified";
NSString * const WABlobPropertyKeyLeaseStatus = @"LeaseStatus";
NSString * const WABlobPropertyKeySequenceNumber = @"x-ms-blob-sequence-number";

@implementation WABlob

@synthesize name = _name;
@synthesize URL = _URL;
@synthesize properties = _properties; 
@synthesize metadata = _metadata;
@synthesize contentData = _contentData;
@synthesize contentType = _contentType;
@synthesize containerName = _containerName;


- (id)initBlobWithName:(NSString *)name URL:(NSString *)URL containerName:(NSString *)containerName properties:(NSDictionary *)properties
{
    if ((self = [super init])) {
        _name = [name copy];
        _URL = [[NSURL URLWithString:URL] retain];
        _properties = [properties retain];
        _metadata = [[NSMutableDictionary alloc] initWithCapacity:5];
        _containerName = [containerName copy];
    }    
    
    return self;
}

- (id)initBlobWithName:(NSString *)name URL:(NSString *)URL containerName:(NSString *)containerName
{
    return [self initBlobWithName:name URL:URL containerName:containerName properties:nil];
}

- (id)initBlobWithName:(NSString *)name URL:(NSString *)URL 
{	
    return [self initBlobWithName:name URL:URL containerName:nil];	
}

- (void) dealloc 
{
    [_name release];
    [_URL release];
    [_properties release];
    [_metadata release];
    [_contentType release];
    [_contentData release];
    [_containerName release];
    
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Blob { name = %@, url = %@, contentType = %@, containerName = %@, properties = %@, metadata = %@ }", _name, _URL, _contentType, _containerName, _properties.description, _metadata.description];
}

- (void)setValue:(NSString *)value forMetadataKey:(NSString *)key
{
    [_metadata setValue:value forKey:key];
}

- (void)removeMetadataForKey:(NSString *)key
{
    [_metadata removeObjectForKey:key];
}

#pragma mark Private Methods

- (void)setContainerName:(NSString *)containerName
{
    if (_containerName != containerName) {
        [containerName retain];
        [_containerName release];
        _containerName = containerName;
    }
}

@end

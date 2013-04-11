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

#import "WABlobContainer.h"

NSString * const WAContainerPropertyKeyEtag = @"Etag";
NSString * const WAContainerPropertyKeyLastModified = @"Last-Modified";

@implementation WABlobContainer

@synthesize name = _name;
@synthesize URL = _URL;
@synthesize properties = _properties;
@synthesize sharedAccessSigniture = _sharedAccessSigniture;
@synthesize metadata = _metadata;
@synthesize isPublic = _isPublic;
@synthesize createIfNotExists = _createIfNotExists;

- (id)initContainerWithName:(NSString *)name 
{
    return [self initContainerWithName:name URL:nil sharedAccessSigniture:nil];
}

- (id)initContainerWithName:(NSString *)name URL:(NSString *)URL
{
    return [self initContainerWithName:name URL:URL sharedAccessSigniture:nil];
}

- (id)initContainerWithName:(NSString *)name URL:(NSString *)URL sharedAccessSigniture:(NSString *)sharedAccessSigniture
{
    return [self initContainerWithName:name URL:URL sharedAccessSigniture:sharedAccessSigniture properties:nil];
}

- (id)initContainerWithName:(NSString *)name URL:(NSString *)URL sharedAccessSigniture:(NSString *)sharedAccessSigniture properties:(NSDictionary *)properties
{
    if ((self = [super init])) {
        _name = [name copy];
        _URL = [[NSURL URLWithString:URL] retain];
        _sharedAccessSigniture = [sharedAccessSigniture copy];
        _properties = [properties retain];
        _metadata = [[NSMutableDictionary alloc] initWithCapacity:5];
    }    
    return self;
}

- (void)dealloc 
{
    [_name release];
    [_URL release];
    [_sharedAccessSigniture release];
    [_properties release];
    [_metadata release];
    
    [super dealloc];
}

- (NSString *)description
{
    //return [NSString stringWithFormat:@"WAßBlobContainer { name = %@, url = %@, sharedAccessSigniture = %@, properties = %@, metadata = %@, isPublic = %@, createIfNotExists = %@ }", _name, _URL, _sharedAccessSigniture, _properties.description, _metadata.description, _isPublic ? @"YES" : @"NO", _createIfNotExists ? @"YES" : @"NO"];
    
    return [NSString stringWithFormat:@"WAßBlobContainer { name = %@, url = %@, sharedAccessSigniture = %@, properties = %@, metadata = %@ }", _name, _URL, _sharedAccessSigniture, _properties.description, _metadata.description];
}

- (void)setValue:(NSString *)value forMetadataKey:(NSString *)key
{
    [_metadata setValue:value forKey:key];
}

- (void)removeMetadataForKey:(NSString *)key
{
    [_metadata removeObjectForKey:key];
}

@end

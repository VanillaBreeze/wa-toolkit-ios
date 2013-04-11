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

#import "WABitlyCredential.h"
#import "WAKeychainController.h"

static NSString * const kLogin = @"login";
static NSString * const kApiKey = @"apikey";
static NSString * const kBitlyInfoSaved = @"bitlyinfosaved";

@implementation WABitlyCredential

@synthesize login = _login;
@synthesize apiKey = _apiKey;
@synthesize saved = _saved;

- (id)init 
{
    self = [super init];
    if (self) {
        _saved = [[NSUserDefaults standardUserDefaults] boolForKey:kBitlyInfoSaved];
        if (_saved) {
            _login = [WAKeychainController keychainStringFromMatchingIdentifier:kLogin];
            _apiKey = [WAKeychainController keychainStringFromMatchingIdentifier:kApiKey];
        }
    }
    return self;
}

- (void)saveLogin:(NSString *)login apiKey:(NSString *)apiKey
{
    [WAKeychainController createKeychainValue:login forIdentifier:kLogin];
    [WAKeychainController createKeychainValue:apiKey forIdentifier:kApiKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kBitlyInfoSaved];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _login = [login copy];
    _apiKey = [apiKey copy];
    _saved = YES;
}

- (void)clear
{
    [WAKeychainController createKeychainValue:@"" forIdentifier:kLogin];
    [WAKeychainController createKeychainValue:@"" forIdentifier:kApiKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kBitlyInfoSaved];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _login = nil;
    _apiKey = nil;
    _saved = NO;
}

@end

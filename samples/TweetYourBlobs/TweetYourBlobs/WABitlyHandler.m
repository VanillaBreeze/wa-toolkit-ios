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
#import "WABitlyHandler.h"
#import "WABitlyResponse.h"
#import "UIApplication+WANetworkActivity.h"

@interface WABitlyHandler()

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *receivedData;

- (NSString *)urlEncode:(NSString *)string;

@end

@implementation WABitlyHandler

@synthesize longURL = _longURL;
@synthesize username = _username;
@synthesize apiKey = _apiKey;
@synthesize connection = _connection;
@synthesize receivedData = _receivedData;

- (id)init 
{
    return [self initWithLongURL:nil username:nil apiKey:nil];
}

- (id)initWithLongURL:(NSURL *)url username:(NSString *)username apiKey:(NSString *)apiKey
{
    self = [super init];
	if (self) {
		_longURL = url;
        _username = username;
        _apiKey = apiKey;
	}
	return self;
}

- (void)shortenUrlWithCompletionHandler:(WABitlyResponseHandler)block;
{
    _block = [block copy];
    
    NSString *longURLString = [self urlEncode:[self.longURL absoluteString]];
    NSString *requestString = [NSString stringWithFormat:@"http://api.bitly.com/v3/shorten?login=%@&apiKey=%@&longUrl=%@&format=json", self.username, self.apiKey, longURLString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    self.receivedData = [NSMutableData data];
    [[UIApplication sharedApplication] wa_pushNetworkActivity];
    [self.connection start];
}

#pragma mark - NSURLConnectionDelegate methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.connection = nil;
    self.receivedData = nil;
    
    /*
    NSString *statusText = [NSString stringWithFormat:@"The connection failed with error:%@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];
    */
    _block(nil, error);
    
    [[UIApplication sharedApplication] wa_popNetworkActivity];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[UIApplication sharedApplication] wa_popNetworkActivity];
    
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.receivedData options:kNilOptions error:&error];    
    if (error) {
        _block(nil, error);
    } else {
        NSDecimalNumber *statusCode = [json objectForKey:@"status_code"];
        NSString *statusText = [json objectForKey:@"status_txt"];
        NSDictionary *data = [json objectForKey:@"data"];
        if (statusCode.intValue != 200) {
            error = [NSError errorWithDomain:@"com.microsoft.WAToolkitConfig" 
                                        code:statusCode.intValue
                                    userInfo:[NSDictionary dictionaryWithObject:statusText forKey:NSLocalizedDescriptionKey]];
            _block(nil, error);
        } else {
            if (!data) { 
                error = [NSError errorWithDomain:@"com.microsoft.WAToolkitConfig" 
                                            code:statusCode.intValue
                                        userInfo:[NSDictionary dictionaryWithObject:@"The response data was empty from the service." forKey:NSLocalizedDescriptionKey]];
                _block(nil, error);
            } else {
                NSString *url = [data objectForKey:@"url"];
                if (!url) {
                    error = [NSError errorWithDomain:@"com.microsoft.WAToolkitConfig" 
                                                code:statusCode.intValue
                                            userInfo:[NSDictionary dictionaryWithObject:@"The service did not return a shortened url." forKey:NSLocalizedDescriptionKey]];
                    _block(nil, error);
                } else {
                    WABitlyResponse *response = [[WABitlyResponse alloc] initWithShortUrl:[NSURL URLWithString:url] longURL:self.longURL responseData:data];
                    _block(response, nil);
                }
            }
        }
    } 
    
    self.connection = nil;
    self.receivedData = nil;
    
    [[UIApplication sharedApplication] wa_popNetworkActivity];
}


#pragma mark - Private methods

- (NSString *)urlEncode:(NSString *)string
{
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                NULL,
                                                                (__bridge CFStringRef)string,
                                                                NULL,
                                                                (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                kCFStringEncodingUTF8);
}
@end

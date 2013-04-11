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

#import "WALoginHandler.h"
#import "WAConfiguration.h"
#import "WALoginViewController.h"
#import "WAServiceCall.h"
#import "WAAcsRegisterViewController.h"
#import "WARegisterViewController.h"

@interface WALoginHandler()

@property (nonatomic, weak) UIStoryboard *storyboard;
@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation WALoginHandler

@synthesize storyboard = _storyboard;
@synthesize navigationController = _navigationController;

- (id)init 
{
    return [self initWithStoryBoard:nil navigationController:nil];
}

- (id)initWithStoryBoard:(UIStoryboard *)storyboard navigationController:(UINavigationController *)navigationController
{
    self = [super init];
    if (self) {
        _storyboard = storyboard;
        _navigationController = navigationController;
    }
    return self;
}

- (void)login:(void (^)(WAAuthenticationCredential *authenticationCredential))block
{
    WAConfiguration *config = [WAConfiguration sharedConfiguration];	
    if(config.connectionType != WAConnectDirect) {
		[WACloudStorageClient ignoreSSLErrorFor:config.proxyNamespace];
	}
	switch(config.connectionType) {
		case WAConnectDirect: {
			WAAuthenticationCredential *authenticationCredential = [WAAuthenticationCredential credentialWithAzureServiceAccount:config.accountName accessKey:config.accessKey];
            
            block(authenticationCredential);
			break;
		}
			
		case WAConnectProxyMembership: {
			WALoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Login"];
            loginViewController.block = ^(WAAuthenticationCredential *authenticationCredential) {
                block(authenticationCredential);
            };
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
            navController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
			[self.navigationController presentModalViewController:navController animated:YES];
			break;
		}
			
		case WAConnectProxyACS: {
			// perform the ACS login procedure
			WACloudAccessControlClient *client = [WACloudAccessControlClient accessControlClientForNamespace:config.ACSNamespace realm:config.ACSRealm];
            
			[client showInViewController:self.navigationController allowsClose:NO withCompletionHandler:^(BOOL authenticated) {
				if (!authenticated) {
					return;
				}
				
                NSString *endpoint = @"/RegistrationService/validate";
                
				[WAServiceCall getFromURL:[config proxyURL:endpoint] withStringCompletionHandler:^(NSString* value, NSError *error) {
                    if (error) {
						UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Error Validating Account" 
																	   message:[error localizedDescription] 
																	  delegate:self
															 cancelButtonTitle:@"OK" 
															 otherButtonTitles:nil];
						[view show];
						return;
					}
                    
					BOOL registered = ([value compare:@"true" options:NSCaseInsensitiveSearch] == NSOrderedSame);
                    
					if (registered) {
						NSString *proxyURL = [config proxyURL];
                        WACloudAccessToken *sharedToken = [WACloudAccessControlClient sharedToken];
                        WAAuthenticationCredential *authenticationCredential = [WAAuthenticationCredential authenticateCredentialWithProxyURL:[NSURL URLWithString:proxyURL] accessToken:sharedToken];
                        block(authenticationCredential);
					} else {
						UIViewController *newController;
						
						if (config.connectionType == WAConnectProxyACS) {
							WAAcsRegisterViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AcsRegister"];
                            controller.block = ^(WAAuthenticationCredential *authenticationCredential) {
                                block(authenticationCredential);
                            };
                            newController = controller;
						} else {
                            WARegisterViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"Register"];
                            controller.block = ^(WAAuthenticationCredential *authenticationCredential) {
                                block(authenticationCredential);
                            };
							newController = controller;
						}
						
						[self.navigationController pushViewController:newController animated:YES];
					}
				}];
			}];
			break;
		}
	}
}

@end

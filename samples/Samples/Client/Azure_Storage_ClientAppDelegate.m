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

#import "Azure_Storage_ClientAppDelegate.h"
#import "WAConfiguration.h"
#import "StorageTypeSelector.h"

@implementation Azure_Storage_ClientAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize authenticationCredential;
@synthesize use_proxy;

- (void)dealloc
{
    RELEASE(_window);
    RELEASE(_navigationController);
    RELEASE(authenticationCredential);

    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Override point for customization after application launch.
	// Add the navigation controller's view to the window and display.
	
	WAConfiguration *config = [WAConfiguration sharedConfiguration];	
	if(!config) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Configuration Error" 
															message:@"You must update the ToolkitConfig section in the application's info.plist file before running the first time."
														   delegate:self 
												  cancelButtonTitle:@"Close" 
												  otherButtonTitles:nil];
		[alertView show];		
		[alertView release];
		return YES;
	}
	
	if(config.connectionType != WAConnectDirect) {
		[WACloudStorageClient ignoreSSLErrorFor:config.proxyNamespace];
	}
    
    // Register for Apple Push Notifications
    LOG(@"Registering for APN");
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
	
	StorageTypeSelector *root = [[StorageTypeSelector alloc] initWithNibName:@"StorageTypeSelector" bundle:nil];
	root.navigationItem.title = @"Toolkit Sample";
		
	UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:root];
	self.navigationController = nav;
	self.window.rootViewController = nav;
	[self.window makeKeyAndVisible];
	[nav release];
	[root release];
	
	[root performSelector:@selector(login:) withObject:self afterDelay:0.0];

    return YES;
}

+ (void)bindAccessToken
{
	WAConfiguration* config = [WAConfiguration sharedConfiguration];

	if(config.connectionType != WAConnectProxyACS) {
		return;
	}
	
	Azure_Storage_ClientAppDelegate *appDelegate = (Azure_Storage_ClientAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSString *proxyURL = [config proxyURL];
	WACloudAccessToken *sharedToken = [WACloudAccessControlClient sharedToken];
	
/*	
    LOG(@"appliesTo: %@", sharedToken.appliesTo);
	LOG(@"tokenType: %@", sharedToken.tokenType);
	LOG(@"expireDate: %@", sharedToken.expireDate);
	LOG(@"createDate: %@", sharedToken.createDate);
	LOG(@"securityToken: %@", sharedToken.securityToken);
	LOG(@"identityProvider: %@", sharedToken.identityProvider);
*/	
	appDelegate.authenticationCredential = [WAAuthenticationCredential authenticateCredentialWithProxyURL:[NSURL URLWithString:proxyURL]
																							  accessToken:sharedToken];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	exit(0);
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken { 
    
    NSString *str = [NSString stringWithFormat:@"Device Token=%@",deviceToken];
    LOG(@"%@",str);
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err { 
    
    NSString *str = [NSString stringWithFormat: @"Error: %@", err];
    LOG(@"%@",str);    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    for (id key in userInfo) {
        LOG(@"key: %@, value: %@", key, [userInfo objectForKey:key]);
    }    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

@end

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

#import "StorageTypeSelector.h"
#import "TableListController.h"
#import "WAConfiguration.h"
#import "ServiceCall.h"
#import "RootViewController.h"
#import "RegisterViewController.h"
#import "AcsRegisterViewController.h"
#import "Azure_Storage_ClientAppDelegate.h"

@interface StorageTypeSelector()

- (void)login:(id)sender;
- (void)logout:(id)sender;

@end

@implementation StorageTypeSelector

@synthesize tableStorage;
@synthesize blobStorage;
@synthesize queueStorage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    RELEASE(tableStorage);
    RELEASE(queueStorage);
    RELEASE(blobStorage);
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	WAConfiguration *config = [WAConfiguration sharedConfiguration];	
	if(config.connectionType != WAConnectDirect) {
		UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(logout:)];
		self.navigationItem.leftBarButtonItem = item;
		[item release];
	}	
	
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
	[self.navigationItem setBackBarButtonItem:backButton];
	[backButton release];
}

- (void)viewDidUnload
{
    self.tableStorage = nil;
    self.blobStorage = nil;
    self.queueStorage = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma - Action Methods

- (IBAction)showTableStorage:(id)sender
{
	TableListController *newController = [[TableListController alloc] initWithNibName:@"TableListController" bundle:nil];
    
	newController.navigationItem.title = @"Table Storage";
	[self.navigationController pushViewController:newController animated:YES];
	[newController release];
}

- (IBAction)showBlobStorage:(id)sender
{
	TableListController *newController = [[TableListController alloc] initWithNibName:@"TableListController" bundle:nil];
	
	newController.navigationItem.title = @"Blob Storage";
	[self.navigationController pushViewController:newController animated:YES];
	[newController release];
}

- (IBAction)showQueueStorage:(id)sender
{	
	TableListController *newController = [[TableListController alloc] initWithNibName:@"TableListController" bundle:nil];
	
	newController.navigationItem.title = @"Queue Storage";
	[self.navigationController pushViewController:newController animated:YES];
	[newController release];
}

#pragma mark - Private Methods

- (void)login:(id)sender
{
	WAConfiguration *config = [WAConfiguration sharedConfiguration];	
	switch(config.connectionType) {
		case WAConnectDirect: {
			Azure_Storage_ClientAppDelegate *appDelegate = (Azure_Storage_ClientAppDelegate *)[[UIApplication sharedApplication] delegate];
			appDelegate.authenticationCredential = [WAAuthenticationCredential credentialWithAzureServiceAccount:config.accountName 
																									   accessKey:config.accessKey];
			break;
		}
			
		case WAConnectProxyMembership: {
			RootViewController *newController = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:nil];
			UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:newController];
			[self presentModalViewController:navController animated:YES];
			[newController release];
			[navController release];
			break;
		}
			
		case WAConnectProxyACS: {
			// perform the ACS login procedure
			WACloudAccessControlClient *client = [WACloudAccessControlClient accessControlClientForNamespace:config.ACSNamespace realm:config.ACSRealm];

			[client showInViewController:self allowsClose:NO withCompletionHandler:^(BOOL authenticated) {
				if (!authenticated) {
					return;
				}
				
				self.navigationItem.leftBarButtonItem.enabled = NO;
				tableStorage.enabled = NO;
				blobStorage.enabled = NO;
				queueStorage.enabled = NO;
				
				UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
				UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:activity];
				self.navigationItem.rightBarButtonItem = item;
				[activity startAnimating];
				[activity release];
                [item release];
				
                NSString *endpoint = @"/RegistrationService/validate";
                
				[ServiceCall getFromURL:[config proxyURL:endpoint] withStringCompletionHandler:^(NSString* value, NSError *error) {
					self.navigationItem.leftBarButtonItem.enabled = YES;
					self.navigationItem.rightBarButtonItem = nil;
					tableStorage.enabled = YES;
					blobStorage.enabled = YES;
					queueStorage.enabled = YES;

					if (error) {
						UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Error Validating Account" 
																	   message:[error localizedDescription] 
																	  delegate:self
															 cancelButtonTitle:@"OK" 
															 otherButtonTitles:nil];
						[view show];
						[view release];
						return;
					}

					BOOL registered = ([value compare:@"true" options:NSCaseInsensitiveSearch] == NSOrderedSame);

					if (registered) {
						[Azure_Storage_ClientAppDelegate bindAccessToken];
					} else {
						WAConfiguration *config = [WAConfiguration sharedConfiguration];
						UIViewController *newController;
						
						if (config.connectionType == WAConnectProxyACS) {
							newController = [[AcsRegisterViewController alloc] initWithNibName:@"AcsRegisterViewController" bundle:nil];
						} else {
							newController = [[RegisterViewController alloc] initWithNibName:@"RegisterViewController" bundle:nil];
						}
						
						[self.navigationController pushViewController:newController animated:YES];
						[newController release];
					}
				}];
			}];
			break;
		}
	}
}

- (void)logout:(id)sender
{
	WAConfiguration *config = [WAConfiguration sharedConfiguration];	
	if(config.connectionType == WAConnectProxyACS) {
		[WACloudAccessControlClient logOut];
	}
	
	[self login:sender];
}


#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	[self logout:self];
}

@end

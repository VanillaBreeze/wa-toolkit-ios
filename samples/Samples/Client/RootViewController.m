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

#import "RootViewController.h"
#import "Azure_Storage_ClientAppDelegate.h"
#import "StorageTypeSelector.h"
#import "WAConfiguration.h"
#import "RegisterViewController.h"

@implementation RootViewController

@synthesize usernameField;
@synthesize passwordField;
@synthesize actionButton;
@synthesize activity;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.title = @"Login";
    }
    return self;
}

- (void)dealloc
{
    RELEASE(usernameField);
    RELEASE(passwordField);
    RELEASE(activity);
    RELEASE(actionButton);
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Register" style:UIBarButtonItemStyleBordered target:self action:@selector(registration:)] autorelease];
    
	[usernameField becomeFirstResponder];
}

- (void)viewDidUnload
{
    self.usernameField = nil;
    self.passwordField = nil;
    self.activity = nil;
    self.actionButton = nil;
    
    [super viewDidUnload];
}

#pragma mark - Action Methods

- (IBAction)login:(id)sender
{
	if(!usernameField.text.length || !passwordField.text.length) {
		UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Login" 
													   message:@"All fields must be filled in."
													  delegate:self 
											 cancelButtonTitle:@"OK" 
											 otherButtonTitles:nil];
		[view show];
		[view release];
		return;
	}
    
	Azure_Storage_ClientAppDelegate *appDelegate = (Azure_Storage_ClientAppDelegate *)[[UIApplication sharedApplication] delegate];
	WAConfiguration *config = [WAConfiguration sharedConfiguration];
	NSString *proxyURL = [config proxyURL];
	
	[usernameField resignFirstResponder];
	[passwordField resignFirstResponder];
    
	[activity startAnimating];
	actionButton.enabled = NO;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	appDelegate.authenticationCredential = [WAAuthenticationCredential authenticateCredentialWithProxyURL:[NSURL URLWithString:proxyURL] 
																									 user:usernameField.text
																								 password:passwordField.text 
																								 delegate:self];
}

- (IBAction)registration:(id)sender 
{
	RegisterViewController *newController = [[RegisterViewController alloc] initWithNibName:@"RegisterViewController" bundle:nil];
	[self.navigationController pushViewController:newController animated:YES];
    [newController release];
}

#pragma mark - WAAuthenticationDelegate Methods

- (void)loginDidSucceed
{
	actionButton.enabled = YES;
	self.navigationItem.rightBarButtonItem.enabled = YES;
	[activity stopAnimating];
	
	[self dismissModalViewControllerAnimated:YES];
}

- (void)loginDidFailWithError:(NSError *)error
{
	actionButton.enabled = YES;
	self.navigationItem.rightBarButtonItem.enabled = YES;
	[activity stopAnimating];
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[NSString stringWithFormat:@"An error occurred: %@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
    
	passwordField.text = @"";
	[passwordField becomeFirstResponder];
}


@end
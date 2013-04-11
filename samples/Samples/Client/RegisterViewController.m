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

#import "RegisterViewController.h"
#import "WAConfiguration.h"
#import "ServiceCall.h"
#import "Azure_Storage_ClientAppDelegate.h"

@implementation RegisterViewController

@synthesize usernameField;
@synthesize passwordField;
@synthesize confirmPasswordField;
@synthesize actionButton;
@synthesize activity;
@synthesize emailField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.title = @"Registration";
    }
    return self;
}

- (void)dealloc
{
    RELEASE(usernameField);
    RELEASE(passwordField);
    RELEASE(emailField);
    RELEASE(confirmPasswordField);
    RELEASE(activity);
    RELEASE(actionButton);

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

    // Do any additional setup after loading the view from its nib.	
	[usernameField becomeFirstResponder];
}

- (void)viewDidUnload
{
    self.usernameField = nil;
    self.passwordField = nil;
    self.emailField = nil;
    self.confirmPasswordField = nil;
    self.activity = nil;
    self.actionButton = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma - Action Methods

- (IBAction)registerClicked:(id)sender 
{
	[usernameField resignFirstResponder];
	[emailField resignFirstResponder];
	[passwordField resignFirstResponder];
	[confirmPasswordField resignFirstResponder];
	
	if(!usernameField.text.length || !emailField.text.length || !passwordField.text.length) {
		UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Registration" 
													   message:@"All fields must be filled in."
													  delegate:self 
											 cancelButtonTitle:@"OK" 
											 otherButtonTitles:nil];
		[view show];
		[view release];
		return;
	}
	
	if(![passwordField.text isEqualToString:confirmPasswordField.text]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Register" 
														message:@"Passwords do not match"
													   delegate:nil 
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	
	[activity startAnimating];
	actionButton.enabled = NO;
	
	WAConfiguration *config = [WAConfiguration sharedConfiguration];	
	NSString *payload = [ServiceCall xmlBuilder:@"RegistrationUser" 
								objectNamespace:@"Microsoft.Samples.WindowsPhoneCloud.StorageClient.Credentials", 
						 @"EMail", emailField.text,
						 @"Name", usernameField.text,
						 @"Password", passwordField.text,
						 nil];
	NSString* url = @"/AuthenticationService/register";
	
	[ServiceCall postXmlToURL:[config proxyURL:url] body:payload withDictionaryCompletionHandler:^(NSDictionary *values, NSError *error) {
		 [activity stopAnimating];
		 actionButton.enabled = YES;
		 
		 if (error) {
			 UIAlertView* view = [[UIAlertView alloc] initWithTitle:@"Registration" 
															message:[NSString stringWithFormat:@"An error occurred (%@)", [error localizedDescription]]
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			 [view show];
			 [view release];
			 return;
		 }
		 
		 NSString *str = [values objectForKey:@"text"];
		 
		 if([str isEqualToString:@"Success"]) {
			 Azure_Storage_ClientAppDelegate* appDelegate = (Azure_Storage_ClientAppDelegate *)[[UIApplication sharedApplication] delegate];
			 WAConfiguration *config = [WAConfiguration sharedConfiguration];
			 NSString *proxyURL = [config proxyURL];
			 
			 [usernameField resignFirstResponder];
			 [passwordField resignFirstResponder];
			 
			 [activity startAnimating];
			 actionButton.enabled = NO;
			 
			 appDelegate.authenticationCredential = [WAAuthenticationCredential authenticateCredentialWithProxyURL:[NSURL URLWithString:proxyURL] 
																											  user:usernameField.text
																										  password:passwordField.text 
																										  delegate:self];
		 } else if([str isEqualToString:@"DuplicateUserName"]) {
			 UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Registration" 
															message:@"Username is already registered."
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			 [view show];
			 [view release];
		 } else if([str isEqualToString:@"DuplicateEmail"]) {
			 UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Registration" 
															message:@"Email is already registered."
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			 [view show];
			 [view release];
		 } else {
			 UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Registration" 
															message:@"User could not be registered."
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			 [view show];
			 [view release];
		 }
	 }];
}

#pragma - WAAuthenticationDelegate Methods

- (void)loginDidSucceed
{
	actionButton.enabled = YES;
	self.navigationItem.rightBarButtonItem.enabled = YES;
	[activity stopAnimating];
	
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)loginDidFailWithError:(NSError *)error
{
	actionButton.enabled = YES;
	[activity stopAnimating];
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[NSString stringWithFormat:@"An error occurred: %@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


@end

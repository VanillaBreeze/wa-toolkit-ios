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

#import "WAAcsRegisterViewController.h"
#import "WAConfiguration.h"
#import "WAServiceCall.h"

@interface WAAcsRegisterViewController()

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showAlertWithMessage:(NSString *)message;
- (void)lockView;
- (void)unlockView;

@end

@implementation WAAcsRegisterViewController

@synthesize usernameField = _usernameField;
@synthesize actionButton = _actionButton;
@synthesize activity = _activity;
@synthesize emailField = _emailField;
@synthesize block;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = @"Registration";
    
	[_usernameField becomeFirstResponder];
	
	WACloudAccessToken *sharedToken = [WACloudAccessControlClient sharedToken];
	NSDictionary *claims = sharedToken.claims;
	
	if (claims) {
		self.usernameField.text = [claims objectForKey:@"name"];
		self.emailField.text = [claims objectForKey:@"emailaddress"];
	}
}

- (void)viewDidUnload
{
    self.usernameField = nil;
    self.emailField = nil;
    self.activity = nil;
    self.actionButton = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Action Methods

- (IBAction)registerUser:(id)sender 
{
	[_usernameField resignFirstResponder];
	[_emailField resignFirstResponder];
	
	if (!_usernameField.text.length || !_emailField.text.length) {
		UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Registration" 
													   message:@"All fields must be filled in."
													  delegate:self 
											 cancelButtonTitle:@"OK" 
											 otherButtonTitles:nil];
		[view show];
		return;
	}
	
    [self lockView];
	
	NSString *payload = [WAServiceCall xmlBuilder:@"RegistrationUser" 
								objectNamespace:@"Microsoft.Samples.WindowsPhoneCloud.StorageClient.Credentials", 
						 @"EMail", _emailField.text,
						 @"Name", _usernameField.text,
						 nil];
    
	WAConfiguration *config = [WAConfiguration sharedConfiguration];	
	NSString *url = @"/RegistrationService/register";
	
	[WAServiceCall postXmlToURL:[config proxyURL:url] body:payload withDictionaryCompletionHandler:^(NSDictionary *values, NSError *error) {
        [self unlockView];
        
        if (error) {
            [self showAlertWithMessage:[NSString stringWithFormat:@"An error occurred (%@)", [error localizedDescription]]];
            return;
        }
        
        NSString* str = [values objectForKey:@"text"];
        
        if ([str isEqualToString:@"Success"]) {
            NSString *proxyURL = [config proxyURL];
            WACloudAccessToken *sharedToken = [WACloudAccessControlClient sharedToken];
            _authenticationCredential = [WAAuthenticationCredential authenticateCredentialWithProxyURL:[NSURL URLWithString:proxyURL] accessToken:sharedToken];
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else if ([str isEqualToString:@"DuplicateUserName"]) {
            [self showAlertWithMessage:@"Username is already registered."];
        } else if ([str isEqualToString:@"DuplicateEmail"]) {
            [self showAlertWithMessage:@"Email is already registered."];
        } else {
            [self showAlertWithMessage:@"User could not be registered."];
        }
    }];
}

#pragma mark - Private methods

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *view = [[UIAlertView alloc] initWithTitle:title
                                                   message:message
                                                  delegate:self 
                                         cancelButtonTitle:@"OK" 
                                         otherButtonTitles:nil];
    [view show];
}

- (void)showAlertWithMessage:(NSString *)message
{
    [self showAlertWithTitle:@"Registration"  message:message];
}

- (void)lockView
{
    [_activity startAnimating];
	_actionButton.enabled = NO;
	self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)unlockView
{
    _actionButton.enabled = YES;
	self.navigationItem.rightBarButtonItem.enabled = YES;
	[_activity stopAnimating];
}

#pragma mark - WAAuthenticationDelegate Methods

- (void)loginDidSucceed
{
	[self unlockView];
    
    block(_authenticationCredential);
	
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)loginDidFailWithError:(NSError *)error
{
	[self unlockView];
	
    [self showAlertWithTitle:@"Login Error" message:[NSString stringWithFormat:@"An error occurred: %@", [error localizedDescription]]];
}

@end

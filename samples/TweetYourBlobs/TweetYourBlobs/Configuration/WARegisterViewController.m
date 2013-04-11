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

#import "WARegisterViewController.h"
#import "WAConfiguration.h"
#import "WAServiceCall.h"

@interface WARegisterViewController()

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showAlertWithMessage:(NSString *)message;

@end

@implementation WARegisterViewController

@synthesize emailField = _emailField;
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize confirmPasswordField = _confirmPasswordField;
@synthesize actionButton = _actionButton;
@synthesize activity = _activity;
@synthesize block;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Registration";
	[_usernameField becomeFirstResponder];
}

- (void)viewDidUnload
{
    self.usernameField = nil;
    self.passwordField = nil;
    self.emailField = nil;
    self.confirmPasswordField = nil;
    self.activity = nil;
    self.actionButton = nil;
    self.block = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma - Action Methods

- (IBAction)registerUser:(id)sender 
{
	[_usernameField resignFirstResponder];
	[_emailField resignFirstResponder];
	[_passwordField resignFirstResponder];
	[_confirmPasswordField resignFirstResponder];
	
	if(!_usernameField.text.length || !_emailField.text.length || !_passwordField.text.length) {
		[self showAlertWithMessage:@"All fields must be filled in."];
		return;
	}
	
	if(![_passwordField.text isEqualToString:_confirmPasswordField.text]) {
		[self showAlertWithMessage:@"Passwords do not match."];
		return;
	}
	
	[_activity startAnimating];
	_actionButton.enabled = NO;
	
	WAConfiguration *config = [WAConfiguration sharedConfiguration];	
	NSString *payload = [WAServiceCall xmlBuilder:@"RegistrationUser" 
								objectNamespace:@"Microsoft.Samples.WindowsPhoneCloud.StorageClient.Credentials", 
                         @"EMail", _emailField.text,
						 @"Name", _usernameField.text,
						 @"Password", _passwordField.text,
						 nil];
	NSString* url = @"/AuthenticationService/register";
	
	[WAServiceCall postXmlToURL:[config proxyURL:url] body:payload withDictionaryCompletionHandler:^(NSDictionary *values, NSError *error) {
        [_activity stopAnimating];
        _actionButton.enabled = YES;
        
        if (error) {
            [self showAlertWithMessage:[NSString stringWithFormat:@"An error occurred (%@)", [error localizedDescription]]];
            return;
        }
        
        NSString *str = [values objectForKey:@"text"];
        
        if([str isEqualToString:@"Success"]) {
            WAConfiguration *config = [WAConfiguration sharedConfiguration];
            NSString *proxyURL = [config proxyURL];
            
            [_usernameField resignFirstResponder];
            [_passwordField resignFirstResponder];
            
            [_activity startAnimating];
            _actionButton.enabled = NO;
            
            _authenticationCredential = [WAAuthenticationCredential authenticateCredentialWithProxyURL:[NSURL URLWithString:proxyURL] 
                                                                                                             user:_usernameField.text
                                                                                                         password:_passwordField.text 
                                                                                                        delegate:self];

            
        } else if([str isEqualToString:@"DuplicateUserName"]) {
            [self showAlertWithMessage:@"Username is already registered."];
        } else if([str isEqualToString:@"DuplicateEmail"]) {
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

#pragma mark - WAAuthenticationDelegate methods

- (void)loginDidSucceed
{
	_actionButton.enabled = YES;
	self.navigationItem.rightBarButtonItem.enabled = YES;
	[_activity stopAnimating];
    
    block(_authenticationCredential);
    
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)loginDidFailWithError:(NSError *)error
{
	_actionButton.enabled = YES;
	[_activity stopAnimating];
    
	[self showAlertWithTitle:@"Login Error" message:[NSString stringWithFormat:@"An error occurred: %@", [error localizedDescription]]];
}

@end

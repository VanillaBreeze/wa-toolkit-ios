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

#import "WALoginViewController.h"
#import "WAConfiguration.h"
#import "WARegisterViewController.h"

@interface WALoginViewController()

- (IBAction)registration:(id)sender;
- (void)lockView;
- (void)unlockView;

@end

@implementation WALoginViewController

@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize actionButton = _actionButton;
@synthesize activity = _activity;
@synthesize block;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = @"Login";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Register" style:UIBarButtonItemStyleBordered target:self action:@selector(registration:)];
    
	[_usernameField becomeFirstResponder];
}

- (void)viewDidUnload
{
    self.usernameField = nil;
    self.passwordField = nil;
    self.activity = nil;
    self.actionButton = nil;
    self.block = nil;
    
    [super viewDidUnload];
}

#pragma mark - Action Methods

- (IBAction)login:(id)sender
{
	if(!_usernameField.text.length || !_passwordField.text.length) {
		UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"Login" 
													   message:@"All fields must be filled in."
													  delegate:self 
											 cancelButtonTitle:@"OK" 
											 otherButtonTitles:nil];
		[view show];
		return;
	}

    [_usernameField resignFirstResponder];
	[_passwordField resignFirstResponder];

    
	WAConfiguration *config = [WAConfiguration sharedConfiguration];
	NSString *proxyURL = [config proxyURL];
    
	[self lockView];
	
	_authenticationCredential = [WAAuthenticationCredential authenticateCredentialWithProxyURL:[NSURL URLWithString:proxyURL] user:_usernameField.text password:_passwordField.text delegate:self];
}

- (IBAction)registration:(id)sender 
{
	WARegisterViewController *newController = [self.storyboard instantiateViewControllerWithIdentifier:@"Register"];
    newController.block = ^(WAAuthenticationCredential *authenticationCredential) {
        _authenticationCredential = authenticationCredential;
        [self loginDidSucceed];
    };
	[self.navigationController pushViewController:newController animated:YES];
    
}

#pragma mark - Private methods

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
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)loginDidFailWithError:(NSError *)error
{
    [self unlockView];
    
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error" 
                                                        message:[NSString stringWithFormat:@"An error occurred: %@", [error localizedDescription]] 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
	[alertView show];
    
	_passwordField.text = @"";
	[_passwordField becomeFirstResponder];
}


@end

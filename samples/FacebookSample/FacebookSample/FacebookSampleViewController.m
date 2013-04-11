//
//  FacebookSampleViewController.m
//  FacebookSample
//
//  Created by Scott Densmore on 11/27/11.
//  Copyright 2011 Scott Densmore. All rights reserved.
//

#import "FacebookSampleViewController.h"

NSString * const ACSNamespace = @"your ACS namespace";
NSString * const ACSRealm = @"your relying party realm";

NSString * const NameIdentifierClaim = @"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier";
NSString * const AccessTokenClaim = @"http://www.facebook.com/claims/AccessToken";

@implementation FacebookSampleViewController

@synthesize loginButton;
@synthesize friendsButton;
@synthesize friendLabel;

- (void)dealloc 
{
    _token = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.friendsButton = nil;
    self.loginButton = nil;
    self.friendLabel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)login:(id)sender 
{
    self.loginButton.hidden = YES;
    WACloudAccessControlClient *acsClient = [WACloudAccessControlClient accessControlClientForNamespace:ACSNamespace realm:ACSRealm];
    [acsClient showInViewController:self allowsClose:NO withCompletionHandler:^(BOOL authenticated) { 
        if (!authenticated) { 
            NSLog(@"Error authenticating"); 
            self.loginButton.hidden = NO;
        } else { 
            _token = [WACloudAccessControlClient sharedToken]; 
            self.friendsButton.hidden = NO;
        }
    }];
}

- (IBAction)friends:(id)sender 
{
    // Get claims
    NSString *fbuserId = [[_token claims] objectForKey:NameIdentifierClaim];
    NSString *oauthToken = [[_token claims] objectForKey:AccessTokenClaim];
        
    // Get my friends
    NSError *error = NULL;
    NSString *graphURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/friends?access_token=%@",fbuserId,oauthToken];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:graphURL]];
    NSURLResponse *response = NULL;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *friendsList = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"id" options:0 error:&error];
    NSUInteger friendCount = [regex numberOfMatchesInString:friendsList options:0 range:NSMakeRange(0, [friendsList length])];
    [friendsList release];
    
    self.friendLabel.text = [NSString stringWithFormat:@"%d friends", friendCount];
    self.friendLabel.hidden = NO;
}
@end

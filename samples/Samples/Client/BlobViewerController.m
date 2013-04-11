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

#import "BlobViewerController.h"
#import "Azure_Storage_ClientAppDelegate.h"

@interface BlobViewerController()

- (void)stopActivity;
- (void)showActivity;

@end

@implementation BlobViewerController

@synthesize blobImageView;
@synthesize blob;

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
    RELEASE(blobImageView);
    storageClient.delegate = nil;
    RELEASE(storageClient);
    RELEASE(blob);

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

    [self showActivity];
    
	Azure_Storage_ClientAppDelegate	*appDelegate = (Azure_Storage_ClientAppDelegate *)[[UIApplication sharedApplication] delegate];

	storageClient = [[WACloudStorageClient storageClientWithCredential:appDelegate.authenticationCredential] retain];
    NSString *contentType = blob.contentType;
    if ([contentType hasPrefix:@"image"]) {
		[storageClient fetchBlobData:self.blob withCompletionHandler:^(NSData *imgData, NSError *error) {
			UIImage *blobImage = [UIImage imageWithData:imgData];
			self.blobImageView.image = blobImage;
            [self stopActivity];
		}];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
    storageClient.delegate = nil;
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    self.blobImageView = nil;;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Private Methods
- (void)stopActivity
{
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)showActivity
{
    UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:view] autorelease];
	[view startAnimating];
	[view release];
}
@end

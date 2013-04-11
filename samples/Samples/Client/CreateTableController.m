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

#import "CreateTableController.h"
#import "Azure_Storage_ClientAppDelegate.h"
#import "UIViewController+ShowError.h"

@implementation CreateTableController

@synthesize itemName;
@synthesize createButton;
@synthesize uploadDefaultImageButton;
@synthesize nameLabel;
@synthesize selectedContainer;
@synthesize selectedQueue;
@synthesize delegate;

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
    delegate = nil;
    RELEASE(itemName);
    RELEASE(createButton);
    RELEASE(uploadDefaultImageButton);
    RELEASE(nameLabel);
	storageClient.delegate = nil;
    RELEASE(storageClient);
    RELEASE(selectedContainer);
    RELEASE(selectedQueue);
    
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
    
	Azure_Storage_ClientAppDelegate *appDelegate = (Azure_Storage_ClientAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    storageClient = [[WACloudStorageClient storageClientWithCredential:appDelegate.authenticationCredential] retain];
	storageClient.delegate = self;

	if ([self.navigationItem.title hasSuffix:@"Table"]) {
		nameLabel.text = @"Table Name:";
	} else if ([self.navigationItem.title hasSuffix:@"Container"]) {
		nameLabel.text = @"Container Name:";
	} else if ([self.navigationItem.title hasSuffix:@"Blob"]) {
		nameLabel.text = @"Blob Name:";
		[createButton setTitle:@"Pick Image" forState:UIControlStateNormal];
        [uploadDefaultImageButton setHidden:NO];
	} else if ([self.navigationItem.title hasSuffix:@"Queue"]) {
		nameLabel.text = @"Queue Name:";
	} else if ([self.navigationItem.title hasSuffix:@"QueueMessage"]) {
		nameLabel.text = @"Queue Message Name:";
	}

	[itemName becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    storageClient.delegate = nil;
    
    [super viewWillDisappear:animated];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (![self.navigationItem.title hasSuffix:@"Table"] &&
		![self.navigationItem.title hasSuffix:@"Container"] &&
		![self.navigationItem.title hasSuffix:@"Queue"] &&
		![self.navigationItem.title hasSuffix:@"Blob"]) {
		createButton.enabled = YES;
		return YES;
	}
	
	NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
	
	if (!newStr.length) {
		createButton.enabled = NO;
        uploadDefaultImageButton.enabled = YES;
		return YES;
	}
	
	if ([newStr rangeOfString:@"^[A-Za-z][A-Za-z0-9\\-\\_]*" 
					 options:NSRegularExpressionSearch].length == newStr.length) {
		createButton.enabled = YES;
        uploadDefaultImageButton.enabled = YES;
		return YES;
	}
		 
	return NO;
}

- (void)viewDidUnload
{
    self.itemName = nil;
    self.createButton = nil;
    self.uploadDefaultImageButton = nil;
    self.nameLabel = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Action Methods

- (IBAction)createItem:(id)sender
{
    [itemName resignFirstResponder];
	
	if ([[itemName text] length] == 0) {
		return;
	}
	
	if (![self.navigationItem.title hasSuffix:@"Blob"]) {
		UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:view] autorelease];
		[view startAnimating];
		[view release];
	}
	
	if ([self.navigationItem.title hasSuffix:@"Table"]) {
		[storageClient createTableNamed:itemName.text];
	} else if ([self.navigationItem.title hasSuffix:@"Container"]) {
        WABlobContainer *container = [[WABlobContainer alloc] initContainerWithName:itemName.text];
		[storageClient addBlobContainer:container];
        [container release];
	} else if ([self.navigationItem.title hasSuffix:@"Blob"]) {
		if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
			[self actionSheet:nil didDismissWithButtonIndex:1];
			return;
		}
		
		UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil 
														   delegate:self 
												  cancelButtonTitle:@"Cancel"
											 destructiveButtonTitle:nil 
												  otherButtonTitles:@"Take Photo", @"Choose Existing", nil];
		[sheet showInView:self.view];
		[sheet release];
	} else if ([self.navigationItem.title hasSuffix:@"Queue"]) {
		[storageClient addQueueNamed:itemName.text];
	}
}

- (IBAction)uploadDefaultImage:(id)sender
{
    WABlob *blob = [[[WABlob alloc] initBlobWithName:@"windows_azure.jpg"  URL:nil containerName:self.selectedContainer.name] autorelease];
    blob.contentType = @"image/jpeg";
    blob.contentData = UIImageJPEGRepresentation([UIImage imageNamed:@"windows_azure.jpg"], 1.0);
	[storageClient addBlob:blob
               toContainer:self.selectedContainer 
     withCompletionHandler:^(NSError* error) {
        if(error) {
            [self showError:error];
            return;
        }
         
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark - UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.delegate = self;
	
	if (buttonIndex == 0) {
		imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	}
    
	[self presentModalViewController:imagePicker animated:YES];
	[imagePicker release];
}

#pragma mark - CloudStorageClientDelegate Methods

- (void)storageClient:(WACloudStorageClient *)client didFailRequest:request withError:(NSError*)error
{
	[self showError:error];
}

- (void)storageClient:(WACloudStorageClient *)client didCreateTableNamed:(NSString *)tableName
{
	self.navigationItem.rightBarButtonItem = nil;
    if ([delegate respondsToSelector:@selector(createTableController:didAddTableNamed:)]) {
        [delegate createTableController:self didAddTableNamed:tableName];
    }
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)storageClient:(WACloudStorageClient *)client didAddBlobContainer:(WABlobContainer *)container
{
	self.navigationItem.rightBarButtonItem = nil;
    if ([delegate respondsToSelector:@selector(createTableController:didAddContainer:)]) {
        [delegate createTableController:self didAddContainer:container];
    }
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)storageClient:(WACloudStorageClient *)client didAddBlob:(WABlob *)blob toContainer:(WABlobContainer *)container
{
	self.navigationItem.rightBarButtonItem = nil;
    if ([delegate respondsToSelector:@selector(createTableController:didAddBlob:toContainer:)]) {
        [delegate createTableController:self didAddBlob:blob toContainer:container];
    }
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)storageClient:(WACloudStorageClient *)client didAddQueueNamed:(NSString *)queueName
{
	self.navigationItem.rightBarButtonItem = nil;
    if ([delegate respondsToSelector:@selector(createTableController:didAddQueueNamed:)]) {
        [delegate createTableController:self didAddQueueNamed:queueName];
    }
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)selectedImage editingInfo:(NSDictionary *)editingInfo
{
    NSString *imageName = itemName.text;
    WABlob *blob = [[[WABlob alloc] initBlobWithName:imageName URL:nil containerName:self.selectedContainer.name] autorelease];
    blob.contentType = @"image/jpeg";
    blob.contentData = UIImageJPEGRepresentation(selectedImage, 1.0);
    [storageClient addBlob:blob
               toContainer:self.selectedContainer
     withCompletionHandler:^(NSError* error) {
        if(error) {
            [self showError:error];
            return;
        }
		 
        [self dismissModalViewControllerAnimated:NO];
        if ([delegate respondsToSelector:@selector(createTableController:didAddBlob:toContainer:)]) {
            [delegate createTableController:self didAddBlob:blob toContainer:self.selectedContainer];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissModalViewControllerAnimated:YES];
}

@end

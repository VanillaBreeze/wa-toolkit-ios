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

#import "DeleteTableController.h"
#import "Azure_Storage_ClientAppDelegate.h"
#import "WABlobContainer.h"
#import "WABlob.h"

@implementation DeleteTableController

@synthesize listTableView;
@synthesize deleteButton;
@synthesize storageList;
@synthesize selectedContainer;
@synthesize selectedQueue;

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
	[listTableView release];
	[deleteButton release];
	[storageClient release];
	[storageList release];
	[selectedContainer release];
	[selectedQueue release];
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

	Azure_Storage_ClientAppDelegate		*appDelegate = (Azure_Storage_ClientAppDelegate *)[[UIApplication sharedApplication] delegate];

	[super viewDidLoad];

	storageClient = [[WACloudStorageClient storageClientWithCredential:appDelegate.authenticationCredential] retain];
	storageClient.delegate = self;

	if ([self.navigationItem.title hasSuffix:@"Table"])
	{
		[storageClient fetchTables];
	}
	else if ([self.navigationItem.title hasSuffix:@"Container"])
	{
		[storageClient fetchBlobContainers];
	}
	else if ([self.navigationItem.title hasSuffix:@"Blob"])
	{
		[storageClient fetchBlobs:self.selectedContainer];
	}
	else if ([self.navigationItem.title hasSuffix:@"Queue"])
	{
		[storageClient fetchQueues];
	}

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)deleteItem:(id)sender
{

	deleteButton.enabled = NO;
	if ([self.navigationItem.title hasSuffix:@"Table"])
	{
		[storageClient deleteTableNamed:[storageList objectAtIndex:[listTableView indexPathForSelectedRow].row]];
	}
	else if ([self.navigationItem.title hasSuffix:@"Container"])
	{
		[storageClient deleteBlobContainer:[storageList objectAtIndex:[listTableView indexPathForSelectedRow].row]];
	}
	else if ([self.navigationItem.title hasSuffix:@"Blob"])
	{
		[storageClient deleteBlob:[storageList objectAtIndex:[listTableView indexPathForSelectedRow].row]];
	}
	else if ([self.navigationItem.title hasSuffix:@"Queue"])
	{
		WAQueue *queue = [storageList objectAtIndex:[listTableView indexPathForSelectedRow].row];
		[storageClient deleteQueueNamed:queue.queueName];
	}

}

#pragma mark - CloudStorageClientDelegate methods

- (void)storageClient:(WACloudStorageClient *)client didFailRequest:request withError:error
{
}

- (void)storageClient:(WACloudStorageClient *)client didFetchTables:(NSArray *)tables
{
	self.storageList = tables;
	[listTableView reloadData];
}

- (void)storageClient:(WACloudStorageClient *)client didDeleteTableNamed:(NSString *)tableName;
{
	[listTableView deselectRowAtIndexPath:[listTableView indexPathForSelectedRow] animated:YES];
	[storageClient fetchTables];
}

- (void)storageClient:(WACloudStorageClient *)client didFetchBlobContainers:(NSArray *)containers
{
	self.storageList = containers;
	[listTableView reloadData];
}

- (void)storageClient:(WACloudStorageClient *)client didFetchBlobs:(NSArray *)blobs inContainer:(WABlobContainer *)container
{
	self.storageList = blobs;
	[listTableView reloadData];
}

- (void)storageClient:(WACloudStorageClient *)client didDeleteBlobContainer:(WABlobContainer *)name
{
	[listTableView deselectRowAtIndexPath:[listTableView indexPathForSelectedRow] animated:YES];
	[storageClient fetchBlobContainers];
}

- (void)storageClient:(WACloudStorageClient *)client didDeleteBlob:(WABlob *)blob
{
	[listTableView deselectRowAtIndexPath:[listTableView indexPathForSelectedRow] animated:YES];
	[storageClient fetchBlobs:self.selectedContainer];
}

- (void)storageClient:(WACloudStorageClient *)client didFetchQueues:(NSArray *)queues
{
	self.storageList = queues;
	[listTableView reloadData];
}

- (void)storageClient:(WACloudStorageClient *)client didDeleteQueueNamed:(NSString *)queueName
{
	[listTableView deselectRowAtIndexPath:[listTableView indexPathForSelectedRow] animated:YES];
	[storageClient fetchQueues];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.storageList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
    
	if ([self.navigationItem.title hasSuffix:@"Table"])
	{
		cell.textLabel.text = [self.storageList objectAtIndex:indexPath.row];
	}
	else if ([self.navigationItem.title hasSuffix:@"Container"])
	{
		WABlobContainer *container = [self.storageList objectAtIndex:indexPath.row];
		cell.textLabel.text = container.name;
	}
	else if ([self.navigationItem.title hasSuffix:@"Blob"])
	{
		WABlob *blob = [self.storageList objectAtIndex:indexPath.row];
		cell.textLabel.text = blob.name;
	}
	else if ([self.navigationItem.title hasSuffix:@"Queue"])
	{
		WAQueue *queue = [self.storageList objectAtIndex:indexPath.row];
		cell.textLabel.text = queue.queueName;
	}
	
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	deleteButton.enabled = YES;
}
@end

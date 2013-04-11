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

#import "ModifyTableController.h"
#import "CreateTableController.h"
#import "DeleteTableController.h"

@implementation ModifyTableController

@synthesize createButton;
@synthesize deleteButton;
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
	[createButton release];
	[deleteButton release];
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

- (void)viewWillAppear:(BOOL)animated
{

	if ([self.navigationItem.title hasSuffix:@"Tables"])
	{
		self.createButton.titleLabel.text = @"Create Table";
		self.deleteButton.titleLabel.text = @"Delete Table";
	}
	else if ([self.navigationItem.title hasSuffix:@"Containers"])
	{
		self.createButton.titleLabel.text = @"Create Container";
		self.deleteButton.titleLabel.text = @"Delete Container";
	}
	else if ([self.navigationItem.title hasSuffix:@"Blobs"])
	{
		self.createButton.titleLabel.text = @"Create Blob";
		self.deleteButton.titleLabel.text = @"Delete Blob";
	}
	else if ([self.navigationItem.title hasSuffix:@"Queues"])
	{
		self.createButton.titleLabel.text = @"Create Queue";
		self.deleteButton.titleLabel.text = @"Delete Queue";
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)createItem:(id)sender
{
	
	CreateTableController *newController = [[CreateTableController alloc] initWithNibName:@"CreateTableController" bundle:nil];
	
	if ([self.navigationItem.title hasSuffix:@"Tables"])
	{
		newController.navigationItem.title = @"Create Table";
	}
	else if ([self.navigationItem.title hasSuffix:@"Containers"])
	{
		newController.navigationItem.title = @"Create Container";
	}
	else if ([self.navigationItem.title hasSuffix:@"Blobs"])
	{
		newController.navigationItem.title = @"Create Blob";
		newController.selectedContainer = self.selectedContainer;
	}
	else if ([self.navigationItem.title hasSuffix:@"Queues"])
	{
		newController.navigationItem.title = @"Create Queue";
		newController.selectedQueue = self.selectedQueue;
	}
	[self.navigationController pushViewController:newController animated:YES];
	[newController release];
}

- (IBAction)deleteItem:(id)sender
{
	
	DeleteTableController *newController = [[DeleteTableController alloc] initWithNibName:@"DeleteTableController" bundle:nil];
	
	if ([self.navigationItem.title hasSuffix:@"Tables"])
	{
		newController.navigationItem.title = @"Delete Table";
	}
	else if ([self.navigationItem.title hasSuffix:@"Containers"])
	{
		newController.navigationItem.title = @"Delete Container";
	}
	else if ([self.navigationItem.title hasSuffix:@"Blobs"])
	{
		newController.navigationItem.title = @"Delete Blob";
		newController.selectedContainer = self.selectedContainer;
	}
	else if ([self.navigationItem.title hasSuffix:@"Queues"])
	{
		newController.navigationItem.title = @"Delete Queue";
		newController.selectedQueue = self.selectedQueue;
	}
	[self.navigationController pushViewController:newController animated:YES];
	[newController release];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	
    [super viewDidLoad];
	
	self.createButton.titleLabel.textAlignment = UITextAlignmentCenter;
	self.deleteButton.titleLabel.textAlignment = UITextAlignmentCenter;
}

- (void)viewDidUnload
{
	[self setCreateButton:nil];
	[self setDeleteButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

@end

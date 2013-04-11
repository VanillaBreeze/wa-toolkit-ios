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

#import <UIKit/UIKit.h>
#import "WACloudStorageClient.h"
#import "WABlobContainer.h"
#import "WAQueue.h"

@interface DeleteTableController : UIViewController <UITableViewDataSource, UITableViewDelegate, WACloudStorageClientDelegate>
{
    
	UITableView *listTableView;
	UIButton *deleteButton;

	WACloudStorageClient		*storageClient;
	
	NSArray						*storageList;
	WABlobContainer				*selectedContainer;
	WAQueue						*selectedQueue;
	}
@property (nonatomic, retain) IBOutlet UITableView *listTableView;
@property (nonatomic, retain) IBOutlet UIButton *deleteButton;
@property (nonatomic, retain) NSArray *storageList;
@property (nonatomic, retain) WABlobContainer *selectedContainer;
@property (nonatomic, retain) WAQueue *selectedQueue;
- (IBAction)deleteItem:(id)sender;
@end

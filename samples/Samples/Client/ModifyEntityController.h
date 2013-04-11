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

@interface ModifyEntityController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WACloudStorageClientDelegate>{
@private
	UITableView *entityTable;
	UIButton *addUpdateButton;
	UIButton *deleteButton;
	WACloudStorageClient *storageClient;
	WATableEntity *entity;
	WAQueueMessage *queueMessage;
	NSString *queueName;
	NSMutableArray *editFields;
	int editingRow;
	int mode;
	NSString *messageString;
}
@property (nonatomic, retain) IBOutlet UITableView *entityTable;
@property (nonatomic, retain) IBOutlet UIButton *addUpdateButton;
@property (nonatomic, retain) IBOutlet UIButton *deleteButton;
@property (nonatomic, retain) WATableEntity *entity;
@property (nonatomic, retain) WAQueueMessage *queueMessage;
@property (nonatomic, retain) NSString *queueName;
@property (nonatomic, retain) NSString *messageString;

- (IBAction)addUpdate:(id)sender;
- (IBAction)delete:(id)sender;
@end

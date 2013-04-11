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
#import "WABlobContainer.h"
#import "WAQueue.h"

@interface ModifyTableController : UIViewController
{
    
	UIButton *createButton;
	UIButton *deleteButton;

	WABlobContainer			*selectedContainer;
	WAQueue					*selectedQueue;
}
@property (nonatomic, retain) IBOutlet UIButton *createButton;
@property (nonatomic, retain) IBOutlet UIButton *deleteButton;
@property (nonatomic, retain) WABlobContainer *selectedContainer;
@property (nonatomic, retain) WAQueue *selectedQueue;
- (IBAction)createItem:(id)sender;
- (IBAction)deleteItem:(id)sender;
@end

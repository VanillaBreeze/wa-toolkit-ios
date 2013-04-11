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

#import "WALocationControllerDelegate.h"

@class WABlobTweet;
@class WABitlyCredential;
@class WALocationHandler;

@interface WAMainViewController : UITableViewController <UINavigationControllerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate, WALocationHandlerDelegate, UIActionSheetDelegate> {
@private
    WABlobTweet *_blobTweet;
    WABitlyCredential *_bitlyCredential;
    WALocationHandler *_locationHandler;
    WAAuthenticationCredential *_authenticationCredential;
}

@property (weak, nonatomic) IBOutlet UITextField *containerNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *blobNameTextField;

- (IBAction)selectImage:(id)sender;
- (IBAction)tweetBlob:(id)sender;
@end

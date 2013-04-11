//
//  FacebookSampleViewController.h
//  FacebookSample
//
//  Created by Scott Densmore on 11/27/11.
//  Copyright 2011 Scott Densmore. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FacebookSampleViewController : UIViewController {
@private
    WACloudAccessToken *_token;
}

@property (assign, nonatomic) IBOutlet UIButton *loginButton;

@property (assign, nonatomic) IBOutlet UIButton *friendsButton;

@property (assign, nonatomic) IBOutlet UILabel *friendLabel;

- (IBAction)login:(id)sender;
- (IBAction)friends:(id)sender;
@end

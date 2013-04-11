//
//  FacebookSampleAppDelegate.h
//  FacebookSample
//
//  Created by Scott Densmore on 11/27/11.
//  Copyright 2011 Scott Densmore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FacebookSampleViewController;

@interface FacebookSampleAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet FacebookSampleViewController *viewController;

@end

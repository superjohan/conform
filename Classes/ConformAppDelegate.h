//
//  ConformAppDelegate.h
//  conform
//
//  Created by Johan Halin on 13.11.2010.
//  Copyright (c) 2013 Aero Deko. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ConformViewController;

@interface ConformAppDelegate : NSObject <UIApplicationDelegate>
@property (nonatomic) UIWindow *window;
@property (nonatomic) ConformViewController *viewController;
@end


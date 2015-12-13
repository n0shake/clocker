//
//  RootViewController.h
//  FeedbackDemo
//
//  Created by Andrew Wooster on 3/18/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UITableViewController {
	NSSet *tags;
}
- (IBAction)showFeedback:(id)sender;
- (IBAction)showRating:(id)sender;
@end

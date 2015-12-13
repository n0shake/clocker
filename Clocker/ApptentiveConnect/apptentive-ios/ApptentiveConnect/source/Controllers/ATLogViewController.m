//
//  ATLogViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/6/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATLogViewController.h"

#import "ATLogger.h"
#import "ATTaskQueue.h"

@implementation ATLogViewController
@synthesize textView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
	return self;
}

- (void)dealloc {
	[textView removeFromSuperview];
	[textView release], textView = nil;
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	textView = [[UITextView alloc] initWithFrame:self.view.bounds];
	textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	textView.delegate = self;
	textView.showsHorizontalScrollIndicator = YES;
	[self.view addSubview:textView];
	
	self.navigationItem.title = @"Debug Logs";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadLogs:)];
	
	ATLogInfo(@"%@", [[ATTaskQueue sharedTaskQueue] queueDescription]);
	
	self.textView.text = [[ATLogger sharedLogger] currentLogText];
	self.textView.editable = NO;
	[self performSelector:@selector(reloadLogs:) withObject:nil afterDelay:0.1];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	[textView removeFromSuperview];
	[textView release], textView = nil;
}

- (void)done:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)reloadLogs:(id)sender {
	self.textView.text = [[ATLogger sharedLogger] currentLogText];
	[self.textView scrollRangeToVisible:NSMakeRange([[self.textView text] length] - 1, 1)];
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	return NO;
}
@end

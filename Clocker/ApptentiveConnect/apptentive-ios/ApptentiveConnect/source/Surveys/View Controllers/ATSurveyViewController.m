//
//  ATSurveyViewController.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveyViewController.h"
#import "ATConnect.h"
#import "ATHUDView.h"
#import "ATRecordTask.h"
#import "ATSurvey.h"
#import "ATSurveys.h"
#import "ATSurveysBackend.h"
#import "ATSurveyMetrics.h"
#import "ATSurveyQuestion.h"
#import "ATSurveyResponse.h"
#import "ATTaskQueue.h"

#define DEBUG_CELL_HEIGHT_PROBLEM 0

enum {
	kTextViewTag = 1
};

@interface ATSurveyViewController (Private)
- (void)sendNotificationAboutTextViewQuestion:(ATSurveyQuestion *)question;
- (ATSurveyQuestion *)questionAtIndexPath:(NSIndexPath *)path;
- (BOOL)questionHasExtraInfo:(ATSurveyQuestion *)question;
- (BOOL)validateSurvey;
- (void)cancel:(id)sender;

- (BOOL)sizeTextView:(ATCellTextView *)textView;

#pragma mark Keyboard Handling
- (void)registerForKeyboardNotifications;
- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWillBeHidden:(NSNotification*)aNotification;
@end

@implementation ATSurveyViewController
@synthesize errorText;

- (id)initWithSurvey:(ATSurvey *)aSurvey {
	if ((self = [super init])) {
		startedSurveyDate = [[NSDate alloc] init];
		survey = [aSurvey retain];
		sentNotificationsAboutQuestionIDs = [[NSMutableSet alloc] init];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if (tableView) {
		[tableView removeFromSuperview];
		tableView.delegate = nil;
		tableView.dataSource = nil;
		[tableView release], tableView = nil;
	}
	[activeTextEntryCell release], activeTextEntryCell = nil;
	[activeTextView release], activeTextView = nil;
	[survey release], survey = nil;
	[errorText release], errorText = nil;
	[sentNotificationsAboutQuestionIDs release], sentNotificationsAboutQuestionIDs = nil;
	[startedSurveyDate release], startedSurveyDate = nil;
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (IBAction)sendSurvey {
	// Send text view notification, if applicable.
	if (activeTextView) {
		ATCellTextView *ctv = activeTextView;
		ATSurveyQuestion *question = ctv.question;
		
		if (question) {
			ctv.question.answerText = ctv.text;
			[self sendNotificationAboutTextViewQuestion:question];
		}
	}
	
	ATSurveyResponse *response = [[ATSurveyResponse alloc] init];
	NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:startedSurveyDate];
	if (interval > 0) {
		response.completionSeconds = (NSUInteger)interval;
	}
	response.identifier = survey.identifier;
	for (ATSurveyQuestion *question in [survey questions]) {
		if (question.type == ATSurveyQuestionTypeSingeLine) {
			ATSurveyQuestionResponse *answer = [[ATSurveyQuestionResponse alloc] init];
			answer.identifier = question.identifier;
			answer.response = question.answerText;
			[response addQuestionResponse:answer];
			[answer release], answer = nil;
		} else if (question.type == ATSurveyQuestionTypeMultipleChoice) {
			if ([question.selectedAnswerChoices count]) {
				ATSurveyQuestionAnswer *selectedAnswer = [question.selectedAnswerChoices objectAtIndex:0];
				ATSurveyQuestionResponse *answer = [[ATSurveyQuestionResponse alloc] init];
				answer.identifier = question.identifier;
				answer.response = selectedAnswer.identifier;
				[response addQuestionResponse:answer];
				[answer release], answer = nil;
			}
		} else if (question.type == ATSurveyQuestionTypeMultipleSelect) {
			if ([question.selectedAnswerChoices count]) {
				ATSurveyQuestionResponse *answer = [[ATSurveyQuestionResponse alloc] init];
				answer.identifier = question.identifier;
				NSMutableArray *responses = [NSMutableArray array];
				for (ATSurveyQuestionAnswer *selectedAnswer in question.selectedAnswerChoices) {
					[responses addObject:selectedAnswer.identifier];
				}
				answer.response = responses;
				[response addQuestionResponse:answer];
				[answer release], answer = nil;
			}
		}
	}
	
	ATRecordTask *task = [[ATRecordTask alloc] init];
	[task setRecord:response];
	[[ATTaskQueue sharedTaskQueue] addTask:task];
	[response release], response = nil;
	[task release], task = nil;
	
	if (!survey.successMessage) {
		ATHUDView *hud = [[ATHUDView alloc] initWithWindow:self.view.window];
		hud.label.text = ATLocalizedString(@"Thanks!", @"Text in thank you display upon submitting survey.");
		hud.fadeOutDuration = 5.0;
		[hud show];
		[hud autorelease];
	} else {
		UIAlertView *successAlert = [[[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Thanks!", @"Text in thank you display upon submitting survey.") message:survey.successMessage delegate:nil cancelButtonTitle:ATLocalizedString(@"Okay", @"Okay button title") otherButtonTitles:nil] autorelease];
		[successAlert show];
	}
	
	NSDictionary *notificationInfo = [[NSDictionary alloc] initWithObjectsAndKeys:survey.identifier, ATSurveyIDKey, nil];
	NSDictionary *metricsInfo = [[NSDictionary alloc] initWithObjectsAndKeys:survey.identifier, ATSurveyMetricsSurveyIDKey, [NSNumber numberWithInt:ATSurveyWindowTypeSurvey], ATSurveyWindowTypeKey, [NSNumber numberWithInt:ATSurveyEventTappedSend], ATSurveyMetricsEventKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidHideWindowNotification object:nil userInfo:metricsInfo];
	[metricsInfo release], metricsInfo = nil;
	
	
	[[ATSurveysBackend sharedBackend] setDidSendSurvey:survey];
	[[ATSurveysBackend sharedBackend] resetSurvey];
	[self.navigationController dismissModalViewControllerAnimated:YES];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveySentNotification object:nil userInfo:notificationInfo];
	[notificationInfo release], notificationInfo = nil;
}

- (void)loadView {
	[super loadView];
	self.view.backgroundColor = [UIColor whiteColor];
	tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;	
	[self.view addSubview:tableView];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if (![survey responseIsRequired]) {
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease];
	}
	
	self.title = ATLocalizedString(@"Survey", @"Survey view title");
	
	tableView.delegate = self;
	tableView.dataSource = self;
	[tableView reloadData];
	[self registerForKeyboardNotifications];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[tableView removeFromSuperview];
	tableView.delegate = nil;
	tableView.dataSource = nil;
	[tableView release], tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	if (activeTextView != nil) {
		
	}
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	return [[survey questions] count] + 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	if (section < [[survey questions] count]) {
		NSUInteger result = 0;
		ATSurveyQuestion *question = [[survey questions] objectAtIndex:section];
		if (question.type == ATSurveyQuestionTypeSingeLine) {
			result = 2;
		} else if (question.type == ATSurveyQuestionTypeMultipleChoice || question.type == ATSurveyQuestionTypeMultipleSelect) {
			result = [[question answerChoices] count] + 1;
		}
		if ([self questionHasExtraInfo:question]) {
			result++;
		}
		return result;
	} else if (section == [[survey questions] count]) {
		return 1;
	}
	return 0;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	ATCellTextView *textViewCell = (ATCellTextView *)[cell viewWithTag:kTextViewTag];
	CGFloat cellHeight = 0;
	if (textViewCell != nil) {
		CGSize cellSize = CGSizeMake(textViewCell.bounds.size.width, textViewCell.bounds.size.height + 20);
		CGRect f = textViewCell.frame;
		f.origin.y = 10.0;
		textViewCell.frame = f;
		cellHeight = MAX(44, cellSize.height);
	} else if (cell.textLabel.text != nil) {
		UIFont *font = cell.textLabel.font;
		
		if (indexPath.row == 0) {
			CGRect textFrame = cell.textLabel.frame;
			textFrame.size.width = cell.frame.size.width - 38.0;
			cell.textLabel.frame = textFrame;
#if DEBUG_CELL_HEIGHT_PROBLEM
			ATLogDebug(@"%@", NSStringFromCGRect(cell.textLabel.frame));
#endif
		}
		
		CGSize cellSize = CGSizeMake(cell.textLabel.bounds.size.width, 1024);
		UILineBreakMode lbm = cell.textLabel.lineBreakMode;
		CGSize s = [cell.textLabel.text sizeWithFont:font constrainedToSize:cellSize lineBreakMode:lbm];
		CGRect f = cell.textLabel.frame;
		f.size = s;
#if DEBUG_CELL_HEIGHT_PROBLEM
		if (s.height >= 50) {
			ATLogDebug(@"cell width is: %f", cell.frame.size.width);
			ATLogDebug(@"width is: %f", cellSize.width);
			ATLogDebug(@"Hi");
		}
#endif
		
		ATSurveyQuestion *question = [self questionAtIndexPath:indexPath];
		if (question != nil && indexPath.row == 1 && [self questionHasExtraInfo:question]) {
			f.origin.y = 4;
			cell.textLabel.frame = f;
			cellHeight = MAX(32, s.height + 8);
		} else {
			f.origin.y = 10;
			cell.textLabel.frame = f;
			cellHeight = MAX(44, s.height + 20);
		}
	} else {
		cellHeight = 44;
	}
	return cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *ATSurveyExtraInfoCellIdentifier = @"ATSurveyExtraInfoCellIdentifier";
	static NSString *ATSurveyCheckboxCellIdentifier = @"ATSurveyCheckboxCellIdentifier";
	static NSString *ATSurveyTextViewCellIdentifier = @"ATSurveyTextViewCellIdentifier";
	static NSString *ATSurveyQuestionCellIdentifier = @"ATSurveyQuestionCellIdentifier";
	static NSString *ATSurveySendCellIdentifier = @"ATSurveySendCellIdentifier";
	
	if (indexPath.section == [[survey questions] count]) {
		UITableViewCell *buttonCell = nil;
		buttonCell = [tableView dequeueReusableCellWithIdentifier:ATSurveySendCellIdentifier];
		if (!buttonCell) {
			buttonCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveySendCellIdentifier] autorelease];
			buttonCell.textLabel.text = ATLocalizedString(@"Send Response", @"Survey send response button title");
			buttonCell.textLabel.textAlignment = UITextAlignmentCenter;
			buttonCell.textLabel.textColor = [UIColor blueColor];
			buttonCell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		return buttonCell;
	} else if (indexPath.section >= [[survey questions] count]) {
		return nil;
	}
	ATSurveyQuestion *question = [self questionAtIndexPath:indexPath];
	UITableViewCell *cell = nil;
	if (indexPath.row == 0) {
		// Show the question row.
		cell = [tableView dequeueReusableCellWithIdentifier:ATSurveyQuestionCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyQuestionCellIdentifier] autorelease];
			cell.textLabel.numberOfLines = 0;
			cell.textLabel.adjustsFontSizeToFitWidth = NO;
			cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
			cell.backgroundColor = [UIColor colorWithRed:223/255. green:235/255. blue:247/255. alpha:1.0];
#if DEBUG_CELL_HEIGHT_PROBLEM
			cell.textLabel.backgroundColor = [UIColor redColor];
#endif
			cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
		}
		cell.textLabel.text = question.questionText;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell layoutIfNeeded];
	} else if (indexPath.row == 1 && [self questionHasExtraInfo:question]) {
		cell = [tableView dequeueReusableCellWithIdentifier:ATSurveyExtraInfoCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyExtraInfoCellIdentifier] autorelease];
			cell.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.textLabel.font = [UIFont systemFontOfSize:15];
			cell.textLabel.numberOfLines = 0;
			cell.textLabel.adjustsFontSizeToFitWidth = NO;
			cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
		}
		NSString *text = nil;
		if (question.instructionsText) {
			if ([question.instructionsText length]) {
				text = question.instructionsText;
			}
		} else if (question.responseIsRequired) {
			text = ATLocalizedString(@"(required)", @"Survey required answer fallback label.");
		}
		cell.textLabel.text = text;
		[cell layoutSubviews];
	} else {
		NSUInteger answerIndex = indexPath.row - 1;
		if ([self questionHasExtraInfo:question]) {
			answerIndex = answerIndex - 1;
		}
		
		if (question.type == ATSurveyQuestionTypeMultipleChoice || question.type == ATSurveyQuestionTypeMultipleSelect) {
			ATSurveyQuestionAnswer *answer = [question.answerChoices objectAtIndex:answerIndex];
			// Make a checkbox cell.
			cell = [tableView dequeueReusableCellWithIdentifier:ATSurveyCheckboxCellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyCheckboxCellIdentifier] autorelease];
			}
			cell.textLabel.font = [UIFont systemFontOfSize:18];
			cell.textLabel.text = answer.value;
			cell.textLabel.numberOfLines = 0;
			cell.textLabel.adjustsFontSizeToFitWidth = NO;
			cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
			if ([[question selectedAnswerChoices] containsObject:answer]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			} else {
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			[cell layoutSubviews];
		} else {
			// Make a text entry cell.
			if (activeTextView != nil && activeTextEntryCell != nil && activeTextView.cellPath.row == indexPath.row && activeTextView.cellPath.section == indexPath.section) {
				cell = activeTextEntryCell;
			} else {
				cell = [tableView dequeueReusableCellWithIdentifier:ATSurveyTextViewCellIdentifier];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyTextViewCellIdentifier] autorelease];
					ATCellTextView *textView = [[ATCellTextView alloc] initWithFrame:CGRectInset(cell.contentView.bounds, 10.0, 10.0)];
					textView.font = [UIFont systemFontOfSize:16];
					textView.backgroundColor = [UIColor clearColor];
					textView.tag = kTextViewTag;
					textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
					[cell.contentView addSubview:textView];
					textView.returnKeyType = UIReturnKeyDone;
					[textView release], textView = nil;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
				}
			}
			
			ATCellTextView *textView = (ATCellTextView *)[cell viewWithTag:kTextViewTag];
			textView.cellPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
			textView.placeholder = ATLocalizedString(@"Answer", @"Answer label");
			textView.delegate = self;
			textView.question = question;
			if (question.answerText != nil) {
				textView.text = question.answerText;
			}
			//[textView sizeToFit];
			[self sizeTextView:textView];
			/*
			 CGRect cellFrame = cell.frame;
			 cellFrame.size.height = textView.frame.size.height + 20.0;
			 cell.frame = cellFrame;
			 */
		}
	}
	
	return cell;
}

#pragma mark UITableViewDelegate

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	if ([survey surveyDescription] != nil && section == 0) {
		return [survey surveyDescription];
	}
	return nil;
}

- (NSString *)tableView:(UITableView *)aTableView titleForFooterInSection:(NSInteger)section {
	if (section == [[survey questions] count] && errorText != nil) {
		return errorText;
	}
	return nil;
}

- (void)scrollToBottom {
	if (tableView) {
		NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:[[survey questions] count]];
		[tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
	}
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == [[survey questions] count]) {
		if ([self validateSurvey]) {
			[self sendSurvey];
		} else {
			[tableView reloadData];
			[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.1];
		}
	} else {
		ATSurveyQuestion *question = [self questionAtIndexPath:indexPath];
		UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
		if (indexPath.row == 0) {
			// Question row.
		} else if ([self questionHasExtraInfo:question] && indexPath.row == 1) {
			
		} else {
			NSUInteger answerIndex = indexPath.row - 1;
			if ([self questionHasExtraInfo:question]) {
				answerIndex = answerIndex - 1;
			}
			if (question.type == ATSurveyQuestionTypeMultipleChoice || question.type == ATSurveyQuestionTypeMultipleSelect) {
				ATSurveyQuestionAnswer *answer = [question.answerChoices objectAtIndex:answerIndex];
				BOOL isChecked = cell.accessoryType == UITableViewCellAccessoryCheckmark;
				
				NSUInteger maxSelections = question.maxSelectionCount;
				if (maxSelections == 0) {
					maxSelections = NSUIntegerMax;
				}
				if (isChecked == NO && question.type == ATSurveyQuestionTypeMultipleSelect && [[question selectedAnswerChoices] count] == maxSelections) {
					// Do nothing if unchecked and have already selected the maximum number of answers.
				} else if (isChecked == NO) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
					[question addSelectedAnswerChoice:answer];
				} else if (isChecked == YES) {
					cell.accessoryType = UITableViewCellAccessoryNone;
					[question removeSelectedAnswerChoice:answer];
				}
				// Deselect the other cells.
				if (question.type == ATSurveyQuestionTypeMultipleChoice) {
					UITableViewCell *otherCell = nil;
					for (NSUInteger i = 1; i < [self tableView:aTableView numberOfRowsInSection:indexPath.section]; i++) {
						if (i != indexPath.row) {
							NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
							otherCell = [aTableView cellForRowAtIndexPath:path];
							otherCell.accessoryType = UITableViewCellAccessoryNone;
						}
					}
				}
				
				// Send notification.
				NSDictionary *metricsInfo = [[NSDictionary alloc] initWithObjectsAndKeys:survey.identifier, ATSurveyMetricsSurveyIDKey, question.identifier, ATSurveyMetricsSurveyQuestionIDKey, [NSNumber numberWithInt:ATSurveyEventAnsweredQuestion], ATSurveyMetricsEventKey, nil];
				[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidAnswerQuestionNotification object:nil userInfo:metricsInfo];
				[metricsInfo release], metricsInfo = nil;
			} else if (question.type == ATSurveyQuestionTypeSingeLine) {
				ATCellTextView *textView = (ATCellTextView *)[cell viewWithTag:kTextViewTag];
				[textView becomeFirstResponder];
			}
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if ([text isEqualToString:@"\n"]) {
		[textView resignFirstResponder];
		return NO;
	}
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
	if ([textView isKindOfClass:[ATCellTextView class]]) {
		ATCellTextView *ctv = (ATCellTextView *)textView;
		ctv.question.answerText = ctv.text;
	}
	
	if ([self sizeTextView:(ATCellTextView *)textView]) {
		[tableView beginUpdates];
		[tableView endUpdates];
		[tableView scrollRectToVisible:CGRectInset(activeTextEntryCell.frame, 0, -10) animated:YES];
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	[textView flashScrollIndicators];
	[activeTextEntryCell release], activeTextEntryCell = nil;
	[activeTextView release], activeTextView = nil;
	activeTextView = (ATCellTextView *)[textView retain];
	activeTextEntryCell = [(UITableViewCell *)activeTextView.superview.superview retain];
	[tableView scrollRectToVisible:textView.superview.superview.frame animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	if ([textView isKindOfClass:[ATCellTextView class]]) {
		ATCellTextView *ctv = (ATCellTextView *)textView;
		ATSurveyQuestion *question = ctv.question;
		
		if (question) {
			ctv.question.answerText = ctv.text;
			[self sendNotificationAboutTextViewQuestion:question];
		}
	}
	[activeTextEntryCell release], activeTextEntryCell = nil;
	[activeTextView release], activeTextView = nil;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	[textView resignFirstResponder];
	return YES;
}
@end

@implementation ATSurveyViewController (Private)
- (void)sendNotificationAboutTextViewQuestion:(ATSurveyQuestion *)question {
	if (!question.type == ATSurveyQuestionTypeSingeLine) {
		return;
	}
	
	// Send notification.
	if (![sentNotificationsAboutQuestionIDs containsObject:question.identifier]) {
		NSDictionary *metricsInfo = [[NSDictionary alloc] initWithObjectsAndKeys:survey.identifier, ATSurveyMetricsSurveyIDKey, question.identifier, ATSurveyMetricsSurveyQuestionIDKey, [NSNumber numberWithInt:ATSurveyEventAnsweredQuestion], ATSurveyMetricsEventKey, nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidAnswerQuestionNotification object:nil userInfo:metricsInfo];
		[metricsInfo release], metricsInfo = nil;
		
		[sentNotificationsAboutQuestionIDs addObject:question.identifier];
	}
}


- (ATSurveyQuestion *)questionAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section >= [[survey questions] count]) {
		return nil;
	}
	return [[survey questions] objectAtIndex:indexPath.section];
}

- (BOOL)questionHasExtraInfo:(ATSurveyQuestion *)question {
	BOOL result = NO;
	if (question.responseIsRequired) {
		result = YES;
	} else if (question.type == ATSurveyQuestionTypeMultipleSelect) {
		result = YES;
	} else if (question.type == ATSurveyQuestionTypeMultipleChoice) {
		result = YES;
	}
	return result;
}

- (BOOL)validateSurvey {
	BOOL valid = YES;
	NSUInteger missingAnswerCount = 0;
	NSUInteger tooFewAnswersCount = 0;
	NSUInteger tooManyAnswersCount = 0;
	for (ATSurveyQuestion *question in [survey questions]) {
		ATSurveyQuestionValidationErrorType error = [question validateAnswer];
		if (error == ATSurveyQuestionValidationErrorMissingRequiredAnswer) {
			missingAnswerCount++;
			valid = NO;
		} else if (error == ATSurveyQuestionValidationErrorTooFewAnswers) {
			tooFewAnswersCount++;
			valid = NO;
		} else if (error == ATSurveyQuestionValidationErrorTooManyAnswers) {
			tooManyAnswersCount++;
			valid = NO;
		}
	}
	if (valid) {
		self.errorText = nil;
	} else {
		if (missingAnswerCount == 1) {
			self.errorText = ATLocalizedString(@"Missing a required answer.", @"Survey missing required answer label.");
		} else if (missingAnswerCount > 1) {
			self.errorText = [NSString stringWithFormat:ATLocalizedString(@"Missing %d required answers.", @"Survey missing required answers formatted label."), missingAnswerCount];
		} else if (tooFewAnswersCount == 1) {
			self.errorText = ATLocalizedString(@"Too few selections made for a question above.", @"Survey too few selections label.");
		} else if (tooFewAnswersCount > 1) {
			self.errorText = [NSString stringWithFormat:ATLocalizedString(@"Too few selections made for %d questions above.", @"Survey too few selections formatted label."), tooFewAnswersCount];
		} else if (tooManyAnswersCount == 1) {
			self.errorText = ATLocalizedString(@"Too many selections made for a question above.", @"Survey too many selections label.");
		} else if (tooManyAnswersCount > 1) {
			self.errorText = [NSString stringWithFormat:ATLocalizedString(@"Too many selections made for %d questions above.", @"Survey too many selections formatted label."), tooFewAnswersCount];
		}
	}
	return valid;
}

- (BOOL)sizeTextView:(ATCellTextView *)textView {
	BOOL didChange = NO;
	CGRect f = textView.frame;
	CGFloat originalHeight = f.size.height;
	CGSize maxSize = CGSizeMake(f.size.width, 150);
	//	CGSize sizeThatFits = [textView.text sizeWithFont:textView.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
	CGSize sizeThatFits = [textView sizeThatFits:maxSize];
	if (originalHeight != sizeThatFits.height) {
		//		NSLog(@"old: %f, new: %f", originalHeight, sizeThatFits.height);
		f.size.height = sizeThatFits.height;
		textView.frame = f;
		didChange = YES;
	}
	return didChange;
}

- (void)cancel:(id)sender {
	NSDictionary *metricsInfo = [[NSDictionary alloc] initWithObjectsAndKeys:survey.identifier, ATSurveyMetricsSurveyIDKey, [NSNumber numberWithInt:ATSurveyWindowTypeSurvey], ATSurveyWindowTypeKey, [NSNumber numberWithInt:ATSurveyEventTappedCancel], ATSurveyMetricsEventKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidHideWindowNotification object:nil userInfo:metricsInfo];
	[metricsInfo release], metricsInfo = nil;
	
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark Keyboard Handling
- (void)registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
	NSDictionary* info = [aNotification userInfo];
	CGRect kbFrame = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGRect kbAdjustedFrame = [tableView.window convertRect:kbFrame toView:tableView];
	CGSize kbSize = kbAdjustedFrame.size;
	
	UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
	tableView.contentInset = contentInsets;
	tableView.scrollIndicatorInsets = contentInsets;
	
	// If active text field is hidden by keyboard, scroll it so it's visible
	if (activeTextView != nil && activeTextEntryCell) {
		CGRect aRect = tableView.frame;
		aRect.size.height -= kbSize.height;
		CGRect r = [activeTextEntryCell convertRect:activeTextView.frame toView:tableView];
		if (!CGRectContainsPoint(aRect, r.origin) ) {
			[activeTextView becomeFirstResponder];
			[tableView scrollRectToVisible:CGRectInset(activeTextEntryCell.frame, 0, -10) animated:YES];
			//			CGPoint scrollPoint = CGPointMake(0.0, r.origin.y - kbSize.height);
			//			[tableView setContentOffset:scrollPoint animated:YES];
		}
	}
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:[duration floatValue]];
	[UIView setAnimationCurve:[curve intValue]];
	UIEdgeInsets contentInsets = UIEdgeInsetsZero;
	tableView.contentInset = contentInsets;
	tableView.scrollIndicatorInsets = contentInsets;
	[UIView commitAnimations];
}
@end

@implementation ATCellTextView
@synthesize cellPath, question;
- (void)dealloc {
	[cellPath release], cellPath = nil;
	[question release], question = nil;
	[super dealloc];
}
@end

//  Created by Abhishek Banthia on 11/4/15.
//  Copyright (c) 2015 Abhishek Banthia All rights reserved.
//

// Copyright (c) 2015, Abhishek Banthia
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "BackgroundView.h"
#import "StatusItemView.h"
#import "CLOneWindowController.h"

@class PanelController;
@class CLTimezoneData;

@protocol PanelControllerDelegate <NSObject>

@optional

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;

@end

#pragma mark -

@interface PanelController : NSWindowController <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
    BOOL _hasActivePanel;
    __unsafe_unretained BackgroundView *_backgroundView;
    __unsafe_unretained id<PanelControllerDelegate> _delegate;
    __unsafe_unretained NSSearchField *_searchField;
    __unsafe_unretained NSTextField *_textField;
}


@property (nonatomic, strong) CLOneWindowController *oneWindow;
@property (nonatomic, strong) NSMutableArray *defaultPreferences;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, assign) NSInteger futureSliderValue;
@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic) BOOL showReviewCell;
@property (nonatomic, unsafe_unretained, readonly) id<PanelControllerDelegate> delegate;
@property (nonatomic, unsafe_unretained) IBOutlet BackgroundView *backgroundView;
@property (weak) IBOutlet NSTableView *mainTableview;
@property (weak) IBOutlet NSLayoutConstraint *scrollViewHeight;
@property (weak) IBOutlet NSButton *shutdownButton;
@property (weak) IBOutlet NSButton *preferencesButton;
@property (weak) IBOutlet NSSlider *futureSlider;
@property (weak) IBOutlet NSTextField *sliderLabel;
@property (strong, nonatomic) PanelController *panelWindow;
@property (strong, nonatomic) NSTimer *floatingWindowTimer;

+ (instancetype)sharedPanel;

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;
- (void)openPanel;
- (void)closePanel;
- (void)updateDefaultPreferences;
- (void)showOptions:(BOOL)value;
- (void)removeContextHelpForSlider;
- (void)updatePanelColor;
- (void)openAsFloatingWindow;

@end

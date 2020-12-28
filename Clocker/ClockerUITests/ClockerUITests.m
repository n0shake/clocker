// Copyright © 2015 Abhishek Banthia

#import <XCTest/XCTest.h>
#import "CommonStrings.h"

@interface ClockerUITests : XCTestCase

@property (strong) XCUIApplication *app;

@end

@implementation ClockerUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = YES;
    self.app = [[XCUIApplication alloc] init];
    [self.app launch];
    
    if (self.app.tables[@"FloatingTableView"].exists) {
        XCUIElement *floatingPinButton = self.app.buttons[@"FloatingPin"];
        [floatingPinButton click];
    }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/*
- (void)testChangingLabelFromPopover {
    
    XCUIElement *menuElement = [[self.app menuBars] elementBoundByIndex:1];
    [menuElement click];
    
    XCUIElement *cell = [self.app.tables[@"mainTableView"] cells].firstMatch;
    XCUIElement *originalField = cell.staticTexts[@"CustomNameLabelForCell"];
    NSString *originalFieldValue = originalField.value;
    [cell hover];

    NSLog(@"%@", cell.buttons.count);
    XCUIElement *extraOptionButton = cell.buttons[@"extraOptionButton"];
    [extraOptionButton click];
    
    XCUIElement *textField = self.app.textFields[@"CustomLabel"];
    [textField typeText:@"My Precious"];
    
    sleep(2);
    
    XCUIElement *verifyCell = self.app.tables[@"mainTableView"].cells.firstMatch;
    XCUIElement *newField = verifyCell.staticTexts[@"CustomNameLabelForCell"];
    NSString *newFieldValue = (NSString *)newField.value;
    
    XCTAssertTrue([newFieldValue isEqualToString:@"My Precious"]);
    
    [self reset:textField withText:originalFieldValue];
    
    sleep(2);
} */

- (void)testSettingAFavourite {
    
    XCUIElement *menuElement = [[self.app statusItems] firstMatch];
    [menuElement click];
    [self.app/*@START_MENU_TOKEN@*/.tables[@"mainTableView"]/*[[".dialogs",".scrollViews.tables[@\"mainTableView\"]",".tables[@\"mainTableView\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ typeKey:@"," modifierFlags:XCUIKeyModifierCommand];
    
    XCUIElement *clockerWindow = self.app.windows[@"Clocker"];
    
    if (clockerWindow.tables.count == 0) {
        XCTFail("We don't have any timezones added");
        return;
    }
    
    NSInteger rowQueryCount = [[clockerWindow.tables[@"TimezoneTableView"] tableRows] count];
    
    if (rowQueryCount == 0) {
        XCTFail("We don't have any timezones added");
        return;
    }
    
    XCUIElement *currentElement = [[clockerWindow.tables[@"TimezoneTableView"] tableRows] elementBoundByIndex:0];
    
    XCUIElement *favoriteCheckbox = [currentElement.checkBoxes elementBoundByIndex:0];
    [favoriteCheckbox click];
    
    sleep(2);

}

- (void)testChangingTo12Hour {
    
    XCUIElement *menuElement = [[self.app statusItems] firstMatch];
    [menuElement click];
    [self.app/*@START_MENU_TOKEN@*/.tables[@"mainTableView"]/*[[".dialogs",".scrollViews.tables[@\"mainTableView\"]",".tables[@\"mainTableView\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ typeKey:@"," modifierFlags:XCUIKeyModifierCommand];
    
    XCUIElement *appearance = [[self.app.toolbars buttons] elementBoundByIndex: 1];
    [appearance click];
    
    XCUIElement *timeFormat = [self.app.popUpButtons[@"TimeFormatPopover"] firstMatch];
    [timeFormat click]; // Open Time Format Popover
    XCUIElementQuery *const query = [[[timeFormat childrenMatchingType:XCUIElementTypeMenu] firstMatch] childrenMatchingType:0];
    [[query elementBoundByIndex:0] click]; // 0 is 12-Hour
 
    XCUIElementQuery *mainTableView = [[self.app.tables[@"mainTableView"] cells] staticTexts];
    NSPredicate *timeCells = [NSPredicate predicateWithFormat:@"identifier like 'ActualTime'"];
    XCUIElementQuery *elements = [mainTableView matchingPredicate:timeCells];
    
    for (NSInteger i = 0; i < elements.count; i++) {
        XCUIElement *currentElement = [elements elementBoundByIndex:i];
        NSString *currentTime = (NSString *)currentElement.value;
        XCTAssertTrue([currentTime containsString:@"AM"] || [currentTime containsString:@"PM"]);
    }
}

- (void)testChangingTo24Hour {
    
    XCUIElement *menuElement = [[self.app statusItems] firstMatch];
    [menuElement click];
    [self.app/*@START_MENU_TOKEN@*/.tables[@"mainTableView"]/*[[".dialogs",".scrollViews.tables[@\"mainTableView\"]",".tables[@\"mainTableView\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ typeKey:@"," modifierFlags:XCUIKeyModifierCommand];
    
    XCUIElement *appearance = [[self.app.toolbars buttons] elementBoundByIndex: 1];
    [appearance click];
    
    XCUIElement *timeFormat = self.app.popUpButtons[@"TimeFormatPopover"];
    [timeFormat click];
  XCUIElementQuery *const query = [[[timeFormat childrenMatchingType:XCUIElementTypeMenu] firstMatch] childrenMatchingType:0];
  [[query elementBoundByIndex:1] click]; // 1 is 24-Hour
    
    XCUIElementQuery *mainTableView = [[self.app.tables[@"mainTableView"] cells] staticTexts];
    
    NSPredicate *timeCells = [NSPredicate predicateWithFormat:@"identifier like 'ActualTime'"];
    XCUIElementQuery *elements = [mainTableView matchingPredicate:timeCells];
    
    for (NSInteger i = 0; i < elements.count; i++) {
        XCUIElement *currentElement = [elements elementBoundByIndex:i];
        NSString *currentTime = (NSString *)currentElement.value;
        XCTAssertFalse([currentTime containsString:@"AM"] || [currentTime containsString:@"PM"]);
    }
    
}

- (void)reset:(XCUIElement *)field withText:(NSString *)text {
    
    NSString *currentValue = (NSString *)field.value;
    
    for (NSInteger i = 0; i < currentValue.length; i++) {
         [field typeKey:XCUIKeyboardKeyDelete modifierFlags:XCUIKeyModifierNone];
    }
    
    [field typeText:text];
}

@end

// Copyright © 2015 Abhishek Banthia

import XCTest

@testable import Clocker

class ThemerTests: XCTestCase {
    private struct ThemeExpectations {
        // Colors
        let expectedSliderKnobColor: NSColor
        let expectedSliderRightColor: NSColor
        let expectedBackgroundColor: NSColor
        let expectedTextColor: NSColor
        let expectedTextBackgroundColor: NSColor
        // Popover Appearance
        let expectedPopoverApperarance: NSAppearance
        // Images
        let expectedShutdownImageName: String
        let expectedPreferenceImageName: String
        let expectedPinImageName: String
        let expectedSunriseImageName: String
        let expectedSunsetImageName: String
        let expectedRemoveImageName: String
        let expectedExtraOptionsImage: String
        let expectedMenubarOnboardingImage: String
        let expectedExtraOptionsHighlightedImage: String
        let expectedSharingImage: String
        let expectedCurrentLocationImage: String
        let expectedAddImage: String
        let expectedPrivacyTabImage: String
        let expectedAppearanceTabImage: String
        let expectedCalendarTabImage: String
        let expectedGeneralTabImage: String
        let expectedAboutTabImage: String
        let expectedVideoCallImage: String
        let expectedFilledTrashImage: String
        let expectedBackwardsImage: String
        let expectedForwardsImage: String
        let expectedResetSliderImage: String
    }
    
    @available(macOS 10.14, *)
    func testSettingTheme() {
        // Set to some random number should set to 0
        let subject = Themer(index: 124)
        XCTAssertEqual(NSAppearance(named: .aqua), NSAppearance(named: .aqua))
        
        // Set the same theme; this should return early
        subject.set(theme: 0)
        
        // Set the theme to dark theme
        subject.set(theme: 1)
        let expectedApperance = NSAppearance(named: .darkAqua)
        XCTAssertEqual(expectedApperance, NSApp.appearance)
    }
    
    func testLightTheme() throws {
        let subject = Themer(index: 0) // 0 is for light theme
        let expectedThemeElements = ThemeExpectations(expectedSliderKnobColor: NSColor(deviceRed: 255.0, green: 255.0, blue: 255, alpha: 0.9),
                                                      expectedSliderRightColor: NSColor.gray, expectedBackgroundColor: NSColor.white,
                                                      expectedTextColor: NSColor.black,
                                                      expectedTextBackgroundColor: NSColor(deviceRed: 241.0 / 255.0, green: 241.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0),
                                                      expectedPopoverApperarance: NSAppearance(named: NSAppearance.Name.vibrantLight)!,
                                                      expectedShutdownImageName: "ellipsis.circle",
                                                      expectedPreferenceImageName: "plus",
                                                      expectedPinImageName: "macwindow.on.rectangle",
                                                      expectedSunriseImageName: "sunrise.fill",
                                                      expectedSunsetImageName: "sunset.fill",
                                                      expectedRemoveImageName: "xmark",
                                                      expectedExtraOptionsImage: "Extra",
                                                      expectedMenubarOnboardingImage: "Light Menubar",
                                                      expectedExtraOptionsHighlightedImage: "ExtraHighlighted",
                                                      expectedSharingImage: "square.and.arrow.up.on.square.fill",
                                                      expectedCurrentLocationImage: "location.fill",
                                                      expectedAddImage: "plus",
                                                      expectedPrivacyTabImage: "lock",
                                                      expectedAppearanceTabImage: "eye",
                                                      expectedCalendarTabImage: "calendar",
                                                      expectedGeneralTabImage: "gearshape",
                                                      expectedAboutTabImage: "info.circle",
                                                      expectedVideoCallImage: "video.circle.fill",
                                                      expectedFilledTrashImage: "trash.fill",
                                                      expectedBackwardsImage: "gobackward.15",
                                                      expectedForwardsImage: "goforward.15",
                                                      expectedResetSliderImage: "xmark.circle.fill")
        testSubject(subject: subject, withExpectatations: expectedThemeElements)
    }
    
    func testDarkTheme() throws {
        let subject = Themer(index: 1) // 1 is for dark theme
        let expectedThemeElements = ThemeExpectations(expectedSliderKnobColor: NSColor(deviceRed: 0.0, green: 0.0, blue: 0, alpha: 0.9),
                                                      expectedSliderRightColor: NSColor.white,
                                                      expectedBackgroundColor: NSColor(deviceRed: 42.0 / 255.0, green: 42.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0),
                                                      expectedTextColor: NSColor.white,
                                                      expectedTextBackgroundColor: NSColor(deviceRed: 42.0 / 255.0, green: 55.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0),
                                                      expectedPopoverApperarance: NSAppearance(named: NSAppearance.Name.vibrantDark)!,
                                                      expectedShutdownImageName: "ellipsis.circle",
                                                      expectedPreferenceImageName: "plus",
                                                      expectedPinImageName: "macwindow.on.rectangle",
                                                      expectedSunriseImageName: "sunrise.fill",
                                                      expectedSunsetImageName: "sunset.fill",
                                                      expectedRemoveImageName: "xmark",
                                                      expectedExtraOptionsImage: "ExtraWhite",
                                                      expectedMenubarOnboardingImage: "Dark Menubar",
                                                      expectedExtraOptionsHighlightedImage: "ExtraWhiteHighlighted",
                                                      expectedSharingImage: "square.and.arrow.up.on.square.fill",
                                                      expectedCurrentLocationImage: "location.fill",
                                                      expectedAddImage: "plus",
                                                      expectedPrivacyTabImage: "lock",
                                                      expectedAppearanceTabImage: "eye",
                                                      expectedCalendarTabImage: "calendar",
                                                      expectedGeneralTabImage: "gearshape",
                                                      expectedAboutTabImage: "info.circle",
                                                      expectedVideoCallImage: "video.circle.fill",
                                                      expectedFilledTrashImage: "trash.fill",
                                                      expectedBackwardsImage: "gobackward.15",
                                                      expectedForwardsImage: "goforward.15",
                                                      expectedResetSliderImage: "xmark.circle.fill")
        testSubject(subject: subject, withExpectatations: expectedThemeElements)
        XCTAssertEqual(subject.description, "Current Theme is \(Themer.Theme.dark)")
    }
    
    func testSystemTheme() throws {
        let currentSystemTheme =
        UserDefaults.standard.string(forKey: CLAppleInterfaceStyleKey)?.lowercased().contains("dark") ?? false ? Themer.Theme.dark : Themer.Theme.light
        let subject = Themer(index: 2) // 2 is for system theme
        let expectedSliderKnobColor = currentSystemTheme == .light ? NSColor(deviceRed: 255.0, green: 255.0, blue: 255, alpha: 0.9) : NSColor(deviceRed: 0.0, green: 0.0, blue: 0, alpha: 0.9)
        let expectedSliderRightColor = currentSystemTheme == .dark ? NSColor.white : NSColor.gray
        let expectedBackgroundColor = currentSystemTheme == .dark ? NSColor.windowBackgroundColor : NSColor.white
        let expectedTextColor = NSColor.textColor
        let expectedTextBackgroundColor = currentSystemTheme == .light ? NSColor(deviceRed: 241.0 / 255.0, green: 241.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0) : NSColor.controlBackgroundColor
        let expectedThemeElements = ThemeExpectations(expectedSliderKnobColor: expectedSliderKnobColor,
                                                      expectedSliderRightColor: expectedSliderRightColor,
                                                      expectedBackgroundColor: expectedBackgroundColor,
                                                      expectedTextColor: expectedTextColor,
                                                      expectedTextBackgroundColor: expectedTextBackgroundColor,
                                                      expectedPopoverApperarance: NSAppearance.current!,
                                                      expectedShutdownImageName: "ellipsis.circle",
                                                      expectedPreferenceImageName: "plus",
                                                      expectedPinImageName: "macwindow.on.rectangle",
                                                      expectedSunriseImageName: "sunrise.fill",
                                                      expectedSunsetImageName: "sunset.fill",
                                                      expectedRemoveImageName: "xmark",
                                                      expectedExtraOptionsImage: "Extra Dynamic",
                                                      expectedMenubarOnboardingImage: "Dynamic Menubar",
                                                      expectedExtraOptionsHighlightedImage: "ExtraHighlighted Dynamic",
                                                      expectedSharingImage: "square.and.arrow.up.on.square.fill",
                                                      expectedCurrentLocationImage: "location.fill",
                                                      expectedAddImage: "plus",
                                                      expectedPrivacyTabImage: "lock",
                                                      expectedAppearanceTabImage: "eye",
                                                      expectedCalendarTabImage: "calendar",
                                                      expectedGeneralTabImage: "gearshape",
                                                      expectedAboutTabImage: "info.circle",
                                                      expectedVideoCallImage: "video.circle.fill",
                                                      expectedFilledTrashImage: "trash.fill",
                                                      expectedBackwardsImage: "gobackward.15",
                                                      expectedForwardsImage: "goforward.15",
                                                      expectedResetSliderImage: "xmark.circle.fill")
        testSubject(subject: subject, withExpectatations: expectedThemeElements)
        XCTAssertEqual(subject.description, "System Theme is \(currentSystemTheme == .dark ? Themer.Theme.dark : Themer.Theme.light)")
    }
    
    func testSolarizedLightTheme() throws {
        let subject = Themer(index: 3) // 3 is for solarized light theme
        let expectedThemeElements = ThemeExpectations(expectedSliderKnobColor: NSColor(deviceRed: 255.0, green: 255.0, blue: 255, alpha: 0.9),
                                                      expectedSliderRightColor: NSColor.gray,
                                                      expectedBackgroundColor: NSColor(deviceRed: 253.0 / 255.0, green: 246.0 / 255.0, blue: 227.0 / 255.0, alpha: 1.0),
                                                      expectedTextColor: NSColor.black,
                                                      expectedTextBackgroundColor: NSColor(deviceRed: 238.0 / 255.0, green: 232.0 / 255.0, blue: 213.0 / 255.0, alpha: 1.0),
                                                      expectedPopoverApperarance: NSAppearance(named: NSAppearance.Name.vibrantLight)!,
                                                      expectedShutdownImageName: "ellipsis.circle",
                                                      expectedPreferenceImageName: "plus",
                                                      expectedPinImageName: "macwindow.on.rectangle",
                                                      expectedSunriseImageName: "sunrise.fill",
                                                      expectedSunsetImageName: "sunset.fill",
                                                      expectedRemoveImageName: "xmark",
                                                      expectedExtraOptionsImage: "Extra",
                                                      expectedMenubarOnboardingImage: "Light Menubar",
                                                      expectedExtraOptionsHighlightedImage: "ExtraHighlighted",
                                                      expectedSharingImage: "square.and.arrow.up.on.square.fill",
                                                      expectedCurrentLocationImage: "location.fill",
                                                      expectedAddImage: "plus",
                                                      expectedPrivacyTabImage: "lock",
                                                      expectedAppearanceTabImage: "eye",
                                                      expectedCalendarTabImage: "calendar",
                                                      expectedGeneralTabImage: "gearshape",
                                                      expectedAboutTabImage: "info.circle",
                                                      expectedVideoCallImage: "video.circle.fill",
                                                      expectedFilledTrashImage: "trash.fill",
                                                      expectedBackwardsImage: "gobackward.15",
                                                      expectedForwardsImage: "goforward.15",
                                                      expectedResetSliderImage: "xmark.circle.fill")
        testSubject(subject: subject, withExpectatations: expectedThemeElements)
    }
    
    func testSolarizedDarkTheme() throws {
        let subject = Themer(index: 4) // 4 is for solarized dark theme
        let expectedThemeElements = ThemeExpectations(expectedSliderKnobColor: NSColor(deviceRed: 0.0, green: 0.0, blue: 0, alpha: 0.9),
                                                      expectedSliderRightColor: NSColor.gray,
                                                      expectedBackgroundColor: NSColor(deviceRed: 7.0 / 255.0, green: 54.0 / 255.0, blue: 66.0 / 255.0, alpha: 1.0),
                                                      expectedTextColor: NSColor.white,
                                                      expectedTextBackgroundColor: NSColor(deviceRed: 0.0 / 255.0, green: 43.0 / 255.0, blue: 54.0 / 255.0, alpha: 1.0),
                                                      expectedPopoverApperarance: NSAppearance(named: NSAppearance.Name.vibrantDark)!,
                                                      expectedShutdownImageName: "ellipsis.circle",
                                                      expectedPreferenceImageName: "plus",
                                                      expectedPinImageName: "macwindow.on.rectangle",
                                                      expectedSunriseImageName: "sunrise.fill",
                                                      expectedSunsetImageName: "sunset.fill",
                                                      expectedRemoveImageName: "xmark",
                                                      expectedExtraOptionsImage: "ExtraWhite",
                                                      expectedMenubarOnboardingImage: "Dark Menubar",
                                                      expectedExtraOptionsHighlightedImage: "ExtraWhiteHighlighted",
                                                      expectedSharingImage: "square.and.arrow.up.on.square.fill",
                                                      expectedCurrentLocationImage: "location.fill",
                                                      expectedAddImage: "plus",
                                                      expectedPrivacyTabImage: "lock",
                                                      expectedAppearanceTabImage: "eye",
                                                      expectedCalendarTabImage: "calendar",
                                                      expectedGeneralTabImage: "gearshape",
                                                      expectedAboutTabImage: "info.circle",
                                                      expectedVideoCallImage: "video.circle.fill",
                                                      expectedFilledTrashImage: "trash.fill",
                                                      expectedBackwardsImage: "gobackward.15",
                                                      expectedForwardsImage: "goforward.15",
                                                      expectedResetSliderImage: "xmark.circle.fill")
        testSubject(subject: subject, withExpectatations: expectedThemeElements)
    }
    
    private func testSubject(subject: Themer, withExpectatations expectations: ThemeExpectations) {
        XCTAssertEqual(subject.sliderKnobColor(), expectations.expectedSliderKnobColor)
        XCTAssertEqual(subject.sliderRightColor(), expectations.expectedSliderRightColor)
        XCTAssertEqual(subject.mainBackgroundColor(), expectations.expectedBackgroundColor)
        XCTAssertEqual(subject.mainTextColor(), expectations.expectedTextColor)
        XCTAssertEqual(subject.textBackgroundColor(), expectations.expectedTextBackgroundColor)
        XCTAssertEqual(subject.shutdownImage().accessibilityDescription, expectations.expectedShutdownImageName)
        XCTAssertEqual(subject.preferenceImage().accessibilityDescription, expectations.expectedPreferenceImageName)
        XCTAssertEqual(subject.pinImage().accessibilityDescription, expectations.expectedPinImageName)
        XCTAssertEqual(subject.sunriseImage().accessibilityDescription, expectations.expectedSunriseImageName)
        XCTAssertEqual(subject.sunsetImage().accessibilityDescription, expectations.expectedSunsetImageName)
        XCTAssertEqual(subject.removeImage().accessibilityDescription, expectations.expectedRemoveImageName)
        XCTAssertEqual(subject.extraOptionsImage().name(), expectations.expectedExtraOptionsImage)
        XCTAssertEqual(subject.menubarOnboardingImage().name(), expectations.expectedMenubarOnboardingImage)
        XCTAssertEqual(subject.extraOptionsHighlightedImage().name(), expectations.expectedExtraOptionsHighlightedImage)
        XCTAssertEqual(subject.sharingImage().accessibilityDescription, expectations.expectedSharingImage)
        XCTAssertEqual(subject.currentLocationImage().accessibilityDescription, expectations.expectedCurrentLocationImage)
        XCTAssertEqual(subject.popoverAppearance(), expectations.expectedPopoverApperarance)
        XCTAssertEqual(subject.addImage().accessibilityDescription, expectations.expectedAddImage)
        XCTAssertEqual(subject.privacyTabImage().accessibilityDescription, expectations.expectedPrivacyTabImage)
        XCTAssertEqual(subject.appearanceTabImage().accessibilityDescription, expectations.expectedAppearanceTabImage)
        XCTAssertEqual(subject.calendarTabImage().accessibilityDescription, expectations.expectedCalendarTabImage)
        XCTAssertEqual(subject.generalTabImage()?.accessibilityDescription, expectations.expectedGeneralTabImage)
        XCTAssertEqual(subject.aboutTabImage()?.accessibilityDescription, expectations.expectedAboutTabImage)
        XCTAssertEqual(subject.videoCallImage()?.accessibilityDescription, expectations.expectedVideoCallImage)
        XCTAssertEqual(subject.filledTrashImage()?.accessibilityDescription, expectations.expectedFilledTrashImage)
        XCTAssertEqual(subject.goBackwardsImage()?.accessibilityDescription, expectations.expectedBackwardsImage)
        XCTAssertEqual(subject.goForwardsImage()?.accessibilityDescription, expectations.expectedForwardsImage)
        XCTAssertEqual(subject.resetModernSliderImage()?.accessibilityDescription, expectations.expectedResetSliderImage)
    }
}

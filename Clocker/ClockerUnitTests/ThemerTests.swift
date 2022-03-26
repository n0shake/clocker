// Copyright © 2015 Abhishek Banthia

import XCTest

@testable import Clocker

class ThemerTests: XCTestCase {
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
        let expectedSliderKnobColor = NSColor(deviceRed: 255.0, green: 255.0, blue: 255, alpha: 0.9)
        let expectedSliderRightColor = NSColor.gray
        let expectedBackgroundColor = NSColor.white
        let expectedTextColor = NSColor.black
        let expectedTextBackgroundColor = NSColor(deviceRed: 241.0 / 255.0, green: 241.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0)

        let expectedShutdownImageName = "ellipsis.circle"
        let expectedPreferenceImageName = "plus"
        let expectedPinImageName = "macwindow.on.rectangle"
        let expectedSunriseImageName = "sunrise.fill"
        let expectedSunsetImageName = "sunset.fill"
        let expectedRemoveImageName = "xmark"
        let expectedExtraOptionsImage = "Extra"
        let expectedMenubarOnboardingImage = "Light Menubar"
        let expectedExtraOptionsHighlightedImage = "ExtraHighlighted"
        let expectedSharingImage = "square.and.arrow.up.on.square.fill"
        let expectedCurrentLocationImage = "location.fill"
        let expectedPopoverApperarance = NSAppearance(named: NSAppearance.Name.vibrantLight)!
        let expectedAddImage = "plus"
        let expectedAddImageHighlighted = "Add Highlighted"
        let expectedPrivacyTabImage = "lock"
        let expectedAppearanceTabImage = "eye"
        let expectedCalendarTabImage = "calendar"
        let expectedGeneralTabImage = "gearshape"
        let expectedAboutTabImage = "info.circle"
        let expectedVideoCallImage = "video.circle.fill"
        let expectedFilledTrashImage = "trash.fill"
        let expectedBackwardsImage = "gobackward.15"
        let expectedForwardsImage = "goforward.15"
        let expectedResetSliderImage = "xmark.circle.fill"

        XCTAssertEqual(subject.sliderKnobColor(), expectedSliderKnobColor)
        XCTAssertEqual(subject.sliderRightColor(), expectedSliderRightColor)
        XCTAssertEqual(subject.mainBackgroundColor(), expectedBackgroundColor)
        XCTAssertEqual(subject.mainTextColor(), expectedTextColor)
        XCTAssertEqual(subject.textBackgroundColor(), expectedTextBackgroundColor)

        XCTAssertEqual(subject.shutdownImage().accessibilityDescription, expectedShutdownImageName)
        XCTAssertEqual(subject.preferenceImage().accessibilityDescription, expectedPreferenceImageName)
        XCTAssertEqual(subject.pinImage().accessibilityDescription, expectedPinImageName)
        XCTAssertEqual(subject.sunriseImage().accessibilityDescription, expectedSunriseImageName)
        XCTAssertEqual(subject.sunsetImage().accessibilityDescription, expectedSunsetImageName)
        XCTAssertEqual(subject.removeImage().accessibilityDescription, expectedRemoveImageName)
        XCTAssertEqual(subject.extraOptionsImage().name(), expectedExtraOptionsImage)
        XCTAssertEqual(subject.menubarOnboardingImage().name(), expectedMenubarOnboardingImage)
        XCTAssertEqual(subject.extraOptionsHighlightedImage().name(), expectedExtraOptionsHighlightedImage)
        XCTAssertEqual(subject.sharingImage().accessibilityDescription, expectedSharingImage)
        XCTAssertEqual(subject.currentLocationImage().accessibilityDescription, expectedCurrentLocationImage)
        XCTAssertEqual(subject.popoverAppearance(), expectedPopoverApperarance)

        XCTAssertEqual(subject.addImage().accessibilityDescription, expectedAddImage)
        XCTAssertEqual(subject.addImageHighlighted().name(), expectedAddImageHighlighted)
        XCTAssertEqual(subject.privacyTabImage().accessibilityDescription, expectedPrivacyTabImage)
        XCTAssertEqual(subject.appearanceTabImage().accessibilityDescription, expectedAppearanceTabImage)
        XCTAssertEqual(subject.calendarTabImage().accessibilityDescription, expectedCalendarTabImage)
        XCTAssertEqual(subject.generalTabImage()?.accessibilityDescription, expectedGeneralTabImage)
        XCTAssertEqual(subject.aboutTabImage()?.accessibilityDescription, expectedAboutTabImage)
        XCTAssertEqual(subject.videoCallImage()?.accessibilityDescription, expectedVideoCallImage)
        XCTAssertEqual(subject.filledTrashImage()?.accessibilityDescription, expectedFilledTrashImage)
        XCTAssertEqual(subject.goBackwardsImage()?.accessibilityDescription, expectedBackwardsImage)
        XCTAssertEqual(subject.goForwardsImage()?.accessibilityDescription, expectedForwardsImage)
        XCTAssertEqual(subject.resetModernSliderImage()?.accessibilityDescription, expectedResetSliderImage)
    }

    func testDarkTheme() throws {
        let subject = Themer(index: 1) // 1 is for dark theme
        let expectedSliderKnobColor = NSColor(deviceRed: 0.0, green: 0.0, blue: 0, alpha: 0.9)
        let expectedSliderRightColor = NSColor.white
        let expectedBackgroundColor = NSColor(deviceRed: 42.0 / 255.0, green: 42.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0)
        let expectedTextColor = NSColor.white
        let expectedTextBackgroundColor = NSColor(deviceRed: 42.0 / 255.0, green: 55.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0)

        let expectedShutdownImageName = "ellipsis.circle"
        let expectedPreferenceImageName = "plus"
        let expectedPinImageName = "macwindow.on.rectangle"
        let expectedSunriseImageName = "sunrise.fill"
        let expectedSunsetImageName = "sunset.fill"
        let expectedRemoveImageName = "xmark"
        let expectedExtraOptionsImage = "ExtraWhite"
        let expectedMenubarOnboardingImage = "Light Menubar"
        let expectedExtraOptionsHighlightedImage = "ExtraWhiteHighlighted"
        let expectedSharingImage = "square.and.arrow.up.on.square.fill"
        let expectedCurrentLocationImage = "location.fill"
        let expectedPopoverApperarance = NSAppearance(named: NSAppearance.Name.vibrantDark)!
        let expectedAddImage = "plus"
        let expectedAddImageHighlighted = "Add White"
        let expectedPrivacyTabImage = "lock"
        let expectedAppearanceTabImage = "eye"
        let expectedCalendarTabImage = "calendar"
        let expectedGeneralTabImage = "gearshape"
        let expectedAboutTabImage = "info.circle"
        let expectedVideoCallImage = "video.circle.fill"
        let expectedFilledTrashImage = "trash.fill"
        let expectedBackwardsImage = "gobackward.15"
        let expectedForwardsImage = "goforward.15"
        let expectedResetSliderImage = "xmark.circle.fill"

        XCTAssertEqual(subject.sliderKnobColor(), expectedSliderKnobColor)
        XCTAssertEqual(subject.sliderRightColor(), expectedSliderRightColor)
        XCTAssertEqual(subject.mainBackgroundColor(), expectedBackgroundColor)
        XCTAssertEqual(subject.mainTextColor(), expectedTextColor)
        XCTAssertEqual(subject.textBackgroundColor(), expectedTextBackgroundColor)
        XCTAssertEqual(subject.shutdownImage().accessibilityDescription, expectedShutdownImageName)
        XCTAssertEqual(subject.preferenceImage().accessibilityDescription, expectedPreferenceImageName)
        XCTAssertEqual(subject.pinImage().accessibilityDescription, expectedPinImageName)
        XCTAssertEqual(subject.sunriseImage().accessibilityDescription, expectedSunriseImageName)
        XCTAssertEqual(subject.sunsetImage().accessibilityDescription, expectedSunsetImageName)
        XCTAssertEqual(subject.removeImage().accessibilityDescription, expectedRemoveImageName)
        XCTAssertEqual(subject.extraOptionsImage().name(), expectedExtraOptionsImage)
        XCTAssertEqual(subject.menubarOnboardingImage().name(), expectedMenubarOnboardingImage)
        XCTAssertEqual(subject.extraOptionsHighlightedImage().name(), expectedExtraOptionsHighlightedImage)
        XCTAssertEqual(subject.sharingImage().accessibilityDescription, expectedSharingImage)
        XCTAssertEqual(subject.currentLocationImage().accessibilityDescription, expectedCurrentLocationImage)
        XCTAssertEqual(subject.popoverAppearance(), expectedPopoverApperarance)
        XCTAssertEqual(subject.addImage().accessibilityDescription, expectedAddImage)
        XCTAssertEqual(subject.addImageHighlighted().name(), expectedAddImageHighlighted)
        XCTAssertEqual(subject.privacyTabImage().accessibilityDescription, expectedPrivacyTabImage)
        XCTAssertEqual(subject.appearanceTabImage().accessibilityDescription, expectedAppearanceTabImage)
        XCTAssertEqual(subject.calendarTabImage().accessibilityDescription, expectedCalendarTabImage)
        XCTAssertEqual(subject.generalTabImage()?.accessibilityDescription, expectedGeneralTabImage)
        XCTAssertEqual(subject.aboutTabImage()?.accessibilityDescription, expectedAboutTabImage)
        XCTAssertEqual(subject.videoCallImage()?.accessibilityDescription, expectedVideoCallImage)
        XCTAssertEqual(subject.filledTrashImage()?.accessibilityDescription, expectedFilledTrashImage)
        XCTAssertEqual(subject.goBackwardsImage()?.accessibilityDescription, expectedBackwardsImage)
        XCTAssertEqual(subject.goForwardsImage()?.accessibilityDescription, expectedForwardsImage)
        XCTAssertEqual(subject.resetModernSliderImage()?.accessibilityDescription, expectedResetSliderImage)
        XCTAssertEqual(subject.description, "Current Theme is \(Themer.Theme.dark)")
    }

    func testSystemTheme() throws {
        let currentSystemTheme =
            UserDefaults.standard.string(forKey: "AppleUserInterfaceStyle")?.lowercased().contains("dark") ?? false ? Themer.Theme.dark : Themer.Theme.light
        let subject = Themer(index: 2) // 2 is for system theme
        let expectedSliderKnobColor = currentSystemTheme == .light ? NSColor(deviceRed: 255.0, green: 255.0, blue: 255, alpha: 0.9) : NSColor(deviceRed: 0.0, green: 0.0, blue: 0, alpha: 0.9)
        let expectedSliderRightColor = currentSystemTheme == .dark ? NSColor.white : NSColor.gray
        let expectedBackgroundColor = currentSystemTheme == .dark ? NSColor(deviceRed: 42.0 / 255.0, green: 42.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0) : NSColor.white
        let expectedTextColor = NSColor.textColor
        let expectedTextBackgroundColor = currentSystemTheme == .dark ? NSColor(deviceRed: 42.0 / 255.0, green: 55.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0) : NSColor(deviceRed: 241.0 / 255.0, green: 241.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0)

        let expectedShutdownImageName = "ellipsis.circle"
        let expectedPreferenceImageName = "plus"
        let expectedPinImageName = "macwindow.on.rectangle"
        let expectedSunriseImageName = "sunrise.fill"
        let expectedSunsetImageName = "sunset.fill"
        let expectedRemoveImageName = "xmark"
        let expectedExtraOptionsImage = "Extra Dynamic"
        let expectedMenubarOnboardingImage = "Dynamic Menubar"
        let expectedExtraOptionsHighlightedImage = "ExtraHighlighted Dynamic"
        let expectedSharingImage = "square.and.arrow.up.on.square.fill"
        let expectedCurrentLocationImage = "location.fill"
        let expectedPopoverApperarance = NSAppearance.current
        let expectedAddImage = "plus"
        let expectedAddImageHighlighted = "Add White"
        let expectedPrivacyTabImage = "lock"
        let expectedAppearanceTabImage = "eye"
        let expectedCalendarTabImage = "calendar"
        let expectedGeneralTabImage = "gearshape"
        let expectedAboutTabImage = "info.circle"
        let expectedVideoCallImage = "video.circle.fill"
        let expectedFilledTrashImage = "trash.fill"
        let expectedBackwardsImage = "gobackward.15"
        let expectedForwardsImage = "goforward.15"
        let expectedResetSliderImage = "xmark.circle.fill"

        XCTAssertEqual(subject.sliderKnobColor(), expectedSliderKnobColor)
        XCTAssertEqual(subject.sliderRightColor(), expectedSliderRightColor)
        XCTAssertEqual(subject.mainBackgroundColor(), expectedBackgroundColor)
        XCTAssertEqual(subject.mainTextColor(), expectedTextColor)
        XCTAssertEqual(subject.textBackgroundColor(), expectedTextBackgroundColor)
        XCTAssertEqual(subject.shutdownImage().accessibilityDescription, expectedShutdownImageName)
        XCTAssertEqual(subject.preferenceImage().accessibilityDescription, expectedPreferenceImageName)
        XCTAssertEqual(subject.pinImage().accessibilityDescription, expectedPinImageName)
        XCTAssertEqual(subject.sunriseImage().accessibilityDescription, expectedSunriseImageName)
        XCTAssertEqual(subject.sunsetImage().accessibilityDescription, expectedSunsetImageName)
        XCTAssertEqual(subject.removeImage().accessibilityDescription, expectedRemoveImageName)
        XCTAssertEqual(subject.extraOptionsImage().name(), expectedExtraOptionsImage)
        XCTAssertEqual(subject.menubarOnboardingImage().name(), expectedMenubarOnboardingImage)
        XCTAssertEqual(subject.extraOptionsHighlightedImage().name(), expectedExtraOptionsHighlightedImage)
        XCTAssertEqual(subject.sharingImage().accessibilityDescription, expectedSharingImage)
        XCTAssertEqual(subject.currentLocationImage().accessibilityDescription, expectedCurrentLocationImage)
        XCTAssertEqual(subject.popoverAppearance(), expectedPopoverApperarance)
        XCTAssertEqual(subject.addImage().accessibilityDescription, expectedAddImage)
        XCTAssertEqual(subject.addImageHighlighted().name(), expectedAddImageHighlighted)
        XCTAssertEqual(subject.privacyTabImage().accessibilityDescription, expectedPrivacyTabImage)
        XCTAssertEqual(subject.appearanceTabImage().accessibilityDescription, expectedAppearanceTabImage)
        XCTAssertEqual(subject.calendarTabImage().accessibilityDescription, expectedCalendarTabImage)
        XCTAssertEqual(subject.generalTabImage()?.accessibilityDescription, expectedGeneralTabImage)
        XCTAssertEqual(subject.aboutTabImage()?.accessibilityDescription, expectedAboutTabImage)
        XCTAssertEqual(subject.videoCallImage()?.accessibilityDescription, expectedVideoCallImage)
        XCTAssertEqual(subject.filledTrashImage()?.accessibilityDescription, expectedFilledTrashImage)
        XCTAssertEqual(subject.goBackwardsImage()?.accessibilityDescription, expectedBackwardsImage)
        XCTAssertEqual(subject.goForwardsImage()?.accessibilityDescription, expectedForwardsImage)
        XCTAssertEqual(subject.resetModernSliderImage()?.accessibilityDescription, expectedResetSliderImage)
        XCTAssertEqual(subject.description, "System Theme is \(currentSystemTheme == .dark ? Themer.Theme.dark : Themer.Theme.light)")
    }

    func testSolarizedLightTheme() throws {
        let subject = Themer(index: 3) // 3 is for solarized light theme
        let expectedSliderKnobColor = NSColor(deviceRed: 0.0, green: 0.0, blue: 0, alpha: 0.9)
        let expectedSliderRightColor = NSColor.gray
        let expectedBackgroundColor = NSColor(deviceRed: 253.0 / 255.0, green: 246.0 / 255.0, blue: 227.0 / 255.0, alpha: 1.0)
        let expectedTextColor = NSColor.black
        let expectedTextBackgroundColor = NSColor(deviceRed: 238.0 / 255.0, green: 232.0 / 255.0, blue: 213.0 / 255.0, alpha: 1.0)

        let expectedShutdownImageName = "ellipsis.circle"
        let expectedPreferenceImageName = "plus"
        let expectedPinImageName = "macwindow.on.rectangle"
        let expectedSunriseImageName = "sunrise.fill"
        let expectedSunsetImageName = "sunset.fill"
        let expectedRemoveImageName = "xmark"
        let expectedExtraOptionsImage = "Extra"
        let expectedMenubarOnboardingImage = "Light Menubar"
        let expectedExtraOptionsHighlightedImage = "ExtraHighlighted"
        let expectedSharingImage = "square.and.arrow.up.on.square.fill"
        let expectedCurrentLocationImage = "location.fill"
        let expectedPopoverApperarance = NSAppearance(named: NSAppearance.Name.vibrantLight)!
        let expectedAddImage = "plus"
        let expectedAddImageHighlighted = "Add White"
        let expectedPrivacyTabImage = "lock"
        let expectedAppearanceTabImage = "eye"
        let expectedCalendarTabImage = "calendar"
        let expectedGeneralTabImage = "gearshape"
        let expectedAboutTabImage = "info.circle"
        let expectedVideoCallImage = "video.circle.fill"
        let expectedFilledTrashImage = "trash.fill"
        let expectedBackwardsImage = "gobackward.15"
        let expectedForwardsImage = "goforward.15"
        let expectedResetSliderImage = "xmark.circle.fill"

        XCTAssertEqual(subject.sliderKnobColor(), expectedSliderKnobColor)
        XCTAssertEqual(subject.sliderRightColor(), expectedSliderRightColor)
        XCTAssertEqual(subject.mainBackgroundColor(), expectedBackgroundColor)
        XCTAssertEqual(subject.mainTextColor(), expectedTextColor)
        XCTAssertEqual(subject.textBackgroundColor(), expectedTextBackgroundColor)

        XCTAssertEqual(subject.shutdownImage().accessibilityDescription, expectedShutdownImageName)
        XCTAssertEqual(subject.preferenceImage().accessibilityDescription, expectedPreferenceImageName)
        XCTAssertEqual(subject.pinImage().accessibilityDescription, expectedPinImageName)
        XCTAssertEqual(subject.sunriseImage().accessibilityDescription, expectedSunriseImageName)
        XCTAssertEqual(subject.sunsetImage().accessibilityDescription, expectedSunsetImageName)
        XCTAssertEqual(subject.removeImage().accessibilityDescription, expectedRemoveImageName)
        XCTAssertEqual(subject.extraOptionsImage().name(), expectedExtraOptionsImage)
        XCTAssertEqual(subject.menubarOnboardingImage().name(), expectedMenubarOnboardingImage)
        XCTAssertEqual(subject.extraOptionsHighlightedImage().name(), expectedExtraOptionsHighlightedImage)
        XCTAssertEqual(subject.sharingImage().accessibilityDescription, expectedSharingImage)
        XCTAssertEqual(subject.currentLocationImage().accessibilityDescription, expectedCurrentLocationImage)
        XCTAssertEqual(subject.popoverAppearance(), expectedPopoverApperarance)

        XCTAssertEqual(subject.addImage().accessibilityDescription, expectedAddImage)
        XCTAssertEqual(subject.addImageHighlighted().name(), expectedAddImageHighlighted)
        XCTAssertEqual(subject.privacyTabImage().accessibilityDescription, expectedPrivacyTabImage)
        XCTAssertEqual(subject.appearanceTabImage().accessibilityDescription, expectedAppearanceTabImage)
        XCTAssertEqual(subject.calendarTabImage().accessibilityDescription, expectedCalendarTabImage)
        XCTAssertEqual(subject.generalTabImage()?.accessibilityDescription, expectedGeneralTabImage)
        XCTAssertEqual(subject.aboutTabImage()?.accessibilityDescription, expectedAboutTabImage)
        XCTAssertEqual(subject.videoCallImage()?.accessibilityDescription, expectedVideoCallImage)
        XCTAssertEqual(subject.filledTrashImage()?.accessibilityDescription, expectedFilledTrashImage)
        XCTAssertEqual(subject.goBackwardsImage()?.accessibilityDescription, expectedBackwardsImage)
        XCTAssertEqual(subject.goForwardsImage()?.accessibilityDescription, expectedForwardsImage)
        XCTAssertEqual(subject.resetModernSliderImage()?.accessibilityDescription, expectedResetSliderImage)
    }

    func testSolarizedDarkTheme() throws {
        let subject = Themer(index: 4) // 4 is for solarized dark theme
        let expectedSliderKnobColor = NSColor(deviceRed: 0.0, green: 0.0, blue: 0, alpha: 0.9)
        let expectedSliderRightColor = NSColor.gray
        let expectedBackgroundColor = NSColor(deviceRed: 7.0 / 255.0, green: 54.0 / 255.0, blue: 66.0 / 255.0, alpha: 1.0)
        let expectedTextColor = NSColor.white
        let expectedTextBackgroundColor = NSColor(deviceRed: 88.0 / 255.0, green: 110.0 / 255.0, blue: 117.0 / 255.0, alpha: 1.0)

        let expectedShutdownImageName = "ellipsis.circle"
        let expectedPreferenceImageName = "plus"
        let expectedPinImageName = "macwindow.on.rectangle"
        let expectedSunriseImageName = "sunrise.fill"
        let expectedSunsetImageName = "sunset.fill"
        let expectedRemoveImageName = "xmark"
        let expectedExtraOptionsImage = "ExtraWhite"
        let expectedMenubarOnboardingImage = "Light Menubar"
        let expectedExtraOptionsHighlightedImage = "ExtraWhiteHighlighted"
        let expectedSharingImage = "square.and.arrow.up.on.square.fill"
        let expectedCurrentLocationImage = "location.fill"
        let expectedPopoverApperarance = NSAppearance(named: NSAppearance.Name.vibrantDark)!
        let expectedAddImage = "plus"
        let expectedAddImageHighlighted = "Add White"
        let expectedPrivacyTabImage = "lock"
        let expectedAppearanceTabImage = "eye"
        let expectedCalendarTabImage = "calendar"
        let expectedGeneralTabImage = "gearshape"
        let expectedAboutTabImage = "info.circle"
        let expectedVideoCallImage = "video.circle.fill"
        let expectedFilledTrashImage = "trash.fill"
        let expectedBackwardsImage = "gobackward.15"
        let expectedForwardsImage = "goforward.15"
        let expectedResetSliderImage = "xmark.circle.fill"

        XCTAssertEqual(subject.sliderKnobColor(), expectedSliderKnobColor)
        XCTAssertEqual(subject.sliderRightColor(), expectedSliderRightColor)
        XCTAssertEqual(subject.mainBackgroundColor(), expectedBackgroundColor)
        XCTAssertEqual(subject.mainTextColor(), expectedTextColor)
        XCTAssertEqual(subject.textBackgroundColor(), expectedTextBackgroundColor)
        XCTAssertEqual(subject.shutdownImage().accessibilityDescription, expectedShutdownImageName)
        XCTAssertEqual(subject.preferenceImage().accessibilityDescription, expectedPreferenceImageName)
        XCTAssertEqual(subject.pinImage().accessibilityDescription, expectedPinImageName)
        XCTAssertEqual(subject.sunriseImage().accessibilityDescription, expectedSunriseImageName)
        XCTAssertEqual(subject.sunsetImage().accessibilityDescription, expectedSunsetImageName)
        XCTAssertEqual(subject.removeImage().accessibilityDescription, expectedRemoveImageName)
        XCTAssertEqual(subject.extraOptionsImage().name(), expectedExtraOptionsImage)
        XCTAssertEqual(subject.menubarOnboardingImage().name(), expectedMenubarOnboardingImage)
        XCTAssertEqual(subject.extraOptionsHighlightedImage().name(), expectedExtraOptionsHighlightedImage)
        XCTAssertEqual(subject.sharingImage().accessibilityDescription, expectedSharingImage)
        XCTAssertEqual(subject.currentLocationImage().accessibilityDescription, expectedCurrentLocationImage)
        XCTAssertEqual(subject.popoverAppearance(), expectedPopoverApperarance)
        XCTAssertEqual(subject.addImage().accessibilityDescription, expectedAddImage)
        XCTAssertEqual(subject.addImageHighlighted().name(), expectedAddImageHighlighted)
        XCTAssertEqual(subject.privacyTabImage().accessibilityDescription, expectedPrivacyTabImage)
        XCTAssertEqual(subject.appearanceTabImage().accessibilityDescription, expectedAppearanceTabImage)
        XCTAssertEqual(subject.calendarTabImage().accessibilityDescription, expectedCalendarTabImage)
        XCTAssertEqual(subject.generalTabImage()?.accessibilityDescription, expectedGeneralTabImage)
        XCTAssertEqual(subject.aboutTabImage()?.accessibilityDescription, expectedAboutTabImage)
        XCTAssertEqual(subject.videoCallImage()?.accessibilityDescription, expectedVideoCallImage)
        XCTAssertEqual(subject.filledTrashImage()?.accessibilityDescription, expectedFilledTrashImage)
        XCTAssertEqual(subject.goBackwardsImage()?.accessibilityDescription, expectedBackwardsImage)
        XCTAssertEqual(subject.goForwardsImage()?.accessibilityDescription, expectedForwardsImage)
        XCTAssertEqual(subject.resetModernSliderImage()?.accessibilityDescription, expectedResetSliderImage)
    }
}

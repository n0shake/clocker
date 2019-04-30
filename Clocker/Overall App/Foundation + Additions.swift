// Copyright © 2015 Abhishek Banthia

import Cocoa

extension NSNotification.Name {
    static let themeDidChange = NSNotification.Name("ThemeDidChangeNotification")
    static let customLabelChanged = NSNotification.Name("CLCustomLabelChangedNotification")
    static let calendarAccessGranted = NSNotification.Name("CalendarAccessStatus")
    static let interfaceStyleDidChange = NSNotification.Name("AppleInterfaceThemeChangedNotification")
}

extension NSPasteboard.PasteboardType {
    static let dragSession = NSPasteboard.PasteboardType(rawValue: "public.text")
}

extension NSNib.Name {
    static let floatingWindowIdentifier = NSNib.Name("FloatingWindow")
    static let notesPopover = NSNib.Name("NotesPopover")
    static let panel = NSNib.Name("Panel")
    static let permissions = NSNib.Name("Permissions")
    static let onboardingPermissions = NSNib.Name("OnboardingPermissions")
}

extension NSImage.Name {
    static let permissionTabIcon = NSImage.Name("Privacy Dynamic")
    static let calendarTabIcon = NSImage.Name("Calendar Tab Dynamic")
    static let appearanceTabIcon = NSImage.Name("Appearance Dynamic")
    static let addIcon = NSImage.Name("Add")
    static let addDynamicIcon = NSImage.Name("Add Dynamic")
    static let privacyIcon = NSImage.Name("Privacy Dynamic")
    static let sortToggleIcon = NSImage.Name("Additional Preferences Dynamic")
    static let sortToggleAlternateIcon = NSImage.Name("Additional Preferences Highlighted Dynamic")
    static let menubarIcon = NSImage.Name("LightModeIcon")
}

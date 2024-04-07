// Copyright © 2015 Abhishek Banthia

import CoreModelKit
import XCTest

@testable import Clocker

class AppDelegateTests: XCTestCase {
    func testStatusItemIsInitialized() throws {
        let subject = NSApplication.shared.delegate as? AppDelegate
        let statusHandler = subject?.statusItemForPanel()
        XCTAssertNotNil(EventCenter.sharedCenter)
        XCTAssertNotNil(statusHandler)
    }

    func testDockMenu() throws {
        let subject = NSApplication.shared.delegate as? AppDelegate
        let dockMenu = subject?.applicationDockMenu(NSApplication.shared)
        let items = dockMenu?.items ?? []

        XCTAssertEqual(dockMenu?.title, "Quick Access")
        XCTAssertEqual(items.first?.title, "Toggle Panel")
        XCTAssertEqual(items[1].title, "Settings")
        XCTAssertEqual(items[1].keyEquivalent, ",")
        XCTAssertEqual(items[2].title, "Hide from Dock")

        // Test selections
        XCTAssertEqual(items.first?.action, #selector(AppDelegate.togglePanel(_:)))
        XCTAssertEqual(items[2].action, #selector(AppDelegate.hideFromDock))

        items.forEach { menuItem in
            XCTAssertTrue(menuItem.isEnabled)
        }
    }

    func testSetupMenubarTimer() {
        let subject = NSApplication.shared.delegate as? AppDelegate

        let statusItemHandler = subject?.statusItemForPanel()
        XCTAssertEqual(statusItemHandler?.statusItem.autosaveName, NSStatusItem.AutosaveName("ClockerStatusItem"))
    }

    func testFloatingWindow() {
        let subject = NSApplication.shared.delegate as? AppDelegate
        let previousWindows = NSApplication.shared.windows
        XCTAssertTrue(previousWindows.count >= 1) // Only the status bar window should be present

        subject?.setupFloatingWindow(true)

        let floatingWindow = NSApplication.shared.windows.first { window in
            if (window.windowController as? FloatingWindowController) != nil {
                return true
            }
            return false
        }

        XCTAssertNotNil(floatingWindow)
        XCTAssertEqual(floatingWindow?.windowController?.windowFrameAutosaveName, NSWindow.FrameAutosaveName("FloatingWindowAutoSave"))

        subject?.setupFloatingWindow(false)

        let closedFloatingWindow = NSApplication.shared.windows.first { window in
            if (window.windowController as? FloatingWindowController) != nil {
                return true
            }
            return false
        }

        XCTAssertNotNil(closedFloatingWindow)
    }

    func testActivationPolicy() {
        let subject = NSApplication.shared.delegate as? AppDelegate
        let previousOption = UserDefaults.standard.integer(forKey: CLAppDisplayOptions)
        if previousOption == 0 {
            XCTAssertEqual(NSApp.activationPolicy(), .accessory)
        } else {
            XCTAssertEqual(NSApp.activationPolicy(), .regular)
        }

        subject?.hideFromDock()
        XCTAssertEqual(NSApp.activationPolicy(), .accessory)
    }

    func testMenubarInvalidationToIcon() {
        let subject = NSApplication.shared.delegate as? AppDelegate
        subject?.invalidateMenubarTimer(true)
        let statusItemHandler = subject?.statusItemForPanel()
        XCTAssertEqual(statusItemHandler?.statusItem.button?.subviews, [])
        XCTAssertEqual(statusItemHandler?.statusItem.button?.title, CLEmptyString)
        XCTAssertEqual(statusItemHandler?.statusItem.button?.image?.name(), "LightModeIcon")
        XCTAssertEqual(statusItemHandler?.statusItem.button?.imagePosition, .imageOnly)
        XCTAssertEqual(statusItemHandler?.statusItem.button?.toolTip, "Clocker")
    }

    func testCompactModeMenubarSetup() {
        let subject = NSApplication.shared.delegate as? AppDelegate
        let olderTimezones = DataStore.shared().timezones()

        let timezone1 = TimezoneData()
        timezone1.timezoneID = TimeZone.autoupdatingCurrent.identifier
        timezone1.formattedAddress = "MenubarTimezone"
        timezone1.isFavourite = 1
        // Encode it in UserDefaults
        guard let encodedTimezone = NSKeyedArchiver.clocker_archive(with: timezone1) else {
            return
        }
        DataStore.shared().setTimezones([encodedTimezone])

        subject?.setupMenubarTimer()
        let statusItemHandler = subject?.statusItemForPanel()
        XCTAssertNotNil(statusItemHandler?.statusItem.button) // This won't be nil for compact mode

        DataStore.shared().setTimezones(olderTimezones)
    }

    func testStandardModeMenubarSetup() {
        let olderTimezones = DataStore.shared().timezones()
        UserDefaults.standard.set(1, forKey: CLMenubarCompactMode) // Set the menubar mode to standard

        let subject = NSApplication.shared.delegate as? AppDelegate
        let statusItemHandler = subject?.statusItemForPanel()
        subject?.setupMenubarTimer()

        if olderTimezones.isEmpty {
            XCTAssertEqual(statusItemHandler?.statusItem.button?.image?.name(), "LightModeIcon")
        } else {
            XCTAssertTrue(statusItemHandler?.statusItem.button?.title != nil)
        }

        let timezone1 = TimezoneData()
        timezone1.timezoneID = TimeZone.autoupdatingCurrent.identifier
        timezone1.formattedAddress = "MenubarTimezone"
        timezone1.isFavourite = 1
        // Encode it in UserDefaults
        guard let encodedTimezone = NSKeyedArchiver.clocker_archive(with: timezone1) else {
            return
        }
        DataStore.shared().setTimezones([encodedTimezone])

        subject?.setupMenubarTimer()

        XCTAssertEqual(subject?.statusItemForPanel().statusItem.button?.subviews.isEmpty, true) // This will be nil for standard mode

        UserDefaults.standard.set(0, forKey: CLMenubarCompactMode) // Set the menubar mode back to compact
    }
}

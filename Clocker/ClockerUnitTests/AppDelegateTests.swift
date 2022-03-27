// Copyright © 2015 Abhishek Banthia

import XCTest
import CoreModelKit

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
        XCTAssertEqual(items[1].title, "Preferences")
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
            if ((window.windowController as? FloatingWindowController) != nil) {
                return true
            }
            return false
        }
        
        XCTAssertNotNil(floatingWindow)
        XCTAssertEqual(floatingWindow?.windowController?.windowFrameAutosaveName, NSWindow.FrameAutosaveName("FloatingWindowAutoSave"))
        
        subject?.setupFloatingWindow(false)
        
        let closedFloatingWindow = NSApplication.shared.windows.first { window in
            if ((window.windowController as? FloatingWindowController) != nil) {
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
        XCTAssertNil(statusItemHandler?.statusItem.view)
        XCTAssertEqual(statusItemHandler?.statusItem.title, CLEmptyString)
        XCTAssertEqual(statusItemHandler?.statusItem.button?.image?.name(), "LightModeIcon")
        XCTAssertEqual(statusItemHandler?.statusItem.button?.imagePosition, .imageOnly)
        XCTAssertEqual(statusItemHandler?.statusItem.toolTip, "Clocker")
    }
    
    func testCompactModeMenubarSetup() {
        let subject = NSApplication.shared.delegate as? AppDelegate
        
        let timezone1 = TimezoneData()
        timezone1.timezoneID = TimeZone.autoupdatingCurrent.identifier
        timezone1.formattedAddress = "MenubarTimezone"
        timezone1.isFavourite = 1
        // Encode it in UserDefaults
        let encodedTimezone = NSKeyedArchiver.archivedData(withRootObject: timezone1)
        DataStore.shared().setTimezones([encodedTimezone])
        
        subject?.setupMenubarTimer()
        let statusItemHandler = subject?.statusItemForPanel()
        XCTAssertNotNil(statusItemHandler?.statusItem.view) // This won't be nil for compact mode
        
        DataStore.shared().setTimezones([])
    }

    func testStandardModeMenubarSetup() {
        UserDefaults.standard.set(1, forKey: CLMenubarCompactMode) // Set the menubar mode to standard
        
        let subject = NSApplication.shared.delegate as? AppDelegate
        let statusItemHandler = subject?.statusItemForPanel()
        
        XCTAssertEqual(statusItemHandler?.statusItem.button?.image?.name(), "LightModeIcon")
        
        let timezone1 = TimezoneData()
        timezone1.timezoneID = TimeZone.autoupdatingCurrent.identifier
        timezone1.formattedAddress = "MenubarTimezone"
        timezone1.isFavourite = 1
        // Encode it in UserDefaults
        let encodedTimezone = NSKeyedArchiver.archivedData(withRootObject: timezone1)
        DataStore.shared().setTimezones([encodedTimezone])
        
        subject?.setupMenubarTimer()
        
        XCTAssertNil(statusItemHandler?.statusItem.view) // This won't be nil for compact mode
        
        DataStore.shared().setTimezones([])
        
        UserDefaults.standard.set(0, forKey: CLMenubarCompactMode) // Set the menubar mode back to compact
    }
    
    func testTogglingPanel() {
        UserDefaults.standard.set(1, forKey: CLShowAppInForeground)
        
        let subject = NSApplication.shared.delegate as? AppDelegate
        subject?.ping("MockArgument")
        
        UserDefaults.standard.set(0, forKey: CLShowAppInForeground)
        let hasActiveGetter = PanelController.shared().hasActivePanel
        subject?.ping("MockArgument")
        
        XCTAssertNotEqual(hasActiveGetter, PanelController.shared().hasActivePanel)
    }

}

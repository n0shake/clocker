// Copyright © 2015 Abhishek Banthia

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
        XCTAssertEqual(previousWindows.count, 1) // Only the status bar window should be present
        
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


}

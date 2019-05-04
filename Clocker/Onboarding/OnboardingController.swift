// Copyright © 2015 Abhishek Banthia

import Cocoa

class OnboardingController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()

        window?.setAccessibilityIdentifier("OnboardingWindow")
        window?.titlebarAppearsTransparent = true
        window?.backgroundColor = Themer.shared().mainBackgroundColor()
        window?.delegate = self

        window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window?.standardWindowButton(.zoomButton)?.isHidden = true
        window?.standardWindowButton(.closeButton)?.isHidden = true
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.center()
    }

    func launch() {
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension OnboardingController: NSWindowDelegate {
    func windowWillClose(_: Notification) {
        if let contentViewController = window?.contentViewController as? OnboardingParentViewController {
            contentViewController.logExitPoint()
        }
    }
}

// Copyright © 2015 Abhishek Banthia

import Cocoa

class CenteredTabViewController: NSTabViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup localized tab labels
        tabViewItems.forEach { item in
            if let identifier = item.identifier as? String {
                item.label = NSLocalizedString(identifier, comment: "Tab View Item Label for \(identifier)")
            }
        }
    }
}

class OneWindowController: NSWindowController {
    private var themeDidChangeNotification: NSObjectProtocol?

    override func windowDidLoad() {
        super.windowDidLoad()
        setup()

        themeDidChangeNotification = NotificationCenter.default.addObserver(forName: .themeDidChangeNotification, object: nil, queue: OperationQueue.main) { _ in

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 1
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
                self.window?.animator().backgroundColor = Themer.shared().mainBackgroundColor()
            }

            self.setupToolbarImages()
        }
    }

    deinit {
        if let themeDidChangeNotif = themeDidChangeNotification {
            NotificationCenter.default.removeObserver(themeDidChangeNotif)
        }
    }

    private func setup() {
        setupWindow()
        setupToolbarImages()
    }

    private func setupWindow() {
        window?.titlebarAppearsTransparent = true
        window?.backgroundColor = Themer.shared().mainBackgroundColor()
        window?.identifier = NSUserInterfaceItemIdentifier("Preferences")
    }
    
    private func setupToolbarImages() {
        guard let tabViewController = contentViewController as? CenteredTabViewController else {
            return
        }

        let themer = Themer.shared()
        var identifierTOImageMapping: [String: NSImage] = ["Appearance Tab": themer.appearanceTabImage(),
                                                           "Calendar Tab": themer.calendarTabImage(),
                                                           "Permissions Tab": themer.privacyTabImage()]

        if let prefsTabImage = themer.generalTabImage() {
            identifierTOImageMapping["Preferences Tab"] = prefsTabImage
        }

        if let aboutTabImage = themer.aboutTabImage() {
            identifierTOImageMapping["About Tab"] = aboutTabImage
        }

        tabViewController.tabViewItems.forEach { tabViewItem in
            let identity = (tabViewItem.identifier as? String) ?? ""
            if identifierTOImageMapping[identity] != nil {
                tabViewItem.image = identifierTOImageMapping[identity]
            }
        }
    }

    // MARK: Public
    
    func openPermissionsPane() {
        openPreferenceTab(at: 3)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // Action mapped to the + button in the PanelController. We should always open the General Pane when the + button is clicked.
    func openGeneralPane() {
        openPreferenceTab(at: 0)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func openPreferenceTab(at index: Int) {
        guard let window = window else {
            return
        }

        if !window.isMainWindow || !window.isVisible {
            showWindow(nil)
        }

        guard let tabViewController = contentViewController as? CenteredTabViewController else {
            return
        }

        tabViewController.selectedTabViewItemIndex = index
    }
}

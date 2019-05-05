// Copyright © 2015 Abhishek Banthia

import Cocoa

class CenteredTabViewController: NSTabViewController {

    override func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        super.toolbarDefaultItemIdentifiers(toolbar)

        var toolbarItems: [NSToolbarItem.Identifier] = [NSToolbarItem.Identifier.flexibleSpace]

        tabViewItems.forEach { (item) in
            if let identifier = item.identifier as? String {
                toolbarItems.append(NSToolbarItem.Identifier.init(identifier))
            }
        }

        toolbarItems.append(NSToolbarItem.Identifier.flexibleSpace)

        return toolbarItems
    }

}

class OneWindowController: NSWindowController {

    private static var sharedWindow: OneWindowController!
    private var themeDidChangeNotification: NSObjectProtocol?

    override func windowDidLoad() {
        super.windowDidLoad()
        setup()

        themeDidChangeNotification = NotificationCenter.default.addObserver(forName: .themeDidChangeNotification, object: nil, queue: OperationQueue.main) { (_) in

            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 1
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
                self.window?.animator().backgroundColor = Themer.shared().mainBackgroundColor()
            })

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
    }

    class func shared() -> OneWindowController {
        if sharedWindow == nil {
            let prefStoryboard = NSStoryboard.init(name: "Preferences", bundle: nil)
            sharedWindow = prefStoryboard.instantiateInitialController() as? OneWindowController
        }
        return sharedWindow
    }

    func openPermissions() {
        guard let window = window else {
            return
        }

        if !(window.isMainWindow) || !(window.isVisible) {
            showWindow(nil)
        }

        guard let tabViewController = contentViewController as? CenteredTabViewController else {
            return
        }

        tabViewController.selectedTabViewItemIndex = 3
    }

    private func setupToolbarImages() {
        guard let tabViewController = contentViewController as? CenteredTabViewController else {
            return
        }

        let themer = Themer.shared()
        let identifierTOImageMapping: [String: NSImage] = ["Appearance": themer.appearanceTabImage(),
                                                           "Calendar": themer.calendarTabImage(),
                                                           "Permissions": themer.privacyTabImage()]

        tabViewController.tabViewItems.forEach { (tabViewItem) in
            let identity = (tabViewItem.identifier as? String) ?? ""
            if identifierTOImageMapping[identity] != nil {
                tabViewItem.image = identifierTOImageMapping[identity]
            }
        }
    }

}

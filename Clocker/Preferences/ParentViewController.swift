// Copyright © 2015 Abhishek Banthia

import Cocoa

class ParentViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if let view = view as? ParentView {
            view.wantsLayer = true
        }

        preferredContentSize = NSSize(width: view.frame.size.width, height: view.frame.size.height)
    }
}

class ParentView: NSView {
    override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = Themer.shared().mainBackgroundColor().cgColor

        if let controller = window?.windowController?.contentViewController as? PermissionsViewController {
            [controller.calendarContainerView, controller.remindersContainerView].forEach { $0?.applyShadow() }
        }
    }
}

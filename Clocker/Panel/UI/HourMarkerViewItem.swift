// Copyright © 2015 Abhishek Banthia

import Cocoa

class HourMarkerViewItem: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("HourMarkerViewItem")
    @IBOutlet var verticalLineView: NSView!

    func setup(with index: Int) {
        for constraint in view.constraints where constraint.identifier == "constrainFromTop" {
            if index % 4 == 0 {
                constraint.constant = 0
            } else {
                constraint.constant = 20
            }
        }
        verticalLineView.wantsLayer = true
        verticalLineView.layer?.backgroundColor = NSColor.lightGray.cgColor
    }

    override var acceptsFirstResponder: Bool {
        return false
    }
}

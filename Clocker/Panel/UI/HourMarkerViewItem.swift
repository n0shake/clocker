// Copyright © 2015 Abhishek Banthia

import Cocoa

class HourMarkerViewItem: NSCollectionViewItem {
    static let topConstraintIdentifier = "constrainFromTop"
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("HourMarkerViewItem")
    @IBOutlet var verticalLineView: NSView!

    func setup(with index: Int) {
        for constraint in view.constraints where constraint.identifier == HourMarkerViewItem.topConstraintIdentifier {
            constraint.constant = index % 4 == 0 ? 0 : 20
        }
        verticalLineView.wantsLayer = true
        verticalLineView.layer?.backgroundColor = NSColor.lightGray.cgColor
    }

    override var acceptsFirstResponder: Bool {
        return false
    }
}

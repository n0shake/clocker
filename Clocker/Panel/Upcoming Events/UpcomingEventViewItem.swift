// Copyright © 2015 Abhishek Banthia

import Foundation

class UpcomingEventViewItem: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("UpcomingEventViewItem")
    @IBOutlet weak var calendarColorView: NSView!
    
    @IBOutlet weak var eventTitleLabel: NSTextField!
    @IBOutlet weak var eventSubtitleLabel: NSButton!
    
    func setup(_ title: String, _ subtitle: String, _ color: NSColor) {
        calendarColorView.layer?.backgroundColor = color.cgColor
        eventTitleLabel.stringValue = title
        eventSubtitleLabel.stringValue = subtitle
    }
    
    override var acceptsFirstResponder: Bool {
        return false
    }
    
}

// Copyright © 2015 Abhishek Banthia

import Cocoa

class HourMarkerViewItem: NSCollectionViewItem {
    @IBOutlet var hourLabel: NSTextField!

    func setup(with indexPath: IndexPath) {
        hourLabel.stringValue = "\(indexPath.item):00"
        if indexPath.item == 2 {
            highlightState = .forSelection
            isSelected = true
        }
    }
}

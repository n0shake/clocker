// Copyright © 2015 Abhishek Banthia

import Cocoa

class AddTableViewCell: NSTableCellView {
    @IBOutlet var addTimezone: NSButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeChanges),
                                               name: Notification.Name.themeDidChange,
                                               object: nil)

        if let addCell = addTimezone.cell as? NSButtonCell {
            addCell.highlightsBy = .contentsCellMask
            addCell.showsStateBy = .pushInCellMask
        }

        updateAddButton()

        addTimezone.setAccessibility("EmptyAddTimezone")
    }

    @objc func themeChanges() {
        updateAddButton()
    }

    private func updateAddButton() {
        addTimezone.image = Themer.shared().addImage()
    }
}

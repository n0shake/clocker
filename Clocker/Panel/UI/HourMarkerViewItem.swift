// Copyright © 2015 Abhishek Banthia

import Cocoa

class HourMarkerViewItem: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("HourMarkerViewItem")

    @IBOutlet var hourLabel: NSTextField!

    func setup(with hour: Int) {
        var dateComponents = DateComponents()
        dateComponents.hour = hour

        if let newDate = Calendar.autoupdatingCurrent.date(byAdding: dateComponents, to: Date().nextHour) {
            let dateFormatter = DateFormatterManager.dateFormatterWithFormat(with: .none,
                                                                             format: "HH:mm",
                                                                             timezoneIdentifier: TimeZone.current.identifier,
                                                                             locale: Locale.autoupdatingCurrent)

            hourLabel.stringValue = dateFormatter.string(from: newDate)
        }
    }

    override var acceptsFirstResponder: Bool {
        return false
    }
}

extension Date {
    public var nextHour: Date {
        let calendar = Calendar.current
        let minutes = calendar.component(.minute, from: self)
        let components = DateComponents(hour: 1, minute: -minutes)
        return calendar.date(byAdding: components, to: self) ?? self
    }
}

// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreModelKit

class TimezoneDataSource: NSObject {
    var timezones: [TimezoneData] = []
    var sliderValue: Int = 0
    var dataStore: DataStore

    init(items: [TimezoneData], store: DataStore) {
        sliderValue = 0
        timezones = Array(items)
        dataStore = store
        super.init()
    }
}

extension TimezoneDataSource {
    func setSlider(value: Int) {
        sliderValue = value
    }

    func setItems(items: [TimezoneData]) {
        timezones = items
    }
}

extension TimezoneDataSource: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in _: NSTableView) -> Int {
        var totalTimezones = timezones.count

        // If totalTimezone is 0, then we can show an option to add timezones
        if totalTimezones == 0 {
            totalTimezones += 1
        }

        return totalTimezones
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        guard !timezones.isEmpty else {
            if let addCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "addCell"), owner: self) as? AddTableViewCell {
                return addCellView
            }

            assertionFailure("Unable to create AddTableViewCell")
            return nil
        }

        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "timeZoneCell"), owner: self) as? TimezoneCellView else {
            assertionFailure("Unable to create tableviewcell")
            return NSView()
        }

        let currentModel = timezones[row]
        let operation = TimezoneDataOperations(with: currentModel, store: dataStore)

        cellView.sunriseSetTime.stringValue = operation.formattedSunriseTime(with: sliderValue)
        cellView.sunriseImage.image = currentModel.isSunriseOrSunset ? Themer.shared().sunriseImage() : Themer.shared().sunsetImage()
        if #available(macOS 10.14, *) {
            cellView.sunriseImage.contentTintColor = currentModel.isSunriseOrSunset ? NSColor.systemYellow : NSColor.systemOrange
        }
        cellView.relativeDate.stringValue = operation.date(with: sliderValue, displayType: .panel)
        cellView.rowNumber = row
        cellView.customName.stringValue = currentModel.formattedTimezoneLabel()
        cellView.time.stringValue = operation.time(with: sliderValue)
        cellView.noteLabel.toolTip = currentModel.note ?? CLEmptyString
        cellView.currentLocationIndicator.isHidden = !currentModel.isSystemTimezone
        cellView.time.setAccessibilityIdentifier("ActualTime")
        cellView.relativeDate.setAccessibilityIdentifier("RelativeDate")
        if let note = currentModel.note, !note.isEmpty {
            cellView.noteLabel.stringValue = note
        } else if let value = operation.nextDaylightSavingsTransitionIfAvailable(with: sliderValue) {
            cellView.noteLabel.stringValue = value
        } else {
            cellView.noteLabel.stringValue = CLEmptyString
        }
        cellView.layout(with: currentModel)
        cellView.setAccessibilityIdentifier(currentModel.formattedTimezoneLabel())
        cellView.setAccessibilityLabel(currentModel.formattedTimezoneLabel())

        return cellView
    }

    func tableView(_: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard !timezones.isEmpty else {
            return 100
        }

        if let userFontSize = dataStore.retrieve(key: CLUserFontSizePreference) as? NSNumber,
           timezones.count > row,
           let relativeDisplay = dataStore.retrieve(key: CLRelativeDateKey) as? NSNumber
        {
            let model = timezones[row]
            let shouldShowSunrise = dataStore.shouldDisplay(.sunrise)

            var rowHeight: Int = userFontSize == 4 ? 60 : 65

            if relativeDisplay.intValue == 3 {
                rowHeight -= 5
            }

            if shouldShowSunrise, model.selectionType == .city {
                rowHeight += 8
            }

            if let note = model.note, !note.isEmpty {
                rowHeight += userFontSize.intValue + 15
            } else if TimezoneDataOperations(with: model, store: dataStore).nextDaylightSavingsTransitionIfAvailable(with: sliderValue) != nil {
                rowHeight += userFontSize.intValue + 15
            }

            if model.isSystemTimezone {
                rowHeight += 2
            }

            rowHeight += (userFontSize.intValue * 2)
            return CGFloat(rowHeight)
        }

        return 1
    }

    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        guard !timezones.isEmpty else {
            return []
        }

        let windowController = FloatingWindowController.shared()

        if edge == .trailing {
            let swipeToDelete = NSTableViewRowAction(style: .destructive,
                                                     title: "Delete",
                                                     handler: { _, row in

                                                         if self.timezones[row].isSystemTimezone {
                                                             self.showAlertForDeletingAHomeRow(row, tableView)
                                                             return
                                                         }

                                                         let indexSet = IndexSet(integer: row)

                                                         tableView.removeRows(at: indexSet, withAnimation: NSTableView.AnimationOptions())

                                                         if self.dataStore.shouldDisplay(ViewType.showAppInForeground) {
                                                             windowController.deleteTimezone(at: row)
                                                         } else {
                                                             guard let panelController = PanelController.panel() else { return }
                                                             panelController.deleteTimezone(at: row)
                                                         }

                                                     })

            if #available(OSX 11.0, *) {
                swipeToDelete.image = Themer.shared().filledTrashImage()

            } else {
                swipeToDelete.image = NSImage(named: NSImage.Name("Trash"))
            }

            return [swipeToDelete]
        }

        return []
    }

    private func showAlertForDeletingAHomeRow(_ row: Int, _ tableView: NSTableView) {
        NSApplication.shared.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Confirm deleting the home row? 😅"
        alert.informativeText = "This row is automatically updated when Clocker detects a system timezone change. Are you sure you want to delete this?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")

        let response = alert.runModal()
        if response.rawValue == 1000 {
            OperationQueue.main.addOperation { [weak self] in
                guard let sSelf = self else { return }

                let indexSet = IndexSet(integer: row)

                tableView.removeRows(at: indexSet, withAnimation: NSTableView.AnimationOptions.slideUp)

                if sSelf.dataStore.shouldDisplay(ViewType.showAppInForeground) {
                    let windowController = FloatingWindowController.shared()
                    windowController.deleteTimezone(at: row)
                } else {
                    guard let panelController = PanelController.panel() else { return }
                    panelController.deleteTimezone(at: row)
                }
            }
        }
    }
}

extension TimezoneDataSource: PanelTableViewDelegate {
    func tableView(_ table: NSTableView, didHoverOver row: NSInteger) {
        for rowIndex in 0 ..< table.numberOfRows {
            if let rowCellView = table.view(atColumn: 0, row: rowIndex, makeIfNecessary: false) as? TimezoneCellView {
                if row == -1 {
                    rowCellView.extraOptions.alphaValue = 0.5
                    continue
                }

                rowCellView.extraOptions.alphaValue = (rowIndex == row) ? 1 : 0.5
                if rowIndex == row, let hoverString = hoverStringForSelectedRow(row: row), sliderValue == 0 {
                    rowCellView.relativeDate.stringValue = hoverString
                }
            }
        }
    }

    private func hoverStringForSelectedRow(row: Int) -> String? {
        let currentModel = timezones[row]
        if let timezone = TimeZone(identifier: currentModel.timezone()) {
            let offSet = Double(timezone.secondsFromGMT()) / 3600
            let localizedName = timezone.localizedName(for: .shortDaylightSaving, locale: Locale.autoupdatingCurrent) ?? "Error"
            if offSet == 0.0 {
                return "\(localizedName)"
            } else {
                let offSetSign = offSet > 0 ? "+" : CLEmptyString
                let offsetString = "UTC\(offSetSign)\(offSet)"
                return "\(localizedName) (\(offsetString))"
            }
        }
        return nil
    }
}

extension TimezoneCellView {
    func layout(with model: TimezoneData) {
        let shouldDisplay = DataStore.shared().shouldDisplay(.sunrise) && !sunriseSetTime.stringValue.isEmpty

        sunriseSetTime.isHidden = !shouldDisplay
        sunriseImage.isHidden = !shouldDisplay

        // If it's a timezone and not a place, we can't determine the sunrise/sunset time; hide the sunrise image
        if model.selectionType == .timezone, model.latitude == nil, model.longitude == nil {
            sunriseImage.isHidden = true
        }

        setupLayout()
    }
}

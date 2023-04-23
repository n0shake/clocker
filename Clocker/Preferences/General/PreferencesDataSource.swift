// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit

struct PreferencesDataSourceConstants {
    static let timezoneNameIdentifier = "formattedAddress"
    static let customLabelIdentifier = "label"
    static let availableTimezoneIdentifier = "availableTimezones"
    static let favoriteTimezoneIdentifier = "favouriteTimezone"
}

protocol PreferenceSelectionUpdates: AnyObject {
    func preferenceSelectionDataSourceMarkAsFavorite(_ dataObject: TimezoneData)
    func preferenceSelectionDataSourceUnfavourite(_ dataObject: TimezoneData)
    func preferenceSelectionDataSourceRefreshTimezoneTable()
    func preferenceSelectionDataSourceRefreshMainTableView()
    func preferenceSelectionDataSourceTableViewSelectionDidChange(_ status: Bool)
    func preferenceSelectionDataSourceTable(didClick tableColumn: NSTableColumn)
}

class PreferencesDataSource: NSObject {
    private weak var updateDelegate: PreferenceSelectionUpdates?
    private let store: DataStore
    var selectedTimezones: [Data] {
        return store.timezones()
    }

    init(with store: DataStore, callbackDelegate delegate: PreferenceSelectionUpdates) {
        self.store = store
        updateDelegate = delegate
        super.init()
    }
}

extension PreferencesDataSource: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView {
            updateDelegate?.preferenceSelectionDataSourceTableViewSelectionDidChange(tableView.selectedRow == -1)
        }
    }

    func tableView(_: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.clocker_archive(with: rowIndexes)

        pboard.declareTypes([.dragSession], owner: self)
        pboard.setData(data, forType: .dragSession)

        return true
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation _: NSTableView.DropOperation) -> Bool {
        var newOrder = selectedTimezones

        var destination = row

        if row == newOrder.count {
            destination -= 1
        }

        let pBoard = info.draggingPasteboard

        guard let data = pBoard.data(forType: .dragSession) else {
            assertionFailure("Data was unexpectedly nil")
            return false
        }

        guard let rowIndexes = NSKeyedUnarchiver.unarchiveObject(with: data) as? IndexSet, let first = rowIndexes.first else {
            assertionFailure("Row was unexpectedly nil")
            return false
        }

        let currentObject = newOrder[first]

        newOrder.remove(at: first)

        newOrder.insert(currentObject, at: destination)

        store.setTimezones(newOrder)

        tableView.reloadData()

        updateDelegate?.preferenceSelectionDataSourceRefreshMainTableView()

        tableView.deselectRow(tableView.selectedRow)

        return true
    }

    func tableView(_: NSTableView, validateDrop _: NSDraggingInfo, proposedRow _: Int, proposedDropOperation _: NSTableView.DropOperation) -> NSDragOperation {
        return .every
    }

    func tableView(_: NSTableView, didClick tableColumn: NSTableColumn) {
        updateDelegate?.preferenceSelectionDataSourceTable(didClick: tableColumn)
    }
}

extension PreferencesDataSource: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return selectedTimezones.count
    }

    func tableView(_: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        var selectedDataSource: TimezoneData?

        if selectedTimezones.count > row,
           let model = TimezoneData.customObject(from: selectedTimezones[row])
        {
            selectedDataSource = model
        }

        if tableColumn?.identifier.rawValue == PreferencesDataSourceConstants.timezoneNameIdentifier {
            return handleTimezoneNameIdentifier(selectedDataSource)
        }

        if tableColumn?.identifier.rawValue == PreferencesDataSourceConstants.customLabelIdentifier {
            return selectedDataSource?.customLabel ?? "Error"
        }

        if tableColumn?.identifier.rawValue == PreferencesDataSourceConstants.favoriteTimezoneIdentifier {
            return selectedDataSource?.isFavourite ?? 0
        }

        return nil
    }

    private func handleTimezoneNameIdentifier(_ selectedDataSource: TimezoneData?) -> Any? {
        guard let model = selectedDataSource else {
            return nil
        }

        if let address = model.formattedAddress, address.isEmpty == false {
            return model.formattedAddress
        }

        return model.timezone()
    }

    func tableView(_: NSTableView, setObjectValue object: Any?, for _: NSTableColumn?, row: Int) {
        guard !selectedTimezones.isEmpty, let dataObject = TimezoneData.customObject(from: selectedTimezones[row]) else {
            return
        }

        if let edit = object as? String {
            setNewLabel(edit, for: dataObject, at: row)
        } else if let isFavouriteValue = object as? NSNumber {
            dataObject.isFavourite = isFavouriteValue.intValue
            insert(timezone: dataObject, at: row)
            dataObject.isFavourite == 1 ?
                updateDelegate?.preferenceSelectionDataSourceMarkAsFavorite(dataObject) :
                updateDelegate?.preferenceSelectionDataSourceUnfavourite(dataObject)
            updateStatusItem()
            updateDelegate?.preferenceSelectionDataSourceRefreshTimezoneTable()
        }

        updateDelegate?.preferenceSelectionDataSourceRefreshMainTableView()
    }

    private func setNewLabel(_ label: String, for dataObject: TimezoneData, at row: Int) {
        let formattedValue = label.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)

        if selectedTimezones.count > row {
            Logger.log(object: [
                "Old Label": dataObject.customLabel ?? "Error",
                "New Label": formattedValue,
            ],
            for: "Custom Label Changed")

            dataObject.setLabel(formattedValue)

            insert(timezone: dataObject, at: row)

            updateMenubarTitles()
        } else {
            Logger.log(object: [
                "MethodName": "SetObjectValue",
                "Selected Timezone Count": selectedTimezones.count,
                "Current Row": row,
            ],
            for: "Error in selected row count")
        }
    }

    private func insert(timezone: TimezoneData, at index: Int) {
        let encodedObject = NSKeyedArchiver.clocker_archive(with: timezone)
        var newDefaults = selectedTimezones
        newDefaults[index] = encodedObject
        store.setTimezones(newDefaults)
    }

    private func updateMenubarTitles() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setupMenubarTimer()
        }
    }

    // TODO: This probably does not need to be used
    private func updateStatusItem() {
        guard let statusItem = (NSApplication.shared.delegate as? AppDelegate)?.statusItemForPanel() else {
            return
        }

        statusItem.refresh()
    }
}

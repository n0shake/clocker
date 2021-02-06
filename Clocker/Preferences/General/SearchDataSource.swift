// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreModelKit

enum RowType {
    case timezoneHeader
    case cityHeader
    case city
    case timezone
}

struct TimezoneMetadata {
    let timezone: NSTimeZone
    let tags: Set<String>
    let formattedName: String
    let abbreviation: String
}

class SearchDataSource: NSObject {
    private var searchField: NSSearchField!
    private var finalArray: [RowType] = []
    private var dataTask: URLSessionDataTask? = .none
    private var timezoneMetadataDictionary: [String: [String]] =
        ["GMT+5:30": ["india", "indian", "kolkata", "calcutta", "mumbai", "delhi", "hyderabad", "noida"],
         "PST": ["los", "los angeles", "california", "san francisco", "bay area", "pacific standard time"],
         "PDT": ["los", "los angeles", "california", "san francisco", "bay area", "pacific standard time"],
         "UTC": ["utc", "universal"],
         "EST": ["florida", "new york"],
         "EDT": ["florida", "new york"]]

    private var filteredArray: [Any] = []
    private var timezoneArray: [TimezoneMetadata] = []
    var timezoneFilteredArray: [TimezoneMetadata] = []

    init(with searchField: NSSearchField) {
        super.init()
        self.searchField = searchField
        setupTimezoneDatasource()
        calculateChangesets()
    }

    func cleanupFilterArray() {
        filteredArray = []
    }

    func setFilteredArrayValue(_ newArray: [Any]) {
        filteredArray = newArray
    }

    func placeForRow(_ row: Int) -> RowType {
        return finalArray[row]
    }

    func retrieveFilteredResult(_ index: Int) -> TimezoneData? {
        guard let dataObject = filteredArray[index % filteredArray.count] as? TimezoneData else {
            assertionFailure("Data was unexpectedly nil")
            return nil
        }

        return dataObject
    }

    private func setupTimezoneDatasource() {
        timezoneArray = []

        let anywhereOnEarth = TimezoneMetadata(timezone: NSTimeZone(abbreviation: "GMT-1200")!,
                                               tags: ["aoe", "anywhere on earth"],
                                               formattedName: "Anywhere on Earth",
                                               abbreviation: "AOE")
        let utcTimezone = TimezoneMetadata(timezone: NSTimeZone(abbreviation: "GMT")!,
                                           tags: ["utc", "gmt", "universal"],
                                           formattedName: "UTC",
                                           abbreviation: "GMT")

        timezoneArray.append(anywhereOnEarth)
        timezoneArray.append(utcTimezone)

        for identifier in TimeZone.knownTimeZoneIdentifiers {
            guard let timezoneObject = TimeZone(identifier: identifier) else {
                continue
            }
            let abbreviation = timezoneObject.abbreviation() ?? "Empty"
            let identifier = timezoneObject.identifier
            var tags: Set<String> = [abbreviation.lowercased(), identifier.lowercased()]
            var extraTags: [String] = []
            if let tagsPresent = timezoneMetadataDictionary[abbreviation] {
                extraTags = tagsPresent
            }

            extraTags.forEach { tag in
                tags.insert(tag)
            }

            let timezoneIdentifier = NSTimeZone(name: identifier)!
            let timezoneMetadata = TimezoneMetadata(timezone: timezoneIdentifier,
                                                    tags: tags,
                                                    formattedName: identifier,
                                                    abbreviation: abbreviation)
            timezoneArray.append(timezoneMetadata)
        }
    }

    @discardableResult func calculateChangesets() -> Bool {
        var changesets: [RowType] = []

        func addTimezonesIfNeeded(_ data: [TimezoneMetadata]) {
            if !data.isEmpty {
                changesets.append(.timezoneHeader)
            }
            data.forEach { _ in
                changesets.append(.timezone)
            }
        }

        if searchField.stringValue.isEmpty {
            addTimezonesIfNeeded(timezoneArray)
        } else {
            if !filteredArray.isEmpty {
                changesets.append(.cityHeader)
            }
            filteredArray.forEach { _ in
                changesets.append(.city)
            }
            addTimezonesIfNeeded(timezoneFilteredArray)
        }

        if changesets != finalArray {
            finalArray = changesets
            return true
        }

        return false
    }

    func searchTimezones(_ searchString: String) {
        timezoneFilteredArray = []

        timezoneFilteredArray = timezoneArray.filter { (timezoneMetadata) -> Bool in
            let tags = timezoneMetadata.tags
            for tag in tags where tag.contains(searchString) {
                return true
            }
            return false
        }
    }

    func retrieveSelectedTimezone(_ searchString: String, _ selectedIndex: Int) -> TimezoneMetadata {
        return searchString.isEmpty == false ? timezoneFilteredArray[selectedIndex % timezoneFilteredArray.count] :
            timezoneArray[selectedIndex - 1]
    }
}

extension SearchDataSource: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return finalArray.count
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let currentRowType = finalArray[row]

        switch currentRowType {
        case .timezoneHeader, .cityHeader:
            return headerCell(tableView, currentRowType)
        case .timezone:
            return timezoneCell(tableView, currentRowType, row)
        case .city:
            return cityCell(tableView, currentRowType, row)
        }
    }
}

extension SearchDataSource: NSTableViewDelegate {
    func tableView(_: NSTableView, isGroupRow row: Int) -> Bool {
        let currentRowType = finalArray[row]
        return
            currentRowType == .timezoneHeader ||
            currentRowType == .cityHeader
    }

    func tableView(_: NSTableView, shouldSelectRow row: Int) -> Bool {
        let currentRowType = finalArray[row]
        return !(currentRowType == .timezoneHeader || currentRowType == .cityHeader)
    }

    func tableView(_: NSTableView, heightOfRow _: Int) -> CGFloat {
        return 30
    }
}

extension SearchDataSource {
    private func timezoneCell(_ tableView: NSTableView, _: RowType, _ row: Int) -> NSView? {
        if let message = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "resultCell"), owner: self) as? SearchResultTableViewCell {
            let datasource = searchField.stringValue.isEmpty ? timezoneArray : timezoneFilteredArray
            guard !datasource.isEmpty else {
                return nil
            }
            let index = searchField.stringValue.isEmpty ? row - 1 : row
            message.sourceName.stringValue = datasource[index % datasource.count].formattedName + " (\(datasource[index % datasource.count].abbreviation))"
            return message
        }
        return nil
    }

    private func cityCell(_ tableView: NSTableView, _: RowType, _ row: Int) -> NSView? {
        if let cityCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "resultCell"), owner: self) as? SearchResultTableViewCell {
            guard let timezoneData = filteredArray[row % filteredArray.count] as? TimezoneData else {
                assertionFailure()
                return nil
            }

            cityCell.sourceName.stringValue = timezoneData.formattedAddress ?? "Error"
            return cityCell
        }

        return nil
    }

    private func headerCell(_ tableView: NSTableView, _ headerType: RowType) -> NSView? {
        if let message = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "headerCell"), owner: self) as? HeaderTableViewCell {
            message.headerField.stringValue = headerType == .timezoneHeader ? "Timezones" : "Places"
            return message
        }

        return nil
    }
}

class SearchResultTableViewCell: NSTableCellView {
    @IBOutlet var sourceName: NSTextField!
}

class HeaderTableViewCell: NSTableCellView {
    @IBOutlet var headerField: NSTextField!
}

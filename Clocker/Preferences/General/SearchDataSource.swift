// Copyright © 2015 Abhishek Banthia

import Cocoa

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
        ["IST": ["india", "indian", "kolkata", "calcutta", "mumbai", "delhi", "hyderabad", "noida"],
         "PST": ["los", "los angeles", "california", "san francisco", "bay area", "pacific standard time"],
         "UTC": ["utc", "universal"],
         "EST": ["florida", "new york"]]

    var filteredArray: [Any] = []
    var timezoneArray: [TimezoneMetadata] = []
    var timezoneFilteredArray: [TimezoneMetadata] = []

    init(with searchField: NSSearchField) {
        super.init()
        self.searchField = searchField
        setupTimezoneDatasource()
        calculateArray()
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

    private func setupTimezoneDatasource() {
        timezoneArray = []

        let anywhereOnEarth = TimezoneMetadata(timezone: NSTimeZone(abbreviation: "GMT-1200")!,
                                               tags: ["aoe", "anywhere on earth"],
                                               formattedName: "Anywhere on Earth",
                                               abbreviation: "AOE")
        timezoneArray.append(anywhereOnEarth)

        for (abbreviation, timezone) in TimeZone.abbreviationDictionary {
            var tags: Set<String> = [abbreviation.lowercased(), timezone.lowercased()]
            var extraTags: [String] = []
            if let tagsPresent = timezoneMetadataDictionary[abbreviation] {
                extraTags = tagsPresent
            }

            extraTags.forEach { tag in
                tags.insert(tag)
            }

            let timezoneIdentifier = NSTimeZone(name: timezone)!
            let timezoneMetadata = TimezoneMetadata(timezone: timezoneIdentifier,
                                                    tags: tags,
                                                    formattedName: timezone,
                                                    abbreviation: abbreviation)
            timezoneArray.append(timezoneMetadata)
        }
    }

    func calculateArray() {
        finalArray = []

        func addTimezonesIfNeeded(_ data: [TimezoneMetadata]) {
            if !data.isEmpty {
                finalArray.append(.timezoneHeader)
            }
            data.forEach { _ in
                finalArray.append(.timezone)
            }
        }

        if searchField.stringValue.isEmpty {
            addTimezonesIfNeeded(timezoneArray)
        } else {
            if !filteredArray.isEmpty {
                finalArray.append(.cityHeader)
            }
            filteredArray.forEach { _ in
                finalArray.append(.city)
            }
            addTimezonesIfNeeded(timezoneFilteredArray)
        }
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

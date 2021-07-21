// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreModelKit

enum RowType {
    case city
    case timezone
}

enum SearchLocation {
    case onboarding
    case preferences
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
    private var location: SearchLocation = .preferences
    private var dataTask: URLSessionDataTask? = .none
    private var timezoneMetadataDictionary: [String: [String]] =
        ["GMT+5:30": ["india", "indian", "kolkata", "calcutta", "mumbai", "delhi", "hyderabad", "noida"],
         "PST": ["los", "los angeles", "california", "san francisco", "bay area", "pacific standard time"],
         "PDT": ["los", "los angeles", "california", "san francisco", "bay area", "pacific standard time"],
         "UTC": ["utc", "universal"],
         "EST": ["florida", "new york"],
         "EDT": ["florida", "new york"]]

    private var filteredArray: [TimezoneData] = [] // Filtered results from the Google API
    private var timezoneArray: [TimezoneMetadata] = [] // All timezones
    var timezoneFilteredArray: [TimezoneMetadata] = [] // Filtered timezones list based on search input

    init(with searchField: NSSearchField, location: SearchLocation = .preferences) {
        super.init()
        self.searchField = searchField
        self.location = location
        setupTimezoneDatasource()
        calculateChangesets()
    }

    func cleanupFilterArray() {
        filteredArray = []
    }

    func setFilteredArrayValue(_ newArray: [TimezoneData]) {
        filteredArray = newArray
    }

    func placeForRow(_ row: Int) -> RowType {
        return finalArray[row]
    }

    // Returns result from finalArray based on the type i.e. city or timezone
    func retrieveResult(_ row: Int) -> Any? {
        let currentRowType = finalArray[row]

        switch currentRowType {
        case .timezone:
            let datasource = searchField.stringValue.isEmpty ? timezoneArray : timezoneFilteredArray
            return datasource[row % datasource.count]
        case .city:
            if filteredArray.count == 0 {
                return nil
            }
            let timezoneData = filteredArray[row % filteredArray.count]
            return timezoneData
        }
    }

    func retrieveFilteredResultFromGoogleAPI(_ index: Int) -> TimezoneData? {
        if index >= filteredArray.count {
            return nil
        }
        
        return filteredArray[index % filteredArray.count]
    }

    func resultsCount() -> Int {
        return finalArray.count
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
            data.forEach { _ in
                changesets.append(.timezone)
            }
        }

        if searchField.stringValue.isEmpty, location == .preferences {
            addTimezonesIfNeeded(timezoneArray)
        } else {
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

        timezoneFilteredArray = timezoneArray.filter { timezoneMetadata -> Bool in
            let tags = timezoneMetadata.tags
            for tag in tags where tag.contains(searchString) {
                return true
            }
            return false
        }
    }

    func retrieveSelectedTimezone(_ selectedIndex: Int) -> TimezoneMetadata {
        return searchField.stringValue.isEmpty == false ? timezoneFilteredArray[selectedIndex % timezoneFilteredArray.count] :
            timezoneArray[selectedIndex]
    }
}

extension SearchDataSource: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return finalArray.count
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let currentRowType = finalArray[row]

        switch currentRowType {
        case .timezone:
            return timezoneCell(tableView, currentRowType, row)
        case .city:
            return cityCell(tableView, currentRowType, row)
        }
    }
}

extension SearchDataSource: NSTableViewDelegate {
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
            message.sourceName.stringValue = datasource[row % datasource.count].formattedName + " (\(datasource[row % datasource.count].abbreviation))"
            return message
        }
        return nil
    }

    private func cityCell(_ tableView: NSTableView, _: RowType, _ row: Int) -> NSView? {
        if let cityCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "resultCell"), owner: self) as? SearchResultTableViewCell {
            let timezoneData = filteredArray[row % filteredArray.count]
            cityCell.sourceName.stringValue = timezoneData.formattedAddress ?? "Error"
            return cityCell
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

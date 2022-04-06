// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit

/* Behaviour is as follows:

 - When the user first sees the screen, show all available timezones
 - When the user searches and tap enters, filter on both cities/locations + timezones
 - On double-tapping, add the timezone to the list
 - Show confirmation with undo screen

 */

class OnboardingSearchController: NSViewController {
    @IBOutlet private var appName: NSTextField!
    @IBOutlet private var onboardingTypeLabel: NSTextField!
    @IBOutlet private var searchBar: NSSearchField!
    @IBOutlet private var resultsTableView: NSTableView!
    @IBOutlet private var accessoryLabel: NSTextField!
    @IBOutlet var undoButton: NSButton!

    private var searchResultsDataSource: SearchDataSource!
    private var dataTask: URLSessionDataTask? = .none
    private var themeDidChangeNotification: NSObjectProtocol?

    private var geocodingKey: String = {
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path),
              let apiKey = dictionary["GeocodingKey"] as? String
        else {
            assertionFailure("Unable to find the API key")
            return ""
        }
        return apiKey
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true
        
        resultsTableView.isHidden = true
        resultsTableView.delegate = self
        resultsTableView.setAccessibility("ResultsTableView")
        resultsTableView.dataSource = self
        resultsTableView.target = self
        resultsTableView.doubleAction = #selector(doubleClickAction(_:))
        if #available(OSX 11.0, *) {
            resultsTableView.style = .fullWidth
        }

        setup()

        themeDidChangeNotification = NotificationCenter.default.addObserver(forName: .themeDidChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            self.setup()
        }

        resultsTableView.reloadData()

        func setupUndoButton() {
            let font = NSFont(name: "Avenir", size: 13) ?? NSFont.systemFont(ofSize: 13)
            let attributes = [NSAttributedString.Key.foregroundColor: NSColor.linkColor,
                              NSAttributedString.Key.font: font]
            undoButton.attributedTitle = NSAttributedString(string: "UNDO", attributes: attributes)
            undoButton.setAccessibility("UndoButton")
        }

        setupUndoButton()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        searchResultsDataSource = SearchDataSource(with: searchBar, location: .onboarding)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        searchResultsDataSource = nil
    }

    deinit {
        if let themeDidChangeNotif = themeDidChangeNotification {
            NotificationCenter.default.removeObserver(themeDidChangeNotif)
        }
    }

    @objc func doubleClickAction(_ tableView: NSTableView) {
        [accessoryLabel].forEach { $0?.isHidden = false }

        if tableView.selectedRow >= 0, tableView.selectedRow < searchResultsDataSource.resultsCount() {
            let selectedType = searchResultsDataSource.placeForRow(resultsTableView.selectedRow)
            switch selectedType {
            case .city:
                if let filteredGoogleResult = searchResultsDataSource.retrieveFilteredResultFromGoogleAPI(resultsTableView.selectedRow) {
                    addTimezoneToDefaults(filteredGoogleResult)
                }
                return
            case .timezone:
                cleanupAfterInstallingTimezone()
                return
            }
        }
    }

    private func cleanupAfterInstallingTimezone() {
        let data = TimezoneData()
        data.setLabel(CLEmptyString)

        let currentSelection = searchResultsDataSource.retrieveSelectedTimezone(resultsTableView.selectedRow)

        let metaInfo = metadata(for: currentSelection)
        data.timezoneID = metaInfo.0.name
        data.formattedAddress = metaInfo.1.formattedName
        data.selectionType = .timezone
        data.isSystemTimezone = metaInfo.0.name == NSTimeZone.system.identifier

        let operationObject = TimezoneDataOperations(with: data)
        operationObject.saveObject()

        searchResultsDataSource.cleanupFilterArray()
        searchResultsDataSource.timezoneFilteredArray = []
        searchResultsDataSource.calculateChangesets()
        searchBar.stringValue = CLEmptyString

        accessoryLabel.stringValue = "Added \(metaInfo.1.formattedName)."
        undoButton.isHidden = false
        setupLabelHidingTimer()

        resultsTableView.reloadData()
        resultsTableView.isHidden = true
    }

    private func metadata(for selection: TimezoneMetadata) -> (NSTimeZone, TimezoneMetadata) {
        if selection.formattedName == "Anywhere on Earth" {
            return (NSTimeZone(name: "GMT-1200")!, selection)
        } else if selection.formattedName == "UTC" {
            return (NSTimeZone(name: "GMT")!, selection)
        } else {
            return (selection.timezone, selection)
        }
    }

    private func setupLabelHidingTimer() {
        Timer.scheduledTimer(withTimeInterval: 5,
                             repeats: false)
        { _ in
            OperationQueue.main.addOperation {
                self.setInfoLabel(CLEmptyString)
            }
        }
    }

    private func addTimezoneToDefaults(_ timezone: TimezoneData) {
        if resultsTableView.selectedRow == -1 {
            setInfoLabel(PreferencesConstants.noTimezoneSelectedErrorMessage)
            setupLabelHidingTimer()
            return
        }

        if DataStore.shared().timezones().count >= 100 {
            setInfoLabel(PreferencesConstants.maxTimezonesErrorMessage)
            setupLabelHidingTimer()
            return
        }

        guard let latitude = timezone.latitude, let longitude = timezone.longitude else {
            setInfoLabel("Unable to fetch latitude/longitude. Try again.")
            return
        }

        fetchTimezone(for: latitude, and: longitude, timezone)
    }

    // We want to display the undo button only if we've added a timezone.
    // If else, we want it hidden. This below method ensures that.
    private func setInfoLabel(_ text: String) {
        accessoryLabel.stringValue = text
        undoButton.isHidden = true
    }

    /// Returns true if there's an error.
    private func handleEdgeCase(for response: Data?) -> Bool {
        func setErrorPlaceholders() {
            setInfoLabel("No timezone found! Try entering an exact name.")
            searchBar.placeholderString = placeholders.randomElement()
        }

        guard let json = response, let jsonUnserialized = try? JSONSerialization.jsonObject(with: json, options: .allowFragments), let unwrapped = jsonUnserialized as? [String: Any] else {
            setErrorPlaceholders()
            return true
        }

        if let status = unwrapped["status"] as? String, status == ResultStatus.zeroResults {
            setErrorPlaceholders()
            return true
        }
        return false
    }

    private func fetchTimezone(for latitude: Double, and longitude: Double, _ dataObject: TimezoneData) {
        if NetworkManager.isConnected() == false || ProcessInfo.processInfo.arguments.contains("mockTimezoneDown") {
            setInfoLabel(PreferencesConstants.noInternetConnectivityError)
            searchResultsDataSource.cleanupFilterArray()
            resultsTableView.reloadData()
            return
        }

        resultsTableView.isHidden = true

        let tuple = "\(latitude),\(longitude)"
        let timeStamp = Date().timeIntervalSince1970
        let urlString = "https://maps.googleapis.com/maps/api/timezone/json?location=\(tuple)&timestamp=\(timeStamp)&key=\(geocodingKey)"

        NetworkManager.task(with: urlString) { [weak self] response, error in

            guard let self = self else { return }

            OperationQueue.main.addOperation {
                if self.handleEdgeCase(for: response) == true {
                    return
                }

                if error == nil, let json = response, let response = json.decodeTimezone() {
                    if self.resultsTableView.selectedRow >= 0, self.resultsTableView.selectedRow < self.searchResultsDataSource.resultsCount() {
                        var filteredAddress = "Error"

                        if let address = dataObject.formattedAddress {
                            filteredAddress = address.filteredName()
                        }

                        let newTimeZone = [
                            CLTimezoneID: response.timeZoneId,
                            CLTimezoneName: filteredAddress,
                            CLPlaceIdentifier: dataObject.placeID!,
                            "latitude": latitude,
                            "longitude": longitude,
                            "nextUpdate": CLEmptyString,
                            CLCustomLabel: filteredAddress,
                        ] as [String: Any]

                        DataStore.shared().addTimezone(TimezoneData(with: newTimeZone))

                        Logger.log(object: ["PlaceName": filteredAddress, "Timezone": response.timeZoneId], for: "Filtered Address")

                        self.accessoryLabel.stringValue = "Added \(filteredAddress)."
                        self.undoButton.isHidden = false

                        Logger.log(object: ["Place Name": filteredAddress],
                                   for: "Added Timezone while Onboarding")
                    }

                    // Cleanup.
                    self.resetSearchView()
                } else {
                    OperationQueue.main.addOperation {
                        if error?.localizedDescription == "The Internet connection appears to be offline." {
                            self.setInfoLabel(PreferencesConstants.noInternetConnectivityError)
                        } else {
                            self.setInfoLabel(PreferencesConstants.noInternetConnectivityError)
                        }
                    }
                }
            }
        }
    }

    private var placeholders: [String] = ["New York", "Los Angeles", "Chicago",
                                          "Moscow", "Tokyo", "Istanbul",
                                          "Beijing", "Shanghai", "Sao Paulo",
                                          "Cairo", "Mexico City", "London",
                                          "Seoul", "Copenhagen", "Tel Aviv",
                                          "Bern", "San Francisco", "Los Angeles",
                                          "Sydney NSW", "Berlin"]

    private func setup() {
        appName.stringValue = "Quick Add Locations".localized()
        onboardingTypeLabel.stringValue = "More search options in Clocker Preferences.".localized()
        setInfoLabel(CLEmptyString)
        searchBar.bezelStyle = .roundedBezel
        searchBar.placeholderString = "Press Enter to Search!"
        searchBar.delegate = self
        searchBar.setAccessibility("MainSearchField")

        resultsTableView.backgroundColor = Themer.shared().mainBackgroundColor()
        resultsTableView.enclosingScrollView?.backgroundColor = Themer.shared().mainBackgroundColor()

        [appName, onboardingTypeLabel, accessoryLabel].forEach { $0?.textColor = Themer.shared().mainTextColor() }
        [accessoryLabel].forEach { $0?.isHidden = true }
    }

    @IBAction func search(_ sender: NSSearchField) {
        resultsTableView.deselectAll(nil)

        let searchString = sender.stringValue

        if searchString.isEmpty {
            resetSearchView()
            setInfoLabel(CLEmptyString)
            return
        }

        if resultsTableView.isHidden {
            resultsTableView.isHidden = false
        }

        accessoryLabel.isHidden = false

        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(OnboardingSearchController.actualSearch), with: nil, afterDelay: 0.2)
    }

    fileprivate func resetIfNeccesary(_ searchString: String) {
        if searchString.isEmpty {
            resetSearchView()
            setInfoLabel(CLEmptyString)
        }
    }

    @objc func actualSearch() {
        func setupForError() {
            searchResultsDataSource.calculateChangesets()
            resultsTableView.isHidden = true
        }

        let userPreferredLanguage = Locale.preferredLanguages.first ?? "en-US"

        var searchString = searchBar.stringValue

        let words = searchString.components(separatedBy: CharacterSet.whitespacesAndNewlines)

        searchString = words.joined(separator: CLEmptyString)

        if searchString.count < 3 {
            resetIfNeccesary(searchString)
            return
        }

        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?address=\(searchString)&key=\(geocodingKey)&language=\(userPreferredLanguage)"

        dataTask = NetworkManager.task(with: urlString,
                                       completionHandler: { [weak self] response, error in

                                           guard let self = self else { return }

                                           OperationQueue.main.addOperation {
                                               let currentSearchBarValue = self.searchBar.stringValue

                                               let words = currentSearchBarValue.components(separatedBy: CharacterSet.whitespacesAndNewlines)

                                               if words.joined(separator: CLEmptyString) != searchString {
                                                   return
                                               }

                                               self.searchResultsDataSource.cleanupFilterArray()
                                               self.searchResultsDataSource.timezoneFilteredArray = []

                                               if let errorPresent = error {
                                                   self.findLocalSearchResultsForTimezones()
                                                   if self.searchResultsDataSource.timezoneFilteredArray.count == 0 {
                                                       self.presentErrorMessage(errorPresent.localizedDescription)
                                                       setupForError()
                                                       return
                                                   }

                                                   self.prepareUIForPresentingResults()
                                                   return
                                               }

                                               guard let data = response else {
                                                   self.setInfoLabel(PreferencesConstants.tryAgainMessage)
                                                   setupForError()
                                                   return
                                               }

                                               let searchResults = data.decode()

                                               if searchResults?.status == ResultStatus.zeroResults {
                                                   self.setInfoLabel("No results! 😔 Try entering the exact name.")
                                                   setupForError()
                                                   return
                                               }

                                               self.appendResultsToFilteredArray(searchResults!.results)
                                               self.findLocalSearchResultsForTimezones()
                                               self.prepareUIForPresentingResults()
                                           }
                                       })
    }

    private func presentErrorMessage(_ errorMessage: String) {
        if errorMessage == PreferencesConstants.offlineErrorMessage {
            setInfoLabel(PreferencesConstants.noInternetConnectivityError)
        } else {
            setInfoLabel(PreferencesConstants.tryAgainMessage)
        }
    }

    private func findLocalSearchResultsForTimezones() {
        let lowercasedSearchString = searchBar.stringValue.lowercased()
        searchResultsDataSource.searchTimezones(lowercasedSearchString)
    }

    private func prepareUIForPresentingResults() {
        setInfoLabel(CLEmptyString)
        if searchResultsDataSource.calculateChangesets() {
            resultsTableView.isHidden = false
            resultsTableView.reloadData()
        }
    }

    private func appendResultsToFilteredArray(_ results: [SearchResult.Result]) {
        let finalTimezones: [TimezoneData] = results.map { result -> TimezoneData in
            let location = result.geometry.location
            let latitude = location.lat
            let longitude = location.lng
            let formattedAddress = result.formattedAddress

            let totalPackage = [
                "latitude": latitude,
                "longitude": longitude,
                CLTimezoneName: formattedAddress,
                CLCustomLabel: formattedAddress,
                CLTimezoneID: CLEmptyString,
                CLPlaceIdentifier: result.placeId,
            ] as [String: Any]

            return TimezoneData(with: totalPackage)
        }

        searchResultsDataSource.setFilteredArrayValue(finalTimezones)
    }

    private func resetSearchView() {
        searchResultsDataSource.cleanupFilterArray()
        searchResultsDataSource.timezoneFilteredArray = []
        searchResultsDataSource.calculateChangesets()
        resultsTableView.reloadData()
        searchBar.stringValue = CLEmptyString
        searchBar.placeholderString = "Press Enter to Search"
    }

    @IBAction func undoAction(_: Any) {
        DataStore.shared().removeLastTimezone()
        setInfoLabel("Removed.")
    }
}

extension OnboardingSearchController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return searchResultsDataSource != nil ? searchResultsDataSource.resultsCount() : 0
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        if let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "resultCellView"), owner: self) as? ResultTableViewCell, row >= 0, row < searchResultsDataSource.resultsCount() {
            let currentSelection = searchResultsDataSource.retrieveResult(row)
            if let timezone = currentSelection as? TimezoneMetadata {
                result.result.stringValue = " \(timezone.formattedName)"
            } else if let location = currentSelection as? TimezoneData {
                result.result.stringValue = " \(location.formattedAddress ?? "Place Name")"
            }

            result.result.textColor = Themer.shared().mainTextColor()
            return result
        }

        return nil
    }
}

extension OnboardingSearchController: NSTableViewDelegate {
    func tableView(_: NSTableView, heightOfRow row: Int) -> CGFloat {
        if row == 0, searchResultsDataSource.resultsCount() == 0 {
            return 30
        }

        return 36
    }

    func tableView(_: NSTableView, shouldSelectRow row: Int) -> Bool {
        return searchResultsDataSource.resultsCount() == 0 ? row != 0 : true
    }

    func tableView(_: NSTableView, rowViewForRow _: Int) -> NSTableRowView? {
        return OnboardingSelectionTableRowView()
    }
}

class ResultSectionHeaderTableViewCell: NSTableCellView {
    @IBOutlet var headerLabel: NSTextField!
}

class OnboardingSelectionTableRowView: NSTableRowView {
    override func drawSelection(in _: NSRect) {
        if selectionHighlightStyle != .none {
            let selectionRect = bounds.insetBy(dx: 1, dy: 1)
            NSColor(calibratedWhite: 0.4, alpha: 1).setStroke()
            NSColor(calibratedWhite: 0.4, alpha: 1).setFill()
            let selectionPath = NSBezierPath(roundedRect: selectionRect, xRadius: 6, yRadius: 6)
            selectionPath.fill()
            selectionPath.stroke()
        }
    }
}

class ResultTableViewCell: NSTableCellView {
    @IBOutlet var result: NSTextField!
}

extension OnboardingSearchController: NSSearchFieldDelegate {
    func control(_ control: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard let searchField = control as? NSSearchField else {
            return false
        }

        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            self.search(searchField)
            return true
        } else if commandSelector == #selector(NSResponder.deleteForward(_:)) || commandSelector == #selector(NSResponder.deleteBackward(_:)) {
            // Handle DELETE key
            self.search(searchField)
            return false
        }

        Logger.info("Not Handled")
        // return true if the action was handled; otherwise false
        return false
    }

    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        search(sender)
    }
}

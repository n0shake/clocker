// Copyright © 2015 Abhishek Banthia

import Cocoa

enum States {
    case initial
    case search
    case error
}

class OnboardingSearchController: NSViewController {
    @IBOutlet private var appName: NSTextField!
    @IBOutlet private var onboardingTypeLabel: NSTextField!
    @IBOutlet private var searchBar: ClockerSearchField!
    @IBOutlet private var resultsTableView: NSTableView!
    @IBOutlet private var accessoryLabel: NSTextField!
    @IBOutlet var undoButton: NSButton!

    private var results: [TimezoneData] = []
    private var dataTask: URLSessionDataTask? = .none
    private var themeDidChangeNotification: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true

        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.target = self
        resultsTableView.doubleAction = #selector(doubleClickAction(_:))

        setup()

        themeDidChangeNotification = NotificationCenter.default.addObserver(forName: .themeDidChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            self.setup()
        }

        resultsTableView.reloadData()

        func setupUndoButton() {
            let font = NSFont(name: "Avenir", size: 13)!
            let attributes = [NSAttributedString.Key.foregroundColor: NSColor.linkColor,
                              NSAttributedString.Key.font: font]
            undoButton.attributedTitle = NSAttributedString(string: "UNDO", attributes: attributes)
        }

        setupUndoButton()
    }

    deinit {
        if let themeDidChangeNotif = themeDidChangeNotification {
            NotificationCenter.default.removeObserver(themeDidChangeNotif)
        }
    }

    @objc func doubleClickAction(_: NSTableView?) {
        [accessoryLabel].forEach { $0?.isHidden = false }

        if resultsTableView.selectedRow >= 0, resultsTableView.selectedRow < results.count {
            let selectedTimezone = results[resultsTableView.selectedRow]

            addTimezoneToDefaults(selectedTimezone)
        }
    }

    private func addTimezoneToDefaults(_ timezone: TimezoneData) {
        func setupLabelHidingTimer() {
            Timer.scheduledTimer(withTimeInterval: 5,
                                 repeats: false) { _ in
                OperationQueue.main.addOperation {
                    self.accessoryLabel.stringValue = CLEmptyString
                }
            }
        }

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

        if let status = unwrapped["status"] as? String, status == "ZERO_RESULTS" {
            setErrorPlaceholders()
            return true
        }
        return false
    }

    // Extracting this out for tests
    private func decodeTimezone(from data: Data) -> Timezone? {
        let jsonDecoder = JSONDecoder()
        do {
            let decodedObject = try jsonDecoder.decode(Timezone.self, from: data)
            return decodedObject
        } catch {
            print("decodedObject error: \n\(error)")
            return nil
        }
    }

    private func fetchTimezone(for latitude: Double, and longitude: Double, _ dataObject: TimezoneData) {
        if NetworkManager.isConnected() == false || ProcessInfo.processInfo.arguments.contains("mockTimezoneDown") {
            setInfoLabel(PreferencesConstants.noInternetConnectivityError)
            results = []
            resultsTableView.reloadData()
            return
        }

        resultsTableView.isHidden = true

        let tuple = "\(latitude),\(longitude)"
        let timeStamp = Date().timeIntervalSince1970
        let urlString = "https://maps.googleapis.com/maps/api/timezone/json?location=\(tuple)&timestamp=\(timeStamp)&key=\(CLGeocodingKey)"

        NetworkManager.task(with: urlString) { [weak self] response, error in

            guard let self = self else { return }

            OperationQueue.main.addOperation {
                if self.handleEdgeCase(for: response) == true {
                    return
                }

                if error == nil, let json = response, let response = self.decodeTimezone(from: json) {
                    if self.resultsTableView.selectedRow >= 0, self.resultsTableView.selectedRow < self.results.count {
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
        searchBar.placeholderString = "Search Locations".localized()

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

        if NetworkManager.isConnected() == false {
            setInfoLabel(PreferencesConstants.noInternetConnectivityError)
            return
        }

        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(OnboardingSearchController.actualSearch), with: nil, afterDelay: 0.5)
    }

    @objc func actualSearch() {
        func setupForError() {
            resultsTableView.isHidden = true
        }

        let userPreferredLanguage = Locale.preferredLanguages.first ?? "en-US"

        var searchString = searchBar.stringValue

        let words = searchString.components(separatedBy: CharacterSet.whitespacesAndNewlines)

        searchString = words.joined(separator: CLEmptyString)

        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?address=\(searchString)&key=\(CLGeocodingKey)&language=\(userPreferredLanguage)"

        dataTask = NetworkManager.task(with: urlString,
                                       completionHandler: { [weak self] response, error in

                                           guard let self = self else { return }

                                           OperationQueue.main.addOperation {
                                               print("Search string was: \(searchString)")

                                               let currentSearchBarValue = self.searchBar.stringValue

                                               let words = currentSearchBarValue.components(separatedBy: CharacterSet.whitespacesAndNewlines)

                                               if words.joined(separator: CLEmptyString) != searchString {
                                                   return
                                               }

                                               self.results = []

                                               if let errorPresent = error {
                                                   self.presentErrorMessage(errorPresent.localizedDescription)
                                                   setupForError()
                                                   return
                                               }

                                               guard let data = response else {
                                                   self.setInfoLabel(PreferencesConstants.tryAgainMessage)
                                                   setupForError()
                                                   return
                                               }

                                               let searchResults = self.decode(from: data)

                                               if searchResults?.status == "ZERO_RESULTS" {
                                                   self.setInfoLabel("No results! 😔 Try entering the exact name.")
                                                   setupForError()
                                                   return
                                               }

                                               self.appendResultsToFilteredArray(searchResults!.results)

                                               self.setInfoLabel(CLEmptyString)

                                               self.resultsTableView.reloadData()
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

    private func appendResultsToFilteredArray(_ results: [SearchResult.Result]) {
        results.forEach {
            let location = $0.geometry.location
            let latitude = location.lat
            let longitude = location.lng
            let formattedAddress = $0.formattedAddress

            let totalPackage = [
                "latitude": latitude,
                "longitude": longitude,
                CLTimezoneName: formattedAddress,
                CLCustomLabel: formattedAddress,
                CLTimezoneID: CLEmptyString,
                CLPlaceIdentifier: $0.placeId,
            ] as [String: Any]

            self.results.append(TimezoneData(with: totalPackage))
        }
    }

    // Extracting this out for tests
    private func decode(from data: Data) -> SearchResult? {
        let jsonDecoder = JSONDecoder()
        do {
            let decodedObject = try jsonDecoder.decode(SearchResult.self, from: data)
            return decodedObject
        } catch {
            print("decodedObject error: \n\(error)")
            return nil
        }
    }

    private func resetSearchView() {
        results = []
        resultsTableView.reloadData()
        searchBar.stringValue = CLEmptyString
        searchBar.placeholderString = placeholders.randomElement()
    }

    @IBAction func undoAction(_: Any) {
        DataStore.shared().removeLastTimezone()
        setInfoLabel("Removed.")
    }
}

extension OnboardingSearchController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return results.count
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        if let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "resultCellView"), owner: self) as? ResultTableViewCell, row >= 0, row < results.count {
            let currentTimezone = results[row]
            result.result.stringValue = currentTimezone.formattedAddress ?? "Place Name"
            result.result.textColor = Themer.shared().mainTextColor()
            return result
        }

        return nil
    }
}

extension OnboardingSearchController: NSTableViewDelegate {
    func tableView(_: NSTableView, heightOfRow row: Int) -> CGFloat {
        if row == 0, results.isEmpty {
            return 30
        }

        return 36
    }

    func tableView(_: NSTableView, shouldSelectRow row: Int) -> Bool {
        return results.isEmpty ? row != 0 : true
    }
}

class ResultSectionHeaderTableViewCell: NSTableCellView {
    @IBOutlet var headerLabel: NSTextField!
}

class ResultTableViewCell: NSTableCellView {
    @IBOutlet var result: NSTextField!
}

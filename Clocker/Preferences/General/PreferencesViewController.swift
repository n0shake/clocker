// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit
import StartupKit

struct PreferencesConstants {
    static let noTimezoneSelectedErrorMessage = NSLocalizedString("No Timezone Selected",
                                                                  comment: "Message shown when the user taps on Add without selecting a timezone")
    static let maxTimezonesErrorMessage = NSLocalizedString("Max Timezones Selected",
                                                            comment: "Max Timezones Error Message")
    static let maxCharactersAllowed = NSLocalizedString("Max Search Characters",
                                                        comment: "Max Character Count Allowed Error Message")
    static let noInternetConnectivityError = "You're offline, maybe?".localized()
    static let tryAgainMessage = "Try again, maybe?".localized()
    static let offlineErrorMessage = "The Internet connection appears to be offline.".localized()
    static let hotKeyPathIdentifier = "values.globalPing"
}

class TableHeaderViewCell: NSTableHeaderCell {
    var backgroundColour: NSColor = NSColor.black {
        didSet {
            backgroundColor = backgroundColour
        }
    }

    override init(textCell: String) {
        super.init(textCell: textCell)
        let attributedParagraphStyle = NSMutableParagraphStyle()
        attributedParagraphStyle.alignment = .left
        attributedStringValue = NSAttributedString(string: textCell,
                                                   attributes: [.foregroundColor: Themer.shared().mainTextColor(),
                                                                .font: NSFont(name: "Avenir", size: 14)!,
                                                                .paragraphStyle: attributedParagraphStyle])
        backgroundColor = Themer.shared().textBackgroundColor()
    }

    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.draw(withFrame: cellFrame, in: controlView)
        if !controlView.isHidden {
            backgroundColor?.setFill()
            cellFrame.fill()
            drawInterior(withFrame: cellFrame, in: controlView)
        }
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        if !controlView.isHidden {
            if let avenirFont = NSFont(name: "Avenir", size: 14) {
                font = avenirFont
            }
            textColor = NSColor.white
            let rect = titleRect(forBounds: cellFrame)
            attributedStringValue.draw(in: rect)
        }
    }
}

class PreferencesViewController: ParentViewController {
    private var isActivityInProgress = false {
        didSet {
            OperationQueue.main.addOperation {
                self.isActivityInProgress ? self.progressIndicator.startAnimation(nil) : self.progressIndicator.stopAnimation(nil)
                self.availableTimezoneTableView.isEnabled = !self.isActivityInProgress
                self.addButton.isEnabled = !self.isActivityInProgress
            }
        }
    }

    private var selectedTimeZones: [Data] {
        return DataStore.shared().timezones()
    }

    private lazy var startupManager = StartupManager()
    private var dataTask: URLSessionDataTask? = .none

    private lazy var notimezoneView: NoTimezoneView? = {
        NoTimezoneView(frame: tableview.frame)
    }()

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

    // Sorting
    private var arePlacesSortedInAscendingOrder = false
    private var arePlacesSortedInAscendingTimezoneOrder = false
    private var isTimezoneSortOptionSelected = false
    private var isTimezoneNameSortOptionSelected = false
    private var isLabelOptionSelected = false

    @IBOutlet private var placeholderLabel: NSTextField!
    @IBOutlet private var timezoneTableView: NSTableView!
    @IBOutlet private var availableTimezoneTableView: NSTableView!
    @IBOutlet private var timezonePanel: Panelr!
    @IBOutlet private var progressIndicator: NSProgressIndicator!
    @IBOutlet private var addButton: NSButton!
    @IBOutlet private var recorderControl: SRRecorderControl!
    @IBOutlet private var closeButton: NSButton!

    @IBOutlet private var timezoneSortButton: NSButton!
    @IBOutlet private var timezoneNameSortButton: NSButton!
    @IBOutlet private var labelSortButton: NSButton!
    @IBOutlet private var deleteButton: NSButton!
    @IBOutlet private var addTimezoneButton: NSButton!

    @IBOutlet private var searchField: NSSearchField!
    @IBOutlet private var messageLabel: NSTextField!

    @IBOutlet private var tableview: NSView!
    @IBOutlet private var additionalSortOptions: NSView!
    @IBOutlet var startAtLoginLabel: NSTextField!

    @IBOutlet var startupCheckbox: NSButton!

    private var themeDidChangeNotification: NSObjectProtocol?

    // Selected Timezones Data Source
    private var selectionsDataSource: PreferencesDataSource!
    // Search Results Data Source Handler
    private var searchResultsDataSource: SearchDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshTimezoneTableView),
                                               name: NSNotification.Name.customLabelChanged,
                                               object: nil)

        refreshTimezoneTableView()

        setup()

        setupShortcutObserver()

        darkModeChanges()

        themeDidChangeNotification = NotificationCenter.default.addObserver(forName: .themeDidChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            self.setup()
        }

        searchField.placeholderString = "Enter city, state, country or timezone name"

        selectionsDataSource = PreferencesDataSource(callbackDelegate: self)
        timezoneTableView.dataSource = selectionsDataSource
        timezoneTableView.delegate = selectionsDataSource

        searchResultsDataSource = SearchDataSource(with: searchField)
        availableTimezoneTableView.dataSource = searchResultsDataSource
        availableTimezoneTableView.delegate = searchResultsDataSource
    }

    deinit {
        // We still need to remove observers set using NotificationCenter block: APIs
        if let themeDidChangeNotif = themeDidChangeNotification {
            NotificationCenter.default.removeObserver(themeDidChangeNotif)
        }
    }

    private func darkModeChanges() {
        if #available(macOS 10.14, *) {
            addTimezoneButton.image = NSImage(named: .addDynamicIcon)
            deleteButton.image = NSImage(named: NSImage.Name("Remove Dynamic"))!
        }
    }

    private func setupLocalizedText() {
        startAtLoginLabel.stringValue = NSLocalizedString("Start at Login",
                                                          comment: "Start at Login")
        timezoneSortButton.title = NSLocalizedString("Sort by Time Difference",
                                                     comment: "Start at Login")
        timezoneNameSortButton.title = NSLocalizedString("Sort by Name",
                                                         comment: "Start at Login")
        labelSortButton.title = NSLocalizedString("Sort by Label",
                                                  comment: "Start at Login")
        addButton.title = NSLocalizedString("Add Button Title",
                                            comment: "Button to add a location")
        closeButton.title = NSLocalizedString("Close Button Title",
                                              comment: "Button to close the panel")
    }

    @objc func refreshTimezoneTableView(_ shouldSelectNewlyInsertedTimezone: Bool = false) {
        OperationQueue.main.addOperation {
            self.build(shouldSelectNewlyInsertedTimezone)
        }
    }

    private func refreshMainTable() {
        OperationQueue.main.addOperation {
            self.refresh()
        }
    }

    private func refresh() {
        if DataStore.shared().shouldDisplay(ViewType.showAppInForeground) {
            updateFloatingWindow()
        } else {
            guard let panel = PanelController.panel() else { return }
            panel.updateDefaultPreferences()
            panel.updateTableContent()
        }
    }

    private func updateFloatingWindow() {
        let current = FloatingWindowController.shared()
        current.updateDefaultPreferences()
        current.updateTableContent()
    }

    private func build(_ shouldSelectLastRow: Bool = false) {
        if DataStore.shared().timezones() == [] {
            housekeeping()
            return
        }

        if selectedTimeZones.isEmpty == false {
            additionalSortOptions.isHidden = false
            if tableview.subviews.count > 1, let zeroView = notimezoneView, tableview.subviews.contains(zeroView) {
                zeroView.removeFromSuperview()
                timezoneTableView.enclosingScrollView?.isHidden = false
            }
            timezoneTableView.reloadData()
            if shouldSelectLastRow {
                selectNewlyInsertedTimezone()
            }
        } else {
            housekeeping()
        }

        cleanup()
    }

    private func housekeeping() {
        timezoneTableView.enclosingScrollView?.isHidden = true
        showNoTimezoneState()
        cleanup()
    }

    private func cleanup() {
        updateMenubarTitles() // Update the menubar titles, the custom labels might have changed.
    }

    private func updateMenubarTitles() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setupMenubarTimer()
        }
    }

    private func setup() {
        setupAccessibilityIdentifiers()

        deleteButton.isEnabled = false

        [placeholderLabel].forEach { $0.isHidden = true }

        messageLabel.stringValue = CLEmptyString

        timezoneTableView.registerForDraggedTypes([.dragSession])

        progressIndicator.usesThreadedAnimation = true

        setupLocalizedText()

        setupColor()

        startupCheckbox.integerValue = DataStore.shared().retrieve(key: CLStartAtLogin) as? Int ?? 0
    }

    private func setupColor() {
        let themer = Themer.shared()

        startAtLoginLabel.textColor = Themer.shared().mainTextColor()

        [timezoneNameSortButton, labelSortButton, timezoneSortButton].forEach {
            $0?.attributedTitle = NSAttributedString(string: $0?.title ?? CLEmptyString, attributes: [
                NSAttributedString.Key.foregroundColor: Themer.shared().mainTextColor(),
                NSAttributedString.Key.font: NSFont(name: "Avenir-Light", size: 13)!,
            ])
        }

        timezoneTableView.backgroundColor = Themer.shared().mainBackgroundColor()
        availableTimezoneTableView.backgroundColor = Themer.shared().textBackgroundColor()
        timezonePanel.backgroundColor = Themer.shared().textBackgroundColor()
        timezonePanel.contentView?.wantsLayer = true
        timezonePanel.contentView?.layer?.backgroundColor = Themer.shared().textBackgroundColor().cgColor
        addTimezoneButton.image = themer.addImage()
        deleteButton.image = themer.removeImage()
    }

    private func setupShortcutObserver() {
        let defaults = NSUserDefaultsController.shared
        recorderControl.setAccessibility("ShortcutControl")
        recorderControl.bind(NSBindingName.value,
                             to: defaults,
                             withKeyPath: PreferencesConstants.hotKeyPathIdentifier,
                             options: nil)

        recorderControl.delegate = self
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change _: [NSKeyValueChangeKey: Any]?, context _: UnsafeMutableRawPointer?) {
        if let path = keyPath, path == PreferencesConstants.hotKeyPathIdentifier {
            let hotKeyCenter = PTHotKeyCenter.shared()
            let oldHotKey = hotKeyCenter?.hotKey(withIdentifier: path)
            hotKeyCenter?.unregisterHotKey(oldHotKey)

            guard let newObject = object as? NSObject, let newShortcut = newObject.value(forKeyPath: path) as? [AnyHashable: Any] else {
                assertionFailure("Unable to recognize shortcuts")
                return
            }

            let newHotKey = PTHotKey(identifier: keyPath,
                                     keyCombo: newShortcut,
                                     target: self,
                                     action: #selector(ping(_:)))

            hotKeyCenter?.register(newHotKey)
        }
    }

    @objc func ping(_ sender: Any) {
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }
        delegate.togglePanel(sender)
    }

    private func showNoTimezoneState() {
        if let zeroView = notimezoneView {
            notimezoneView?.wantsLayer = true
            tableview.addSubview(zeroView)
            Logger.log(object: ["Showing Empty View": "YES"], for: "Showing Empty View")
        }
        additionalSortOptions.isHidden = true
    }

    private func setupAccessibilityIdentifiers() {
        timezoneTableView.setAccessibilityIdentifier("TimezoneTableView")
        availableTimezoneTableView.setAccessibilityIdentifier("AvailableTimezoneTableView")
        searchField.setAccessibilityIdentifier("AvailableSearchField")
        timezoneSortButton.setAccessibility("SortByDifference")
        labelSortButton.setAccessibility("SortByLabelButton")
        timezoneNameSortButton.setAccessibility("SortByTimezoneName")
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}

extension PreferencesViewController: NSTableViewDataSource, NSTableViewDelegate {
    private func _markAsFavorite(_ dataObject: TimezoneData) {
        if dataObject.customLabel != nil {
            Logger.log(object: ["label": dataObject.customLabel ?? "Error"], for: "favouriteSelected")
        }

        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setupMenubarTimer()
        }

        if let menubarTimezones = DataStore.shared().menubarTimezones(), menubarTimezones.count > 1 {
            showAlertIfMoreThanOneTimezoneHasBeenAddedToTheMenubar()
        }
    }

    private func _unfavourite(_ dataObject: TimezoneData) {
        Logger.log(object: ["label": dataObject.customLabel ?? "Error"],
                   for: "favouriteRemoved")

        if let appDelegate = NSApplication.shared.delegate as? AppDelegate,
            let menubarFavourites = DataStore.shared().menubarTimezones(),
            menubarFavourites.isEmpty,
            DataStore.shared().shouldDisplay(.showMeetingInMenubar) == false {
            appDelegate.invalidateMenubarTimer(true)
        }

        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setupMenubarTimer()
        }
    }

    private func showAlertIfMoreThanOneTimezoneHasBeenAddedToTheMenubar() {
        let isUITestRunning = ProcessInfo.processInfo.arguments.contains(CLUITestingLaunchArgument)

        // If we have seen displayed the message before, abort!
        let haveWeSeenThisMessageBefore = UserDefaults.standard.bool(forKey: CLLongStatusBarWarningMessage)

        if haveWeSeenThisMessageBefore, !isUITestRunning {
            return
        }

        // If the user is already using the compact mode, abort.
        if DataStore.shared().shouldDisplay(.menubarCompactMode), !isUITestRunning {
            return
        }

        // Time to display the alert.
        NSApplication.shared.activate(ignoringOtherApps: true)

        let infoText = """
        Multiple timezones occupy space and if macOS determines Clocker is occupying too much space, it'll hide Clocker entirely!
        Enable Menubar Compact Mode to fit in more timezones in less space.
        """

        let alert = NSAlert()
        alert.showsSuppressionButton = true
        alert.messageText = "More than one location added to the menubar 😅"
        alert.informativeText = infoText
        alert.addButton(withTitle: "Enable Compact Mode")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response.rawValue == 1000 {
            OperationQueue.main.addOperation {
                UserDefaults.standard.set(0, forKey: CLMenubarCompactMode)

                if alert.suppressionButton?.state == NSControl.StateValue.on {
                    UserDefaults.standard.set(true, forKey: CLLongStatusBarWarningMessage)
                }

                self.updateStatusBarAppearance()

                Logger.log(object: ["Context": ">1 Menubar Timezone in Preferences"], for: "Switched to Compact Mode")
            }
        }
    }
}

extension PreferencesViewController {
    @objc private func search() {
        let searchString = searchField.stringValue

        if searchString.isEmpty {
            dataTask?.cancel()
            resetSearchView()
            return
        }

        if dataTask?.state == .running {
            dataTask?.cancel()
        }

        OperationQueue.main.addOperation {
            if self.availableTimezoneTableView.isHidden {
                self.availableTimezoneTableView.isHidden = false
            }

            self.placeholderLabel.isHidden = false
            self.isActivityInProgress = true
            self.placeholderLabel.placeholderString = "Searching for \(searchString)"

            Logger.info(self.placeholderLabel.placeholderString ?? "")

            self.dataTask = NetworkManager.task(with: self.generateSearchURL(),
                                                completionHandler: { [weak self] response, error in

                                                    guard let self = self else { return }

                                                    OperationQueue.main.addOperation {
                                                        if let errorPresent = error {
                                                            self.findLocalSearchResultsForTimezones()
                                                            if self.searchResultsDataSource.timezoneFilteredArray.isEmpty {
                                                                self.presentError(errorPresent.localizedDescription)
                                                                return
                                                            }
                                                            self.prepareUIForPresentingResults()
                                                            return
                                                        }

                                                        guard let data = response else {
                                                            assertionFailure("Data was unexpectedly nil")
                                                            return
                                                        }

                                                        let searchResults = data.decode()

                                                        if searchResults?.status == "ZERO_RESULTS" {
                                                            self.findLocalSearchResultsForTimezones()
                                                            self.placeholderLabel.placeholderString = self.searchResultsDataSource.timezoneFilteredArray.isEmpty ? "No results! 😔 Try entering the exact name." : CLEmptyString
                                                            self.reloadSearchResults()
                                                            self.isActivityInProgress = false
                                                            return
                                                        }

                                                        self.appendResultsToFilteredArray(searchResults!.results)
                                                        self.findLocalSearchResultsForTimezones()
                                                        self.prepareUIForPresentingResults()
                                                    }

            })
        }
    }

    private func findLocalSearchResultsForTimezones() {
        let lowercasedSearchString = searchField.stringValue.lowercased()
        searchResultsDataSource.searchTimezones(lowercasedSearchString)
    }

    private func generateSearchURL() -> String {
        let userPreferredLanguage = Locale.preferredLanguages.first ?? "en-US"

        var searchString = searchField.stringValue
        let words = searchString.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        searchString = words.joined(separator: CLEmptyString)

        let url = "https://maps.googleapis.com/maps/api/geocode/json?address=\(searchString)&key=\(geocodingKey)&language=\(userPreferredLanguage)"
        return url
    }

    private func presentError(_ errorMessage: String) {
        if errorMessage == PreferencesConstants.offlineErrorMessage {
            placeholderLabel.placeholderString = PreferencesConstants.noInternetConnectivityError
        } else {
            placeholderLabel.placeholderString = PreferencesConstants.tryAgainMessage
        }

        isActivityInProgress = false
    }

    private func appendResultsToFilteredArray(_ results: [SearchResult.Result]) {
        var finalResults: [TimezoneData] = []
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

            finalResults.append(TimezoneData(with: totalPackage))
        }
        searchResultsDataSource.setFilteredArrayValue(finalResults)
    }

    private func prepareUIForPresentingResults() {
        placeholderLabel.placeholderString = CLEmptyString
        isActivityInProgress = false
        reloadSearchResults()
    }

    private func reloadSearchResults() {
        if searchResultsDataSource.calculateChangesets() {
            Logger.info("Reloading Search Results")
            availableTimezoneTableView.reloadData()
        }
    }

    private func resetSearchView() {
        if dataTask?.state == .running {
            dataTask?.cancel()
        }

        isActivityInProgress = false
        placeholderLabel.placeholderString = CLEmptyString
    }

    private func getTimezone(for latitude: Double, and longitude: Double) {
        if placeholderLabel.isHidden {
            placeholderLabel.isHidden = false
        }

        searchField.placeholderString = "Fetching data might take some time!"
        placeholderLabel.placeholderString = "Retrieving timezone data"
        availableTimezoneTableView.isHidden = true

        let tuple = "\(latitude),\(longitude)"
        let timeStamp = Date().timeIntervalSince1970
        let urlString = "https://maps.googleapis.com/maps/api/timezone/json?location=\(tuple)&timestamp=\(timeStamp)&key=\(geocodingKey)"

        NetworkManager.task(with: urlString) { [weak self] response, error in

            guard let strongSelf = self else { return }

            OperationQueue.main.addOperation {
                if strongSelf.handleEdgeCase(for: response) == true {
                    strongSelf.reloadSearchResults()
                    return
                }

                if error == nil, let json = response, let timezone = json.decodeTimezone() {
                    if strongSelf.availableTimezoneTableView.selectedRow >= 0 {
                        strongSelf.installTimezone(timezone)
                    }
                    strongSelf.updateViewState()
                } else {
                    OperationQueue.main.addOperation {
                        if error?.localizedDescription == "The Internet connection appears to be offline." {
                            strongSelf.placeholderLabel.placeholderString = PreferencesConstants.noInternetConnectivityError
                        } else {
                            strongSelf.placeholderLabel.placeholderString = PreferencesConstants.tryAgainMessage
                        }

                        strongSelf.isActivityInProgress = false
                    }
                }
            }
        }
    }

    private func installTimezone(_ timezone: Timezone) {
        guard let dataObject = searchResultsDataSource.retrieveFilteredResultFromGoogleAPI(availableTimezoneTableView.selectedRow) else {
            assertionFailure("Data was unexpectedly nil")
            return
        }

        var filteredAddress = "Error"

        if let address = dataObject.formattedAddress {
            filteredAddress = address.filteredName()
        }

        let newTimeZone = [
            CLTimezoneID: timezone.timeZoneId,
            CLTimezoneName: filteredAddress,
            CLPlaceIdentifier: dataObject.placeID!,
            "latitude": dataObject.latitude!,
            "longitude": dataObject.longitude!,
            "nextUpdate": CLEmptyString,
            CLCustomLabel: filteredAddress,
        ] as [String: Any]

        // Mark if the timezone is same as local timezone
        let timezoneObject = TimezoneData(with: newTimeZone)

        let operationsObject = TimezoneDataOperations(with: timezoneObject)
        operationsObject.saveObject()

        Logger.log(object: ["PlaceName": filteredAddress, "Timezone": timezone.timeZoneId], for: "Filtered Address")
    }

    private func resetStateAndShowDisconnectedMessage() {
        OperationQueue.main.addOperation {
            self.showMessage()
        }
    }

    private func showMessage() {
        placeholderLabel.placeholderString = PreferencesConstants.noInternetConnectivityError
        isActivityInProgress = false
        searchResultsDataSource.cleanupFilterArray()
        reloadSearchResults()
    }

    /// Returns true if there's an error.
    private func handleEdgeCase(for response: Data?) -> Bool {
        guard let json = response, let jsonUnserialized = try? JSONSerialization.jsonObject(with: json, options: .allowFragments), let unwrapped = jsonUnserialized as? [String: Any] else {
            setErrorPlaceholders()
            return false
        }

        if let status = unwrapped["status"] as? String, status == "ZERO_RESULTS" {
            setErrorPlaceholders()
            return true
        }
        return false
    }

    private func setErrorPlaceholders() {
        placeholderLabel.placeholderString = "No timezone found! Try entering an exact name."
        searchField.placeholderString = NSLocalizedString("Search Field Placeholder",
                                                          comment: "Search Field Placeholder")
        isActivityInProgress = false
    }

    private func updateViewState() {
        searchResultsDataSource.cleanupFilterArray()
        reloadSearchResults()
        refreshTimezoneTableView(true)
        refreshMainTable()
        timezonePanel.close()
        placeholderLabel.placeholderString = CLEmptyString
        searchField.placeholderString = NSLocalizedString("Search Field Placeholder",
                                                          comment: "Search Field Placeholder")
        availableTimezoneTableView.isHidden = false
        isActivityInProgress = false
    }

    @IBAction func addTimeZone(_: NSButton) {
        searchResultsDataSource.cleanupFilterArray()
        view.window?.beginSheet(timezonePanel,
                                completionHandler: nil)
    }

    @IBAction func addToFavorites(_: NSButton) {
        isActivityInProgress = true

        if availableTimezoneTableView.selectedRow == -1 {
            timezonePanel.contentView?.makeToast(PreferencesConstants.noTimezoneSelectedErrorMessage)
            isActivityInProgress = false
            return
        }

        if selectedTimeZones.count >= 100 {
            timezonePanel.contentView?.makeToast(PreferencesConstants.maxTimezonesErrorMessage)
            isActivityInProgress = false
            return
        }

        if searchField.stringValue.isEmpty {
            addTimezoneIfSearchStringIsEmpty()
        } else {
            addTimezoneIfSearchStringIsNotEmpty()
        }
    }

    private func addTimezoneIfSearchStringIsEmpty() {
        let currentRowType = searchResultsDataSource.placeForRow(availableTimezoneTableView.selectedRow)

        switch currentRowType {
        case .timezone:
            cleanupAfterInstallingTimezone()
        default:
            return
        }
    }

    private func addTimezoneIfSearchStringIsNotEmpty() {
        let currentRowType = searchResultsDataSource.placeForRow(availableTimezoneTableView.selectedRow)

        switch currentRowType {
        case .timezone:
            cleanupAfterInstallingTimezone()
            return
        case .city:
            cleanupAfterInstallingCity()
        }
    }

    private func cleanupAfterInstallingCity() {
        guard let dataObject = searchResultsDataSource.retrieveFilteredResultFromGoogleAPI(availableTimezoneTableView.selectedRow) else {
            assertionFailure("Data was unexpectedly nil")
            return
        }

        if messageLabel.stringValue.isEmpty {
            searchField.stringValue = CLEmptyString

            guard let latitude = dataObject.latitude, let longitude = dataObject.longitude else {
                assertionFailure("Data was unexpectedly nil")
                return
            }

            getTimezone(for: latitude, and: longitude)
        }
    }

    private func cleanupAfterInstallingTimezone() {
        let data = TimezoneData()
        data.setLabel(CLEmptyString)

        let currentSelection = searchResultsDataSource.retrieveSelectedTimezone(availableTimezoneTableView.selectedRow)

        let metaInfo = metadata(for: currentSelection)
        data.timezoneID = metaInfo.0.name
        data.formattedAddress = metaInfo.1.formattedName
        data.selectionType = .timezone
        data.isSystemTimezone = metaInfo.0.name == NSTimeZone.system.identifier

        let operationObject = TimezoneDataOperations(with: data)
        operationObject.saveObject()

        searchResultsDataSource.cleanupFilterArray()
        searchResultsDataSource.timezoneFilteredArray = []
        placeholderLabel.placeholderString = CLEmptyString
        searchField.stringValue = CLEmptyString

        reloadSearchResults()
        refreshTimezoneTableView(true)
        refreshMainTable()

        timezonePanel.close()
        searchField.placeholderString = NSLocalizedString("Search Field Placeholder",
                                                          comment: "Search Field Placeholder")
        availableTimezoneTableView.isHidden = false
        isActivityInProgress = false
    }

    private func selectNewlyInsertedTimezone() {
        // Let's highlight the newly added row. If the number of timezones is greater than 6, the newly added timezone isn't visible. Since we hide the scrollbars as well, the user might get the impression that something is broken!
        if timezoneTableView.numberOfRows > 6 {
            timezoneTableView.scrollRowToVisible(timezoneTableView.numberOfRows - 1)
        }

        let indexSet = IndexSet(integer: IndexSet.Element(timezoneTableView.numberOfRows - 1))
        timezoneTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
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

    @IBAction func closePanel(_: NSButton) {
        searchResultsDataSource.cleanupFilterArray()
        searchResultsDataSource.timezoneFilteredArray = []
        searchField.stringValue = CLEmptyString
        placeholderLabel.placeholderString = CLEmptyString
        searchField.placeholderString = NSLocalizedString("Search Field Placeholder",
                                                          comment: "Search Field Placeholder")

        reloadSearchResults()

        timezonePanel.close()
        isActivityInProgress = false
        addTimezoneButton.state = .off

        // The table might be hidden because of an early exit especially
        // if we are not able to fetch an associated timezone
        // For eg. Europe doesn't have an associated timezone
        availableTimezoneTableView.isHidden = false
    }

    @IBAction func removeFromFavourites(_: NSButton) {
        // If the user is editing a row, and decides to delete the row then we have a crash
        if timezoneTableView.editedRow != -1 || timezoneTableView.editedColumn != -1 {
            return
        }

        if timezoneTableView.selectedRow == -1, selectedTimeZones.count <= timezoneTableView.selectedRow {
            assertionFailure("Data was unexpectedly nil")
            return
        }

        var newDefaults = selectedTimeZones

        let objectsToRemove = timezoneTableView.selectedRowIndexes.map { index -> Data in
            selectedTimeZones[index]
        }

        newDefaults = newDefaults.filter { !objectsToRemove.contains($0) }

        DataStore.shared().setTimezones(newDefaults)

        timezoneTableView.reloadData()

        refreshTimezoneTableView()

        refreshMainTable()

        updateStatusBarAppearance()

        updateStatusItem()
    }

    // TODO: This probably does not need to be used
    private func updateStatusItem() {
        guard let statusItem = (NSApplication.shared.delegate as? AppDelegate)?.statusItemForPanel() else {
            return
        }

        statusItem.refresh()
    }

    private func updateStatusBarAppearance() {
        guard let statusItem = (NSApplication.shared.delegate as? AppDelegate)?.statusItemForPanel() else {
            return
        }

        statusItem.setupStatusItem()
    }

    @IBAction func filterArray(_: Any?) {
        searchResultsDataSource.cleanupFilterArray()

        if searchField.stringValue.count > 50 {
            isActivityInProgress = false
            reloadSearchResults()
            timezonePanel.contentView?.makeToast(PreferencesConstants.maxCharactersAllowed)
            return
        }

        if searchField.stringValue.isEmpty == false {
            dataTask?.cancel()
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            perform(#selector(search), with: nil, afterDelay: 0.5)
        } else {
            resetSearchView()
        }

        reloadSearchResults()
    }
}

extension PreferencesViewController {
    @IBAction func loginPreferenceChanged(_ sender: NSButton) {
        startupManager.toggleLogin(sender.state == .on)
    }
}

// Sorting
extension PreferencesViewController {
    @IBAction func sortOptions(_: NSButton) {
        additionalSortOptions.isHidden.toggle()
    }

    @IBAction func sortByTime(_ sender: NSButton) {
        let sortedByTime = selectedTimeZones.sorted { obj1, obj2 -> Bool in

            let system = NSTimeZone.system

            guard let object1 = TimezoneData.customObject(from: obj1),
                let object2 = TimezoneData.customObject(from: obj2)
            else {
                assertionFailure("Data was unexpectedly nil")
                return false
            }

            let timezone1 = NSTimeZone(name: object1.timezone())
            let timezone2 = NSTimeZone(name: object2.timezone())

            let difference1 = system.secondsFromGMT() - timezone1!.secondsFromGMT
            let difference2 = system.secondsFromGMT() - timezone2!.secondsFromGMT

            return arePlacesSortedInAscendingTimezoneOrder ? difference1 > difference2 : difference1 < difference2
        }

        sender.image = arePlacesSortedInAscendingTimezoneOrder ? NSImage(named: NSImage.Name("NSDescendingSortIndicator"))! : NSImage(named: NSImage.Name("NSAscendingSortIndicator"))!

        arePlacesSortedInAscendingTimezoneOrder.toggle()

        DataStore.shared().setTimezones(sortedByTime)

        updateAfterSorting()
    }

    @IBAction func sortByLabel(_ sender: NSButton) {
        let sortedLabels = selectedTimeZones.sorted { obj1, obj2 -> Bool in

            guard let object1 = TimezoneData.customObject(from: obj1),
                let object2 = TimezoneData.customObject(from: obj2)
            else {
                assertionFailure("Data was unexpectedly nil")
                return false
            }

            return isLabelOptionSelected ? object1.customLabel! > object2.customLabel! : object1.customLabel! < object2.customLabel!
        }

        sender.image = isLabelOptionSelected ?
            NSImage(named: NSImage.Name("NSDescendingSortIndicator"))! :
            NSImage(named: NSImage.Name("NSAscendingSortIndicator"))!

        isLabelOptionSelected.toggle()

        DataStore.shared().setTimezones(sortedLabels)

        updateAfterSorting()
    }

    @IBAction func sortByFormattedAddress(_ sender: NSButton) {
        let sortedByAddress = selectedTimeZones.sorted { obj1, obj2 -> Bool in

            guard let object1 = TimezoneData.customObject(from: obj1),
                let object2 = TimezoneData.customObject(from: obj2)
            else {
                assertionFailure("Data was unexpectedly nil")
                return false
            }

            return isTimezoneNameSortOptionSelected ? object1.formattedAddress! > object2.formattedAddress! : object1.formattedAddress! < object2.formattedAddress!
        }

        sender.image = isTimezoneNameSortOptionSelected ? NSImage(named: NSImage.Name("NSDescendingSortIndicator"))! : NSImage(named: NSImage.Name("NSAscendingSortIndicator"))!

        isTimezoneNameSortOptionSelected.toggle()

        DataStore.shared().setTimezones(sortedByAddress)

        updateAfterSorting()
    }

    private func updateAfterSorting() {
        let newDefaults = selectedTimeZones
        DataStore.shared().setTimezones(newDefaults)
        refreshTimezoneTableView()
        refreshMainTable()
    }
}

extension PreferencesViewController: SRRecorderControlDelegate {}

// Helpers
extension PreferencesViewController {
    private func insert(timezone: TimezoneData, at index: Int) {
        let encodedObject = NSKeyedArchiver.archivedData(withRootObject: timezone)
        var newDefaults = selectedTimeZones
        newDefaults[index] = encodedObject
        DataStore.shared().setTimezones(newDefaults)
    }
}

extension PreferencesViewController: PreferenceSelectionUpdates {
    func markAsFavorite(_ dataObject: TimezoneData) {
        _markAsFavorite(dataObject)
    }

    func unfavourite(_ dataObject: TimezoneData) {
        _unfavourite(dataObject)
    }

    func refreshTimezoneTable() {
        refreshTimezoneTableView()
    }

    func refreshMainTableView() {
        refreshMainTable()
    }

    func tableViewSelectionDidChange(_ status: Bool) {
        deleteButton.isEnabled = !status
    }

    func table(didClick tableColumn: NSTableColumn) {
        if tableColumn.identifier.rawValue == "favouriteTimezone" {
            return
        }

        let sortedTimezones = selectedTimeZones.sorted { obj1, obj2 -> Bool in

            guard let object1 = TimezoneData.customObject(from: obj1),
                let object2 = TimezoneData.customObject(from: obj2)
            else {
                assertionFailure("Data was unexpectedly nil")
                return false
            }

            if tableColumn.identifier.rawValue == "formattedAddress" {
                return arePlacesSortedInAscendingOrder ?
                    object1.formattedAddress! > object2.formattedAddress! :
                    object1.formattedAddress! < object2.formattedAddress!
            } else {
                return arePlacesSortedInAscendingOrder ?
                    object1.customLabel! > object2.customLabel! :
                    object1.customLabel! < object2.customLabel!
            }
        }

        let indicatorImage = arePlacesSortedInAscendingOrder ?
            NSImage(named: NSImage.Name("NSDescendingSortIndicator"))! :
            NSImage(named: NSImage.Name("NSAscendingSortIndicator"))!

        timezoneTableView.setIndicatorImage(indicatorImage, in: tableColumn)

        arePlacesSortedInAscendingOrder.toggle()

        DataStore.shared().setTimezones(sortedTimezones)

        updateAfterSorting()
    }
}

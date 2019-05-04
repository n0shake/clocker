// Copyright © 2015 Abhishek Banthia

import Cocoa
import ServiceManagement

struct PreferencesConstants {
    static let timezoneNameIdentifier = "formattedAddress"
    static let customLabelIdentifier = "label"
    static let availableTimezoneIdentifier = "availableTimezones"
    static let noTimezoneSelectedErrorMessage = "Please select a timezone!"
    static let maxTimezonesErrorMessage = "Maximum 100 timezones allowed!"
    static let maxCharactersAllowed = "Only 50 characters allowed!"
    static let noInternetConnectivityError = "You're offline, maybe?"
    static let tryAgainMessage = "Try again, maybe?"
    static let offlineErrorMessage = "The Internet connection appears to be offline."
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
        get {
            return DataStore.shared().timezones()
        } set {
        }
    }

    private var filteredArray: [Any] = []
    private var timezoneArray: [String] = []
    private var timezoneFilteredArray: [String] = []
    private var columnName = "Place(s)"
    private var dataTask: URLSessionDataTask? = .none

    private lazy var notimezoneView: NoTimezoneView? = {
        NoTimezoneView(frame: tableview.frame)
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
    @IBOutlet private var stackView: NSStackView!
    @IBOutlet private var progressIndicator: NSProgressIndicator!
    @IBOutlet private var addButton: NSButton!
    @IBOutlet private var recorderControl: SRRecorderControl!

    @IBOutlet private var timezoneSortButton: NSButton!
    @IBOutlet private var timezoneNameSortButton: NSButton!
    @IBOutlet private var labelSortButton: NSButton!
    @IBOutlet private var deleteButton: NSButton!
    @IBOutlet private var addTimezoneButton: NSButton!

    @IBOutlet private var searchField: NSSearchField!
    @IBOutlet private var messageLabel: NSTextField!
    @IBOutlet private var searchCriteria: NSSegmentedControl!
    @IBOutlet private var abbreviation: NSTableColumn!

    @IBOutlet private var headerView: NSView!
    @IBOutlet private var tableview: NSView!
    @IBOutlet private var additionalSortOptions: NSView!
    @IBOutlet weak var startAtLoginLabel: NSTextField!

    @IBOutlet var startupCheckbox: NSButton!
    @IBOutlet var headerLabel: NSTextField!

    @IBOutlet var sortToggle: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshTimezoneTableView),
                                               name: NSNotification.Name.customLabelChanged,
                                               object: nil)

        refreshTimezoneTableView()

        setup()

        availableTimezoneTableView.reloadData()

        setupShortcutObserver()

        darkModeChanges()

        NotificationCenter.default.addObserver(forName: .themeDidChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            self.setup()
        }
    }

    private func darkModeChanges() {
        if #available(macOS 10.14, *) {
            addTimezoneButton.image = NSImage(named: .addDynamicIcon)
            sortToggle.image = NSImage(named: .sortToggleIcon)
            sortToggle.alternateImage = NSImage(named: .sortToggleAlternateIcon)
            deleteButton.image = NSImage(named: NSImage.Name("Remove Dynamic"))!
        }
    }

    private func setupLocalizedText() {
        startAtLoginLabel.stringValue = "Start Clocker at Login"
        headerLabel.stringValue = "Selected Timezones"
        timezoneSortButton.title = "Sort by Time Difference"
        timezoneNameSortButton.title = "Sort by Name"
        labelSortButton.title = "Sort by Label"
    }

    @objc func refreshTimezoneTableView() {
        OperationQueue.main.addOperation {
            self.build()
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

    private func build() {
        if DataStore.shared().timezones() == [] {
            housekeeping()
            return
        }

        if selectedTimeZones.count > 0 {
            headerView.isHidden = false

            if tableview.subviews.count > 1, let zeroView = notimezoneView, tableview.subviews.contains(zeroView) {
                zeroView.removeFromSuperview()
                timezoneTableView.enclosingScrollView?.isHidden = false
            }
            timezoneTableView.reloadData()
        } else {
            housekeeping()
        }

        cleanup()
    }

    private func housekeeping() {
        timezoneTableView.enclosingScrollView?.isHidden = true
        headerView.isHidden = true
        showNoTimezoneState()
        cleanup()
        return
    }

    private func cleanup() {
        timezoneTableView.scrollRowToVisible(selectedTimeZones.count - 1)
        updateMenubarTitles() // Update the menubar titles, the custom labels might have changed.
    }

    private func updateMenubarTitles() {
        let defaultTimezones = DataStore.shared().timezones()
        UserDefaults.standard.set([], forKey: CLMenubarFavorites)

        let menubarTimes = defaultTimezones.compactMap { (data) -> TimezoneData? in
            if let model = TimezoneData.customObject(from: data), model.isFavourite == 1 {
                return model
            }
            return nil
        }

        let archivedObjects = menubarTimes.map { (timezone) -> Data in
            return NSKeyedArchiver.archivedData(withRootObject: timezone)
        }

        UserDefaults.standard.set(archivedObjects, forKey: CLMenubarFavorites)

        // Update appereance if in compact menubar mode
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setupMenubarTimer()
        }
    }

    private func setup() {
        setupAccessibilityIdentifiers()

        deleteButton.isEnabled = false

        [placeholderLabel, additionalSortOptions].forEach { $0.isHidden = true }

        if timezoneArray.count == 0 {
            timezoneArray.append("UTC")
            timezoneArray.append("Anywhere on Earth")
            timezoneArray.append(contentsOf: NSTimeZone.knownTimeZoneNames)
        }

        messageLabel.stringValue = CLEmptyString

        timezoneTableView.registerForDraggedTypes([.dragSession])

        progressIndicator.usesThreadedAnimation = true

        setupLocalizedText()

        setupColor()

        startupCheckbox.integerValue = DataStore.shared().retrieve(key: CLStartAtLogin) as? Int ?? 0
    }

    private func setupColor() {
        let themer = Themer.shared()

        headerLabel.textColor = themer.mainTextColor()
        startAtLoginLabel.textColor = Themer.shared().mainTextColor()

        [timezoneNameSortButton, labelSortButton, timezoneSortButton].forEach {
            $0?.attributedTitle = NSAttributedString(string: $0?.title ?? CLEmptyString, attributes: [
                NSAttributedString.Key.foregroundColor: Themer.shared().mainTextColor(),
                NSAttributedString.Key.font: NSFont(name: "Avenir-Light", size: 13)!
            ])
        }

        addTimezoneButton.image = themer.addImage()
        deleteButton.image = themer.removeImage()
        sortToggle.image = themer.additionalPreferencesImage()
        sortToggle.alternateImage = themer.additionalPreferencesHighlightedImage()
    }

    private func setupShortcutObserver() {
        let defaults = NSUserDefaultsController.shared

        recorderControl.bind(NSBindingName.value,
                             to: defaults,
                             withKeyPath: "values.globalPing",
                             options: nil)

        recorderControl.delegate = self
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change _: [NSKeyValueChangeKey: Any]?, context _: UnsafeMutableRawPointer?) {
        if let path = keyPath, path == "values.globalPing" {
            let hotKeyCenter = PTHotKeyCenter.shared()
            let oldHotKey = hotKeyCenter?.hotKey(withIdentifier: path)
            hotKeyCenter?.unregisterHotKey(oldHotKey)

            guard let newObject = object as? NSObject, let newShortcut = newObject.value(forKeyPath: path) as? [AnyHashable: Any] else {
                assertionFailure("Unable to recognize shortcuts")
                return
            }

            let newHotKey: PTHotKey = PTHotKey(identifier: keyPath,
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
    func numberOfRows(in tableView: NSTableView) -> Int {
        var numberOfRows = 0

        if tableView == timezoneTableView {
            numberOfRows = selectedTimeZones.count
        } else {
            numberOfRows = numberOfSearchResults()
        }

        return numberOfRows
    }

    func tableView(_: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        var dataSource: TimezoneData?
        var selectedDataSource: TimezoneData?

        if filteredArray.count > row, let currentFilteredObject = filteredArray[row] as? TimezoneData {
            dataSource = currentFilteredObject
        }

        if selectedTimeZones.count > row, let model = TimezoneData.customObject(from: selectedTimeZones[row]) {
            selectedDataSource = model
        }

        if tableColumn?.identifier.rawValue == PreferencesConstants.timezoneNameIdentifier {
            guard let model = selectedDataSource else {
                return nil
            }

            if let address = model.formattedAddress, address.count > 0 {
                return model.formattedAddress
            }

            return model.timezoneID
        }

        if tableColumn?.identifier.rawValue == PreferencesConstants.availableTimezoneIdentifier {
            let criteria = searchCriteria.selectedSegment

            if criteria == 0 {
                if row < filteredArray.count {
                    return dataSource?.formattedAddress
                }
            } else {
                if searchField.stringValue.count > 0 && row < timezoneFilteredArray.count {
                    return timezoneFilteredArray[row]
                }
                return timezoneArray[row]
            }
        }

        if tableColumn?.identifier.rawValue == PreferencesConstants.customLabelIdentifier {
            return selectedDataSource?.customLabel ?? "Error"
        }

        if tableColumn?.identifier.rawValue == "favouriteTimezone" {
            return selectedDataSource?.isFavourite ?? 0
        }

        if tableColumn?.identifier.rawValue == "abbreviation" {
            if searchField.stringValue.count > 0 && (row < timezoneFilteredArray.count) {
                let currentSelection = timezoneFilteredArray[row]
                if currentSelection == "UTC" {
                    return "UTC"
                } else if currentSelection == "Anywhere on Earth" {
                    return "GMT+12"
                }

                return NSTimeZone(name: timezoneFilteredArray[row])?.abbreviation ?? "Error"
            }

            if timezoneArray.count > row {
                // Special return for manually inserted 'UTC'
                if timezoneArray[row] == "UTC" {
                    return "UTC"
                }

                if timezoneArray[row] == "Anywhere on Earth" {
                    return "AoE"
                }

                return NSTimeZone(name: timezoneArray[row])?.abbreviation ?? "Error"
            }
        }

        return nil
    }

    func tableView(_: NSTableView, setObjectValue object: Any?, for _: NSTableColumn?, row: Int) {
        guard !selectedTimeZones.isEmpty, let dataObject = TimezoneData.customObject(from: selectedTimeZones[row]) else {
            return
        }

        if let edit = object as? String {
            let formattedValue = edit.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)

            if selectedTimeZones.count > row {
                Logger.log(object: [
                    "Old Label": dataObject.customLabel ?? "Error",
                    "New Label": formattedValue
                ],
                for: "Custom Label Changed")

                dataObject.setLabel(formattedValue)

                insert(timezone: dataObject, at: row)

                updateMenubarTitles()
            } else {
                Logger.log(object: [
                    "MethodName": "SetObjectValue",
                    "Selected Timezone Count": selectedTimeZones.count,
                    "Current Row": row
                ],
                for: "Error in selected row count")
            }
        } else if let isFavouriteValue = object as? NSNumber {
            dataObject.isFavourite = isFavouriteValue.intValue
            insert(timezone: dataObject, at: row)

            if dataObject.isFavourite == 1, let menubarTitles = DataStore.shared().retrieve(key: CLMenubarFavorites) as? [Data] {

                var mutableArray = menubarTitles
                let archivedObject = NSKeyedArchiver.archivedData(withRootObject: dataObject)
                mutableArray.append(archivedObject)

                UserDefaults.standard.set(mutableArray, forKey: CLMenubarFavorites)

                if dataObject.customLabel != nil {
                    Logger.log(object: ["label": dataObject.customLabel ?? "Error"], for: "favouriteSelected")
                }

                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.setupMenubarTimer()
                }

                if mutableArray.count > 1 {
                    showAlertIfMoreThanOneTimezoneHasBeenAddedToTheMenubar()
                }

            } else {
                guard let menubarTimers = DataStore.shared().retrieve(key: CLMenubarFavorites) as? [Data] else {
                    assertionFailure("Menubar timers is unexpectedly nil")
                    return
                }

                Logger.log(object: ["label": dataObject.customLabel ?? "Error"],
                           for: "favouriteRemoved")

                let filteredMenubars = menubarTimers.filter {
                    guard let current = NSKeyedUnarchiver.unarchiveObject(with: $0) as? TimezoneData else {
                        return false
                    }
                    return current != dataObject
                }

                UserDefaults.standard.set(filteredMenubars, forKey: CLMenubarFavorites)

                if let appDelegate = NSApplication.shared.delegate as? AppDelegate, let menubarFavourites = DataStore.shared().retrieve(key: CLMenubarFavorites) as? [Data], menubarFavourites.count <= 0, DataStore.shared().shouldDisplay(.showMeetingInMenubar) == false {
                    appDelegate.invalidateMenubarTimer(true)
                }

                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.setupMenubarTimer()
                }
            }

            updateStatusItem()

            refreshTimezoneTableView()
        }

        refreshMainTable()
    }

    private func showAlertIfMoreThanOneTimezoneHasBeenAddedToTheMenubar() {

        let isUITestRunning = ProcessInfo.processInfo.arguments.contains(CLUITestingLaunchArgument)

        // If we have seen displayed the message before, abort!
        let haveWeSeenThisMessageBefore = UserDefaults.standard.bool(forKey: CLLongStatusBarWarningMessage)

        if haveWeSeenThisMessageBefore && !isUITestRunning {
            return
        }

        // If the user is already using the compact mode, abort.
        if DataStore.shared().shouldDisplay(.menubarCompactMode) && !isUITestRunning {
            return
        }

        // Time to display the alert.
        NSApplication.shared.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.showsSuppressionButton = true
        alert.messageText = "More than one location added to the menubar 😅"
        alert.informativeText = "Multiple timezones occupy space and if macOS determines Clocker is occupying too much space, it'll hide Clocker entirely! Enable Menubar Compact Mode to fit in more timezones in less space."
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

    func tableView(_: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)

        pboard.declareTypes([.dragSession], owner: self)
        pboard.setData(data, forType: .dragSession)

        return true
    }

    func tableView(_: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation _: NSTableView.DropOperation) -> Bool {
        var newOrder = selectedTimeZones

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

        DataStore.shared().setTimezones(newOrder)

        timezoneTableView.reloadData()

        refreshMainTable()

        timezoneTableView.deselectRow(timezoneTableView.selectedRow)

        return true
    }

    func tableView(_: NSTableView, validateDrop _: NSDraggingInfo, proposedRow _: Int, proposedDropOperation _: NSTableView.DropOperation) -> NSDragOperation {
        return .every
    }

    func tableViewSelectionDidChange(_: Notification) {
        deleteButton.isEnabled = !(timezoneTableView.selectedRow == -1)
    }

    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        if tableColumn.identifier.rawValue == "favouriteTimezone" {
            return
        }

        if tableView == timezoneTableView {
            let sortedTimezones = selectedTimeZones.sorted { (obj1, obj2) -> Bool in

                guard let object1 = TimezoneData.customObject(from: obj1),
                    let object2 = TimezoneData.customObject(from: obj2) else {
                    assertionFailure("Data was unexpectedly nil")
                    return false
                }

                if tableColumn.identifier.rawValue == "formattedAddress" {
                    return arePlacesSortedInAscendingOrder ? object1.formattedAddress! > object2.formattedAddress! : object1.formattedAddress! < object2.formattedAddress!
                } else {
                    return arePlacesSortedInAscendingOrder ? object1.customLabel! > object2.customLabel! : object1.customLabel! < object2.customLabel!
                }
            }

            arePlacesSortedInAscendingOrder ? timezoneTableView.setIndicatorImage(NSImage(named: NSImage.Name("NSDescendingSortIndicator"))!, in: tableColumn) : timezoneTableView.setIndicatorImage(NSImage(named: NSImage.Name("NSAscendingSortIndicator"))!, in: tableColumn)

            arePlacesSortedInAscendingOrder.toggle()

            DataStore.shared().setTimezones(sortedTimezones)

            updateAfterSorting()
        }
    }
}

extension PreferencesViewController {
    @objc private func search() {
        var searchString = searchField.stringValue

        if searchString.count <= 0 {
            dataTask?.cancel()
            resetSearchView()
            return
        }

        if dataTask?.state == .running {
            dataTask?.cancel()
        }

        let userPreferredLanguage = Locale.preferredLanguages.first ?? "en-US"

        OperationQueue.main.addOperation {
            if self.availableTimezoneTableView.isHidden {
                self.availableTimezoneTableView.isHidden = false
            }

            self.placeholderLabel.isHidden = false

            if NetworkManager.isConnected() == false {
                self.placeholderLabel.placeholderString = PreferencesConstants.noInternetConnectivityError
                return
            }

            self.isActivityInProgress = true

            self.placeholderLabel.placeholderString = "Searching for \(searchString)"

            let words = searchString.components(separatedBy: CharacterSet.whitespacesAndNewlines)

            searchString = words.joined(separator: CLEmptyString)

            let urlString = "https://maps.googleapis.com/maps/api/geocode/json?address=\(searchString)&key=\(CLGeocodingKey)&language=\(userPreferredLanguage)"

            self.dataTask = NetworkManager.task(with: urlString,
                                                completionHandler: { [weak self] response, error in

                                                    guard let `self` = self else { return }

                                                    OperationQueue.main.addOperation {
                                                        if let errorPresent = error {
                                                            if errorPresent.localizedDescription == PreferencesConstants.offlineErrorMessage {
                                                                self.placeholderLabel.placeholderString = PreferencesConstants.noInternetConnectivityError
                                                            } else {
                                                                self.placeholderLabel.placeholderString = PreferencesConstants.tryAgainMessage
                                                            }

                                                            self.isActivityInProgress = false
                                                            return
                                                        }

                                                        guard let data = response else {
                                                            assertionFailure("Data was unexpectedly nil")
                                                            return
                                                        }

                                                        let searchResults = self.decode(from: data)

                                                        if searchResults?.status == "ZERO_RESULTS" {
                                                            self.placeholderLabel.placeholderString = "No results! 😔 Try entering the exact name."
                                                            self.isActivityInProgress = false
                                                            return
                                                        }

                                                        for result in searchResults!.results {
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
                                                                CLPlaceIdentifier: result.placeId
                                                            ] as [String: Any]

                                                            self.filteredArray.append(TimezoneData(with: totalPackage))
                                                        }

                                                        self.placeholderLabel.placeholderString = CLEmptyString

                                                        self.isActivityInProgress = false

                                                        self.availableTimezoneTableView.reloadData()
                                                    }

            })
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

        if NetworkManager.isConnected() == false || ProcessInfo.processInfo.arguments.contains("mockTimezoneDown") {
            resetStateAndShowDisconnectedMessage()
            return
        }

        searchField.placeholderString = "Fetching data might take some time!"
        placeholderLabel.placeholderString = "Retrieving timezone data"
        availableTimezoneTableView.isHidden = true

        let tuple = "\(latitude),\(longitude)"
        let timeStamp = Date().timeIntervalSince1970
        let urlString = "https://maps.googleapis.com/maps/api/timezone/json?location=\(tuple)&timestamp=\(timeStamp)&key=\(CLGeocodingKey)"

        NetworkManager.task(with: urlString) { [weak self] response, error in

            guard let `self` = self else { return }

            OperationQueue.main.addOperation {
                if self.handleEdgeCase(for: response) == true {
                    return
                }

                if error == nil, let json = response, let timezone = self.decodeTimezone(from: json) {
                    if self.availableTimezoneTableView.selectedRow >= 0 && self.availableTimezoneTableView.selectedRow < self.filteredArray.count {
                        guard let dataObject = self.filteredArray[self.availableTimezoneTableView.selectedRow] as? TimezoneData else {
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
                            CLCustomLabel: filteredAddress
                        ] as [String: Any]

                        let timezoneObject = TimezoneData(with: newTimeZone)
                        let operationsObject = TimezoneDataOperations(with: timezoneObject)
                        operationsObject.saveObject()

                        Logger.log(object: ["PlaceName": filteredAddress, "Timezone": timezone.timeZoneId], for: "Filtered Address")
                    }

                    self.updateViewState()
                } else {
                    OperationQueue.main.addOperation {
                        if error?.localizedDescription == "The Internet connection appears to be offline." {
                            self.placeholderLabel.placeholderString = PreferencesConstants.noInternetConnectivityError
                        } else {
                            self.placeholderLabel.placeholderString = PreferencesConstants.tryAgainMessage
                        }

                        self.isActivityInProgress = false
                    }
                }
            }
        }
    }

    private func resetStateAndShowDisconnectedMessage() {
        OperationQueue.main.addOperation {
            self.showMessage()
        }
    }

    private func showMessage() {
        placeholderLabel.placeholderString = PreferencesConstants.noInternetConnectivityError
        isActivityInProgress = false
        filteredArray = []
        availableTimezoneTableView.reloadData()
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
        searchField.placeholderString = "Enter a city, state or country name"
        isActivityInProgress = false
    }

    private func updateViewState() {
        filteredArray = []
        availableTimezoneTableView.reloadData()
        refreshTimezoneTableView()
        refreshMainTable()
        timezonePanel.close()
        placeholderLabel.placeholderString = CLEmptyString
        searchField.placeholderString = "Enter a city, state or country name"
        availableTimezoneTableView.isHidden = false
        isActivityInProgress = false
    }

    @IBAction func searchOptions(_: Any) {
        placeholderLabel.placeholderString = CLEmptyString
        placeholderLabel.isHidden = true

        if searchCriteria.selectedSegment == 0 {
            searchField.placeholderString = "Enter a city, state or country name"
            columnName = "Place(s)"
            abbreviation.isHidden = true
        } else {
            searchField.placeholderString = "Enter a timezone name"
            columnName = "Timezone(s)"
            abbreviation.isHidden = false
            timezoneArray = []
            timezoneArray.append("UTC")
            timezoneArray.append("Anywhere on Earth")
            timezoneArray.append(contentsOf: NSTimeZone.knownTimeZoneNames)
        }

        searchField.stringValue = CLEmptyString
        availableTimezoneTableView.reloadData()
    }

    @IBAction func addTimeZone(_: NSButton) {
        abbreviation.isHidden = true
        filteredArray = []
        searchCriteria.selectedSegment = 0
        view.window?.beginSheet(timezonePanel,
                                completionHandler: nil)
    }

    @IBAction func addToFavorites(_: NSButton) {
        isActivityInProgress = true

        if availableTimezoneTableView.selectedRow == -1 {
            messageLabel.stringValue = PreferencesConstants.noTimezoneSelectedErrorMessage

            Timer.scheduledTimer(withTimeInterval: 5,
                                 repeats: false) { _ in
                OperationQueue.main.addOperation {
                    self.messageLabel.stringValue = CLEmptyString
                }
            }

            isActivityInProgress = false
            return
        }

        if selectedTimeZones.count >= 100 {
            messageLabel.stringValue = PreferencesConstants.maxTimezonesErrorMessage
            Timer.scheduledTimer(withTimeInterval: 5,
                                 repeats: false) { _ in
                OperationQueue.main.addOperation {
                    self.messageLabel.stringValue = CLEmptyString
                }
            }

            isActivityInProgress = false
            return
        }

        if searchCriteria.selectedSegment == 0 {
            guard let dataObject = filteredArray[availableTimezoneTableView.selectedRow] as? TimezoneData else {
                assertionFailure("Data was unexpectedly nil")
                return
            }

            if messageLabel.stringValue.count == 0 {
                searchField.stringValue = CLEmptyString

                guard let latitude = dataObject.latitude, let longitude = dataObject.longitude else {
                    assertionFailure("Data was unexpectedly nil")
                    return
                }

                getTimezone(for: latitude, and: longitude)
            }

        } else {
            let data = TimezoneData()
            data.setLabel(CLEmptyString)

            if searchField.stringValue.count > 0 {
                if timezoneFilteredArray.count <= availableTimezoneTableView.selectedRow {
                    return
                }

                let currentSelection = timezoneFilteredArray[availableTimezoneTableView.selectedRow]

                let metaInfo = metadata(for: currentSelection)
                data.timezoneID = metaInfo.0
                data.formattedAddress = metaInfo.1

            } else {
                let currentSelection = timezoneArray[availableTimezoneTableView.selectedRow]

                let metaInfo = metadata(for: currentSelection)
                data.timezoneID = metaInfo.0
                data.formattedAddress = metaInfo.1
            }

            data.selectionType = .timezone

            let operationObject = TimezoneDataOperations(with: data)
            operationObject.saveObject()

            timezoneFilteredArray = []

            timezoneArray = []

            availableTimezoneTableView.reloadData()

            refreshTimezoneTableView()

            refreshMainTable()

            timezonePanel.close()

            placeholderLabel.placeholderString = CLEmptyString

            searchField.stringValue = CLEmptyString

            searchField.placeholderString = "Enter a city, state or country name"

            availableTimezoneTableView.isHidden = false

            isActivityInProgress = false
        }
    }

    private func metadata(for selection: String) -> (String, String) {
        if selection == "Anywhere on Earth" {
            return ("GMT-1200", selection)
        } else if selection == "UTC" {
            return ("GMT", selection)
        } else {
            return (selection, selection)
        }
    }

    @IBAction func closePanel(_: NSButton) {
        filteredArray = []

        timezoneArray = []

        searchCriteria.setSelected(true, forSegment: 0)

        columnName = "Place(s)"

        availableTimezoneTableView.reloadData()

        searchField.stringValue = CLEmptyString

        placeholderLabel.placeholderString = CLEmptyString

        searchField.placeholderString = "Enter a city, state or country name"

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

        let currentObject = selectedTimeZones[timezoneTableView.selectedRow]
        guard let model = TimezoneData.customObject(from: currentObject) else {
            assertionFailure("Data was unexpectedly nil")
            return
        }

        if model.isFavourite == 1 {
            removeFromMenubarFavourites(object: model)
        }

        var newDefaults = selectedTimeZones

        let objectsToRemove = timezoneTableView.selectedRowIndexes.map { (index) -> Data in
            return selectedTimeZones[index]
        }

        newDefaults = newDefaults.filter { !objectsToRemove.contains($0) }

        DataStore.shared().setTimezones(newDefaults)

        timezoneTableView.reloadData()

        refreshTimezoneTableView()

        refreshMainTable()

        if selectedTimeZones.count == 0 {
            UserDefaults.standard.set(nil, forKey: CLMenubarFavorites)
        }

        updateStatusBarAppearance()

        updateStatusItem()
    }

    // TODO: This probably does not need to be used
    private func updateStatusItem() {
        guard let statusItem = (NSApplication.shared.delegate as? AppDelegate)?.statusItemForPanel() else {
            return
        }

        statusItem.performTimerWork()
    }

    private func updateStatusBarAppearance() {
        guard let statusItem = (NSApplication.shared.delegate as? AppDelegate)?.statusItemForPanel() else {
            return
        }

        statusItem.setupStatusItem()
    }

    private func removeFromMenubarFavourites(object: TimezoneData?) {
        guard let model = object else {
            assertionFailure("Data was unexpectedly nil")
            return
        }

        if model.isFavourite == 1 {
            if let menubarTitles = DataStore.shared().retrieve(key: CLMenubarFavorites) as? [Data] {
                let updated = menubarTitles.filter { (data) -> Bool in
                    let current = TimezoneData.customObject(from: data)
                    return current != model
                }

                UserDefaults.standard.set(updated, forKey: CLMenubarFavorites)
            }
        }
    }

    @IBAction func filterTimezoneArray(_: Any?) {
        let lowercasedSearchString = searchField.stringValue.lowercased()
        timezoneFilteredArray = timezoneArray.filter { $0.lowercased().contains(lowercasedSearchString) }
        availableTimezoneTableView.reloadData()
    }

    @IBAction func filterArray(_ sender: Any?) {
        if searchCriteria.selectedSegment == 1 {
            filterTimezoneArray(sender)
            return
        }

        messageLabel.stringValue = CLEmptyString

        filteredArray = []

        if searchField.stringValue.count > 50 {
            isActivityInProgress = false
            messageLabel.stringValue = PreferencesConstants.maxCharactersAllowed
            Timer.scheduledTimer(withTimeInterval: 5,
                                 repeats: false) { _ in
                OperationQueue.main.addOperation {
                    self.messageLabel.stringValue = CLEmptyString
                }
            }
            return
        }

        if searchField.stringValue.count > 0 {
            dataTask?.cancel()
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            perform(#selector(search), with: nil, afterDelay: 0.5)
        } else {
            resetSearchView()
        }

        availableTimezoneTableView.reloadData()
    }
}

extension PreferencesViewController {
    @IBAction func loginPreferenceChanged(_ sender: NSButton) {
        if !SMLoginItemSetEnabled("com.abhishek.ClockerHelper" as CFString, sender.state == .on) {
            Logger.log(object: ["Successful": "NO"], for: "Start Clocker Login")
            addClockerToLoginItemsManually()
        } else {
            Logger.log(object: ["Successful": "YES"], for: "Start Clocker Login")
        }
    }

    private func addClockerToLoginItemsManually() {
        NSApplication.shared.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Clocker is unable to set to start at login. 😅"
        alert.informativeText = "You can manually set it to start at startup by adding Clocker to your login items."
        alert.addButton(withTitle: "Add Manually")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response.rawValue == 1000 {
            OperationQueue.main.addOperation {
                let prefPane = "/System/Library/PreferencePanes/Accounts.prefPane"
                NSWorkspace.shared.openFile(prefPane)
            }
        }
    }
}

// Sorting
extension PreferencesViewController {
    @IBAction func sortOptions(_: NSButton) {
        additionalSortOptions.isHidden.toggle()
    }

    @IBAction func sortByTime(_ sender: NSButton) {
        let sortedByTime = selectedTimeZones.sorted { (obj1, obj2) -> Bool in

            let system = NSTimeZone.system

            guard let object1 = TimezoneData.customObject(from: obj1),
                let object2 = TimezoneData.customObject(from: obj2) else {
                assertionFailure("Data was unexpectedly nil")
                return false
            }

            let timezone1 = NSTimeZone(name: object1.timezoneID!)
            let timezone2 = NSTimeZone(name: object2.timezoneID!)

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
        let sortedLabels = selectedTimeZones.sorted { (obj1, obj2) -> Bool in

            guard let object1 = TimezoneData.customObject(from: obj1),
                let object2 = TimezoneData.customObject(from: obj2) else {
                assertionFailure("Data was unexpectedly nil")
                return false
            }

            return isLabelOptionSelected ? object1.customLabel! > object2.customLabel! : object1.customLabel! < object2.customLabel!
        }

        sender.image = isLabelOptionSelected ? NSImage(named: NSImage.Name("NSDescendingSortIndicator"))! : NSImage(named: NSImage.Name("NSAscendingSortIndicator"))!

        isLabelOptionSelected.toggle()

        DataStore.shared().setTimezones(sortedLabels)

        updateAfterSorting()
    }

    @IBAction func sortByFormattedAddress(_ sender: NSButton) {
        let sortedByAddress = selectedTimeZones.sorted { (obj1, obj2) -> Bool in

            guard let object1 = TimezoneData.customObject(from: obj1),
                let object2 = TimezoneData.customObject(from: obj2) else {
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

extension PreferencesViewController: SRRecorderControlDelegate {
}

// Helpers
extension PreferencesViewController {
    private func numberOfSearchResults() -> Int {
        if searchCriteria.selectedSegment == 0 {
            return filteredArray.count
        }

        if searchField.stringValue.count > 0 {
            return timezoneFilteredArray.count
        }

        return timezoneArray.count
    }

    private func insert(timezone: TimezoneData, at index: Int) {
        let encodedObject = NSKeyedArchiver.archivedData(withRootObject: timezone)
        var newDefaults = selectedTimeZones
        newDefaults[index] = encodedObject
        DataStore.shared().setTimezones(newDefaults)
    }
}

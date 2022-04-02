// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit
import EventKit

struct PanelConstants {
    static let notReallyButtonTitle = "Not Really"
    static let feedbackString = "Mind giving feedback?"
    static let noThanksTitle = "No, thanks"
    static let yesWithQuestionMark = "Yes?"
    static let yesWithExclamation = "Yes!"
    static let modernSliderPointsInADay = 96
}

class ParentPanelController: NSWindowController {
    private var futureSliderObserver: NSKeyValueObservation?
    private var userFontSizeSelectionObserver: NSKeyValueObservation?
    private var futureSliderRangeObserver: NSKeyValueObservation?

    private var eventStoreChangedNotification: NSObjectProtocol?

    var dateFormatter = DateFormatter()

    var futureSliderValue: Int {
        return futureSlider.integerValue
    }

    var parentTimer: Repeater?

    var showReviewCell: Bool = false

    var previousPopoverRow: Int = -1

    var additionalOptionsPopover: NSPopover?

    var datasource: TimezoneDataSource?

    private lazy var feedbackWindow = AppFeedbackWindowController.shared()

    private var notePopover: NotesPopover?

    private lazy var oneWindow: OneWindowController? = {
        let preferencesStoryboard = NSStoryboard(name: "Preferences", bundle: nil)
        return preferencesStoryboard.instantiateInitialController() as? OneWindowController
    }()

    @IBOutlet var mainTableView: PanelTableView!

    @IBOutlet var stackView: NSStackView!

    @IBOutlet var futureSlider: NSSlider!

    @IBOutlet var scrollViewHeight: NSLayoutConstraint!

    @IBOutlet var futureSliderView: NSView!

    @IBOutlet var reviewView: NSView!

    @IBOutlet var leftField: NSTextField!

    @IBOutlet var sharingButton: NSButton!

    @IBOutlet var leftButton: NSButton!

    @IBOutlet var rightButton: NSButton!

    @IBOutlet var shutdownButton: NSButton!

    @IBOutlet var preferencesButton: NSButton!

    @IBOutlet var pinButton: NSButton!

    @IBOutlet var sliderDatePicker: NSDatePicker!

    @IBOutlet var roundedDateView: NSView!

    // Modern Slider
    public var currentCenterIndexPath: Int = -1
    public var closestQuarterTimeRepresentation: Date?
    @IBOutlet var modernSlider: NSCollectionView!
    @IBOutlet var modernSliderLabel: NSTextField!
    @IBOutlet var modernContainerView: ModernSliderContainerView!
    @IBOutlet var goBackwardsButton: NSButton!
    @IBOutlet var goForwardButton: NSButton!
    @IBOutlet var resetModernSliderButton: NSButton!

    // Upcoming Events
    @IBOutlet var upcomingEventCollectionView: NSCollectionView!
    @IBOutlet var upcomingEventContainerView: NSView!
    public var upcomingEventsDataSource: UpcomingEventsDataSource!

    var defaultPreferences: [Data] {
        return DataStore.shared().timezones()
    }

    deinit {
        datasource = nil

        if let eventStoreNotif = eventStoreChangedNotification {
            NotificationCenter.default.removeObserver(eventStoreNotif)
        }

        [futureSliderObserver, userFontSizeSelectionObserver, futureSliderRangeObserver].forEach {
            $0?.invalidate()
        }
    }

    private func setupObservers() {
        futureSliderObserver = UserDefaults.standard.observe(\.displayFutureSlider, options: [.new]) { _, change in
            if let changedValue = change.newValue {
                if changedValue == 0 {
                    self.futureSliderView.isHidden = true
                    if self.modernContainerView != nil {
                        self.modernContainerView.isHidden = false
                    }
                } else if changedValue == 1 {
                    self.futureSliderView.isHidden = false

                    if self.modernContainerView != nil {
                        self.modernContainerView.isHidden = true
                    }

                } else {
                    self.futureSliderView.isHidden = true

                    if self.modernContainerView != nil {
                        self.modernContainerView.isHidden = true
                    }
                }
            }
        }

        userFontSizeSelectionObserver = UserDefaults.standard.observe(\.userFontSize, options: [.new]) { _, change in
            if let newFontSize = change.newValue {
                Logger.log(object: ["FontSize": newFontSize], for: "User Font Size Preference")
                self.mainTableView.reloadData()
                self.setScrollViewConstraint()
            }
        }

        futureSliderRangeObserver = UserDefaults.standard.observe(\.sliderDayRange, options: [.new]) { _, change in
            if change.newValue != nil {
                self.adjustFutureSliderBasedOnPreferences()
                if self.modernSlider != nil {
                    self.modernSlider.reloadData()
                }
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        // Setup table
        mainTableView.backgroundColor = NSColor.clear
        mainTableView.selectionHighlightStyle = .none
        mainTableView.enclosingScrollView?.hasVerticalScroller = false
        if #available(OSX 11.0, *) {
            mainTableView.style = .fullWidth
        }

        // Setup images
        let sharedThemer = Themer.shared()
        shutdownButton.image = sharedThemer.shutdownImage()
        preferencesButton.image = sharedThemer.preferenceImage()
        pinButton.image = sharedThemer.pinImage()
        sharingButton.image = sharedThemer.sharingImage()

        // Setup KVO observers for user default changes
        setupObservers()

        updateReviewViewFontColor()

        // Set the background color of the bottom buttons view to something different to indicate we're not in a release candidate
        #if DEBUG
            stackView.arrangedSubviews.last?.layer?.backgroundColor = NSColor(deviceRed: 255.0 / 255.0,
                                                                              green: 150.0 / 255.0,
                                                                              blue: 122.0 / 255.0,
                                                                              alpha: 0.5).cgColor
            stackView.arrangedSubviews.last?.toolTip = "Clocker is running in Debug Mode"
        #endif

        // Setup layers
        futureSliderView.wantsLayer = true
        reviewView.wantsLayer = true

        // Setup notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeChanged),
                                               name: Notification.Name.themeDidChange,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(systemTimezoneDidChange),
                                               name: NSNotification.Name.NSSystemTimeZoneDidChange,
                                               object: nil)
        
        if (DataStore.shared().shouldDisplay(.sync)) {
            NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                                   object: self,
                                                   queue: OperationQueue.main)
            { [weak self] _ in
                if let sSelf = self {
                    sSelf.mainTableView.reloadData()
                    sSelf.setScrollViewConstraint()
                }
            }
        }

        // Setup upcoming events view
        upcomingEventContainerView.setAccessibility("UpcomingEventView")
        determineUpcomingViewVisibility()
        setupUpcomingEventViewCollectionViewIfNeccesary()

        // Setup colors based on the curren theme
        themeChanged()

        // UI adjustments based on user preferences
        if DataStore.shared().timezones().isEmpty || DataStore.shared().shouldDisplay(.futureSlider) == false {
            futureSliderView.isHidden = true
            if modernContainerView != nil {
                modernContainerView.isHidden = true
            }
        } else if let value = DataStore.shared().retrieve(key: CLDisplayFutureSliderKey) as? NSNumber {
            if value.intValue == 1 {
                futureSliderView.isHidden = false
                if modernContainerView != nil {
                    modernContainerView.isHidden = true
                }
            } else if value.intValue == 0 {
                futureSliderView.isHidden = true
                // Floating Window doesn't support modern slider yet!
                if modernContainerView != nil {
                    modernContainerView.isHidden = false
                }
            }
        }

        // More UI adjustments
        sharingButton.sendAction(on: .leftMouseDown)
        adjustFutureSliderBasedOnPreferences()
        setupModernSliderIfNeccessary()
        if roundedDateView != nil {
            setupRoundedDateView()
        }
    }

    private func setupRoundedDateView() {
        roundedDateView.wantsLayer = true
        roundedDateView.layer?.cornerRadius = 12.0
        roundedDateView.layer?.masksToBounds = false
        roundedDateView.layer?.backgroundColor = Themer.shared().textBackgroundColor().cgColor
    }

    @objc func systemTimezoneDidChange() {
        OperationQueue.main.addOperation {
            /*
             let locationController = LocationController.sharedController()
             locationController.determineAndRequestLocationAuthorization()*/

            self.updateHomeObject(with: TimeZone.autoupdatingCurrent.identifier,
                                  coordinates: nil)
        }
    }

    private func updateHomeObject(with customLabel: String, coordinates: CLLocationCoordinate2D?) {
        let timezones = DataStore.shared().timezones()

        var timezoneObjects: [TimezoneData] = []

        for timezone in timezones {
            if let model = TimezoneData.customObject(from: timezone) {
                timezoneObjects.append(model)
            }
        }

        for timezoneObject in timezoneObjects where timezoneObject.isSystemTimezone == true {
            timezoneObject.setLabel(customLabel)
            timezoneObject.formattedAddress = customLabel
            if let latlong = coordinates {
                timezoneObject.longitude = latlong.longitude
                timezoneObject.latitude = latlong.latitude
            }
        }

        var datas: [Data] = []

        for updatedObject in timezoneObjects {
            let dataObject = NSKeyedArchiver.archivedData(withRootObject: updatedObject)
            datas.append(dataObject)
        }

        DataStore.shared().setTimezones(datas)

        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setupMenubarTimer()
        }
    }

    func determineUpcomingViewVisibility() {
        let showUpcomingEventView = DataStore.shared().shouldDisplay(ViewType.upcomingEventView)

        if showUpcomingEventView == false {
            upcomingEventContainerView?.isHidden = true
        } else {
            upcomingEventContainerView?.isHidden = false
            setupUpcomingEventView()
            eventStoreChangedNotification = NotificationCenter.default.addObserver(forName: NSNotification.Name.EKEventStoreChanged, object: self, queue: OperationQueue.main) { _ in
                self.fetchCalendarEvents()
            }
        }
    }

    private func adjustFutureSliderBasedOnPreferences() {
        // Setting up Slider's Date Picker
        sliderDatePicker.minDate = Date()

        guard let sliderRange = DataStore.shared().retrieve(key: CLFutureSliderRange) as? NSNumber else {
            sliderDatePicker.maxDate = Date(timeInterval: 1 * 24 * 60 * 60, since: Date())
            return
        }

        sliderDatePicker.maxDate = Date(timeInterval: (sliderRange.doubleValue + 1) * 24 * 60 * 60, since: Date())
        futureSlider.maxValue = (sliderRange.doubleValue + 1) * 24 * 60

        futureSlider.integerValue = 0
        setTimezoneDatasourceSlider(sliderValue: 0)
        updateTableContent()
    }

    private func setupUpcomingEventView() {
        let eventCenter = EventCenter.sharedCenter()

        if eventCenter.calendarAccessGranted() {
            // Nice. Events will be retrieved when we open the panel
        } else if eventCenter.calendarAccessNotDetermined() {
            upcomingEventCollectionView.reloadData()
        } else {
            removeUpcomingEventView()
        }

        themeChanged()
    }

    private func updateReviewViewFontColor() {
        let textColor = Themer.shared().mainTextColor()

        leftField.textColor = textColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let styleAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: NSFont(name: "Avenir-Light", size: 13) ?? NSFont.systemFont(ofSize: 13),
        ]

        let leftButtonAttributedTitle = NSAttributedString(string: leftButton.title, attributes: styleAttributes)
        leftButton.attributedTitle = leftButtonAttributedTitle

        let rightButtonAttributedTitle = NSAttributedString(string: rightButton.title, attributes: styleAttributes)
        rightButton.attributedTitle = rightButtonAttributedTitle

        futureSliderView.layer?.backgroundColor = NSColor.clear.cgColor
    }

    @objc func themeChanged() {
        let sharedThemer = Themer.shared()

        if upcomingEventContainerView?.isHidden == false {
            upcomingEventContainerView?.layer?.backgroundColor = NSColor.clear.cgColor
        }

        shutdownButton.image = sharedThemer.shutdownImage()
        preferencesButton.image = sharedThemer.preferenceImage()
        pinButton.image = sharedThemer.pinImage()
        sharingButton.image = sharedThemer.sharingImage()

        sliderDatePicker.textColor = sharedThemer.mainTextColor()

        if roundedDateView != nil {
            roundedDateView.layer?.backgroundColor = Themer.shared().textBackgroundColor().cgColor
        }

        updateReviewViewFontColor()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        additionalOptionsPopover = NSPopover()
    }

    func screenHeight() -> CGFloat {
        guard let main = NSScreen.main else { return 100 }

        let mouseLocation = NSEvent.mouseLocation

        var current = main.frame.height

        let activeScreens = NSScreen.screens.filter { current -> Bool in
            NSMouseInRect(mouseLocation, current.frame, false)
        }

        if let main = activeScreens.first {
            current = main.frame.height
        }

        return current
    }

    func invalidateMenubarTimer() {
        parentTimer = nil
    }

    private func getAdjustedRowHeight(for object: TimezoneData?, _ currentHeight: CGFloat) -> CGFloat {
        let userFontSize: NSNumber = DataStore.shared().retrieve(key: CLUserFontSizePreference) as? NSNumber ?? 4
        let shouldShowSunrise = DataStore.shared().shouldDisplay(.sunrise)

        var newHeight = currentHeight

        if newHeight <= 68.0 {
            newHeight = 60.0
        }

        if newHeight >= 68.0 {
            newHeight = userFontSize == 4 ? 68.0 : 68.0
            if let note = object?.note, note.isEmpty == false {
                newHeight += 20
            } else if DataStore.shared().shouldDisplay(.dstTransitionInfo),
                      let obj = object,
                      TimezoneDataOperations(with: obj).nextDaylightSavingsTransitionIfAvailable(with: futureSliderValue) != nil
            {
                newHeight += 20
            }
        }

        if newHeight >= 88.0 {
            // Set it to 90 expicity in case the row height is calculated be higher.
            newHeight = 88.0

            if let note = object?.note, note.isEmpty, DataStore.shared().shouldDisplay(.dstTransitionInfo) == false, let obj = object, TimezoneDataOperations(with: obj).nextDaylightSavingsTransitionIfAvailable(with: futureSliderValue) == nil {
                newHeight -= 20.0
            }
        }

        if shouldShowSunrise, object?.selectionType == .city {
            newHeight += 8.0
        }

        if object?.isSystemTimezone == true {
            newHeight += 5
        }

        newHeight += mainTableView.intercellSpacing.height

        return newHeight
    }

    func setScrollViewConstraint() {
        var totalHeight: CGFloat = 0.0
        let preferences = defaultPreferences

        for cellIndex in 0 ..< preferences.count {
            let currentObject = TimezoneData.customObject(from: preferences[cellIndex])
            let rowRect = mainTableView.rect(ofRow: cellIndex)
            totalHeight += getAdjustedRowHeight(for: currentObject, rowRect.size.height)
        }

        // This is for the Add Cell View case
        if preferences.isEmpty {
            scrollViewHeight.constant = 100.0
            return
        }

        if let userFontSize = DataStore.shared().retrieve(key: CLUserFontSizePreference) as? NSNumber {
            if userFontSize == 4 {
                scrollViewHeight.constant = totalHeight + CGFloat(userFontSize.intValue * 2)
            } else {
                scrollViewHeight.constant = totalHeight + CGFloat(userFontSize.intValue * 2) * 3.0
            }
        }

        if DataStore.shared().shouldDisplay(ViewType.upcomingEventView) {
            if scrollViewHeight.constant > (screenHeight() - 160) {
                scrollViewHeight.constant = (screenHeight() - 160)
            }
        } else {
            if scrollViewHeight.constant > (screenHeight() - 100) {
                scrollViewHeight.constant = (screenHeight() - 100)
            }
        }

        if DataStore.shared().shouldDisplay(.futureSlider) {
            let isModernSliderDisplayed = DataStore.shared().retrieve(key: CLDisplayFutureSliderKey) as? NSNumber ?? 0
            if isModernSliderDisplayed == 0 {
                if scrollViewHeight.constant >= (screenHeight() - 200) {
                    scrollViewHeight.constant = (screenHeight() - 300)
                }
            } else {
                if scrollViewHeight.constant >= (screenHeight() - 200) {
                    scrollViewHeight.constant = (screenHeight() - 200)
                }
            }
        }
    }

    func updateDefaultPreferences() {
        if #available(OSX 10.14, *) {
            PerfLogger.startMarker("Update Default Preferences")
        }

        updatePanelColor()

        let defaults = DataStore.shared().timezones()
        let convertedTimezones = defaults.map { data -> TimezoneData in
            TimezoneData.customObject(from: data)!
        }

        datasource = TimezoneDataSource(items: convertedTimezones)
        mainTableView.dataSource = datasource
        mainTableView.delegate = datasource
        mainTableView.panelDelegate = datasource

        updateDatasource(with: convertedTimezones)

        if #available(OSX 10.14, *) {
            PerfLogger.endMarker("Update Default Preferences")
        }
    }

    func updateDatasource(with timezones: [TimezoneData]) {
        datasource?.setItems(items: timezones)
        datasource?.setSlider(value: futureSliderValue)

        if let userFontSize = DataStore.shared().retrieve(key: CLUserFontSizePreference) as? NSNumber {
            scrollViewHeight.constant = CGFloat(timezones.count) * (mainTableView.rowHeight + CGFloat(userFontSize.floatValue * 1.5))

            setScrollViewConstraint()

            mainTableView.reloadData()
        }
    }

    func updatePanelColor() {
        window?.alphaValue = 1.0
    }

    @IBAction func sliderMoved(_: Any) {
        let currentCalendar = Calendar(identifier: .gregorian)
        guard let newDate = currentCalendar.date(byAdding: .minute,
                                                 value: Int(futureSlider.doubleValue),
                                                 to: Date())
        else {
            assertionFailure("Data was unexpectedly nil")
            return
        }

        setTimezoneDatasourceSlider(sliderValue: futureSliderValue)

        sliderDatePicker.dateValue = newDate

        mainTableView.reloadData()
    }

    func setTimezoneDatasourceSlider(sliderValue: Int) {
        datasource?.setSlider(value: sliderValue)
    }

    @IBAction func openPreferences(_: NSButton) {
        updatePopoverDisplayState() // Popover's class has access to all timezones. Need to close the popover, so that we don't have two copies of selections
        openPreferencesWindow()
    }

    func deleteTimezone(at row: Int) {
        var defaults = defaultPreferences

        // Remove from panel
        defaults.remove(at: row)
        DataStore.shared().setTimezones(defaults)
        updateDefaultPreferences()

        NotificationCenter.default.post(name: Notification.Name.customLabelChanged,
                                        object: nil)

        // Now log!
        Logger.log(object: nil, for: "Deleted Timezone Through Swipe")
    }

    private lazy var menubarTitleHandler = MenubarTitleProvider(with: DataStore.shared())

    @objc func updateTime() {
        let store = DataStore.shared()

        let menubarCount = store.menubarTimezones()?.count ?? 0

        if menubarCount >= 1 || store.shouldDisplay(.showMeetingInMenubar) == true {
            if let status = (NSApplication.shared.delegate as? AppDelegate)?.statusItemForPanel() {
                if store.shouldDisplay(.menubarCompactMode) {
                    status.updateCompactMenubar()
                } else {
                    status.statusItem.title = menubarTitleHandler.titleForMenubar()
                }
            }
        }

        let preferences = store.timezones()

        if modernSlider != nil, modernSlider.isHidden == false, modernContainerView.currentlyInFocus == false {
            if currentCenterIndexPath != -1, currentCenterIndexPath != modernSlider.numberOfItems(inSection: 0) / 2 {
                // User is currently scrolling, return!
                return
            }
        }

        stride(from: 0, to: preferences.count, by: 1).forEach {
            let current = preferences[$0]

            if $0 < mainTableView.numberOfRows,
               let cellView = mainTableView.view(atColumn: 0, row: $0, makeIfNecessary: false) as? TimezoneCellView,
               let model = TimezoneData.customObject(from: current)
            {
                if let futureSliderCell = futureSlider.cell as? CustomSliderCell, futureSliderCell.tracking == true {
                    return
                }
                if modernContainerView != nil, modernSlider.isHidden == false, modernContainerView.currentlyInFocus {
                    return
                }
                let dataOperation = TimezoneDataOperations(with: model)
                cellView.time.stringValue = dataOperation.time(with: futureSliderValue)
                cellView.sunriseSetTime.stringValue = dataOperation.formattedSunriseTime(with: futureSliderValue)
                cellView.sunriseSetTime.lineBreakMode = .byClipping
                cellView.relativeDate.stringValue = dataOperation.date(with: futureSliderValue, displayType: .panel)
                cellView.currentLocationIndicator.isHidden = !model.isSystemTimezone
                cellView.sunriseImage.image = model.isSunriseOrSunset ? Themer.shared().sunriseImage() : Themer.shared().sunsetImage()
                if #available(macOS 10.14, *) {
                    cellView.sunriseImage.contentTintColor = model.isSunriseOrSunset ? NSColor.systemYellow : NSColor.systemOrange
                }
                if let note = model.note, !note.isEmpty {
                    cellView.noteLabel.stringValue = note
                } else if DataStore.shared().shouldDisplay(.dstTransitionInfo),
                          let value = TimezoneDataOperations(with: model).nextDaylightSavingsTransitionIfAvailable(with: futureSliderValue)
                {
                    cellView.noteLabel.stringValue = value
                } else {
                    cellView.noteLabel.stringValue = CLEmptyString
                }
                cellView.layout(with: model)
                updateDatePicker()
            }
        }
    }

    private func updateDatePicker() {
        sliderDatePicker.minDate = Date()
        guard let sliderRange = DataStore.shared().retrieve(key: CLFutureSliderRange) as? NSNumber else {
            sliderDatePicker.maxDate = Date(timeInterval: 1 * 24 * 60 * 60, since: Date())
            return
        }

        sliderDatePicker.maxDate = Date(timeInterval: (sliderRange.doubleValue + 1) * 24 * 60 * 60, since: Date())
    }

    @discardableResult
    func showNotesPopover(forRow row: Int, relativeTo _: NSRect, andButton target: NSButton!) -> Bool {
        let defaults = DataStore.shared().timezones()

        guard let popover = additionalOptionsPopover else {
            assertionFailure("Data was unexpectedly nil")
            return false
        }

        var correctRow = row

        target.image = Themer.shared().extraOptionsHighlightedImage()

        popover.animates = true

        if notePopover == nil {
            notePopover = NotesPopover(nibName: NSNib.Name.notesPopover, bundle: nil)
            popover.behavior = .applicationDefined
            popover.delegate = self
        }

        // Found a case where row number was 8 but we had only 2 timezones
        if correctRow >= defaults.count {
            correctRow = defaults.count - 1
        }

        let current = defaults[correctRow]

        if let model = TimezoneData.customObject(from: current) {
            notePopover?.setDataSource(data: model)
            notePopover?.setRow(row: correctRow)
            notePopover?.set(timezones: defaults)

            popover.contentViewController = notePopover
            notePopover?.set(with: popover)
            return true
        }

        return false
    }

    func dismissRowActions() {
        mainTableView.rowActionsVisible = false
    }

    @objc func updateTableContent() {
        mainTableView.reloadData()
    }

    @objc private func openPreferencesWindow() {
        oneWindow?.openGeneralPane()
    }

    @IBAction func dismissNextEventLabel(_: NSButton) {
        let eventCenter = EventCenter.sharedCenter()
        let now = Date()
        if let events = eventCenter.eventsForDate[NSCalendar.autoupdatingCurrent.startOfDay(for: now)], events.isEmpty == false {
            if let upcomingEvent = eventCenter.nextOccuring(events), let meetingLink = upcomingEvent.meetingURL {
                NSWorkspace.shared.open(meetingLink)
            }
        } else {
            removeUpcomingEventView()
        }
    }

    func removeUpcomingEventView() {
        OperationQueue.main.addOperation {
            if self.upcomingEventCollectionView != nil {
                if self.stackView.arrangedSubviews.contains(self.upcomingEventContainerView!), self.upcomingEventContainerView?.isHidden == false {
                    self.upcomingEventContainerView?.isHidden = true
                    UserDefaults.standard.set("NO", forKey: CLShowUpcomingEventView)
                    Logger.log(object: ["Removed": "YES"], for: "Removed Upcoming Event View")
                }
            }
        }
    }

    @IBAction func calendarButtonAction(_ sender: NSButton) {
        if sender.title == NSLocalizedString("Click here to start.",
                                             comment: "Button Title for no Calendar access")
        {
            showPermissionsWindow()
        } else {
            retrieveCalendarEvents()
        }
    }

    private func showPermissionsWindow() {
        oneWindow?.openPermissionsPane()
        NSApp.activate(ignoringOtherApps: true)
    }

    func retrieveCalendarEvents() {
        if #available(OSX 10.14, *) {
            PerfLogger.startMarker("Retrieve Calendar Events")
        }

        let eventCenter = EventCenter.sharedCenter()

        if eventCenter.calendarAccessGranted() {
            fetchCalendarEvents()
        } else if eventCenter.calendarAccessNotDetermined() {
            /* Wait till we get the thumbs up. */
        } else {
            removeUpcomingEventView()
        }

        if #available(OSX 10.14, *) {
            PerfLogger.endMarker("Retrieve Calendar Events")
        }
    }

    @IBAction func shareAction(_ sender: NSButton) {
        let copyAllTimes = retrieveAllTimes()
        let servicePicker = NSSharingServicePicker(items: [copyAllTimes])
        servicePicker.delegate = self

        servicePicker.show(relativeTo: sender.bounds,
                           of: sender,
                           preferredEdge: .minY)
    }

    @IBAction func convertToFloatingWindow(_: NSButton) {
        guard let sharedDelegate = NSApplication.shared.delegate as? AppDelegate
        else {
            assertionFailure("Data was unexpectedly nil")
            return
        }

        let showAppInForeground = DataStore.shared().shouldDisplay(ViewType.showAppInForeground)

        let inverseSelection = showAppInForeground ? NSNumber(value: 0) : NSNumber(value: 1)

        UserDefaults.standard.set(inverseSelection, forKey: CLShowAppInForeground)

        close()

        if inverseSelection.isEqual(to: NSNumber(value: 1)) {
            sharedDelegate.setupFloatingWindow(false)
        } else {
            sharedDelegate.setupFloatingWindow(true)
            updateDefaultPreferences()
        }

        let mode = inverseSelection.isEqual(to: NSNumber(value: 1)) ? "Floating Mode" : "Menubar Mode"

        Logger.log(object: ["displayMode": mode], for: "Clocker Mode")
    }

    func showUpcomingEventView() {
        OperationQueue.main.addOperation {
            if let upcomingView = self.upcomingEventContainerView, upcomingView.isHidden {
                self.upcomingEventContainerView?.isHidden = false
                UserDefaults.standard.set("YES", forKey: CLShowUpcomingEventView)
                Logger.log(object: ["Shown": "YES"], for: "Added Upcoming Event View")
                self.themeChanged()
            }
        }
    }

    private func fetchCalendarEvents() {
        if #available(OSX 10.14, *) {
            PerfLogger.startMarker("Fetch Calendar Events")
        }

        let eventCenter = EventCenter.sharedCenter()
        let now = Date()

        if let events = eventCenter.eventsForDate[NSCalendar.autoupdatingCurrent.startOfDay(for: now)], events.isEmpty == false {
            OperationQueue.main.addOperation {
                if self.upcomingEventCollectionView != nil,
                   let upcomingEvents = eventCenter.upcomingEventsForDay(events)
                {
                    self.upcomingEventsDataSource.updateEventsDataSource(upcomingEvents)
                    self.upcomingEventCollectionView.reloadData()
                    return
                }

                if #available(OSX 10.14, *) {
                    PerfLogger.endMarker("Fetch Calendar Events")
                }
            }
        } else {
            if upcomingEventCollectionView != nil {
                upcomingEventsDataSource.updateEventsDataSource([])
                upcomingEventCollectionView.reloadData()
                return
            }
            if #available(OSX 10.14, *) {
                PerfLogger.endMarker("Fetch Calendar Events")
            }
        }
    }

    // If the popover is displayed, close it
    // Called when preferences are going to be displayed!
    func updatePopoverDisplayState() {
        if notePopover != nil, let isShown = notePopover?.popover?.isShown, isShown {
            notePopover?.popover?.close()
        }
        additionalOptionsPopover = nil
    }

    // MARK: Review

    @IBAction func actionOnNegativeFeedback(_ sender: NSButton) {
        if sender.title == PanelConstants.notReallyButtonTitle {
            setAnimated(title: PanelConstants.feedbackString,
                        field: leftField,
                        leftTitle: PanelConstants.noThanksTitle,
                        rightTitle: PanelConstants.yesWithQuestionMark)

        } else {
            updateReviewView()
            ReviewController.prompted()

            if let countryCode = Locale.autoupdatingCurrent.regionCode {
                Logger.log(object: ["CurrentCountry": countryCode], for: "Remind Later for Feedback")
            }
        }
    }

    @IBAction func actionOnPositiveFeedback(_ sender: NSButton) {
        if sender.title == PanelConstants.yesWithExclamation {
            setAnimated(title: "Would you like to rate us?",
                        field: leftField,
                        leftTitle: PanelConstants.noThanksTitle,
                        rightTitle: "Yes")
        } else if sender.title == PanelConstants.yesWithQuestionMark {
            ReviewController.prompted()
            updateReviewView()

            feedbackWindow = AppFeedbackWindowController.shared()
            feedbackWindow.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            updateReviewView()
            ReviewController.prompt()
        }
    }

    private func updateReviewView() {
        reviewView.isHidden = true
        showReviewCell = false
        leftField.stringValue = NSLocalizedString("Enjoy using Clocker?",
                                                  comment: "Title asking users if they like the app")

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let styleAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: NSFont(name: "Avenir-Light", size: 13)!,
        ]
        leftButton.attributedTitle = NSAttributedString(string: "Not Really", attributes: styleAttributes)
        rightButton.attributedTitle = NSAttributedString(string: "Yes!", attributes: styleAttributes)
    }

    private func setAnimated(title: String, field: NSTextField, leftTitle: String, rightTitle: String) {
        if field.stringValue == title {
            return
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 1
            context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            leftButton.animator().alphaValue = 0.0
            rightButton.animator().alphaValue = 0.0
        }, completionHandler: {
            field.stringValue = title

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 1
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
                self.runAnimationCompletionBlock(leftTitle, rightTitle)
            }, completionHandler: {})
        })
    }

    private func runAnimationCompletionBlock(_ leftButtonTitle: String, _ rightButtonTitle: String) {
        leftButton.animator().alphaValue = 1.0
        rightButton.animator().alphaValue = 1.0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let styleAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: NSFont(name: "Avenir-Light", size: 13)!,
        ]

        if leftButton.attributedTitle.string == "Not Really" {
            leftButton.animator().attributedTitle = NSAttributedString(string: PanelConstants.noThanksTitle, attributes: styleAttributes)
        }

        if rightButton.attributedTitle.string == PanelConstants.yesWithExclamation {
            rightButton.animator().attributedTitle = NSAttributedString(string: "Yes, sure", attributes: styleAttributes)
        }

        leftButton.animator().attributedTitle = NSAttributedString(string: leftButtonTitle, attributes: styleAttributes)
        rightButton.animator().attributedTitle = NSAttributedString(string: rightButtonTitle, attributes: styleAttributes)
    }

    // MARK: Date Picker + Slider

    @IBAction func sliderPickerChanged(_: Any) {
        let minutesDifference = minutes(from: Date(), other: sliderDatePicker.dateValue)
        futureSlider.integerValue = minutesDifference
        setTimezoneDatasourceSlider(sliderValue: minutesDifference)
        updateTableContent()
    }

    func minutes(from date: Date, other: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: other).minute ?? 0
    }

    @IBAction func resetDatePicker(_: Any) {
        futureSlider.integerValue = 0
        sliderDatePicker.dateValue = Date()
        setTimezoneDatasourceSlider(sliderValue: 0)
    }

    @objc func terminateClocker() {
        NSApplication.shared.terminate(nil)
    }

    @objc func reportIssue() {
        feedbackWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.orderOut(nil)

        if let countryCode = Locale.autoupdatingCurrent.regionCode {
            let custom: [String: Any] = ["Country": countryCode]
            Logger.log(object: custom, for: "Report Issue Opened")
        }
    }

    @objc func openCrowdin() {
        guard let localizationURL = URL(string: AboutUsConstants.CrowdInLocalizationLink),
              let languageCode = Locale.preferredLanguages.first else { return }

        NSWorkspace.shared.open(localizationURL)

        // Log this
        let custom: [String: Any] = ["Language": languageCode]
        Logger.log(object: custom, for: "Opened Localization Link")
    }

    @objc func rate() {
        guard let sourceURL = URL(string: AboutUsConstants.AppStoreLink) else { return }

        NSWorkspace.shared.open(sourceURL)
    }

    @objc func openFAQs() {
        guard let sourceURL = URL(string: AboutUsConstants.FAQsLink) else { return }

        NSWorkspace.shared.open(sourceURL)
    }

    @IBAction func showMoreOptions(_ sender: NSButton) {
        let menuItem = NSMenu(title: "More Options")
        let terminateOption = NSMenuItem(title: "Quit Clocker",
                                         action: #selector(terminateClocker), keyEquivalent: "")
        let rateClocker = NSMenuItem(title: "Support Clocker...",
                                     action: #selector(rate), keyEquivalent: "")
        let sendFeedback = NSMenuItem(title: "Send Feedback...",
                                      action: #selector(reportIssue), keyEquivalent: "")
        let localizeClocker = NSMenuItem(title: "Localize Clocker...",
                                         action: #selector(openCrowdin), keyEquivalent: "")
        let openPreferences = NSMenuItem(title: "Preferences",
                                         action: #selector(openPreferencesWindow), keyEquivalent: "")

        let appDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? "Clocker"
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "N/A"
        let longVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "N/A"

        let versionInfo = "\(appDisplayName) \(shortVersion) (\(longVersion))"
        let clockerVersionInfo = NSMenuItem(title: versionInfo, action: nil, keyEquivalent: "")
        clockerVersionInfo.isEnabled = false
        menuItem.addItem(openPreferences)
        menuItem.addItem(rateClocker)
        menuItem.addItem(withTitle: "FAQs", action: #selector(openFAQs), keyEquivalent: "")
        menuItem.addItem(sendFeedback)
        menuItem.addItem(localizeClocker)
        menuItem.addItem(NSMenuItem.separator())
        menuItem.addItem(clockerVersionInfo)

        menuItem.addItem(NSMenuItem.separator())
        menuItem.addItem(terminateOption)
        NSMenu.popUpContextMenu(menuItem,
                                with: NSApp.currentEvent!,
                                for: sender)
    }
}

extension ParentPanelController: NSPopoverDelegate {
    func popoverShouldClose(_: NSPopover) -> Bool {
        return false
    }
}

extension ParentPanelController: NSSharingServicePickerDelegate {
    func sharingServicePicker(_: NSSharingServicePicker, delegateFor sharingService: NSSharingService) -> NSSharingServiceDelegate? {
        Logger.log(object: ["Service Title": sharingService.title],
                   for: "Sharing Service Executed")
        return self as? NSSharingServiceDelegate
    }

    func sharingServicePicker(_: NSSharingServicePicker, sharingServicesForItems _: [Any], proposedSharingServices proposed: [NSSharingService]) -> [NSSharingService] {
        let copySharingService = NSSharingService(title: "Copy All Times", image: NSImage(), alternateImage: nil) { [weak self] in
            guard let strongSelf = self else { return }
            let clipboardCopy = strongSelf.retrieveAllTimes()
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(clipboardCopy, forType: .string)
        }
        let allowedServices: Set<String> = Set(["Messages", "Notes"])
        let filteredServices = proposed.filter { service in
            allowedServices.contains(service.title)
        }

        var newProposedServices: [NSSharingService] = [copySharingService]
        newProposedServices.append(contentsOf: filteredServices)
        return newProposedServices
    }

    /// Retrieves all the times from user's added timezones. Times are sorted by date. For eg:
    /// Feb 5
    /// California - 17:17:01
    /// Feb 6
    /// London - 01:17:01
    private func retrieveAllTimes() -> String {
        var clipboardCopy = String()

        // Get all timezones
        let timezones = DataStore.shared().timezones()

        if timezones.isEmpty {
            return clipboardCopy
        }

        // Sort them in ascending order
        let sortedByTime = timezones.sorted { obj1, obj2 -> Bool in
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

            return difference1 > difference2
        }

        // Grab date in first place and store it as local variable
        guard let earliestTimezone = TimezoneData.customObject(from: sortedByTime.first) else {
            return clipboardCopy
        }

        let timezoneOperations = TimezoneDataOperations(with: earliestTimezone)
        var sectionTitle = timezoneOperations.todaysDate(with: 0) // TODO: Take slider value into consideration
        clipboardCopy.append("\(sectionTitle)\n")

        stride(from: 0, to: sortedByTime.count, by: 1).forEach {
            if $0 < sortedByTime.count,
               let dataModel = TimezoneData.customObject(from: sortedByTime[$0])
            {
                let dataOperations = TimezoneDataOperations(with: dataModel)
                let date = dataOperations.todaysDate(with: 0)
                let time = dataOperations.time(with: 0)
                if date != sectionTitle {
                    sectionTitle = date
                    clipboardCopy.append("\n\(sectionTitle)\n")
                }

                clipboardCopy.append("\(dataModel.formattedTimezoneLabel()) - \(time)\n")
            }
        }
        return clipboardCopy
    }
}

// Copyright © 2015 Abhishek Banthia

import Cocoa
import EventKit

struct PanelConstants {
    static let notReallyButtonTitle = "Not Really"
    static let feedbackString = "Mind giving feedback?"
    static let noThanksTitle = "No, thanks"
    static let yesWithQuestionMark = "Yes?"
    static let yesWithExclamation = "Yes!"
}

class ParentPanelController: NSWindowController {
    var dateFormatter = DateFormatter()

    var futureSliderValue: Int {
        return futureSlider.integerValue
    }

    var parentTimer: Repeater?

    var showReviewCell: Bool = false

    var previousPopoverRow: Int = -1

    var morePopover: NSPopover?

    var datasource: TimezoneDataSource?

    private lazy var feedbackWindow: AppFeedbackWindowController = AppFeedbackWindowController.shared()

    private var note: NotesPopover?

    private lazy var oneWindow = OneWindowController.shared()

    @IBOutlet var mainTableView: PanelTableView!

    @IBOutlet var stackView: NSStackView!

    @IBOutlet var futureSlider: NSSlider!

    @IBOutlet var scrollViewHeight: NSLayoutConstraint!

    @IBOutlet var calendarColorView: NSView!

    @IBOutlet var futureSliderView: NSView!

    @IBOutlet var upcomingEventView: NSView?

    @IBOutlet var reviewView: NSView!

    @IBOutlet var leftField: NSTextField!

    @IBOutlet var nextEventLabel: NSTextField!

    @IBOutlet var whiteRemoveButton: NSButton!

    @IBOutlet var sharingButton: NSButton!

    @IBOutlet var leftButton: NSButton!

    @IBOutlet var rightButton: NSButton!

    @IBOutlet var shutdownButton: NSButton!

    @IBOutlet var preferencesButton: NSButton!

    @IBOutlet var pinButton: NSButton!

    @IBOutlet var calendarButton: NSButton!

    @IBOutlet var sliderDatePicker: NSDatePicker!

    @IBOutlet var debugVersionView: NSView!

    var defaultPreferences: [Data] {
        return DataStore.shared().timezones()
    }

    deinit {
        datasource = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        mainTableView.backgroundColor = NSColor.clear

        let sharedThemer = Themer.shared()
        shutdownButton.image = sharedThemer.shutdownImage()
        preferencesButton.image = sharedThemer.preferenceImage()
        pinButton.image = sharedThemer.pinImage()
        sharingButton.image = sharedThemer.sharingImage()

        if let upcomingView = upcomingEventView {
            upcomingView.setAccessibility("UpcomingEventView")
        }

        mainTableView.selectionHighlightStyle = .none
        mainTableView.enclosingScrollView?.hasVerticalScroller = false

        [CLDisplayFutureSliderKey, CLUserFontSizePreference, CLThemeKey, CLFutureSliderRange].forEach { key in

            UserDefaults.standard.addObserver(self,
                                              forKeyPath: key,
                                              options: .new,
                                              context: nil)
        }

        updateReviewViewFontColor()

        futureSliderView.wantsLayer = true
        reviewView.wantsLayer = true

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeChanged),
                                               name: Notification.Name.themeDidChange,
                                               object: nil)

        determineUpcomingViewVisibility()

        themeChanged()

        futureSliderView.isHidden = !(DataStore.shared().shouldDisplay(.futureSlider))

        sharingButton.sendAction(on: .leftMouseDown)

        adjustFutureSliderBasedOnPreferences()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(timezoneGonnaChange),
                                               name: NSNotification.Name.NSSystemTimeZoneDidChange,
                                               object: nil)

        showDebugVersionViewIfNeccesary()
    }

    private func showDebugVersionViewIfNeccesary() {

        if debugVersionView != nil {
            debugVersionView.wantsLayer = true
            debugVersionView.layer?.backgroundColor = NSColor.systemRed.cgColor
        }

        #if RELEASE
        if debugVersionView != nil && stackView.arrangedSubviews.contains(debugVersionView) {
            stackView.removeView(debugVersionView)
        }
        #endif
    }

    @objc func timezoneGonnaChange() {
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

        for timezoneObject in timezoneObjects {
            if timezoneObject.isSystemTimezone == true {
                timezoneObject.setLabel(customLabel)
                if let latlong = coordinates {
                    timezoneObject.longitude = latlong.longitude
                    timezoneObject.latitude = latlong.latitude
                }
            }
        }

        var datas: [Data] = []

        for updatedObject in timezoneObjects {
            let dataObject = NSKeyedArchiver.archivedData(withRootObject: updatedObject)
            datas.append(dataObject)
        }

        DataStore.shared().setTimezones(datas)
    }

    func determineUpcomingViewVisibility() {
        let showUpcomingEventView = DataStore.shared().shouldDisplay(ViewType.upcomingEventView)

        if showUpcomingEventView == false {
            upcomingEventView?.isHidden = true
        } else {
            upcomingEventView?.isHidden = false
            setupUpcomingEventView()
            NotificationCenter.default.addObserver(forName: NSNotification.Name.EKEventStoreChanged, object: self, queue: OperationQueue.main) { _ in
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
            nextEventLabel.stringValue = "See your next Calendar event here."
            setCalendarButtonTitle(buttonTitle: "Click here to start.")
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
            NSAttributedString.Key.font: NSFont(name: "Avenir-Light", size: 13) ?? NSFont.systemFont(ofSize: 13)
        ]

        let leftButtonAttributedTitle = NSAttributedString(string: leftButton.title, attributes: styleAttributes)
        leftButton.attributedTitle = leftButtonAttributedTitle

        let rightButtonAttributedTitle = NSAttributedString(string: rightButton.title, attributes: styleAttributes)
        rightButton.attributedTitle = rightButtonAttributedTitle

        futureSliderView.layer?.backgroundColor = NSColor.clear.cgColor
    }

    @objc func themeChanged() {
        let sharedThemer = Themer.shared()

        if upcomingEventView?.isHidden == false {
            upcomingEventView?.layer?.backgroundColor = NSColor.clear.cgColor
            nextEventLabel.textColor = sharedThemer.mainTextColor()
            whiteRemoveButton.image = sharedThemer.removeImage()
            setCalendarButtonTitle(buttonTitle: calendarButton.title)
        }

        shutdownButton.image = sharedThemer.shutdownImage()
        preferencesButton.image = sharedThemer.preferenceImage()
        pinButton.image = sharedThemer.pinImage()
        sharingButton.image = sharedThemer.sharingImage()

        sliderDatePicker.textColor = sharedThemer.mainTextColor()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        morePopover = NSPopover()
    }

    private func setCalendarButtonTitle(buttonTitle: String) {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.lineBreakMode = .byTruncatingTail

        if let boldFont = NSFont(name: "Avenir", size: 12) {
            let attributes = [NSAttributedString.Key.foregroundColor: NSColor.lightGray, NSAttributedString.Key.paragraphStyle: style, NSAttributedString.Key.font: boldFont]

            let attributedString = NSAttributedString(string: buttonTitle, attributes: attributes)
            calendarButton.attributedTitle = attributedString
            calendarButton.toolTip = attributedString.string
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of _: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == CLDisplayFutureSliderKey, let changes = change, let new = changes[NSKeyValueChangeKey.newKey] as? NSNumber {
            futureSliderView.isHidden = new.isEqual(to: NSNumber(value: 1))
        } else if keyPath == CLUserFontSizePreference, let userFontSize = DataStore.shared().retrieve(key: CLUserFontSizePreference) as? NSNumber {
            Logger.log(object: ["FontSize": userFontSize], for: "User Font Size Preference")
            mainTableView.reloadData()
            setScrollViewConstraint()
        } else if keyPath == CLThemeKey {
            updateReviewViewFontColor()
        } else if keyPath == CLFutureSliderRange {
            adjustFutureSliderBasedOnPreferences()
        } else {
            super.observeValue(forKeyPath: keyPath,
                               of: keyPath,
                               change: change,
                               context: context)
        }
    }

    func screenHeight() -> CGFloat {
        guard let main = NSScreen.main else { return 100 }

        let mouseLocation = NSEvent.mouseLocation

        var current = main.frame.height

        let activeScreens = NSScreen.screens.filter { (current) -> Bool in
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

    func setScrollViewConstraint() {
        var totalHeight: CGFloat = 0.0
        let preferences = defaultPreferences

        for cellIndex in 0 ..< preferences.count {
            let currentObject = TimezoneData.customObject(from: preferences[cellIndex])
            let rowRect = mainTableView.rect(ofRow: cellIndex)
            var height: CGFloat = rowRect.size.height

            if height <= 68.0 {
                height = 69.0
            }

            if height >= 68.0 {
                height = 75.0
                if let note = currentObject?.note, note.count > 0 {
                    height += 30
                }
            }

            if height >= 88.0 {
                // Set it to 95 expicity in case the row height is calculated be higher.
                height = 95.0

                if let note = currentObject?.note, note.count <= 0 {
                    height -= 30.0
                }
            }

            height += mainTableView.intercellSpacing.height

            totalHeight += height
        }

        // This is for the Add Cell View case
        if preferences.count == 0 {
            scrollViewHeight.constant = 100.0
            return
        }

        if let userFontSize = DataStore.shared().retrieve(key: CLUserFontSizePreference) as? NSNumber {
            scrollViewHeight.constant = totalHeight + CGFloat(userFontSize.intValue * 3) + 5.0
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
    }

    @objc func updateDefaultPreferences() {
        updatePanelColor()

        let defaults = DataStore.shared().timezones()
        let convertedTimezones = defaults.map { (data) -> TimezoneData in
            TimezoneData.customObject(from: data)!
        }

        datasource = TimezoneDataSource(items: convertedTimezones)
        mainTableView.dataSource = datasource
        mainTableView.delegate = datasource
        mainTableView.panelDelegate = datasource

        updateDatasource(with: convertedTimezones)
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
                                                 to: Date()) else {
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
        openPreferences()
    }

    func deleteTimezone(at row: Int) {
        var defaults = defaultPreferences

        // Remove object from menubar favourites if present
        if let dataObject = TimezoneData.customObject(from: defaults[row]) {
            removeFromMenubarFavourites(timezone: dataObject)
        }

        // Remove from panel
        defaults.remove(at: row)
        DataStore.shared().setTimezones(defaults)
        updateDefaultPreferences()

        if defaults.isEmpty {
            UserDefaults.standard.set([], forKey: CLMenubarFavorites)
        }

        NotificationCenter.default.post(name: Notification.Name.customLabelChanged,
                                        object: nil)

        // Now log!
        Logger.log(object: [:], for: "Deleted Timezone Through Swipe")
    }

    private func removeFromMenubarFavourites(timezone: TimezoneData) {
        if timezone.isFavourite == 1, let menubarTitles = DataStore.shared().retrieve(key: CLMenubarFavorites) as? [Data] {
            let filtered = menubarTitles.filter {
                let dataObject = TimezoneData.customObject(from: $0)

                // Special check for home indicator objects!
                if timezone.isSystemTimezone, let isSystem = dataObject?.isSystemTimezone, isSystem {
                    return false
                }

                return dataObject?.placeID != timezone.placeID
            }

            UserDefaults.standard.set(filtered, forKey: CLMenubarFavorites)

            // Update the status bar's appearance if it is in custom mode.
            if let delegate = NSApplication.shared.delegate as? AppDelegate {
                let statusItemPanel = delegate.statusItemForPanel()
                statusItemPanel.setupStatusItem()
            }
        }
    }

    private lazy var menubarTitleHandler = MenubarHandler()

    @objc func updateTime() {
        let store = DataStore.shared()

        let menubarCount = (store.retrieve(key: CLMenubarFavorites) as? [Data])?.count ?? 0

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

        stride(from: 0, to: preferences.count, by: 1).forEach {
            let current = preferences[$0]

            if $0 < mainTableView.numberOfRows, let cellView = mainTableView.view(atColumn: 0, row: $0, makeIfNecessary: false) as? TimezoneCellView, let model = TimezoneData.customObject(from: current) {
                if let futureSliderCell = futureSlider.cell as? CustomSliderCell, futureSliderCell.tracking == true {
                    return
                }

                let dataOperation = TimezoneDataOperations(with: model)
                cellView.time.stringValue = dataOperation.time(with: futureSliderValue)
                cellView.sunriseSetTime.stringValue = dataOperation.formattedSunriseTime(with: futureSliderValue)
                cellView.sunriseSetTime.lineBreakMode = .byClipping
                cellView.relativeDate.stringValue = dataOperation.date(with: futureSliderValue, displayType: .panelDisplay)
                cellView.currentLocationIndicator.isHidden = !model.isSystemTimezone
                cellView.sunriseImage.image = model.isSunriseOrSunset ? Themer.shared().sunriseImage() : Themer.shared().sunsetImage()
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

        guard let popover = morePopover else {
            assertionFailure("Data was unexpectedly nil")
            return false
        }

        var correctRow = row

        target.image = Themer.shared().extraOptionsHighlightedImage()

        popover.animates = true

        if note == nil {
            note = NotesPopover(nibName: NSNib.Name.notesPopover, bundle: nil)
            popover.behavior = .applicationDefined
            popover.delegate = self
        }

        // Found a case where row number was 8 but we had only 2 timezones
        if correctRow >= defaults.count {
            correctRow = defaults.count - 1
        }

        let current = defaults[correctRow]

        if let model = TimezoneData.customObject(from: current) {
            note?.setDataSource(data: model)
            note?.setRow(row: correctRow)
            note?.set(timezones: defaults)

            popover.contentViewController = note
            note?.set(with: popover)
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

    private func openPreferences() {
        oneWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @IBAction func dismissNextEventLabel(_: NSButton) {
        removeUpcomingEventView()
    }

    func removeUpcomingEventView() {
        OperationQueue.main.addOperation {
            if self.stackView.arrangedSubviews.contains(self.upcomingEventView!), self.upcomingEventView?.isHidden == false {
                self.upcomingEventView?.isHidden = true
                UserDefaults.standard.set("NO", forKey: CLShowUpcomingEventView)
                Logger.log(object: ["Removed": "YES"], for: "Removed Upcoming Event View")
            }
        }
    }

    @IBAction func calendarButtonAction(_: NSButton) {
        if calendarButton.title == "Click here to start." {
            showPermissionsWindow()
        } else {
            retrieveCalendarEvents()
        }
    }

    private func showPermissionsWindow() {
        oneWindow.openPermissions()
        NSApp.activate(ignoringOtherApps: true)
    }

    func retrieveCalendarEvents() {
        let eventCenter = EventCenter.sharedCenter()

        if eventCenter.calendarAccessGranted() {
            fetchCalendarEvents()
        } else if eventCenter.calendarAccessNotDetermined() {
            /* Wait till we get the thumbs up. */
            return
        } else {
            removeUpcomingEventView()
        }
    }

    @IBAction func shareAction(_ sender: NSButton) {
        let promotionText = "Keep track of your friends and colleagues in different timezones using Clocker: appstore.com/mac/clockermenubarworldclock"

        guard let url = URL(string: "https://goo.gl/xyLA4j") else {
            assertionFailure("Data was unexpectedly nil")
            return
        }

        let servicePicker = NSSharingServicePicker(items: [promotionText, url])
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
            sharedDelegate.setupFloatingWindow()
        } else {
            sharedDelegate.closeFloatingWindow()
            sharedDelegate.setPanelDefaults()
        }

        let mode = inverseSelection.isEqual(to: NSNumber(value: 1)) ? "Floating Mode" : "Menubar Mode"

        Logger.log(object: ["displayMode": mode], for: "Clocker Mode")
    }

    func showUpcomingEventView() {
        OperationQueue.main.addOperation {
            if let upcomingView = self.upcomingEventView, upcomingView.isHidden {
                self.upcomingEventView?.isHidden = false
                UserDefaults.standard.set("YES", forKey: CLShowUpcomingEventView)
                Logger.log(object: ["Shown": "YES"], for: "Added Upcoming Event View")
                self.themeChanged()
            }
        }
    }

    private func fetchCalendarEvents() {
        let eventCenter = EventCenter.sharedCenter()
        let now = Date()

        if let events = eventCenter.eventsForDate[NSCalendar.autoupdatingCurrent.startOfDay(for: now)], events.count > 0 {
            OperationQueue.main.addOperation {
                guard let upcomingEvent = eventCenter.nextOccuring(events) else {
                    self.setPlaceholdersForUpcomingCalendarView()
                    return
                }

                self.calendarColorView.layer?.backgroundColor = upcomingEvent.calendar.color.cgColor
                self.nextEventLabel.stringValue = upcomingEvent.title
                self.nextEventLabel.toolTip = upcomingEvent.title
                if upcomingEvent.isAllDay == true {
                    let title = events.count == 1 ? "All-Day" : "All Day - Total \(events.count) events today"
                    self.setCalendarButtonTitle(buttonTitle: title)
                    return
                }

                let timeSince = Date().timeAgo(since: upcomingEvent.startDate)
                let withoutAn = timeSince.replacingOccurrences(of: "an", with: CLEmptyString)
                let withoutAgo = withoutAn.replacingOccurrences(of: "ago", with: CLEmptyString)

                self.setCalendarButtonTitle(buttonTitle: "in \(withoutAgo.lowercased())")
            }
        } else {
            setPlaceholdersForUpcomingCalendarView()
        }
    }

    private func setPlaceholdersForUpcomingCalendarView() {
        let eventCenter = EventCenter.sharedCenter()

        var tomorrow = DateComponents()
        tomorrow.day = 1
        guard let tomorrowDate = Calendar.autoupdatingCurrent.date(byAdding: tomorrow, to: Date()) else {
            setCalendarButtonTitle(buttonTitle: "You have no events scheduled for tomorrow.")
            return
        }

        nextEventLabel.stringValue = "No upcoming event."
        calendarColorView.layer?.backgroundColor = NSColor(red: 97 / 255.0, green: 194 / 255.0, blue: 80 / 255.0, alpha: 1.0).cgColor

        let events = eventCenter.filteredEvents[NSCalendar.autoupdatingCurrent.startOfDay(for: tomorrowDate)]

        if let count = events?.count, count > 1 {
            let suffix = "events coming up tomorrow."
            setCalendarButtonTitle(buttonTitle: "\(count) \(suffix)")
        } else if let first = events?.first?.event.title {
            setCalendarButtonTitle(buttonTitle: "\(first) coming up.")
        } else {
            setCalendarButtonTitle(buttonTitle: "You have no events scheduled for tomorrow.")
        }
    }

    // If the popover is displayed, close it
    // Called when preferences are going to be displayed!
    func updatePopoverDisplayState() {
        if note != nil, let isShown = note?.popover?.isShown, isShown {
            note?.popover?.close()
        }
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
            RateController.prompted()

            if let countryCode = Locale.autoupdatingCurrent.regionCode {
                Logger.log(object: ["CurrentCountry": countryCode], for: "Remind Later for Feedback")
            }
        }
    }

    @IBAction func actionOnPositiveFeedback(_ sender: NSButton) {
        if sender.title == PanelConstants.yesWithExclamation {
            setAnimated(title: "Mind rating us?",
                        field: leftField,
                        leftTitle: PanelConstants.noThanksTitle,
                        rightTitle: "Yes")
        } else if sender.title == PanelConstants.yesWithQuestionMark {
            RateController.prompted()
            updateReviewView()

            feedbackWindow = AppFeedbackWindowController.shared()
            feedbackWindow.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            updateReviewView()
            RateController.prompt()

            if let countryCode = Locale.autoupdatingCurrent.regionCode {
                Logger.log(object: ["CurrentCountry": countryCode], for: "Remind Later for Feedback")
            }
        }
    }

    private func updateReviewView() {
        reviewView.isHidden = true
        showReviewCell = false
        leftField.stringValue = "Enjoy using Clocker?"

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let styleAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: NSFont(name: "Avenir-Light", size: 13)!
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
        }) {
            field.stringValue = title

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 1
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
                self.leftButton.animator().alphaValue = 1.0
                self.rightButton.animator().alphaValue = 1.0

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center

                let styleAttributes = [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: NSFont(name: "Avenir-Light", size: 13)!
                ]

                if self.leftButton.attributedTitle.string == "Not Really" {
                    self.leftButton.animator().attributedTitle = NSAttributedString(string: PanelConstants.noThanksTitle, attributes: styleAttributes)
                }

                if self.rightButton.attributedTitle.string == PanelConstants.yesWithExclamation {
                    self.rightButton.animator().attributedTitle = NSAttributedString(string: "Yes, sure", attributes: styleAttributes)
                }

                self.leftButton.animator().attributedTitle = NSAttributedString(string: leftTitle, attributes: styleAttributes)
                self.rightButton.animator().attributedTitle = NSAttributedString(string: rightTitle, attributes: styleAttributes)

            }) {}
        }
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
}

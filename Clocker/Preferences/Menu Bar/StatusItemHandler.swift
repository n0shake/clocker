// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit

private enum MenubarState {
    case compactText
    case standardText
    case icon
}

class StatusItemHandler: NSObject {
    var hasActiveIcon: Bool = false

    var menubarTimer: Timer?

    var statusItem: NSStatusItem = {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.toolTip = "Clocker"
        (statusItem.button?.cell as? NSButtonCell)?.highlightsBy = NSCell.StyleMask(rawValue: 0)
        return statusItem
    }()

    private lazy var menubarTitleHandler = MenubarTitleProvider(with: self.store, eventStore: EventCenter.sharedCenter())

    private var statusContainerView: StatusContainerView?

    private var nsCalendar = Calendar.autoupdatingCurrent

    private lazy var units: Set<Calendar.Component> = Set([.era, .year, .month, .day, .hour, .minute])

    private var userNotificationsDidChangeNotif: NSObjectProtocol?

    private let store: DataStore

    // Current State might be set twice when the user first launches an app.
    // First, when StatusItemHandler() is instantiated in AppDelegate
    // Second, when AppDelegate.fetchLocalTimezone() is called triggering a customLabel didSet.
    // TODO: Make sure it's set just once.
    private var currentState: MenubarState = .standardText {
        didSet {
            // Do some cleanup
            switch oldValue {
            case .compactText:
                statusItem.button?.subviews = []
                statusContainerView = nil
            case .standardText:
                statusItem.button?.title = UserDefaultKeys.emptyString
            case .icon:
                statusItem.button?.image = nil
            }

            // Now setup for the new menubar state
            switch currentState {
            case .compactText:
                setupForCompactTextMode()
            case .standardText:
                setupForStandardTextMode()
            case .icon:
                setClockerIcon()
            }

            Logger.info("Status Bar Current State changed: \(currentState)\n")
        }
    }

    init(with dataStore: DataStore) {
        store = dataStore
        super.init()

        setupStatusItem()
        setupNotificationObservers()
    }

    func setupStatusItem() {
        // Let's figure out the initial menubar state
        var menubarState = MenubarState.icon

        let shouldTextBeDisplayed = store.menubarTimezones()?.isEmpty ?? true

        if !shouldTextBeDisplayed || store.shouldDisplay(.showMeetingInMenubar) {
            if store.shouldDisplay(.menubarCompactMode) {
                menubarState = .compactText
            } else {
                menubarState = .standardText
            }
        }

        // Initial state has been figured out. Time to set it!
        currentState = menubarState

        func setSelector() {
            if #available(macOS 10.14, *) {
                statusItem.button?.action = #selector(menubarIconClicked(_:))
            } else {
                statusItem.action = #selector(menubarIconClicked(_:))
            }
        }

        statusItem.button?.target = self
        statusItem.autosaveName = NSStatusItem.AutosaveName("ClockerStatusItem")
        setSelector()
    }

    private func setupNotificationObservers() {
        let center = NotificationCenter.default
        let mainQueue = OperationQueue.main

        center.addObserver(self,
                           selector: #selector(updateMenubar),
                           name: NSWorkspace.didWakeNotification,
                           object: nil)

        DistributedNotificationCenter.default.addObserver(self, selector: #selector(respondToInterfaceStyleChange),
                                                          name: .interfaceStyleDidChange,
                                                          object: nil)

        userNotificationsDidChangeNotif = center.addObserver(forName: UserDefaults.didChangeNotification,
                                                             object: self,
                                                             queue: mainQueue)
        { _ in
            self.setupStatusItem()
        }

        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: OperationQueue.main) { _ in
            self.menubarTimer?.invalidate()
        }

        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: OperationQueue.main) { _ in
            self.setupStatusItem()
        }
    }

    deinit {
        if let userNotifsDidChange = userNotificationsDidChangeNotif {
            NotificationCenter.default.removeObserver(userNotifsDidChange)
        }
    }

    private func constructCompactView(with upcomingEventView: Bool = false) {
        statusItem.button?.subviews = []
        statusContainerView = nil

        let menubarTimezones = store.menubarTimezones() ?? []
        if menubarTimezones.isEmpty {
            currentState = .icon
            return
        }

        statusContainerView = StatusContainerView(with: menubarTimezones,
                                                  store: store,
                                                  showUpcomingEventView: upcomingEventView,
                                                  bufferContainerWidth: bufferCalculatedWidth())
        statusContainerView?.wantsLayer = true
        statusItem.button?.addSubview(statusContainerView!)
        statusItem.button?.frame = statusContainerView!.bounds

        // For OS < 11, we need to fix the sizing (width) on the button's window
        // Otherwise, we won't be able to see the menu bar option at all.
        if let window = statusItem.button?.window {
            let currentFrame = window.frame
            let newFrame = NSRect(x: currentFrame.origin.x,
                                  y: currentFrame.origin.y,
                                  width: statusItem.button?.bounds.size.width ?? 0,
                                  height: currentFrame.size.height)
            window.setFrame(newFrame, display: true)
        }
        statusItem.button?.subviews.first?.window?.backgroundColor = NSColor.clear
    }

    // This is called when the Apple interface style pre-Mojave is changed.
    // In High Sierra and before, we could have a dark or light menubar and dock
    // Our icon is template, so it changes automatically; so is our standard status bar text
    // Only need to handle the compact mode!
    @objc func respondToInterfaceStyleChange() {
        if store.shouldDisplay(.menubarCompactMode) {
            updateCompactMenubar()
        }
    }

    @objc func setHasActiveIcon(_ value: Bool) {
        hasActiveIcon = value
    }

    @objc func menubarIconClicked(_ sender: NSStatusBarButton) {
        guard let mainDelegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }

        mainDelegate.togglePanel(sender)
    }

    @objc func updateMenubar() {
        guard let fireDate = calculateFireDate() else { return }

        let shouldDisplaySeconds = shouldDisplaySecondsInMenubar()

        menubarTimer = Timer(fire: fireDate,
                             interval: 0,
                             repeats: false,
                             block: { [weak self] _ in

                                 if let strongSelf = self {
                                     strongSelf.refresh()
                                 }
                             })

        // Tolerance, even a small amount, has a positive imapct on the power usage. As a rule, we set it to 10% of the interval
        menubarTimer?.tolerance = shouldDisplaySeconds ? 0.5 : 20

        guard let runLoopTimer = menubarTimer else {
            Logger.info("Timer is unexpectedly nil")
            return
        }

        RunLoop.main.add(runLoopTimer, forMode: .common)
    }

    private func shouldDisplaySecondsInMenubar() -> Bool {
        let syncedTimezones = store.menubarTimezones() ?? []

        let timezonesSupportingSeconds = syncedTimezones.filter { data in
            if let timezoneObj = TimezoneData.customObject(from: data) {
                return timezoneObj.shouldShowSeconds(store.timezoneFormat())
            }
            return false
        }

        return timezonesSupportingSeconds.isEmpty == false
    }

    private func calculateFireDate() -> Date? {
        let shouldDisplaySeconds = shouldDisplaySecondsInMenubar()
        let menubarFavourites = store.menubarTimezones()

        if !units.contains(.second), shouldDisplaySeconds {
            units.insert(.second)
        }

        var components = nsCalendar.dateComponents(units, from: Date())

        // We want to update every second only when there's a timezone present!
        if shouldDisplaySeconds, let seconds = components.second, let favourites = menubarFavourites, !favourites.isEmpty {
            components.second = seconds + 1
        } else if let minutes = components.minute {
            components.minute = minutes + 1
        } else {
            Logger.info("Unable to create date components for the menubar timewr")
            return nil
        }

        guard let fireDate = nsCalendar.date(from: components) else {
            Logger.info("Unable to form Fire Date")
            return nil
        }

        return fireDate
    }

    func updateCompactMenubar() {
        let filteredEvents = EventCenter.sharedCenter().filteredEvents
        let calendar = EventCenter.sharedCenter().autoupdatingCalendar
        let upcomingEvent = menubarTitleHandler.checkForUpcomingEvents(filteredEvents, calendar: calendar)
        if upcomingEvent != nil {
            // Iterate and see if we're showing the calendar item view
            let upcomingEventView = retrieveUpcomingEventStatusView()
            // If not, reconstruct Status Container View with another view
            if upcomingEventView == nil {
                constructCompactView(with: true)
            }
        }

        if let upcomingEventView = retrieveUpcomingEventStatusView(), upcomingEvent == nil {
            upcomingEventView.removeFromSuperview()
            constructCompactView() // So that Status Container View reclaims the space
        }
        // This will internally call `statusItemViewSetNeedsDisplay` on all subviews ensuring all text in the menubar is up-to-date.
        statusContainerView?.updateTime()
    }

    private func removeUpcomingStatusItemView() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            let upcomingEventView = retrieveUpcomingEventStatusView()
            upcomingEventView?.removeFromSuperview()
        }) { [weak self] in
            if let sSelf = self {
                sSelf.constructCompactView()
            }
        }
    }

    func refresh() {
        if currentState == .compactText {
            updateCompactMenubar()
            updateMenubar()
        } else if currentState == .standardText, let title = menubarTitleHandler.titleForMenubar() {
            // Need setting button's image to nil
            // Especially if we have showUpcomingEvents turned to true and menubar timezones are empty
            statusItem.button?.image = nil
            let attributes = [NSAttributedString.Key.font: NSFont.monospacedDigitSystemFont(ofSize: 13.0, weight: NSFont.Weight.regular),
                              NSAttributedString.Key.baselineOffset: 0.1] as [NSAttributedString.Key: Any]
            statusItem.button?.attributedTitle = NSAttributedString(string: title, attributes: attributes)
            updateMenubar()
        } else {
            setClockerIcon()
            menubarTimer?.invalidate()
        }
    }

    private func setupForStandardTextMode() {
        Logger.info("Initializing menubar timer")

        // Let's invalidate the previous timer
        menubarTimer?.invalidate()
        menubarTimer = nil

        setupForStandardText()
        updateMenubar()
    }

    func invalidateTimer(showIcon show: Bool, isSyncing sync: Bool) {
        // Check if user is not showing
        // 1. Timezones
        // 2. Upcoming Event
        let menubarFavourites = store.menubarTimezones() ?? []

        if menubarFavourites.isEmpty, store.shouldDisplay(.showMeetingInMenubar) == false {
            Logger.info("Invalidating menubar timer!")

            invalidation()

            if show {
                currentState = .icon
            }

        } else if sync {
            Logger.info("Invalidating menubar timer for sync purposes!")

            invalidation()

            if show {
                setClockerIcon()
            }

        } else {
            Logger.info("Not stopping menubar timer!")
        }
    }

    private func invalidation() {
        menubarTimer?.invalidate()
    }

    private func setClockerIcon() {
        if statusItem.button?.subviews.isEmpty == false {
            statusItem.button?.subviews = []
        }

        if statusItem.button?.image?.name() == NSImage.Name.menubarIcon {
            return
        }

        statusItem.button?.title = UserDefaultKeys.emptyString
        statusItem.button?.image = NSImage(named: .menubarIcon)
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.toolTip = "Clocker"
    }

    private func setupForStandardText() {
        var menubarText = UserDefaultKeys.emptyString

        if let menubarTitle = menubarTitleHandler.titleForMenubar() {
            menubarText = menubarTitle
        } else if store.shouldDisplay(.showMeetingInMenubar) {
            // Don't have any meeting to show
        } else {
            // We have no favourites to display and no meetings to show.
            // That means we should display our icon!
        }

        guard !menubarText.isEmpty else {
            setClockerIcon()
            return
        }

        let attributes = [NSAttributedString.Key.font: NSFont.monospacedDigitSystemFont(ofSize: 13.0, weight: NSFont.Weight.regular),
                          NSAttributedString.Key.baselineOffset: 0.1] as [NSAttributedString.Key: Any]
        statusItem.button?.attributedTitle = NSAttributedString(string: menubarText, attributes: attributes)
        statusItem.button?.image = nil
        statusItem.button?.imagePosition = .imageLeft
    }

    private func setupForCompactTextMode() {
        // Let's invalidate the previous timer
        menubarTimer?.invalidate()
        menubarTimer = nil

        let filteredEvents = EventCenter.sharedCenter().filteredEvents
        let calendar = EventCenter.sharedCenter().autoupdatingCalendar
        let checkForUpcomingEvents = menubarTitleHandler.checkForUpcomingEvents(filteredEvents, calendar: calendar)
        constructCompactView(with: checkForUpcomingEvents != nil)
        updateMenubar()
    }

    private func retrieveUpcomingEventStatusView() -> NSView? {
        let upcomingEventView = statusContainerView?.subviews.first(where: { statusItemView in
            if let upcomingEventView = statusItemView as? StatusItemViewConforming {
                return upcomingEventView.statusItemViewIdentifier() == "upcoming_event_view"
            }
            return false
        })
        return upcomingEventView
    }

    private func bufferCalculatedWidth() -> Int {
        var totalWidth = 55

        if store.shouldShowDayInMenubar() {
            totalWidth += 12
        }

        if store.isBufferRequiredForTwelveHourFormats() {
            totalWidth += 20
        }

        if store.shouldShowDateInMenubar() {
            totalWidth += 20
        }

        if store.shouldDisplay(.showMeetingInMenubar) {
            totalWidth += 100
        }

        return totalWidth
    }
}

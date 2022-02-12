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
        statusItem.toolTip = "Clocker"
        statusItem.highlightMode = false
        return statusItem
    }()

    private var menubarTitleHandler = MenubarHandler()

    private var parentView: StatusContainerView?

    private var nsCalendar = Calendar.autoupdatingCurrent

    private lazy var units: Set<Calendar.Component> = Set([.era, .year, .month, .day, .hour, .minute])

    private var userNotificationsDidChangeNotif: NSObjectProtocol?

    // Current State might be set twice when the user first launches an app.
    // First, when StatusItemHandler() is instantiated in AppDelegate
    // Second, when AppDelegate.fetchLocalTimezone() is called triggering a customLabel didSet.
    // TODO: Make sure it's set just once.
    private var currentState: MenubarState = .standardText {
        didSet {
            // Do some cleanup
            switch oldValue {
            case .compactText:
                statusItem.view = nil
                parentView = nil
            case .standardText:
                statusItem.button?.title = CLEmptyString
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

            Logger.info("\nStatus Bar Current State changed: \(currentState)\n")
        }
    }

    override init() {
        super.init()

        setupStatusItem()
        setupNotificationObservers()
    }

    func setupStatusItem() {
        // Let's figure out the initial menubar state
        var menubarState = MenubarState.icon

        let shouldTextBeDisplayed = DataStore.shared().menubarTimezones()?.isEmpty ?? true

        if !shouldTextBeDisplayed || DataStore.shared().shouldDisplay(.showMeetingInMenubar) {
            if DataStore.shared().shouldDisplay(.menubarCompactMode) {
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

        statusItem.target = self
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
                                                             queue: mainQueue) { _ in
            self.setupStatusItem()
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: OperationQueue.main) { notification in
            self.menubarTimer?.invalidate()
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: OperationQueue.main) { notification in
            self.setupStatusItem()
        }
    }

    deinit {
        if let userNotifsDidChange = userNotificationsDidChangeNotif {
            NotificationCenter.default.removeObserver(userNotifsDidChange)
        }
    }

    private func constructCompactView() {
        parentView = nil

        let menubarTimezones = retrieveSyncedMenubarTimezones()

        if menubarTimezones.isEmpty {
            currentState = .icon
            return
        }

        parentView = StatusContainerView(with: menubarTimezones)
        statusItem.view = parentView
        statusItem.view?.window?.backgroundColor = NSColor.clear
    }

    private func retrieveSyncedMenubarTimezones() -> [Data] {
        let defaultPreferences = DataStore.shared().retrieve(key: CLDefaultPreferenceKey) as? [Data] ?? []

        let menubarTimezones = defaultPreferences.filter { data -> Bool in
            if let timezoneObj = TimezoneData.customObject(from: data) {
                return timezoneObj.isFavourite == 1
            }
            return false
        }
        return menubarTimezones
    }

    // This is called when the Apple interface style pre-Mojave is changed.
    // In High Sierra and before, we could have a dark or light menubar and dock
    // Our icon is template, so it changes automatically; so is our standard status bar text
    // Only need to handle the compact mode!
    @objc func respondToInterfaceStyleChange() {
        if DataStore.shared().shouldDisplay(.menubarCompactMode) {
            updateCompactMenubar()
        }
    }

    @objc func setHasActiveIcon(_ value: Bool) {
        hasActiveIcon = value
    }

    @objc func menubarIconClicked(_ sender: Any) {
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
        let syncedTimezones = retrieveSyncedMenubarTimezones()

        for timezone in syncedTimezones {
            if let timezoneObj = TimezoneData.customObject(from: timezone) {
                let shouldShowSeconds = timezoneObj.shouldShowSeconds(DataStore.shared().timezoneFormat())
                if shouldShowSeconds {
                    return true
                }
            }
            continue
        }

        return false
    }

    private func calculateFireDate() -> Date? {
        let shouldDisplaySeconds = shouldDisplaySecondsInMenubar()
        let menubarFavourites = DataStore.shared().menubarTimezones()

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
        parentView?.updateTime()
    }

    func refresh() {
        if currentState == .compactText {
            updateCompactMenubar()
            updateMenubar()
        } else if currentState == .standardText, let title = menubarTitleHandler.titleForMenubar() {
            // Need setting button's image to nil
            // Especially if we have showUpcomingEvents turned to true and menubar timezones are empty
            statusItem.button?.image = nil
            statusItem.button?.title = title
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
        let menubarFavourites = DataStore.shared().menubarTimezones() ?? []

        if menubarFavourites.isEmpty, DataStore.shared().shouldDisplay(.showMeetingInMenubar) == false {
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
        if statusItem.view != nil {
            statusItem.view = nil
        }

        if statusItem.button?.image?.name() == NSImage.Name.menubarIcon {
            return
        }

        statusItem.button?.title = CLEmptyString
        statusItem.button?.image = NSImage(named: .menubarIcon)
        statusItem.button?.imagePosition = .imageOnly
        statusItem.toolTip = "Clocker"
    }

    private func setupForStandardText() {
        var menubarText = CLEmptyString

        if let menubarTitle = menubarTitleHandler.titleForMenubar() {
            menubarText = menubarTitle
        } else if DataStore.shared().shouldDisplay(.showMeetingInMenubar) {
            // Don't have any meeting to show
        } else {
            // We have no favourites to display and no meetings to show.
            // That means we should display our icon!
        }

        guard !menubarText.isEmpty else {
            setClockerIcon()
            return
        }

        statusItem.button?.title = menubarText
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 14.0, weight: NSFont.Weight.regular)
        statusItem.button?.image = nil
        statusItem.button?.imagePosition = .imageLeft
    }

    private func setupForCompactTextMode() {
        // Let's invalidate the previous timer
        menubarTimer?.invalidate()
        menubarTimer = nil

        constructCompactView()
        updateMenubar()
    }
}

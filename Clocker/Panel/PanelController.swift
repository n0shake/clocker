// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit

class PanelController: ParentPanelController {
    @objc dynamic var hasActivePanel: Bool = false
    
    @IBOutlet var backgroundView: BackgroundPanelView!
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        enablePerformanceLoggingIfNeccessary()
        
        window?.title = "Clocker Panel"
        window?.setAccessibilityIdentifier("Clocker Panel")
        // Otherwise, the panel can be dragged around while we try to scroll through the modern slider
        window?.isMovableByWindowBackground = false
        
        if let panel = window {
            panel.acceptsMouseMovedEvents = true
            panel.level = .popUpMenu
            panel.isOpaque = false
            panel.backgroundColor = NSColor.clear
        }
        
        mainTableView.registerForDraggedTypes([.dragSession])
        
        super.updatePanelColor()
        
        super.updateDefaultPreferences()
    }
    
    private func enablePerformanceLoggingIfNeccessary() {
        if !ProcessInfo.processInfo.environment.keys.contains("ENABLE_PERF_LOGGING") {
            PerfLogger.disable()
        }
    }
    
    func setFrameTheNewWay(_ rect: NSRect, _ maxX: CGFloat) {
        // Calculate window's top left point.
        // First, center window under status item.
        let width = (window?.frame)!.width
        var xPoint = CGFloat(roundf(Float(rect.midX - width / 2)))
        let yPoint = CGFloat(rect.minY - 2)
        let kMinimumSpaceBetweenWindowAndScreenEdge: CGFloat = 10
        
        if xPoint + width + kMinimumSpaceBetweenWindowAndScreenEdge > maxX {
            xPoint = maxX - width - kMinimumSpaceBetweenWindowAndScreenEdge
        }
        
        window?.setFrameTopLeftPoint(NSPoint(x: xPoint, y: yPoint))
        window?.invalidateShadow()
    }
    
    func open() {
        PerfLogger.startMarker("Open")
        
        guard isWindowLoaded == true else {
            return
        }
        
        super.dismissRowActions()
        
        updateDefaultPreferences()
        
        setupUpcomingEventViewCollectionViewIfNeccesary()
        
        if DataStore.shared().timezones().isEmpty || DataStore.shared().shouldDisplay(.futureSlider) == false {
            modernContainerView.isHidden = true
        } else if let value = DataStore.shared().retrieve(key: UserDefaultKeys.displayFutureSliderKey) as? NSNumber, modernContainerView != nil {
            if value.intValue == 1 {
                modernContainerView.isHidden = true
            } else if value.intValue == 0 {
                modernContainerView.isHidden = false
            }
        }
        
        // Reset future slider value to zero
        closestQuarterTimeRepresentation = findClosestQuarterTimeApproximation()
        modernSliderLabel.stringValue = "Time Scroller"
        resetModernSliderButton.isHidden = true
        
        if modernSlider != nil {
            let indexPaths: Set<IndexPath> = Set([IndexPath(item: modernSlider.numberOfItems(inSection: 0) / 2, section: 0)])
            modernSlider.scrollToItems(at: indexPaths, scrollPosition: .centeredHorizontally)
        }
        
        goForwardButton.alphaValue = 0
        goBackwardsButton.alphaValue = 0
        
        setTimezoneDatasourceSlider(sliderValue: 0)
        
        reviewView.isHidden = !ReviewController.canPrompt()
        
        reviewView.layer?.backgroundColor = NSColor.clear.cgColor
        
        setPanelFrame()
        
        startWindowTimer()
        
        if DataStore.shared().shouldDisplay(ViewType.upcomingEventView) {
            retrieveCalendarEvents()
        } else {
            removeUpcomingEventView()
            super.setScrollViewConstraint()
        }
        
        // This is done to make the UI look updated.
        mainTableView.reloadData()
        
        log()
        
        PerfLogger.endMarker("Open")
    }
    
    // New way to set the panel's frame.
    // This takes into account the screen's dimensions.
    private func setPanelFrame() {
        PerfLogger.startMarker("Set Panel Frame")
        
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        var statusBackgroundWindow = appDelegate.statusItemForPanel().statusItem.button?.window
        var statusView = appDelegate.statusItemForPanel().statusItem.button
        
        // This below is a better way than actually checking if the menubar compact mode is set.
        if statusBackgroundWindow == nil || statusView == nil {
            statusBackgroundWindow = appDelegate.statusItemForPanel().statusItem.button?.window
            statusView = appDelegate.statusItemForPanel().statusItem.button
        }
        
        if let statusWindow = statusBackgroundWindow,
           let statusButton = statusView
        {
            var statusItemFrame = statusWindow.convertToScreen(statusButton.frame)
            var statusItemScreen = NSScreen.main
            var testPoint = statusItemFrame.origin
            testPoint.y -= 100
            
            for screen in NSScreen.screens where screen.frame.contains(testPoint) {
                statusItemScreen = screen
                break
            }
            
            let screenMaxX = (statusItemScreen?.frame)!.maxX
            let minY = statusItemFrame.origin.y < (statusItemScreen?.frame)!.maxY ?
            statusItemFrame.origin.y :
            (statusItemScreen?.frame)!.maxY
            statusItemFrame.origin.y = minY
            
            setFrameTheNewWay(statusItemFrame, screenMaxX)
            PerfLogger.endMarker("Set Panel Frame")
        }
    }
    
    private func log() {
        PerfLogger.startMarker("Logging")
        
        let preferences = DataStore.shared().timezones()
        
        guard let theme = DataStore.shared().retrieve(key: UserDefaultKeys.themeKey) as? NSNumber,
              let displayFutureSliderKey = DataStore.shared().retrieve(key: UserDefaultKeys.themeKey) as? NSNumber,
              let showAppInForeground = DataStore.shared().retrieve(key: UserDefaultKeys.showAppInForeground) as? NSNumber,
              let relativeDateKey = DataStore.shared().retrieve(key: UserDefaultKeys.relativeDateKey) as? NSNumber,
              let fontSize = DataStore.shared().retrieve(key: UserDefaultKeys.userFontSizePreference) as? NSNumber,
              let sunriseTime = DataStore.shared().retrieve(key: UserDefaultKeys.sunriseSunsetTime) as? NSNumber,
              let showDayInMenu = DataStore.shared().retrieve(key: UserDefaultKeys.showDayInMenu) as? NSNumber,
              let showDateInMenu = DataStore.shared().retrieve(key: UserDefaultKeys.showDateInMenu) as? NSNumber,
              let showPlaceInMenu = DataStore.shared().retrieve(key: UserDefaultKeys.showPlaceInMenu) as? NSNumber,
              let showUpcomingEventView = DataStore.shared().retrieve(key: UserDefaultKeys.showUpcomingEventView) as? String,
              let country = Locale.autoupdatingCurrent.region?.identifier
        else {
            return
        }
        
        var relativeDate = "Relative"
        
        if relativeDateKey.isEqual(to: NSNumber(value: 1)) {
            relativeDate = "Actual Day"
        } else if relativeDateKey.isEqual(to: NSNumber(value: 2)) {
            relativeDate = "Date"
        }
        
        let panelEvent: [String: Any] = [
            "Theme": theme.isEqual(to: NSNumber(value: 0)) ? "Default" : "Black",
            "Display Future Slider": displayFutureSliderKey.isEqual(to: NSNumber(value: 0)) ? "Yes" : "No",
            "Clocker mode": showAppInForeground.isEqual(to: NSNumber(value: 0)) ? "Menubar" : "Floating",
            "Relative Date": relativeDate,
            "Font Size": fontSize,
            "Sunrise Sunset": sunriseTime.isEqual(to: NSNumber(value: 0)) ? "Yes" : "No",
            "Show Day in Menu": showDayInMenu.isEqual(to: NSNumber(value: 0)) ? "Yes" : "No",
            "Show Date in Menu": showDateInMenu.isEqual(to: NSNumber(value: 0)) ? "Yes" : "No",
            "Show Place in Menu": showPlaceInMenu.isEqual(to: NSNumber(value: 0)) ? "Yes" : "No",
            "Show Upcoming Event View": showUpcomingEventView == "YES" ? "Yes" : "No",
            "Country": country,
            "Calendar Access Provided": EventCenter.sharedCenter().calendarAccessGranted() ? "Yes" : "No",
            "Number of Timezones": preferences.count,
        ]
        
        Logger.log(object: panelEvent, for: "openedPanel")
        
        PerfLogger.endMarker("Logging")
    }
    
    private func startWindowTimer() {
        PerfLogger.startMarker("Start Window Timer")
        
        stopMenubarTimerIfNeccesary()
        
        if let timer = parentTimer, timer.state == .paused {
            parentTimer?.start()
            
            PerfLogger.endMarker("Start Window Timer")
            
            return
        }
        
        startTimer()
        
        PerfLogger.endMarker("Start Window Timer")
    }
    
    private func startTimer() {
        Logger.info("Start timer called")
        
        parentTimer = Repeater(interval: .seconds(1), mode: .infinite) { _ in
            OperationQueue.main.addOperation {
                self.updateTime()
            }
        }
        parentTimer!.start()
    }
    
    private func stopMenubarTimerIfNeccesary() {
        let count = DataStore.shared().menubarTimezones()?.count ?? 0
        
        if count >= 1 || DataStore.shared().shouldDisplay(.showMeetingInMenubar) {
            if let delegate = NSApplication.shared.delegate as? AppDelegate {
                Logger.info("We will be invalidating the menubar timer as we want the parent timer to take care of both panel and menubar ")
                
                delegate.invalidateMenubarTimer(false)
            }
        }
    }
    
    func cancelOperation() {
        setActivePanel(newValue: false)
    }
    
    func hasActivePanelGetter() -> Bool {
        return hasActivePanel
    }
    
    func minimize() {
        let delegate = NSApplication.shared.delegate as? AppDelegate
        let count = DataStore.shared().menubarTimezones()?.count ?? 0
        if count >= 1 || DataStore.shared().shouldDisplay(.showMeetingInMenubar) == true {
            if let handler = delegate?.statusItemForPanel(), let timer = handler.menubarTimer, !timer.isValid {
                delegate?.setupMenubarTimer()
            }
        }
        
        parentTimer?.pause()
        
        updatePopoverDisplayState()
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.1
        window?.animator().alphaValue = 0
        additionalOptionsPopover?.close()
        NSAnimationContext.endGrouping()
        
        window?.orderOut(nil)
        
        datasource = nil
        parentTimer?.pause()
        parentTimer = nil
    }
    
    func setActivePanel(newValue: Bool) {
        hasActivePanel = newValue
        hasActivePanel ? open() : minimize()
    }
    
    class func panel() -> PanelController? {
        let panel = NSApplication.shared.windows.compactMap { window -> PanelController? in
            
            guard let parent = window.windowController as? PanelController else {
                return nil
            }
            
            return parent
        }
        
        return panel.first
    }
    
    override func showNotesPopover(forRow row: Int, relativeTo positioningRect: NSRect, andButton target: NSButton!) -> Bool {
        if additionalOptionsPopover == nil {
            additionalOptionsPopover = NSPopover()
        }
        
        guard let popover = additionalOptionsPopover else {
            return false
        }
        
        target.image = Themer.shared().extraOptionsHighlightedImage()
        
        if popover.isShown, row == previousPopoverRow {
            popover.close()
            target.image = Themer.shared().extraOptionsImage()
            previousPopoverRow = -1
            return false
        }
        
        previousPopoverRow = row
        
        super.showNotesPopover(forRow: row, relativeTo: positioningRect, andButton: target)
        
        popover.show(relativeTo: positioningRect,
                     of: target,
                     preferredEdge: .minX)
        
        if let timer = parentTimer, timer.state == .paused {
            timer.start()
        }
        
        return true
    }
    
    func setupMenubarTimer() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setupMenubarTimer()
        }
    }
    
    func pauseTimer() {
        if let timer = parentTimer {
            timer.pause()
        }
    }
    
    func refreshBackgroundView() {
        backgroundView.setNeedsDisplay(backgroundView.bounds)
    }
    
    override func scrollWheel(with event: NSEvent) {
        if event.phase == NSEvent.Phase.ended {
            Logger.log(object: nil, for: "Scroll Event Ended")
        }
        
        // We only want to move the slider if the slider is visible.
        // If the parent view is hidden, then that doesn't automatically mean that all the childViews are also hidden
        // Hence, check if the parent view is totally hidden or not..
        if modernSlider.isHidden {
            // TODO: Move modern slider
        }
    }
}

extension PanelController: NSWindowDelegate {
    func windowWillClose(_: Notification) {
        parentTimer = nil
        setActivePanel(newValue: false)
    }
    
    func windowDidResignKey(_: Notification) {
        parentTimer = nil
        
        if let isVisible = window?.isVisible, isVisible == true {
            setActivePanel(newValue: false)
        }
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.statusItemForPanel().statusItem.button?.state = .off
        }
    }
}

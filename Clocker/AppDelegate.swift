// Copyright © 2015 Abhishek Banthia

import Cocoa

open class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var floatingWindow: FloatingWindowController = FloatingWindowController.shared()
    private lazy var panelController: PanelController = PanelController.shared()
    private var statusBarHandler: StatusItemHandler!
    private var panelObserver: NSKeyValueObservation?

    deinit {
        panelObserver?.invalidate()
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change _: [NSKeyValueChangeKey: Any]?, context _: UnsafeMutableRawPointer?) {
        if let path = keyPath, path == "values.globalPing" {
            let hotKeyCenter = PTHotKeyCenter.shared()

            // Unregister old hot key
            let oldHotKey = hotKeyCenter?.hotKey(withIdentifier: path)
            hotKeyCenter?.unregisterHotKey(oldHotKey)

            // We don't register unless there's a valid key combination
            guard let newObject = object as? NSObject, let newShortcut = newObject.value(forKeyPath: path) as? [AnyHashable: Any] else {
                return
            }

            // Register new key
            let newHotKey: PTHotKey = PTHotKey(identifier: keyPath,
                                               keyCombo: newShortcut,
                                               target: self,
                                               action: #selector(ping(_:)))

            hotKeyCenter?.register(newHotKey)
        }
    }

    public func applicationWillFinishLaunching(_: Notification) {
        iVersion.sharedInstance().useAllAvailableLanguages = true
        iVersion.sharedInstance().verboseLogging = false
    }

    public func applicationDidFinishLaunching(_: Notification) {
        // Initializing the event store takes really long
        EventCenter.sharedCenter()

        AppDefaults.initialize()

        // Check if we can show the onboarding flow!
        showOnboardingFlowIfEligible()

        // Ratings Controller initialization
        RateController.applicationDidLaunch(UserDefaults.standard)

        #if RELEASE
            Crashlytics.sharedInstance().debugMode = true
            Fabric.with([Crashlytics.self])
            checkIfRunFromApplicationsFolder()
        #endif

        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }

    public func applicationDockMenu(_: NSApplication) -> NSMenu? {
        let menu = NSMenu(title: "Quick Access")

        Logger.log(object: ["Dock Menu Triggered": "YES"], for: "Dock Menu Triggered")

        let toggleMenuItem = NSMenuItem(title: "Toggle Panel", action: #selector(AppDelegate.togglePanel(_:)), keyEquivalent: "")
        let openPreferences = NSMenuItem(title: "Preferences", action: #selector(AppDelegate.openPreferencesWindow), keyEquivalent: ",")

        [toggleMenuItem, openPreferences].forEach {
            $0.isEnabled = true
            menu.addItem($0)
        }

        return menu
    }

    @objc private func openPreferencesWindow() {
        let displayMode = UserDefaults.standard.integer(forKey: CLShowAppInForeground)

        if displayMode == 1 {
            let floatingWindow = FloatingWindowController.shared()
            floatingWindow.openPreferences(NSButton())
        } else {
            let panelController = PanelController.shared()
            panelController.openPreferences(NSButton())
        }
    }

    private lazy var controller: OnboardingController? = {
        let onboardingStoryboard = NSStoryboard(name: NSStoryboard.Name("Onboarding"), bundle: nil)
        return onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingFlow")) as? OnboardingController
    }()

    private func showOnboardingFlowIfEligible() {
        let shouldLaunchOnboarding = (DataStore.shared().retrieve(key: CLShowOnboardingFlow) == nil && DataStore.shared().timezones().isEmpty)
            || ProcessInfo.processInfo.arguments.contains(CLOnboaringTestsLaunchArgument)

        shouldLaunchOnboarding ? controller?.launch() : continueUsually()
    }

    func continueUsually() {
        // Check if another instance of the app is already running. If so, then stop this one.
        checkIfAppIsAlreadyOpen()

        // Make sure the old models are not used anymore
        TimezoneData.convert()

        // Install the menubar item!
        statusBarHandler = StatusItemHandler()

        if UserDefaults.standard.object(forKey: CLInstallHomeIndicatorObject) == nil {
            fetchLocalTimezone()
            UserDefaults.standard.set(1, forKey: CLInstallHomeIndicatorObject)
        }

        if ProcessInfo.processInfo.arguments.contains(CLUITestingLaunchArgument) {
            RateController.setPreviewMode(true)
        }

        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

        assignShortcut()

        panelObserver = panelController.observe(\.hasActivePanel, options: [.new]) { obj, _ in
            self.statusBarHandler.setHasActiveIcon(obj.hasActivePanelGetter())
        }

        let defaults = UserDefaults.standard

        setActivationPolicy()

        // Set the display mode default as panel!
        if let displayMode = defaults.object(forKey: CLShowAppInForeground) as? NSNumber, displayMode.intValue == 1 {
            showFloatingWindow()
        } else if let displayMode = defaults.object(forKey: CLShowAppInForeground) as? Int, displayMode == 1 {
            showFloatingWindow()
        }
    }

    // Should we have a dock icon or just stay in the menubar?
    private func setActivationPolicy() {
        let defaults = UserDefaults.standard

        let activationPolicy: NSApplication.ActivationPolicy = defaults.integer(forKey: CLAppDislayOptions) == 0 ? .accessory : .regular
        NSApp.setActivationPolicy(activationPolicy)
    }

    private func checkIfAppIsAlreadyOpen() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return
        }

        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)

        if apps.count > 1 {
            let currentApplication = NSRunningApplication.current
            for app in apps where app != currentApplication {
                app.terminate()
            }
        }
    }

    private func showAppAlreadyOpenMessage() {
        showAlert(message: "An instance of Clocker is already open 😅",
                  informativeText: "This instance of Clocker will terminate now.",
                  buttonTitle: "Close")
    }

    private func showAlert(message: String, informativeText: String, buttonTitle: String) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.addButton(withTitle: buttonTitle)
        alert.runModal()
    }

    private func fetchLocalTimezone() {
        let identifier = TimeZone.autoupdatingCurrent.identifier

        let currentTimezone = TimezoneData()
        currentTimezone.timezoneID = identifier
        currentTimezone.setLabel(identifier)
        currentTimezone.formattedAddress = identifier
        currentTimezone.isSystemTimezone = true
        currentTimezone.placeID = "Home"

        let operations = TimezoneDataOperations(with: currentTimezone)
        operations.saveObject(at: 0)

        // Retrieve Location
        // retrieveLatestLocation()
    }

    @IBAction func ping(_ sender: Any) {
        togglePanel(sender)
    }

    private func retrieveLatestLocation() {
        let locationController = LocationController.sharedController()
        locationController.determineAndRequestLocationAuthorization()
    }

    private func showFloatingWindow() {
        // Display the Floating Window!
        floatingWindow.showWindow(nil)
        floatingWindow.updateTableContent()
        floatingWindow.startWindowTimer()

        NSApp.activate(ignoringOtherApps: true)
    }

    private func assignShortcut() {
        NSUserDefaultsController.shared.addObserver(self,
                                                    forKeyPath: "values.globalPing",
                                                    options: [.initial, .new],
                                                    context: nil)
    }

    private func checkIfRunFromApplicationsFolder() {
        if let shortCircuit = UserDefaults.standard.object(forKey: "AllowOutsideApplicationsFolder") as? Bool, shortCircuit == true {
            return
        }

        let bundlePath = Bundle.main.bundlePath
        let applicationDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.applicationDirectory,
                                                                       FileManager.SearchPathDomainMask.localDomainMask,
                                                                       true)
        for appDir in applicationDirectory {
            if bundlePath.hasPrefix(appDir) {
                return
            }
        }

        let informativeText = """
        Clocker must be run from the Applications folder in order to work properly.
        Please quit Clocker, move it to the Applications folder, and relaunch.
        Current folder: \(applicationDirectory)"
        """

        // Clocker is installed out of Applications directory
        // This breaks start at login! Time to show an alert and terminate
        showAlert(message: "Move Clocker to the Applications folder",
                  informativeText: informativeText,
                  buttonTitle: "Quit")

        // Terminate
        NSApp.terminate(nil)
    }

    @IBAction open func togglePanel(_: Any) {
        let displayMode = UserDefaults.standard.integer(forKey: CLShowAppInForeground)

        if displayMode == 1 {
            floatingWindow.showWindow(nil)
            floatingWindow.updateTableContent()
            floatingWindow.startWindowTimer()
        } else {
            panelController.showWindow(nil)
            panelController.setActivePanel(newValue: !panelController.hasActivePanelGetter())
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    open func setupFloatingWindow() {
        showFloatingWindow()
    }

    open func closeFloatingWindow() {
        floatingWindow.window?.close()
    }

    func statusItemForPanel() -> StatusItemHandler {
        return statusBarHandler
    }

    open func setPanelDefaults() {
        panelController.updateDefaultPreferences()
    }

    open func setupMenubarTimer() {
        statusBarHandler.setupStatusItem()
    }

    open func invalidateMenubarTimer(_ showIcon: Bool) {
        statusBarHandler.invalidateTimer(showIcon: showIcon, isSyncing: true)
    }
}

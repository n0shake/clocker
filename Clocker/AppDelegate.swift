// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit
import FirebaseCore
import FirebaseCrashlytics

open class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var floatingWindow = FloatingWindowController.shared()
    internal lazy var panelController = PanelController(windowNibName: .panel)
    private var statusBarHandler: StatusItemHandler!
    
    // TODO: Replace iVersion with this!
//    private let versionUpdateHandler: VersionUpdateHandler = VersionUpdateHandler(with: DataStore.shared())

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change _: [NSKeyValueChangeKey: Any]?, context _: UnsafeMutableRawPointer?) {
        if let path = keyPath, path == PreferencesConstants.hotKeyPathIdentifier {
            let hotKeyCenter = PTHotKeyCenter.shared()

            // Unregister old hot key
            let oldHotKey = hotKeyCenter?.hotKey(withIdentifier: path)
            hotKeyCenter?.unregisterHotKey(oldHotKey)

            // We don't register unless there's a valid key combination
            guard let newObject = object as? NSObject, let newShortcut = newObject.value(forKeyPath: path) as? [AnyHashable: Any] else {
                return
            }

            // Register new key
            let newHotKey = PTHotKey(identifier: keyPath,
                                     keyCombo: newShortcut,
                                     target: self,
                                     action: #selector(ping(_:)))

            hotKeyCenter?.register(newHotKey)
        }
    }

    public func applicationDidFinishLaunching(_: Notification) {
        AppDefaults.initialize(with: DataStore.shared(), defaults: UserDefaults.standard)

        // Check if we can show the onboarding flow!
        showOnboardingFlowIfEligible()

        // Ratings Controller initialization
        ReviewController.applicationDidLaunch(UserDefaults.standard)

        #if RELEASE
            FirebaseApp.configure()
            checkIfRunFromApplicationsFolder()
        #endif
    }
  
    public func applicationWillFinishLaunching(_: Notification) {
        iVersion.sharedInstance().useAllAvailableLanguages = true
        iVersion.sharedInstance().verboseLogging = false
    }

    public func applicationDockMenu(_: NSApplication) -> NSMenu? {
        let menu = NSMenu(title: "Quick Access")

        let toggleMenuItem = NSMenuItem(title: "Toggle Panel", action: #selector(AppDelegate.togglePanel(_:)), keyEquivalent: "")
        let openPreferences = NSMenuItem(title: "Settings", action: #selector(AppDelegate.openPreferencesWindow), keyEquivalent: ",")
        let hideFromDockMenuItem = NSMenuItem(title: "Hide from Dock", action: #selector(AppDelegate.hideFromDock), keyEquivalent: "")

        [toggleMenuItem, openPreferences, hideFromDockMenuItem].forEach {
            $0.isEnabled = true
            menu.addItem($0)
        }

        return menu
    }

    @objc private func openPreferencesWindow() {
        let displayMode = DataStore.shared().shouldDisplay(.showAppInForeground)

        if displayMode {
            let floatingWindow = FloatingWindowController.shared()
            floatingWindow.openPreferences(NSButton())
        } else {
            panelController.openPreferences(NSButton())
        }
    }

    @objc func hideFromDock() {
        UserDefaults.standard.set(0, forKey: UserDefaultKeys.appDisplayOptions)
        NSApp.setActivationPolicy(.accessory)
    }

    private var controller: OnboardingController?

    private func showOnboardingFlowIfEligible() {
        let isTestInProgress = ProcessInfo.processInfo.arguments.contains(UserDefaultKeys.onboardingTestsLaunchArgument)
        let shouldLaunchOnboarding =
        (DataStore.shared().retrieve(key: UserDefaultKeys.showOnboardingFlow) == nil
                && DataStore.shared().timezones().isEmpty)
            || isTestInProgress

        if shouldLaunchOnboarding {
            let onboardingStoryboard = NSStoryboard(name: NSStoryboard.Name("Onboarding"), bundle: nil)
            controller = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingFlow")) as? OnboardingController
            controller?.launch()
        } else {
            continueUsually()
        }
    }

    func continueUsually() {
        // Cleanup onboarding controller after its done!
        if controller != nil {
            controller = nil
        }

        // Check if another instance of the app is already running. If so, then stop this one.
        checkIfAppIsAlreadyOpen()

        // Install the menubar item!
        statusBarHandler = StatusItemHandler(with: DataStore.shared())

        if ProcessInfo.processInfo.arguments.contains(UserDefaultKeys.testingLaunchArgument) {
            FirebaseApp.configure()
            ReviewController.setPreviewMode(true)
        }

        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

        assignShortcut()

        let defaults = UserDefaults.standard

        setActivationPolicy()

        // Set the display mode default as panel!
        if let displayMode = defaults.object(forKey: UserDefaultKeys.showAppInForeground) as? NSNumber, displayMode.intValue == 1 {
            showFloatingWindow()
        } else if let displayMode = defaults.object(forKey: UserDefaultKeys.showAppInForeground) as? Int, displayMode == 1 {
            showFloatingWindow()
        }
    }

    // Should we have a dock icon or just stay in the menubar?
    private func setActivationPolicy() {
        let defaults = UserDefaults.standard

        let currentActivationPolicy = NSRunningApplication.current.activationPolicy
        let activationPolicy: NSApplication.ActivationPolicy = defaults.integer(forKey: UserDefaultKeys.appDisplayOptions) == 0 ? .accessory : .regular

        if currentActivationPolicy != activationPolicy {
            NSApp.setActivationPolicy(activationPolicy)
        }
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

    private func showAlert(message: String, informativeText: String, buttonTitle: String) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.addButton(withTitle: buttonTitle)
        alert.runModal()
    }

    @IBAction func ping(_ sender: NSButton) {
        if let statusItemButton = statusBarHandler.statusItem.button {
            statusItemButton.state = statusItemButton.state == .on ? .off : .on
            togglePanel(statusItemButton)
        }
    }

    private func retrieveLatestLocation() {
        let locationController = LocationController(withStore: DataStore.shared())
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
                                                    forKeyPath: PreferencesConstants.hotKeyPathIdentifier,
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

    @IBAction open func togglePanel(_ sender: NSButton) {
        Logger.info("Toggle Panel called with sender state \(sender.state.rawValue)")
        let displayMode = UserDefaults.standard.integer(forKey: UserDefaultKeys.showAppInForeground)

        if displayMode == 1 {
            // No need to call NSApp.activate here since `showFloatingWindow` takes care of this
            showFloatingWindow()
        } else {
            panelController.showWindow(nil)
            panelController.setActivePanel(newValue: sender.state == .on)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    open func setupFloatingWindow(_ hide: Bool) {
        hide ? floatingWindow.window?.close() : showFloatingWindow()
    }

    func statusItemForPanel() -> StatusItemHandler {
        return statusBarHandler
    }

    open func setupMenubarTimer() {
        statusBarHandler.setupStatusItem()
    }

    open func invalidateMenubarTimer(_ showIcon: Bool) {
        statusBarHandler.invalidateTimer(showIcon: showIcon, isSyncing: true)
    }
}

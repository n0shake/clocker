// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit

class VersionUpdateHandler: NSObject {
    enum VersionUpdateHandlerPriority {
        case defaultPri
        case low
        case medium
        case high
    }

    static let kSecondsInDay: Double = 86400.0
    static let kMacAppStoreRefreshDelay: Double = 5.0
    static let kMacRequestTimeout: Double = 60.0
    static let kVersionCheckLastVersionKey = "VersionCheckLastVersionKey"
    static let kVersionIgnoreVersionKey = "VersionCheckIgnoreVersionKey"
    static let kMacAppStoreIDKey = "VersionCheckAppStoreIDKey"
    static let kVersionLastCheckedKey = "VersionLastCheckedKey"
    static let kVersionLastRemindedKey = "VersionLastRemindedKey"

    static let sharedInstance = VersionUpdateHandler()

    private var appStoreCountry: String!
    private var applicationVersion: String!
    private var applicationBundleID: String = Bundle.main.bundleIdentifier ?? "N/A"
    private var updatePriority = VersionUpdateHandlerPriority.defaultPri
    public var useAllAvailableLanguages: Bool = true
    private var onlyPromptIfMainWindowIsAvailable: Bool = true
    private var checkAtLaunch: Bool = true
    private var checkPeriod: Double = 0.0
    private var remindPeriod: Double = 1.0
    private var verboseLogging: Bool = true
    private var updateURL: URL!
    private var checkingForNewVersion: Bool = false
    private var remoteVersionsDict: [String: Any] = [:]
    private var downloadError: Error?
    private var dataTask: URLSessionDataTask? = .none

    private var showOnFirstLaunch: Bool = false
    public var previewMode: Bool = false
    private var versionDetails: String?

    override init() {
        // Setup App Store Country
        appStoreCountry = Locale.current.regionCode
        if appStoreCountry == "150" {
            appStoreCountry = "eu"
        } else if appStoreCountry.replacingOccurrences(of: "[A-Za-z]{2}", with: "", options: .regularExpression, range: appStoreCountry.startIndex ..< appStoreCountry.endIndex).isEmpty == false {
            appStoreCountry = "us"
        }

        // Setup App Version
        var appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        if appVersion == nil {
            appVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
        }

        applicationVersion = appVersion ?? "N/A"

        // Bundle Identifier
        self.applicationBundleID = Bundle.main.bundleIdentifier ?? "com.abhishek.Clocker"
        
        //default settings
        self.updatePriority = .defaultPri;
        self.useAllAvailableLanguages = true;
        self.onlyPromptIfMainWindowIsAvailable = true;
        self.checkAtLaunch = true;
        self.checkPeriod = 0.0;
        self.remindPeriod = 1.0;
        self.verboseLogging = true;

        super.init()
        
        applicationLaunched()
    }

    private func inThisVersionTitle() -> String {
        return "New in this version"
    }

    private func updateAvailableTitle() -> String {
        return "New version available"
    }

    private func versionLabelFormat() -> String {
        return "Version %@"
    }

    private func okayButtonLabel() -> String {
        return "OK"
    }

    private func ignoreButtonLabel() -> String {
        return "Ignore"
    }

    private func downloadButtonLabel() -> String {
        return "Download"
    }

    private func remindButtonLabel() -> String {
        return "Remind Me Later"
    }

    private func updatedURL() -> URL {
        if updateURL.absoluteString.isEmpty == false {
            return updateURL
        }

        guard let appStoreId = appStoreID() else {
            Logger.info("No App Store ID was found for Clocker")
            return URL(string: "")!
        }

        return URL(string: "macappstore://itunes.apple.com/app/id\(appStoreId)")!
    }

    private func appStoreID() -> Int? {
        return UserDefaults.standard.integer(forKey: VersionUpdateHandler.kMacAppStoreIDKey)
    }

    @objc func setAppStoreID(_ appStoreID: Int) {
        UserDefaults.standard.set(appStoreID, forKey: VersionUpdateHandler.kMacAppStoreIDKey)
    }

    @objc private func setLastChecked(_ date: Date) {
        UserDefaults.standard.set(date, forKey: VersionUpdateHandler.kVersionLastCheckedKey)
    }

    private func lastChecked() -> Date? {
        return UserDefaults.standard.object(forKey: VersionUpdateHandler.kVersionLastCheckedKey) as? Date
    }

    private func setLastReminded(_ date: Date?) {
        UserDefaults.standard.set(date, forKey: VersionUpdateHandler.kVersionLastRemindedKey)
    }

    private func lastReminded() -> Date? {
        return UserDefaults.standard.object(forKey: VersionUpdateHandler.kVersionLastRemindedKey) as? Date
    }

    private func ignoredVersion() -> String? {
        return UserDefaults.standard.object(forKey: VersionUpdateHandler.kVersionIgnoreVersionKey) as? String
    }

    private func setIgnoredVersion(_ version: String) {
        UserDefaults.standard.set(version, forKey: VersionUpdateHandler.kVersionIgnoreVersionKey)
    }

    private func setViewedVersionDetails(_ viewed: Bool) {
        UserDefaults.standard.set(viewed ? applicationVersion : nil, forKey: VersionUpdateHandler.kVersionCheckLastVersionKey)
    }

    private func viewedVersionDetails() -> Bool {
        let lastVersionKey = UserDefaults.standard.object(forKey: VersionUpdateHandler.kVersionCheckLastVersionKey) as? String ?? ""
        return lastVersionKey == applicationVersion
    }

    private func lastVersion() -> String {
        return UserDefaults.standard.object(forKey: VersionUpdateHandler.kVersionCheckLastVersionKey) as? String ?? ""
    }

    private func setLastVersion(_ version: String) {
        UserDefaults.standard.set(version, forKey: VersionUpdateHandler.kVersionCheckLastVersionKey)
    }

    private func localVersionsDict() -> [String: Any] {
        return [String: Any]()
    }

    private func versionDetails(_ version: String, _ dict: [String: Any]) -> String? {
        if let versionData = dict[version] as? String {
            return versionData
        } else if let versionDataArray = dict[version] as? NSArray {
            return versionDataArray.componentsJoined(by: "\n")
        }
        return nil
    }

    private func versionDetails(since lastVersion: String, in dict: [String: Any]) -> String? {
        var lastVersionCopy = lastVersion
        if previewMode {
            lastVersionCopy = "0"
        }
        var newVersionFound = false
        var details = ""

        let versions = dict.keys.sorted()

        for version in versions {
            if version.compareVersion(lastVersionCopy) == .orderedDescending {
                newVersionFound = true
            }
            details.append(versionDetails(version, dict) ?? "")
            details.append("\n")
        }

        if newVersionFound {
            return details.trimmingCharacters(in: CharacterSet.newlines)
        }
        return nil
    }

    private func shouldCheckForNewVersion() -> Bool {
        if (!self.previewMode) {
            if let lastRemindedDate = lastReminded() {
                // Reminder takes priority over check period
                if Date().timeIntervalSince(lastRemindedDate) < Double(remindPeriod * Self.kSecondsInDay) {
                    if verboseLogging {
                        Logger.info("iVersion did not check for a new version because the user last asked to be reminded less than \(self.remindPeriod) days ago")
                    }
                    return false
                }
            } else if let lastCheckedDate = lastChecked(), Date().timeIntervalSince(lastCheckedDate) < Double(self.checkPeriod * Self.kSecondsInDay) {
                if (self.verboseLogging) {
                    Logger.info("iVersion did not check for a new version because the last check was less than \(self.checkPeriod) days ago")
                }
                return false
            }
        } else if (self.verboseLogging) {
            Logger.info("iVersion debug mode is enabled - make sure you disable this for release")
        }
        // perform the check
        return true
    }
    
    private func checkForNewVersionInBackground() {
        var newerVersionAvailable = false
        var osVersionSupported = false
        var latestVersion: String? = nil
        var versions: [String:String]? = nil
        
        var itunesServiceURL = "http://itunes.apple.com/\(self.appStoreCountry ?? "us")/lookup"
        if let appStoreID = appStoreID(), appStoreID != 0 {
            Logger.info("--- App Store ID is \(appStoreID)")
            itunesServiceURL = itunesServiceURL.appendingFormat("?id=%@", appStoreID)
        } else {
            itunesServiceURL = itunesServiceURL.appendingFormat("?bundleId=%@", self.applicationBundleID)
        }
        
        if (verboseLogging) {
            Logger.info("iVersion is checking \(itunesServiceURL) for a new app version...")
        }
        

        
        dataTask = NetworkManager.task(with: itunesServiceURL) { [weak self] response, error in
            guard let self, let data = response else {return }
            
            if (error != nil || response == nil) {
                Logger.info("Response is nil or error is non-nil")
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            
            if let unwrapped = json as? [String: Any], 
                let results = unwrapped["results"] as? Array<Any>,
               let firstResult = results.first as? [String: Any],
            let bundleID = firstResult["bundleId"] as? String {
                
                if (bundleID == self.applicationBundleID) {
                    guard let minimumSupportedOSVersion = firstResult["minimumOsVersion"] as? String else { return }
                    let version = ProcessInfo.processInfo.operatingSystemVersion
                    let systemVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
                    osVersionSupported = systemVersion.compareVersion(minimumSupportedOSVersion) != ComparisonResult.orderedAscending
                    if (!osVersionSupported) {
                        Logger.info("Current OS version is not supported")
                    }
                    // get version details
                    let releaseNotes = firstResult["releaseNotes"]
                    latestVersion = firstResult["version"] as? String
                    
                    if let version = latestVersion, osVersionSupported {
                        versions = [version : (releaseNotes as? String) ?? ""]
                    }
                    
                    // Get app ID
                    if (appStoreID() == nil) {
                        let appStoreIDString = firstResult["trackId"]
                        performSelector(onMainThread: #selector(setAppStoreID(_:)),
                                        with: appStoreIDString,
                                        waitUntilDone: true)
                        if (verboseLogging) {
                            Logger.info("iVersion found the app on iTunes. The App Store ID is \(appStoreIDString ?? "")")
                        }
                    }
                    
                    newerVersionAvailable = latestVersion?.compareVersion(self.applicationVersion) == .orderedDescending
                    if (verboseLogging) {
                        if (newerVersionAvailable) {
                            Logger.info("iVersion found a new version \(latestVersion ?? "N/A") of the app on iTunes. Current version is \(self.applicationVersion ?? "nil")")
                        } else {
                            Logger.info("iVersion did not find a new version of the app on iTunes. Current version is \(self.applicationVersion ?? "nil") and the latest version is \(latestVersion ?? "nil")")
                        }
                    }
                } else {
                    if (verboseLogging) {
                        Logger.info("iVersion found that the application bundle ID \(self.applicationBundleID) does not match the bundle ID of the app found on iTunes \(bundleID) with the specified App Store ID \(self.appStoreID() ?? 0)")
                    }
                }
            } else {
                Logger.info("Server returned an error while fetching version info")
            }
            
            //TODO: Set download error
            
            performSelector(onMainThread: #selector(setRemoteVersionsDict(_:)), with: versions, waitUntilDone: true)
            performSelector(onMainThread: #selector(setLastChecked(_:)), with: Date(), waitUntilDone: true)
            performSelector(onMainThread: #selector(Self.downloadVersionsData), with: nil, waitUntilDone: true)
        }
        
        dataTask?.resume()
    }
    
    @objc private func setRemoteVersionsDict(_ dict: [String: Any]?) {
        if let unwrappedDict = dict {
            remoteVersionsDict = unwrappedDict
        }
    }
    
    private func checkForNewVersion() {
        if (!self.checkingForNewVersion) {
            self.checkingForNewVersion = true
            DispatchQueue.global(qos: .userInitiated).async {
                self.checkForNewVersionInBackground()
            }
        }
    }

    private func applicationLaunched() {
        if checkAtLaunch {
            checkIfNewVersion()
            if (shouldCheckForNewVersion()) {
                checkForNewVersion()
            }
        } else if verboseLogging {
            Logger.info("iVersion will not check for updatess because checkAtLaunch option is disabled")
        }
    }

    private func versionDetailsString() -> String {
        if versionDetails == nil {
            if viewedVersionDetails() {
                versionDetails = versionDetails(applicationVersion, localVersionsDict())
            }
        } else {
            versionDetails = versionDetails(since: lastVersion(), in: localVersionsDict())
        }

        return versionDetails!
    }

    private func mostRecentVersionInDict(_ dict: [String: Any]) -> String {
//      return [dictionary.allKeys sortedArrayUsingSelector:@selector(compareVersion:)].lastObject;
        // TODO: Fix this sorting
        return dict.keys.sorted().last ?? ""
    }

    private func showAlertWithTitle(_ title: String, _ details: String, _ defaultButton: String, _ ignoreButton: String, _ remindButton: String) -> NSAlert {
        let floatMax = CGFloat.greatestFiniteMagnitude

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = inThisVersionTitle()
        alert.addButton(withTitle: defaultButton)

        let scrollView = NSScrollView(frame: NSRect(x: 0.0,
                                                    y: 0.0,
                                                    width: 380.0,
                                                    height: 15.0))
        let contentSize = scrollView.contentSize
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]

        let textView = NSTextView(frame: NSRect(x: 0.0,
                                                y: 0.0,
                                                width: contentSize.width,
                                                height: contentSize.height))
        textView.minSize = NSSize(width: 0.0, height: contentSize.height)
        textView.maxSize = NSSize(width: floatMax, height: floatMax)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.isEditable = false
        textView.autoresizingMask = .width
        textView.textContainer?.containerSize = NSSize(width: contentSize.width, height: floatMax)
        textView.textContainer?.widthTracksTextView = true
        textView.string = details
        scrollView.documentView = textView
        textView.sizeToFit()

        let height = min(200.0, scrollView.documentView?.frame.size.height ?? 200.0) + 3.0
        scrollView.frame = NSRect(x: 0.0, y: 0.0, width: scrollView.frame.size.width, height: height)
        alert.accessoryView = scrollView

        if ignoreButton.isEmpty == false {
            alert.addButton(withTitle: ignoreButton)
        }

        if remindButton.isEmpty == false {
            alert.addButton(withTitle: remindButton)

            let modalResponse = alert.runModal()
            if modalResponse == .alertFirstButtonReturn {
                // Right most button
                didDismissAlert(alert, 0)
            } else if modalResponse == .alertSecondButtonReturn {
                didDismissAlert(alert, 1)
            } else {
                didDismissAlert(alert, 2)
            }
        }

        return alert
    }

    private func showIgnoreButton() -> Bool {
        return false
    }

    private func showRemindButtton() -> Bool {
        return false
    }

    private func didDismissAlert(_: NSAlert, _: Int) {
        // Get Button Indice
    }

    @objc private func downloadVersionsData() {
        if onlyPromptIfMainWindowIsAvailable {
            guard NSApplication.shared.mainWindow != nil else {
                return
            }

            _ = Repeater(interval: .seconds(0.5), mode: .infinite) { _ in
                OperationQueue.main.addOperation { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.downloadVersionsData()
                }
            }
        }

        if checkingForNewVersion {
            checkingForNewVersion = false

            if remoteVersionsDict.isEmpty {
                if downloadError != nil {
                    Logger.info("Update Check Failed because of \(downloadError!.localizedDescription)")
                } else {
                    Logger.info("Version Update Check because an unknown error occurred")
                }
            }
            return
        }

        let details = versionDetails(since: applicationVersion, in: remoteVersionsDict)
        let mostRecentVersion = mostRecentVersionInDict(remoteVersionsDict)

        if details != nil {
            // Check if ignored
            let showDetails = ignoredVersion() == mostRecentVersion || previewMode

            if showDetails {}
        }
    }

    private func checkIfNewVersion() {
        if onlyPromptIfMainWindowIsAvailable {
            guard NSApplication.shared.mainWindow != nil else {
                return
            }

            _ = Repeater(interval: .seconds(5), mode: .infinite) { _ in
                OperationQueue.main.addOperation { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.checkIfNewVersion()
                }
            }
        }

        let lastVersionString = lastVersion()
        if lastVersionString.isEmpty == false || showOnFirstLaunch || previewMode {
            if applicationVersion.compareVersion(lastVersionString) == ComparisonResult.orderedDescending || previewMode {
                // Clear Reminder
                setLastReminded(nil)
            }
        }
    }
}

extension String {
    func compareVersion(_ version: String) -> ComparisonResult {
        return compare(version,
                       options: CompareOptions.numeric,
                       range: nil,
                       locale: nil)
    }

    func compareVersionDescending(_ version: String) -> ComparisonResult {
        let comparsionResult = (0 - compareVersion(version).rawValue)
        switch comparsionResult {
        case -1:
            return ComparisonResult.orderedAscending
        case 0:
            return ComparisonResult.orderedSame
        case 1:
            return ComparisonResult.orderedDescending
        default:
            assertionFailure("Invalid Comparison Result")
            return .orderedSame
        }
    }
}

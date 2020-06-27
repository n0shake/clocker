// Copyright © 2015 Abhishek Banthia

import Cocoa

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
    private var updatePriority: VersionUpdateHandlerPriority = VersionUpdateHandlerPriority.defaultPri
    private var useAllAvailableLanguages: Bool = true
    private var onlyPromptIfMainWindowIsAvailable: Bool = true
    private var checkAtLaunch: Bool = true
    private var checkPeriod: Float = 0.0
    private var remindPeriod: Float = 1.0
    private var verboseLogging: Bool = true
    private var updateURL: URL!
    private var checkingForNewVersion: Bool = false
    private var remoteVersionsDict: [String: Any] = [:]
    private var downloadError: Error?

    private var showOnFirstLaunch: Bool = false
    public var previewMode: Bool = false
    private var versionDetails: String?

    override init() {
        // Setup App Store Country
        appStoreCountry = Locale.current.regionCode
        if appStoreCountry == "150" {
            appStoreCountry = "eu"
        } else if appStoreCountry.replacingOccurrences(of: "[A-Za-z]{2}", with: "", options: .regularExpression, range: appStoreCountry.startIndex ..< appStoreCountry.endIndex).count > 0 {
            appStoreCountry = "us"
        }

        // Setup App Version
        var appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        if appVersion == nil {
            appVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
        }

        applicationVersion = appVersion ?? "N/A"

        // Bundle Identifier

        super.init()
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
        if updateURL.absoluteString.count > 0 {
            return updateURL
        }

        guard let appStoreId = appStoreID() else {
            print("No App Store ID was found for Clocker")
            return URL(string: "")!
        }

        return URL(string: "macappstore://itunes.apple.com/app/id\(appStoreId)")!
    }

    private func appStoreID() -> Int? {
        return UserDefaults.standard.integer(forKey: VersionUpdateHandler.kMacAppStoreIDKey)
    }

    func setAppStoreID(_ appStoreID: Int) {
        UserDefaults.standard.set(appStoreID, forKey: VersionUpdateHandler.kMacAppStoreIDKey)
    }

    private func setLastChecked(_ date: Date) {
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
        var details: String = ""

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
        return true
    }

    private func applicationLaunched() {
        if checkAtLaunch {
            checkIfNewVersion()
        } else if verboseLogging {
            print("iVersion will not check for updatess because checkAtLaunch option is disabled")
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
        textView.minSize = NSMakeSize(0.0, contentSize.height)
        textView.maxSize = NSMakeSize(floatMax, floatMax)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.isEditable = false
        textView.autoresizingMask = .width
        textView.textContainer?.containerSize = NSMakeSize(contentSize.width, floatMax)
        textView.textContainer?.widthTracksTextView = true
        textView.string = details
        scrollView.documentView = textView
        textView.sizeToFit()

        let height = min(200.0, scrollView.documentView?.frame.size.height ?? 200.0) + 3.0
        scrollView.frame = NSMakeRect(0.0, 0.0, scrollView.frame.size.width, height)
        alert.accessoryView = scrollView

        if ignoreButton.count > 0 {
            alert.addButton(withTitle: ignoreButton)
        }

        if remindButton.count > 0 {
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

    private func downloadVersionsData() {
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

            if remoteVersionsDict.count <= 0 {
                if downloadError != nil {
                    print("Update Check Failed because of \(downloadError!.localizedDescription)")
                } else {
                    print("Version Update Check because an unknown error occurred")
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
        if lastVersionString.count > 0 || showOnFirstLaunch || previewMode {
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

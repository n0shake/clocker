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

    private func lastVersion() -> String {
        return UserDefaults.standard.object(forKey: VersionUpdateHandler.kVersionCheckLastVersionKey) as? String ?? ""
    }

    private func setLastReminded(_ date: Date?) {
        UserDefaults.standard.set(date, forKey: VersionUpdateHandler.kVersionIgnoreVersionKey)
    }

    private func versionDetails(_ version: String, _ dict: [String: Any]) -> String? {
        if let versionData = dict[version] as? String {
            return versionData
        } else if let versionDataArray = dict[version] as? NSArray {
            return versionDataArray.componentsJoined(by: "\n")
        }
        return nil
    }

    private func setViewedVersionDetails(_ viewed: Bool) {
        UserDefaults.standard.set(viewed ? applicationVersion : nil, forKey: VersionUpdateHandler.kVersionCheckLastVersionKey)
    }

    private func viewedVersionDetails() -> Bool {
        let lastVersionKey = UserDefaults.standard.object(forKey: VersionUpdateHandler.kVersionCheckLastVersionKey) as? String ?? ""
        return lastVersionKey == applicationVersion
    }

    private func localVersionsDict() -> [String: Any] {
        return [String: Any]()
    }

    private func versionDetailsString() -> String {
        if versionDetails == nil {
            if viewedVersionDetails() {
                versionDetails = versionDetails(applicationVersion, localVersionsDict())
            }
        } else {
            versionDetails = versionDetails(lastVersion(), localVersionsDict())
        }

        return versionDetails!
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

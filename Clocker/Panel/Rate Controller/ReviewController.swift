// Copyright © 2015 Abhishek Banthia

import Cocoa
import StoreKit

final class ReviewController {
    private static var storage = UserDefaults.standard
    private static var debugging = false

    private enum Keys {
        static let lastPrompt = "last-prompt"
        static let lastVersion = "last-version"
        static let install = "install"
    }

    class func applicationDidLaunch(_ defaults: UserDefaults) {
        if ProcessInfo.processInfo.arguments.contains(CLUITestingLaunchArgument) {
            debugging = true
        }

        storage = defaults

        if defaults.object(forKey: Keys.install) == nil {
            defaults.set(Date(), forKey: Keys.install)
        }
    }

    class func setPreviewMode(_ value: Bool) {
        debugging = value
    }

    class func prompted() {
        storage.set(Date(), forKey: Keys.lastPrompt)
        storage.set(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String, forKey: Keys.lastVersion)
    }

    class func canPrompt() -> Bool {
        if debugging == true {
            return true
        }

        let day: TimeInterval = -1 * 60 * 60 * 24
        let minInstall: TimeInterval = day * 7

        // Check if the app has been installed for atleast 7 days
        guard let install = storage.object(forKey: Keys.install) as? Date,
              install.timeIntervalSinceNow < minInstall
        else { return false }

        // If we have never been prompted before, go ahead and prompt
        guard let lastPrompt = storage.object(forKey: Keys.lastPrompt) as? Date,
              let lastVersion = storage.object(forKey: Keys.lastVersion) as? String
        else { return true }

        // Minimum interval between two versions should be 3 months
        let minInterval: TimeInterval = day * 90

        // never prompt w/in the same version
        return lastVersion != (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
            // limit all types of prompts to at least 1mo intervals
            && lastPrompt.timeIntervalSinceNow < minInterval
    }

    class func prompt() {
        if #available(OSX 10.14, *) {
            SKStoreReviewController.requestReview()
        } else {
            guard let ratingsURL = URL(string: AboutUsConstants.AppStoreLink) else {
                return
            }
            NSWorkspace.shared.open(ratingsURL)
        }

        prompted()
    }
}

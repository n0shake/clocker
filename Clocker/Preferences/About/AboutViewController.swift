// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit

struct AboutUsConstants {
    static let AboutUsNibIdentifier = "CLAboutWindows"
    static let GitHubURL = "https://github.com/abhishekbanthia/Clocker/?ref=ClockerApp"
    static let PayPalURL = "https://paypal.me/abhishekbanthia1712"
    static let TwitterLink = "https://twitter.com/clocker_support/?ref=ClockerApp"
    static let TwitterFollowIntentLink = "https://twitter.com/intent/follow?screen_name=clocker_support"
    static let AppStoreLink = "macappstore://itunes.apple.com/us/app/clocker/id1056643111?action=write-review"
    static let CrowdInLocalizationLink = "https://crwd.in/clocker"
    static let FAQsLink = "https://abhishekbanthia.com/clocker/faq"
}

class AboutViewController: ParentViewController {
    @IBOutlet var quickCommentAction: PointingHandCursorButton!
    @IBOutlet var privateFeedback: PointingHandCursorButton!
    @IBOutlet var supportClocker: PointingHandCursorButton!
    @IBOutlet var openSourceButton: PointingHandCursorButton!
    @IBOutlet var versionField: NSTextField!

    private var themeDidChangeNotification: NSObjectProtocol?
    private var feedbackWindow: AppFeedbackWindowController?

    override func viewDidLoad() {
        super.viewDidLoad()

        privateFeedback.setAccessibilityIdentifier("ClockerPrivateFeedback")

        let appDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? "Clocker"
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "N/A"
        let longVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "N/A"

        versionField.stringValue = "\(appDisplayName) \(shortVersion) (\(longVersion))"

        setup()

        themeDidChangeNotification = NotificationCenter.default.addObserver(forName: .themeDidChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            self.setup()
        }
    }

    deinit {
        if let themeDidChangeNotif = themeDidChangeNotification {
            NotificationCenter.default.removeObserver(themeDidChangeNotif)
        }
    }

    private func underlineTextForActionButton() {
        let rangesInOrder = [NSRange(location: 3, length: 16),
                             NSRange(location: 7, length: privateFeedback.attributedTitle.length - 7),
                             NSRange(location: 27, length: 33),
                             NSRange(location: 42, length: 14)]

        let buttonsInOrder = [quickCommentAction,
                              privateFeedback,
                              supportClocker,
                              openSourceButton]

        let localizedKeys = ["1. @clocker_support on Twitter for quick comments",
                             "2. For Private Feedback",
                             "You can support Clocker by leaving a review on the App Store! :)",
                             "Help localize Clocker in your language by clicking here!"]

        zip(buttonsInOrder, localizedKeys).forEach { arg in
            let (button, title) = arg
            button?.title = title
        }

        zip(rangesInOrder, buttonsInOrder).forEach { arg in
            let (range, button) = arg
            setUnderline(for: button, range: range)
        }
    }

    private func setUnderline(for button: PointingHandCursorButton?, range: NSRange) {
        guard let underlinedButton = button else { return }

        let mutableParaghStyle = NSMutableParagraphStyle()
        mutableParaghStyle.alignment = .center

        let originalText = NSMutableAttributedString(string: underlinedButton.title)
        originalText.addAttribute(NSAttributedString.Key.underlineStyle,
                                  value: NSNumber(value: Int8(NSUnderlineStyle.single.rawValue)),
                                  range: range)
        originalText.addAttribute(NSAttributedString.Key.foregroundColor,
                                  value: Themer.shared().mainTextColor(),
                                  range: NSRange(location: 0, length: underlinedButton.attributedTitle.string.count))
        originalText.addAttribute(NSAttributedString.Key.font,
                                  value: (button?.font)!,
                                  range: NSRange(location: 0, length: underlinedButton.attributedTitle.string.count))
        originalText.addAttribute(NSAttributedString.Key.paragraphStyle,
                                  value: mutableParaghStyle,
                                  range: NSRange(location: 0, length: underlinedButton.attributedTitle.string.count))
        underlinedButton.attributedTitle = originalText
    }

    @IBAction func openMyTwitter(_: Any) {
        guard let twitterURL = URL(string: AboutUsConstants.TwitterLink),
              let countryCode = Locale.autoupdatingCurrent.regionCode else { return }

        NSWorkspace.shared.open(twitterURL)

        // Log this
        let custom: [String: Any] = ["Country": countryCode]
        Logger.log(object: custom, for: "Opened Twitter")
    }

    @IBAction func viewSource(_: Any) {
        guard let sourceURL = URL(string: AboutUsConstants.AppStoreLink),
              let countryCode = Locale.autoupdatingCurrent.regionCode else { return }

        NSWorkspace.shared.open(sourceURL)

        // Log this
        let custom: [String: Any] = ["Country": countryCode]
        Logger.log(object: custom, for: "Open App Store to Review")
    }

    @IBAction func reportIssue(_: Any) {
        feedbackWindow = AppFeedbackWindowController.sharedWindow
        feedbackWindow?.appFeedbackWindowDelegate = self
        feedbackWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        view.window?.orderOut(nil)

        if let countryCode = Locale.autoupdatingCurrent.regionCode {
            let custom: [String: Any] = ["Country": countryCode]
            Logger.log(object: custom, for: "Report Issue Opened")
        }
    }

    @IBAction func openGitHub(_: Any) {
        guard let localizationURL = URL(string: AboutUsConstants.CrowdInLocalizationLink),
              let languageCode = Locale.preferredLanguages.first else { return }

        NSWorkspace.shared.open(localizationURL)

        // Log this
        let custom: [String: Any] = ["Language": languageCode]
        Logger.log(object: custom, for: "Opened Localization Link")
    }

    @IBOutlet var feedbackLabel: NSTextField!

    private func setup() {
        feedbackLabel.stringValue = "Feedback is always welcome:".localized()
        feedbackLabel.textColor = Themer.shared().mainTextColor()
        versionField.textColor = Themer.shared().mainTextColor()
        underlineTextForActionButton()
    }
}

extension AboutViewController: AppFeedbackWindowControllerDelegate {
    func appFeedbackWindowWillClose() {
        feedbackWindow = nil
    }
    
    func appFeedbackWindoEntryPoint() -> String {
        return "about_view_controller"
    }
}

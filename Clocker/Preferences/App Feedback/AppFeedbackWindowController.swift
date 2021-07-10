// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import FirebaseDatabase

extension NSNib.Name {
    static let appFeedbackWindowIdentifier = NSNib.Name("AppFeedbackWindow")
    static let onboardingWindowIdentifier = NSNib.Name("OnboardingWindow")
    static let welcomeViewIdentifier = NSNib.Name("WelcomeView")
    static let startAtLoginViewIdentifier = NSNib.Name("StartAtLoginView")
}

enum AppFeedbackConstants {
    static let CLAppFeedbackNibIdentifier = "AppFeedbackWindow"
    static let CLAppFeedbackNoResponseString = "Not Provided"
    static let CLAppFeedbackNameProperty = "name"
    static let CLAppFeedbackEmailProperty = "email"
    static let CLAppFeedbackFeedbackProperty = "feedback"
    static let CLOperatingSystemVersion = "OS"
    static let CLClockerVersion = "Clocker version"
    static let CLFeedbackAlertTitle = "Thank you for helping make Clocker even better!"
    static let CLFeedbackAlertInformativeText = "We owe you a candy. 😇"
    static let CLFeedbackAlertButtonTitle = "Close"
    static let CLFeedbackNotEnteredErrorMessage = "Please enter some feedback."
    static let CLAppFeedbackDateProperty = "date"
    static let CLCaliforniaTimezoneIdentifier = "America/Los_Angeles"
}

class AppFeedbackWindowController: NSWindowController {
    @IBOutlet var nameField: NSTextField!
    @IBOutlet var emailField: NSTextField!
    @IBOutlet var feedbackTextView: NSTextView!
    @IBOutlet var progressIndicator: NSProgressIndicator!

    @IBOutlet var quickCommentsLabel: UnderlinedButton!
    private var themeDidChangeNotification: NSObjectProtocol?
    private var serialNumber: String? {
        let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        guard platformExpert > 0 else {
            return nil
        }

        guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String) else {
            return nil
        }

        IOObjectRelease(platformExpert)

        return serialNumber
    }

    private var isActivityInProgress = false {
        didSet {
            progressIndicator.isHidden = !isActivityInProgress
            isActivityInProgress ? progressIndicator.startAnimation(nil) : progressIndicator.stopAnimation(nil)
        }
    }

    static var sharedWindow = AppFeedbackWindowController(windowNibName: NSNib.Name.appFeedbackWindowIdentifier)

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.backgroundColor = Themer.shared().mainBackgroundColor()
        window?.titleVisibility = .hidden
        window?.titlebarAppearsTransparent = true

        progressIndicator.isHidden = true
        feedbackTextView.setAccessibilityIdentifier("FeedbackTextView")
        nameField.setAccessibilityIdentifier("NameField")
        emailField.setAccessibilityIdentifier("EmailField")
        progressIndicator.setAccessibilityIdentifier("ProgressIndicator")
        quickCommentsLabel.setAccessibility("QuickCommentLabel")

        setup()

        themeDidChangeNotification = NotificationCenter.default.addObserver(forName: .themeDidChangeNotification,
                                                                            object: nil,
                                                                            queue: OperationQueue.main) { _ in
            self.window?.backgroundColor = Themer.shared().mainBackgroundColor()
            self.setup()
        }
    }

    class func shared() -> AppFeedbackWindowController {
        return sharedWindow
    }

    override init(window: NSWindow!) {
        super.init(window: window)
    }

    deinit {
        if let themeDidChangeNotif = themeDidChangeNotification {
            NotificationCenter.default.removeObserver(themeDidChangeNotif)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func sendFeedback(_: Any) {
        isActivityInProgress = true

        if didUserEnterFeedback() == false {
            return
        }

        let feedbackInfo = retrieveDataForSending()
        sendDataToFirebase(feedbackInfo: feedbackInfo)
        showSucccessOnSendingInfo()
    }

    @IBAction func cancel(_: Any) {
        window?.close()
    }

    private func didUserEnterFeedback() -> Bool {
        let cleanedUpString = feedbackTextView.string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if cleanedUpString.isEmpty {
            self.window?.contentView?.makeToast(AppFeedbackConstants.CLFeedbackNotEnteredErrorMessage)
            isActivityInProgress = false
            return false
        }

        return true
    }

    private func retrieveDataForSending() -> [String: String] {
        guard let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        else {
            return [:]
        }

        let name = nameField.stringValue.isEmpty ? AppFeedbackConstants.CLAppFeedbackNoResponseString : nameField.stringValue
        let email = emailField.stringValue.isEmpty ? AppFeedbackConstants.CLAppFeedbackNoResponseString : emailField.stringValue
        let appFeedbackProperty = feedbackTextView.string
        let operatingSystem = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(operatingSystem.majorVersion).\(operatingSystem.minorVersion).\(operatingSystem.patchVersion)"
        let versionInfo = "Clocker \(shortVersion) (\(appVersion))"

        let feedbackInfo = [
            AppFeedbackConstants.CLAppFeedbackNameProperty: name,
            AppFeedbackConstants.CLAppFeedbackEmailProperty: email,
            AppFeedbackConstants.CLAppFeedbackFeedbackProperty: appFeedbackProperty,
            AppFeedbackConstants.CLOperatingSystemVersion: osVersion,
            AppFeedbackConstants.CLClockerVersion: versionInfo,
            AppFeedbackConstants.CLAppFeedbackDateProperty: todaysDate(),
        ]

        return feedbackInfo
    }

    private func todaysDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = TimeZone(identifier: AppFeedbackConstants.CLCaliforniaTimezoneIdentifier)
        return dateFormatter.string(from: Date())
    }

    var firebaseDBReference: DatabaseReference!

    private func sendDataToFirebase(feedbackInfo info: [String: String]) {
        guard let identifier = serialNumber else {
            assertionFailure("Serial Identifier was unexpectedly nil")
            return
        }

        firebaseDBReference = Database.database().reference()
        firebaseDBReference.child("Feedback").child(identifier).setValue(info)
    }

    private func showSucccessOnSendingInfo() {
        guard let feedbackWindow = window else {
            assertionFailure("Window property was unexpectedly nil")
            return
        }

        isActivityInProgress = false

        let alert = NSAlert()
        alert.messageText = "Thank you for helping make Clocker even better!"
        alert.informativeText = AppFeedbackConstants.CLFeedbackAlertInformativeText
        alert.addButton(withTitle: AppFeedbackConstants.CLFeedbackAlertButtonTitle)
        alert.beginSheetModal(for: feedbackWindow) { _ in
            self.window?.close()
        }
    }

    @IBOutlet var contactBox: NSBox!
    @IBOutlet var accessoryInfo: NSTextField!

    private func setup() {
        contactBox.title = "Contact Information (Optional)".localized()
        accessoryInfo.stringValue = "Contact fields are optional! Your contact information will let us contact you in case we need more information or can help!".localized()

        let range = NSRange(location: 9, length: 16)
        quickCommentsLabel.title = "Tweet to @Clocker_Support if you have a quick comment!"
        setUnderline(for: quickCommentsLabel, range: range)

        [accessoryInfo].forEach { $0?.textColor = Themer.shared().mainTextColor() }

        contactBox.borderColor = Themer.shared().mainTextColor()
    }

    private func setUnderline(for button: UnderlinedButton?, range: NSRange) {
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

    @IBAction func navigateToSupportTwitter(_: Any) {
        guard let twitterURL = URL(string: AboutUsConstants.TwitterLink),
              let countryCode = Locale.autoupdatingCurrent.regionCode else { return }

        NSWorkspace.shared.open(twitterURL)

        // Log this
        let custom: [String: Any] = ["Country": countryCode]
        Logger.log(object: custom, for: "Opened Twitter")
    }
}

extension AppFeedbackWindowController: NSWindowDelegate {
    func windowWillClose(_: Notification) {
        performClosingCleanUp()
        bringPreferencesWindowToFront()
    }

    func performClosingCleanUp() {
        nameField.stringValue = CLEmptyString
        emailField.stringValue = CLEmptyString
        feedbackTextView.string = CLEmptyString
        isActivityInProgress = false
    }

    func bringPreferencesWindowToFront() {
        let oneWindowController = OneWindowController.shared()
        oneWindowController.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
}

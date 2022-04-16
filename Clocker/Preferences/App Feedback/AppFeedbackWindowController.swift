// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit
import CoreModelKit
import FirebaseDatabase

protocol AppFeedbackWindowControllerDelegate: AnyObject {
    func appFeedbackWindowWillClose()
    func appFeedbackWindoEntryPoint() -> String
}

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
    static let CLAppFeedbackUserPreferences = "Prefs"
    static let CLCaliforniaTimezoneIdentifier = "America/Los_Angeles"
    static let CLFeedbackEntryPoint = "entry_point"
}

class AppFeedbackWindowController: NSWindowController {
    @IBOutlet var nameField: NSTextField!
    @IBOutlet var emailField: NSTextField!
    @IBOutlet var feedbackTextView: NSTextView!
    @IBOutlet var progressIndicator: NSProgressIndicator!

    @IBOutlet var quickCommentsLabel: PointingHandCursorButton!
    public weak var appFeedbackWindowDelegate: AppFeedbackWindowControllerDelegate?
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
                                                                            queue: OperationQueue.main)
        { _ in
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
        Logger.info("About to send \(feedbackInfo)")

        sendDataToFirebase(feedbackInfo: feedbackInfo)
        showSucccessOnSendingInfo()
    }

    @IBAction func cancel(_: Any) {
        window?.close()
    }

    private func didUserEnterFeedback() -> Bool {
        let cleanedUpString = feedbackTextView.string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if cleanedUpString.isEmpty {
            window?.contentView?.makeToast(AppFeedbackConstants.CLFeedbackNotEnteredErrorMessage)
            isActivityInProgress = false
            return false
        }

        return true
    }

    private func generateUserPreferences() -> String {
        let preferences = DataStore.shared().timezones()

        guard let theme = DataStore.shared().retrieve(key: CLThemeKey) as? NSNumber,
              let displayFutureSliderKey = DataStore.shared().retrieve(key: CLThemeKey) as? NSNumber,
              let relativeDateKey = DataStore.shared().retrieve(key: CLRelativeDateKey) as? NSNumber,
              let country = Locale.autoupdatingCurrent.regionCode
        else {
            return "Error"
        }

        let selectedTimezones = preferences.compactMap { data -> String? in
            guard let timezoneObject = TimezoneData.customObject(from: data) else {
                return nil
            }
            let customString = """
            Timezone: \(timezoneObject.timezone())
            Name: \(timezoneObject.formattedAddress ?? "No")
            Favourited: \((timezoneObject.isFavourite == 1) ? "Yes" : "No")
            Note: \(timezoneObject.note ?? "No Note")
            System: \(timezoneObject.isSystemTimezone ? "Yes" : "No")"
            """
            return customString
        }

        var relativeDate = "Relative"

        if relativeDateKey.isEqual(to: NSNumber(value: 1)) {
            relativeDate = "Actual Day"
        } else if relativeDateKey.isEqual(to: NSNumber(value: 2)) {
            relativeDate = "Date"
        }

        var themeInfo = "Light"
        if theme.isEqual(to: NSNumber(value: 1)) {
            themeInfo = "Dark"
        } else if theme.isEqual(to: NSNumber(value: 2)) {
            themeInfo = "System"
        }

        var futureSlider = "Modern"
        if displayFutureSliderKey.isEqual(to: NSNumber(value: 1)) {
            futureSlider = "Legacy"
        } else if theme.isEqual(to: NSNumber(value: 2)) {
            futureSlider = "Hidden"
        }

        return """
        "Theme: \(themeInfo), "Display Future Slider": \(futureSlider), "Relative Date": \(relativeDate), "Country": \(country), "Timezones": \(selectedTimezones)
        """
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

        return [
            AppFeedbackConstants.CLAppFeedbackNameProperty: name,
            AppFeedbackConstants.CLAppFeedbackEmailProperty: email,
            AppFeedbackConstants.CLAppFeedbackFeedbackProperty: appFeedbackProperty,
            AppFeedbackConstants.CLOperatingSystemVersion: osVersion,
            AppFeedbackConstants.CLClockerVersion: versionInfo,
            AppFeedbackConstants.CLAppFeedbackDateProperty: todaysDate(),
            AppFeedbackConstants.CLAppFeedbackUserPreferences: generateUserPreferences(),
            AppFeedbackConstants.CLFeedbackEntryPoint: appFeedbackWindowDelegate?.appFeedbackWindoEntryPoint() ?? "Error",
        ]
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
        #if DEBUG
            Logger.info("Sending a feedback in Debug builds will lead to a no-op")
        #endif

        guard let identifier = serialNumber else {
            assertionFailure("Serial Identifier was unexpectedly nil")
            return
        }

        #if RELEASE
            firebaseDBReference = Database.database().reference()
            firebaseDBReference.child("Feedback").child(identifier).setValue(info)
        #endif
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
        feedbackTextView.backgroundColor = Themer.shared().mainBackgroundColor()
        nameField.backgroundColor = Themer.shared().mainBackgroundColor()
        emailField.backgroundColor = Themer.shared().mainBackgroundColor()
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
        appFeedbackWindowDelegate?.appFeedbackWindowWillClose()
    }

    func bringPreferencesWindowToFront() {
        let windows = NSApplication.shared.windows
        let prefWindow = windows.first(where: { window in
            window.identifier == NSUserInterfaceItemIdentifier("Preferences")
        })
        if let prefW = prefWindow {
            prefW.makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

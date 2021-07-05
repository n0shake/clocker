// Copyright © 2015 Abhishek Banthia

import Cocoa
import CoreLoggerKit

struct EmailSignupConstants {
    static let CLEmailSignupEmailProperty = "email"
    static let CLOperatingSystemVersion = "OS"
    static let CLClockerVersion = "Clocker version"
    static let CLAppFeedbackDateProperty = "date"
    static let CLAppLanguageKey = "language"
}

class FinalOnboardingViewController: NSViewController {
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var subtitleLabel: NSTextField!
    @IBOutlet var accesoryLabel: NSTextField!
    @IBOutlet var accessoryImageView: NSImageView!
    @IBOutlet var emailTextField: NSTextField!
    @IBOutlet var localizationButton: UnderlinedButton!

    private let emailValidator = EmailTextFieldValidator()

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

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.stringValue = "You're all set!".localized()
        subtitleLabel.stringValue = "Thank you for the details.".localized()
        accesoryLabel.stringValue = "You'll see a clock icon in your Menu Bar when you launch the app. If you'd like to see a dock icon, go to Preferences.".localized()
        accessoryImageView.image = Themer.shared().menubarOnboardingImage()
        emailTextField.isHidden = true
        setupLocalizationButton()
    }

    private func setupLocalizationButton() {
        let mutableParaghStyle = NSMutableParagraphStyle()
        mutableParaghStyle.alignment = .center

        let underlineRange = NSRange(location: 0, length: 9)
        let originalText = NSMutableAttributedString(string: "Follow us on Twitter for occasional updates!")
        originalText.addAttribute(NSAttributedString.Key.underlineStyle,
                                  value: NSNumber(value: Int8(NSUnderlineStyle.single.rawValue)),
                                  range: underlineRange)
        originalText.addAttribute(NSAttributedString.Key.foregroundColor,
                                  value: Themer.shared().mainTextColor(),
                                  range: NSRange(location: 0, length: localizationButton.attributedTitle.string.count))
        originalText.addAttribute(NSAttributedString.Key.font,
                                  value: (localizationButton?.font)!,
                                  range: NSRange(location: 0, length: localizationButton.attributedTitle.string.count))
        originalText.addAttribute(NSAttributedString.Key.paragraphStyle,
                                  value: mutableParaghStyle,
                                  range: NSRange(location: 0, length: localizationButton.attributedTitle.string.count))

        localizationButton.attributedTitle = originalText
    }

    @IBAction func localizationAction(_: Any) {
        guard let localizationURL = URL(string: AboutUsConstants.TwitterLink),
            let languageCode = Locale.preferredLanguages.first else { return }

        NSWorkspace.shared.open(localizationURL)

        // Log this
        let custom: [String: Any] = ["Language": languageCode]
        Logger.log(object: custom, for: "Opened Localization Link")

        guard let parentVC = parent as? OnboardingParentViewController else { return }
        parentVC.performFinalStepsBeforeFinishing()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        emailTextField.becomeFirstResponder()
    }

    private func todaysDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = TimeZone(identifier: AppFeedbackConstants.CLCaliforniaTimezoneIdentifier)
        return dateFormatter.string(from: Date())
    }

    private func extraData() -> [String: String]? {
        guard let validEmail = emailValidator.validate(field: emailTextField) else {
            Logger.info("Not sending up email because it was invalid")
            return nil
        }

        guard let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            return nil
        }
        let operatingSystem = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(operatingSystem.majorVersion).\(operatingSystem.minorVersion).\(operatingSystem.patchVersion)"
        let versionInfo = "Clocker \(shortVersion) (\(appVersion))"

        return [
            EmailSignupConstants.CLEmailSignupEmailProperty: validEmail,
            EmailSignupConstants.CLOperatingSystemVersion: osVersion,
            EmailSignupConstants.CLClockerVersion: versionInfo,
            EmailSignupConstants.CLAppFeedbackDateProperty: todaysDate(),
            EmailSignupConstants.CLAppLanguageKey: Locale.preferredLanguages.first ?? "en-US",
        ]
    }
}

class EmailTextFieldValidator {
    func validate(field: NSTextField) -> String? {
        let trimmedText = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }

        let range = NSMakeRange(0, NSString(string: trimmedText).length)
        let allMatches = dataDetector.matches(in: trimmedText,
                                              options: [],
                                              range: range)

        if allMatches.count == 1,
            allMatches.first?.url?.absoluteString.contains("mailto:") == true {
            return trimmedText
        }
        return nil
    }
}

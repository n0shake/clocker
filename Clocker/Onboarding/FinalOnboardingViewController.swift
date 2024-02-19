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
    @IBOutlet var localizationButton: PointingHandCursorButton!

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
        let originalText = NSMutableAttributedString(string: "Follow us on X / Twitter for occasional updates!")
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
        guard let localizationURL = URL(string: AboutUsConstants.TwitterFollowIntentLink),
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
}

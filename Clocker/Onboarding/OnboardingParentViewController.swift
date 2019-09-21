// Copyright © 2015 Abhishek Banthia

import Cocoa

extension NSStoryboard.SceneIdentifier {
    static let welcomeIdentifier = NSStoryboard.SceneIdentifier("welcomeVC")
    static let onboardingPermissionsIdentifier = NSStoryboard.SceneIdentifier("onboardingPermissionsVC")
    static let startAtLoginIdentifier = NSStoryboard.SceneIdentifier("startAtLoginVC")
    static let onboardingSearchIdentifier = NSStoryboard.SceneIdentifier("onboardingSearchVC")
    static let finalOnboardingIdentifier = NSStoryboard.SceneIdentifier("finalOnboardingVC")
}

private enum OnboardingType: Int {
    case welcome
    case permissions
    case launchAtLogin
    case search
    case final
    case complete // Added for logging purposes
}

class OnboardingParentViewController: NSViewController {
    @IBOutlet private var containerView: NSView!
    @IBOutlet private var negativeButton: NSButton!
    @IBOutlet private var backButton: NSButton!
    @IBOutlet private var positiveButton: NSButton!

    private lazy var startupManager = StartupManager()

    private lazy var welcomeVC = (storyboard?.instantiateController(withIdentifier: .welcomeIdentifier) as? OnboardingWelcomeViewController)

    private lazy var permissionsVC = (storyboard?.instantiateController(withIdentifier: .onboardingPermissionsIdentifier) as? OnboardingPermissionsViewController)

    private lazy var startAtLoginVC = (storyboard?.instantiateController(withIdentifier: .startAtLoginIdentifier) as? StartAtLoginViewController)

    private lazy var onboardingSearchVC = (storyboard?.instantiateController(withIdentifier: .onboardingSearchIdentifier) as? OnboardingSearchController)

    private lazy var finalOnboardingVC = (storyboard?.instantiateController(withIdentifier: .finalOnboardingIdentifier) as? FinalOnboardingViewController)

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        setupWelcomeScreen()
        setupUI()
    }

    private func setupWelcomeScreen() {
        guard let firstVC = welcomeVC else {
            assertionFailure()
            return
        }

        addChildIfNeccessary(firstVC)
        containerView.addSubview(firstVC.view)
        firstVC.view.frame = containerView.bounds
    }

    private func setupUI() {
        setIdentifiersForTests()

        positiveButton.title = NSLocalizedString("Get Started",
                                                 comment: "Title for Welcome View Controller's Continue Button")
        backButton.title = NSLocalizedString("Back",
                                             comment: "Button title for going back to the previous screen")
        positiveButton.tag = OnboardingType.welcome.rawValue
        backButton.tag = OnboardingType.welcome.rawValue

        [negativeButton, backButton].forEach { $0?.isHidden = true }
    }

    private func setIdentifiersForTests() {
        positiveButton.setAccessibilityIdentifier("Forward")
        negativeButton.setAccessibilityIdentifier("Alternate")
        backButton.setAccessibilityIdentifier("Backward")
    }

    @IBAction func negativeAction(_: Any) {
        guard let fromViewController = startAtLoginVC, let toViewController = onboardingSearchVC else {
            assertionFailure()
            return
        }

        addChildIfNeccessary(toViewController)

        shouldStartAtLogin(false)

        transition(from: fromViewController,
                   to: toViewController,
                   options: .slideLeft) {
            self.positiveButton.tag = OnboardingType.search.rawValue
            self.backButton.tag = OnboardingType.launchAtLogin.rawValue
            self.positiveButton.title = NSLocalizedString("Continue",
                                                          comment: "Continue Button Title")
            self.negativeButton.isHidden = true
        }
    }

    @IBAction func continueOnboarding(_: NSButton) {
        if positiveButton.tag == OnboardingType.welcome.rawValue {
            navigateToPermissions()
        } else if positiveButton.tag == OnboardingType.permissions.rawValue {
            navigateToStartAtLogin()
        } else if positiveButton.tag == OnboardingType.launchAtLogin.rawValue {
            navigateToSearch()
        } else if positiveButton.tag == OnboardingType.search.rawValue {
            navigateToFinalStage()
        } else {
            performFinalStepsBeforeFinishing()
        }
    }

    private func navigateToPermissions() {
        guard let fromViewController = welcomeVC, let toViewController = permissionsVC else {
            assertionFailure()
            return
        }

        addChildIfNeccessary(toViewController)

        transition(from: fromViewController,
                   to: toViewController,
                   options: .slideLeft) {
            self.positiveButton.tag = OnboardingType.permissions.rawValue
            self.positiveButton.title = NSLocalizedString("Continue",
                                                          comment: "Continue Button Title")
            self.backButton.isHidden = false
        }
    }

    private func navigateToStartAtLogin() {
        guard let fromViewController = permissionsVC, let toViewController = startAtLoginVC else {
            assertionFailure()
            return
        }

        addChildIfNeccessary(toViewController)

        transition(from: fromViewController,
                   to: toViewController,
                   options: .slideLeft) {
            self.backButton.tag = OnboardingType.permissions.rawValue
            self.positiveButton.tag = OnboardingType.launchAtLogin.rawValue
            self.positiveButton.title = "Open Clocker At Login".localized()
            self.negativeButton.isHidden = false
        }
    }

    private func navigateToSearch() {
        guard let fromViewController = startAtLoginVC, let toViewController = onboardingSearchVC else {
            assertionFailure()
            return
        }

        addChildIfNeccessary(toViewController)

        shouldStartAtLogin(true)

        transition(from: fromViewController,
                   to: toViewController,
                   options: .slideLeft) {
            self.backButton.tag = OnboardingType.launchAtLogin.rawValue
            self.positiveButton.tag = OnboardingType.search.rawValue
            self.positiveButton.title = NSLocalizedString("Continue",
                                                          comment: "Continue Button Title")
            self.negativeButton.isHidden = true
        }
    }

    private func navigateToFinalStage() {
        guard let fromViewController = onboardingSearchVC, let toViewController = finalOnboardingVC else {
            assertionFailure()
            return
        }

        addChildIfNeccessary(toViewController)

        transition(from: fromViewController,
                   to: toViewController,
                   options: .slideLeft) {
            self.backButton.tag = OnboardingType.search.rawValue
            self.positiveButton.tag = OnboardingType.final.rawValue
            self.positiveButton.title = "Launch Clocker".localized()
        }
    }

    private func performFinalStepsBeforeFinishing() {
        finalOnboardingVC?.sendUpEmailIfValid()

        positiveButton.tag = OnboardingType.complete.rawValue

        // Install the menubar option!
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        appDelegate?.continueUsually()

        view.window?.close()

        if ProcessInfo.processInfo.arguments.contains(CLOnboaringTestsLaunchArgument) == false {
            UserDefaults.standard.set(true, forKey: CLShowOnboardingFlow)
        }
    }

    private func addChildIfNeccessary(_ viewController: NSViewController) {
        if children.contains(viewController) == false {
            addChild(viewController)
        }
    }

    @IBAction func back(_: Any) {
        if backButton.tag == OnboardingType.welcome.rawValue {
            goBackToWelcomeScreen()
        } else if backButton.tag == OnboardingType.permissions.rawValue {
            goBackToPermissions()
        } else if backButton.tag == OnboardingType.launchAtLogin.rawValue {
            goBackToStartAtLogin()
        } else if backButton.tag == OnboardingType.search.rawValue {
            goBackToSearch()
        }
    }

    private func goBackToSearch() {
        guard let fromViewController = finalOnboardingVC, let toViewController = onboardingSearchVC else {
            assertionFailure()
            return
        }

        transition(from: fromViewController,
                   to: toViewController,
                   options: .slideRight) {
            self.positiveButton.tag = OnboardingType.search.rawValue
            self.backButton.tag = OnboardingType.launchAtLogin.rawValue
            self.positiveButton.title = NSLocalizedString("Continue",
                                                          comment: "Continue Button Title")
            self.negativeButton.isHidden = true
        }
    }

    private func goBackToStartAtLogin() {
        guard let fromViewController = onboardingSearchVC, let toViewController = startAtLoginVC else {
            assertionFailure()
            return
        }

        transition(from: fromViewController,
                   to: toViewController,
                   options: .slideRight) {
            self.positiveButton.tag = OnboardingType.launchAtLogin.rawValue
            self.backButton.tag = OnboardingType.permissions.rawValue
            self.positiveButton.title = "Open Clocker At Login".localized()
            self.negativeButton.isHidden = false
        }
    }

    private func goBackToPermissions() {
        // We're on StartAtLogin VC and we have to go back to Permissions

        guard let fromViewController = startAtLoginVC, let toViewController = permissionsVC else {
            assertionFailure()
            return
        }

        transition(from: fromViewController,
                   to: toViewController,
                   options: .slideRight) {
            self.positiveButton.tag = OnboardingType.permissions.rawValue
            self.backButton.tag = OnboardingType.welcome.rawValue
            self.negativeButton.isHidden = true
            self.positiveButton.title = NSLocalizedString("Continue",
                                                          comment: "Continue Button Title")
        }
    }

    private func goBackToWelcomeScreen() {
        guard let fromViewController = permissionsVC, let toViewController = welcomeVC else {
            assertionFailure()
            return
        }

        transition(from: fromViewController,
                   to: toViewController,
                   options: .slideRight) {
            self.positiveButton.tag = OnboardingType.welcome.rawValue
            self.backButton.isHidden = true
            self.positiveButton.title = NSLocalizedString("Get Started",
                                                          comment: "Title for Welcome View Controller's Continue Button")
        }
    }

    private func shouldStartAtLogin(_ shouldStart: Bool) {
        // If tests are going on, we don't want to enable/disable launch at login!
        if ProcessInfo.processInfo.arguments.contains(CLOnboaringTestsLaunchArgument) {
            return
        }

        UserDefaults.standard.set(shouldStart ? 1 : 0, forKey: CLStartAtLogin)
        startupManager.toggleLogin(shouldStart)
        shouldStart ?
            Logger.log(object: [:], for: "Enable Launch at Login while Onboarding") :
            Logger.log(object: [:], for: "Disable Launch at Login while Onboarding")
    }

    func logExitPoint() {
        let currentViewController = currentController()
        print(currentViewController)
        Logger.log(object: currentViewController, for: "Onboarding Process Exit")
    }

    private func currentController() -> [String: String] {
        switch positiveButton.tag {
        case 0:
            return ["Onboarding Process Interrupted": "Welcome View"]
        case 1:
            return ["Onboarding Process Interrupted": "Onboarding Permissions View"]
        case 2:
            return ["Onboarding Process Interrupted": "Start At Login View"]
        case 3:
            return ["Onboarding Process Interrupted": "Onboarding Search View"]
        case 4:
            return ["Onboarding Process Interrupted": "Finish Onboarding View"]
        case 5:
            return ["Onboarding Process Completed": "Successfully"]
        default:
            return ["Onboarding Process Interrupted": "Error"]
        }
    }
}

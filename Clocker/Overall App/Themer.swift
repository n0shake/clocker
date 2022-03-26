// Copyright © 2015 Abhishek Banthia

import Cocoa

extension Notification.Name {
    static let themeDidChangeNotification = Notification.Name(rawValue: "ThemeDidChangeNotification")
}

enum Theme: Int {
    case light = 0
    case dark
    case system
    case solarizedLight
    case solarizedDark
}

class Themer: NSObject {
    private static var sharedInstance = Themer(index: UserDefaults.standard.integer(forKey: CLThemeKey))
    private var effectiveApperanceObserver: NSKeyValueObservation?

    private var themeIndex: Theme {
        didSet {
            NotificationCenter.default.post(name: .themeDidChangeNotification, object: nil)
        }
    }

    init(index: Int) {
        switch index {
        case 0:
            themeIndex = Theme.light
        case 1:
            themeIndex = Theme.dark
        case 2:
            themeIndex = Theme.system
        case 3:
            themeIndex = Theme.solarizedLight
        case 4:
            themeIndex = Theme.solarizedDark
        default:
            themeIndex = Theme.light
        }

        super.init()

        setAppAppearance()

        DistributedNotificationCenter.default.addObserver(self,
                                                          selector: #selector(respondToInterfaceStyle),
                                                          name: .interfaceStyleDidChange,
                                                          object: nil)
        
        if #available(macOS 10.14, *) {
            effectiveApperanceObserver = NSApp.observe(\.effectiveAppearance) { [weak self] (app, _) in
                if let sSelf = self {
                    sSelf.setAppAppearance()
                    NotificationCenter.default.post(name: .themeDidChangeNotification, object: nil)
                }
            }
        }
    }
}

extension Themer {
    class func shared() -> Themer {
        return sharedInstance
    }

    func set(theme: Int) {
        if themeIndex.rawValue == theme {
            return
        }

        switch theme {
        case 0:
            themeIndex = Theme.light
        case 1:
            themeIndex = Theme.dark
        case 2:
            themeIndex = Theme.system
        case 3:
            themeIndex = Theme.solarizedLight
        case 4:
            themeIndex = Theme.solarizedDark
        default:
            themeIndex = Theme.light
        }

        setAppAppearance()
    }

    @objc func respondToInterfaceStyle() {
        OperationQueue.main.addOperation {
            self.setAppAppearance()
        }
    }
    
    //MARK: Color
    func sliderKnobColor() -> NSColor {
        return themeIndex == .light ? NSColor(deviceRed: 255.0, green: 255.0, blue: 255, alpha: 0.9) : NSColor(deviceRed: 0.0, green: 0.0, blue: 0, alpha: 0.9)
    }

    func sliderRightColor() -> NSColor {
        return themeIndex == .dark ? NSColor.white : NSColor.gray
    }

    func mainBackgroundColor() -> NSColor {
        if #available(macOS 10.14, *) {
            switch themeIndex {
            case .light:
                return NSColor.white
            case .dark:
                return NSColor(deviceRed: 42.0 / 255.0, green: 42.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0)
            case .system:
                return retrieveCurrentSystem() == .light ? NSColor.white : NSColor.windowBackgroundColor
            case .solarizedLight:
                return NSColor(deviceRed: 253.0 / 255.0, green: 246.0 / 255.0, blue: 227.0 / 255.0, alpha: 1.0)
            case .solarizedDark:
                return NSColor(deviceRed: 7.0 / 255.0, green: 54.0 / 255.0, blue: 66.0 / 255.0, alpha: 1.0)
            }
        }

        return themeIndex == .light ? NSColor.white : NSColor(deviceRed: 55.0 / 255.0, green: 71.0 / 255.0, blue: 79.0 / 255.0, alpha: 1.0)
    }
    
    func textBackgroundColor() -> NSColor {
        if #available(macOS 10.14, *) {
            switch themeIndex {
            case .light:
                return NSColor(deviceRed: 241.0 / 255.0, green: 241.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0)
            case .dark:
                return NSColor(deviceRed: 42.0 / 255.0, green: 55.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0)
            case .system:
                return retrieveCurrentSystem() == .light ? NSColor(deviceRed: 241.0 / 255.0, green: 241.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0) : NSColor.controlBackgroundColor
            case .solarizedLight:
                return NSColor(deviceRed: 238.0 / 255.0, green: 232.0 / 255.0, blue: 213.0 / 255.0, alpha: 1.0)
            case .solarizedDark:
                return NSColor(deviceRed: 88.0 / 255.0, green: 110.0 / 255.0, blue: 117.0 / 255.0, alpha: 1.0)
            }
        }

        return themeIndex == .light ?
            NSColor(deviceRed: 241.0 / 255.0, green: 241.0 / 255.0, blue: 241.0 / 255.0, alpha: 1.0) :
            NSColor(deviceRed: 42.0 / 255.0, green: 55.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0)
    }

    func mainTextColor() -> NSColor {
        if #available(macOS 10.14, *) {
            switch themeIndex {
            case .light:
                return NSColor.black
            case .dark:
                return NSColor.white
            case .system:
                return NSColor.textColor
            case .solarizedLight:
                return NSColor.black
            case .solarizedDark:
                return NSColor.white
            }
        }

        return themeIndex == .light ? NSColor.black : NSColor.white
    }
    
    //MARK: Images
    func shutdownImage() -> NSImage {
        if let symbolImageForShutdown = symbolImage(for: "ellipsis.circle") {
            return symbolImageForShutdown
        }

        if #available(macOS 10.14, *) {
            switch themeIndex {
            case .light:
                return NSImage(named: NSImage.Name("PowerIcon"))!
            case .dark, .solarizedDark:
                return NSImage(named: NSImage.Name("PowerIcon-White"))!
            case .system:
                return NSImage(named: NSImage.Name("Power"))!
            case .solarizedLight:
                return NSImage(named: NSImage.Name("PowerIcon"))!
            }
        }

        return themeIndex == .light ? NSImage(named: NSImage.Name("PowerIcon"))! : NSImage(named: NSImage.Name("PowerIcon-White"))!
    }

    func preferenceImage() -> NSImage {
        if let symbolImageForPreference = symbolImage(for: "plus") {
            return symbolImageForPreference
        }
        
        return fallbackImageProvider(NSImage(named: NSImage.Name("Settings"))!,
                                     NSImage(named: NSImage.Name("Settings-White"))!,
                                     NSImage(named: NSImage.actionTemplateName)!,
                                     NSImage(named: NSImage.Name("Settings"))!,
                                     NSImage(named: NSImage.Name("Settings-White"))!)
    }

    func pinImage() -> NSImage {
        if let pinImage = symbolImage(for: "macwindow.on.rectangle") {
            return pinImage
        }
        
        return fallbackImageProvider(NSImage(named: NSImage.Name("Float"))!,
                                     NSImage(named: NSImage.Name("Float-White"))!,
                                     NSImage(named: NSImage.Name("Pin"))!,
                                     NSImage(named: NSImage.Name("Float"))!,
                                     NSImage(named: NSImage.Name("Float-White"))!)
    }

    func sunriseImage() -> NSImage {
        if let symbolImage = symbolImage(for: "sunrise.fill") {
            return symbolImage
        }
        return fallbackImageProvider(NSImage(named: NSImage.Name("Sunrise"))!,
                                     NSImage(named: NSImage.Name("WhiteSunrise"))!,
                                     NSImage(named: NSImage.Name("Sunrise Dynamic"))!,
                                     NSImage(named: NSImage.Name("Sunrise"))!,
                                     NSImage(named: NSImage.Name("WhiteSunrise"))!)
    }

    func sunsetImage() -> NSImage {
        if let symbolImage = symbolImage(for: "sunset.fill") {
            return symbolImage
        }
        
        return fallbackImageProvider(NSImage(named: NSImage.Name("Sunset"))!,
                                     NSImage(named: NSImage.Name("WhiteSunset"))!,
                                     NSImage(named: NSImage.Name("Sunset Dynamic"))!,
                                     NSImage(named: NSImage.Name("Sunset"))!,
                                     NSImage(named: NSImage.Name("WhiteSunset"))!)
    }

    func removeImage() -> NSImage {
        if let symbolImage = symbolImage(for: "xmark") {
            return symbolImage
        }
        
        return fallbackImageProvider(NSImage(named: NSImage.Name("Remove"))!,
                                     NSImage(named: NSImage.Name("WhiteRemove"))!,
                                     NSImage(named: NSImage.Name("Remove Dynamic"))!,
                                     NSImage(named: NSImage.Name("Remove"))!,
                                     NSImage(named: NSImage.Name("WhiteRemove"))!)
    }

    func extraOptionsImage() -> NSImage {
        return fallbackImageProvider(NSImage(named: NSImage.Name("Extra"))!,
                                     NSImage(named: NSImage.Name("ExtraWhite"))!,
                                     NSImage(named: NSImage.Name("Extra Dynamic"))!,
                                     NSImage(named: NSImage.Name("Extra"))!,
                                     NSImage(named: NSImage.Name("ExtraWhite"))!)
    }

    func menubarOnboardingImage() -> NSImage {
        if #available(macOS 10.14, *) {
            switch themeIndex {
            case .system:
                return NSImage(named: NSImage.Name("Dynamic Menubar"))!
            default:
                return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ? NSImage(named: NSImage.Name("Dark Menubar"))! : NSImage(named: NSImage.Name("Light Menubar"))!
            }
        }

        return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ? NSImage(named: NSImage.Name("Dark Menubar"))! : NSImage(named: NSImage.Name("Light Menubar"))!
    }

    func extraOptionsHighlightedImage() -> NSImage {
        return fallbackImageProvider(NSImage(named: NSImage.Name("ExtraHighlighted"))!,
                                     NSImage(named: NSImage.Name("ExtraWhiteHighlighted"))!,
                                     NSImage(named: NSImage.Name("ExtraHighlighted Dynamic"))!,
                                     NSImage(named: NSImage.Name("ExtraHighlighted"))!,
                                     NSImage(named: NSImage.Name("ExtraWhiteHighlighted"))!)
    }

    func sharingImage() -> NSImage {
        if let sharingImage = symbolImage(for: "square.and.arrow.up.on.square.fill") {
            return sharingImage
        }

        return fallbackImageProvider(NSImage(named: NSImage.Name("Sharing"))!,
                                     NSImage(named: NSImage.Name("SharingDarkIcon"))!,
                                     NSImage(named: NSImage.Name("Sharing Dynamic"))!,
                                     NSImage(named: NSImage.Name("Sharing"))!,
                                     NSImage(named: NSImage.Name("SharingDarkIcon"))!)
    }

    func currentLocationImage() -> NSImage {
        if let symbolImage = symbolImage(for: "location.fill") {
            return symbolImage
        }

        return fallbackImageProvider(NSImage(named: NSImage.Name("CurrentLocation"))!,
                                     NSImage(named: NSImage.Name("CurrentLocationWhite"))!,
                                     NSImage(named: NSImage.Name("CurrentLocationDynamic"))!,
                                     NSImage(named: NSImage.Name("CurrentLocation"))!,
                                     NSImage(named: NSImage.Name("CurrentLocationWhite"))!)
    }

    func popoverAppearance() -> NSAppearance {
        if #available(macOS 10.14, *) {
            switch themeIndex {
            case .light, .solarizedLight:
                return NSAppearance(named: NSAppearance.Name.vibrantLight)!
            case .dark, .solarizedDark:
                return NSAppearance(named: NSAppearance.Name.vibrantDark)!
            case .system:
                return NSAppearance.current
            }
        }

        return themeIndex == .light ? NSAppearance(named: NSAppearance.Name.vibrantLight)! : NSAppearance(named: NSAppearance.Name.vibrantDark)!
    }

    func addImage() -> NSImage {
        if let symbolImageForPreference = symbolImage(for: "plus") {
            return symbolImageForPreference
        }
        
        return fallbackImageProvider(NSImage(named: NSImage.Name("Add Icon"))!,
                                     NSImage(named: NSImage.Name("Add White"))!,
                                     NSImage(named: .addDynamicIcon)!,
                                     NSImage(named: NSImage.Name("Add Icon"))!,
                                     NSImage(named: NSImage.Name("Add White"))!)
    }

    func addImageHighlighted() -> NSImage {
        return themeIndex == .light ? NSImage(named: NSImage.Name("Add Highlighted"))! : NSImage(named: NSImage.Name("Add White"))!
    }

    func privacyTabImage() -> NSImage {
        if let privacyTabSFImage = symbolImage(for: "lock") {
            return privacyTabSFImage
        }

        return fallbackImageProvider(NSImage(named: NSImage.Name("Privacy"))!,
                                     NSImage(named: NSImage.Name("Privacy Dark"))!,
                                     NSImage(named: .permissionTabIcon)!,
                                     NSImage(named: NSImage.Name("Privacy"))!,
                                     NSImage(named: NSImage.Name("Privacy Dark"))!)
    }

    func appearanceTabImage() -> NSImage {
        if let appearanceTabImage = symbolImage(for: "eye") {
            return appearanceTabImage
        }

        return fallbackImageProvider(NSImage(named: NSImage.Name("Appearance"))!,
                                     NSImage(named: NSImage.Name("Appearance Dark"))!,
                                     NSImage(named: .appearanceTabIcon)!,
                                     NSImage(named: NSImage.Name("Appearance"))!,
                                     NSImage(named: NSImage.Name("Appearance Dark"))!)
    }

    func calendarTabImage() -> NSImage {
        if let calendarTabImage = symbolImage(for: "calendar") {
            return calendarTabImage
        }

        return fallbackImageProvider(NSImage(named: NSImage.Name("Calendar Tab Icon"))!,
                                     NSImage(named: NSImage.Name("Calendar Tab Dark"))!,
                                     NSImage(named: .calendarTabIcon)!,
                                     NSImage(named: NSImage.Name("Calendar Tab Icon"))!,
                                     NSImage(named: NSImage.Name("Calendar Tab Dark"))!)
    }

    func generalTabImage() -> NSImage? {
        return symbolImage(for: "gearshape")
    }

    func aboutTabImage() -> NSImage? {
        return symbolImage(for: "info.circle")
    }

    func videoCallImage() -> NSImage? {
        if #available(macOS 11.0, *) {
            let symbolConfig = NSImage.SymbolConfiguration(pointSize: 20, weight: .regular)
            return symbolImage(for: "video.circle.fill")?.withSymbolConfiguration(symbolConfig)
        } else {
            return nil
        }
    }

    func filledTrashImage() -> NSImage? {
        return symbolImage(for: "trash.fill")
    }

    // Modern Slider
    func goBackwardsImage() -> NSImage? {
        return symbolImage(for: "gobackward.15")
    }

    func goForwardsImage() -> NSImage? {
        return symbolImage(for: "goforward.15")
    }

    func resetModernSliderImage() -> NSImage? {
        if let xmarkImage = symbolImage(for: "xmark.circle.fill") {
            return xmarkImage
        }

        return removeImage()
    }
    
    //MARK: Debug Description
    
    override var debugDescription: String {
        if themeIndex == .system {
            return "System Theme is \(retrieveCurrentSystem())"
        }
        return "Current Theme is \(themeIndex)"
    }
    
    override var description: String {
        return debugDescription
    }
    
    //MARK: Private

    private func symbolImage(for name: String) -> NSImage? {
        assert(name.isEmpty == false)

        if #available(OSX 11.0, *) {
            return NSImage(systemSymbolName: name,
                           accessibilityDescription: name)
        }

        return nil
    }
    
    private func retrieveCurrentSystem() -> Theme {
        if #available(OSX 10.14, *) {
            if let appleInterfaceStyle = UserDefaults.standard.object(forKey: "AppleInterfaceStyle") as? String {
                if appleInterfaceStyle.lowercased().contains("dark") {
                    return .dark
                }
            }
        }
        return .light
    }
    
    private func setAppAppearance() {
        if #available(OSX 10.14, *) {
            var appAppearance = NSAppearance(named: .aqua)

            if themeIndex == .dark {
                appAppearance = NSAppearance(named: .darkAqua)
            } else if themeIndex == .system {
                appAppearance = retrieveCurrentSystem() == .dark ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
            }
            NSApp.appearance = appAppearance
        }
    }
    
    private func fallbackImageProvider(_ lightImage: NSImage,
                                       _ darkImage: NSImage,
                                       _ systemImage: NSImage,
                                       _ solarizedLightImage: NSImage,
                                       _ solarizedDarkImage: NSImage) -> NSImage {
        if #available(macOS 10.14, *) {
            switch themeIndex {
            case .light:
                return lightImage
            case .dark:
                return darkImage
            case .system:
                return systemImage
            case .solarizedLight:
                return solarizedLightImage
            case .solarizedDark:
                return solarizedDarkImage
            }
        }

        return themeIndex == .light ? lightImage : darkImage
        
    }

}

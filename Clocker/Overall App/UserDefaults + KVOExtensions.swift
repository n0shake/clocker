// Copyright © 2015 Abhishek Banthia

import Cocoa

extension UserDefaults {
    @objc dynamic var displayFutureSlider: Int {
        return integer(forKey: UserDefaultKeys.displayFutureSliderKey)
    }

    @objc dynamic var userFontSize: Int {
        return integer(forKey: UserDefaultKeys.userFontSizePreference)
    }

    @objc dynamic var sliderDayRange: Int {
        return integer(forKey: UserDefaultKeys.futureSliderRange)
    }
}

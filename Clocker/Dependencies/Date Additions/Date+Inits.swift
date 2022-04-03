//
//  Date+DateTools.swift
//  DateTools
//
//  Created by Grayson Webster on 8/17/16.
//  Copyright © 2016 Grayson Webster. All rights reserved.
//

import Foundation

/**
 *  Extends the Date class by adding convenient initializers based on components
 *  and format strings.
 */

public extension Date {
    // MARK: - Initializers

    /**
     *  Init date with components.
     *
     *  - parameter year: Year component of new date
     *  - parameter month: Month component of new date
     *  - parameter day: Day component of new date
     *  - parameter hour: Hour component of new date
     *  - parameter minute: Minute component of new date
     *  - parameter second: Second component of new date
     */
    init(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second

        guard let date = Calendar.current.date(from: dateComponents) else {
            self = Date()
            return
        }
        self = date
    }
}

//
//  WidgetDataMapper.swift
//  DontGoMart
//
//  Created by 황석현 on 12/2/24.
//

import SwiftUI
import WidgetKit

struct HolidayEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let holidayText: String
}

struct DayEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct TwoHolidayEntry: TimelineEntry {
    var date: Date
    let configuration: ConfigurationIntent
    let holidayText: [String]
}


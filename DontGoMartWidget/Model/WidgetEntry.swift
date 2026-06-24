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

/// 앱이 앱그룹에 저장해 둔 다가오는 휴무일 한 건.
struct UpcomingClosedDay {
    let date: Date
    let martName: String
    let martKey: String
}

/// 위젯이 '기준일(entry.date) 이후 가장 가까운 휴무일들' 을 스스로 골라낸다.
/// entry.date 가 매일 바뀌므로, 앱을 실행하지 않아도 하루가 지나면
/// 자동으로 다음 휴무일·D-Day 로 넘어간다.
enum WidgetClosedDayStore {
    static func upcoming(onOrAfter day: Date) -> [UpcomingClosedDay] {
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: day)

        guard let dates = defaults?.array(forKey: AppStorageKeys.widgetUpcomingDates) as? [Double],
              !dates.isEmpty else { return [] }
        let names = (defaults?.array(forKey: AppStorageKeys.widgetUpcomingMartNames) as? [String]) ?? []
        let keys = (defaults?.array(forKey: AppStorageKeys.widgetUpcomingMartKeys) as? [String]) ?? []

        var result: [UpcomingClosedDay] = []
        for (index, interval) in dates.enumerated() {
            let date = Date(timeIntervalSince1970: interval)
            guard calendar.startOfDay(for: date) >= startDay else { continue }
            let name = index < names.count ? names[index] : String(localized: "마트")
            let key = index < keys.count ? keys[index] : ""
            result.append(UpcomingClosedDay(date: date, martName: name, martKey: key))
        }
        return result
    }
}


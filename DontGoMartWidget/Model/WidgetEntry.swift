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

/// '이번 주 일요일' 영업/휴무 위젯용 엔트리.
/// - sundayDate: entry.date 기준 다가오는(이번 주) 일요일
/// - isClosed: 그 일요일이 선택 마트의 휴무일이면 true (빨강), 아니면 영업(초록)
/// - hasMart: 선택된 마트가 하나라도 있는지 (없으면 안내 문구 표시)
struct SundayStatusEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let sundayDate: Date
    let isClosed: Bool
    let hasMart: Bool
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

    /// 선택된 마트가 하나라도 있는지 (앱그룹에 저장된 선택 목록 기준).
    static var hasSelectedMart: Bool {
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)
        let array = defaults?.array(forKey: AppStorageKeys.selectedMartTypes) as? [String]
        return !(array?.isEmpty ?? true)
    }

    /// 기준일(day) 이후 가장 가까운 일요일. 오늘이 일요일이면 오늘.
    static func nextSunday(onOrAfter day: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: day)
        let weekday = calendar.component(.weekday, from: start) // 1 = 일요일
        let daysToAdd = (1 - weekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysToAdd, to: start) ?? start
    }

    /// 기준일(day) 기준 '이번 주 일요일' 과 그날 선택 마트의 휴무 여부.
    /// 저장된 다가오는 휴무일 목록에 그 일요일이 있으면 휴무(빨강)로 본다.
    static func sundayStatus(onOrAfter day: Date) -> (sunday: Date, isClosed: Bool) {
        let calendar = Calendar.current
        let sunday = nextSunday(onOrAfter: day, calendar: calendar)
        let isClosed = upcoming(onOrAfter: day).contains { closed in
            calendar.isDate(calendar.startOfDay(for: closed.date), inSameDayAs: sunday)
        }
        return (sunday, isClosed)
    }
}


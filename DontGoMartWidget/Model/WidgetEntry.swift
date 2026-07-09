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

/// 앱이 앱그룹에 저장해 둔 다가오는 휴무일 한 건. (앱↔위젯 공유 저장 모델)
struct UpcomingClosedDay: Codable {
    let date: Date
    let martName: String
    let martKey: String
}

/// 위젯이 '기준일(entry.date) 이후 가장 가까운 휴무일들' 을 스스로 골라낸다.
/// entry.date 가 매일 바뀌므로, 앱을 실행하지 않아도 하루가 지나면
/// 자동으로 다음 휴무일·D-Day 로 넘어간다.
///
/// 앱그룹에는 다가오는 휴무일 목록을 단일 JSON(`widgetUpcomingList`)으로 저장한다.
/// (예전엔 평행 배열 + 문자열 키가 여러 개로 흩어져 있었으나 하나로 통합)
enum WidgetClosedDayStore {
    /// 앱이 저장한 전체 목록.
    static func loadAll() -> [UpcomingClosedDay] {
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)
        guard let data = defaults?.data(forKey: AppStorageKeys.widgetUpcomingList),
              let list = try? JSONDecoder().decode([UpcomingClosedDay].self, from: data) else {
            return []
        }
        return list
    }

    /// 앱이 목록을 저장한다.
    static func save(_ list: [UpcomingClosedDay]) {
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)
        if list.isEmpty {
            defaults?.removeObject(forKey: AppStorageKeys.widgetUpcomingList)
        } else if let data = try? JSONEncoder().encode(list) {
            defaults?.set(data, forKey: AppStorageKeys.widgetUpcomingList)
        }
    }

    static func upcoming(onOrAfter day: Date) -> [UpcomingClosedDay] {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: day)
        return loadAll()
            .filter { calendar.startOfDay(for: $0.date) >= startDay }
            .sorted { $0.date < $1.date }
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


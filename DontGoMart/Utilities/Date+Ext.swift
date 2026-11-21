//
//  Untitled.swift
//  DontGoMart
//
//  Created by hyunho lee on 11/9/24.
//

import SwiftUI

// MARK: - 아랍어: 양력 · 0~9

// 휴무일은 한국의 양력 날짜다. 아랍어 기기는 히즈라력과 아랍-인도 숫자(١٢٣)가 기본일 수 있어
// '둘째 · 넷째 일요일' 계산과 달력이 어긋나고, 한 화면에 ١٢٣ 과 123 이 섞인다.
// 그래서 앱 글이 아랍어일 때만 양력과 0~9 로 맞춘다. 다른 언어는 기기 설정을 그대로 따른다.

extension Locale {
    /// 앱 글이 아랍어인가 (기기 언어 중 앱이 고른 번역).
    static let isArabicUI = Bundle.main.preferredLocalizations.first == "ar"

    /// 날짜 · 숫자 표기용 로케일. 아랍어면 언어 · 지역은 그대로, 달력은 양력, 숫자는 0~9.
    static let app: Locale = {
        guard isArabicUI else { return .autoupdatingCurrent }
        var parts = Locale.Components(locale: .current)
        parts.calendar = .gregorian
        parts.numberingSystem = "latn"
        return Locale(components: parts)
    }()
}

extension Calendar {
    /// 날짜 계산용 달력. 아랍어면 양력, 아니면 기기 달력 그대로.
    static let app: Calendar = {
        guard Locale.isArabicUI else { return .autoupdatingCurrent }
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .app
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()
}

extension FormatStyle where Self == Date.FormatStyle {
    /// `.dateTime` 대신 쓴다 — 아랍어에서도 양력 · 0~9 로 나온다.
    static var app: Date.FormatStyle { Date.FormatStyle(locale: .app, calendar: .app) }
}

extension Date {
    /// `formatted(date:time:)` 의 아랍어 양력판.
    func appFormatted(date: Date.FormatStyle.DateStyle, time: Date.FormatStyle.TimeStyle = .omitted) -> String {
        formatted(Date.FormatStyle(date: date, time: time, locale: .app, calendar: .app))
    }
}

extension View {
    /// 화면 · 위젯 · 그려 내는 카드에 앱 언어의 방향 · 달력 · 숫자를 준다.
    /// ImageRenderer 는 기기 방향을 물려받지 않아 아랍어 카드도 왼쪽에서 오른쪽으로 그려졌다.
    @ViewBuilder func appLocale() -> some View {
        if Locale.isArabicUI {
            environment(\.locale, .app)
                .environment(\.calendar, .app)
                .environment(\.layoutDirection, .rightToLeft)
        } else {
            self
        }
    }
}

extension Date {
    
    var dayDisplayFormat: String { self.formatted(.app.day()) }
    
    var weekdayDisplayFormat: String { self.formatted(.app.weekday(.wide)) }
    
    func getAllDates() -> [Date] {
        let calendar = Calendar.app
        guard
            let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: self)),
            let range = calendar.range(of: .day, in: .month, for: startDate)
        else { return [] }
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: startDate)
        }
    }
    
    func getMonthDayWeekday() -> (month: String, day: String, weekday: String) {
        let formatter = DateFormatter()
        if Locale.isArabicUI {
            // 아랍어: 한국어 조각(11월 · 23일) 대신 "23 نوفمبر" 한 덩어리를 day 에 담는다
            formatter.locale = .app
            formatter.calendar = .app
            formatter.setLocalizedDateFormatFromTemplate("dMMMM")
            let day = formatter.string(from: self)
            formatter.setLocalizedDateFormatFromTemplate("EEEE")
            return ("", day, formatter.string(from: self))
        }
        formatter.locale = Locale(identifier: "ko_KR") // 한국어 설정
        
        // 월
        formatter.dateFormat = "M월"
        let month = formatter.string(from: self)
        
        // 일
        formatter.dateFormat = "d일"
        let day = formatter.string(from: self)
        
        // 요일
        formatter.dateFormat = "EEEE"
        let weekday = formatter.string(from: self)
        
        return (month, day, weekday)
    }
    
    func dateToDisplay(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(calendar: Calendar.app,
                                        year: year,
                                        month: month,
                                        day: day)
        return Calendar.app.date(from: components) ?? Date()
    }
}

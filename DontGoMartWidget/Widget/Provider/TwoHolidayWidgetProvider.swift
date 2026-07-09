//
//  TwoHolidayWidgetProvider.swift
//  DontGoMart
//
//  Created by 황석현 on 12/2/24.
//

import SwiftUI
import WidgetKit

struct TwoHoliydayWidgetProvider: IntentTimelineProvider {

    private static var previewText: [String] {
        [
            String(format: String(localized: "%@ 휴무"), String(localized: "마트")),
            "Jan 26 Sun", "D-5",
            "Feb 9 Sun", "D-19"
        ]
    }
    private static var emptyHolidayText: [String] {
        [String(localized: "마트 휴무"), "-", "D-?", "-", "D-?"]
    }

    func placeholder(in context: Context) -> TwoHolidayEntry {
        TwoHolidayEntry(date: Date(), configuration: ConfigurationIntent(), holidayText: Self.previewText)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (TwoHolidayEntry) -> ()) {
        let entry = TwoHolidayEntry(date: Date(), configuration: configuration, holidayText: Self.previewText)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<TwoHolidayEntry>) -> ()) {
        var entries: [TwoHolidayEntry] = []
        let calendar = Calendar.current
        let currentDate = Date()

        // 16일치 일별 엔트리. 각 엔트리는 그 날 기준으로 '다가오는 휴무일 2건' 을
        // 스스로 골라 D-Day 를 계산하므로, 하루가 지나면 자동으로 다음 휴무일로 넘어간다.
        for dayOffset in 0 ..< 16 {
            guard let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: currentDate) else { continue }
            let startOfDate = calendar.startOfDay(for: entryDate)

            let upcoming = WidgetClosedDayStore.upcoming(onOrAfter: startOfDate)

            let displayText: [String]
            if upcoming.count >= 2 {
                let first = upcoming[0]
                let second = upcoming[1]

                let firstDday = calendar.dateComponents([.day], from: startOfDate, to: calendar.startOfDay(for: first.date)).day ?? 0
                let secondDday = calendar.dateComponents([.day], from: startOfDate, to: calendar.startOfDay(for: second.date)).day ?? 0

                let firstDateText = first.date.getMonthDayWeekday()
                let secondDateText = second.date.getMonthDayWeekday()

                displayText = [
                    String(format: String(localized: "%@ 휴무"), first.martName),
                    "\(firstDateText.month)\(firstDateText.day) (\(firstDateText.weekday))",
                    firstDday >= 0 ? "D-\(firstDday)" : "D+\(abs(firstDday))",
                    "\(secondDateText.month)\(secondDateText.day) (\(secondDateText.weekday))",
                    secondDday >= 0 ? "D-\(secondDday)" : "D+\(abs(secondDday))",
                    first.martKey
                ]
            } else if let only = upcoming.first {
                // 다가오는 휴무일이 1건뿐일 때
                let dday = calendar.dateComponents([.day], from: startOfDate, to: calendar.startOfDay(for: only.date)).day ?? 0
                let dateText = only.date.getMonthDayWeekday()
                displayText = [
                    String(format: String(localized: "%@ 휴무"), only.martName),
                    "\(dateText.month)\(dateText.day) (\(dateText.weekday))",
                    dday >= 0 ? "D-\(dday)" : "D+\(abs(dday))",
                    "-",
                    "D-?",
                    only.martKey
                ]
            } else {
                // 다가오는 휴무일 목록이 비어 있음(마트 미선택 등)
                displayText = Self.emptyHolidayText
            }

            let entry = TwoHolidayEntry(date: startOfDate, configuration: configuration, holidayText: displayText)
            entries.append(entry)
        }

        // 매일 자정에 timeline 재생성 → 목록 갱신 + D-Day 재계산
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(86400)
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        let timeline = Timeline(entries: entries, policy: .after(nextMidnight))
        completion(timeline)
    }
}

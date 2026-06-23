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
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)
        let calendar = Calendar.current

        let firstDateInterval = defaults?.double(forKey: AppStorageKeys.widgetNextClosedDate) ?? 0
        let secondDateInterval = defaults?.double(forKey: AppStorageKeys.widgetSecondClosedDate) ?? 0
        let martName = defaults?.string(forKey: AppStorageKeys.widgetNextClosedMartName) ?? String(localized: "마트")
        let martStorageKey = defaults?.string(forKey: AppStorageKeys.widgetMartStorageKey) ?? ""

        let currentDate = Date()
        for dayOffset in 0 ..< 7 {
            guard let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: currentDate) else { continue }
            let startOfDate = calendar.startOfDay(for: entryDate)

            let displayText: [String]
            if firstDateInterval > 0 && secondDateInterval > 0 {
                let firstClosedDate = Date(timeIntervalSince1970: firstDateInterval)
                let secondClosedDate = Date(timeIntervalSince1970: secondDateInterval)

                let firstDday = calendar.dateComponents([.day], from: startOfDate, to: calendar.startOfDay(for: firstClosedDate)).day ?? 0
                let secondDday = calendar.dateComponents([.day], from: startOfDate, to: calendar.startOfDay(for: secondClosedDate)).day ?? 0

                let firstDateText = firstClosedDate.getMonthDayWeekday()
                let secondDateText = secondClosedDate.getMonthDayWeekday()

                displayText = [
                    String(format: String(localized: "%@ 휴무"), martName),
                    "\(firstDateText.month)\(firstDateText.day) (\(firstDateText.weekday))",
                    firstDday >= 0 ? "D-\(firstDday)" : "D+\(abs(firstDday))",
                    "\(secondDateText.month)\(secondDateText.day) (\(secondDateText.weekday))",
                    secondDday >= 0 ? "D-\(secondDday)" : "D+\(abs(secondDday))",
                    martStorageKey
                ]
            } else {
                @AppStorage(AppStorageKeys.widgetTwoHolidayText, store: defaults)
                var storedString: String = ""
                let holidayText: [String] = storedString.split(separator: "|").map { String($0) }
                displayText = holidayText.isEmpty ? Self.emptyHolidayText : holidayText
            }

            let entry = TwoHolidayEntry(date: startOfDate, configuration: configuration, holidayText: displayText)
            entries.append(entry)
        }

        // 매일 자정에 timeline 재생성 → D-Day가 매일 자동 갱신됨
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(86400)
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        let timeline = Timeline(entries: entries, policy: .after(nextMidnight))
        completion(timeline)
    }
}

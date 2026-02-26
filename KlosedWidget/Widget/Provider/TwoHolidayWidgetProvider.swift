//
//  TwoHolidayWidgetProvider.swift
//  Klosed
//
//  Created by 황석현 on 12/2/24.
//

import SwiftUI
import WidgetKit

struct TwoHoliydayWidgetProvider: IntentTimelineProvider {

    let previewText = ["Klosed Mart","Jan 26 Sun","D-5","Feb 9 Sun","D-19"]
    let emptyHolidayText = ["Store Info", "Data", "D-00", "None", "D-00"]

    func placeholder(in context: Context) -> TwoHolidayEntry {
        TwoHolidayEntry(date: Date(), configuration: ConfigurationIntent(), holidayText: previewText)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (TwoHolidayEntry) -> ()) {
        let entry = TwoHolidayEntry(date: Date(), configuration: configuration, holidayText: previewText)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<TwoHolidayEntry>) -> ()) {
        var entries: [TwoHolidayEntry] = []
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)
        let calendar = Calendar.current

        // 날짜 기반 데이터 읽기
        let firstDateInterval = defaults?.double(forKey: AppStorageKeys.widgetNextClosedDate) ?? 0
        let secondDateInterval = defaults?.double(forKey: AppStorageKeys.widgetSecondClosedDate) ?? 0
        let martName = defaults?.string(forKey: AppStorageKeys.widgetNextClosedMartName) ?? "Mart"
        let martStorageKey = defaults?.string(forKey: AppStorageKeys.widgetMartStorageKey) ?? ""

        let currentDate = Date()
        for dayOffset in 0 ..< 7 {
            let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: currentDate)!
            let startOfDate = calendar.startOfDay(for: entryDate)

            let displayText: [String]
            if firstDateInterval > 0 && secondDateInterval > 0 {
                // 저장된 휴무일 날짜로부터 해당 엔트리 날짜 기준 D-Day를 동적 계산
                let firstClosedDate = Date(timeIntervalSince1970: firstDateInterval)
                let secondClosedDate = Date(timeIntervalSince1970: secondDateInterval)

                let firstDday = calendar.dateComponents([.day], from: startOfDate, to: calendar.startOfDay(for: firstClosedDate)).day ?? 0
                let secondDday = calendar.dateComponents([.day], from: startOfDate, to: calendar.startOfDay(for: secondClosedDate)).day ?? 0

                let firstDateText = firstClosedDate.getMonthDayWeekday()
                let secondDateText = secondClosedDate.getMonthDayWeekday()

                displayText = [
                    "Klosed \(martName)",
                    "\(firstDateText.month)\(firstDateText.day) (\(firstDateText.weekday))",
                    firstDday >= 0 ? "D-\(firstDday)" : "D+\(abs(firstDday))",
                    "\(secondDateText.month)\(secondDateText.day) (\(secondDateText.weekday))",
                    secondDday >= 0 ? "D-\(secondDday)" : "D+\(abs(secondDday))",
                    martStorageKey
                ]
            } else {
                // 날짜 데이터가 없으면 기존 텍스트 기반 fallback
                @AppStorage(AppStorageKeys.widgetTwoHolidayText, store: defaults)
                var storedString: String = ""
                let holidayText: [String] = storedString.split(separator: "|").map { String($0) }
                displayText = holidayText.isEmpty ? emptyHolidayText : holidayText
            }

            let entry = TwoHolidayEntry(date: startOfDate, configuration: configuration, holidayText: displayText)
            entries.append(entry)
        }

        // 다음 날 자정에 위젯 업데이트
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        let timeline = Timeline(entries: entries, policy: .after(nextMidnight))
        completion(timeline)
    }
}

//
//  HolidayProvider.swift
//  Klosed
//
//  Created by 황석현 on 12/2/24.
//

import WidgetKit
import SwiftUI

struct HolidayWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> HolidayEntry {
        HolidayEntry(date: Date(), configuration: ConfigurationIntent(), holidayText: "Tomorrow Klosed")
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (HolidayEntry) -> ()) {
        let entry = HolidayEntry(date: Date(), configuration: configuration, holidayText: "Tomorrow Klosed")
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<HolidayEntry>) -> ()) {
        print("HolidayWidget getTimeline()")
        var entries: [HolidayEntry] = []
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)
        let calendar = Calendar.current

        // 날짜 기반 데이터 읽기
        let closedDateInterval = defaults?.double(forKey: AppStorageKeys.widgetNextClosedDate) ?? 0
        let martName = defaults?.string(forKey: AppStorageKeys.widgetNextClosedMartName) ?? "Mart"

        let currentDate = Date()
        for dayOffset in 0 ..< 7 {
            let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: currentDate)!
            let startOfDate = calendar.startOfDay(for: entryDate)

            let holidayText: String
            if closedDateInterval > 0 {
                // 저장된 휴무일 날짜로부터 해당 엔트리 날짜 기준 D-Day를 동적 계산
                let closedDate = calendar.startOfDay(for: Date(timeIntervalSince1970: closedDateInterval))
                let daysDifference = calendar.dateComponents([.day], from: startOfDate, to: closedDate).day ?? -1

                if daysDifference < 0 {
                    holidayText = "Klosed \(martName)"
                } else if daysDifference == 0 {
                    holidayText = "Klosed \(martName)"
                } else if daysDifference == 1 {
                    holidayText = "Tomorrow Klosed \(martName)"
                } else if daysDifference <= 6 {
                    holidayText = "This week Klosed \(martName)"
                } else {
                    holidayText = "Klosed \(martName)"
                }
            } else {
                // 날짜 데이터가 없으면 기존 텍스트 기반 fallback
                @AppStorage(AppStorageKeys.widgetHolidayText, store: defaults)
                var fallbackText: String = ""
                holidayText = fallbackText.isEmpty ? "Klosed Mart" : fallbackText
            }

            let entry = HolidayEntry(date: startOfDate, configuration: configuration, holidayText: holidayText)
            entries.append(entry)
        }

        // 다음 날 자정에 위젯 업데이트
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        let timeline = Timeline(entries: entries, policy: .after(nextMidnight))
        completion(timeline)
    }
}

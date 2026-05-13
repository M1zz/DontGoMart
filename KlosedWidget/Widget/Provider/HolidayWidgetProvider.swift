//
//  HolidayProvider.swift
//  Klosed
//
//  Created by 황석현 on 12/2/24.
//

import WidgetKit
import SwiftUI

struct HolidayWidgetProvider: IntentTimelineProvider {
    private static let placeholderText = String(localized: "내일 %@ 휴무")
        .replacingOccurrences(of: "%@", with: String(localized: "마트"))

    func placeholder(in context: Context) -> HolidayEntry {
        HolidayEntry(date: Date(), configuration: ConfigurationIntent(), holidayText: Self.placeholderText)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (HolidayEntry) -> ()) {
        let entry = HolidayEntry(date: Date(), configuration: configuration, holidayText: Self.placeholderText)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<HolidayEntry>) -> ()) {
        var entries: [HolidayEntry] = []
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)
        let calendar = Calendar.current

        let closedDateInterval = defaults?.double(forKey: AppStorageKeys.widgetNextClosedDate) ?? 0
        let martName = defaults?.string(forKey: AppStorageKeys.widgetNextClosedMartName) ?? String(localized: "마트")

        let currentDate = Date()
        for dayOffset in 0 ..< 7 {
            guard let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: currentDate) else { continue }
            let startOfDate = calendar.startOfDay(for: entryDate)

            let holidayText: String
            if closedDateInterval > 0 {
                let closedDate = calendar.startOfDay(for: Date(timeIntervalSince1970: closedDateInterval))
                let daysDifference = calendar.dateComponents([.day], from: startOfDate, to: closedDate).day ?? -1

                switch daysDifference {
                case 1:
                    holidayText = String(format: String(localized: "내일 %@ 휴무"), martName)
                case 2...6:
                    holidayText = String(format: String(localized: "이번 주 %@ 휴무"), martName)
                default:
                    holidayText = String(format: String(localized: "%@ 휴무"), martName)
                }
            } else {
                @AppStorage(AppStorageKeys.widgetHolidayText, store: defaults)
                var fallbackText: String = ""
                holidayText = fallbackText.isEmpty ? String(localized: "마트 휴무") : fallbackText
            }

            let entry = HolidayEntry(date: startOfDate, configuration: configuration, holidayText: holidayText)
            entries.append(entry)
        }

        // 매일 자정에 위젯 timeline 재생성 → D-Day가 매일 갱신됨
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(86400)
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        let timeline = Timeline(entries: entries, policy: .after(nextMidnight))
        completion(timeline)
    }
}

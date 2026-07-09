//
//  HolidayProvider.swift
//  DontGoMart
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
        let calendar = Calendar.current
        let currentDate = Date()

        // 16일치 일별 엔트리를 만든다. 각 엔트리는 그 날(startOfDate) 기준으로
        // '오늘 이후 가장 가까운 휴무일' 을 스스로 골라 D-Day 문구를 계산하므로,
        // 하루가 지나면 자동으로 다음 휴무일로 넘어간다.
        for dayOffset in 0 ..< 16 {
            guard let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: currentDate) else { continue }
            let startOfDate = calendar.startOfDay(for: entryDate)

            let holidayText: String
            if let next = WidgetClosedDayStore.upcoming(onOrAfter: startOfDate).first {
                let closedDay = calendar.startOfDay(for: next.date)
                let daysDifference = calendar.dateComponents([.day], from: startOfDate, to: closedDay).day ?? 0
                switch daysDifference {
                case 0:
                    holidayText = String(format: String(localized: "오늘 %@ 휴무"), next.martName)
                case 1:
                    holidayText = String(format: String(localized: "내일 %@ 휴무"), next.martName)
                case 2...6:
                    holidayText = String(format: String(localized: "이번 주 %@ 휴무"), next.martName)
                default:
                    holidayText = String(format: String(localized: "%@ 휴무"), next.martName)
                }
            } else {
                // 다가오는 휴무일 목록이 비어 있음(마트 미선택 등)
                holidayText = String(localized: "마트 휴무")
            }

            let entry = HolidayEntry(date: startOfDate, configuration: configuration, holidayText: holidayText)
            entries.append(entry)
        }

        // 매일 자정에 timeline 재생성 → 목록 갱신 + D-Day 재계산
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(86400)
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        let timeline = Timeline(entries: entries, policy: .after(nextMidnight))
        completion(timeline)
    }
}

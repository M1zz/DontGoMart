//
//  DDayWidgetProvider.swift
//  DontGoMart
//
//  Created by 황석현 on 12/2/24.
//

import Foundation

import WidgetKit

struct DDayWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: Date(), configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (DayEntry) -> ()) {
        let entry = DayEntry(date: Date(), configuration: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<DayEntry>) -> ()) {
        var entries: [DayEntry] = []

        let currentDate = Date()
        for dayOffset in 0 ..< 7 {
            let entryDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: currentDate)!
            let startOfDate = Calendar.current.startOfDay(for: entryDate)
            let entry = DayEntry(date: startOfDate, configuration: configuration)
            entries.append(entry)
        }

        // 다음 날 자정에 위젯 업데이트
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        let nextMidnight = Calendar.current.startOfDay(for: tomorrow)
        let timeline = Timeline(entries: entries, policy: .after(nextMidnight))
        completion(timeline)
    }
}

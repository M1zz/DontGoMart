//
//  HolidayProvider.swift
//  DontGoMart
//
//  Created by 황석현 on 12/2/24.
//

import WidgetKit
import SwiftUI

struct HolidayWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> HolidayEntry {
        HolidayEntry(date: Date(), configuration: ConfigurationIntent(), holidayText: "내일 돈꼬")
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (HolidayEntry) -> ()) {
        let entry = HolidayEntry(date: Date(), configuration: configuration, holidayText: "내일 돈꼬")
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<HolidayEntry>) -> ()) {
        print("HolidayWidget getTimeline()")
        var entries: [HolidayEntry] = []
        @AppStorage(AppStorageKeys.widgetHolidayText, store: UserDefaults(suiteName: Utillity.appGroupId))
        var holidayText: String = ""
        
        let currentDate = Date()
        for dayOffset in 0 ..< 7 {
            let entryDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: currentDate)!
            let startOfDate = Calendar.current.startOfDay(for: entryDate)
            let entry = HolidayEntry(date: startOfDate, configuration: configuration, holidayText: holidayText)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

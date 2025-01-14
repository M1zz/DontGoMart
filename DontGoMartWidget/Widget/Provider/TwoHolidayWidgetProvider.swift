//
//  TwoHolidayWidgetProvider.swift
//  DontGoMart
//
//  Created by 황석현 on 12/2/24.
//

import SwiftUI
import WidgetKit

struct TwoHoliydayWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> TwoHolidayEntry {
        TwoHolidayEntry(date: Date(), configuration: ConfigurationIntent(), holidayText: ["돈꼬 마트","",""])
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (TwoHolidayEntry) -> ()) {
        let entry = TwoHolidayEntry(date: Date(), configuration: configuration, holidayText: ["돈꼬 마트","1월 26일 일요일","2월 9일 일요일"])
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<TwoHolidayEntry>) -> ()) {
        var entries: [TwoHolidayEntry] = []
        
        @AppStorage(AppStorageKeys.widgetTwoHolidayText, store: UserDefaults(suiteName: Utillity.appGroupId))
        var storedString: String = ""
        print("storeString: \(storedString)")
        
        let holidayText: [String] = storedString.split(separator: "|").map { String($0) }
        print("holidayText: \(holidayText)")
        let displayText = holidayText.isEmpty ? ["마트 정보", "데이터", "없음"] : holidayText
        
        let currentDate = Date()
        for dayOffset in 0 ..< 7 {
            let entryDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: currentDate)!
            let startOfDate = Calendar.current.startOfDay(for: entryDate)
            let entry = TwoHolidayEntry(date: startOfDate, configuration: configuration, holidayText: displayText)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

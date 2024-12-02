//
//  CalendarWidget.swift
//  CalendarWidget
//
//  Created by hyunho lee on 2023/06/15.
//

import WidgetKit
import SwiftUI
import Intents

let year = Calendar.current.component(.year, from: Date())

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: Date(), configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (DayEntry) -> ()) {
        let entry = DayEntry(date: Date(), configuration: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [DayEntry] = []
        
        let currentDate = Date()
        for dayOffset in 0 ..< 7 {
            let entryDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: currentDate)!
            let startOfDate = Calendar.current.startOfDay(for: entryDate)
            let entry = DayEntry(date: startOfDate, configuration: configuration)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

let appGroupId = "group.com.leeo.DontGoMart"

struct HolidayWidgetEntryView : View {
    @AppStorage("isNormal", store: UserDefaults(suiteName: appGroupId)) var isCostco: Bool = false
    @AppStorage("selectedBranch", store: UserDefaults(suiteName: appGroupId)) var selectedBranch: Int = 0
    @State private var selectedMartType: MartType = .normal
    
    var entry: DayEntry
    var config: MonthConfig
    var widgetDataMapper: WidgetDataMapper

    // 기본 마트 휴일 목록 정의
    
    // 오늘 날짜로부터 2025년까지의 모든 둘째, 넷째 주 일요일 찾기
    let startDate = Date()

    init(entry: DayEntry) {
        self.entry = entry
        self.config = MonthConfig.determineConfig(from: entry.date)
        self.widgetDataMapper = WidgetDataMapper()
    }
    
    var body: some View {
        VStack {
            // ForEach 구문
            if let holiday = widgetDataMapper.holidayText(selectedMartType: selectedMartType, entryDate: Date()) {
                Text(holiday.text)
                    .font(.title3)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(holiday.color)
                    .multilineTextAlignment(.center)
                    .onChange(of: selectedBranch) {
                        WidgetCenter.shared.reloadTimelines(ofKind: "MonthlyWidget")
                        WidgetCenter.shared.reloadAllTimelines()
                    }
            }
        
            
            HStack(spacing: 0) {
                Text(config.emojiText)
                    .font(.title)
                Text(entry.date.weekdayDisplayFormat)
                    .font(.title3)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(config.weekdayTextColor)
                Spacer()
            }
            
            Text(entry.date.dayDisplayFormat)
                .font(.system(size: 50, weight: .heavy))
                .foregroundColor(config.dayTextColor)
            
        }
        .containerBackground(for: .widget) { // 위젯 배경 모디파이어 추가
            LinearGradient(gradient: Gradient(colors: [config.backgroundColor, config.backgroundColor]), startPoint: .top, endPoint: .bottom)
            
        }
        .onAppear {
            if isCostco {
                if selectedBranch == 1 {
                    selectedMartType = .costco(type: .normal)
                } else if selectedBranch == 2 {
                    selectedMartType = .costco(type: .daegu)
                } else if selectedBranch == 3 {
                    selectedMartType = .costco(type: .ilsan)
                } else if selectedBranch == 4 {
                    selectedMartType = .costco(type: .ulsan)
                }
            } else if !isCostco {
                selectedMartType = .normal
            }
        }
    }
}

struct HolidayWidget: Widget {
    let kind: String = "HolidayWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            HolidayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("휴무알림위젯")
        .description("휴무가 1주일 이내로 가까워지면 알려주는 위젯이에요!")
        .supportedFamilies([.systemSmall])
    }
}

struct CalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        HolidayWidgetEntryView(entry: DayEntry(date: dateToDisplay(month: 7, day: 5), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
    
    static func dateToDisplay(month: Int, day: Int) -> Date {
        let components = DateComponents(calendar: Calendar.current,
                                        year: year, month: month, day: day)
        return Calendar.current.date(from: components)!
    }
}

extension Date {
    var weekdayDisplayFormat: String {
        self.formatted(.dateTime.weekday(.wide))
    }
    
    var dayDisplayFormat: String {
        self.formatted(.dateTime.day())
    }
}


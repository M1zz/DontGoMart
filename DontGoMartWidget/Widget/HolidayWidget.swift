//
//  CalendarWidget.swift
//  CalendarWidget
//
//  Created by hyunho lee on 2023/06/15.
//

import WidgetKit
import SwiftUI
import Intents

struct HolidayWidgetEntryView : View {
    @AppStorage("isNormal", store: UserDefaults(suiteName: Utillity.appGroupId)) var isCostco: Bool = false
    @AppStorage("selectedBranch", store: UserDefaults(suiteName: Utillity.appGroupId)) var selectedBranch: Int = 0
    @State private var selectedMartType: MartType = .normal
    
    var entry: HolidayEntry
    var config: MonthConfig
    var widgetDataMapper: WidgetDataMapper

    init(entry: HolidayEntry) {
        self.entry = entry
        self.config = MonthConfig.determineConfig(from: entry.date)
        self.widgetDataMapper = WidgetDataMapper()
    }
    
    var body: some View {
        VStack {
            Text(entry.holidayText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .onChange(of: selectedBranch) {
                        widgetDataMapper.createMartHolidays()
                        WidgetCenter.shared.reloadTimelines(ofKind: "HolidayWidget")
                        WidgetCenter.shared.reloadAllTimelines()
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
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: HolidayWidgetProvider()) { entry in
            HolidayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("휴무 알림위젯")
        .description("휴무가 1주일 이내로 가까워지면 알려주는 위젯이에요!")
        .supportedFamilies([.systemSmall])
    }
}

struct CalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        HolidayWidgetEntryView(entry: HolidayEntry(date: dateToDisplay(month: 12, day: 31), configuration: ConfigurationIntent(), holidayText: "Preview"))
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


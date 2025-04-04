//
//  TwoHolidayWidget.swift
//  CalendarWidgetExtension
//
//  Created by 황석현 on 12/2/24.
//

import SwiftUI
import WidgetKit

struct TwoHolidayEntryView: View {
    
    var entry: TwoHolidayEntry
    var config: MonthConfig
    let startDate = Date()
    
    init(entry: TwoHolidayEntry) {
        self.entry = entry
        self.config = MonthConfig.determineConfig(from: entry.date)
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text(entry.holidayText[0])
                .font(.title)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)
            
            VStack(alignment: .leading) {
                Text(entry.holidayText[1])
                    .fontWeight(.bold)
                Text(entry.holidayText[2])
                    .fontWeight(.bold)
                    .padding(.bottom, 5)
            }
            
            VStack(alignment: .leading) {
                Text(entry.holidayText[3])
                    .fontWeight(.bold)
                Text(entry.holidayText[4])
                    .fontWeight(.bold)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(gradient: Gradient(colors: [config.backgroundColor, config.backgroundColor]), startPoint: .top, endPoint: .bottom)
        }
    }
}

struct TwoHolidayWidget: Widget {
    let kind = "TwoHoliday"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: TwoHoliydayWidgetProvider()) { entry in
            TwoHolidayEntryView(entry: entry)
        }
        .configurationDisplayName("2개의 휴무일 위젯")
        .description("다다음 휴무일까지 보여주는 위젯이에요!")
        .supportedFamilies([.systemSmall])
    }
}

struct TwoHolidayWidgetPreviews: PreviewProvider {
    static var previews: some View {
        TwoHolidayEntryView(entry: TwoHolidayEntry(date: Date(), configuration: ConfigurationIntent(), holidayText: ["돈꼬 마트","1월 26일 일요일","D-5","2월 9일 일요일","D-19"]))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

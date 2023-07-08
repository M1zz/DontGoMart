//
//  CalendarWidget.swift
//  CalendarWidget
//
//  Created by hyunho lee on 2023/06/15.
//

import WidgetKit
import SwiftUI
import Intents

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


struct DayEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}


struct MartHolyday: Hashable {
    let month: Int
    let day: Int
}
struct CalendarWidgetEntryView : View {
    var entry: DayEntry
    var config: MonthConfig
    
    var data = [MartHolyday(month: 6, day: 25),
                MartHolyday(month: 7, day: 9),
                MartHolyday(month: 7, day: 23),
                MartHolyday(month: 8, day: 13),
                MartHolyday(month: 8, day: 27),
                MartHolyday(month: 9, day: 10),
                MartHolyday(month: 9, day: 24),
                MartHolyday(month: 10, day: 8),
                MartHolyday(month: 10, day: 22),
                MartHolyday(month: 11, day: 12),
                MartHolyday(month: 11, day: 26),
                MartHolyday(month: 12, day: 10),
                MartHolyday(month: 12, day: 24)
    ]
    
    init(entry: DayEntry) {
        self.entry = entry
        self.config = MonthConfig.determineConfig(from: entry.date)
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(config.backgroundColor.gradient)
            VStack {
                ForEach(data, id: \.self) { datum in
                    if entry.date == dateToDisplay(month: datum.month, day: datum.day) {
                        Text("Don't go mart")
                            .font(.title3)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.red)
                    } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 1) {
                        Text("Don't go mart\ntomorrow")
                            .font(.title3)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.palePink)
                            .multilineTextAlignment(.center)
                    } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 2) ||
                              entry.date == dateToDisplay(month: datum.month, day: datum.day - 3) ||
                                entry.date == dateToDisplay(month: datum.month, day: datum.day - 4) ||
                                entry.date == dateToDisplay(month: datum.month, day: datum.day - 5) ||
                                entry.date == dateToDisplay(month: datum.month, day: datum.day - 6) {
                        Text("Don't go mart\nweekend")
                            .font(.title3)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.palePink)
                            .multilineTextAlignment(.center)
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
            .padding()
        }
    }
    
    func dateToDisplay(month: Int, day: Int) -> Date {
        let components = DateComponents(calendar: Calendar.current,
                                        year: 2023, month: month, day: day)
        return Calendar.current.date(from: components)!
    }
}

struct CalendarWidget: Widget {
    let kind: String = "MonthlyWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            CalendarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Monthly Style Widget")
        .description("The theme of the widget changes based on month.")
        .supportedFamilies([.systemSmall])
    }
}

struct CalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        CalendarWidgetEntryView(entry: DayEntry(date: dateToDisplay(month: 7, day: 5), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
    
    static func dateToDisplay(month: Int, day: Int) -> Date {
        let components = DateComponents(calendar: Calendar.current,
                                        year: 2023, month: month, day: day)
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

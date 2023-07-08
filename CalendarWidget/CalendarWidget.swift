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


struct MartHolyday: Hashable, Codable {
    let month: Int
    let day: Int
    let martType: MartType
}

enum MartType: Codable {
    case normal
    case costcoNormal
    case costcoDaegu
    case costcoIlsan
    case costcoUlsan
}

struct CalendarWidgetEntryView : View {
    @AppStorage("isNormal", store: UserDefaults(suiteName: "group.com.leeo.DontGoMart")) var isCostco: Bool = false
    @AppStorage("selectedLocation", store: UserDefaults(suiteName: "group.com.leeo.DontGoMart")) var selectedLocation: Int = 0
    @State private var selectedMartType: MartType = .costcoNormal
    
    var entry: DayEntry
    var config: MonthConfig
    
    var data = [MartHolyday(month: 6, day: 25, martType: .normal),
                MartHolyday(month: 7, day: 9, martType: .normal),
                MartHolyday(month: 7, day: 23, martType: .normal),
                MartHolyday(month: 8, day: 13, martType: .normal),
                MartHolyday(month: 8, day: 27, martType: .normal),
                MartHolyday(month: 9, day: 10, martType: .normal),
                MartHolyday(month: 9, day: 24, martType: .normal),
                MartHolyday(month: 10, day: 8, martType: .normal),
                MartHolyday(month: 10, day: 22, martType: .normal),
                MartHolyday(month: 11, day: 12, martType: .normal),
                MartHolyday(month: 11, day: 26, martType: .normal),
                MartHolyday(month: 12, day: 10, martType: .normal),
                MartHolyday(month: 12, day: 24, martType: .normal),
                
                // Costco
                
                MartHolyday(month: 7, day: 9, martType: .costcoNormal),
                MartHolyday(month: 7, day: 10, martType: .costcoDaegu),
                MartHolyday(month: 7, day: 12, martType: .costcoIlsan),
                MartHolyday(month: 7, day: 12, martType: .costcoUlsan),
                MartHolyday(month: 7, day: 23, martType: .costcoNormal),
                MartHolyday(month: 7, day: 23, martType: .costcoUlsan),
                MartHolyday(month: 7, day: 24, martType: .costcoDaegu),
                MartHolyday(month: 7, day: 26, martType: .costcoIlsan)
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
                    if selectedMartType == .normal {
                        if entry.date == dateToDisplay(month: datum.month, day: datum.day),
                           datum.martType == .normal {
                            Text("Don't go mart")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.red)
                        } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 1),
                                  datum.martType == .normal {
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
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 6),
                                  datum.martType == .normal {
                            Text("Don't go mart\nweekend")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.palePink)
                                .multilineTextAlignment(.center)
                        }
                    } else if selectedMartType == .costcoNormal {
                        
                        if entry.date == dateToDisplay(month: datum.month, day: datum.day),
                           datum.martType == .costcoNormal {
                            Text("Don't go costco")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.red)
                        } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 1),
                                  datum.martType == .costcoNormal {
                            Text("Don't go costco\ntomorrow")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.palePink)
                                .multilineTextAlignment(.center)
                        } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 2) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 3) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 4) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 5) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 6),
                                  datum.martType == .costcoNormal  {
                            Text("Don't go costco\nweekend")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.palePink)
                                .multilineTextAlignment(.center)
                            
                        }
                    }
                    else if selectedMartType == .costcoDaegu {
                        if entry.date == dateToDisplay(month: datum.month, day: datum.day),
                           datum.martType == .costcoDaegu {
                            Text("Don't go costco")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.red)
                        } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 1),
                                  datum.martType == .costcoDaegu {
                            Text("Don't go costco\ntomorrow")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.palePink)
                                .multilineTextAlignment(.center)
                        } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 2) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 3) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 4) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 5) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 6),
                                  datum.martType == .costcoDaegu  {
                            Text("Don't go costco\nweekend")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.palePink)
                                .multilineTextAlignment(.center)
                            
                        }
                    } else if selectedMartType == .costcoIlsan {
                        if entry.date == dateToDisplay(month: datum.month, day: datum.day),
                           datum.martType == .costcoIlsan {
                            Text("Don't go costco")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.red)
                        } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 1),
                                  datum.martType == .costcoIlsan {
                            Text("Don't go costco\ntomorrow")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.palePink)
                                .multilineTextAlignment(.center)
                        } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 2) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 3) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 4) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 5) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 6),
                                  datum.martType == .costcoIlsan  {
                            Text("Don't go costco\nweekend")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.palePink)
                                .multilineTextAlignment(.center)
                            
                        }
                    } else if selectedMartType == .costcoUlsan {
                        if entry.date == dateToDisplay(month: datum.month, day: datum.day),
                           datum.martType == .costcoUlsan {
                            Text("Don't go costco")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.red)
                        } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 1),
                                  datum.martType == .costcoUlsan {
                            Text("Don't go costco\ntomorrow")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.palePink)
                                .multilineTextAlignment(.center)
                        } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 2) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 3) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 4) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 5) ||
                                    entry.date == dateToDisplay(month: datum.month, day: datum.day - 6),
                                  datum.martType == .costcoUlsan  {
                            Text("Don't go costco\nweekend")
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.palePink)
                                .multilineTextAlignment(.center)
                            
                        }
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
        .onAppear {
            print(isCostco.description)
            if isCostco {
                if selectedLocation == 0 {
                    selectedMartType = .costcoNormal
                } else if selectedLocation == 1 {
                    selectedMartType = .costcoDaegu
                } else if selectedLocation == 2 {
                    selectedMartType = .costcoIlsan
                } else if selectedLocation == 3 {
                    selectedMartType = .costcoUlsan
                }
            } else if !isCostco {
                selectedMartType = .normal
            }
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

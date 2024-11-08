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
    
    // MartHoliday 타입의 데이터를 초기화하는 함수 정의
    func createMartHolidays(monthDayPairs: [(Int, Int)], martType: MartType) -> [MartHolyday] {
        return monthDayPairs.map { MartHolyday(month: $0.0, day: $0.1, martType: martType) }
    }

    // 기본 마트 휴일 목록 정의
    var data: [MartHolyday] = []

    // 격주 일요일 추출기
    func findSecondAndFourthSundaysAsMonthDayPairs(from startDate: Date, to endYear: Int) -> [(Int, Int)] {
        var results: [(Int, Int)] = []
        let calendar = Calendar.current

        // 시작 날짜의 연도와 월
        let startComponents = calendar.dateComponents([.year, .month], from: startDate)
        guard let startYear = startComponents.year, let startMonth = startComponents.month else { return results }
        
        for year in startYear...endYear {
            for month in (year == startYear ? startMonth : 1)...12 {
                // 둘째 주 일요일 찾기
                var dateComponents = DateComponents(year: year, month: month, weekday: 1, weekdayOrdinal: 2)
                if let secondSunday = calendar.date(from: dateComponents) {
                    let secondSundayDay = calendar.component(.day, from: secondSunday)
                    results.append((month, secondSundayDay))
                }
                
                // 넷째 주 일요일 찾기
                dateComponents.weekdayOrdinal = 4
                if let fourthSunday = calendar.date(from: dateComponents) {
                    let fourthSundayDay = calendar.component(.day, from: fourthSunday)
                    results.append((month, fourthSundayDay))
                }
            }
        }
        
        return results
    }
    
    // 격주 월요일 추출기
    func findSecondAndFourthMondaysAsMonthDayPairs(from startDate: Date, to endYear: Int) -> [(Int, Int)] {
        var results: [(Int, Int)] = []
        let calendar = Calendar.current

        // 시작 날짜의 연도와 월
        let startComponents = calendar.dateComponents([.year, .month], from: startDate)
        guard let startYear = startComponents.year, let startMonth = startComponents.month else { return results }
        
        for year in startYear...endYear {
            for month in (year == startYear ? startMonth : 1)...12 {
                // 둘째 주 월요일 찾기
                var dateComponents = DateComponents(year: year, month: month, weekday: 2, weekdayOrdinal: 2)
                if let secondMonday = calendar.date(from: dateComponents) {
                    let secondMondayDay = calendar.component(.day, from: secondMonday)
                    results.append((month, secondMondayDay))
                }
                
                // 넷째 주 월요일 찾기
                dateComponents.weekdayOrdinal = 4
                if let fourthMonday = calendar.date(from: dateComponents) {
                    let fourthMondayDay = calendar.component(.day, from: fourthMonday)
                    results.append((month, fourthMondayDay))
                }
            }
        }
        
        return results
    }
    
    // 격주 수요일 추출기
    func findSecondAndFourthWednesdaysAsMonthDayPairs(from startDate: Date, to endYear: Int) -> [(Int, Int)] {
        var results: [(Int, Int)] = []
        let calendar = Calendar.current

        // 시작 날짜의 연도와 월
        let startComponents = calendar.dateComponents([.year, .month], from: startDate)
        guard let startYear = startComponents.year, let startMonth = startComponents.month else { return results }
        
        for year in startYear...endYear {
            for month in (year == startYear ? startMonth : 1)...12 {
                // 둘째 주 수요일 찾기
                var dateComponents = DateComponents(year: year, month: month, weekday: 4, weekdayOrdinal: 2)
                if let secondWednesday = calendar.date(from: dateComponents) {
                    let secondWednesdayDay = calendar.component(.day, from: secondWednesday)
                    results.append((month, secondWednesdayDay))
                }
                
                // 넷째 주 수요일 찾기
                dateComponents.weekdayOrdinal = 4
                if let fourthWednesday = calendar.date(from: dateComponents) {
                    let fourthWednesdayDay = calendar.component(.day, from: fourthWednesday)
                    results.append((month, fourthWednesdayDay))
                }
            }
        }
        
        return results
    }

    // 2째주 수요일 4째주 일요일 추출기
    func findSecondWednesdayAndFourthSundayAsMonthDayPairs(from startDate: Date, to endYear: Int) -> [(Int, Int)] {
        var results: [(Int, Int)] = []
        let calendar = Calendar.current

        // 시작 날짜의 연도와 월
        let startComponents = calendar.dateComponents([.year, .month], from: startDate)
        guard let startYear = startComponents.year, let startMonth = startComponents.month else { return results }
        
        for year in startYear...endYear {
            for month in (year == startYear ? startMonth : 1)...12 {
                // 둘째 주 수요일 찾기
                var dateComponents = DateComponents(year: year, month: month, weekday: 4, weekdayOrdinal: 2) // 수요일은 weekday 4
                if let secondWednesday = calendar.date(from: dateComponents) {
                    let secondWednesdayDay = calendar.component(.day, from: secondWednesday)
                    results.append((month, secondWednesdayDay))
                }
                
                // 넷째 주 일요일 찾기
                dateComponents.weekday = 1 // 일요일은 weekday 1
                dateComponents.weekdayOrdinal = 4
                if let fourthSunday = calendar.date(from: dateComponents) {
                    let fourthSundayDay = calendar.component(.day, from: fourthSunday)
                    results.append((month, fourthSundayDay))
                }
            }
        }
        
        return results
    }
    
    // 오늘 날짜로부터 2025년까지의 모든 둘째, 넷째 주 일요일 찾기
    let startDate = Date()

    init(entry: DayEntry) {
        self.entry = entry
        self.config = MonthConfig.determineConfig(from: entry.date)
        
        data += createMartHolidays(monthDayPairs: findSecondAndFourthSundaysAsMonthDayPairs(from: startDate, to: 2024), martType: .normal)

        // 코스트코 일반 휴일 데이터 추가
        data += createMartHolidays(monthDayPairs: findSecondAndFourthSundaysAsMonthDayPairs(from: startDate, to: 2024), martType: .costcoNormal)


        // 코스트코 대구점 휴일 데이터 추가
        data += createMartHolidays(monthDayPairs: findSecondAndFourthMondaysAsMonthDayPairs(from: startDate, to: 2024), martType: .costcoDaegu)

        // 코스트코 일산점 휴일 데이터 추가
        data += createMartHolidays(monthDayPairs: findSecondAndFourthMondaysAsMonthDayPairs(from: startDate, to: 2024), martType: .costcoIlsan)

        // 코스트코 울산점 휴일 데이터 추가
        data += createMartHolidays(monthDayPairs: findSecondWednesdayAndFourthSundayAsMonthDayPairs(from: startDate, to: 2024), martType: .costcoUlsan)
        
        
        print(data)
    }
    
    var body: some View {
        VStack {
            ForEach(data, id: \.self) { datum in
                if selectedMartType == .normal {
                    if entry.date == dateToDisplay(month: datum.month, day: datum.day),
                       datum.martType == .normal {
                        Text("돈꼬마트")
                            .font(.title3)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.red)
                    } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 1),
                              datum.martType == .normal {
                        Text("내일 돈꼬마트")
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
                        Text("이번 주 돈꼬마트")
                            .font(.title3)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.palePink)
                            .multilineTextAlignment(.center)
                    }
                } else if selectedMartType == .costcoNormal {
                    
                    if entry.date == dateToDisplay(month: datum.month, day: datum.day),
                       datum.martType == .costcoNormal {
                        Text("돈꼬 코스트코")
                            .font(.title3)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.red)
                    } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 1),
                              datum.martType == .costcoNormal {
                        Text("내일 돈꼬 코스트코")
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
                        Text("이번 주 돈꼬 코스트코")
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
                        Text("돈꼬 코스트코")
                            .font(.title3)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.red)
                    } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 1),
                              datum.martType == .costcoDaegu {
                        Text("내일 돈꼬 코스트코")
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
                        Text("월요일 돈꼬 코스트코")
                            .font(.title3)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.palePink)
                            .multilineTextAlignment(.center)
                        
                    }
                } else if selectedMartType == .costcoIlsan {
                    if entry.date == dateToDisplay(month: datum.month, day: datum.day),
                       datum.martType == .costcoIlsan {
                        Text("돈꼬 코스트코")
                            .font(.title3)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.red)
                    } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 1),
                              datum.martType == .costcoIlsan {
                        Text("내일 돈꼬 코스트코")
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
                        Text("수요일 돈꼬 코스트코")
                            .font(.title3)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.palePink)
                            .multilineTextAlignment(.center)
                        
                    }
                } else if selectedMartType == .costcoUlsan {
                    if entry.date == dateToDisplay(month: datum.month, day: datum.day),
                       datum.martType == .costcoUlsan {
                        Text("돈꼬 코스트코")
                            .font(.title3)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.red)
                    } else if entry.date == dateToDisplay(month: datum.month, day: datum.day - 1),
                              datum.martType == .costcoUlsan {
                        Text("내일 돈꼬 코스트코")
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
                        Text("곧 돈꼬 코스트코")
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
        .containerBackground(for: .widget) { // 위젯 배경 모디파이어 추가
            LinearGradient(gradient: Gradient(colors: [config.backgroundColor, config.backgroundColor]), startPoint: .top, endPoint: .bottom)
            
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
                                        year: 2024, month: month, day: day)
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
                                        year: 2024, month: month, day: day)
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

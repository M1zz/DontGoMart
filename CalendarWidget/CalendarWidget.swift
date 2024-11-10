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

struct CalendarWidgetEntryView : View {
    @AppStorage("isNormal", store: UserDefaults(suiteName: appGroupId)) var isCostco: Bool = false
    @AppStorage("selectedBranch", store: UserDefaults(suiteName: appGroupId)) var selectedBranch: Int = 0
    @State private var selectedMartType: MartType = .costcoNormal
    
    var entry: DayEntry
    var config: MonthConfig
    
    // MartHoliday 타입의 데이터를 초기화하는 함수 정의
    func createMartHolidays(monthDayPairs: [(Int, Int)], martType: MartType) -> [MartHoliday] {
        return monthDayPairs.map { MartHoliday(month: $0.0, day: $0.1, martType: martType) }
    }

    // 기본 마트 휴일 목록 정의
    var data: [MartHoliday] = []
    
    private func generateBiweeklyTasks(forYear year: Int, weekdays: [(Calendar.Weekday, Calendar.Ordinal, String)], martType: MartType) -> [MartHoliday] {
        var tasks: [MartHoliday] = []
        let calendar = Calendar.current

        // 각 요일과 주차에 대해 날짜 찾기
        for (weekday, ordinal, title) in weekdays {
            for month in 1...12 {
                var dateComponents = DateComponents(year: year, month: month, weekday: weekday.rawValue, weekdayOrdinal: ordinal.rawValue)
                if let date = calendar.date(from: dateComponents) {
                    let day = calendar.component(.day, from: date)
                    tasks.append(MartHoliday(month: month, day: day, martType: martType))
                }
            }
        }
        
        return tasks
    }
    
    // 오늘 날짜로부터 2025년까지의 모든 둘째, 넷째 주 일요일 찾기
    let startDate = Date()

    init(entry: DayEntry) {
        self.entry = entry
        self.config = MonthConfig.determineConfig(from: entry.date)
        
        // 마트 휴일 생성 (일반 마트, 코스트코 휴일 데이터)
        data += generateBiweeklyTasks(
            forYear: year,
            weekdays: [
                (.sunday, .second, "2번째 일요일"),
                (.sunday, .fourth, "4번째 일요일")
            ],
            martType: .normal
        )
        
        data += generateBiweeklyTasks(
            forYear: year,
            weekdays: [
                (.sunday, .second, "2번째 일요일"),
                (.sunday, .fourth, "4번째 일요일")
            ],
            martType: .costcoNormal
        )
        
        data += generateBiweeklyTasks(
            forYear: year,
            weekdays: [
                (.monday, .second, "2번째 월요일"),
                (.monday, .fourth, "4번째 월요일")
            ],
            martType: .costcoDaegu
        )
        
        data += generateBiweeklyTasks(
            forYear: year,
            weekdays: [
                (.wednesday, .second, "2번째 수요일"),
                (.wednesday, .fourth, "4번째 수요일")
            ],
            martType: .costcoIlsan
        )
        
        data += generateBiweeklyTasks(
            forYear: year,
            weekdays: [
                (.wednesday, .second, "2번째 수요일"),
                (.sunday, .fourth, "4번째 일요일")
            ],
            martType: .costcoUlsan
        )
    }
    
    var body: some View {
        VStack {
            // ForEach 구문
            ForEach(data, id: \.self) { datum in
                if let holiday = holidayText(for: datum, selectedMartType: selectedMartType, entryDate: entry.date) {
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
                    selectedMartType = .costcoNormal
                } else if selectedBranch == 2 {
                    selectedMartType = .costcoDaegu
                } else if selectedBranch == 3 {
                    selectedMartType = .costcoIlsan
                } else if selectedBranch == 4 {
                    selectedMartType = .costcoUlsan
                }
            } else if !isCostco {
                selectedMartType = .normal
            }
            print("?",selectedBranch)
        }
    }
    
    func holidayText(for datum: MartHoliday, selectedMartType: MartType, entryDate: Date) -> (text: String, color: Color)? {
        let displayDate = dateToDisplay(month: datum.month, day: datum.day)
        guard datum.martType == selectedMartType else { return nil }
        
        // daysDifference 계산
        if let daysDifference = Calendar.current.dateComponents([.day], from: entryDate, to: displayDate).day {
            switch daysDifference {
            case 0:
                return ("돈꼬 \(selectedMartType.displayName)", .red)
            case -1:
                return ("내일 돈꼬 \(selectedMartType.displayName)", .palePink)
            case -6...(-2):
                let dayText: String
                switch selectedMartType {
                case .costcoDaegu: dayText = "월요일"
                case .costcoIlsan: dayText = "수요일"
                case .costcoUlsan: dayText = "곧"
                default: dayText = "이번 주"
                }
                return ("\(dayText) 돈꼬 \(selectedMartType.displayName)", .palePink)
            default:
                return nil
            }
        }
        
        return nil
    }

    
    func dateToDisplay(month: Int, day: Int) -> Date {
        let components = DateComponents(calendar: Calendar.current,
                                        year: year, month: month, day: day)
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


/// Model
struct DayEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}


struct MartHoliday: Hashable, Codable {
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
    
    var displayName: String {
        switch self {
        case .normal: return "마트"
        case .costcoNormal, .costcoDaegu, .costcoIlsan, .costcoUlsan: return "코스트코"
        }
    }
}

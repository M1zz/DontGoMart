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
    @State private var selectedMartType: MartType = .normal
    
    var entry: DayEntry
    var config: MonthConfig
    
    // MartHoliday 타입의 데이터를 초기화하는 함수 정의
    func createMartHolidays(monthDayPairs: [(Int, Int)], martType: MartType) -> [MartHoliday] {
        return monthDayPairs.map { MartHoliday(month: $0.0, day: $0.1, martType: martType) }
    }

    // 기본 마트 휴일 목록 정의
    var data: [MartHoliday] = []
    
    private func nthWeekdayOfYear(forYear year: Int, weekday: Calendar.Weekday, nth: Int) -> [Date?] {
        var dates: [Date?] = []
        
        for month in 1...12 {
            if let nthWeekdayDate = nthWeekday(forYear: year, month: month, weekday: weekday, nth: nth) {
                dates.append(nthWeekdayDate)
            } else {
                dates.append(nil)  // 해당 달에 nth 번째 요일이 없는 경우
            }
        }
        
        return dates
    }
    
    // 한 달의 N번째 특정 요일을 찾는 함수 (참고용)
    private func nthWeekday(forYear year: Int, month: Int, weekday: Calendar.Weekday, nth: Int) -> Date? {
        guard nth > 0 else { return nil }  // nth가 1 이상이어야 함
        
        let calendar = Calendar.current
        var dateComponents = DateComponents(year: year, month: month)
        dateComponents.weekday = weekday.rawValue
        
        var foundWeekdays: [Date] = []
        
        // 1일부터 시작해서 지정한 요일을 찾아 리스트에 추가
        for day in 1...28 {  // 최대 4번째 요일은 28일 내에 발생
            dateComponents.day = day
            if let date = calendar.date(from: dateComponents),
               calendar.component(.weekday, from: date) == weekday.rawValue {
                foundWeekdays.append(date)
                if foundWeekdays.count == nth {  // n번째 요일까지 찾으면 중단
                    return date
                }
            }
        }
        
        return nil  // nth번째 요일이 없는 경우
    }

    // N번째 특정 요일에 따른 MartHoliday 배열 생성 함수
    func generateMartHolidays(forYear year: Int, weekday: Calendar.Weekday, nth: Int, martType: MartType) -> [MartHoliday] {
        let dates = nthWeekdayOfYear(forYear: year, weekday: weekday, nth: nth)
        var holidays: [MartHoliday] = []
        let calendar = Calendar.current
        
        for (monthIndex, date) in dates.enumerated() {
            if let date = date {
                let day = calendar.component(.day, from: date)
                let holiday = MartHoliday(month: monthIndex + 1, day: day, martType: martType)
                holidays.append(holiday)
            }
        }
        
        return holidays
    }
    
    // 오늘 날짜로부터 2025년까지의 모든 둘째, 넷째 주 일요일 찾기
    let startDate = Date()

    init(entry: DayEntry) {
        self.entry = entry
        self.config = MonthConfig.determineConfig(from: entry.date)
        
        // 마트 휴일 생성 (일반 마트, 코스트코 휴일 데이터)
        data = []
        
        let weekday = Calendar.Weekday.sunday
        data += generateMartHolidays(forYear: year, weekday: .sunday, nth: 2, martType: .normal)
        data += generateMartHolidays(forYear: year, weekday: .sunday, nth: 4, martType: .normal)
        
        
        data += generateMartHolidays(forYear: year, weekday: .monday, nth: 2, martType: .costco(type: .daegu))
        data += generateMartHolidays(forYear: year, weekday: .monday, nth: 4, martType: .costco(type: .daegu))
        
        
        data += generateMartHolidays(forYear: year, weekday: .wednesday, nth: 2, martType: .costco(type: .ilsan))
        data += generateMartHolidays(forYear: year, weekday: .wednesday, nth: 4, martType: .costco(type: .ilsan))
        
        
        data += generateMartHolidays(forYear: year, weekday: .wednesday, nth: 2, martType: .costco(type: .ulsan))
        data += generateMartHolidays(forYear: year, weekday: .sunday, nth: 4, martType: .costco(type: .ulsan))
        
    }
    
    var body: some View {
        VStack {
            // ForEach 구문
            if let holiday = holidayText(selectedMartType: selectedMartType, entryDate: Date()) {
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
    
    func holidayText(selectedMartType: MartType, entryDate: Date) -> (text: String, color: Color)? {
        let costcoHolidays = data.filter { $0.martType == selectedMartType }
        print("======================")
        for datum in costcoHolidays {
            print(costcoHolidays)

            
            let displayDate = dateToDisplay(month: datum.month, day: datum.day)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let formattedDate = dateFormatter.string(from: displayDate)
            let finalDate = dateFormatter.date(from: formattedDate)!
            
            guard datum.martType == selectedMartType else { return nil }
                        
            // daysDifference 계산
            if let daysDifference = Calendar.current.dateComponents([.day], from: entryDate, to: finalDate).day {
                print("daysDifference", daysDifference, entryDate.description, displayDate)
                switch daysDifference {
                case 0:
                    print("0")
                    return ("돈꼬 \(selectedMartType.widgetDisplayName)", .red)
                case 1:
                    print("1")
                    return ("내일 돈꼬 \(selectedMartType.widgetDisplayName)", .palePink)
                case 2...6:
                    print("2")
                    let dayText: String
                    switch selectedMartType {
                    case .costco(type: .daegu): dayText = "월요일"
                    case .costco(type: .ilsan): dayText = "수요일"
                    case .costco(type: .ulsan): dayText = "곧"
                    default: dayText = "이번 주"
                    }
                    return ("\(dayText) 돈꼬 \(selectedMartType.widgetDisplayName)", .palePink)
                default:
                    continue
                }
            }
        }
        
        
        return nil
    }

    
    func dateToDisplay(month: Int, day: Int) -> Date {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentHour = calendar.component(.hour, from: currentDate)
        let currentMinute = calendar.component(.minute, from: currentDate)
        let currentSecond = calendar.component(.second, from: currentDate)
        var dateComponents = DateComponents()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        
        
        
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = currentHour + 9 + 15
        dateComponents.minute = currentMinute
        dateComponents.second = currentSecond
        
        // 날짜 생성
        if let date = calendar.date(from: dateComponents) {
            return date
        }
        return Date()
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


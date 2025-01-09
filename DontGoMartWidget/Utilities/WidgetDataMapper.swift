//
//  WidgetDataMapper.swift
//  DontGoMart
//
//  Created by 황석현 on 12/2/24.
//

import SwiftUI
import WidgetKit

struct HolidayEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let holidayText: String
}

struct DayEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct TwoHolidayEntry: TimelineEntry {
    var date: Date
    let configuration: ConfigurationIntent
    let holidayText: [String]
}

class WidgetDataMapper {
    
    var data: [MartHoliday] = []
    
    // 마트 휴일 생성 (일반 마트, 코스트코 휴일 데이터)
    func createMartHolidays() {
        print("createMartHolidays")
        data = []
        data += modifiedGenerateMartHolidays()
    }
    
    
    func modifiedGenerateMartHolidays() -> [MartHoliday] {
        let calendar = Calendar.current
        var holidays: [MartHoliday] = []
        
        for task in tasks {
            let month = calendar.component(.month, from: task.taskDate)
            let day = calendar.component(.day, from: task.taskDate)
            let holiday = MartHoliday(type: task.type, month: month, day: day)
            holidays.append(holiday)
        }
        
        return holidays
    }
    
    // N번째 특정 요일에 따른 MartHoliday 배열 생성 함수
    func generateMartHolidays(forYear year: Int, weekday: Calendar.Weekday, nth: Int, martType: MartType) -> [MartHoliday] {
        // n번째 요일을 저장
        let dates = nthWeekdayOfYear(forYear: year, weekday: weekday, nth: nth)
        var holidays: [MartHoliday] = []
        let calendar = Calendar.current
        
        for (monthIndex, date) in dates.enumerated() {
            if let date = date {
                let day = calendar.component(.day, from: date)
                let holiday = MartHoliday(type: martType, month: monthIndex + 1, day: day)
                holidays.append(holiday)
            }
        }
        
        return holidays
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
    
    private func nthWeekdayOfYear(forYear year: Int, weekday: Calendar.Weekday, nth: Int) -> [Date?] {
        var dates: [Date?] = []
        
        for month in 1...12 {
            // 한 달에 N번쨰 특정 요일을 찾는 함수
            if let nthWeekdayDate = nthWeekday(forYear: year, month: month, weekday: weekday, nth: nth) {
                dates.append(nthWeekdayDate)
            } else {
                dates.append(nil)  // 해당 달에 nth 번째 요일이 없는 경우
            }
        }
        
        return dates
    }
    
    // MartHoliday 타입의 데이터를 초기화하는 함수 정의
    func createMartHolidays(monthDayPairs: [(Int, Int)], martType: MartType) -> [MartHoliday] {
        return monthDayPairs.map { MartHoliday(type: martType, month: $0.0, day: $0.1) }
    }
    
    func holidayText(selectedMartType: MartType, entryDate: Date) -> (text: String, color: Color)? {
        print("======================")
        let costcoHolidays = data.filter { $0.type == selectedMartType }
        for datum in costcoHolidays {
            print(costcoHolidays)

            
            let displayDate = dateToDisplay(month: datum.month, day: datum.day)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let formattedDate = dateFormatter.string(from: displayDate)
            let finalDate = dateFormatter.date(from: formattedDate)!
            
            guard datum.type == selectedMartType else { return nil }
                        
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
                case 2...20:
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
            } else { print("DaysDifference Error")}
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

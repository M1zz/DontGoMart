//
//  Untitled.swift
//  DontGoMart
//
//  Created by hyunho lee on 11/9/24.
//

import Foundation

extension Date {
    
    var dayDisplayFormat: String { self.formatted(.dateTime.day()) }
    
    var weekdayDisplayFormat: String { self.formatted(.dateTime.weekday(.wide)) }
    
    func getAllDates() -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: Calendar.current.dateComponents([.year,.month], from: self))!
        let range = calendar.range(of: .day, in: .month, for: startDate)!
        return range.compactMap { day -> Date in
            return calendar.date(byAdding: .day, value: day - 1, to: startDate)!
        }
    }
    
    func getMonthDayWeekday() -> (month: String, day: String, weekday: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR") // 한국어 설정
        
        // 월
        formatter.dateFormat = "M월"
        let month = formatter.string(from: self)
        
        // 일
        formatter.dateFormat = "d일"
        let day = formatter.string(from: self)
        
        // 요일
        formatter.dateFormat = "EEEE"
        let weekday = formatter.string(from: self)
        
        return (month, day, weekday)
    }
    
    func dateToDisplay(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(calendar: Calendar.current,
                                        year: year,
                                        month: month,
                                        day: day)
        return Calendar.current.date(from: components) ?? Date()
    }
}

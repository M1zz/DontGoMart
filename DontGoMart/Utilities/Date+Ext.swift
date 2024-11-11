//
//  Untitled.swift
//  DontGoMart
//
//  Created by hyunho lee on 11/9/24.
//

import Foundation

extension Date {
    func getAllDates() -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: Calendar.current.dateComponents([.year,.month], from: self))!
        let range = calendar.range(of: .day, in: .month, for: startDate)!
        return range.compactMap { day -> Date in
            return calendar.date(byAdding: .day, value: day - 1, to: startDate)!
        }
    }
}

func dateToDisplay(year: Int = year, month: Int, day: Int) -> Date {
    let components = DateComponents(calendar: Calendar.current,
                                    year: year,
                                    month: month,
                                    day: day)
    return Calendar.current.date(from: components) ?? Date()
}

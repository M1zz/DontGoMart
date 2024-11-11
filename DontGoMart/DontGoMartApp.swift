//
//  DontGoMartApp.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/15.
//

import SwiftUI

let year = Calendar.current.component(.year, from: Date())

@main
struct DontGoMartApp: App {
    
    var body: some Scene {
        WindowGroup {
            ClosedDaysView()
                .onAppear {
                    tasks.append(contentsOf: generateBiweeklyTasks(
                        forYear: year,
                        weekdays: [
                            (.sunday, .second, "2번째 일요일"),
                            (.sunday, .fourth, "4번째 일요일")
                        ],
                        martType: .normal
                    ))
                    tasks.append(contentsOf: generateBiweeklyTasks(
                        forYear: year,
                        weekdays: [
                            (.sunday, .second, "2번째 일요일"),
                            (.sunday, .fourth, "4번째 일요일")
                        ],
                        martType: .costco(type: .normal)
                    ))
                    tasks.append(contentsOf: generateBiweeklyTasks(
                        forYear: 2024,
                        weekdays: [
                            (.monday, .second, "2번째 월요일"),
                            (.monday, .fourth, "4번째 월요일")
                        ],
                        martType: .costco(type: .daegu)
                    ))
                    tasks.append(contentsOf: generateBiweeklyTasks(
                        forYear: 2024,
                        weekdays: [
                            (.wednesday, .second, "2번째 수요일"),
                            (.wednesday, .fourth, "4번째 수요일")
                        ],
                        martType: .costco(type: .ilsan)
                    ))
                    tasks.append(contentsOf: generateBiweeklyTasks(
                        forYear: 2024,
                        weekdays: [
                            (.wednesday, .second, "2번째 수요일"),
                            (.sunday, .fourth, "4번째 일요일")
                        ],
                        martType: .costco(type: .ulsan)
                    ))
                }
        }
    }
    
//    // 특정 주간의 요일을 찾는 함수
//    private func findPatternDay(of weekday: Calendar.Weekday, ordinal: Calendar.Ordinal, inMonth month: Int, year: Int, calendar: Calendar) -> Date? {
//        var components = DateComponents(year: year, month: month, weekday: weekday.rawValue, weekdayOrdinal: ordinal.rawValue)
//        return calendar.date(from: components)
//    }
    
    private func generateBiweeklyTasks(
            forYear year: Int,
            monthRange: Range<Int> = 1..<13,
            weekdays: [(Calendar.Weekday, Calendar.Ordinal, String)],
            martType: MartType
        ) -> [MetaMartsClosedDays] {
            var tasks: [MetaMartsClosedDays] = []
            let calendar = Calendar.current

            // 각 달을 순회하면서 요일과 주차에 맞는 날짜를 찾음
            for month in monthRange {
                for (weekday, ordinal, title) in weekdays {
                    if let date = findPatternDay(of: weekday, ordinal: ordinal, inMonth: month, year: year, calendar: calendar) {
                        tasks.append(MetaMartsClosedDays(type: martType, task: [MartCloseData(title: title)], taskDate: date))
                    }
                }
            }

            return tasks
        }

    private func findPatternDay(of weekday: Calendar.Weekday, ordinal: Calendar.Ordinal, inMonth month: Int, year: Int, calendar: Calendar) -> Date? {
        // 날짜 컴포넌트 설정
        var dateComponents = DateComponents(year: year, month: month)

        // 해당 월의 첫 번째 날짜를 가져와서, 그 날이 어떤 요일인지 확인
        if let firstDayOfMonth = calendar.date(from: dateComponents) {
            let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
            var targetDay = weekday.rawValue

            // 첫 번째 날짜의 요일을 맞추기 위해 첫 번째 날을 이동
            let daysToAdd = (targetDay - firstWeekday + 7) % 7
            dateComponents.day = 1 + daysToAdd  // 첫 번째 목표 날짜로 설정

            if let targetDate = calendar.date(from: dateComponents) {
                // 두 번째, 네 번째 등 원하는 ordinal 번째 날짜 찾기
                if ordinal == .first {
                    return targetDate
                } else if ordinal == .second {
                    return calendar.date(byAdding: .weekOfMonth, value: 1, to: targetDate)  // 2번째
                } else if ordinal == .third {
                    return calendar.date(byAdding: .weekOfMonth, value: 2, to: targetDate)  // 3번째
                } else if ordinal == .fourth {
                    return calendar.date(byAdding: .weekOfMonth, value: 3, to: targetDate)  // 4번째
                } else if ordinal == .fifth {
                    return calendar.date(byAdding: .weekOfMonth, value: 4, to: targetDate)  // 5번째
                }
            }
        }
        
        return nil
    }

    
//    private func generateNormalBiweeklySundayTasks(forYear year: Int) -> [MetaMartsClosedDays] {
//        var sundayTasks: [MetaMartsClosedDays] = []
//        let calendar = Calendar.current
//        
//        for month in 1...12 {
//            let ordinals: [(Calendar.Ordinal, String)] = [
//                (.second, "2번째 일요일"),
//                (.fourth, "4번째 일요일")
//            ]
//            
//            for (ordinal, title) in ordinals {
//                if let date = findPatternDay(of: .sunday, ordinal: ordinal, inMonth: month, year: year, calendar: calendar) {
//                    sundayTasks.append(MetaMartsClosedDays(type: .normal, task: [MartCloseData(title: title)], taskDate: date))
//                }
//            }
//        }
//        
//        return sundayTasks
//    }
//    
//    private func generateCostcoNormalBiweeklySundayTasks(forYear year: Int) -> [MetaMartsClosedDays] {
//        var sundayTasks: [MetaMartsClosedDays] = []
//        let calendar = Calendar.current
//        
//        for month in 1...12 {
//            let ordinals: [(Calendar.Ordinal, String)] = [
//                (.second, "2번째 일요일"),
//                (.fourth, "4번째 일요일")
//            ]
//            
//            for (ordinal, title) in ordinals {
//                if let date = findPatternDay(of: .sunday, ordinal: ordinal, inMonth: month, year: year, calendar: calendar) {
//                    sundayTasks.append(MetaMartsClosedDays(type: .costco(type: .normal), task: [MartCloseData(title: title)], taskDate: date))
//                }
//            }
//        }
//        
//        return sundayTasks
//    }
//    
//    private func generateCostcoDaeguBiweeklyMondayTasks(forYear year: Int) -> [MetaMartsClosedDays] {
//        var mondayTasks: [MetaMartsClosedDays] = []
//        let calendar = Calendar.current
//        
//        for month in 1...12 {
//            let ordinals: [(Calendar.Ordinal, String)] = [
//                (.first, "1번째 월요일"),
//                (.third, "3번째 월요일")
//            ]
//            
//            for (ordinal, title) in ordinals {
//                if let date = findPatternDay(of: .monday, ordinal: ordinal, inMonth: month, year: year, calendar: calendar) {
//                    mondayTasks.append(MetaMartsClosedDays(type: .costco(type: .daegu), task: [MartCloseData(title: title)], taskDate: date))
//                }
//            }
//        }
//        
//        return mondayTasks
//    }
//    
//    private func generateCostcoIlsanBiweeklyWednesdayTasks(forYear year: Int) -> [MetaMartsClosedDays] {
//        var wednesdayTasks: [MetaMartsClosedDays] = []
//        let calendar = Calendar.current
//        
//        for month in 1...12 {
//            let ordinals: [(Calendar.Ordinal, String)] = [
//                (.first, "1번째 수요일"),
//                (.third, "3번째 수요일")
//            ]
//            
//            for (ordinal, title) in ordinals {
//                if let date = findPatternDay(of: .wednesday, ordinal: ordinal, inMonth: month, year: year, calendar: calendar) {
//                    wednesdayTasks.append(MetaMartsClosedDays(type: .costco(type: .ilsan), task: [MartCloseData(title: title)], taskDate: date))
//                }
//            }
//        }
//        
//        return wednesdayTasks
//    }
//    
//    private func generateCostcoUlsanBiweeklySecondAndFourthWednesdayAndSundayTasks(forYear year: Int) -> [MetaMartsClosedDays] {
//        var tasks: [MetaMartsClosedDays] = []
//        let calendar = Calendar.current
//        
//        for month in 1...12 {
//            let weekTargets: [(Calendar.Weekday, Calendar.Ordinal, String)] = [
//                (.wednesday, .second, "2번째 수요일"),
//                (.sunday, .fourth, "4번째 일요일")
//            ]
//            
//            for (weekday, ordinal, title) in weekTargets {
//                if let date = findPatternDay(of: weekday, ordinal: ordinal, inMonth: month, year: year, calendar: calendar) {
//                    tasks.append(MetaMartsClosedDays(type: .costco(type: .ulsan), task: [MartCloseData(title: title)], taskDate: date))
//                }
//            }
//        }
//        
//        return tasks
//    }

}

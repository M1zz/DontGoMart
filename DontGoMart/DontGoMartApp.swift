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
                            (.monday, .first, "1번째 월요일"),
                            (.monday, .third, "3번째 월요일")
                        ],
                        martType: .costco(type: .daegu)
                    ))
                    tasks.append(contentsOf: generateBiweeklyTasks(
                        forYear: 2024,
                        weekdays: [
                            (.wednesday, .first, "1번째 수요일"),
                            (.wednesday, .third, "3번째 수요일")
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
    
    // 특정 주간의 요일을 찾는 함수
    private func findPatternDay(of weekday: Calendar.Weekday, ordinal: Calendar.Ordinal, inMonth month: Int, year: Int, calendar: Calendar) -> Date? {
        var components = DateComponents(year: year, month: month, weekday: weekday.rawValue, weekdayOrdinal: ordinal.rawValue)
        return calendar.date(from: components)
    }
    
    // 공통적인 일정 생성 함수
    private func generateBiweeklyTasks(
        forYear year: Int,
        monthRange: Range<Int> = 1..<13,
        weekdays: [(Calendar.Weekday, Calendar.Ordinal, String)],
        martType: MartType
    ) -> [MetaMartsClosedDays] {
        var tasks: [MetaMartsClosedDays] = []
        let calendar = Calendar.current

        for month in monthRange {
            for (weekday, ordinal, title) in weekdays {
                if let date = findPatternDay(of: weekday, ordinal: ordinal, inMonth: month, year: year, calendar: calendar) {
                    tasks.append(MetaMartsClosedDays(type: martType, task: [MartCloseData(title: title)], taskDate: date))
                }
            }
        }

        return tasks
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

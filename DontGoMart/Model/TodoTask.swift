//
//  Task.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/17.
//

import SwiftUI

// Date Value Model...
struct DateValue: Identifiable {
    var id = UUID().uuidString
    var day: Int
    var date: Date
}


// Task Model and Sample Tasks...
// Array of Tasks...
struct TodoTask: Identifiable {
    var id = UUID().uuidString
    var title: String
    //var time: Date = Date()
}

enum MartType: Equatable {
    case normal
    case costco(type: CostcoMartType)
}

enum CostcoMartType: Equatable, Codable, CaseIterable {
    case normal
    case daegu
    case ilsan
    case ulsan
    
    var storeName: String {
        switch self {
        case .normal:
            return "일반매장 - 양평점, 대전점, 양재점, \n상봉점, 부산점, 광명점, \n천안점, 의정부점, 공세점, \n송도점, 세종점, 하남점, \n김해점, 고척점"
        case .daegu:
            return "대구점, 대구혁신점"
        case .ilsan:
            return "일산점"
        case .ulsan:
            return "울산점"
        }
    }
    
    var storeID: Int {
        switch self {
        case .normal:
            return 0
        case .daegu:
            return 1
        case .ilsan:
            return 2
        case .ulsan:
            return 3
        }
    }
}

// Total Task Meta View...
struct TaskMetaData: Identifiable {
    var id = UUID().uuidString
    let type: MartType
    var task: [TodoTask]
    var taskDate: Date
}

// sample Date for Testing...
func getSampleDate(offset: Int)->Date {
    let calender = Calendar.current
    
    let date = calender.date(byAdding: .day, value: offset, to: Date())
    
    return date ?? Date()
}

func dateToDisplay(year: Int = 2024, month: Int, day: Int) -> Date {
    let components = DateComponents(calendar: Calendar.current,
                                    year: year, month: month, day: day)
    return Calendar.current.date(from: components)!
}

// MARK: Helper 함수
func generateSundayTasks(forYear year: Int) -> [TaskMetaData] {
    var sundayTasks: [TaskMetaData] = []
    let calendar = Calendar.current
    
    for month in 1...12 {
        // 두 번째 일요일 찾기
        let secondSunday = findWeekday(of: 1, ordinal: 2, inMonth: month, year: year, calendar: calendar)
        if let date = secondSunday {
            sundayTasks.append(TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: date))
        }
        
        // 네 번째 일요일 찾기
        let fourthSunday = findWeekday(of: 1, ordinal: 4, inMonth: month, year: year, calendar: calendar)
        if let date = fourthSunday {
            sundayTasks.append(TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: date))
        }
    }
    return sundayTasks
}

func findWeekday(of weekday: Int, ordinal: Int, inMonth month: Int, year: Int, calendar: Calendar) -> Date? {
    var components = DateComponents(year: year, month: month, weekday: weekday, weekdayOrdinal: ordinal)
    return calendar.date(from: components)
}

// MARK: Data 생성
var tasks: [TaskMetaData] = []

// MARK: Costco 관련 Tasks
let costcoTasks: [TaskMetaData] = [
    TaskMetaData(type: .costco(type: .normal), task: [TodoTask(title: "전점 7시 조기폐점")], taskDate: dateToDisplay(month: 2, day: 9)),
    TaskMetaData(type: .costco(type: .normal), task: [TodoTask(title: "전점설날휴무")], taskDate: dateToDisplay(month: 2, day: 10)),
    
    // 2월 휴점일 (지점별로 구분)
    TaskMetaData(type: .costco(type: .normal), task: [], taskDate: dateToDisplay(month: 2, day: 11)),
    TaskMetaData(type: .costco(type: .daegu), task: [], taskDate: dateToDisplay(month: 2, day: 11)),
    TaskMetaData(type: .costco(type: .ilsan), task: [], taskDate: dateToDisplay(month: 2, day: 11)),
    TaskMetaData(type: .costco(type: .ulsan), task: [], taskDate: dateToDisplay(month: 2, day: 11)),
    
    TaskMetaData(type: .costco(type: .daegu), task: [], taskDate: dateToDisplay(month: 2, day: 12)),
    TaskMetaData(type: .costco(type: .ulsan), task: [], taskDate: dateToDisplay(month: 2, day: 14)),
    
    TaskMetaData(type: .costco(type: .normal), task: [], taskDate: dateToDisplay(month: 2, day: 25)),
    TaskMetaData(type: .costco(type: .daegu), task: [], taskDate: dateToDisplay(month: 2, day: 25)),
    TaskMetaData(type: .costco(type: .ilsan), task: [], taskDate: dateToDisplay(month: 2, day: 25)),
    TaskMetaData(type: .costco(type: .ulsan), task: [], taskDate: dateToDisplay(month: 2, day: 25)),
    
    TaskMetaData(type: .costco(type: .daegu), task: [], taskDate: dateToDisplay(month: 2, day: 26)),
    TaskMetaData(type: .costco(type: .ilsan), task: [], taskDate: dateToDisplay(month: 2, day: 28))
]

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

// Sample Tasks...
var tasks: [TaskMetaData] = [
    
    // 1월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 1, day: 14)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 1, day: 28)),
    
    // 2월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 2, day: 11)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 2, day: 25)),
    
    // 3월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 3, day: 10)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 3, day: 24)),
    
    // 4월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 4, day: 14)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 4, day: 28)),
    
    // 5월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 5, day: 12)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 5, day: 26)),
    
    // 6월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 6, day: 9)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 6, day: 23)),
    
    // 7월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 7, day: 14)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 7, day: 28)),
    
    // 8월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 8, day: 11)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 8, day: 25)),
    
    // 9월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 9, day: 8)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 9, day: 22)),
    
    // 10월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 10, day: 13)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 10, day: 27)),
    
    // 11월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 11, day: 10)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 11, day: 24)),
        
    // 12월
    TaskMetaData(type: .normal, task: [TodoTask(title: "2번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 12, day: 8)),
    TaskMetaData(type: .normal, task: [TodoTask(title: "4번째 일요일")], taskDate: dateToDisplay(year: 2024, month: 12, day: 22)),

    
    //MARK: Costco
    // 2월 9일(금) - 전점 7시 조기폐점
    TaskMetaData(type: .costco(type: .normal), task: [TodoTask(title: "전점 7시 조기폐점")], taskDate: dateToDisplay(month: 2, day: 9)),
    
    // 2월 10일(토) - 전점설날휴무
    TaskMetaData(type: .costco(type: .normal), task: [TodoTask(title: "전점설날휴무")], taskDate: dateToDisplay(month: 2, day: 10)),
    
    // 2월 11일(일) - 양평점, 대전점, 상봉점, 부산점, 천안점, 공세점, 송도점, 세종점, 김해점, 고척점
    TaskMetaData(type: .costco(type: .normal), task: [], taskDate: dateToDisplay(month: 2, day: 11)),
    TaskMetaData(type: .costco(type: .daegu), task: [], taskDate: dateToDisplay(month: 2, day: 11)),
    TaskMetaData(type: .costco(type: .ilsan), task: [], taskDate: dateToDisplay(month: 2, day: 11)),
    TaskMetaData(type: .costco(type: .ulsan), task: [], taskDate: dateToDisplay(month: 2, day: 11)),
    
    // 2월 12일(월) - 대구점, 대구혁신점
    TaskMetaData(type: .costco(type: .daegu), task: [], taskDate: dateToDisplay(month: 2, day: 12)),
    
    // 2월 14일(수) - 울산점
    TaskMetaData(type: .costco(type: .ulsan), task: [], taskDate: dateToDisplay(month: 2, day: 14)),
    
    // 2월 25일(일) - 양평점, 대전점, 양재점, 상봉점, 부산점, 울산점, 광명점, 천안점, 의정부점, 공세점, 송도점, 세종점, 하남점, 김해점, 고척점
    TaskMetaData(type: .costco(type: .normal), task: [], taskDate: dateToDisplay(month: 2, day: 25)),
    TaskMetaData(type: .costco(type: .daegu), task: [], taskDate: dateToDisplay(month: 2, day: 25)),
    TaskMetaData(type: .costco(type: .ilsan), task: [], taskDate: dateToDisplay(month: 2, day: 25)),
    TaskMetaData(type: .costco(type: .ulsan), task: [], taskDate: dateToDisplay(month: 2, day: 25)),
    
    // 2월 26일(월) - 대구점, 대구혁신점
    TaskMetaData(type: .costco(type: .daegu), task: [], taskDate: dateToDisplay(month: 2, day: 26)),
    
    // 2월 28일(수) - 일산점
    TaskMetaData(type: .costco(type: .ilsan), task: [], taskDate: dateToDisplay(month: 2, day: 28))
]


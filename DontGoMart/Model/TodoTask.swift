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
            return "일반매장 - 양평점, 대전점, 양재점, \n상봉점,부산점, 광명점, \n천안점, 의정부점, 공세점, \n송도점, 세종점, 하남점, \n김해점, 고척점"
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

func dateToDisplay(month: Int, day: Int) -> Date {
    let components = DateComponents(calendar: Calendar.current,
                                    year: 2023, month: month, day: day)
    return Calendar.current.date(from: components)!
}

// Sample Tasks...
var tasks: [TaskMetaData] = [
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 6, day: 11)),
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 6, day: 25)),
    
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 7, day: 9)),
    
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 7, day: 23)),
    
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 8, day: 13)),
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 8, day: 27)),
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 9, day: 10)),
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 9, day: 24)),
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 10, day: 8)),
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 10, day: 22)),
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 11, day: 12)),
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 11, day: 26)),
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 12, day: 10)),
    
    TaskMetaData(type: .normal,
                 task: [TodoTask(title: "Don't go mart")],
                 taskDate: dateToDisplay(month: 12, day: 24)),
    
    //MARK: Costco
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 7, day: 9)),
    
    TaskMetaData(type: .costco(type: .daegu),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 7, day: 10)),
    
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 7, day: 12)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 7, day: 12)),
    
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 7, day: 23)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 7, day: 23)),
    
    TaskMetaData(type: .costco(type: .daegu),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 7, day: 24)),
    
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 7, day: 26)),
    
    //MARK: Costco August
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 8, day: 13)),
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 8, day: 27)),
    TaskMetaData(type: .costco(type: .daegu),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 8, day: 14)),
    TaskMetaData(type: .costco(type: .daegu),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 8, day: 28)),
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 8, day: 9)),
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 8, day: 23)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 8, day: 9)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 8, day: 27)),

    //MARK: Costco September
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 9, day: 10)),
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 9, day: 24)),
    TaskMetaData(type: .costco(type: .daegu),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 9, day: 11)),
    TaskMetaData(type: .costco(type: .daegu),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 9, day: 25)),
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 9, day: 13)),
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 9, day: 27)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 9, day: 13)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 9, day: 24)),

    //MARK: Costco October
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 10, day: 8)),
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 10, day: 22)),
    TaskMetaData(type: .costco(type: .daegu),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 10, day: 9)),
    TaskMetaData(type: .costco(type: .daegu),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 10, day: 23)),
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 10, day: 11)),
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 10, day: 25)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 10, day: 11)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 10, day: 22)),

    //MARK: Costco November
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 11, day: 12)),
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 11, day: 26)),
    TaskMetaData(type: .costco(type: .daegu),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 11, day: 13)),
    TaskMetaData(type: .costco(type: .daegu),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 11, day: 27)),
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 11, day: 8)),
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 11, day: 22)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 11, day: 8)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 11, day: 26)),

    //MARK: Costco December
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 12, day: 10)),
    TaskMetaData(type: .costco(type: .normal),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 12, day: 24)),
    TaskMetaData(type: .costco(type: .daegu),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 12, day: 11)),
    TaskMetaData(type: .costco(type: .daegu),
                 task:[TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 12, day: 25)),
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 12, day: 13)),
    TaskMetaData(type: .costco(type: .ilsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 12, day: 27)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 12, day: 13)),
    TaskMetaData(type: .costco(type: .ulsan),
                 task: [TodoTask(title: "Don't go costco")],
                 taskDate: dateToDisplay(month: 12, day: 24))

]

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
    var time: Date = Date()
}

// Total Task Meta View...
struct TaskMetaData: Identifiable {
    var id = UUID().uuidString
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
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 6, day: 11)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 6, day: 25)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 7, day: 9)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 7, day: 23)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 8, day: 13)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 8, day: 27)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 9, day: 10)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 9, day: 24)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 10, day: 8)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 10, day: 22)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 11, day: 12)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 11, day: 26)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 12, day: 10)),
    TaskMetaData(task: [
        
        TodoTask(title: "Don't go mart")
    ], taskDate: dateToDisplay(month: 12, day: 24)),
]

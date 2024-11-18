//
//  MartClosedData.swift
//  DontGoMart
//
//  Created by hyunho lee on 11/9/24.
//

import Foundation

struct MetaMartsClosedDays: Identifiable {
    var id = UUID().uuidString
    let type: MartType
    var task: [MartCloseData]
    var taskDate: Date
}

struct MartCloseData: Identifiable {
    var id = UUID().uuidString
    var title: String
}

var tasks: [MetaMartsClosedDays] = []

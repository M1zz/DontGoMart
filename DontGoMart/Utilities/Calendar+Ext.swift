//
//  Calendar.swift
//  DontGoMart
//
//  Created by hyunho lee on 11/9/24.
//

import Foundation

extension Calendar {
    /// 요일
    enum Weekday: Int {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }
    /// 주차
    enum Ordinal: Int {
        case first = 1, second, third, fourth, fifth
    }
}

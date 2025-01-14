//
//  CalendarWidgetBundle.swift
//  CalendarWidget
//
//  Created by hyunho lee on 2023/06/15.
//

import WidgetKit
import SwiftUI

@main
struct CalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        HolidayWidget()
        TwoHolidayWidget()
    }
}

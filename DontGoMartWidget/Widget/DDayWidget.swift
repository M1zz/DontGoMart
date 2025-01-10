//
//  DDayWidget.swift
//  CalendarWidgetExtension
//
//  Created by 황석현 on 12/2/24.
//

import SwiftUI
import WidgetKit

// TODO: 2개의 휴일을 보여준다
struct DDayWidgetEntryView: View {
    @AppStorage("isNormal", store: UserDefaults(suiteName: Utillity.appGroupId)) var isCostco: Bool = false
    @AppStorage("selectedBranch", store: UserDefaults(suiteName: Utillity.appGroupId)) var selectedBranch: Int = 0
    @State private var selectedMartType: MartType = .normal
    
    var entry: DayEntry
    var config: MonthConfig
    let startDate = Date()

    init(entry: DayEntry) {
        self.entry = entry
        self.config = MonthConfig.determineConfig(from: entry.date)
    }
    
    var body: some View {
        Text("DDayWidget")
    }
}

struct DDayWidget: Widget {
    let kind = "DDayWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: DDayWidgetProvider()) { entry in
            DDayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("휴무 디데이위젯")
        .description("휴무일까지 남은 일수를 보여주는 위젯이에요!")
        .supportedFamilies([.systemSmall])
    }
}

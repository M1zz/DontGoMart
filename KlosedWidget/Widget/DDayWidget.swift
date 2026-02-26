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
    @State private var selectedMartType: MartType = .normal(type: .sunday)

    var entry: DayEntry
    var config: MonthConfig
    let startDate = Date()

    init(entry: DayEntry) {
        self.entry = entry
        self.config = MonthConfig.determineConfig(from: entry.date)
    }

    var body: some View {
        Text("DDayWidget")
            .containerBackground(for: .widget) {
                LinearGradient(
                    gradient: Gradient(colors: [config.backgroundColor, config.backgroundColor]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }
}

struct DDayWidget: Widget {
    let kind = "DDayWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: DDayWidgetProvider()) { entry in
            DDayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Closure D-Day Widget")
        .description("Shows the number of days until the next closed day!")
        .supportedFamilies([.systemSmall])
    }
}

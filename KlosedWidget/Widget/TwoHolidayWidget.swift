//
//  TwoHolidayWidget.swift
//  CalendarWidgetExtension
//
//  Created by 황석현 on 12/2/24.
//

import SwiftUI
import WidgetKit

struct TwoHolidayEntryView: View {

    var entry: TwoHolidayEntry
    var config: MonthConfig
    let startDate = Date()

    init(entry: TwoHolidayEntry) {
        self.entry = entry
        self.config = MonthConfig.determineConfig(from: entry.date)
    }

    // 마트 타입에 따른 색상 반환
    private func colorForMartType(_ storageKey: String) -> Color {
        switch storageKey {
        // 대형마트 패턴들
        case "normal_sunday":
            return .blue
        case "normal_wednesday":
            return .cyan
        case "normal_mixed":
            return .teal
        case "normal_jeju":
            return .mint
        // 코스트코 패턴들
        case "costco_normal":
            return .red
        case "costco_daegu":
            return .orange
        case "costco_ilsan":
            return .green
        case "costco_ulsan":
            return .purple
        // 공휴일
        case "holiday":
            return .pink
        default:
            // 커스텀 마트인 경우 (custom_UUID 형식)
            if storageKey.hasPrefix("custom_") {
                let id = String(storageKey.dropFirst(7)) // "custom_" 제거
                if let customMart = CustomMartManager.shared.getCustomMart(byId: id),
                   let color = Color(hex: customMart.color) {
                    return color
                }
            }
            return .gray
        }
    }

    private var martColor: Color {
        // holidayText[5]에 마트 타입이 저장되어 있음
        if entry.holidayText.count > 5 {
            return colorForMartType(entry.holidayText[5])
        }
        return config.backgroundColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 헤더: 마트 이름
            HStack(spacing: 4) {
                Circle()
                    .fill(martColor)
                    .frame(width: 8, height: 8)
                Text(entry.holidayText[0])
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 2)

            // 첫 번째 휴무일 (가까운 날짜) - 크게 표시
            VStack(alignment: .leading, spacing: 4) {
                // D-day 크게
                Text(entry.holidayText[2])
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(martColor)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                // 날짜
                Text(entry.holidayText[1])
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 2)

            // 구분선
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)

            // 두 번째 휴무일 (먼 날짜) - 작게 표시
            HStack(spacing: 6) {
                Text(entry.holidayText[4])
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Text(entry.holidayText[3])
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(10)
        .containerBackground(for: .widget) {
            LinearGradient(
                gradient: Gradient(colors: [
                    martColor.opacity(0.6),
                    martColor.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct TwoHolidayWidget: Widget {
    let kind = "TwoHoliday"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: TwoHoliydayWidgetProvider()) { entry in
            TwoHolidayEntryView(entry: entry)
        }
        .configurationDisplayName("Two Closed Days Widget")
        .description("Shows the next two upcoming closed days!")
        .supportedFamilies([.systemSmall])
    }
}

struct TwoHolidayWidgetPreviews: PreviewProvider {
    static var previews: some View {
        TwoHolidayEntryView(entry: TwoHolidayEntry(date: Date(), configuration: ConfigurationIntent(), holidayText: ["Klosed Mart","Jan 26 Sun","D-5","Feb 9 Sun","D-19"]))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

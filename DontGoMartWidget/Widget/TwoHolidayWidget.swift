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
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            HStack(spacing: 4) {
                Text(config.emojiText)
                    .font(.body)
                HStack(spacing: 4) {
                    Circle()
                        .fill(martColor)
                        .frame(width: 6, height: 6)
                    Text(entry.holidayText[0])
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            Spacer(minLength: 4)

            // 첫 번째 휴무일
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.holidayText[1])
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 4) {
                    Text(entry.holidayText[2])
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(martColor)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.9))
            )

            // 두 번째 휴무일
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.holidayText[3])
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 4) {
                    Text(entry.holidayText[4])
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.7))
            )
        }
        .padding(12)
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
        .configurationDisplayName("2개의 휴무일 위젯")
        .description("다다음 휴무일까지 보여주는 위젯이에요!")
        .supportedFamilies([.systemSmall])
    }
}

struct TwoHolidayWidgetPreviews: PreviewProvider {
    static var previews: some View {
        TwoHolidayEntryView(entry: TwoHolidayEntry(date: Date(), configuration: ConfigurationIntent(), holidayText: ["돈꼬 마트","1월 26일 일요일","D-5","2월 9일 일요일","D-19"]))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

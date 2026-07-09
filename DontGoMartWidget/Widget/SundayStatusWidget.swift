//
//  SundayStatusWidget.swift
//  CalendarWidgetExtension
//
//  '이번 주 일요일' 에 내가 설정한 마트가 열면 초록색, 닫으면 빨간색으로
//  홈 화면 위젯과 잠금화면(액세서리)에서 한눈에 확인.
//

import WidgetKit
import SwiftUI

// MARK: - Provider

struct SundayStatusWidgetProvider: IntentTimelineProvider {

    func placeholder(in context: Context) -> SundayStatusEntry {
        let sunday = WidgetClosedDayStore.nextSunday(onOrAfter: Date())
        return SundayStatusEntry(date: Date(),
                                 configuration: ConfigurationIntent(),
                                 sundayDate: sunday,
                                 isClosed: false,
                                 hasMart: true)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SundayStatusEntry) -> ()) {
        let status = WidgetClosedDayStore.sundayStatus(onOrAfter: Date())
        let entry = SundayStatusEntry(date: Date(),
                                      configuration: configuration,
                                      sundayDate: status.sunday,
                                      isClosed: status.isClosed,
                                      hasMart: WidgetClosedDayStore.hasSelectedMart)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SundayStatusEntry>) -> ()) {
        var entries: [SundayStatusEntry] = []
        let calendar = Calendar.current
        let currentDate = Date()
        let hasMart = WidgetClosedDayStore.hasSelectedMart

        // 16일치 일별 엔트리. 각 엔트리는 그 날 기준 '이번 주 일요일' 을 스스로 계산하므로
        // 일요일이 지나면 자동으로 다음 주 일요일로 넘어간다.
        for dayOffset in 0 ..< 16 {
            guard let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: currentDate) else { continue }
            let startOfDate = calendar.startOfDay(for: entryDate)
            let status = WidgetClosedDayStore.sundayStatus(onOrAfter: startOfDate)
            entries.append(SundayStatusEntry(date: startOfDate,
                                             configuration: configuration,
                                             sundayDate: status.sunday,
                                             isClosed: status.isClosed,
                                             hasMart: hasMart))
        }

        // 매일 자정에 재생성 → 일요일 롤오버 + 상태 재계산
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(86400)
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        completion(Timeline(entries: entries, policy: .after(nextMidnight)))
    }
}

// MARK: - Shared status model

private struct SundayDisplay {
    let statusColor: Color        // 초록(영업) / 빨강(휴무)
    let emoji: String             // 🟢 / 🔴
    let symbolName: String        // SF Symbol (잠금화면 틴트용)
    let statusText: String        // "영업" / "휴무"
    let dateText: String          // "7월 12일"
    let accessibility: String     // VoiceOver 단일 문장

    init(entry: SundayStatusEntry) {
        let mdw = entry.sundayDate.getMonthDayWeekday()
        let dateText = "\(mdw.month) \(mdw.day)"
        self.dateText = dateText

        if !entry.hasMart {
            statusColor = .gray
            emoji = "❓"
            symbolName = "questionmark.circle.fill"
            statusText = String(localized: "마트 선택", defaultValue: "Pick a store")
            accessibility = String(localized: "선택된 마트가 없습니다. 앱에서 마트를 선택하세요.",
                                   defaultValue: "No store selected. Open the app to choose one.")
        } else if entry.isClosed {
            statusColor = .red
            emoji = "🔴"
            symbolName = "xmark.circle.fill"
            statusText = String(localized: "휴무_status", defaultValue: "Closed")
            accessibility = String(format: String(localized: "이번 주 일요일 %@, 마트 휴무",
                                                   defaultValue: "This Sunday %@, store closed"), dateText)
        } else {
            statusColor = .green
            emoji = "🟢"
            symbolName = "checkmark.circle.fill"
            statusText = String(localized: "영업", defaultValue: "Open")
            accessibility = String(format: String(localized: "이번 주 일요일 %@, 마트 영업",
                                                   defaultValue: "This Sunday %@, store open"), dateText)
        }
    }
}

private let sundayHeaderText = String(localized: "이번 주 일요일", defaultValue: "This Sunday")

// MARK: - Home screen (systemSmall)

struct SundayStatusHomeView: View {
    fileprivate let display: SundayDisplay

    var body: some View {
        VStack(spacing: 6) {
            Text(sundayHeaderText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.9))

            Text(display.dateText)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(display.emoji)
                .font(.system(size: 44))

            Text(display.statusText)
                .font(.title3)
                .fontWeight(.heavy)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [display.statusColor, display.statusColor.opacity(0.75)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Lock screen (accessory families)

struct SundayStatusAccessoryView: View {
    @Environment(\.widgetFamily) private var family
    fileprivate let display: SundayDisplay

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: display.symbolName)
                        .font(.system(size: 20, weight: .bold))
                    Text(String(localized: "일", defaultValue: "Sun"))
                        .font(.system(size: 11, weight: .semibold))
                }
            }

        case .accessoryInline:
            // 인라인은 심볼 1개 + 텍스트만 허용
            Label("\(sundayHeaderText) \(display.statusText)", systemImage: display.symbolName)

        default: // accessoryRectangular
            HStack(spacing: 8) {
                Image(systemName: display.symbolName)
                    .font(.system(size: 26, weight: .bold))
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 1) {
                    Text(sundayHeaderText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(display.statusText)
                        .font(.headline)
                    Text(display.dateText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Entry view

struct SundayStatusEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: SundayStatusEntry

    private var display: SundayDisplay { SundayDisplay(entry: entry) }

    var body: some View {
        Group {
            if family == .systemSmall {
                SundayStatusHomeView(display: display)
            } else {
                SundayStatusAccessoryView(display: display)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(display.accessibility)
        .widgetURL(Utillity.calendarDeepLink)
    }
}

// MARK: - Widget

struct SundayStatusWidget: Widget {
    let kind = "SundayStatusWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: SundayStatusWidgetProvider()) { entry in
            SundayStatusEntryView(entry: entry)
        }
        .configurationDisplayName("Sunday Open/Closed")
        .description("Shows in green/red whether your store is open this Sunday.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct SundayStatusWidget_Previews: PreviewProvider {
    static var previews: some View {
        let open = SundayStatusEntry(date: Date(), configuration: ConfigurationIntent(),
                                     sundayDate: Date(), isClosed: false, hasMart: true)
        let closed = SundayStatusEntry(date: Date(), configuration: ConfigurationIntent(),
                                       sundayDate: Date(), isClosed: true, hasMart: true)
        Group {
            SundayStatusEntryView(entry: open)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            SundayStatusEntryView(entry: closed)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            SundayStatusEntryView(entry: open)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
        }
    }
}

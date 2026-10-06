//
//  RestaurantWeekWidget.swift
//  CalendarWidgetExtension
//
//  단골 식당 7일: 오늘부터 7일 중 내가 넣은 식당이 쉬는 요일에 점을 찍는다.
//  식당 목록(규칙)만 앱그룹에서 읽고 날짜 계산은 위젯이 매일 스스로 한다.
//

import WidgetKit
import SwiftUI

struct RestaurantWeekEntry: TimelineEntry {
    let date: Date
    let days: [RestaurantDay]
    let hasRestaurants: Bool
}

struct RestaurantWeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> RestaurantWeekEntry {
        let sample = Restaurant(name: String(localized: "단골 식당", defaultValue: "My restaurant"),
                                patterns: [ClosurePattern(weeks: Set(WeekOfMonth.allCases), weekday: .tuesday)])
        return entry(for: Date(), restaurants: [sample])
    }

    func getSnapshot(in context: Context, completion: @escaping (RestaurantWeekEntry) -> Void) {
        let restaurants = RestaurantStore.load()
        completion(restaurants.isEmpty && context.isPreview ? placeholder(in: context)
                                                            : entry(for: Date(), restaurants: restaurants))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RestaurantWeekEntry>) -> Void) {
        let calendar = Calendar.current
        let restaurants = RestaurantStore.load()
        let today = calendar.startOfDay(for: Date())
        // 7일치 자정 엔트리 — 앱을 열지 않아도 날마다 하루씩 밀린다.
        let entries = (0..<7).compactMap { offset -> RestaurantWeekEntry? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return entry(for: offset == 0 ? Date() : day, restaurants: restaurants)
        }
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86400)
        completion(Timeline(entries: entries, policy: .after(nextMidnight)))
    }

    private func entry(for date: Date, restaurants: [Restaurant]) -> RestaurantWeekEntry {
        RestaurantWeekEntry(date: date,
                            days: RestaurantStore.week(from: date, restaurants: restaurants),
                            hasRestaurants: !restaurants.isEmpty)
    }
}

// MARK: - Views

struct RestaurantWeekEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RestaurantWeekEntry

    private var closedDays: [RestaurantDay] { entry.days.filter { !$0.closed.isEmpty } }

    var body: some View {
        Group {
            if !entry.hasRestaurants {
                emptyView
            } else {
                switch family {
                case .accessoryRectangular: accessoryView
                case .systemMedium: mediumView
                default: smallView
                }
            }
        }
        .containerBackground(.background, for: .widget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary))
    }

    private var title: some View {
        Label {
            Text("단골 식당 7일")
        } icon: {
            Image(systemName: "fork.knife")
        }
        .font(.headline)
        .foregroundStyle(Color.pink)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 6) {
            title
            Text("앱에서 단골 식당을 추가하세요")
                .font(.body)
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            title
            strip(showDayNumber: false)
            Spacer(minLength: 0)
            Text(nextClosedText)
                .font(.body.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            title
            strip(showDayNumber: true)
            Spacer(minLength: 0)
            if closedDays.isEmpty {
                Text("7일 동안 쉬는 곳이 없어요")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(closedDays.prefix(2)) { day in
                    HStack(spacing: 6) {
                        Text(day.date.formatted(.dateTime.weekday(.abbreviated).day()))
                            .font(.body.weight(.semibold))
                        Text(day.closed.map(\.name).joined(separator: ", "))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            }
        }
    }

    private var accessoryView: some View {
        HStack(spacing: 2) {
            ForEach(entry.days) { day in
                VStack(spacing: 3) {
                    Text(Weekday.symbol(calendarWeekday: Calendar.current.component(.weekday, from: day.date)))
                        .font(.headline)
                        .minimumScaleFactor(0.6)
                    Circle()
                        .frame(width: 7, height: 7)
                        .opacity(day.closed.isEmpty ? 0 : 1)
                        .widgetAccentable()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func strip(showDayNumber: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(entry.days.enumerated()), id: \.element.id) { index, day in
                let weekday = Calendar.current.component(.weekday, from: day.date)
                VStack(spacing: 4) {
                    Text(Weekday.symbol(calendarWeekday: weekday))
                        .font(.body.weight(index == 0 ? .heavy : .medium))
                        .foregroundStyle(weekday == 1 ? Color.red : (weekday == 7 ? Color.blue : Color.primary))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    if showDayNumber {
                        Text("\(Calendar.current.component(.day, from: day.date))")
                            .font(.body)
                            .foregroundStyle(index == 0 ? Color.white : Color.primary)
                            .minimumScaleFactor(0.6)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(index == 0 ? Color.pink : Color.clear))
                    }
                    HStack(spacing: 2) {
                        ForEach(Array(day.closed.prefix(3).enumerated()), id: \.offset) { _, restaurant in
                            Circle()
                                .fill(Color(hex: restaurant.color) ?? .orange)
                                .frame(width: 7, height: 7)
                        }
                    }
                    .frame(height: 7)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// 작은 위젯 아래 한 줄: "화 · 청산한우" / "7일간 휴무 없음"
    private var nextClosedText: String {
        guard let day = closedDays.first else {
            return String(localized: "7일간 휴무 없음", defaultValue: "No closures this week")
        }
        let weekday = Weekday.symbol(calendarWeekday: Calendar.current.component(.weekday, from: day.date))
        return "\(weekday) · " + day.closed.map(\.name).joined(separator: ", ")
    }

    private var accessibilitySummary: String {
        guard entry.hasRestaurants else {
            return String(localized: "단골 식당이 없습니다. 앱에서 추가하세요.",
                          defaultValue: "No restaurants yet. Add them in the app.")
        }
        guard !closedDays.isEmpty else {
            return String(localized: "앞으로 7일 동안 쉬는 단골 식당이 없습니다.",
                          defaultValue: "None of your restaurants close in the next 7 days.")
        }
        return closedDays.map { day in
            let date = day.date.formatted(.dateTime.month().day().weekday(.wide))
            let names = day.closed.map(\.name).joined(separator: ", ")
            return date + " " + String(format: String(localized: "%@ 휴무", defaultValue: "%@ closed"), names)
        }.joined(separator: ". ")
    }
}

struct RestaurantWeekWidget: Widget {
    let kind = "RestaurantWeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RestaurantWeekProvider()) { entry in
            RestaurantWeekEntryView(entry: entry)
        }
        .configurationDisplayName("단골 식당 7일")
        .description("앞으로 7일 중 단골 식당이 쉬는 요일을 점으로 보여줘요.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

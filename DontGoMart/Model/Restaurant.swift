//
//  Restaurant.swift
//  DontGoMart
//
//  내가 자주 가는 식당(단골집)의 정기 휴무. 앱과 위젯이 함께 쓰는 저장 모델.
//  휴무 규칙은 마트와 같은 ClosurePattern 을 그대로 재사용한다.
//

import Foundation
import WidgetKit

struct Restaurant: Codable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var address: String
    var patterns: [ClosurePattern]
    var color: String
    /// 가져온 원본 링크(네이버지도 등). 목록에서 다시 열어볼 수 있게 보관한다.
    var placeURL: String?

    init(id: UUID = UUID(), name: String, address: String = "", patterns: [ClosurePattern],
         color: String = "#FF8A3D", placeURL: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.patterns = patterns
        self.color = color
        self.placeURL = placeURL
    }

    func isClosed(on date: Date, calendar: Calendar = .current) -> Bool {
        patterns.contains { $0.matches(date, calendar: calendar) }
    }

    /// 휴무 규칙을 한 줄로 ("매주 화요일 / 격주 수요일").
    var patternSummary: String {
        patterns.map(\.displayText).joined(separator: " / ")
    }

    /// 식당 목록에서 돌려 쓰는 기본 색상들 (추가할 때마다 다음 색).
    static let palette = ["#FF8A3D", "#2EA3F2", "#8E5CF0", "#20B26B", "#F2507B", "#C9A227"]
}

extension ClosurePattern {
    /// 이 날짜가 이 규칙의 휴무일인지. 연도 전체를 펼치지 않고 바로 판정한다.
    func matches(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard calendar.component(.weekday, from: date) == weekday.rawValue else { return false }
        switch frequency {
        case .weekOfMonth:
            let ordinal = (calendar.component(.day, from: date) - 1) / 7 + 1
            return weeks.contains { $0.rawValue == ordinal }
        case .biweekly:
            guard let anchorDate else { return false }
            let days = calendar.dateComponents([.day],
                                               from: calendar.startOfDay(for: anchorDate),
                                               to: calendar.startOfDay(for: date)).day ?? 1
            return days % 14 == 0
        }
    }
}

/// 하루치 — 그날 쉬는 식당들.
struct RestaurantDay: Identifiable {
    let date: Date
    let closed: [Restaurant]
    var id: Date { date }
}

/// 앱그룹 UserDefaults 에 JSON 으로 저장. 위젯은 이걸 읽어 스스로 7일을 계산한다.
enum RestaurantStore {
    private static let key = "restaurants"

    static func load() -> [Restaurant] {
        guard let data = UserDefaults(suiteName: Utillity.appGroupId)?.data(forKey: key),
              let list = try? JSONDecoder().decode([Restaurant].self, from: data) else {
            return []
        }
        return list
    }

    static func save(_ list: [Restaurant]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults(suiteName: Utillity.appGroupId)?.set(data, forKey: key)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// start 부터 days 일 동안, 날마다 쉬는 식당.
    static func week(from start: Date, days: Int = 7, restaurants: [Restaurant],
                     calendar: Calendar = .current) -> [RestaurantDay] {
        let first = calendar.startOfDay(for: start)
        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: first) else { return nil }
            return RestaurantDay(date: date, closed: restaurants.filter { $0.isClosed(on: date, calendar: calendar) })
        }
    }
}

//
//  CustomMart.swift
//  DontGoMart
//
//  Created by Claude on 1/20/25.
//

import Foundation

// 주차 선택 (1-5주차)
enum WeekOfMonth: Int, Codable, CaseIterable {
    case first = 1
    case second = 2
    case third = 3
    case fourth = 4
    case fifth = 5

    var displayName: String {
        return "\(rawValue)주차"
    }
}

// 요일 선택
enum Weekday: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var displayName: String {
        switch self {
        case .sunday: return "일"
        case .monday: return "월"
        case .tuesday: return "화"
        case .wednesday: return "수"
        case .thursday: return "목"
        case .friday: return "금"
        case .saturday: return "토"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return "일요일"
        case .monday: return "월요일"
        case .tuesday: return "화요일"
        case .wednesday: return "수요일"
        case .thursday: return "목요일"
        case .friday: return "금요일"
        case .saturday: return "토요일"
        }
    }
}

// 커스텀 마트 패턴
struct ClosurePattern: Codable, Hashable, Identifiable {
    let id: UUID
    let weeks: Set<WeekOfMonth>  // 선택된 주차들 (예: [2, 4] = 2주차, 4주차)
    let weekday: Weekday  // 요일

    init(id: UUID = UUID(), weeks: Set<WeekOfMonth>, weekday: Weekday) {
        self.id = id
        self.weeks = weeks
        self.weekday = weekday
    }

    var displayText: String {
        let weekText = weeks.sorted(by: { $0.rawValue < $1.rawValue })
            .map { $0.displayName }
            .joined(separator: ", ")
        return "\(weekText) \(weekday.displayName)요일"
    }
}

// 사용자 정의 마트
struct CustomMart: Codable, Hashable, Identifiable {
    let id: UUID
    var name: String  // 마트 이름
    var patterns: [ClosurePattern]  // 여러 패턴 가능 (예: 2,4주 일요일 + 3주 수요일)
    var color: String  // 색상 hex
    var isEnabled: Bool

    init(id: UUID = UUID(), name: String, patterns: [ClosurePattern], color: String = "#FF6B6B", isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.patterns = patterns
        self.color = color
        self.isEnabled = isEnabled
    }

    // 특정 연도의 휴무일 계산
    func calculateClosedDates(for year: Int) -> [Date] {
        var closedDates: [Date] = []
        let calendar = Calendar.current

        // 해당 연도의 모든 월을 순회
        for month in 1...12 {
            for pattern in patterns {
                // 해당 월의 특정 요일 찾기
                let weekdayDates = getDatesForWeekday(pattern.weekday, inMonth: month, year: year)

                // 선택된 주차의 날짜만 추가
                for week in pattern.weeks {
                    if week.rawValue <= weekdayDates.count {
                        closedDates.append(weekdayDates[week.rawValue - 1])
                    }
                }
            }
        }

        return closedDates.sorted()
    }

    // 특정 월의 특정 요일 날짜들을 가져오기
    private func getDatesForWeekday(_ weekday: Weekday, inMonth month: Int, year: Int) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current

        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return dates
        }

        guard let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return dates
        }

        var currentDate = monthStart
        while currentDate <= monthEnd {
            let currentWeekday = calendar.component(.weekday, from: currentDate)
            if currentWeekday == weekday.rawValue {
                dates.append(currentDate)
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates
    }
}

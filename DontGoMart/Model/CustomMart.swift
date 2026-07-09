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

// 휴무 반복 방식
// - weekOfMonth: 매월 정해진 주차 (예: 2·4주차 화요일). 월마다 리셋되므로 격주와 다름.
// - biweekly: 격주 (시작일부터 정확히 14일 간격). 월 경계와 무관하게 계속 이어짐.
enum ClosureFrequency: String, Codable {
    case weekOfMonth
    case biweekly
}

// 커스텀 마트 패턴
struct ClosurePattern: Hashable, Identifiable {
    let id: UUID
    let weeks: Set<WeekOfMonth>  // weekOfMonth 방식에서 선택된 주차들 (예: [2, 4])
    let weekday: Weekday  // 요일
    let frequency: ClosureFrequency  // 반복 방식
    let anchorDate: Date?  // biweekly(격주) 기준 시작일 — 이 날 + 14일마다 휴무

    init(id: UUID = UUID(),
         weeks: Set<WeekOfMonth> = [],
         weekday: Weekday,
         frequency: ClosureFrequency = .weekOfMonth,
         anchorDate: Date? = nil) {
        self.id = id
        self.weeks = weeks
        self.weekday = weekday
        self.frequency = frequency
        self.anchorDate = anchorDate
    }

    private static let anchorFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M/d"
        return f
    }()

    var displayText: String {
        switch frequency {
        case .biweekly:
            if let anchor = anchorDate {
                return "격주 \(weekday.displayName)요일 · \(Self.anchorFormatter.string(from: anchor)) 시작"
            }
            return "격주 \(weekday.displayName)요일"
        case .weekOfMonth:
            // 모든 주차가 선택되면 '매주'로 간결하게 표시 (매주 화요일 등)
            if weeks.count == WeekOfMonth.allCases.count {
                return "매주 \(weekday.displayName)요일"
            }
            let weekText = weeks.sorted(by: { $0.rawValue < $1.rawValue })
                .map { $0.displayName }
                .joined(separator: ", ")
            return "\(weekText) \(weekday.displayName)요일"
        }
    }
}

// 기존 저장 데이터(주차 방식만 있던 시절) 호환을 위해 frequency/anchorDate 는 없으면 기본값 사용
extension ClosurePattern: Codable {
    enum CodingKeys: String, CodingKey {
        case id, weeks, weekday, frequency, anchorDate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        weeks = try c.decodeIfPresent(Set<WeekOfMonth>.self, forKey: .weeks) ?? []
        weekday = try c.decode(Weekday.self, forKey: .weekday)
        frequency = try c.decodeIfPresent(ClosureFrequency.self, forKey: .frequency) ?? .weekOfMonth
        anchorDate = try c.decodeIfPresent(Date.self, forKey: .anchorDate)
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

        // 격주(biweekly) 패턴: 기준일부터 14일 간격으로 해당 연도 안의 날짜 계산
        for pattern in patterns where pattern.frequency == .biweekly {
            closedDates.append(contentsOf: biweeklyDates(anchor: pattern.anchorDate, year: year, calendar: calendar))
        }

        // 주차(weekOfMonth) 패턴: 매월 정해진 주차의 요일
        for month in 1...12 {
            for pattern in patterns where pattern.frequency == .weekOfMonth {
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

    // 격주 휴무일: anchor(기준 시작일)에서 정확히 14일 간격으로, 지정 연도에 속하는 날짜들
    private func biweeklyDates(anchor: Date?, year: Int, calendar: Calendar) -> [Date] {
        guard let anchor else { return [] }
        guard let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let yearEnd = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) else {
            return []
        }

        var dates: [Date] = []
        var current = calendar.startOfDay(for: anchor)

        // 기준일이 연도보다 뒤라면 뒤로, 앞이라면 연도 시작 부근까지 14일씩 이동
        while current > yearStart {
            guard let prev = calendar.date(byAdding: .day, value: -14, to: current) else { break }
            current = prev
        }
        while current < yearStart {
            guard let next = calendar.date(byAdding: .day, value: 14, to: current) else { break }
            current = next
        }

        // 연도 안에서 14일씩 전진하며 수집
        while current <= yearEnd {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 14, to: current) else { break }
            current = next
        }

        return dates
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

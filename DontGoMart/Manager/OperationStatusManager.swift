//
//  OperationStatusManager.swift
//  DontGoMart
//
//  Created by Claude Code
//

import Foundation
import Combine

enum OperationStatus {
    case open
    case closed
    case unknown

    var displayText: String {
        switch self {
        case .open:
            return "영업중"
        case .closed:
            return "휴무"
        case .unknown:
            return "알 수 없음"
        }
    }

    var emoji: String {
        switch self {
        case .open:
            return "✅"
        case .closed:
            return "🚫"
        case .unknown:
            return "❓"
        }
    }
}

class OperationStatusManager: ObservableObject {
    static let shared = OperationStatusManager()

    private init() {}

    func checkStatus(for martType: MartType, on date: Date = Date()) -> OperationStatus {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        let closedDates = tasks.filter { task in
            return task.type == martType
        }

        for closedDate in closedDates {
            let closedDay = calendar.startOfDay(for: closedDate.taskDate)
            if calendar.isDate(today, inSameDayAs: closedDay) {
                return .closed
            }
        }

        return .open
    }

    func nextClosedDate(for martType: MartType, from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        let futureClosed = tasks.filter { task in
            task.type == martType && calendar.startOfDay(for: task.taskDate) >= today
        }.sorted { $0.taskDate < $1.taskDate }

        return futureClosed.first?.taskDate
    }

    func daysUntilNextClosed(for martType: MartType, from date: Date = Date()) -> Int? {
        guard let nextClosed = nextClosedDate(for: martType, from: date) else {
            return nil
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: nextClosed))
        return components.day
    }

    func canGoToday(for martType: MartType) -> Bool {
        return checkStatus(for: martType) == .open
    }

    func formatDDay(_ days: Int) -> String {
        if days == 0 {
            return "오늘"
        } else if days == 1 {
            return "내일"
        } else {
            return "D-\(days)"
        }
    }
}

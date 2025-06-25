//
//  DontGoMartApp.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/15.
//

import SwiftUI

@main
struct DontGoMartApp: App {
    
    var body: some Scene {
        WindowGroup {
            ClosedDaysView()
                .onAppear {
                    tasks.append(contentsOf: generateBiweeklyTasks(
                        forYear: Calendar.current.component(.year, from: Date()),
                        weekdays: [
                            (.sunday, .second, "2번째 일요일"),
                            (.sunday, .fourth, "4번째 일요일")
                        ],
                        martType: .normal
                    ))
                    tasks.append(contentsOf: generateBiweeklyTasks(
                        forYear: Calendar.current.component(.year, from: Date()),
                        weekdays: [
                            (.sunday, .second, "2번째 일요일"),
                            (.sunday, .fourth, "4번째 일요일")
                        ],
                        martType: .costco(type: .normal)
                    ))
                    tasks.append(contentsOf: generateBiweeklyTasks(
                        forYear: Calendar.current.component(.year, from: Date()),
                        weekdays: [
                            (.monday, .second, "2번째 월요일"),
                            (.monday, .fourth, "4번째 월요일")
                        ],
                        martType: .costco(type: .daegu)
                    ))
                    tasks.append(contentsOf: generateBiweeklyTasks(
                        forYear: Calendar.current.component(.year, from: Date()),
                        weekdays: [
                            (.wednesday, .second, "2번째 수요일"),
                            (.wednesday, .fourth, "4번째 수요일")
                        ],
                        martType: .costco(type: .ilsan)
                    ))
                    tasks.append(contentsOf: generateBiweeklyTasks(
                        forYear: Calendar.current.component(.year, from: Date()),
                        weekdays: [
                            (.wednesday, .second, "2번째 수요일"),
                            (.sunday, .fourth, "4번째 일요일")
                        ],
                        martType: .costco(type: .ulsan)
                    ))
                    WidgetManager.shared.updateWidget()
                    
                    Task {
                        await setupSmartNotifications()
                    }
                }
        }
    }
        
    private func setupSmartNotifications() async {
        let notificationManager = NotificationManager.shared
        
        let userDefaults = UserDefaults(suiteName: Utillity.appGroupId)
        let isNotificationEnabled = userDefaults?.bool(forKey: AppStorageKeys.notificationEnabled) ?? false
        
        guard isNotificationEnabled else { return }
        
        let status = await notificationManager.checkAuthorizationStatus()
        
        switch status {
        case .authorized:
            await notificationManager.setupSmartNotifications(for: tasks)
        case .notDetermined:
            break
        default:
            break
        }
    }

    private func generateBiweeklyTasks(
        forYear year: Int,
        monthRange: Range<Int> = 1..<13,
        weekdays: [(Calendar.Weekday, Calendar.Ordinal, String)],
        martType: MartType
    ) -> [MetaMartsClosedDays] {
        var tasks: [MetaMartsClosedDays] = []
        let calendar = Calendar.current
        
        let yearRange = [year - 1, year, year + 1]
        
        for year in yearRange {
            print("\(year) - \(martType) Task Generate")
            for month in monthRange {
                for (weekday, ordinal, title) in weekdays {
                    if let date = findPatternDay(of: weekday, ordinal: ordinal, inMonth: month, year: year, calendar: calendar) {
                        tasks.append(MetaMartsClosedDays(type: martType, task: [MartCloseData(title: title)], taskDate: date))
                    }
                }
            }
        }
        
        return tasks
    }
    
    func findPatternDay(of weekday: Calendar.Weekday, ordinal: Calendar.Ordinal, inMonth month: Int, year: Int, calendar: Calendar) -> Date? {
        var dateComponents = DateComponents(year: year, month: month)
        
        if let firstDayOfMonth = calendar.date(from: dateComponents) {
            let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
            var targetDay = weekday.rawValue
            
            let daysToAdd = (targetDay - firstWeekday + 7) % 7
            dateComponents.day = 1 + daysToAdd
            
            if let targetDate = calendar.date(from: dateComponents) {
                if ordinal == .first {
                    return targetDate
                } else if ordinal == .second {
                    return calendar.date(byAdding: .weekOfMonth, value: 1, to: targetDate)
                } else if ordinal == .third {
                    return calendar.date(byAdding: .weekOfMonth, value: 2, to: targetDate)
                } else if ordinal == .fourth {
                    return calendar.date(byAdding: .weekOfMonth, value: 3, to: targetDate)
                } else if ordinal == .fifth {
                    return calendar.date(byAdding: .weekOfMonth, value: 4, to: targetDate)
                }
            }
        }
        
        return nil
    }
}

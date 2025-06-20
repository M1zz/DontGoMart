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
                    tasks.append(contentsOf: modifiedGenerateBiweeklyTasks(
                        forYear: Calendar.current.component(.year, from: Date()),
                        weekdays: [
                            (.sunday, .second, "2번째 일요일"),
                            (.sunday, .fourth, "4번째 일요일")
                        ],
                        martType: .normal
                    ))
                    tasks.append(contentsOf: modifiedGenerateBiweeklyTasks(
                        forYear: Calendar.current.component(.year, from: Date()),
                        weekdays: [
                            (.sunday, .second, "2번째 일요일"),
                            (.sunday, .fourth, "4번째 일요일")
                        ],
                        martType: .costco(type: .normal)
                    ))
                    tasks.append(contentsOf: modifiedGenerateBiweeklyTasks(
                        forYear: Calendar.current.component(.year, from: Date()),
                        weekdays: [
                            (.monday, .second, "2번째 월요일"),
                            (.monday, .fourth, "4번째 월요일")
                        ],
                        martType: .costco(type: .daegu)
                    ))
                    tasks.append(contentsOf: modifiedGenerateBiweeklyTasks(
                        forYear: Calendar.current.component(.year, from: Date()),
                        weekdays: [
                            (.wednesday, .second, "2번째 수요일"),
                            (.wednesday, .fourth, "4번째 수요일")
                        ],
                        martType: .costco(type: .ilsan)
                    ))
                    tasks.append(contentsOf: modifiedGenerateBiweeklyTasks(
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
    
    /// 스마트 알림 초기 설정 (사용자 설정 고려)
    private func setupSmartNotifications() async {
        let notificationManager = NotificationManager.shared
        
        // 사용자가 알림을 활성화했는지 확인
        let userDefaults = UserDefaults(suiteName: Utillity.appGroupId)
        let isNotificationEnabled = userDefaults?.bool(forKey: AppStorageKeys.notificationEnabled) ?? false
        
        guard isNotificationEnabled else {
            print("🔕 사용자가 알림을 비활성화했으므로 알림을 설정하지 않습니다.")
            return
        }
        
        // 권한 상태 확인
        let status = await notificationManager.checkAuthorizationStatus()
        
        if status == .authorized {
            // 이미 권한이 있으면 바로 알림 설정
            await notificationManager.setupSmartNotifications(for: tasks)
        } else if status == .notDetermined {
            // 권한이 결정되지 않았으면 요청 (사용자가 직접 설정에서 켤 때까지 대기)
            print("⏳ 알림 권한이 결정되지 않았습니다. 설정에서 알림을 활성화해주세요.")
        } else {
            print("❌ 알림 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.")
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
        
        // 각 달을 순회하면서 요일과 주차에 맞는 날짜를 찾음
        for month in monthRange {
            for (weekday, ordinal, title) in weekdays {
                if let date = findPatternDay(of: weekday, ordinal: ordinal, inMonth: month, year: year, calendar: calendar) {
                    tasks.append(MetaMartsClosedDays(type: martType, task: [MartCloseData(title: title)], taskDate: date))
                }
            }
        }
        
        return tasks
    }
    
    func modifiedGenerateBiweeklyTasks(
        forYear year: Int,
        monthRange: Range<Int> = 1..<13,
        weekdays: [(Calendar.Weekday, Calendar.Ordinal, String)],
        martType: MartType
    ) -> [MetaMartsClosedDays] {
        var tasks: [MetaMartsClosedDays] = []
        let calendar = Calendar.current
        
        let yearRange = [year - 1, year, year + 1]
        // 각 달을 순회하면서 요일과 주차에 맞는 날짜를 찾음
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
        // 날짜 컴포넌트 설정
        var dateComponents = DateComponents(year: year, month: month)
        
        // 해당 월의 첫 번째 날짜를 가져와서, 그 날이 어떤 요일인지 확인
        if let firstDayOfMonth = calendar.date(from: dateComponents) {
            let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
            var targetDay = weekday.rawValue
            
            // 첫 번째 날짜의 요일을 맞추기 위해 첫 번째 날을 이동
            let daysToAdd = (targetDay - firstWeekday + 7) % 7
            dateComponents.day = 1 + daysToAdd  // 첫 번째 목표 날짜로 설정
            
            if let targetDate = calendar.date(from: dateComponents) {
                // 두 번째, 네 번째 등 원하는 ordinal 번째 날짜 찾기
                if ordinal == .first {
                    return targetDate
                } else if ordinal == .second {
                    return calendar.date(byAdding: .weekOfMonth, value: 1, to: targetDate)  // 2번째
                } else if ordinal == .third {
                    return calendar.date(byAdding: .weekOfMonth, value: 2, to: targetDate)  // 3번째
                } else if ordinal == .fourth {
                    return calendar.date(byAdding: .weekOfMonth, value: 3, to: targetDate)  // 4번째
                } else if ordinal == .fifth {
                    return calendar.date(byAdding: .weekOfMonth, value: 4, to: targetDate)  // 5번째
                }
            }
        }
        
        return nil
    }
}

//
//  DontGoMartApp.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/15.
//

import SwiftUI

@main
struct DontGoMartApp: App {

    init() {
        // 앱 시작 시 즉시 tasks 초기화
        initializeTasks()
    }

    var body: some Scene {
        WindowGroup {
            ClosedDaysView()
                .onAppear {
                    // 위젯 업데이트 및 알림 설정
                    WidgetManager.shared.updateWidget()

                    Task {
                        await setupSmartNotifications()
                    }
                }
        }
    }

    private func initializeTasks() {
        // tasks 배열이 이미 초기화되어 있으면 스킵
        guard tasks.isEmpty else { return }

        let currentYear = Calendar.current.component(.year, from: Date())

        // === 대형마트 패턴들 ===

        // 1. 대형마트 일요일 휴무 (전국 대부분 지역)
        tasks.append(contentsOf: generateBiweeklyTasks(
            forYear: currentYear,
            weekdays: [
                (.sunday, .second, "2번째 일요일"),
                (.sunday, .fourth, "4번째 일요일")
            ],
            martType: .normal(type: .sunday)
        ))

        // 2. 대형마트 수요일 휴무 (경기 일부, 청주)
        tasks.append(contentsOf: generateBiweeklyTasks(
            forYear: currentYear,
            weekdays: [
                (.wednesday, .second, "2번째 수요일"),
                (.wednesday, .fourth, "4번째 수요일")
            ],
            martType: .normal(type: .wednesday)
        ))

        // 3. 대형마트 울산 (2번째 수요일 + 4번째 일요일)
        tasks.append(contentsOf: generateBiweeklyTasks(
            forYear: currentYear,
            weekdays: [
                (.wednesday, .second, "2번째 수요일"),
                (.sunday, .fourth, "4번째 일요일")
            ],
            martType: .normal(type: .mixed)
        ))

        // 4. 대형마트 제주 (2번째 금요일 + 4번째 토요일)
        tasks.append(contentsOf: generateBiweeklyTasks(
            forYear: currentYear,
            weekdays: [
                (.friday, .second, "2번째 금요일"),
                (.saturday, .fourth, "4번째 토요일")
            ],
            martType: .normal(type: .jeju)
        ))

        // === 코스트코 패턴들 ===

        // 5. 코스트코 일반매장
        tasks.append(contentsOf: generateBiweeklyTasks(
            forYear: currentYear,
            weekdays: [
                (.sunday, .second, "2번째 일요일"),
                (.sunday, .fourth, "4번째 일요일")
            ],
            martType: .costco(type: .normal)
        ))

        // 6. 코스트코 대구점
        tasks.append(contentsOf: generateBiweeklyTasks(
            forYear: currentYear,
            weekdays: [
                (.monday, .second, "2번째 월요일"),
                (.monday, .fourth, "4번째 월요일")
            ],
            martType: .costco(type: .daegu)
        ))

        // 7. 코스트코 일산점
        tasks.append(contentsOf: generateBiweeklyTasks(
            forYear: currentYear,
            weekdays: [
                (.wednesday, .second, "2번째 수요일"),
                (.wednesday, .fourth, "4번째 수요일")
            ],
            martType: .costco(type: .ilsan)
        ))

        // 8. 코스트코 울산점
        tasks.append(contentsOf: generateBiweeklyTasks(
            forYear: currentYear,
            weekdays: [
                (.wednesday, .second, "2번째 수요일"),
                (.sunday, .fourth, "4번째 일요일")
            ],
            martType: .costco(type: .ulsan)
        ))

        // === 설날/추석 공휴일 ===
        tasks.append(contentsOf: generateHolidayTasks(forYear: currentYear))

        // === 커스텀 마트 ===
        CustomMartManager.shared.loadCustomMarts()
        CustomMartManager.shared.updateTasksWithCustomMarts()

        print("✅ Tasks 초기화 완료: \(tasks.count)개")
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

    // 설날/추석 휴무일 생성 (음력 기반)
    private func generateHolidayTasks(forYear year: Int) -> [MetaMartsClosedDays] {
        var tasks: [MetaMartsClosedDays] = []
        let calendar = Calendar.current

        // 2024-2026년 설날/추석 날짜 (음력이므로 매년 변동)
        let holidays: [Int: [(month: Int, day: Int, name: String)]] = [
            2024: [
                (2, 10, "설날"),
                (9, 17, "추석")
            ],
            2025: [
                (1, 29, "설날"),
                (10, 6, "추석")
            ],
            2026: [
                (2, 17, "설날"),
                (9, 25, "추석")
            ],
            2027: [
                (2, 6, "설날"),
                (9, 15, "추석")
            ]
        ]

        // 작년, 올해, 내년 데이터 생성
        for targetYear in [year - 1, year, year + 1] {
            if let yearHolidays = holidays[targetYear] {
                for holiday in yearHolidays {
                    let dateComponents = DateComponents(year: targetYear, month: holiday.month, day: holiday.day)
                    if let date = calendar.date(from: dateComponents) {
                        tasks.append(MetaMartsClosedDays(
                            type: .holiday,
                            task: [MartCloseData(title: holiday.name)],
                            taskDate: date
                        ))
                        print("\(targetYear) - \(holiday.name) (\(holiday.month)/\(holiday.day)) 추가")
                    }
                }
            }
        }

        return tasks
    }
}

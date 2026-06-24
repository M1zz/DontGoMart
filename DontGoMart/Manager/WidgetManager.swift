//
//  WidgetManager.swift
//  DontGoMart
//
//  Created by 황석현 on 1/7/25.
//

import SwiftUI
import WidgetKit

class WidgetManager {
    static let shared = WidgetManager()
    private init() {}
    
    func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateWidget() {
        debugLog("==========updateWidget==========")
        self.updateUpcomingClosedList()
        self.updateMultiMartHolidayText()
        self.updateMultiMartTwoHolidayText()
        self.reloadWidget()
    }

    /// 앞으로의 휴무일 목록을 앱그룹에 저장한다.
    /// 위젯은 이 목록에서 '표시 중인 날(entry.date) 이후 가장 가까운 휴무일' 을 직접 골라
    /// D-Day 를 매일 다시 계산한다. 덕분에 앱을 실행하지 않아도 하루가 지나면
    /// 위젯의 날짜·D-Day 가 자동으로 다음 휴무일로 넘어간다.
    private func updateUpcomingClosedList() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)

        let selectedMartTypes = MartSelectionManager.shared.getSelectedMartTypes()

        guard !selectedMartTypes.isEmpty else {
            defaults?.removeObject(forKey: AppStorageKeys.widgetUpcomingDates)
            defaults?.removeObject(forKey: AppStorageKeys.widgetUpcomingMartNames)
            defaults?.removeObject(forKey: AppStorageKeys.widgetUpcomingMartKeys)
            return
        }

        // 넉넉한 지평선(다음 24개)을 저장해 앱을 한동안 안 켜도 위젯이 스스로 굴러가도록 한다.
        let upcoming = tasks
            .filter { selectedMartTypes.contains($0.type) && $0.taskDate >= today }
            .sorted { $0.taskDate < $1.taskDate }
            .prefix(24)

        let dates = upcoming.map { $0.taskDate.timeIntervalSince1970 }
        let names = upcoming.map { $0.type.widgetDisplayName }
        let keys = upcoming.map { $0.type.storageKey }

        defaults?.set(dates, forKey: AppStorageKeys.widgetUpcomingDates)
        defaults?.set(names, forKey: AppStorageKeys.widgetUpcomingMartNames)
        defaults?.set(keys, forKey: AppStorageKeys.widgetUpcomingMartKeys)

        debugLog("Upcoming list saved: \(dates.count) dates")
    }

    private static let emptyMartText = String(localized: "마트 휴무")

    private func localizedHolidayText(daysDifference: Int, martName: String) -> String {
        switch daysDifference {
        case 1:
            return String(format: String(localized: "내일 %@ 휴무"), martName)
        case 2...6:
            return String(format: String(localized: "이번 주 %@ 휴무"), martName)
        default:
            return String(format: String(localized: "%@ 휴무"), martName)
        }
    }

    // 선택된 모든 마트 중 가장 가까운 휴무일 업데이트 (날짜 기반)
    func updateMultiMartHolidayText() {
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: Date())
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)

        let martSelection = MartSelectionManager.shared
        let selectedMartTypes = martSelection.getSelectedMartTypes()

        guard !selectedMartTypes.isEmpty else {
            defaults?.set(Self.emptyMartText, forKey: AppStorageKeys.widgetHolidayText)
            defaults?.removeObject(forKey: AppStorageKeys.widgetNextClosedDate)
            defaults?.removeObject(forKey: AppStorageKeys.widgetNextClosedMartName)
            return
        }

        let nextClosedDate = tasks
            .filter { task in
                selectedMartTypes.contains(task.type) && task.taskDate >= entryDate
            }
            .sorted { $0.taskDate < $1.taskDate }
            .first

        guard let closedDate = nextClosedDate else {
            defaults?.set(Self.emptyMartText, forKey: AppStorageKeys.widgetHolidayText)
            defaults?.removeObject(forKey: AppStorageKeys.widgetNextClosedDate)
            defaults?.removeObject(forKey: AppStorageKeys.widgetNextClosedMartName)
            return
        }

        defaults?.set(closedDate.taskDate.timeIntervalSince1970, forKey: AppStorageKeys.widgetNextClosedDate)
        defaults?.set(closedDate.type.widgetDisplayName, forKey: AppStorageKeys.widgetNextClosedMartName)

        // 기존 텍스트 기반 데이터도 호환성을 위해 유지
        let daysDifference = calendar.dateComponents([.day], from: entryDate, to: closedDate.taskDate).day ?? -1
        defaults?.set(localizedHolidayText(daysDifference: daysDifference, martName: closedDate.type.widgetDisplayName),
                      forKey: AppStorageKeys.widgetHolidayText)

        debugLog("HolidayText Update Success: \(closedDate.type.displayName)")
    }

    // 선택된 모든 마트 중 가장 가까운 2개의 휴무일 업데이트 (날짜 기반)
    func updateMultiMartTwoHolidayText() {
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: Date())
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)

        // 선택된 마트 타입들 가져오기
        let martSelection = MartSelectionManager.shared
        let selectedMartTypes = martSelection.getSelectedMartTypes()

        guard !selectedMartTypes.isEmpty else {
            let defaultData = [Self.emptyMartText, "-", "D-?", "-", "D-?"]
            defaults?.set(defaultData.joined(separator: "|"), forKey: AppStorageKeys.widgetTwoHolidayText)
            defaults?.removeObject(forKey: AppStorageKeys.widgetNextClosedDate)
            defaults?.removeObject(forKey: AppStorageKeys.widgetSecondClosedDate)
            return
        }

        let nextTwoHolidays = tasks
            .filter { task in
                selectedMartTypes.contains(task.type) && task.taskDate >= entryDate
            }
            .sorted { $0.taskDate < $1.taskDate }
            .prefix(2)

        guard nextTwoHolidays.count >= 2 else {
            debugLog("Error: Not enough upcoming holidays found")
            return
        }

        let firstHoliday = Array(nextTwoHolidays)[0]
        let secondHoliday = Array(nextTwoHolidays)[1]

        defaults?.set(firstHoliday.taskDate.timeIntervalSince1970, forKey: AppStorageKeys.widgetNextClosedDate)
        defaults?.set(secondHoliday.taskDate.timeIntervalSince1970, forKey: AppStorageKeys.widgetSecondClosedDate)
        defaults?.set(firstHoliday.type.widgetDisplayName, forKey: AppStorageKeys.widgetNextClosedMartName)
        defaults?.set(secondHoliday.type.widgetDisplayName, forKey: AppStorageKeys.widgetSecondClosedMartName)
        defaults?.set(firstHoliday.type.storageKey, forKey: AppStorageKeys.widgetMartStorageKey)

        let firstHolidayText = firstHoliday.taskDate.getMonthDayWeekday()
        let secondHolidayText = secondHoliday.taskDate.getMonthDayWeekday()

        guard let firstHolidayDday = calendar.dateComponents([.day], from: entryDate, to: firstHoliday.taskDate).day else { return }
        guard let secondHolidayDday = calendar.dateComponents([.day], from: entryDate, to: secondHoliday.taskDate).day else { return }

        let saveData = [
            String(format: String(localized: "%@ 휴무"), firstHoliday.type.widgetDisplayName),
            "\(firstHolidayText.month)\(firstHolidayText.day) (\(firstHolidayText.weekday))",
            "D-\(firstHolidayDday)",
            "\(secondHolidayText.month)\(secondHolidayText.day) (\(secondHolidayText.weekday))",
            "D-\(secondHolidayDday)",
            firstHoliday.type.storageKey
        ]
        let saveString = saveData.joined(separator: "|")
        defaults?.set(saveString, forKey: AppStorageKeys.widgetTwoHolidayText)
        debugLog("Saved String: \(saveString)")
        debugLog("TwoHolidayText Update Success")
    }
    
}

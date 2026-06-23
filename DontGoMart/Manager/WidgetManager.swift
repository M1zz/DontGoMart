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
        self.updateMultiMartHolidayText()
        self.updateMultiMartTwoHolidayText()
        self.reloadWidget()
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

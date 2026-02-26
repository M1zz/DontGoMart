//
//  WidgetManager.swift
//  Klosed
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
        print("==========updateWidget==========")
        self.updateMultiMartHolidayText()
        self.updateMultiMartTwoHolidayText()
        self.reloadWidget()
    }

    // 선택된 모든 마트 중 가장 가까운 휴무일 업데이트 (날짜 기반)
    func updateMultiMartHolidayText() {
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: Date())
        let defaults = UserDefaults(suiteName: Utillity.appGroupId)

        // 선택된 마트 타입들 가져오기
        let martSelection = MartSelectionManager.shared
        let selectedMartTypes = martSelection.getSelectedMartTypes()

        guard !selectedMartTypes.isEmpty else {
            defaults?.set("Klosed 마트", forKey: AppStorageKeys.widgetHolidayText)
            defaults?.removeObject(forKey: AppStorageKeys.widgetNextClosedDate)
            defaults?.removeObject(forKey: AppStorageKeys.widgetNextClosedMartName)
            return
        }

        // 선택된 마트들의 가장 가까운 휴무일 찾기
        let nextClosedDate = tasks
            .filter { task in
                selectedMartTypes.contains(task.type) && task.taskDate >= entryDate
            }
            .sorted { $0.taskDate < $1.taskDate }
            .first

        guard let closedDate = nextClosedDate else {
            defaults?.set("Klosed Mart", forKey: AppStorageKeys.widgetHolidayText)
            defaults?.removeObject(forKey: AppStorageKeys.widgetNextClosedDate)
            defaults?.removeObject(forKey: AppStorageKeys.widgetNextClosedMartName)
            return
        }

        // 날짜(TimeInterval)와 마트명을 저장하여 위젯이 자체적으로 D-Day 계산 가능
        defaults?.set(closedDate.taskDate.timeIntervalSince1970, forKey: AppStorageKeys.widgetNextClosedDate)
        defaults?.set(closedDate.type.widgetDisplayName, forKey: AppStorageKeys.widgetNextClosedMartName)

        // 기존 텍스트 기반 데이터도 호환성을 위해 유지
        let daysDifference = calendar.dateComponents([.day], from: entryDate, to: closedDate.taskDate).day ?? -1
        switch daysDifference {
        case 0:
            defaults?.set("Klosed \(closedDate.type.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
        case 1:
            defaults?.set("Tomorrow Klosed \(closedDate.type.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
        case 2...6:
            let dayText = "This week"
            defaults?.set("\(dayText) Klosed \(closedDate.type.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
        default:
            defaults?.set("Klosed \(closedDate.type.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
        }

        print("HolidayText Update Success: \(closedDate.type.displayName)")
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
            let defaultData = ["Klosed Mart", "No info", "D-?", "No info", "D-?"]
            defaults?.set(defaultData.joined(separator: "|"), forKey: AppStorageKeys.widgetTwoHolidayText)
            defaults?.removeObject(forKey: AppStorageKeys.widgetNextClosedDate)
            defaults?.removeObject(forKey: AppStorageKeys.widgetSecondClosedDate)
            return
        }

        // 선택된 마트들의 다가오는 휴무일 찾기
        let nextTwoHolidays = tasks
            .filter { task in
                selectedMartTypes.contains(task.type) && task.taskDate >= entryDate
            }
            .sorted { $0.taskDate < $1.taskDate }
            .prefix(2)

        guard nextTwoHolidays.count >= 2 else {
            print("Error: Not enough upcoming holidays found")
            return
        }

        let firstHoliday = Array(nextTwoHolidays)[0]
        let secondHoliday = Array(nextTwoHolidays)[1]

        // 날짜(TimeInterval)를 저장하여 위젯이 자체적으로 D-Day 계산 가능
        defaults?.set(firstHoliday.taskDate.timeIntervalSince1970, forKey: AppStorageKeys.widgetNextClosedDate)
        defaults?.set(secondHoliday.taskDate.timeIntervalSince1970, forKey: AppStorageKeys.widgetSecondClosedDate)
        defaults?.set(firstHoliday.type.widgetDisplayName, forKey: AppStorageKeys.widgetNextClosedMartName)
        defaults?.set(secondHoliday.type.widgetDisplayName, forKey: AppStorageKeys.widgetSecondClosedMartName)
        defaults?.set(firstHoliday.type.storageKey, forKey: AppStorageKeys.widgetMartStorageKey)

        // 기존 텍스트 기반 데이터도 호환성을 위해 유지
        let firstHolidayText = firstHoliday.taskDate.getMonthDayWeekday()
        let secondHolidayText = secondHoliday.taskDate.getMonthDayWeekday()

        guard let firstHolidayDday = calendar.dateComponents([.day], from: entryDate, to: firstHoliday.taskDate).day else { return }
        guard let secondHolidayDday = calendar.dateComponents([.day], from: entryDate, to: secondHoliday.taskDate).day else { return }

        let saveData = [
            "Klosed \(firstHoliday.type.widgetDisplayName)",
            "\(firstHolidayText.month)\(firstHolidayText.day) (\(firstHolidayText.weekday))",
            "D-\(firstHolidayDday)",
            "\(secondHolidayText.month)\(secondHolidayText.day) (\(secondHolidayText.weekday))",
            "D-\(secondHolidayDday)",
            firstHoliday.type.storageKey
        ]
        let saveString = saveData.joined(separator: "|")
        defaults?.set(saveString, forKey: AppStorageKeys.widgetTwoHolidayText)
        print("Saved String: \(saveString)")
        print("TwoHolidayText Update Success")
    }
    
    func twoHolidayText(isCostco: Bool, selectedBranch: Int) {

        print("==========twoHolidayText===========")
        print("함수 내 selectedBranch: \(String(describing: selectedBranch))")
        print("함수 내 isNormal: \(String(describing: isCostco))")

        var selectedMartType: MartType = .normal(type: .sunday)
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: Date())

        // 마트 유형 설정
        if selectedBranch == 0 || !isCostco {
            selectedMartType = .normal(type: .sunday)
            UserDefaults(suiteName: Utillity.appGroupId)?.set(0, forKey: AppStorageKeys.selectedBranch)
        } else {
            switch selectedBranch {
            case 1: selectedMartType = .costco(type: .normal)
            case 2: selectedMartType = .costco(type: .daegu)
            case 3: selectedMartType = .costco(type: .ilsan)
            case 4: selectedMartType = .costco(type: .ulsan)
            default:
                print("Wrong MartType")
                return
            }
        }
        
        print("함수 내 selectedMartType: \(selectedMartType)")
        let costcoHolidays = tasks.filter { $0.type == selectedMartType }
        
        let nextTwoHoliday = costcoHolidays
            .filter { $0.taskDate >= entryDate } // 오늘 이후의 휴일만 필터링
            .sorted { $0.taskDate < $1.taskDate } // 날짜순 정렬
        
        guard !nextTwoHoliday.isEmpty else {
            print("Error: No upcoming holidays found(twoHolidayText)")
            return
        }
        
        let firstHolidayText = nextTwoHoliday[0].taskDate.getMonthDayWeekday()
        let secondHolidayText = nextTwoHoliday[1].taskDate.getMonthDayWeekday()
        guard let firstHolidayDdayText = calendar.dateComponents([.day], from: entryDate, to: nextTwoHoliday[0].taskDate).day else { return }
        guard let secondHolidayDdayText = calendar.dateComponents([.day], from: entryDate, to: nextTwoHoliday[1].taskDate).day else { return }
        
        let saveData = [
            "Klosed \(selectedMartType.widgetDisplayName)",
            "\(firstHolidayText.month)\(firstHolidayText.day) (\(firstHolidayText.weekday))",
            "D\(String(describing: firstHolidayDdayText))",
            "\(secondHolidayText.month)\(secondHolidayText.day) (\(secondHolidayText.weekday))",
            "D\(String(describing: secondHolidayDdayText))"
        ]
        let saveString = saveData.joined(separator: "|")
        UserDefaults(suiteName: Utillity.appGroupId)?.set(saveString, forKey: AppStorageKeys.widgetTwoHolidayText)
        print("Saved String: \(saveString)")
        
        print("TwoHolidayText Update Success")
    }
    
    func holidayText(isCostco: Bool, selectedBranch: Int) {

        print("==========holidayText============")
        print("함수 내 selectedBranch: \(String(describing: selectedBranch))")
        print("함수 내 isNormal: \(String(describing: isCostco))")

        var selectedMartType: MartType = .normal(type: .sunday)
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: Date())

        // 마트 유형 설정
        if selectedBranch == 0 || !isCostco {
            selectedMartType = .normal(type: .sunday)
            UserDefaults(suiteName: Utillity.appGroupId)?.set(0, forKey: AppStorageKeys.selectedBranch)
        } else {
            switch selectedBranch {
            case 1: selectedMartType = .costco(type: .normal)
            case 2: selectedMartType = .costco(type: .daegu)
            case 3: selectedMartType = .costco(type: .ilsan)
            case 4: selectedMartType = .costco(type: .ulsan)
            default:
                print("Wrong MartType")
                return
            }
        }
        
        // 가장 가까운 휴일 찾기
        print("함수 내 selectedMartType: \(selectedMartType)")
        let costcoHolidays = tasks.filter { $0.type == selectedMartType }
        
        // 가장 가까운 휴일 필터링
        let nextHoliday = costcoHolidays
            .filter { $0.taskDate >= entryDate } // 오늘 이후의 휴일만 필터링
            .sorted { $0.taskDate < $1.taskDate } // 날짜순 정렬
            .first // 가장 가까운 휴일 선택
        
        guard let nextHolidayDate = nextHoliday?.taskDate else {
            print("Error: No upcoming holidays found(holidayText)")
            return
        }
        
        // 날짜 차이 계산
        let daysDifference = calendar.dateComponents([.day], from: entryDate, to: nextHolidayDate).day ?? -1
        print("daysDifference:", daysDifference)
        print("entryDate:", entryDate)
        print("nextHolidayDate:", nextHolidayDate)
        
        // UserDefaults에 텍스트 저장
        switch daysDifference {
        case 0:
            UserDefaults(suiteName: Utillity.appGroupId)?.set("Klosed \(selectedMartType.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
        case 1:
            UserDefaults(suiteName: Utillity.appGroupId)?.set("Tomorrow Klosed \(selectedMartType.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
        case 2...6:
            let dayText: String
            switch selectedMartType {
            case .costco(type: .daegu): dayText = "Mon"
            case .costco(type: .ilsan): dayText = "Wed"
            case .costco(type: .ulsan): dayText = "Soon"
            default: dayText = "This week"
            }
            UserDefaults(suiteName: Utillity.appGroupId)?.set("\(dayText) Klosed \(selectedMartType.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
        default:
            UserDefaults(suiteName: Utillity.appGroupId)?.set("Klosed \(selectedMartType.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
            print("No relevant holiday text found")
        }
        
        print("HolidayText Update Success")
    }
    
}

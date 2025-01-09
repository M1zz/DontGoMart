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
    
    func holidayText() {
        var isNormal: Bool {
            UserDefaults(suiteName: Utillity.appGroupId)?.bool(forKey: AppStorageKeys.isNormal) ?? true
        }
        
        var selectedBranch: Int {
            UserDefaults(suiteName: Utillity.appGroupId)?.integer(forKey: AppStorageKeys.selectedBranch) ?? 1
        }
        print("함수 내 selectedBranch: \(selectedBranch)")
        print("함수 내 isNormal: \(isNormal)")
        
        var selectedMartType: MartType = .normal
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: Date())
        
        print("======================")
        
        // 마트 유형 설정
        if selectedBranch == 0 {
            selectedMartType = .normal
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
            print("No upcoming holidays found")
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
            UserDefaults(suiteName: Utillity.appGroupId)?.set("돈꼬 \(selectedMartType.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
        case 1:
            UserDefaults(suiteName: Utillity.appGroupId)?.set("내일 돈꼬 \(selectedMartType.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
        case 2...6:
            let dayText: String
            switch selectedMartType {
            case .costco(type: .daegu): dayText = "월요일"
            case .costco(type: .ilsan): dayText = "수요일"
            case .costco(type: .ulsan): dayText = "곧"
            default: dayText = "이번 주"
            }
            UserDefaults(suiteName: Utillity.appGroupId)?.set("\(dayText) 돈꼬 \(selectedMartType.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
        default:
            UserDefaults(suiteName: Utillity.appGroupId)?.set("꼬 \(selectedMartType.widgetDisplayName)", forKey: AppStorageKeys.widgetHolidayText)
            print("No relevant holiday text found")
        }
        
        self.reloadWidget()
        print("Widget Update Success")
    }
    
}

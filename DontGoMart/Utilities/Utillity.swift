//
//  Utillity.swift
//  DontGoMart
//
//  Created by 황석현 on 1/6/25.
//

import Foundation

enum Utillity {
    static let primuimAppName = "돈꼬마트 Pro"
    static let appName = "돈꼬마트"
    static let restorePurchases = String(localized: "구매복원")
    static let appGroupId = "group.com.leeo.DontGoMart"
}

@inlinable
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
#if DEBUG
    let message = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(message, terminator: terminator)
#endif
}

enum AppStorageKeys {
    static let selectedBranch = "selectedBranch"
    static let isCostco = "isCostco"
    static let isPremium = "isPremium"
    static let widgetHolidayText = "widgetHolidayText"
    static let widgetTwoHolidayText = "widgetTwoHolidayText"
    static let notificationEnabled = "notificationEnabled"
    static let notificationHour = "notificationHour"
    static let notificationMinute = "notificationMinute"
    static let beforeDayNotificationEnabled = "beforeDayNotificationEnabled"
    static let selectedMartTypes = "selectedMartTypes"
    // 과거 유료(Pro) 구매자 여부 — 후원자 배지 표시용 (한 번 true 면 유지)
    static let isLegacySupporter = "isLegacySupporter"
    // 위젯 날짜 기반 데이터 (자동 D-Day 계산용)
    static let widgetNextClosedDate = "widgetNextClosedDate" // TimeInterval
    static let widgetNextClosedMartName = "widgetNextClosedMartName" // String
    static let widgetSecondClosedDate = "widgetSecondClosedDate" // TimeInterval
    static let widgetSecondClosedMartName = "widgetSecondClosedMartName" // String
    static let widgetMartStorageKey = "widgetMartStorageKey" // String (마트 타입 색상용)
    // 다가오는 휴무일 목록 (위젯이 매일 스스로 '오늘 이후 다음 휴무일' 을 골라
    // D-Day 를 다시 계산할 수 있도록 앱이 미리 저장해 둔다. 평행 배열)
    static let widgetUpcomingDates = "widgetUpcomingDates"       // [Double] TimeInterval, 오름차순
    static let widgetUpcomingMartNames = "widgetUpcomingMartNames" // [String]
    static let widgetUpcomingMartKeys = "widgetUpcomingMartKeys"   // [String] storageKey
}

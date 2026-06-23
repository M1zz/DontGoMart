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
    static let shoppingReminderEnabled = "shoppingReminderEnabled"
    static let locationEnabled = "locationEnabled"
    static let selectedMartTypes = "selectedMartTypes"
    static let viewMode = "viewMode" // "week" or "month"
    static let favoriteMarts = "favoriteMarts"
    // 위젯 날짜 기반 데이터 (자동 D-Day 계산용)
    static let widgetNextClosedDate = "widgetNextClosedDate" // TimeInterval
    static let widgetNextClosedMartName = "widgetNextClosedMartName" // String
    static let widgetSecondClosedDate = "widgetSecondClosedDate" // TimeInterval
    static let widgetSecondClosedMartName = "widgetSecondClosedMartName" // String
    static let widgetMartStorageKey = "widgetMartStorageKey" // String (마트 타입 색상용)
}

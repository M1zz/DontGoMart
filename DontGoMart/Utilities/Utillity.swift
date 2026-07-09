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

    /// 위젯 탭 딥링크. 위젯이 소유 앱을 열 때는 스킴 등록 없이도 onOpenURL 로 전달된다.
    static let deepLinkScheme = "dontgomart"
    /// 캘린더 화면으로 여는 딥링크.
    static let calendarDeepLink = URL(string: "\(deepLinkScheme)://calendar")!
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
    static let notificationEnabled = "notificationEnabled"
    static let notificationHour = "notificationHour"
    static let notificationMinute = "notificationMinute"
    static let beforeDayNotificationEnabled = "beforeDayNotificationEnabled"
    // 주 알림 리드타임(휴무 며칠 전). 미설정 시 기본 3일 전.
    static let notificationLeadDays = "notificationLeadDays"
    static let selectedMartTypes = "selectedMartTypes"
    // 과거 유료(Pro) 구매자 여부 — 후원자 배지 표시용 (한 번 true 면 유지)
    static let isLegacySupporter = "isLegacySupporter"
    // 다가오는 휴무일 목록 (위젯이 매일 스스로 '오늘 이후 다음 휴무일' 을 골라
    // D-Day 를 다시 계산할 수 있도록 앱이 미리 저장해 둔다. [UpcomingClosedDay] JSON)
    static let widgetUpcomingList = "widgetUpcomingList" // Data (JSON)
}

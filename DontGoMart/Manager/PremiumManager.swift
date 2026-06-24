//
//  PremiumManager.swift
//  DontGoMart
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

/// 기능 잠금 관리
///
/// 모든 기능을 무료로 개방한다. 과거 유료(Pro) 잠금은 제거되었으며,
/// 호출부 호환을 위해 API 형태만 유지하고 항상 허용을 반환한다.
enum PremiumManager {

    /// 모든 기능이 개방되어 있으므로 항상 true.
    static var isPremium: Bool { true }

    /// 마트를 더 추가할 수 있는지 확인 (제한 없음)
    static func canAddMoreMarts(currentCount: Int) -> Bool { true }

    /// 장보기 아이템을 더 추가할 수 있는지 확인 (제한 없음)
    static func canAddMoreShoppingItems(currentCount: Int) -> Bool { true }

    /// 커스텀 마트를 추가할 수 있는지 확인 (제한 없음)
    static func canAddCustomMart(currentCount: Int) -> Bool { true }

    /// 알림 기능 사용 가능 여부 (항상 가능)
    static var canUseNotifications: Bool { true }

    /// 즐겨찾기 기능 사용 가능 여부 (항상 가능)
    static var canUseFavorites: Bool { true }
}

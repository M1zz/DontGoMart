//
//  PremiumManager.swift
//  Klosed
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

/// 프리미엄 기능 제한 관리
enum PremiumManager {

    // MARK: - 무료 사용자 제한값

    /// 무료 사용자가 선택할 수 있는 최대 마트 수
    static let freeMaxMartSelection = 1

    /// 무료 사용자 장보기 목록 최대 개수
    static let freeMaxShoppingItems = 5

    /// 무료 사용자 커스텀 마트 최대 개수
    static let freeMaxCustomMarts = 0

    // MARK: - 프리미엄 상태 확인

    static var isPremium: Bool {
        UserDefaults.standard.bool(forKey: AppStorageKeys.isPremium)
    }

    // MARK: - 기능별 잠금 체크

    /// 마트를 더 추가할 수 있는지 확인
    static func canAddMoreMarts(currentCount: Int) -> Bool {
        if isPremium { return true }
        return currentCount < freeMaxMartSelection
    }

    /// 장보기 아이템을 더 추가할 수 있는지 확인
    static func canAddMoreShoppingItems(currentCount: Int) -> Bool {
        if isPremium { return true }
        return currentCount < freeMaxShoppingItems
    }

    /// 커스텀 마트를 추가할 수 있는지 확인
    static func canAddCustomMart(currentCount: Int) -> Bool {
        if isPremium { return true }
        return currentCount < freeMaxCustomMarts
    }

    /// 알림 기능을 사용할 수 있는지 확인
    static var canUseNotifications: Bool {
        isPremium
    }

    /// 즐겨찾기 기능을 사용할 수 있는지 확인
    static var canUseFavorites: Bool {
        isPremium
    }
}

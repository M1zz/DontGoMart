//
//  StoreKitManager.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/21.
//

import Foundation
import StoreKit

/// 과거에 Pro(비소비성 IAP)를 구매한 '후원자' 를 가려낸다.
///
/// 전 기능을 무료로 풀었지만, Apple 은 비소비성 구매 기록을 영구 보관하므로
/// 같은 Apple ID 면 재설치·기기 변경 후에도 후원자 여부를 확인할 수 있다.
/// 기능 잠금이 아니라 감사 표시(후원자 배지)에만 쓴다.
///
/// (예전의 StoreKitManager/PremiumManager/PremiumUpgradeView 결제·잠금 코드는
///  전 기능 무료화 이후 미사용이라 제거했고, 후원자 배지 판별만 남겼다.)
enum SupporterManager {
    /// 후원으로 인정하는 상품 ID (ProductList.plist 의 coffee)
    static let supporterProductIDs: Set<String> = ["com.dontgomart.Coffee"]

    /// 현재 후원자 배지를 표시해야 하는지.
    static var isSupporter: Bool {
        UserDefaults.standard.bool(forKey: AppStorageKeys.isLegacySupporter)
    }

    /// StoreKit 구매 권한(entitlement)을 확인해 후원자 플래그를 갱신한다.
    /// 한 번 후원자로 인정되면 유지한다(환불·오프라인 등으로 인사가 사라지지 않도록 회수하지 않음).
    static func refresh() async {
        var isSupporter = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               supporterProductIDs.contains(transaction.productID) {
                isSupporter = true
            }
        }

        if isSupporter {
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: AppStorageKeys.isLegacySupporter)
            }
        }
    }
}

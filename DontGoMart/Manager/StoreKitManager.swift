//
//  StoreKitManager.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/21.
//

import Combine
import Foundation
import StoreKit
import UIKit
import LeeoKit

/// 후원자 판별과 누적 후원 횟수를 관리한다.
///
/// 전 기능은 무료이고, 팁 IAP 는 기능 잠금이 아니라 순수 후원이다.
/// 팁을 사고 세는 일 · 후원자 배지 · 응원 단계는 LeeoKit 팁이 한다(`DontGoMartTips`).
/// 여기는 옛 비소모성 커피 구매자를 알아보고, 옛 횟수를 들고 있다가 장부로 넘겨 주는 곳이다.
///
/// 영속화 전략:
/// - 과거 비소비성(com.dontgomart.Coffee) 구매자는 Apple 이 구매 기록을 영구 보관하므로
///   `Transaction.currentEntitlements` 로 재설치·기기 변경 후에도 복원된다.
/// - 새 팁은 소모성(Consumable)이라 entitlement 에 남지 않으므로,
///   로컬 UserDefaults + iCloud Key-Value Store 에 미러링해 재설치에도 유지한다.
enum SupporterManager {
    /// 과거 비소비성 커피 상품 (배지 복원 앵커, 신규 판매 없음)
    static let legacyProductID = "com.dontgomart.Coffee"

    /// 판매하는 소모성 팁 상품들 — 작은 것부터(LeeoKit 팁의 칸 순서)
    static let tipProductIDs: [String] = [
        "com.dontgomart.tip.coffee",
        "com.dontgomart.tip.cake",
        "com.dontgomart.tip.meal",
    ]

    /// 후원으로 인정하는 전체 상품 ID
    static var allSupporterProductIDs: Set<String> {
        Set(tipProductIDs).union([legacyProductID])
    }

    /// 과거 비소비성 커피(레거시) 권한을 판정하는 공용 스토어.
    /// StoreKit 2 의 `Transaction.currentEntitlements` 순회·서명 검증은
    /// LeeoKit 의 `LeeoStore` 가 담당한다. 여기서는 소유 여부만 읽어 쓴다.
    /// (소모성 팁은 LeeoKit 팁이 처리한다 — DontGoMartTips.)
    ///
    /// 구성을 Spec 이 아니라 여기서 만드는 이유: 이 앱은 `.free` 라 페이월이 없다.
    /// Spec 에 paywall 을 선언하면 "무료 모델인데 페이월이 있다" 는 모순이 되어
    /// Preflight 가 오류로 잡는다. 이건 파는 화면이 아니라 옛 구매자를 알아보는 조회일 뿐이다.
    @MainActor
    static let entitlementStore = LeeoStore(config: LeeoPaywallConfig(
        productIDs: [legacyProductID],
        cacheSuiteName: Utillity.appGroupId
    ))

    /// 현재 후원자 배지를 표시해야 하는지.
    static var isSupporter: Bool {
        UserDefaults.standard.bool(forKey: AppStorageKeys.isLegacySupporter)
    }

    /// 누적 후원 횟수 (배지에 ☕️ ×N 으로 표시)
    static var tipCount: Int {
        UserDefaults.standard.integer(forKey: AppStorageKeys.tipCount)
    }

    /// 후원자 표시를 켠다(iCloud 에도). 횟수 · 점수는 LeeoKit 팁 장부가 센다(`DontGoMartTips`).
    /// 전 기능 무료일 때 후원한 사람을 나중에 Pro 로 모시려고 남겨 두는 표시다.
    @MainActor
    static func markSupporter() {
        UserDefaults.standard.set(true, forKey: AppStorageKeys.isLegacySupporter)
        let kvs = NSUbiquitousKeyValueStore.default
        kvs.set(true, forKey: AppStorageKeys.isLegacySupporter)
        kvs.synchronize()
        // 방금 감사를 전했으므로, 감사 리마인더 주기의 기준점을 오늘로 맞춘다
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: AppStorageKeys.supporterThanksShownAt)
    }

    /// 앱 시작 시 후원자 상태를 복원한다.
    /// 1) 과거 비소비성 구매 → entitlement 로 확인
    /// 2) 소모성 팁 → iCloud KVS 와 로컬 중 큰 값으로 병합
    /// 한 번 후원자로 인정되면 유지한다(환불·오프라인 등으로 인사가 사라지지 않도록 회수하지 않음).
    static func refresh() async {
        // 과거 비소비성 커피 권한 확인을 공용 스토어(LeeoStore)에 위임한다.
        // (StoreKit 순회·검증은 LeeoKit 이 처리하고, 우리는 결과만 읽는다.)
        await entitlementStore.refreshEntitlements()

        await MainActor.run {
            let legacy = entitlementStore.purchasedProductIDs.contains(legacyProductID)
            let defaults = UserDefaults.standard
            let kvs = NSUbiquitousKeyValueStore.default
            kvs.synchronize()

            var count = max(defaults.integer(forKey: AppStorageKeys.tipCount),
                            Int(kvs.longLong(forKey: AppStorageKeys.tipCount)))
            var supporter = legacy
                || defaults.bool(forKey: AppStorageKeys.isLegacySupporter)
                || kvs.bool(forKey: AppStorageKeys.isLegacySupporter)

            // 과거 비소비성 구매자는 커피 1잔으로 쳐준다 (카운트 기록이 없던 시절 구매)
            if legacy && count == 0 {
                count = 1
            }
            if count > 0 {
                supporter = true
            }

            defaults.set(count, forKey: AppStorageKeys.tipCount)
            defaults.set(supporter, forKey: AppStorageKeys.isLegacySupporter)
            if supporter {
                kvs.set(Int64(count), forKey: AppStorageKeys.tipCount)
                kvs.set(true, forKey: AppStorageKeys.isLegacySupporter)
                kvs.synchronize()
            }
        }
    }
}

// MARK: - DontGoMartTips (팁 — LeeoKit)

/// 팁(응원)은 LeeoKit 팁(`LeeoTipJar`)을 쓴다 — 리이오의 다른 앱과 같은 화면 · 같은 응원 단계(응원자 · 단골 · 후견인).
/// 예전 앱 자체 팁(CoffeeTipStore)이 세던 횟수와 옛 비소모성 커피는 처음 한 번 장부로 옮긴다(한 번에 1점).
///
/// ⚠️ 이 앱은 아직 전 기능 무료라, 지금 후원한 사람은 나중에 페이월이 생기면 Pro 로 모신다(후원 보상 설계의 예외).
///    그래서 팁을 낼 때마다 `SupporterManager` 의 후원자 표시(iCloud 에도 남는다)를 계속 켠다.
@MainActor
enum DontGoMartTips {
    static let jar = LeeoTipJar(config: LeeoTipJarConfig(
        productIDs: SupporterManager.tipProductIDs,
        thanksPage: URL(string: "https://m1zz.github.io/DontGoMart/#leeo-thanks")))

    private static var watch: AnyCancellable?

    /// 앱을 열 때 한 번. 옛 후원을 옮기고, 상품을 불러오고, 다른 기기 · 다른 앱의 응원 점수와 맞춘다.
    static func start() async {
        await SupporterManager.refresh()
        jar.adoptLegacyTips(SupporterManager.tipCount)
        if watch == nil {
            var last = jar.tipCount
            watch = jar.$tipCount.sink { count in
                if count > last {
                    SupporterManager.markSupporter()
                    if jar.justTipped { AppUsage.log(.tip) }
                }
                last = count
            }
        }
        await jar.startStandalone()
        await jar.syncSupporter(containerIdentifier: DontGoMartSpec.feedback.containerIdentifier)
    }

    /// 메인 화면의 부탁 카드에 넘길 순간. 앱이 헛걸음을 막아 준 날(휴무일)에, 신뢰가 쌓인 사람에게만.
    /// 얼마나 드물게 물을지는 LeeoKit 규칙(물은 뒤 60일 · 낸 뒤 180일 · '다음에' 세 번이면 끝)이 정한다.
    static func moments(todayHasClosedMart: Bool) -> [LeeoTipMoment] {
        guard todayHasClosedMart else { return [] }
        #if !DEBUG
        guard ReviewManager.appOpenCount >= 5, ReviewManager.meaningfulActionsCount >= 3 else { return [] }
        #endif
        return [LeeoTipMoment(id: "closedDay.saved", message: String(localized: "오늘 헛걸음을 막아드렸어요"))]
    }
}

// MARK: - SupporterThanksPrompt (후원자 감사 리마인더 노출 판정)

/// 이미 후원한 사용자에게 '보내주신 기부의 감사함을 잊지 않았다' 는 축하를
/// 휴무일에 가끔 다시 보여줄지 판정한다 (재응원 버튼 포함).
///
/// 원칙: 감사는 반복되면 소음이 된다. 1년에 3번 정도(최소 120일 간격)만,
/// 앱이 실제로 헛걸음을 막아준 날(휴무일)에만 보여준다.
@MainActor
enum SupporterThanksPrompt {
    /// 1년에 3번 정도 = 최소 120일 간격
    private static let minimumIntervalDays = 120

    static func shouldShow(todayHasClosedMart: Bool) -> Bool {
        // 감사의 순간(휴무일)이 아니면 보여주지 않는다
        guard todayHasClosedMart else { return false }
        guard DontGoMartTips.jar.hasTipped else { return false }

        let last = UserDefaults.standard.double(forKey: AppStorageKeys.supporterThanksShownAt)
        // 기준점이 없는 기존 후원자는 다음 휴무일에 한 번 보여주고 주기를 시작한다
        guard last > 0 else { return true }
        let lastDate = Date(timeIntervalSince1970: last)
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return days >= minimumIntervalDays
    }

    static func markShown() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: AppStorageKeys.supporterThanksShownAt)
    }
}

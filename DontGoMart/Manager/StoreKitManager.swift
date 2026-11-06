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

/// 옛 후원자 판별과 누적 후원 횟수를 들고 있다.
///
/// 팁 IAP 는 기능 잠금이 아니라 순수 후원이다. 팁을 사고 세는 일 · 후원자 배지 · 응원 단계는
/// LeeoKit 팁이 한다(`DontGoMartTips`). 여기는 **모든 기능이 무료였던 때**의 후원을 알아보는 곳이다.
/// 그때 후원한 사람은 Pro 로 모신다(`PlanManager`). 그래서 이 표시는 그때 값에서 더 늘지 않는다 —
/// 페이월이 생긴 뒤의 팁은 LeeoKit 장부에만 쌓이고 아무것도 열지 않는다.
///
/// 영속화 전략:
/// - 과거 비소비성(com.dontgomart.Coffee) 구매자는 Apple 이 구매 기록을 영구 보관하므로
///   재설치·기기 변경 후에도 영수증으로 복원된다. 이 상품은 이제 Pro 평생으로 판다(`PlanProducts.proLifetime`).
/// - 예전 소모성 팁 횟수는 로컬 UserDefaults + iCloud Key-Value Store 에 남아 있다.
enum SupporterManager {
    /// 과거 비소비성 커피 상품(스토어 이름 '클로즈드 Pro'). 지금은 Pro 평생으로 판다.
    static let legacyProductID = "com.dontgomart.Coffee"

    /// 판매하는 소모성 팁 상품들 — 작은 것부터(LeeoKit 팁의 칸 순서)
    static let tipProductIDs: [String] = [
        "com.dontgomart.tip.coffee",
        "com.dontgomart.tip.cake",
        "com.dontgomart.tip.meal",
    ]

    /// Pro 평생으로 팔기 시작한 날. 이 앞에 산 옛 커피만 후원으로 친다(그 뒤의 구매는 Pro 평생이다).
    static let lifetimeSaleStart: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 11; c.day = 7
        return Calendar(identifier: .gregorian).date(from: c) ?? .distantPast
    }()

    /// 모든 기능이 무료일 때 옛 비소모성 커피를 샀는가.
    static func boughtLegacyCoffee() async -> Bool {
        guard case .verified(let tx)? = await Transaction.latest(for: legacyProductID),
              tx.revocationDate == nil else { return false }
        return tx.originalPurchaseDate < lifetimeSaleStart
    }

    /// 모든 기능이 무료일 때 후원했는가 (커피 · 팁, iCloud 포함).
    static var isSupporter: Bool {
        UserDefaults.standard.bool(forKey: AppStorageKeys.isLegacySupporter)
    }

    /// 누적 후원 횟수 (배지에 ☕️ ×N 으로 표시)
    static var tipCount: Int {
        UserDefaults.standard.integer(forKey: AppStorageKeys.tipCount)
    }

    /// 앱 시작 시 후원자 상태를 복원한다.
    /// 1) 모든 기능이 무료일 때 산 비소비성 커피 → 영수증으로 확인
    /// 2) 소모성 팁 → iCloud KVS 와 로컬 중 큰 값으로 병합
    /// 한 번 후원자로 인정되면 유지한다(환불·오프라인 등으로 인사가 사라지지 않도록 회수하지 않음).
    static func refresh() async {
        let legacy = await boughtLegacyCoffee()

        await MainActor.run {
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
/// ⚠️ 팁은 아무것도 열지 않는다. 모든 기능이 무료일 때 후원한 사람만 Pro 로 모시고(`PlanManager`),
///    그 표시(`SupporterManager`)는 더 늘리지 않는다.
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
                    // 방금 감사를 전했으므로, 감사 리마인더 주기의 기준점을 오늘로 맞춘다
                    SupporterThanksPrompt.markShown()
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

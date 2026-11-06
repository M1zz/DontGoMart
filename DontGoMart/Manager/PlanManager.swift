//
//  PlanManager.swift
//  DontGoMart
//
//  돈꼬마트 Plus · Pro 를 파는 자리. 상품 로드 · 구매 · 복원 · 거래 리스너는 LeeoKit `LeeoStore` 가 하고,
//  여기는 그 결과를 칸(`PlanTier`)으로 옮기고 위젯과 나눠 읽게 적는다.
//
//  이미 쓰던 사람은 그대로 Pro 다:
//   · 옛 비소모성 com.dontgomart.Coffee(스토어 이름 '클로즈드 Pro')는 지금 Pro 평생 그 상품이다. 산 사람은 영수증으로 Pro.
//   · 모든 기능이 무료일 때 받은 사람(App Store 최초 다운로드 빌드가 `lastFreeBuild` 이하)은 Pro.
//   · 모든 기능이 무료일 때 팁을 보낸 사람(`SupporterManager.isSupporter`, iCloud KVS 포함)은 Pro.
//     페이월이 생긴 뒤의 팁은 아무것도 열지 않는다.
//

import Foundation
import Combine
import StoreKit
import SwiftUI
import WidgetKit
import LeeoKit

/// 상품 ID 와 상품마다 여는 칸. 계약(`DontGoMartSpec`)과 화면이 함께 읽으므로 actor 밖에 둔다.
///
/// ⚠️ App Store Connect · `CoffeeConfiguration.storekit` 과 글자 하나까지 같아야 한다.
///    주 · 월 · 연 구독 여섯은 구독 그룹 하나에 넣는다(Pro 가 위 단계). 그래야 서로 갈아탄다.
enum PlanProducts {
    static let plusWeekly = "com.leeo.DontGoMart.plus.weekly"
    static let plusMonthly = "com.leeo.DontGoMart.plus.monthly"
    static let plusYearly = "com.leeo.DontGoMart.plus.yearly"
    static let plusLifetime = "com.leeo.DontGoMart.plus.lifetime"
    static let proWeekly = "com.leeo.DontGoMart.pro.weekly"
    static let proMonthly = "com.leeo.DontGoMart.pro.monthly"
    static let proYearly = "com.leeo.DontGoMart.pro.yearly"
    /// Pro 평생. **옛 비소모성 커피(스토어 이름 '클로즈드 Pro') 그 상품이다** — 그때 산 사람은 따로 챙기지 않아도 평생 Pro.
    static let proLifetime = SupporterManager.legacyProductID
    /// Plus 평생을 산 사람이 Pro 평생으로 올리는 값. 열면 Pro 평생과 같다.
    static let proUpgrade = "com.leeo.DontGoMart.pro.upgrade"
    /// 연 구독 중인 사람만 보는 졸업가 Pro 평생(`LeeoGraduation`). 열면 Pro 평생과 같다.
    static let proGraduate = "com.leeo.DontGoMart.pro.graduate"

    /// 페이월이 불러올 상품, 화면 순서대로. 팁은 넣지 않는다(팁은 아무것도 열지 않는다).
    static let sale: [String] = [plusYearly, plusLifetime, proYearly, proLifetime, proUpgrade, proGraduate,
                                 plusWeekly, plusMonthly, proWeekly, proMonthly]

    static let tierByProduct: [String: PlanTier] = [
        plusWeekly: .plus, plusMonthly: .plus, plusYearly: .plus, plusLifetime: .plus,
        proWeekly: .pro, proMonthly: .pro, proYearly: .pro, proLifetime: .pro, proUpgrade: .pro, proGraduate: .pro,
    ]

    static var entitlements: Set<String> { Set(tierByProduct.keys) }
    static let lifetimes: Set<String> = [plusLifetime, proLifetime, proUpgrade, proGraduate]
    /// 자동 갱신 구독 전부. 설정의 '구독 관리' 가 이걸 본다.
    static let subscriptions: Set<String> = [plusWeekly, plusMonthly, plusYearly, proWeekly, proMonthly, proYearly]
    /// 졸업가를 제안할 연 구독. 주 · 월 구독에 졸업가를 주면 한 주 값으로 평생이 싸진다.
    static let yearlies: Set<String> = [plusYearly, proYearly]

    /// 가진 상품과 옛 사용자 표시가 여는 칸. 가장 높은 것을 쓴다.
    static func tier(owning ids: Set<String>, legacy: Bool) -> PlanTier {
        if legacy { return .pro }
        return ids.compactMap { tierByProduct[$0] }.max() ?? .free
    }

    static func ownsLifetime(_ tier: PlanTier, in ids: Set<String>) -> Bool {
        ids.contains { lifetimes.contains($0) && tierByProduct[$0] == tier }
    }

    /// 모든 기능이 무료였던 마지막 빌드(2.0.11 빌드 8). 빌드 번호는 지금까지 이보다 큰 적이 없다.
    static let lastFreeBuild = 8

    /// `originalAppVersion` 은 iOS 에서 처음 받은 빌드 번호(CFBundleVersion)다.
    static func isFreeEraBuild(_ originalAppVersion: String) -> Bool {
        guard let build = Int(originalAppVersion.split(separator: ".").first ?? "") else { return false }
        return build <= lastFreeBuild
    }
}

@MainActor
final class PlanManager: ObservableObject {
    static let shared = PlanManager()

    let store: LeeoStore

    /// 지금 쓰는 칸. 화면은 이 값과 `allows` 만 본다.
    @Published private(set) var tier: PlanTier = .free
    /// 이번 실행에서 영수증을 읽었는가. 아직이면 화면은 '무료' 라고 단정하지 않는다(권유 카드를 띄우지 않는다).
    @Published private(set) var isKnown = false
    /// 모든 기능이 무료일 때부터 쓴 사람이라 Pro 를 받았는가.
    @Published private(set) var isLegacy = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var ownedProductIDs: Set<String> = []
    /// 지금 살아 있는 자동 갱신 구독. 있으면 설정에 '구독 관리' · '평생으로 바꾸기' 가 선다.
    @Published private(set) var subscription: LeeoGraduation.Subscription?
    @Published private(set) var isWorking = false
    @Published private(set) var failureMessage: String?

    private var checked = false
    private var observation: AnyCancellable?

    private init() {
        guard let config = DontGoMartSpec.paywall else {
            preconditionFailure("계약에 페이월이 없다. DontGoMartSpec.monetization 을 확인할 것")
        }
        store = LeeoStore(config: config, grandfather: { await PlanManager.isFreeEraUser() })
        isKnown = PlanAccess.cachedTier != nil
        // objectWillChange 는 값이 바뀌기 직전에 온다. 다음 차례에 읽는다.
        observation = store.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in self?.pull() }
        }
        pull()
    }

    /// 이 기능을 지금 쓸 수 있는가. 개수가 걸린 것은 `current`(지금 개수)에 하나를 더해 본다.
    func allows(_ feature: PlanFeature, current: Int = 0) -> Bool {
        LeeoGate(policy: DontGoMartSpec.monetization.gate, hasPro: tier >= feature.tier, isTrialActive: false)
            .evaluate(feature.rawValue, current: current)
            .isAllowed
    }

    func product(_ id: String) -> Product? { products.first { $0.id == id } }

    func ownsLifetime(_ tier: PlanTier) -> Bool { PlanProducts.ownsLifetime(tier, in: ownedProductIDs) }

    /// 연 구독 중이고 6개월째 · 갱신 7일 전 창에 들었는가(`LeeoGraduation`). 띄운 쪽이 `markGraduationOffered()`.
    var graduationIsDue: Bool {
        guard let subscription, PlanProducts.yearlies.contains(subscription.productID),
              !ownsLifetime(.pro), product(PlanProducts.proGraduate) != nil else { return false }
        return LeeoGraduation.isDue(subscription, lastOffered: LeeoGraduation.lastOffered())
    }

    func markGraduationOffered() { LeeoGraduation.markOffered() }

    // MARK: - 상태 맞추기

    /// 영수증을 다시 읽어 칸을 정한다. 앱이 켜질 때와 돌아올 때 부른다.
    func refresh() async {
        await store.refreshEntitlements()
        await store.loadProducts()
        subscription = await LeeoGraduation.currentSubscription(among: PlanProducts.subscriptions)
        checked = true
        pull()
    }

    /// 페이월이 상품을 못 불러왔을 때 다시 청한다.
    func loadProducts() async {
        await store.loadProducts()
        pull()
    }

    /// ⚠️ `action` 은 화면의 `@Environment(\.purchase)` 다. 아이패드에서 결제 시트가 엉뚱한 창에 뜨지 않게.
    func purchase(_ product: Product, using action: PurchaseAction) async {
        _ = await store.purchase(product) { try await action($0) }
        subscription = await LeeoGraduation.currentSubscription(among: PlanProducts.subscriptions)
        checked = true
        pull()
    }

    /// 기기를 바꿨거나 앱을 지웠다 받은 사람이 되찾는 길. 유료 칸이 열려 있으면 true.
    @discardableResult
    func restore() async -> Bool {
        await store.restore()
        subscription = await LeeoGraduation.currentSubscription(among: PlanProducts.subscriptions)
        checked = true
        pull()
        return tier > .free
    }

    private func pull() {
        let owned = store.purchasedProductIDs
        let newTier = PlanProducts.tier(owning: owned, legacy: store.isGrandfathered)
        // 물어보기 전에는 위젯 통에 쓰지 않는다. 빈 권한을 적으면 처음 켠 구매자의 위젯이 잠긴다.
        if checked {
            isKnown = true
            if PlanAccess.store(newTier) { WidgetCenter.shared.reloadAllTimelines() }
        }
        tier = newTier
        isLegacy = store.isGrandfathered && PlanProducts.tier(owning: owned, legacy: false) < .pro
        ownedProductIDs = owned
        products = store.products
        isWorking = store.purchasingProductID != nil || store.isRestoring
        failureMessage = store.lastError
    }

    // MARK: - 모든 기능이 무료일 때부터 쓴 사람

    /// LeeoStore 가 산 것이 없을 때 한 번 묻는다. 한 번 true 면 내려가지 않는다(그 통에 적힌다).
    /// 시험 환경(샌드박스 · TestFlight · Xcode)은 최초 빌드를 알 수 없어 처음 받은 사람으로 본다.
    private static func isFreeEraUser() async -> Bool {
        await SupporterManager.refresh()
        if SupporterManager.isSupporter { return true }
        guard case .verified(let app)? = try? await AppTransaction.shared,
              app.environment == .production else { return false }
        return PlanProducts.isFreeEraBuild(app.originalAppVersion)
    }
}

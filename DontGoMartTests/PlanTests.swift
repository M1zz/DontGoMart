//
//  PlanTests.swift
//  DontGoMartTests
//
//  무료 · Plus · Pro 판정과 StoreKit 설정의 상품이 서로 맞는지.
//

import Foundation
import Testing
import StoreKit

@testable import DontGoMart

struct PlanTests {

    @Test func tierFollowsHighestProduct() {
        #expect(PlanProducts.tier(owning: [], legacy: false) == .free)
        #expect(PlanProducts.tier(owning: [PlanProducts.plusWeekly], legacy: false) == .plus)
        #expect(PlanProducts.tier(owning: [PlanProducts.plusLifetime, PlanProducts.proMonthly], legacy: false) == .pro)
        // 옛 비소모성 커피(스토어 이름 '클로즈드 Pro')를 산 사람은 Pro 평생이다
        #expect(PlanProducts.tier(owning: ["com.dontgomart.Coffee"], legacy: false) == .pro)
        // 모든 기능이 무료일 때부터 쓴 사람은 Pro
        #expect(PlanProducts.tier(owning: [], legacy: true) == .pro)
    }

    /// 팁은 아무것도 열지 않는다.
    @Test func tipsOpenNothing() {
        #expect(PlanProducts.tier(owning: Set(SupporterManager.tipProductIDs), legacy: false) == .free)
        #expect(PlanProducts.entitlements.isDisjoint(with: SupporterManager.tipProductIDs))
    }

    @Test func freeEraBuilds() {
        #expect(PlanProducts.isFreeEraBuild("1"))
        #expect(PlanProducts.isFreeEraBuild("8"))
        #expect(!PlanProducts.isFreeEraBuild("9"))
        #expect(!PlanProducts.isFreeEraBuild(""))
    }

    @Test func plusLifetimeOwnerUpgradesToPro() {
        #expect(PlanProducts.ownsLifetime(.plus, in: [PlanProducts.plusLifetime]))
        #expect(!PlanProducts.ownsLifetime(.pro, in: [PlanProducts.plusLifetime]))
        #expect(PlanProducts.ownsLifetime(.pro, in: [PlanProducts.proUpgrade]))
    }

    @Test func featureTiers() {
        #expect(PlanFeature.moreMarts.tier == .plus)
        #expect(PlanFeature.storyAndVideo.tier == .plus)
        #expect(PlanFeature.lockScreenWidgets.tier == .pro)
        #expect(PlanFeature.restaurantImport.tier == .pro)
    }

    /// 판매 상품이 StoreKit 설정 파일에 모두 있고, 여섯 구독이 한 그룹에서 Pro 가 위 단계인지.
    ///
    /// ⚠️ 파일을 직접 읽는다. 이 시험 환경에서 `SKTestSession` 은 실제 App Store(샌드박스) 상품을 돌려주므로,
    ///    App Store Connect 에 상품을 만들기 전에는 `Product.products` 로 확인할 수 없다.
    @Test func storeKitConfigurationHasEveryProduct() throws {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "CoffeeConfiguration", withExtension: "storekit"))
        let root = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let products = root["products"] as? [[String: Any]] ?? []
        let groups = root["subscriptionGroups"] as? [[String: Any]] ?? []
        #expect(groups.count == 1)
        let subscriptions = groups.first?["subscriptions"] as? [[String: Any]] ?? []

        func price(_ id: String) -> Double {
            let all = products + subscriptions
            return Double(all.first { $0["productID"] as? String == id }?["displayPrice"] as? String ?? "") ?? 0
        }

        let nonConsumables = Set(products.filter { $0["type"] as? String == "NonConsumable" }.compactMap { $0["productID"] as? String })
        #expect(PlanProducts.lifetimes.isSubset(of: nonConsumables))
        #expect(Set(subscriptions.compactMap { $0["productID"] as? String }) == PlanProducts.subscriptions)
        #expect(Set(PlanProducts.sale).isSubset(of: nonConsumables.union(PlanProducts.subscriptions)))

        // Pro 가 위 단계(그룹 순번이 작을수록 위)
        for sub in subscriptions {
            let id = sub["productID"] as? String ?? ""
            #expect(sub["groupNumber"] as? Int == (PlanProducts.tierByProduct[id] == .pro ? 1 : 2), "\(id)")
        }
        // 연 구독은 처음 보는 사람에게 첫 해 반값
        for sub in subscriptions where PlanProducts.yearlies.contains(sub["productID"] as? String ?? "") {
            let intro = try #require(sub["introductoryOffer"] as? [String: Any])
            #expect(intro["paymentMode"] as? String == "payUpFront")
            let half = (Double(intro["displayPrice"] as? String ?? "") ?? 0) * 2
            #expect(abs(half - (Double(sub["displayPrice"] as? String ?? "") ?? 0)) <= 0.02)
        }
        // 같은 기간이면 Pro 가 Plus 보다 비싸다
        #expect(price(PlanProducts.proWeekly) > price(PlanProducts.plusWeekly))
        #expect(price(PlanProducts.proMonthly) > price(PlanProducts.plusMonthly))
        #expect(price(PlanProducts.proYearly) > price(PlanProducts.plusYearly))
        #expect(price(PlanProducts.proLifetime) > price(PlanProducts.plusLifetime))
    }
}

private final class BundleToken {}

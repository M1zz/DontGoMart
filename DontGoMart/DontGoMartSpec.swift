//
//  DontGoMartSpec.swift
//  DontGoMart
//

import Foundation
import LeeoKit

enum DontGoMartSpec: LeeoAppSpec {
    static let appName = "돈꼬마트"
    static let developerEmail = "leeo@kakao.com"
    /// 위젯과 나눠 쓰는 기록 — 백업 금고가 함께 떠 둔다.
    static let appGroups = ["group.com.leeo.DontGoMart"]
    static let feedback = LeeoFeedbackConfig(containerIdentifier: "iCloud.com.Ysoup.FeedbackHub", appIdentifier: "com.leeo.DontGoMart")

    /// App Store 숫자 ID. 있어야 설정의 '리뷰 남기기' 가 시스템 평점 팝업 대신
    /// 실제 리뷰 작성 페이지로 간다.
    static let appStoreID: String? = "6450387984"

    /// 개인정보·지원 링크. GitHub Pages 로 올려 둔 페이지들이다(레포의 docs/).
    /// 설정 ▸ 지원 섹션이 이 선언에서 링크 행을 만든다 — 앱이 따로 넣지 않아도 항상 있다.
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/DontGoMart/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/DontGoMart/support.html")!,
        marketingURL: URL(string: "https://m1zz.github.io/DontGoMart/")!
    )

    /// 수익모델 — 무료로 받아 쓰고, 동네 가게를 여럿 챙기면 Plus, 앱을 안 열고 알고 입력을 맡기면 Pro.
    ///
    /// 칸마다 주 · 월 · 연 구독과 평생(`PlanProducts`). 무엇이 어느 칸인지는 `PlanFeature.tier` 한 곳에 있고,
    /// 무료 개수는 `PlanLimits` 에 있다. 이미 쓰던 사람은 그대로 Pro 다(`PlanManager`).
    ///
    /// 팁(coffee/cake/meal)은 여기 넣지 않는다. 팁은 아무것도 열지 않는 순수 후원이고,
    /// LeeoKit 팁을 혼자 쓴다(`DontGoMartTips` — 리이오의 다른 앱과 같은 팁 화면 · 응원 단계).
    static let monetization = LeeoMonetization.freemiumSubscription(
        LeeoSubscriptionConfig(
            productIDs: PlanProducts.sale,
            // 자체 약관이 없으므로 애플 표준 사용권 계약(EULA)을 건다. 구독을 파는 앱의 심사 필수 항목이다.
            termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
            entitlementIDs: PlanProducts.entitlements,
            gate: LeeoGatePolicy(
                freeLimits: [PlanFeature.moreMarts.rawValue: PlanLimits.customMarts,
                             PlanFeature.moreRestaurants.rawValue: PlanLimits.restaurants],
                proOnly: Set([PlanFeature.storyAndVideo, .moreWidgets, .lockScreenWidgets, .restaurantImport].map(\.rawValue))),
            // 위젯과 함께 읽는 통. 권한 캐시가 여기 적힌다.
            cacheSuiteName: Utillity.appGroupId))
}

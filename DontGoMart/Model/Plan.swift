//
//  Plan.swift
//  DontGoMart
//
//  돈꼬마트의 세 칸(무료 · Plus · Pro). **앱과 위젯이 함께 읽는다.**
//
//  선은 하나로 긋는다 — 헛걸음을 막는 핵심(마트 의무휴업일, 오늘 영업 여부, 달력, 휴무 알림 · 배너,
//  가까운 휴무일 위젯, 게시물 공유 카드)은 무료다. 동네 가게를 여럿 챙기는 사람은 Plus,
//  앱을 열지 않고 알고 싶거나 입력을 알아서 채우고 싶은 사람은 Pro. Pro 는 Plus 를 전부 포함한다.
//
//  StoreKit 은 여기 없다. 위젯은 결제를 조회할 수 없으므로 앱(`PlanManager`)이 확인한 칸을
//  App Group 에 한 줄로 적어 두고, 위젯은 그것만 읽는다.
//

import Foundation

/// 칸. 값이 클수록 더 많이 연다.
enum PlanTier: Int, Comparable, CaseIterable {
    case free = 0
    case plus = 1
    case pro = 2

    static func < (lhs: PlanTier, rhs: PlanTier) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .free: String(localized: "무료")
        case .plus: String(localized: "돈꼬마트 Plus")
        case .pro:  String(localized: "돈꼬마트 Pro")
        }
    }
}

/// 값을 받고 여는 것. 열쇠말(rawValue)은 계약(`DontGoMartSpec.monetization` 의 게이트)과 같다.
enum PlanFeature: String, CaseIterable {
    /// 나만의 마트 3곳째부터
    case moreMarts
    /// 단골 식당 4곳째부터
    case moreRestaurants
    /// 공유 카드의 스토리 규격 · 동영상
    case storyAndVideo
    /// 다음 두 번의 휴무 · 이번 주 일요일 · 단골 식당 7일 홈 위젯
    case moreWidgets
    /// 잠금화면 위젯
    case lockScreenWidgets
    /// 네이버지도 링크 · 스크린샷으로 식당 휴무 채우기
    case restaurantImport

    /// 이 기능을 여는 가장 낮은 칸.
    var tier: PlanTier {
        switch self {
        case .moreMarts, .moreRestaurants, .storyAndVideo:            .plus
        case .moreWidgets, .lockScreenWidgets, .restaurantImport:     .pro
        }
    }
}

/// 무료로 넣을 수 있는 개수. 페이월 비교표와 게이트가 이 값 하나를 쓴다.
enum PlanLimits {
    static let customMarts = 2
    static let restaurants = 3
}

/// 앱이 확인한 칸을 위젯과 나눠 읽는 자리.
enum PlanAccess {
    private static let tierKey = "plan.tier"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: Utillity.appGroupId) ?? .standard
    }

    /// 앱이 적어 둔 칸. **nil 은 '무료' 가 아니라 '앱이 아직 영수증을 확인하지 않았다'** 이다.
    /// 그 차이를 잃으면 업데이트 뒤 앱을 열기 전, 이미 산 사람의 위젯이 잠긴다.
    static var cachedTier: PlanTier? {
        (defaults.object(forKey: tierKey) as? Int).flatMap(PlanTier.init(rawValue:))
    }

    /// `PlanManager` 만 부른다. 값이 바뀌었으면 true(위젯을 다시 그릴 때).
    @discardableResult
    static func store(_ tier: PlanTier) -> Bool {
        guard cachedTier != tier else { return false }
        defaults.set(tier.rawValue, forKey: tierKey)
        return true
    }

    /// Pro 위젯(추가 홈 위젯 3종 · 잠금화면)을 그려도 되는가. 아직 모르면 잠그지 않는다.
    static var opensProWidgets: Bool { (cachedTier ?? .pro) >= .pro }

    /// 잠긴 위젯을 누르면 여는 페이월. 홈 위젯과 잠금화면 위젯은 비교표의 다른 줄을 짚는다.
    static func paywallLink(for feature: PlanFeature) -> URL {
        URL(string: "\(Utillity.deepLinkScheme)://paywall/\(feature.rawValue)")!
    }
}

//
//  ReviewManager.swift
//  DontGoMart
//
//  Created by Claude on 2025/01/29.
//

import StoreKit
import SwiftUI
import UIKit

enum ReviewManager {
    private static let appOpenCountKey = "appOpenCount"
    private static let lastReviewRequestDateKey = "lastReviewRequestDate"

    // 리뷰 요청 조건: 앱을 5번 이상 열고, 마지막 요청 이후 90일 경과
    private static let minimumAppOpens = 5
    private static let daysBetweenRequests = 90

    static func incrementAppOpenCount() {
        let defaults = UserDefaults.standard
        let currentCount = defaults.integer(forKey: appOpenCountKey)
        defaults.set(currentCount + 1, forKey: appOpenCountKey)
    }

    static func requestReviewIfAppropriate() {
        let defaults = UserDefaults.standard
        let appOpenCount = defaults.integer(forKey: appOpenCountKey)

        // 앱을 최소 횟수 이상 열지 않았으면 요청하지 않음
        guard appOpenCount >= minimumAppOpens else { return }

        // 마지막 리뷰 요청 이후 충분한 시간이 지났는지 확인
        if let lastRequestDate = defaults.object(forKey: lastReviewRequestDateKey) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            guard daysSinceLastRequest >= daysBetweenRequests else { return }
        }

        // 리뷰 요청
        requestReview()

        // 마지막 요청 날짜 저장
        defaults.set(Date(), forKey: lastReviewRequestDateKey)
    }

    private static func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

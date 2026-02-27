//
//  PremiumUpgradeView.swift
//  Klosed
//
//  Created by Claude Code
//

import SwiftUI
import StoreKit

// MARK: - Paywall 트리거 컨텍스트

/// Paywall이 어떤 상황에서 트리거됐는지 나타냄
/// 컨텍스트에 따라 히어로 메시지가 달라져서 전환율을 높임
enum PaywallContext {
    case martLimit          // 두 번째 마트 추가 시도
    case shoppingLimit      // 장보기 6번째 아이템 추가 시도
    case notification       // 알림 설정 진입
    case customMart         // 커스텀 마트 추가 시도
    case favorites          // 즐겨찾기 시도
    case general            // 일반 (메인 화면 배너 등)

    var heroEmoji: String {
        switch self {
        case .martLimit:      return "🏬"
        case .shoppingLimit:  return "🛒"
        case .notification:   return "🔔"
        case .customMart:     return "🏪"
        case .favorites:      return "⭐"
        case .general:        return "🚀"
        }
    }

    var heroTitle: String {
        switch self {
        case .martLimit:
            return String(localized: "paywall_martLimit_title",
                          defaultValue: "여러 마트를 한번에 추적하세요",
                          table: "CodeStrings")
        case .shoppingLimit:
            return String(localized: "paywall_shoppingLimit_title",
                          defaultValue: "장보기 목록, 제한 없이 사용하세요",
                          table: "CodeStrings")
        case .notification:
            return String(localized: "paywall_notification_title",
                          defaultValue: "휴무일 알림으로 헛걸음을 막으세요",
                          table: "CodeStrings")
        case .customMart:
            return String(localized: "paywall_customMart_title",
                          defaultValue: "나만의 마트 휴무 패턴을 등록하세요",
                          table: "CodeStrings")
        case .favorites:
            return String(localized: "paywall_favorites_title",
                          defaultValue: "자주 가는 매장을 즐겨찾기 하세요",
                          table: "CodeStrings")
        case .general:
            return String(localized: "paywall_general_title",
                          defaultValue: "Klosed Pro로 업그레이드",
                          table: "CodeStrings")
        }
    }

    var heroSubtitle: String {
        switch self {
        case .martLimit:
            return String(localized: "paywall_martLimit_sub",
                          defaultValue: "이마트, 코스트코, 홈플러스 휴무일을 동시에 확인하세요",
                          table: "CodeStrings")
        case .shoppingLimit:
            return String(localized: "paywall_shoppingLimit_sub",
                          defaultValue: "장볼 것이 많을 때 걱정 없이 추가하세요",
                          table: "CodeStrings")
        case .notification:
            return String(localized: "paywall_notification_sub",
                          defaultValue: "휴무 전날 알림을 받았다면, 지난번 헛걸음은 없었을 거예요",
                          table: "CodeStrings")
        case .customMart:
            return String(localized: "paywall_customMart_sub",
                          defaultValue: "동네 마트도 휴무 패턴을 등록해서 관리하세요",
                          table: "CodeStrings")
        case .favorites:
            return String(localized: "paywall_favorites_sub",
                          defaultValue: "자주 가는 매장이 항상 위에 보여요",
                          table: "CodeStrings")
        case .general:
            return String(localized: "paywall_general_sub",
                          defaultValue: "한 번 구매로 모든 기능을 영구 사용하세요",
                          table: "CodeStrings")
        }
    }
}

// MARK: - PremiumUpgradeView

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var storeKit = StoreKitManager()
    @AppStorage(AppStorageKeys.isPremium) var isPremium: Bool = false
    @State private var isPurchasing = false

    /// Paywall을 트리거한 컨텍스트 (기본: general)
    var context: PaywallContext = .general

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    heroSection
                    featuresSection
                    purchaseSection
                    restoreButton
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
    }

    // MARK: - Hero (컨텍스트 기반)

    private var heroSection: some View {
        VStack(spacing: 16) {
            Text(context.heroEmoji)
                .font(.system(size: 56))

            Text(context.heroTitle)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(context.heroSubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.top, 16)
        .padding(.horizontal, 8)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 0) {
            featureRow(
                icon: "building.2.fill",
                color: .blue,
                title: String(localized: "다중_마트_추적_title", defaultValue: "Multi-Mart Tracking", table: "CodeStrings"),
                subtitle: String(localized: "다중_마트_추적_desc", defaultValue: "Track multiple marts simultaneously", table: "CodeStrings"),
                isHighlighted: context == .martLimit
            )

            Divider().padding(.leading, 56)

            featureRow(
                icon: "bell.fill",
                color: .red,
                title: String(localized: "알림_기능_title", defaultValue: "Notifications", table: "CodeStrings"),
                subtitle: String(localized: "알림_기능_desc", defaultValue: "Get notified before closed days", table: "CodeStrings"),
                isHighlighted: context == .notification
            )

            Divider().padding(.leading, 56)

            featureRow(
                icon: "cart.fill",
                color: .green,
                title: String(localized: "무제한_장보기_title", defaultValue: "Unlimited Shopping List", table: "CodeStrings"),
                subtitle: String(localized: "무제한_장보기_desc", defaultValue: "No item limit on your shopping list", table: "CodeStrings"),
                isHighlighted: context == .shoppingLimit
            )

            Divider().padding(.leading, 56)

            featureRow(
                icon: "storefront.fill",
                color: .orange,
                title: String(localized: "커스텀_마트_title", defaultValue: "Custom Mart", table: "CodeStrings"),
                subtitle: String(localized: "커스텀_마트_desc", defaultValue: "Add your own mart's closed-day patterns", table: "CodeStrings"),
                isHighlighted: context == .customMart
            )

            Divider().padding(.leading, 56)

            featureRow(
                icon: "star.fill",
                color: .yellow,
                title: String(localized: "즐겨찾기_title", defaultValue: "Favorites", table: "CodeStrings"),
                subtitle: String(localized: "즐겨찾기_desc", defaultValue: "Pin your favorite marts to the top", table: "CodeStrings"),
                isHighlighted: context == .favorites
            )
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String, isHighlighted: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isHighlighted {
                Image(systemName: "arrow.left")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isHighlighted ? Color.orange.opacity(0.06) : Color.clear)
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let product = storeKit.storeProducts.first {
                // 가치 앵커링 메시지
                Text(String(localized: "paywall_value_anchor",
                            defaultValue: "☕ 커피 한 잔 가격으로, 영구적으로 사용하세요",
                            table: "CodeStrings"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(action: {
                    Task {
                        isPurchasing = true
                        do {
                            if let _ = try await storeKit.purchase(product) {
                                isPremium = true
                                dismiss()
                            }
                        } catch {
                            print("Purchase failed: \(error)")
                        }
                        isPurchasing = false
                    }
                }) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            VStack(spacing: 2) {
                                Text("Klosed Pro - \(product.displayPrice)")
                                    .font(.headline)
                                Text(String(localized: "일회성_구매_안내",
                                            defaultValue: "One-time purchase. No subscription.",
                                            table: "CodeStrings"))
                                    .font(.caption2)
                                    .opacity(0.9)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(isPurchasing)
            } else {
                ProgressView()
                    .padding()
            }
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button(action: {
            Task {
                try? await AppStore.sync()
                await storeKit.updateCustomerProductStatus()
                if !storeKit.purchasedCourses.isEmpty {
                    isPremium = true
                    dismiss()
                }
            }
        }) {
            Text(Utillity.restorePurchases)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 프리미엄 유도 배너 (인라인용)

struct PremiumBanner: View {
    let feature: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pro " + String(localized: "기능_label", defaultValue: "Feature", table: "CodeStrings"))
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                    Text(feature)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.orange.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    PremiumUpgradeView(context: .martLimit)
}

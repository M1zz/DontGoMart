//
//  PremiumUpgradeView.swift
//  Klosed
//
//  Created by Claude Code
//

import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var storeKit = StoreKitManager()
    @AppStorage(AppStorageKeys.isPremium) var isPremium: Bool = false
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    purchaseSection
                    restoreButton
                }
                .padding()
            }
            .navigationTitle("Klosed Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Klosed Pro")
                .font(.largeTitle.bold())

            Text(String(localized: "프리미엄_설명", defaultValue: "Unlock all features with a one-time purchase", table: "CodeStrings"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 0) {
            featureRow(
                icon: "building.2.fill",
                color: .blue,
                title: String(localized: "다중_마트_추적_title", defaultValue: "Multi-Mart Tracking", table: "CodeStrings"),
                subtitle: String(localized: "다중_마트_추적_desc", defaultValue: "Track multiple marts simultaneously", table: "CodeStrings"),
                isFree: false
            )

            Divider().padding(.leading, 56)

            featureRow(
                icon: "storefront.fill",
                color: .orange,
                title: String(localized: "커스텀_마트_title", defaultValue: "Custom Mart", table: "CodeStrings"),
                subtitle: String(localized: "커스텀_마트_desc", defaultValue: "Add your own mart's closed-day patterns", table: "CodeStrings"),
                isFree: false
            )

            Divider().padding(.leading, 56)

            featureRow(
                icon: "bell.fill",
                color: .red,
                title: String(localized: "알림_기능_title", defaultValue: "Notifications", table: "CodeStrings"),
                subtitle: String(localized: "알림_기능_desc", defaultValue: "Get notified before closed days", table: "CodeStrings"),
                isFree: false
            )

            Divider().padding(.leading, 56)

            featureRow(
                icon: "cart.fill",
                color: .green,
                title: String(localized: "무제한_장보기_title", defaultValue: "Unlimited Shopping List", table: "CodeStrings"),
                subtitle: String(localized: "무제한_장보기_desc", defaultValue: "No item limit on your shopping list", table: "CodeStrings"),
                isFree: false
            )

            Divider().padding(.leading, 56)

            featureRow(
                icon: "star.fill",
                color: .yellow,
                title: String(localized: "즐겨찾기_title", defaultValue: "Favorites", table: "CodeStrings"),
                subtitle: String(localized: "즐겨찾기_desc", defaultValue: "Pin your favorite marts to the top", table: "CodeStrings"),
                isFree: false
            )
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String, isFree: Bool) -> some View {
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

            if isFree {
                Text("Free")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(6)
            } else {
                Text("Pro")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let product = storeKit.storeProducts.first {
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
                            Text("Klosed Pro - \(product.displayPrice)")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
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

                Text(String(localized: "일회성_구매_안내", defaultValue: "One-time purchase. No subscription.", table: "CodeStrings"))
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                // 구매 상태 확인
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
    PremiumUpgradeView()
}

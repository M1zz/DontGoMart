//
//  ImprovedClosedDaysView.swift
//  DontGoMart
//
//  Created by Claude Code
//

import SwiftUI
import WidgetKit

struct ImprovedClosedDaysView: View {
    @State var currentDate: Date = Date()
    @StateObject var locationManager = LocationManager.shared
    @StateObject var operationStatusManager = OperationStatusManager.shared
    @StateObject var shoppingManager = ShoppingReminderManager.shared
    @AppStorage("isPremium") var isPremium: Bool = false
    @State private var isShowingSettings = false
    @State private var isShowingShoppingList = false
    @State private var isShowingPremiumUpgrade = false
    @State private var isCostco: Bool = false
    @AppStorage(AppStorageKeys.selectedBranch, store: UserDefaults(suiteName: Utillity.appGroupId)) var selectedBranch: Int = 0
    @AppStorage(AppStorageKeys.locationEnabled, store: UserDefaults(suiteName: Utillity.appGroupId)) var isLocationEnabled: Bool = false

    private var selectedMartType: MartType {
        if isCostco {
            switch selectedBranch {
            case 1:
                return .costco(type: .normal)
            case 2:
                return .costco(type: .daegu)
            case 3:
                return .costco(type: .ilsan)
            case 4:
                return .costco(type: .ulsan)
            default:
                return .normal(type: .sunday)
            }
        }
        return .normal(type: .sunday)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    operationStatusCard

                    nextClosedDateCard

                    if isLocationEnabled && !locationManager.nearbyStores.isEmpty {
                        nearbyStoresCard
                    }

                    quickActionsCard

                    ClosedDayCalendarView(currentDate: $currentDate,
                                          isCostco: isCostco,
                                          selectedBranch: selectedBranch)
                    .padding(.vertical)

                    if !isPremium {
                        PremiumBanner(
                            feature: String(localized: "프리미엄_메인_배너", defaultValue: "Unlock multi-mart tracking, notifications & more")
                        ) {
                            isShowingPremiumUpgrade = true
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(isPremium ? "클로즈드 " + locationName(forID: selectedBranch) + " pro" : "클로즈드 " + locationName(forID: selectedBranch))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingSettings.toggle()
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onChange(of: selectedBranch) {
            WidgetManager.shared.updateWidget()
        }
        .sheet(isPresented: $isShowingSettings, onDismiss: {
            isCostco = UserDefaults(suiteName: Utillity.appGroupId)?.bool(forKey: AppStorageKeys.isCostco) ?? false
            selectedBranch = UserDefaults(suiteName: Utillity.appGroupId)?.integer(forKey: AppStorageKeys.selectedBranch) ?? 0
        }) {
            ImprovedSettingsView(isShowingSettings: $isShowingSettings)
        }
        .sheet(isPresented: $isShowingPremiumUpgrade) {
            PremiumUpgradeView(context: .general)
        }
        .sheet(isPresented: $isShowingShoppingList) {
            NavigationStack {
                ShoppingListView()
            }
        }
        .onAppear {
            isCostco = UserDefaults(suiteName: Utillity.appGroupId)?.bool(forKey: AppStorageKeys.isCostco) ?? false

            if isLocationEnabled && locationManager.authorizationStatus == .notDetermined {
                locationManager.requestAuthorization()
            }
        }
    }

    private var operationStatusCard: some View {
        let status = operationStatusManager.checkStatus(for: selectedMartType)

        return VStack(spacing: 12) {
            HStack {
                Text("오늘 갈 수 있나요?")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Text(status.emoji)
                    .font(.system(size: 50))

                VStack(alignment: .leading, spacing: 8) {
                    Text(status.displayText)
                        .font(.title.bold())
                        .foregroundColor(status == .open ? .green : .red)

                    Text(locationName(forID: selectedBranch))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(status == .open ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(status == .open ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal)
    }

    private var nextClosedDateCard: some View {
        let daysUntil = operationStatusManager.daysUntilNextClosed(for: selectedMartType)

        return VStack(spacing: 12) {
            HStack {
                Text("다음 휴무일")
                    .font(.headline)
                Spacer()
            }

            if let days = daysUntil, let nextDate = operationStatusManager.nextClosedDate(for: selectedMartType) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(operationStatusManager.formatDDay(days))
                            .font(.title2.bold())
                            .foregroundColor(Color("Pink"))

                        Text(nextDate.formatted(date: .long, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if days <= 3 {
                        VStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("곧 휴무")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            } else {
                Text("휴무일 정보 없음")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }

    private var nearbyStoresCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(Color("Pink"))
                Text("주변 매장")
                    .font(.headline)
                Spacer()
            }

            ForEach(locationManager.nearbyStores.prefix(3)) { store in
                HStack {
                    VStack(alignment: .leading) {
                        Text(store.displayName)
                            .font(.subheadline.bold())
                        Text(store.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)

                if store.id != locationManager.nearbyStores.prefix(3).last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }

    private var quickActionsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("빠른 실행")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: {
                    isShowingShoppingList = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                            .font(.title2)
                        Text("장보기 목록")
                            .font(.caption)

                        if shoppingManager.currentReminder.totalItemsCount > 0 {
                            Text("\(shoppingManager.currentReminder.totalItemsCount)개")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Pink").opacity(0.1))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)

                Button(action: {
                    if let nextDate = operationStatusManager.nextClosedDate(for: selectedMartType) {
                        currentDate = nextDate
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.title2)
                        Text("다음 휴무일")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Pink").opacity(0.1))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }

    private func locationName(forID id: Int) -> String {
        switch id {
        case 0:
            return String(localized: "마트_loc", defaultValue: "Mart")
        case 1:
            return String(localized: "일반 코스트코_loc", defaultValue: "Costco")
        case 2:
            return String(localized: "대구 코스트코_loc", defaultValue: "Costco Daegu")
        case 3:
            return String(localized: "일산 코스트코_loc", defaultValue: "Costco Ilsan")
        case 4:
            return String(localized: "울산 코스트코_loc", defaultValue: "Costco Ulsan")
        default:
            return ""
        }
    }

}

#Preview {
    ImprovedClosedDaysView()
}

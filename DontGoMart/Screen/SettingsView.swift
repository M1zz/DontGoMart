//
//  SettingsView.swift
//  DontGoMart
//
//  Created by hyunho lee on 7/8/23.
//

import SwiftUI
import WidgetKit
import UIKit

struct SettingsView: View {
    @Binding var isShowingSettings: Bool
    @AppStorage(AppStorageKeys.notificationEnabled, store: UserDefaults(suiteName: Utillity.appGroupId)) var isNotificationEnabled: Bool = false
    @AppStorage(AppStorageKeys.notificationHour, store: UserDefaults(suiteName: Utillity.appGroupId)) var notificationHour: Int = 9
    @AppStorage(AppStorageKeys.notificationMinute, store: UserDefaults(suiteName: Utillity.appGroupId)) var notificationMinute: Int = 0
    @AppStorage(AppStorageKeys.beforeDayNotificationEnabled, store: UserDefaults(suiteName: Utillity.appGroupId)) var beforeDayNotificationEnabled: Bool = true
    @AppStorage(AppStorageKeys.isPremium) var isPremium: Bool = false

    @StateObject private var martSelection = MartSelectionManager.shared
    @StateObject private var customMartManager = CustomMartManager.shared

    private let notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false
    @State private var showingTimePicker = false
    @State private var showingCustomMartEditor = false
    @State private var editingCustomMart: CustomMart? = nil
    @State private var showingPremiumUpgrade = false
    @State private var paywallContext: PaywallContext = .general

    var body: some View {
        NavigationStack {
            Form {
                martSelectionSection
                customMartSection
                notificationSection
                #if DEBUG
                developerSection
                #endif
            }
            .navigationTitle("매장선택")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        WidgetManager.shared.updateWidget()
                        isShowingSettings = false
                    }
                }
            }
            .onAppear {
                Task {
                    await checkAndSyncNotificationStatus()
                }
            }
            .background(
                NotificationPermissionAlert(isPresented: $showingPermissionAlert)
            )
            .sheet(isPresented: $showingCustomMartEditor) {
                CustomMartEditView(editingMart: editingCustomMart)
            }
            .sheet(isPresented: $showingPremiumUpgrade) {
                PremiumUpgradeView(context: paywallContext)
            }
        }
    }

    // MARK: - Mart Selection Section

    private var martSelectionSection: some View {
        Section(header: Text("추적할 매장 선택 (여러개 가능)")) {
            // 대형마트 지역별
            martToggle(
                martType: .normal(type: .sunday),
                icon: "cart.fill",
                color: .blue,
                label: String(localized: "대형마트 (일요일 휴무)_label", defaultValue: "Supermarket (Sunday closed)")
            )

            martToggle(
                martType: .normal(type: .wednesday),
                icon: "cart.fill",
                color: .cyan,
                label: String(localized: "대형마트 (수요일 휴무)_label", defaultValue: "Supermarket (Wednesday closed)")
            )

            martToggle(
                martType: .normal(type: .mixed),
                icon: "cart.fill",
                color: .teal,
                label: String(localized: "대형마트 (울산 혼합)_label", defaultValue: "Supermarket (Ulsan mixed)")
            )

            martToggle(
                martType: .normal(type: .jeju),
                icon: "cart.fill",
                color: .mint,
                label: String(localized: "대형마트 (제주)_label", defaultValue: "Supermarket (Jeju)")
            )

            // 코스트코 지점별
            martToggle(
                martType: .costco(type: .normal),
                icon: "building.2.fill",
                color: .red,
                label: String(localized: "코스트코 일반매장_label", defaultValue: "Costco Regular")
            )

            martToggle(
                martType: .costco(type: .daegu),
                icon: "building.2.fill",
                color: .orange,
                label: String(localized: "코스트코 대구점_label", defaultValue: "Costco Daegu")
            )

            martToggle(
                martType: .costco(type: .ilsan),
                icon: "building.2.fill",
                color: .green,
                label: String(localized: "코스트코 일산점_label", defaultValue: "Costco Ilsan")
            )

            martToggle(
                martType: .costco(type: .ulsan),
                icon: "building.2.fill",
                color: .purple,
                label: String(localized: "코스트코 울산점_label", defaultValue: "Costco Ulsan")
            )

            // 공휴일
            martToggle(
                martType: .holiday,
                icon: "calendar.badge.exclamationmark",
                color: .pink,
                label: String(localized: "설날/추석 공휴일_label", defaultValue: "Lunar New Year/Chuseok Holidays")
            )
        }
    }

    private func martToggle(martType: MartType, icon: String, color: Color, label: String) -> some View {
        Toggle(isOn: Binding(
            get: { martSelection.isSelected(martType) },
            set: { newValue in
                // 무료 사용자: 이미 1개 선택 상태에서 추가 선택 시도 시 프리미엄 유도
                if newValue && !martSelection.isSelected(martType) {
                    let currentCount = martSelection.selectedMartTypes.count
                    if !PremiumManager.canAddMoreMarts(currentCount: currentCount) {
                        paywallContext = .martLimit
                        showingPremiumUpgrade = true
                        return
                    }
                }
                martSelection.toggleMart(martType)
                WidgetManager.shared.updateWidget()
            }
        )) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(label)
            }
        }
    }

    // MARK: - Custom Mart Section

    private var customMartSection: some View {
        Section(header: Text("나만의 마트")) {
            if !isPremium {
                PremiumBanner(
                    feature: String(localized: "커스텀_마트_배너", defaultValue: "Add your own mart's closed-day patterns")
                ) {
                    paywallContext = .customMart
                    showingPremiumUpgrade = true
                }
            } else {
                if customMartManager.customMarts.isEmpty {
                    Text("자주 가는 마트의 휴무 패턴을 추가하세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(customMartManager.customMarts) { mart in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { mart.isEnabled && martSelection.isSelected(.custom(id: mart.id.uuidString)) },
                                set: { isOn in
                                    var updatedMart = mart
                                    updatedMart.isEnabled = isOn
                                    customMartManager.updateCustomMart(updatedMart)

                                    if isOn {
                                        martSelection.toggleMart(.custom(id: mart.id.uuidString))
                                    }
                                    WidgetManager.shared.updateWidget()
                                }
                            )) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: mart.color) ?? .gray)
                                        .frame(width: 12, height: 12)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(mart.name)
                                            .font(.subheadline)
                                        Text(mart.patterns.map { $0.displayText }.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }

                            Button(action: {
                                editingCustomMart = mart
                                showingCustomMartEditor = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("\(mart.name) 수정"))

                            Button(action: {
                                customMartManager.deleteCustomMart(mart)
                                WidgetManager.shared.updateWidget()
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("\(mart.name) 삭제"))
                        }
                    }
                }

                Button(action: {
                    editingCustomMart = nil
                    showingCustomMartEditor = true
                }) {
                    Label("마트 추가", systemImage: "plus.circle.fill")
                }
            }
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        Section(header: Text("알림설정")) {
            if !isPremium {
                PremiumBanner(
                    feature: String(localized: "알림_배너", defaultValue: "Get notified before closed days")
                ) {
                    paywallContext = .notification
                    showingPremiumUpgrade = true
                }
            } else {
                Toggle("휴무일 알림", isOn: $isNotificationEnabled)
                    .onChange(of: isNotificationEnabled) {
                        Task {
                            await handleNotificationToggle()
                        }
                    }

                if isNotificationEnabled {
                    Toggle("장보기 좋은 날 알림", isOn: $beforeDayNotificationEnabled)
                        .onChange(of: beforeDayNotificationEnabled) {
                            Task {
                                await notificationManager.setupSmartNotifications(for: tasks)
                            }
                        }

                    HStack {
                        Text("알림 시간")
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {
                            showingTimePicker.toggle()
                        }) {
                            Text(String(format: "%02d:%02d", notificationHour, notificationMinute))
                                .foregroundColor(.blue)
                        }
                    }

                    if showingTimePicker {
                        HStack {
                            Spacer()
                            Picker("시", selection: $notificationHour) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)시").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)

                            Picker("분", selection: $notificationMinute) {
                                ForEach([0, 30], id: \.self) { minute in
                                    Text("\(minute)분").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            Spacer()
                        }
                        .onChange(of: notificationHour) {
                            Task {
                                await notificationManager.setupSmartNotifications(for: tasks)
                            }
                        }
                        .onChange(of: notificationMinute) {
                            Task {
                                await notificationManager.setupSmartNotifications(for: tasks)
                            }
                        }
                    }

                    Text("휴무일 3일 전과 1일 전에 알림이 전송됩니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Developer Section (DEBUG 전용)

    #if DEBUG
    private var developerSection: some View {
        Section(header: Text("개발자")) {
            Toggle(isOn: $isPremium) {
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.purple)
                    Text("Pro 버전 잠금 해제")
                }
            }
            .onChange(of: isPremium) {
                WidgetManager.shared.updateWidget()
            }
            Text("DEBUG 빌드에서만 보이는 개발자용 토글입니다. 릴리스 빌드에는 표시되지 않습니다.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    #endif

    // MARK: - Private Methods

    @MainActor
    private func handleNotificationToggle() async {
        if isNotificationEnabled {
            let status = await notificationManager.checkAuthorizationStatus()

            if status == .authorized {
                await notificationManager.setupSmartNotifications(for: tasks)
                debugLog("✅ [SettingsView] 알림이 활성화되었습니다.")
            } else if status == .denied {
                isNotificationEnabled = false
                showingPermissionAlert = true
                debugLog("❌ [SettingsView] 알림 권한이 거부된 상태입니다.")
            } else {
                let authorized = await notificationManager.requestAuthorization()
                if authorized {
                    await notificationManager.setupSmartNotifications(for: tasks)
                    debugLog("✅ [SettingsView] 알림 권한 허용 후 알림이 활성화되었습니다.")
                } else {
                    isNotificationEnabled = false
                    showingPermissionAlert = true
                    debugLog("❌ [SettingsView] 알림 권한이 거부되어 알림을 비활성화했습니다.")
                }
            }
        } else {
            notificationManager.cancelAllNotifications()
            debugLog("🔕 [SettingsView] 알림이 비활성화되었습니다.")
        }
    }

    @MainActor
    private func checkAndSyncNotificationStatus() async {
        let status = await notificationManager.checkAuthorizationStatus()

        if (status == .denied || status == .notDetermined) && isNotificationEnabled {
            isNotificationEnabled = false
        }

        if isNotificationEnabled && status == .authorized {
            await notificationManager.setupSmartNotifications(for: tasks)
        }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isShowingSettings: .constant(true))
    }
}

// MARK: - NotificationPermissionAlert

struct NotificationPermissionAlert: View {
    @Binding var isPresented: Bool

    var body: some View {
        EmptyView()
            .alert("알림 권한 필요", isPresented: $isPresented) {
                Button("설정으로 이동") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text("휴무일 알림을 받으려면 설정에서 알림 권한을 허용해주세요.")
            }
    }
}

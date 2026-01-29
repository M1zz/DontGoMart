//
//  ImprovedSettingsView.swift
//  DontGoMart
//
//  Created by Claude Code
//

import SwiftUI
import WidgetKit
import TipKit
import UserNotifications

struct ImprovedSettingsView: View {
    @Binding var isShowingSettings: Bool
    @AppStorage(AppStorageKeys.selectedBranch, store: UserDefaults(suiteName: Utillity.appGroupId)) var selectedBranch: Int = 0
    @AppStorage(AppStorageKeys.isCostco, store: UserDefaults(suiteName: Utillity.appGroupId)) var isCostco: Bool = false
    @AppStorage(AppStorageKeys.notificationEnabled, store: UserDefaults(suiteName: Utillity.appGroupId)) var isNotificationEnabled: Bool = false
    @AppStorage(AppStorageKeys.shoppingReminderEnabled, store: UserDefaults(suiteName: Utillity.appGroupId)) var isShoppingReminderEnabled: Bool = false
    @AppStorage(AppStorageKeys.locationEnabled, store: UserDefaults(suiteName: Utillity.appGroupId)) var isLocationEnabled: Bool = false

    @StateObject private var locationManager = LocationManager.shared

    private let notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false
    @State private var showingLocationPermissionAlert = false

    var body: some View {
        NavigationStack {
            Form {
                martSelectionSection

                locationSection

                notificationSection

                shoppingReminderSection

                supportSection

                aboutSection
            }
            .navigationTitle("설정")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        WidgetManager.shared.updateWidget()
                        isShowingSettings = false
                    }) {
                        Text("완료")
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
            .alert("위치 권한 필요", isPresented: $showingLocationPermissionAlert) {
                Button("설정으로 이동") {
                    openAppSettings()
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text("주변 매장을 찾으려면\n설정 > DontGoMart > 위치에서\n권한을 허용해주세요.")
            }
        }
    }

    private var martSelectionSection: some View {
        Section(header: Text("매장 선택")) {
            Toggle(isOn: $isCostco, label: {
                Text("코스트코")
            })
            .onChange(of: isCostco) {
                selectedBranch = isCostco ? 1 : 0
                WidgetManager.shared.updateWidget()

                Task {
                    await handleNotificationToggle()
                }
            }
            if isCostco {
                CostcoSettings()
            }
        }
    }

    private var locationSection: some View {
        Section(header: Text("위치 기반 기능")) {
            Toggle(isOn: $isLocationEnabled, label: {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color("Pink"))
                    Text("주변 매장 자동 감지")
                }
            })
            .onChange(of: isLocationEnabled) {
                handleLocationToggle()
            }

            if isLocationEnabled {
                Text("현재 위치를 기반으로 가까운 매장을 찾아 추천합니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !locationManager.nearbyStores.isEmpty {
                    ForEach(locationManager.nearbyStores.prefix(3)) { store in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(store.displayName)
                                    .font(.subheadline)
                                Text(store.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var notificationSection: some View {
        Section(header: Text("알림 설정")) {
            Toggle(isOn: $isNotificationEnabled, label: {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(Color("Pink"))
                    Text("휴무일 알림")
                }
            })
            .onChange(of: isNotificationEnabled) {
                Task {
                    await handleNotificationToggle()
                }
            }

            if isNotificationEnabled {
                Text(NotificationManager.settingsDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var shoppingReminderSection: some View {
        Section(header: Text("장보기 리마인더")) {
            Toggle(isOn: $isShoppingReminderEnabled, label: {
                HStack {
                    Image(systemName: "cart.fill")
                        .foregroundColor(Color("Pink"))
                    Text("장보기 알림")
                }
            })
            .disabled(!isNotificationEnabled)

            if isShoppingReminderEnabled {
                Text("다음 휴무일 2일 전에 장보기를 알려드립니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if !isNotificationEnabled {
                Text("휴무일 알림을 먼저 켜주세요.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private var supportSection: some View {
        Section(header: Text("응원하기")) {
            Button(action: {
                ReviewManager.openAppStoreForReview()
            }) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("앱스토어에 리뷰 남기기")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }

            Button(action: {
                ReviewManager.openAppStorePage()
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color("Pink"))
                    Text("앱스토어에서 보기")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }

    private var aboutSection: some View {
        Section(header: Text("정보")) {
            HStack {
                Text("버전")
                Spacer()
                Text("2.0.0")
                    .foregroundColor(.secondary)
            }

            Link(destination: URL(string: "https://github.com/MuchanKim/DontGoMart")!) {
                HStack {
                    Text("GitHub")
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func handleNotificationToggle() async {
        if isNotificationEnabled {
            let status = await notificationManager.checkAuthorizationStatus()

            if status == .authorized {
                await notificationManager.setupSmartNotifications(for: tasks)
                print("✅ [ImprovedSettingsView] 알림이 활성화되었습니다.")
            } else if status == .denied {
                DispatchQueue.main.async {
                    self.isNotificationEnabled = false
                    self.showingPermissionAlert = true
                }
                print("❌ [ImprovedSettingsView] 알림 권한이 거부된 상태입니다.")
            } else {
                let authorized = await notificationManager.requestAuthorization()
                if authorized {
                    await notificationManager.setupSmartNotifications(for: tasks)
                    print("✅ [ImprovedSettingsView] 알림 권한 허용 후 알림이 활성화되었습니다.")
                } else {
                    DispatchQueue.main.async {
                        self.isNotificationEnabled = false
                        self.showingPermissionAlert = true
                    }
                    print("❌ [ImprovedSettingsView] 알림 권한이 거부되어 알림을 비활성화했습니다.")
                }
            }
        } else {
            notificationManager.cancelAllNotifications()
            print("🔕 [ImprovedSettingsView] 알림이 비활성화되었습니다.")
        }
    }

    private func handleLocationToggle() {
        if isLocationEnabled {
            let status = locationManager.authorizationStatus

            if status == .authorizedWhenInUse || status == .authorizedAlways {
                locationManager.startUpdatingLocation()
            } else if status == .denied || status == .restricted {
                DispatchQueue.main.async {
                    self.isLocationEnabled = false
                    self.showingLocationPermissionAlert = true
                }
            } else {
                locationManager.requestAuthorization()
            }
        } else {
            locationManager.stopUpdatingLocation()
        }
    }

    private func checkAndSyncNotificationStatus() async {
        let status = await notificationManager.checkAuthorizationStatus()

        if status == .denied || status == .notDetermined {
            if isNotificationEnabled {
                DispatchQueue.main.async {
                    self.isNotificationEnabled = false
                }
            }
        }

        if isNotificationEnabled && status == .authorized {
            await notificationManager.setupSmartNotifications(for: tasks)
        }
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    ImprovedSettingsView(isShowingSettings: .constant(true))
}

//
//  SettingsView.swift
//  DontGoMart
//
//  Created by hyunho lee on 7/8/23.
//

import SwiftUI
import WidgetKit
import UIKit
import StoreKit
import LeeoKit

struct SettingsView: View {
    @Binding var isShowingSettings: Bool
    @AppStorage(AppStorageKeys.notificationEnabled, store: UserDefaults(suiteName: Utillity.appGroupId)) var isNotificationEnabled: Bool = false
    @AppStorage(AppStorageKeys.notificationHour, store: UserDefaults(suiteName: Utillity.appGroupId)) var notificationHour: Int = 9
    @AppStorage(AppStorageKeys.notificationMinute, store: UserDefaults(suiteName: Utillity.appGroupId)) var notificationMinute: Int = 0
    @AppStorage(AppStorageKeys.beforeDayNotificationEnabled, store: UserDefaults(suiteName: Utillity.appGroupId)) var beforeDayNotificationEnabled: Bool = true
    @AppStorage(AppStorageKeys.notificationLeadDays, store: UserDefaults(suiteName: Utillity.appGroupId)) var notificationLeadDays: Int = NotificationManager.defaultLeadDays

    @StateObject private var martSelection = MartSelectionManager.shared
    @StateObject private var customMartManager = CustomMartManager.shared

    private let notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false
    @State private var showingTimePicker = false
    @State private var showingCustomMartEditor = false
    @State private var editingCustomMart: CustomMart? = nil

    /// 개발자(마스터) 모드 — LeeoSupportSection 의 '버전' 행을 7번 탭하면 켜진다.
    /// 켜져 있을 때만 접수된 피드백·사용 통계 진입점이 보인다. 키 이름은 LeeoKit 과 같아야 한다.
    @AppStorage("dev.masterMode") private var isMasterMode = false

    var body: some View {
        NavigationStack {
            Form {
                martSelectionSection
                customMartSection
                notificationSection
                supportSection
                Section {
                    LeeoSupportSection<DontGoMartSpec>()
                    // 앞으로 만들 기능 — 원본은 DontGoMartRoadmap.swift
                    NavigationLink(LeeoRoadmapText.entry) { RoadmapScreen() }
                    // 친구에게 소개하기 — App Store ID 가 없으면 그리지 않는다
                    LeeoShareAppLink<DontGoMartSpec>()
                    if isMasterMode {
                        NavigationLink {
                            LeeoUsageStatsView<DontGoMartSpec>()
                        } label: {
                            Label("사용 통계 (개발자)", systemImage: "chart.bar.xaxis")
                        }
                    }
                } header: {
                    Text("지원")
                }
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
                #if DEBUG
                // 스토어 스크린샷용: -ScreenshotScreen pattern 이면 내 매장 → 패턴 편집까지 바로 연다
                if UserDefaults.standard.string(forKey: "ScreenshotScreen") == "pattern" {
                    showingCustomMartEditor = true
                }
                #endif
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
        }
    }

    // MARK: - Support Section (팁 — 리이오의 다른 앱과 같은 LeeoKit 팁 화면)

    /// 낸 사람에게는 줄에 후원자 배지(응원 단계 · 점수)가 선다. 상품을 못 불러오면 줄이 서지 않는다.
    private var supportSection: some View {
        Section(
            header: Text("응원하기"),
            footer: Text("모든 기능은 계속 무료예요. 후원은 순수한 응원이며, 몇 번이든 보낼 수 있어요.")
        ) {
            LeeoTipJarLink<DontGoMartSpec>(tipJar: DontGoMartTips.jar, systemImage: "cup.and.saucer.fill")
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
            set: { _ in
                martSelection.toggleMart(martType)
                WidgetManager.shared.updateWidget()
                AppUsage.log(.martChanged)
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

                                // toggleMart 를 쓰면 껐다 켤 때 선택이 어긋나므로 목표 상태로 직접 맞춘다
                                martSelection.setSelected(isOn, for: .custom(id: mart.id.uuidString))
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

    // MARK: - Notification Section

    private var notificationSection: some View {
        Section(header: Text("알림설정")) {
            Toggle("휴무일 알림", isOn: $isNotificationEnabled)
                .onChange(of: isNotificationEnabled) {
                    Task {
                        await handleNotificationToggle()
                    }
                }

            if isNotificationEnabled {
                Picker("알림 시점", selection: $notificationLeadDays) {
                    ForEach(NotificationManager.leadDayPresets, id: \.self) { days in
                        Text("\(days)일 전").tag(days)
                    }
                }
                .onChange(of: notificationLeadDays) {
                    Task {
                        await notificationManager.setupSmartNotifications(for: tasks)
                    }
                }

                Toggle("장보기 좋은 날 알림 (전날)", isOn: $beforeDayNotificationEnabled)
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

                Text(notificationDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// 현재 알림 설정을 사람이 읽기 좋은 한 줄로.
    private var notificationDescription: String {
        // 문장을 조각내어 이어 붙이면 번역이 불가능하므로, 완성된 문장 두 개 중 하나를 고른다.
        let time = String(format: "%02d:%02d", notificationHour, notificationMinute)
        if beforeDayNotificationEnabled {
            return String(format: String(localized: "휴무일 %1$lld일 전과 전날 %2$@에 알림이 전송됩니다.",
                                         defaultValue: "You'll be notified %1$lld days before and the day before, at %2$@."),
                          notificationLeadDays, time)
        }
        return String(format: String(localized: "휴무일 %1$lld일 전 %2$@에 알림이 전송됩니다.",
                                     defaultValue: "You'll be notified %1$lld days before, at %2$@."),
                      notificationLeadDays, time)
    }

    // MARK: - Private Methods

    @MainActor
    private func handleNotificationToggle() async {
        if isNotificationEnabled {
            let status = await notificationManager.checkAuthorizationStatus()

            if status == .authorized {
                await notificationManager.setupSmartNotifications(for: tasks)
                AppUsage.log(.notificationOn)
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

//
//  SettingsView.swift
//  Klosed
//
//  Created by hyunho lee on 7/8/23.
//

import SwiftUI
import WidgetKit
import TipKit
import UIKit

struct StoreTip: Tip {
    var title: Text { Text("해당 지점") }
    var message: Text? {
        Text("양평점, 대전점, 양재점, \n상봉점, 부산점, 광명점, \n천안점, 의정부점, 공세점, \n송도점, 세종점, 하남점, \n김해점, 고척점")
    }
    var options: [Option] {
        MaxDisplayCount(10)
    }
}


struct SettingsView: View {
    @Binding var isShowingSettings: Bool
    @AppStorage(AppStorageKeys.selectedBranch, store: UserDefaults(suiteName: Utillity.appGroupId)) var selectedBranch: Int = 0
    @AppStorage(AppStorageKeys.isCostco, store: UserDefaults(suiteName: Utillity.appGroupId)) var isCostco: Bool = false
    @AppStorage(AppStorageKeys.notificationEnabled, store: UserDefaults(suiteName: Utillity.appGroupId)) var isNotificationEnabled: Bool = false
    @AppStorage(AppStorageKeys.notificationHour, store: UserDefaults(suiteName: Utillity.appGroupId)) var notificationHour: Int = 9
    @AppStorage(AppStorageKeys.notificationMinute, store: UserDefaults(suiteName: Utillity.appGroupId)) var notificationMinute: Int = 0
    @AppStorage(AppStorageKeys.beforeDayNotificationEnabled, store: UserDefaults(suiteName: Utillity.appGroupId)) var beforeDayNotificationEnabled: Bool = true
    @AppStorage(AppStorageKeys.favoriteMarts, store: UserDefaults(suiteName: Utillity.appGroupId)) var favoriteMarts: String = ""
    @AppStorage(AppStorageKeys.isPremium) var isPremium: Bool = false

    @StateObject private var martSelection = MartSelectionManager.shared
    @StateObject private var customMartManager = CustomMartManager.shared

    private let notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false
    @State private var showingTimePicker = false
    @State private var showingCustomMartEditor = false
    @State private var editingCustomMart: CustomMart? = nil
    @State private var showingPremiumUpgrade = false

    private func isFavorite(_ martType: MartType) -> Bool {
        return favoriteMarts.contains(martType.storageKey)
    }

    private func toggleFavorite(_ martType: MartType) {
        var favorites = Set(favoriteMarts.split(separator: ",").map(String.init))
        if favorites.contains(martType.storageKey) {
            favorites.remove(martType.storageKey)
        } else {
            favorites.insert(martType.storageKey)
        }
        favoriteMarts = favorites.joined(separator: ",")
    }

    var body: some View {
        NavigationStack {
            Form {
                martSelectionSection
                customMartSection
                notificationSection
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
                PremiumUpgradeView()
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
                label: String(localized: "대형마트 (일요일 휴무)_label", defaultValue: "Supermarket (Sunday closed)", table: "CodeStrings")
            )

            martToggle(
                martType: .normal(type: .wednesday),
                icon: "cart.fill",
                color: .cyan,
                label: String(localized: "대형마트 (수요일 휴무)_label", defaultValue: "Supermarket (Wednesday closed)", table: "CodeStrings")
            )

            martToggle(
                martType: .normal(type: .mixed),
                icon: "cart.fill",
                color: .teal,
                label: String(localized: "대형마트 (울산 혼합)_label", defaultValue: "Supermarket (Ulsan mixed)", table: "CodeStrings")
            )

            martToggle(
                martType: .normal(type: .jeju),
                icon: "cart.fill",
                color: .mint,
                label: String(localized: "대형마트 (제주)_label", defaultValue: "Supermarket (Jeju)", table: "CodeStrings")
            )

            // 코스트코 지점별
            martToggle(
                martType: .costco(type: .normal),
                icon: "building.2.fill",
                color: .red,
                label: String(localized: "코스트코 일반매장_label", defaultValue: "Costco Regular", table: "CodeStrings")
            )

            martToggle(
                martType: .costco(type: .daegu),
                icon: "building.2.fill",
                color: .orange,
                label: String(localized: "코스트코 대구점_label", defaultValue: "Costco Daegu", table: "CodeStrings")
            )

            martToggle(
                martType: .costco(type: .ilsan),
                icon: "building.2.fill",
                color: .green,
                label: String(localized: "코스트코 일산점_label", defaultValue: "Costco Ilsan", table: "CodeStrings")
            )

            martToggle(
                martType: .costco(type: .ulsan),
                icon: "building.2.fill",
                color: .purple,
                label: String(localized: "코스트코 울산점_label", defaultValue: "Costco Ulsan", table: "CodeStrings")
            )

            // 공휴일
            martToggle(
                martType: .holiday,
                icon: "calendar.badge.exclamationmark",
                color: .pink,
                label: String(localized: "설날/추석 공휴일_label", defaultValue: "Lunar New Year/Chuseok Holidays", table: "CodeStrings")
            )
        }
    }

    private func martToggle(martType: MartType, icon: String, color: Color, label: String) -> some View {
        HStack {
            Toggle(isOn: Binding(
                get: { martSelection.isSelected(martType) },
                set: { newValue in
                    // 무료 사용자: 이미 1개 선택 상태에서 추가 선택 시도 시 프리미엄 유도
                    if newValue && !martSelection.isSelected(martType) {
                        let currentCount = martSelection.selectedMartTypes.count
                        if !PremiumManager.canAddMoreMarts(currentCount: currentCount) {
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

            if isPremium {
                Button(action: {
                    toggleFavorite(martType)
                }) {
                    Image(systemName: isFavorite(martType) ? "star.fill" : "star")
                        .foregroundColor(isFavorite(martType) ? .yellow : .gray)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Custom Mart Section

    private var customMartSection: some View {
        Section(header: Text("나만의 마트")) {
            if !isPremium {
                PremiumBanner(
                    feature: String(localized: "커스텀_마트_배너", defaultValue: "Add your own mart's closed-day patterns", table: "CodeStrings")
                ) {
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

                            Button(action: {
                                customMartManager.deleteCustomMart(mart)
                                WidgetManager.shared.updateWidget()
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
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
                    feature: String(localized: "알림_배너", defaultValue: "Get notified before closed days", table: "CodeStrings")
                ) {
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

    // MARK: - Private Methods

    private func handleNotificationToggle() async {
        if isNotificationEnabled {
            let status = await notificationManager.checkAuthorizationStatus()

            if status == .authorized {
                await notificationManager.setupSmartNotifications(for: tasks)
                print("✅ [SettingsView] 알림이 활성화되었습니다.")
            } else if status == .denied {
                DispatchQueue.main.async {
                    self.isNotificationEnabled = false
                    self.showingPermissionAlert = true
                }
                print("❌ [SettingsView] 알림 권한이 거부된 상태입니다.")
            } else {
                let authorized = await notificationManager.requestAuthorization()
                if authorized {
                    await notificationManager.setupSmartNotifications(for: tasks)
                    print("✅ [SettingsView] 알림 권한 허용 후 알림이 활성화되었습니다.")
                } else {
                    DispatchQueue.main.async {
                        self.isNotificationEnabled = false
                        self.showingPermissionAlert = true
                    }
                    print("❌ [SettingsView] 알림 권한이 거부되어 알림을 비활성화했습니다.")
                }
            }
        } else {
            notificationManager.cancelAllNotifications()
            print("🔕 [SettingsView] 알림이 비활성화되었습니다.")
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
}


struct CostcoSettings: View {
    @AppStorage(AppStorageKeys.selectedBranch, store: UserDefaults(suiteName: Utillity.appGroupId)) var selectedBranch: Int = 0
    @State var selectedCostcoBranch: CostcoBranch = .normal

    @State private var isNormalSelected = false
    @State private var isDaeguSelected = false
    @State private var isIlsanSelected = false
    @State private var isUlsanSelected = false
    @State private var isTipShowing = false
    var storeTip = StoreTip()


    var body: some View {
        VStack {
            HStack {
                Text("매장을 선택해주세요")
                    .padding()
                Spacer()
            }
            VStack(spacing: 10) {
                Toggle(isOn: Binding(
                    get: { isNormalSelected },
                    set: { _ in updateSelection(for: .normal) }
                )) {
                    HStack {
                        Text("일반매장")

                        if isTipShowing {
                            Image(systemName: "questionmark.circle")
                                .popoverTip(storeTip)
                                .onTapGesture {
                                    isTipShowing.toggle()
                                }
                        } else {
                            Image(systemName: "questionmark.circle")
                                .onTapGesture {
                                    isTipShowing.toggle()
                                }
                        }
                    }
                }


                Toggle("대구 지점", isOn: Binding(
                    get: { isDaeguSelected },
                    set: { _ in updateSelection(for: .daegu) }
                ))

                Toggle("일산 지점", isOn: Binding(
                    get: { isIlsanSelected },
                    set: { _ in updateSelection(for: .ilsan) }
                ))

                Toggle("울산 지점", isOn: Binding(
                    get: { isUlsanSelected },
                    set: { _ in updateSelection(for: .ulsan) }
                ))
            }
            .padding()

            Spacer()
        }
        .onAppear {
            syncSelectionState()
        }
        .task {
            try? Tips.resetDatastore()
            try? Tips.configure([.displayFrequency(.immediate)])
        }
    }

    private func updateSelection(for branch: CostcoBranch) {
            // 다른 선택지를 초기화하고 현재 선택지를 저장
            resetAllSelections()
            selectedCostcoBranch = branch
            selectedBranch = branch.branchID

            switch branch {
            case .normal:
                isNormalSelected = true
            case .daegu:
                isDaeguSelected = true
            case .ilsan:
                isIlsanSelected = true
            case .ulsan:
                isUlsanSelected = true
            }
    }

    private func resetAllSelections() {
        isNormalSelected = false
        isDaeguSelected = false
        isIlsanSelected = false
        isUlsanSelected = false
    }

    private func syncSelectionState() {
        switch selectedBranch {
        case 1:
            updateSelection(for: .normal)
        case 2:
            updateSelection(for: .daegu)
        case 3:
            updateSelection(for: .ilsan)
        case 4:
            updateSelection(for: .ulsan)
        default:
            resetAllSelections()
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

//
//  ClosedDaysView.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/15.
//

import SwiftUI
import StoreKit
import WidgetKit

struct ClosedDaysView: View {
    @State var currentDate: Date = Date()
    @StateObject var storeKit = StoreKitManager()
    @AppStorage("isPremium") var isPremium: Bool = false
    @State private var isShowingSettings = false
    @State private var isShowingShoppingList = false
    @State private var isShowingCalendar = false
    @State private var isCostco: Bool = false
    @AppStorage(AppStorageKeys.selectedBranch, store: UserDefaults(suiteName: Utillity.appGroupId)) var selectedBranch: Int = 0
    @AppStorage(AppStorageKeys.locationEnabled, store: UserDefaults(suiteName: Utillity.appGroupId)) var isLocationEnabled: Bool = false
    @AppStorage(AppStorageKeys.viewMode, store: UserDefaults(suiteName: Utillity.appGroupId)) var viewMode: String = "month"
    @AppStorage(AppStorageKeys.favoriteMarts, store: UserDefaults(suiteName: Utillity.appGroupId)) var favoriteMarts: String = ""

    @StateObject private var operationStatusManager = OperationStatusManager.shared
    @StateObject private var shoppingManager = ShoppingReminderManager.shared
    @StateObject private var martSelection = MartSelectionManager.shared

    private func isFavorite(_ martType: MartType) -> Bool {
        return favoriteMarts.contains(martType.storageKey)
    }

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

    private var primaryMartType: MartType {
        let selected = martSelection.getSelectedMartTypes()
        return selected.first ?? .normal(type: .sunday)
    }

    var body: some View {
        NavigationStack {
            mainScrollView
                .navigationTitle(navigationTitle)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        settingsButton
                    }
                }
        }
        .onChange(of: selectedBranch) {
            handleBranchChange()
        }
        .sheet(isPresented: $isShowingSettings, onDismiss: onSettingsDismiss) {
            SettingsView(isShowingSettings: $isShowingSettings)
        }
        .sheet(isPresented: $isShowingShoppingList) {
            shoppingListSheet
        }
        .sheet(isPresented: $isShowingCalendar) {
            calendarSheet
        }
        .onAppear {
            onViewAppear()
        }
    }

    // MARK: - Subviews

    private var mainScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                operationStatusCard
                nextClosedDateCard
                viewModeToggle
                quickActionsCard
                upcomingClosedDatesCard

                if !isPremium {
                    premiumSection
                }
            }
            .padding(.vertical)
        }
    }

    private var viewModeToggle: some View {
        HStack {
            Picker("", selection: $viewMode) {
                Text("주간").tag("week")
                Text("월간").tag("month")
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
        }
        .padding(.horizontal)
    }

    private var navigationTitle: String {
        let baseName = locationName(forID: selectedBranch)
        return isPremium ? "돈꼬 \(baseName) pro" : "돈꼬 \(baseName)"
    }

    private var settingsButton: some View {
        Button(action: {
            isShowingSettings.toggle()
        }) {
            Image(systemName: "gear")
        }
    }

    private var premiumSection: some View {
        Group {
            PurchaseItemView()
            Divider()
            Button(Utillity.restorePurchases) {
                Task {
                    try? await AppStore.sync()
                }
            }
        }
    }

    private var shoppingListSheet: some View {
        NavigationStack {
            ShoppingListView()
        }
    }

    private var calendarSheet: some View {
        NavigationStack {
            ClosedDayCalendarView(
                currentDate: $currentDate,
                isCostco: isCostco,
                selectedBranch: selectedBranch
            )
            .navigationTitle("휴무일 캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        isShowingCalendar = false
                    }
                }
            }
        }
    }

    // MARK: - Event Handlers

    private func handleBranchChange() {
        print("selectedBranch: \(selectedBranch)")
        WidgetManager.shared.updateWidget()
    }

    private func onSettingsDismiss() {
        isCostco = UserDefaults(suiteName: Utillity.appGroupId)?.bool(forKey: AppStorageKeys.isCostco) ?? false
        selectedBranch = UserDefaults(suiteName: Utillity.appGroupId)?.integer(forKey: AppStorageKeys.selectedBranch) ?? 0
    }

    private func onViewAppear() {
        isCostco = UserDefaults(suiteName: Utillity.appGroupId)?.bool(forKey: AppStorageKeys.isCostco) ?? false
    }

    // MARK: - 새로운 카드 뷰들

    private var operationStatusCard: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 선택된 모든 마트의 오늘 영업 상태 확인
        let selectedMartTypes = martSelection.getSelectedMartTypes()
        let todayClosedMarts = tasks.filter { task in
            selectedMartTypes.contains(task.type) && calendar.isDate(task.taskDate, inSameDayAs: today)
        }

        let hasClosedMart = !todayClosedMarts.isEmpty
        let allClosed = selectedMartTypes.count == todayClosedMarts.count && !selectedMartTypes.isEmpty
        let hasNoSelection = selectedMartTypes.isEmpty
        let status: OperationStatus = allClosed ? .closed : .open

        return VStack(spacing: 12) {
            HStack {
                Text("오늘 갈 수 있나요?")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Text(hasNoSelection ? "⚙️" : status.emoji)
                    .font(.system(size: 50))

                operationStatusText(
                    allClosed: allClosed,
                    hasClosedMart: hasClosedMart,
                    todayClosedMarts: todayClosedMarts,
                    hasNoSelection: hasNoSelection
                )

                Spacer()
            }
        }
        .padding()
        .background(operationStatusBackground(allClosed: allClosed, hasClosedMart: hasClosedMart, hasNoSelection: hasNoSelection))
        .overlay(operationStatusBorder(allClosed: allClosed, hasClosedMart: hasClosedMart, hasNoSelection: hasNoSelection))
        .padding(.horizontal)
    }

    private func operationStatusText(allClosed: Bool, hasClosedMart: Bool, todayClosedMarts: [MetaMartsClosedDays], hasNoSelection: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if hasNoSelection {
                Text("매장을 선택해주세요")
                    .font(.title.bold())
                    .foregroundColor(.gray)
                Text("설정에서 추적할 매장을 선택하세요")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if allClosed {
                Text("휴무예요")
                    .font(.title.bold())
                    .foregroundColor(.red)
                Text("선택한 모든 매장이 휴무입니다")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if hasClosedMart {
                Text("일부 영업중")
                    .font(.title.bold())
                    .foregroundColor(.orange)
                ForEach(todayClosedMarts.prefix(2)) { closedMart in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorForMartType(closedMart.type))
                            .frame(width: 6, height: 6)
                        Text("\(closedMart.type.displayName) 휴무")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("영업중이에요")
                    .font(.title.bold())
                    .foregroundColor(.green)
                Text("선택한 모든 매장이 영업합니다")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func operationStatusBackground(allClosed: Bool, hasClosedMart: Bool, hasNoSelection: Bool) -> some View {
        let backgroundColor: Color
        if hasNoSelection {
            backgroundColor = Color.gray.opacity(0.1)
        } else if allClosed {
            backgroundColor = Color.red.opacity(0.1)
        } else if hasClosedMart {
            backgroundColor = Color.orange.opacity(0.1)
        } else {
            backgroundColor = Color.green.opacity(0.1)
        }

        return RoundedRectangle(cornerRadius: 16).fill(backgroundColor)
    }

    private func operationStatusBorder(allClosed: Bool, hasClosedMart: Bool, hasNoSelection: Bool) -> some View {
        let borderColor: Color
        if hasNoSelection {
            borderColor = Color.gray.opacity(0.3)
        } else if allClosed {
            borderColor = Color.red.opacity(0.3)
        } else if hasClosedMart {
            borderColor = Color.orange.opacity(0.3)
        } else {
            borderColor = Color.green.opacity(0.3)
        }

        return RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 2)
    }

    private var nextClosedDateCard: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 선택된 모든 마트의 휴무일 중 가장 가까운 날짜 찾기
        let selectedMartTypes = martSelection.getSelectedMartTypes()
        let nextClosedDate = tasks
            .filter { task in
                selectedMartTypes.contains(task.type) && task.taskDate >= today
            }
            .sorted { $0.taskDate < $1.taskDate }
            .first

        let daysUntil = nextClosedDate.flatMap { closedDate in
            calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: closedDate.taskDate)).day
        }

        return VStack(spacing: 12) {
            HStack {
                Text("다음 휴무일")
                    .font(.headline)
                Spacer()
            }

            if let days = daysUntil, let closedDate = nextClosedDate {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorForMartType(closedDate.type))
                                .frame(width: 8, height: 8)
                            Text(operationStatusManager.formatDDay(days))
                                .font(.title2.bold())
                                .foregroundColor(Color("Pink"))
                        }

                        Text(closedDate.taskDate.formatted(date: .long, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Text(closedDate.type.displayName)
                                .font(.caption.bold())
                                .foregroundColor(colorForMartType(closedDate.type))
                            Text("•")
                                .foregroundColor(.secondary)
                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text(closedDate.type.operatingHours)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if days <= 3 {
                        VStack(spacing: 4) {
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
                    isShowingCalendar = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.title2)
                        Text("캘린더 보기")
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

    private var upcomingClosedDatesCard: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 주간/월간 뷰에 따라 기간 설정
        let endDate: Date
        if viewMode == "week" {
            endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: today) ?? today
        } else {
            endDate = calendar.date(byAdding: .month, value: 3, to: today) ?? today
        }

        let selectedMartTypes = martSelection.getSelectedMartTypes()
        let upcomingDates = tasks.filter { task in
            selectedMartTypes.contains(task.type) &&
            task.taskDate >= today &&
            task.taskDate <= endDate
        }.sorted { task1, task2 in
            // 즐겨찾기 마트를 우선 정렬
            let isFav1 = isFavorite(task1.type)
            let isFav2 = isFavorite(task2.type)
            if isFav1 != isFav2 {
                return isFav1
            }
            return task1.taskDate < task2.taskDate
        }
        .prefix(10)

        return VStack(spacing: 12) {
            HStack {
                Text("다가오는 휴무일")
                    .font(.headline)
                Spacer()
                Button(action: {
                    isShowingCalendar = true
                }) {
                    HStack(spacing: 4) {
                        Text("전체보기")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(Color("Pink"))
                }
            }

            if upcomingDates.isEmpty {
                Text("휴무일 정보가 없습니다")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(upcomingDates.enumerated()), id: \.element.id) { index, closedDate in
                        HStack {
                            // 마트 타입 색상 표시
                            Circle()
                                .fill(colorForMartType(closedDate.type))
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if isFavorite(closedDate.type) {
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundColor(.yellow)
                                    }
                                    Text(closedDate.type.displayName)
                                        .font(.caption.bold())
                                        .foregroundColor(colorForMartType(closedDate.type))
                                    Text(closedDate.taskDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                }
                                if let task = closedDate.task.first {
                                    Text(task.title)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            if let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: closedDate.taskDate)).day {
                                Text(operationStatusManager.formatDDay(days))
                                    .font(.caption.bold())
                                    .foregroundColor(colorForMartType(closedDate.type))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(colorForMartType(closedDate.type).opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 8)

                        if index < upcomingDates.count - 1 {
                            Divider()
                        }
                    }
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
    
    private func locationName(forID id: Int) -> String {
        switch id {
        case 0:
            return "마트"
        case 1:
            return "일반 코스트코"
        case 2:
            return "대구 코스트코"
        case 3:
            return "일산 코스트코"
        case 4:
            return "울산 코스트코"
        default:
            return ""
        }
    }

    private func colorForMartType(_ martType: MartType) -> Color {
        switch martType {
        case .normal(let branch):
            switch branch {
            case .sunday:
                return .blue
            case .wednesday:
                return .cyan
            case .mixed:
                return .teal
            case .jeju:
                return .mint
            }
        case .costco(let branch):
            switch branch {
            case .normal:
                return .red
            case .daegu:
                return .orange
            case .ilsan:
                return .green
            case .ulsan:
                return .purple
            }
        case .custom(let id):
            if let customMart = CustomMartManager.shared.getCustomMart(byId: id) {
                return Color(hex: customMart.color) ?? .gray
            }
            return .gray
        case .holiday:
            return .pink
        }
    }
    
    fileprivate func PurchaseItemView() -> ForEach<[Product], Product.ID, HStack<TupleView<(Text, Spacer, Button<SellItem>)>>> {
        return ForEach(storeKit.storeProducts) {product in
            HStack {
                Text(product.displayName)
                Spacer()
                Button(action: {
                    Task { try await
                        storeKit.purchase(product)
                        isPremium = true
                    }
                }) {
                    SellItem(storeKit: storeKit, product: product)
                }
            }
        }
    }
}

struct SellItem: View {
    @ObservedObject var storeKit : StoreKitManager
    @State var isPurchased: Bool = false
    var product: Product
    
    var body: some View {
        VStack {
            if isPurchased {
                Text(Image(systemName: "checkmark"))
                    .bold()
                    .padding(10)
            } else {
                Text(product.displayPrice)
                    .padding(10)
            }
        }
        .onChange(of: storeKit.purchasedCourses) {
            Task {
                isPurchased = (try? await storeKit.isPurchased(product)) ?? false
            }
        }
    }
}

class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: Utillity.appGroupId)!
    
    @AppStorage("hasPro", store: userDefaults) var hasPro: Bool = false
}

#Preview {
    ClosedDaysView()
}

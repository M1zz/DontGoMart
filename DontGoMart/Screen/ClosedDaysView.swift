//
//  ClosedDaysView.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/15.
//

import SwiftUI
import WidgetKit

struct ClosedDaysView: View {
    @State var currentDate: Date = Date()
    @State private var isShowingSettings = false
    @State private var isShowingCalendar = false

    @StateObject private var martSelection = MartSelectionManager.shared

    var body: some View {
        NavigationStack {
            mainScrollView
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .overlay(alignment: .bottomTrailing) {
                    settingsButton
                }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(isShowingSettings: $isShowingSettings)
        }
        .sheet(isPresented: $isShowingCalendar) {
            calendarSheet
        }
        .onOpenURL { url in
            // 위젯 탭 딥링크 → 캘린더 열기
            if url.scheme == Utillity.deepLinkScheme, url.host == "calendar" {
                isShowingSettings = false
                isShowingCalendar = true
            }
        }
    }

    // MARK: - Subviews

    private var mainScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                todayStatusCard
                nextClosedDateCard
                calendarButton
                upcomingClosedDatesCard
            }
            .padding(.vertical)
        }
    }

    private var settingsButton: some View {
        Button(action: {
            isShowingSettings.toggle()
        }) {
            Image(systemName: "gear")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(Color("Pink"))
                )
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel(Text("설정"))
        .accessibilityHint(Text("매장 선택 및 알림 설정 화면을 엽니다"))
    }

    private var calendarSheet: some View {
        NavigationStack {
            ClosedDayCalendarView(currentDate: $currentDate)
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

    // MARK: - 오늘 갈 수 있나요? (가장 큰 한 가지 정보)

    private var todayStatusCard: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let selectedMartTypes = martSelection.getSelectedMartTypes()
        let todayClosedMarts = tasks.filter { task in
            selectedMartTypes.contains(task.type) && calendar.isDate(task.taskDate, inSameDayAs: today)
        }

        let hasNoSelection = selectedMartTypes.isEmpty
        let allClosed = !selectedMartTypes.isEmpty && selectedMartTypes.count == todayClosedMarts.count
        let hasClosedMart = !todayClosedMarts.isEmpty

        return VStack(spacing: 12) {
            HStack {
                Text("오늘 갈 수 있나요?")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            HStack(spacing: 16) {
                Text(hasNoSelection ? "⚙️" : (allClosed ? "🚫" : (hasClosedMart ? "⚠️" : "✅")))
                    .font(.system(size: 56))
                    .accessibilityHidden(true)

                todayStatusText(
                    hasNoSelection: hasNoSelection,
                    allClosed: allClosed,
                    hasClosedMart: hasClosedMart,
                    todayClosedMarts: todayClosedMarts
                )

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(todayStatusColor(hasNoSelection: hasNoSelection, allClosed: allClosed, hasClosedMart: hasClosedMart).opacity(0.12))
        )
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(todayStatusAccessibilityLabel(
            hasNoSelection: hasNoSelection,
            allClosed: allClosed,
            hasClosedMart: hasClosedMart,
            todayClosedMarts: todayClosedMarts
        )))
    }

    private func todayStatusColor(hasNoSelection: Bool, allClosed: Bool, hasClosedMart: Bool) -> Color {
        if hasNoSelection { return .gray }
        if allClosed { return .red }
        if hasClosedMart { return .orange }
        return .green
    }

    private func todayStatusText(hasNoSelection: Bool, allClosed: Bool, hasClosedMart: Bool, todayClosedMarts: [MetaMartsClosedDays]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if hasNoSelection {
                Text("매장을 선택해주세요")
                    .font(.title2.bold())
                    .foregroundColor(.gray)
                Text("설정에서 추적할 매장을 고르세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if allClosed {
                Text("오늘 휴무예요")
                    .font(.title.bold())
                    .foregroundColor(.red)
            } else if hasClosedMart {
                Text("일부만 휴무예요")
                    .font(.title2.bold())
                    .foregroundColor(.orange)
                Text(todayClosedMarts.map { $0.type.displayName }.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("오늘 영업해요")
                    .font(.title.bold())
                    .foregroundColor(.green)
            }
        }
    }

    private func todayStatusAccessibilityLabel(hasNoSelection: Bool, allClosed: Bool, hasClosedMart: Bool, todayClosedMarts: [MetaMartsClosedDays]) -> String {
        if hasNoSelection {
            return String(localized: "매장이 선택되지 않았습니다. 설정에서 매장을 선택해주세요.", defaultValue: "No mart selected. Please choose one in settings.")
        }
        if allClosed {
            return String(localized: "오늘 선택한 모든 매장이 휴무입니다.", defaultValue: "All selected marts are closed today.")
        }
        if hasClosedMart {
            let names = todayClosedMarts.map { $0.type.displayName }.joined(separator: ", ")
            return String(format: String(localized: "오늘 일부 매장만 휴무입니다. %@ 휴무.", defaultValue: "Some marts closed today: %@."), names)
        }
        return String(localized: "오늘 선택한 모든 매장이 영업 중입니다.", defaultValue: "All selected marts are open today.")
    }

    // MARK: - 다음 휴무일

    private var nextClosedDateCard: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

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

        let cardAccessibilityLabel: String
        if let days = daysUntil, let closedDate = nextClosedDate {
            let header = String(localized: "다음 휴무일", defaultValue: "Next closed day")
            let dateText = closedDate.taskDate.formatted(date: .long, time: .omitted)
            cardAccessibilityLabel = "\(header), \(closedDate.type.displayName), \(dateText), \(spokenDaysUntil(days))"
        } else {
            cardAccessibilityLabel = String(localized: "다음 휴무일 정보 없음", defaultValue: "No closed day info")
        }

        return VStack(spacing: 12) {
            HStack {
                Text("다음 휴무일")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            if let days = daysUntil, let closedDate = nextClosedDate {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(operationStatusManager.formatDDay(days))
                            .font(.title.bold())
                            .foregroundColor(Color("Pink"))
                        Text(closedDate.taskDate.formatted(date: .long, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(closedDate.type.displayName)
                            .font(.subheadline.bold())
                            .foregroundColor(closedDate.type.themeColor)
                    }
                    Spacer()
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(cardAccessibilityLabel))
    }

    private let operationStatusManager = OperationStatusManager.shared

    /// VoiceOver 가 D-Day 를 자연스럽게 읽도록 일수를 풀어서 표현한다.
    private func spokenDaysUntil(_ days: Int) -> String {
        if days <= 0 { return String(localized: "오늘 휴무", defaultValue: "Closed today") }
        if days == 1 { return String(localized: "내일 휴무", defaultValue: "Closed tomorrow") }
        return String(format: String(localized: "%lld일 남음", defaultValue: "%lld days left"), days)
    }

    // MARK: - 캘린더 버튼

    private var calendarButton: some View {
        Button(action: {
            isShowingCalendar = true
            ReviewManager.trackMeaningfulAction()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.title2)
                Text("휴무일 캘린더 보기")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("Pink").opacity(0.12))
            .cornerRadius(16)
        }
        .foregroundColor(.primary)
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("휴무일 캘린더 보기"))
        .accessibilityHint(Text("달력에서 휴무일을 확인합니다"))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - 다가오는 휴무일

    private var upcomingClosedDatesCard: some View {
        let groups = upcomingGroups()

        return VStack(spacing: 14) {
            HStack {
                Text("다가오는 휴무일")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            if groups.isEmpty {
                Text("휴무일 정보가 없습니다")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 10) {
                    ForEach(groups, id: \.date) { group in
                        closedDayCard(date: group.date, marts: group.marts, days: group.days)
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

    /// 휴무일을 날짜별로 묶어 한눈에 보이도록 한 카드.
    private func closedDayCard(date: Date, marts: [MetaMartsClosedDays], days: Int) -> some View {
        let calendar = Calendar.current
        let dayNumber = calendar.component(.day, from: date)
        let weekdayIndex = calendar.component(.weekday, from: date) // 1 = 일요일
        let weekdaySymbol = Weekday.symbol(calendarWeekday: weekdayIndex)
        let isSunday = weekdayIndex == 1
        let monthText = "\(calendar.component(.month, from: date))월"
        let isSoon = days <= 3

        return HStack(spacing: 14) {
            // 달력 한 장 블록 (月 / 일 / 요일)
            VStack(spacing: 1) {
                Text(monthText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(dayNumber)")
                    .font(.title.bold())
                    .foregroundColor(isSunday ? .red : .primary)
                Text(weekdaySymbol)
                    .font(.caption2.bold())
                    .foregroundColor(isSunday ? .red : .secondary)
            }
            .frame(width: 60, height: 68)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSoon ? Color("Pink").opacity(0.15) : Color(.systemBackground))
            )

            // 직관적 상대 표현 + 휴무 마트 목록 (색상으로 구분)
            VStack(alignment: .leading, spacing: 6) {
                Text(relativeDayPhrase(date: date, days: days))
                    .font(.subheadline.bold())
                    .foregroundColor(isSoon ? Color("Pink") : .primary)

                ForEach(marts) { mart in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(mart.type.themeColor)
                            .frame(width: 8, height: 8)
                        Text(mart.type.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)

            // D-day 배지
            Text(operationStatusManager.formatDDay(days))
                .font(.subheadline.bold())
                .foregroundColor(isSoon ? .white : Color("Pink"))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(isSoon ? Color("Pink") : Color("Pink").opacity(0.12))
                )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(groupAccessibilityLabel(date: date, marts: marts, days: days)))
    }

    /// 다가오는 휴무일을 날짜별로 묶어 정렬된 배열로 반환한다 (가까운 8일치).
    private func upcomingGroups() -> [(date: Date, marts: [MetaMartsClosedDays], days: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .month, value: 3, to: today) ?? today

        let selectedMartTypes = martSelection.getSelectedMartTypes()
        let upcoming = tasks.filter { task in
            selectedMartTypes.contains(task.type) &&
            task.taskDate >= today &&
            task.taskDate <= endDate
        }
        .sorted { $0.taskDate < $1.taskDate }

        var order: [Date] = []
        var map: [Date: [MetaMartsClosedDays]] = [:]
        for task in upcoming {
            let day = calendar.startOfDay(for: task.taskDate)
            if map[day] == nil { order.append(day) }
            map[day, default: []].append(task)
        }

        return order.prefix(8).map { day in
            let days = calendar.dateComponents([.day], from: today, to: day).day ?? 0
            return (date: day, marts: map[day] ?? [], days: days)
        }
    }

    /// 다가오는 휴무일을 '오늘 / 내일 / 모레 / 이번 주 토요일 / 다음 주 일요일 / 토요일'
    /// 처럼 한눈에 와닿는 표현으로 바꾼다. D-day 숫자보다 직관적이다.
    private func relativeDayPhrase(date: Date, days: Int) -> String {
        if days <= 0 { return String(localized: "오늘", defaultValue: "Today") }
        if days == 1 { return String(localized: "내일", defaultValue: "Tomorrow") }
        if days == 2 { return String(localized: "모레", defaultValue: "In 2 days") }

        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: date) // 1 = 일요일
        let weekday = Weekday.symbol(calendarWeekday: weekdayIndex)
        let weekdayName = String(format: String(localized: "%@요일", defaultValue: "%@"), weekday)

        let today = calendar.startOfDay(for: Date())
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return weekdayName
        }
        let nextWeekStart = thisWeek.end
        let weekAfterNextStart = calendar.date(byAdding: .weekOfYear, value: 1, to: nextWeekStart)

        if date < nextWeekStart {
            return String(format: String(localized: "이번 주 %@", defaultValue: "This %@"), weekdayName)
        }
        if let limit = weekAfterNextStart, date < limit {
            return String(format: String(localized: "다음 주 %@", defaultValue: "Next %@"), weekdayName)
        }
        return weekdayName
    }

    /// 날짜별 카드를 VoiceOver 가 한 문장으로 읽도록 라벨을 구성한다.
    private func groupAccessibilityLabel(date: Date, marts: [MetaMartsClosedDays], days: Int) -> String {
        var parts: [String] = [relativeDayPhrase(date: date, days: days)]
        parts.append(date.formatted(date: .complete, time: .omitted))
        let names = marts.map { $0.type.displayName }.joined(separator: ", ")
        parts.append(String(format: String(localized: "%@ 휴무", defaultValue: "%@ closed"), names))
        return parts.joined(separator: ", ")
    }
}

#Preview {
    ClosedDaysView()
}

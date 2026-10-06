//
//  RestaurantViews.swift
//  DontGoMart
//
//  단골 식당: 메인의 '앞으로 7일' 카드 + 목록 + 링크/스크린샷으로 추가하는 화면.
//

import SwiftUI
import PhotosUI

// MARK: - 메인 카드: 오늘부터 7일, 쉬는 식당이 있는 날에 점

struct RestaurantWeekCard: View {
    @ObservedObject var manager = RestaurantManager.shared
    @State private var isShowingList = false
    @State private var isShowingAdd = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("단골 식당 7일")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if !manager.restaurants.isEmpty {
                    Button("관리") { isShowingList = true }
                        .font(.body.weight(.semibold))
                        .accessibilityHint(Text("단골 식당을 추가하거나 고칩니다"))
                }
            }

            if manager.restaurants.isEmpty {
                emptyState
            } else {
                let days = RestaurantStore.week(from: Date(), restaurants: manager.restaurants)
                RestaurantWeekStrip(days: days)
                closedList(days)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
        .padding(.horizontal)
        .sheet(isPresented: $isShowingList) { RestaurantListView() }
        .sheet(isPresented: $isShowingAdd) { RestaurantEditView() }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("자주 가는 식당의 정기 휴무를 넣어 두면 앞으로 7일 중 쉬는 날을 점으로 알려드려요.")
                .font(.body)
                .foregroundColor(.secondary)
            Button {
                isShowingAdd = true
            } label: {
                Label("식당 추가하기", systemImage: "fork.knife")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color("Pink")))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("네이버지도 공유 링크나 스크린샷으로 추가할 수 있습니다"))
        }
    }

    @ViewBuilder
    private func closedList(_ days: [RestaurantDay]) -> some View {
        let closedDays = days.filter { !$0.closed.isEmpty }
        if closedDays.isEmpty {
            Text("7일 동안 쉬는 단골 식당이 없어요")
                .font(.body)
                .foregroundColor(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(closedDays) { day in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(day.date.formatted(.dateTime.month(.defaultDigits).day().weekday(.abbreviated)))
                            .font(.body.weight(.semibold))
                            .frame(minWidth: 96, alignment: .leading)
                        Text(day.closed.map(\.name).joined(separator: ", "))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

/// 7칸 요일 줄. 쉬는 식당이 있는 날 아래에 식당 색 점.
struct RestaurantWeekStrip: View {
    let days: [RestaurantDay]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                RestaurantDayCell(day: day, isToday: index == 0)
            }
        }
    }
}

struct RestaurantDayCell: View {
    let day: RestaurantDay
    let isToday: Bool

    private var weekdayIndex: Int { Calendar.current.component(.weekday, from: day.date) }

    var body: some View {
        VStack(spacing: 6) {
            Text(Weekday.symbol(calendarWeekday: weekdayIndex))
                .font(.body.weight(.semibold))
                .foregroundColor(weekdayIndex == 1 ? .red : (weekdayIndex == 7 ? .blue : .primary))
            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.body)
                .foregroundColor(isToday ? .white : .primary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(isToday ? Color("Pink") : Color.clear))
            ClosedDots(colors: day.closed.map { Color(hex: $0.color) ?? .orange })
                .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(RestaurantDayCell.accessibilityText(for: day, isToday: isToday)))
    }

    static func accessibilityText(for day: RestaurantDay, isToday: Bool) -> String {
        var date = day.date.formatted(.dateTime.month().day().weekday(.wide))
        if isToday { date = String(localized: "오늘", defaultValue: "Today") + ", " + date }
        if day.closed.isEmpty {
            return date + ", " + String(localized: "쉬는 식당 없음", defaultValue: "No restaurant closed")
        }
        let names = day.closed.map(\.name).joined(separator: ", ")
        return date + ", " + String(format: String(localized: "%@ 휴무", defaultValue: "%@ closed"), names)
    }
}

/// 식당 색 점 (최대 3개, 넘치면 3개만).
struct ClosedDots: View {
    let colors: [Color]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(colors.prefix(3).enumerated()), id: \.offset) { _, color in
                Circle().fill(color).frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - 목록

struct RestaurantListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager = RestaurantManager.shared
    @State private var editing: Restaurant?
    @State private var isShowingAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(manager.restaurants) { restaurant in
                        Button {
                            editing = restaurant
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: restaurant.color) ?? .orange)
                                    .frame(width: 12, height: 12)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(restaurant.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(restaurant.patternSummary)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .accessibilityHint(Text("휴무 정보를 고칩니다"))
                    }
                    .onDelete { offsets in
                        offsets.map { manager.restaurants[$0] }.forEach(manager.delete)
                    }
                    .onMove(perform: manager.move)
                } footer: {
                    Text("위젯 '단골 식당 7일' 을 홈 화면에 추가하면 앱을 열지 않아도 보여요.")
                        .font(.body)
                }
            }
            .navigationTitle("단골 식당")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("완료") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("식당 추가하기"))
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $isShowingAdd) { RestaurantEditView() }
            .sheet(item: $editing) { RestaurantEditView(editing: $0) }
        }
    }
}

// MARK: - 추가 / 편집

struct RestaurantEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = RestaurantManager.shared

    private let editing: Restaurant?
    @State private var name: String
    @State private var address: String
    @State private var patterns: [ClosurePattern]
    @State private var placeURL: String?
    @State private var color: Color

    @State private var pastedText = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var isImporting = false
    @State private var importMessage: String?
    @State private var importSucceeded = false
    @State private var isShowingPatternEditor = false

    init(editing: Restaurant? = nil) {
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _address = State(initialValue: editing?.address ?? "")
        _patterns = State(initialValue: editing?.patterns ?? [])
        _placeURL = State(initialValue: editing?.placeURL)
        _color = State(initialValue: Color(hex: editing?.color ?? RestaurantManager.shared.nextColor) ?? .orange)
    }

    var body: some View {
        NavigationStack {
            Form {
                if editing == nil {
                    importSection
                }

                Section("식당 정보") {
                    TextField("식당 이름", text: $name)
                        .font(.body)
                    TextField("주소 (선택)", text: $address)
                        .font(.body)
                    ColorPicker("점 색상", selection: $color)
                        .font(.body)
                }

                Section("정기 휴무") {
                    if patterns.isEmpty {
                        Text("휴무 요일을 추가해주세요")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    ForEach(patterns) { pattern in
                        Text(pattern.displayText)
                            .font(.body)
                    }
                    .onDelete { patterns.remove(atOffsets: $0) }

                    Button {
                        isShowingPatternEditor = true
                    } label: {
                        Label("휴무 요일 직접 추가", systemImage: "plus.circle.fill")
                            .font(.body)
                    }
                }

                if editing != nil {
                    Section {
                        if let placeURL, let url = URL(string: placeURL) {
                            Link(destination: url) {
                                Label("지도에서 열기", systemImage: "map")
                                    .font(.body)
                            }
                        }
                        Button(role: .destructive) {
                            if let editing { manager.delete(editing) }
                            dismiss()
                        } label: {
                            Text("식당 삭제")
                                .font(.body)
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? Text("식당 추가") : Text("식당 편집"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? LocalizedStringKey("추가") : LocalizedStringKey("저장"), action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || patterns.isEmpty)
                }
            }
            .sheet(isPresented: $isShowingPatternEditor) {
                PatternEditorView { patterns.append($0) }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { await importPhoto(item) }
            }
        }
    }

    // MARK: 가져오기

    private var importSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("지도 앱에서 식당을 '공유 → 복사' 한 뒤 붙여넣거나, 식당 정보 화면 스크린샷을 고르세요.")
                    .font(.body)
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    PasteButton(payloadType: String.self) { strings in
                        guard let text = strings.first else { return }
                        Task { @MainActor in
                            pastedText = text
                            await importText(text)
                        }
                    }
                    .buttonBorderShape(.capsule)
                    .labelStyle(.titleAndIcon)

                    PhotosPicker(selection: $photoItem, matching: .screenshots) {
                        Label("스크린샷", systemImage: "photo")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .accessibilityHint(Text("사진에서 휴무 문구를 기기 안에서 읽어옵니다"))
                }

                TextField("또는 공유 링크·문구를 여기에 붙여넣기", text: $pastedText, axis: .vertical)
                    .font(.body)
                    .lineLimit(1...4)
                    .onSubmit { Task { await importText(pastedText) } }
                if !pastedText.isEmpty && !isImporting {
                    Button("이 내용으로 가져오기") {
                        Task { await importText(pastedText) }
                    }
                    .font(.body.weight(.semibold))
                }

                if isImporting {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("휴무 정보를 찾는 중…")
                            .font(.body)
                    }
                } else if let importMessage {
                    Label(importMessage, systemImage: importSucceeded ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .font(.body)
                        .foregroundColor(importSucceeded ? .green : .orange)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("빠르게 가져오기")
        }
    }

    @MainActor
    private func importText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isImporting = true
        let result = await RestaurantImporter.importShared(text: trimmed)
        apply(result)
        isImporting = false
    }

    @MainActor
    private func importPhoto(_ item: PhotosPickerItem) async {
        isImporting = true
        defer {
            isImporting = false
            photoItem = nil
        }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            importSucceeded = false
            importMessage = String(localized: "사진을 불러오지 못했어요", defaultValue: "Couldn't load the photo")
            return
        }
        apply(await RestaurantImporter.importScreenshot(image))
    }

    @MainActor
    private func apply(_ result: RestaurantImportResult) {
        if name.isEmpty { name = result.name }
        if address.isEmpty { address = result.address }
        if placeURL == nil { placeURL = result.placeURL }

        if !result.patterns.isEmpty {
            patterns = result.patterns
            importSucceeded = true
            let found = result.evidence ?? result.patterns.map(\.displayText).joined(separator: ", ")
            importMessage = String(format: String(localized: "'%@' 을 찾았어요. 맞는지 확인하고 추가하세요.",
                                                  defaultValue: "Found \"%@\". Check it and tap Add."), found)
        } else if result.isOpenEveryDay {
            importSucceeded = false
            importMessage = String(localized: "연중무휴로 나와 있어요. 쉬는 날이 없는 식당이에요.",
                                   defaultValue: "Listed as open every day — no regular closed day.")
        } else {
            importSucceeded = false
            importMessage = result.name.isEmpty
                ? String(localized: "휴무 정보를 찾지 못했어요. 아래에서 직접 골라주세요.",
                         defaultValue: "Couldn't find closing info. Please pick the days below.")
                : String(localized: "이름은 가져왔지만 휴무 정보가 없어요. 영업시간 화면을 스크린샷으로 고르거나 직접 골라주세요.",
                         defaultValue: "Got the name but no closing info. Try a screenshot of the hours, or pick the days below.")
        }
        UIAccessibility.post(notification: .announcement, argument: importMessage)
    }

    private func save() {
        var restaurant = editing ?? Restaurant(name: name, patterns: patterns)
        restaurant.name = name.trimmingCharacters(in: .whitespaces)
        restaurant.address = address
        restaurant.patterns = patterns
        restaurant.placeURL = placeURL
        restaurant.color = color.toHex() ?? manager.nextColor
        manager.upsert(restaurant)
        dismiss()
    }
}

#Preview {
    RestaurantWeekCard()
}

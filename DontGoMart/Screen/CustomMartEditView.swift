//
//  CustomMartEditView.swift
//  DontGoMart
//
//  Created by Claude on 1/20/25.
//

import SwiftUI

struct CustomMartEditView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var customMartManager = CustomMartManager.shared

    let editingMart: CustomMart?
    @State private var martName: String = ""
    @State private var patterns: [ClosurePattern] = []
    @State private var selectedColor: Color = .red
    @State private var showingPatternEditor = false

    init(editingMart: CustomMart? = nil) {
        self.editingMart = editingMart

        if let mart = editingMart {
            _martName = State(initialValue: mart.name)
            _patterns = State(initialValue: mart.patterns)
            _selectedColor = State(initialValue: Color(hex: mart.color) ?? .red)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("마트 정보")) {
                    TextField("마트 이름 (예: 홈플러스 강남점)", text: $martName)

                    ColorPicker("마트 색상", selection: $selectedColor)
                }

                Section(header: Text("휴무 패턴")) {
                    if patterns.isEmpty {
                        Text("패턴을 추가해주세요")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(patterns) { pattern in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pattern.displayText)
                                        .font(.subheadline)
                                }
                                Spacer()
                                Button(action: {
                                    patterns.removeAll { $0.id == pattern.id }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button(action: {
                        showingPatternEditor = true
                    }) {
                        Label("패턴 추가", systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    Button(action: saveMart) {
                        Text(editingMart == nil ? "추가" : "저장")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .disabled(martName.isEmpty || patterns.isEmpty)
                }
            }
            .navigationTitle(editingMart == nil ? "커스텀 마트 추가" : "커스텀 마트 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPatternEditor) {
                PatternEditorView { newPattern in
                    patterns.append(newPattern)
                }
            }
        }
    }

    private func saveMart() {
        let colorHex = selectedColor.toHex() ?? "#FF6B6B"

        if let existing = editingMart {
            let updated = CustomMart(
                id: existing.id,
                name: martName,
                patterns: patterns,
                color: colorHex,
                isEnabled: existing.isEnabled
            )
            customMartManager.updateCustomMart(updated)
        } else {
            let newMart = CustomMart(
                name: martName,
                patterns: patterns,
                color: colorHex
            )
            customMartManager.addCustomMart(newMart)
        }

        dismiss()
    }
}

// MARK: - Pattern Editor View (7x5 Grid)

struct PatternEditorView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (ClosurePattern) -> Void

    // 선택된 셀들: (주차, 요일) 조합
    @State private var selectedCells: Set<GridCell> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 안내 텍스트
                Text("휴무일을 선택하세요")
                    .font(.headline)
                    .padding(.top)

                // 7x5 그리드
                PatternGridView(selectedCells: $selectedCells)
                    .padding(.horizontal)

                // 선택된 패턴 미리보기
                if !selectedCells.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("선택된 패턴")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(previewText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                Spacer()

                // 선택 초기화 버튼
                if !selectedCells.isEmpty {
                    Button("선택 초기화") {
                        selectedCells.removeAll()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("패턴 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        savePatterns()
                    }
                    .disabled(selectedCells.isEmpty)
                }
            }
        }
    }

    private var previewText: String {
        // 요일별로 그룹화
        var weekdayGroups: [Weekday: Set<WeekOfMonth>] = [:]

        for cell in selectedCells {
            if weekdayGroups[cell.weekday] == nil {
                weekdayGroups[cell.weekday] = []
            }
            weekdayGroups[cell.weekday]?.insert(cell.week)
        }

        // 정렬된 텍스트 생성
        let sortedWeekdays = weekdayGroups.keys.sorted { $0.rawValue < $1.rawValue }
        var texts: [String] = []

        for weekday in sortedWeekdays {
            if let weeks = weekdayGroups[weekday] {
                let weekText = weeks.sorted { $0.rawValue < $1.rawValue }
                    .map { "\($0.rawValue)" }
                    .joined(separator: ",")
                texts.append("\(weekText)주 \(weekday.displayName)요일")
            }
        }

        return texts.joined(separator: " / ")
    }

    private func savePatterns() {
        // 요일별로 그룹화하여 패턴 생성
        var weekdayGroups: [Weekday: Set<WeekOfMonth>] = [:]

        for cell in selectedCells {
            if weekdayGroups[cell.weekday] == nil {
                weekdayGroups[cell.weekday] = []
            }
            weekdayGroups[cell.weekday]?.insert(cell.week)
        }

        // 첫 번째 패턴만 저장 (하나의 패턴으로 합침)
        // 여러 요일이 선택된 경우 각각 패턴으로 저장
        for (weekday, weeks) in weekdayGroups {
            let pattern = ClosurePattern(weeks: weeks, weekday: weekday)
            onSave(pattern)
        }

        dismiss()
    }
}

// MARK: - Grid Cell Model

struct GridCell: Hashable {
    let week: WeekOfMonth
    let weekday: Weekday
}

// MARK: - Pattern Grid View (7x5)

struct PatternGridView: View {
    @Binding var selectedCells: Set<GridCell>

    private let weekdays = Weekday.allCases
    private let weeks = WeekOfMonth.allCases

    var body: some View {
        VStack(spacing: 8) {
            // 요일 헤더
            HStack(spacing: 4) {
                // 빈 코너
                Text("")
                    .frame(width: 36)

                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(weekdayColor(weekday))
                }
            }

            // 5주차 행들
            ForEach(weeks, id: \.self) { week in
                HStack(spacing: 4) {
                    // 주차 라벨
                    Text("\(week.rawValue)주")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 36)

                    // 요일 버튼들
                    ForEach(weekdays, id: \.self) { weekday in
                        GridCellButton(
                            week: week,
                            weekday: weekday,
                            isSelected: selectedCells.contains(GridCell(week: week, weekday: weekday)),
                            onTap: {
                                toggleCell(week: week, weekday: weekday)
                            }
                        )
                    }
                }
            }
        }
    }

    private func toggleCell(week: WeekOfMonth, weekday: Weekday) {
        let cell = GridCell(week: week, weekday: weekday)
        if selectedCells.contains(cell) {
            selectedCells.remove(cell)
        } else {
            selectedCells.insert(cell)
        }
    }

    private func weekdayColor(_ weekday: Weekday) -> Color {
        switch weekday {
        case .sunday: return .red
        case .saturday: return .blue
        default: return .primary
        }
    }
}

// MARK: - Grid Cell Button

struct GridCellButton: View {
    let week: WeekOfMonth
    let weekday: Weekday
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.pink : Color(.systemGray5))
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CustomMartEditView()
}

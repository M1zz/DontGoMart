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

// MARK: - Pattern Editor View

struct PatternEditorView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (ClosurePattern) -> Void

    @State private var selectedWeeks: Set<WeekOfMonth> = []
    @State private var selectedWeekday: Weekday = .sunday

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("주차 선택 (여러개 가능)")) {
                    ForEach(WeekOfMonth.allCases, id: \.self) { week in
                        Button(action: {
                            if selectedWeeks.contains(week) {
                                selectedWeeks.remove(week)
                            } else {
                                selectedWeeks.insert(week)
                            }
                        }) {
                            HStack {
                                Text(week.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedWeeks.contains(week) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("요일 선택")) {
                    Picker("요일", selection: $selectedWeekday) {
                        ForEach(Weekday.allCases, id: \.self) { weekday in
                            Text(weekday.fullName).tag(weekday)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section {
                    if !selectedWeeks.isEmpty {
                        Text("선택: \(previewText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
                        let pattern = ClosurePattern(
                            weeks: selectedWeeks,
                            weekday: selectedWeekday
                        )
                        onSave(pattern)
                        dismiss()
                    }
                    .disabled(selectedWeeks.isEmpty)
                }
            }
        }
    }

    private var previewText: String {
        let weekText = selectedWeeks.sorted(by: { $0.rawValue < $1.rawValue })
            .map { $0.displayName }
            .joined(separator: ", ")
        return "\(weekText) \(selectedWeekday.displayName)요일"
    }
}

#Preview {
    CustomMartEditView()
}

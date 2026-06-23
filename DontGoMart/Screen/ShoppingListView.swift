//
//  ShoppingListView.swift
//  DontGoMart
//
//  Created by Claude Code
//

import SwiftUI

struct ShoppingListView: View {
    @StateObject private var reminderManager = ShoppingReminderManager.shared
    @State private var newItemText = ""
    @State private var showingPremiumUpgrade = false
    @State private var paywallContext: PaywallContext = .shoppingLimit
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if reminderManager.currentReminder.items.isEmpty {
                emptyStateView
            } else {
                progressView
                itemListView
            }

            if !PremiumManager.isPremium {
                shoppingLimitBanner
            }

            Spacer()

            addItemSection
        }
        .navigationTitle("장보기 목록")
        .sheet(isPresented: $showingPremiumUpgrade) {
            PremiumUpgradeView(context: paywallContext)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        reminderManager.clearCompleted()
                    }) {
                        Label("완료 항목 삭제", systemImage: "checkmark.circle")
                    }
                    .disabled(reminderManager.currentReminder.completedItemsCount == 0)

                    Button(role: .destructive, action: {
                        reminderManager.clearAll()
                    }) {
                        Label("전체 삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("장볼 것을 추가해보세요")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var progressView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("진행률")
                    .font(.headline)
                Spacer()
                Text("\(reminderManager.currentReminder.completedItemsCount) / \(reminderManager.currentReminder.totalItemsCount)")
                    .foregroundColor(.secondary)
            }

            ProgressView(value: reminderManager.currentReminder.progress)
                .tint(Color("Pink"))
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var itemListView: some View {
        List {
            ForEach(reminderManager.currentReminder.items) { item in
                ShoppingItemRow(item: item)
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    let item = reminderManager.currentReminder.items[index]
                    reminderManager.removeItem(item)
                }
            }
        }
        .listStyle(.plain)
    }

    private var addItemSection: some View {
        HStack(spacing: 12) {
            TextField("장볼 것 추가", text: $newItemText)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .onSubmit {
                    addItem()
                }

            Button(action: addItem) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(newItemText.isEmpty ? .gray : Color("Pink"))
            }
            .disabled(newItemText.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
    }

    private var shoppingLimitBanner: some View {
        let currentCount = reminderManager.currentReminder.totalItemsCount
        let maxCount = PremiumManager.freeMaxShoppingItems
        return VStack(spacing: 4) {
            Text("\(currentCount)/\(maxCount)")
                .font(.caption.bold())
                .foregroundColor(currentCount >= maxCount ? .orange : .secondary)
            PremiumBanner(
                feature: String(localized: "무제한_장보기_배너", defaultValue: "Upgrade for unlimited shopping items")
            ) {
                showingPremiumUpgrade = true
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func addItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let currentCount = reminderManager.currentReminder.totalItemsCount
        if !PremiumManager.canAddMoreShoppingItems(currentCount: currentCount) {
            showingPremiumUpgrade = true
            return
        }

        reminderManager.addItem(trimmed)
        newItemText = ""
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingItem
    @StateObject private var reminderManager = ShoppingReminderManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                reminderManager.toggleItem(item)
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isCompleted ? Color("Pink") : .gray)
            }

            Text(item.title)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? .secondary : .primary)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            reminderManager.toggleItem(item)
        }
    }
}

#Preview {
    NavigationStack {
        ShoppingListView()
    }
}

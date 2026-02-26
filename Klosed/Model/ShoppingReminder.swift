//
//  ShoppingReminder.swift
//  Klosed
//
//  Created by Claude Code
//

import Foundation

struct ShoppingItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
    var createdAt: Date = Date()
}

struct ShoppingReminder: Identifiable, Codable {
    var id: UUID = UUID()
    var items: [ShoppingItem] = []
    var createdAt: Date = Date()
    var reminderEnabled: Bool = true

    var completedItemsCount: Int {
        items.filter { $0.isCompleted }.count
    }

    var totalItemsCount: Int {
        items.count
    }

    var progress: Double {
        guard totalItemsCount > 0 else { return 0 }
        return Double(completedItemsCount) / Double(totalItemsCount)
    }
}

class ShoppingReminderManager: ObservableObject {
    static let shared = ShoppingReminderManager()

    @Published var currentReminder: ShoppingReminder = ShoppingReminder()

    private let reminderKey = "shoppingReminder"
    private let userDefaults = UserDefaults(suiteName: Utillity.appGroupId)

    private init() {
        loadReminder()
    }

    func addItem(_ title: String) {
        let newItem = ShoppingItem(title: title)
        currentReminder.items.append(newItem)
        saveReminder()
        print("✅ [ShoppingReminderManager] 장보기 항목 추가: \(title)")
    }

    func toggleItem(_ item: ShoppingItem) {
        if let index = currentReminder.items.firstIndex(where: { $0.id == item.id }) {
            currentReminder.items[index].isCompleted.toggle()
            saveReminder()
        }
    }

    func removeItem(_ item: ShoppingItem) {
        currentReminder.items.removeAll { $0.id == item.id }
        saveReminder()
    }

    func clearCompleted() {
        currentReminder.items.removeAll { $0.isCompleted }
        saveReminder()
    }

    func clearAll() {
        currentReminder.items.removeAll()
        saveReminder()
    }

    private func saveReminder() {
        if let encoded = try? JSONEncoder().encode(currentReminder) {
            userDefaults?.set(encoded, forKey: reminderKey)
        }
    }

    private func loadReminder() {
        if let data = userDefaults?.data(forKey: reminderKey),
           let decoded = try? JSONDecoder().decode(ShoppingReminder.self, from: data) {
            currentReminder = decoded
            print("✅ [ShoppingReminderManager] 장보기 리스트 로드: \(currentReminder.items.count)개")
        }
    }
}

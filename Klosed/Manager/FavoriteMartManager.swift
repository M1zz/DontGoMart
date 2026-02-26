//
//  FavoriteMartManager.swift
//  Klosed
//
//  Created by Claude Code
//

import Foundation
import Combine

class FavoriteMartManager: ObservableObject {
    static let shared = FavoriteMartManager()

    @Published var favoriteStores: [MartStore] = []

    private let favoritesKey = "favoriteStores"
    private let userDefaults = UserDefaults(suiteName: Utillity.appGroupId)

    private init() {
        loadFavorites()
    }

    func addFavorite(_ store: MartStore) {
        if !favoriteStores.contains(where: { $0.id == store.id }) {
            favoriteStores.append(store)
            saveFavorites()
            print("✅ [FavoriteMartManager] 매장 추가: \(store.displayName)")
        }
    }

    func removeFavorite(_ store: MartStore) {
        favoriteStores.removeAll { $0.id == store.id }
        saveFavorites()
        print("✅ [FavoriteMartManager] 매장 제거: \(store.displayName)")
    }

    func isFavorite(_ store: MartStore) -> Bool {
        return favoriteStores.contains(where: { $0.id == store.id })
    }

    func toggleFavorite(_ store: MartStore) {
        if isFavorite(store) {
            removeFavorite(store)
        } else {
            addFavorite(store)
        }
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteStores) {
            userDefaults?.set(encoded, forKey: favoritesKey)
        }
    }

    private func loadFavorites() {
        if let data = userDefaults?.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([MartStore].self, from: data) {
            favoriteStores = decoded
            print("✅ [FavoriteMartManager] 즐겨찾기 \(favoriteStores.count)개 로드")
        }
    }
}

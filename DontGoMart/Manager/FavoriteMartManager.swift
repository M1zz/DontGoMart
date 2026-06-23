//
//  FavoriteMartManager.swift
//  DontGoMart
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
            debugLog("✅ [FavoriteMartManager] 매장 추가: \(store.displayName)")
        }
    }

    func removeFavorite(_ store: MartStore) {
        favoriteStores.removeAll { $0.id == store.id }
        saveFavorites()
        debugLog("✅ [FavoriteMartManager] 매장 제거: \(store.displayName)")
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
        do {
            let encoded = try JSONEncoder().encode(favoriteStores)
            userDefaults?.set(encoded, forKey: favoritesKey)
        } catch {
            debugLog("⚠️ [FavoriteMartManager] save 실패: \(error)")
        }
    }

    private func loadFavorites() {
        guard let data = userDefaults?.data(forKey: favoritesKey) else { return }
        do {
            favoriteStores = try JSONDecoder().decode([MartStore].self, from: data)
            debugLog("✅ [FavoriteMartManager] 즐겨찾기 \(favoriteStores.count)개 로드")
        } catch {
            debugLog("⚠️ [FavoriteMartManager] load 실패: \(error)")
        }
    }
}

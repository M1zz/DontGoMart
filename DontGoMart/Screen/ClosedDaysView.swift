//
//  ClosedDaysView.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/15.
//

import SwiftUI
import StoreKit
import WidgetKit

let primuimAppName = "돈꼬마트 pro"
let appName = "돈꼬마트"
let restorePurchases = "구매복원"
let appGroupId = "group.com.leeo.DontGoMart"

struct ClosedDaysView: View {
    @State var currentDate: Date = Date()
    @StateObject var storeKit = StoreKitManager()
    @AppStorage("isPremium") var isPremium: Bool = false
    @State private var isShowingSettings = false
    @State private var isCostco: Bool = false
    @AppStorage("selectedBranch", store: UserDefaults(suiteName: appGroupId)) var selectedBranch: Int = 0
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                
                
                ClosedDayCalendarView(currentDate: $currentDate,
                                      isCostco: isCostco,
                                      selectedBranch: selectedBranch)
                    .padding(.vertical)
                
                PurchaseItemView()
                Divider()
                Button(restorePurchases, action: {
                    Task {
                        try? await AppStore.sync()
                    }
                })
            }
            .navigationTitle(isPremium ? "돈꼬 " + locationName(forID: selectedBranch) + " pro" : "돈꼬 " + locationName(forID: selectedBranch))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingSettings.toggle()
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onChange(of: selectedBranch) {
            print("selectedBranch: \(selectedBranch)")
            WidgetCenter.shared.reloadAllTimelines()
        }
        .sheet(isPresented: $isShowingSettings ,onDismiss: {
            isCostco = UserDefaults(suiteName: appGroupId)?.bool(forKey: "isNormal") ?? false
            selectedBranch = UserDefaults(suiteName: appGroupId)?.integer(forKey: "selectedBranch") ?? 0
        }) {
            SettingsView(isShowingSettings: $isShowingSettings)
        }
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
        .onChange(of: storeKit.purchasedCourses) { course in
            Task {
                isPurchased = (try? await storeKit.isPurchased(product)) ?? false
            }
        }
    }
}

class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: appGroupId)!
    
    @AppStorage("hasPro", store: userDefaults) var hasPro: Bool = false
}

#Preview {
    ClosedDaysView()
}

//
//  ContentView.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/15.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    @State var currentDate: Date = Date()
    @StateObject var storeKit = StoreKitManager()
    @AppStorage("isPremium") var isPremium: Bool = false
    @State private var isShowingSettings = false
    //@AppStorage("isNormal", store: UserDefaults(suiteName: "group.com.leeo.DontGoMart")) var isCostco: Bool = false
    
    @State private var isCostco: Bool = false
    @State private var selectedLocation: Int = 0
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack(spacing: 20){
                    
                    // Custom Date Picker....
                    CustomDatePicker(currentDate: $currentDate,
                                     isCostco: isCostco,
                                     selectedLocation: selectedLocation)
                }
                .padding(.vertical)
                ForEach(storeKit.storeProducts) {product in
                    HStack {
                        Text(product.displayName)
                        Spacer()
                        Button(action: {
                            // purchase this product
                            Task { try await
                                storeKit.purchase(product)
                                isPremium = true
                            }
                        }) {
                            CourseItem(storeKit: storeKit, product: product)
                        }
                    }
                }
                Divider()
                Button("Restore Purchases", action: {
                    Task {
                        try? await AppStore.sync()
                    }
                })
            }
            .navigationTitle(isPremium ? "Don't go mart day pro" : "Don't go mart day")
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
        .sheet(isPresented: $isShowingSettings ,onDismiss: {
            isCostco = UserDefaults(suiteName: "group.com.leeo.DontGoMart")?.bool(forKey: "isNormal") ?? false
            selectedLocation = UserDefaults(suiteName: "group.com.leeo.DontGoMart")?.integer(forKey: "selectedLocation") ?? 0
        }) {
            SettingsView(isShowingSettings: $isShowingSettings)
        }
    }
}

struct CourseItem: View {
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
    static let userDefaults = UserDefaults(suiteName: "group.com.leeo.DontGoMart")!
    
    @AppStorage("hasPro", store: userDefaults)
    var hasPro: Bool = false
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

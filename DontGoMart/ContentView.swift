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

    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack(spacing: 20){
                    
                    // Custom Date Picker....
                    CustomDatePicker(currentDate: $currentDate)
                }
                .padding(.vertical)
                ForEach(storeKit.storeProducts) {product in
                    HStack {
                        Text(product.displayName)
                        Spacer()
                        Button(action: {
                            // purchase this product
                            Task { try await storeKit.purchase(product)
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
                        //This call displays a system prompt that asks users to authenticate with their App Store credentials.
                        //Call this function only in response to an explicit user action, such as tapping a button.
                        try? await AppStore.sync()
                    }
                })
            }
            .navigationTitle(isPremium ? "Don't go mart day pro" : "Don't go mart day")
        }
        
        // Safe Area View...
//        .safeAreaInset(edge: .bottom) {
//
//            HStack{
//
//                Button {
//
//                } label: {
//                    Text("Add Task")
//                        .fontWeight(.bold)
//                        .padding(.vertical)
//                        .frame(maxWidth: .infinity)
//                        .background(Color("Orange"),in: Capsule())
//                }
//
//                Button {
//
//                } label: {
//                    Text("Add Remainder")
//                        .fontWeight(.bold)
//                        .padding(.vertical)
//                        .frame(maxWidth: .infinity)
//                        .background(Color("Purple"),in: Capsule())
//                }
//            }
//            .padding(.horizontal)
//            .padding(.top,10)
//            .foregroundColor(.white)
//            .background(.ultraThinMaterial)
//        }
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

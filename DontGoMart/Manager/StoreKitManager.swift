//
//  StoreKitManager.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/21.
//

import Foundation
import StoreKit

public enum StoreError: Error {
    case failedVerification
}

/// 과거에 Pro(비소비성 IAP)를 구매한 '후원자' 를 가려낸다.
///
/// 전 기능을 무료로 풀었지만, Apple 은 비소비성 구매 기록을 영구 보관하므로
/// 같은 Apple ID 면 재설치·기기 변경 후에도 후원자 여부를 확인할 수 있다.
/// 기능 잠금이 아니라 감사 표시(후원자 배지)에만 쓴다.
enum SupporterManager {
    /// 후원으로 인정하는 상품 ID (ProductList.plist 의 coffee)
    static let supporterProductIDs: Set<String> = ["com.dontgomart.Coffee"]

    /// 현재 후원자 배지를 표시해야 하는지.
    static var isSupporter: Bool {
        UserDefaults.standard.bool(forKey: AppStorageKeys.isLegacySupporter)
    }

    /// StoreKit 구매 권한(entitlement)을 확인해 후원자 플래그를 갱신한다.
    /// 한 번 후원자로 인정되면 유지한다(환불·오프라인 등으로 인사가 사라지지 않도록 회수하지 않음).
    static func refresh() async {
        var isSupporter = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               supporterProductIDs.contains(transaction.productID) {
                isSupporter = true
            }
        }

        if isSupporter {
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: AppStorageKeys.isLegacySupporter)
            }
        }
    }
}

class StoreKitManager: ObservableObject {
    // if there are multiple product types - create multiple variable for each .consumable, .nonconsumable, .autoRenewable, .nonRenewable.
    @Published var storeProducts: [Product] = []
    @Published var purchasedCourses : [Product] = []
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    //maintain a plist of products
    private let productDict: [String : String]
    init() {
        //check the path for the plist
        if let plistPath = Bundle.main.path(forResource: "ProductList", ofType: "plist"),
           //get the list of products
           let plist = FileManager.default.contents(atPath: plistPath) {
            productDict = (try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String : String]) ?? [:]
        } else {
            productDict = [:]
        }
        
        //Start a transaction listener as close to the app launch as possible so you don't miss any transaction
        updateListenerTask = listenForTransactions()
        
        //create async operation
        Task {
            await requestProducts()
            
            //deliver the products that the customer purchased
            await updateCustomerProductStatus()
        }
    }
    
    //denit transaction listener on exit or app close
    deinit {
        updateListenerTask?.cancel()
    }
    
    //listen for transactions - start this early in the app
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //iterate through any transactions that don't come from a direct call to 'purchase()'
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    debugLog("⚠️ [StoreKit] Transaction.updates verification failed: \(error)")
                }
            }
        }
    }
    
    // request the products in the background
    @MainActor
    func requestProducts() async {
        do {
            //using the Product static method products to retrieve the list of products
            storeProducts = try await Product.products(for: productDict.values)
        } catch {
            debugLog("⚠️ [StoreKit] requestProducts failed: \(error)")
        }
    }
    
    
    //Generics - check the verificationResults
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //check if JWS passes the StoreKit verification
        switch result {
        case .unverified:
            //failed verificaiton
            throw StoreError.failedVerification
        case .verified(let signedType):
            //the result is verified, return the unwrapped value
            return signedType
        }
    }
    
    // update the customers products
    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedCourses: [Product] = []
        var hasActiveEntitlement = false

        //iterate through all the user's purchased products
        for await result in Transaction.currentEntitlements {
            do {
                //again check if transaction is verified
                let transaction = try checkVerified(result)

                // 알려진 상품 ID(ProductList.plist)에 해당하는 권한이 있으면 Pro 보유로 간주.
                // storeProducts 로드 실패(네트워크 등) 시에도 권한이 잘못 해제되지 않도록
                // storeProducts 매칭이 아닌 productID 기준으로 판별한다.
                if productDict.values.contains(transaction.productID) {
                    hasActiveEntitlement = true
                }

                // since we only have one type of producttype - .nonconsumables -- check if any storeProducts matches the transaction.productID then add to the purchasedCourses
                if let course = storeProducts.first(where: { $0.id == transaction.productID}) {
                    purchasedCourses.append(course)
                }

            } catch {
                debugLog("⚠️ [StoreKit] currentEntitlements verification failed: \(error)")
            }
        }

        self.purchasedCourses = purchasedCourses
        syncPremiumStatus(hasPurchase: hasActiveEntitlement)
    }

    /// 구매 권한 상태를 isPremium(UserDefaults)에 동기화한다.
    /// 복원/재설치/기기 변경 후에도 Pro 기능이 유지되도록 한다.
    @MainActor
    private func syncPremiumStatus(hasPurchase: Bool) {
        #if DEBUG
        // DEBUG 빌드에서는 개발자용 "Pro 버전 잠금 해제" 토글을 덮어쓰지 않도록,
        // 실제 구매가 있을 때만 켜고 임의로 끄지 않는다.
        if hasPurchase {
            UserDefaults.standard.set(true, forKey: AppStorageKeys.isPremium)
        }
        #else
        // 릴리스: 실제 구매 권한(entitlement)에 정확히 일치시킨다. (복원 시 true, 환불 시 false)
        UserDefaults.standard.set(hasPurchase, forKey: AppStorageKeys.isPremium)
        #endif
    }
    
    // call the product purchase and returns an optional transaction
    func purchase(_ product: Product) async throws -> Transaction? {
        //make a purchase request - optional parameters available
        let result = try await product.purchase()
        
        // check the results
        switch result {
        case .success(let verificationResult):
            //Transaction will be verified for automatically using JWT(jwsRepresentation) - we can check the result
            let transaction = try checkVerified(verificationResult)
            
            //the transaction is verified, deliver the content to the user
            await updateCustomerProductStatus()
            
            //always finish a transaction - performance
            await transaction.finish()
            
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
        
    }
    
    //check if product has already been purchased
    func isPurchased(_ product: Product) async throws -> Bool {
        //as we only have one product type grouping .nonconsumable - we check if it belongs to the purchasedCourses which ran init()
        return purchasedCourses.contains(product)
    }
    
    
}

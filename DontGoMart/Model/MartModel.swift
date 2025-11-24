//
//  MartModel.swift
//  DontGoMart
//
//  Created by 황석현 on 11/18/24.
//

import SwiftUI
import WidgetKit

var tasks: [MetaMartsClosedDays] = []

enum MartType: Hashable {
    case normal(type: LargeMartBranch)  // 대형마트 (지역별)
    case costco(type: CostcoBranch)
    case custom(id: String)  // 커스텀 마트 (UUID string으로 식별)
    case holiday  // 설날/추석 등 공휴일

    var widgetDisplayName: String {
        switch self {
        case .normal(let branch):
            switch branch {
            case .sunday:
                return "마트"
            case .wednesday:
                return "마트"
            case .mixed:
                return "마트"
            case .jeju:
                return "마트"
            }
        case .costco:
            return "코스트코"
        case .custom(let id):
            if let customMart = CustomMartManager.shared.getCustomMart(byId: id) {
                return customMart.name
            }
            return "커스텀 마트"
        case .holiday:
            return "공휴일"
        }
    }

    var notificationStoreName: String {
        switch self {
        case .normal(let branch):
            switch branch {
            case .sunday:
                return "대형마트 (일요일 휴무)"
            case .wednesday:
                return "대형마트 (수요일 휴무)"
            case .mixed:
                return "대형마트 (울산)"
            case .jeju:
                return "대형마트 (제주)"
            }
        case .costco(let branch):
            switch branch {
            case .normal:
                return "코스트코 일반매장"
            case .daegu:
                return "코스트코 대구점"
            case .ilsan:
                return "코스트코 일산점"
            case .ulsan:
                return "코스트코 울산점"
            }
        case .custom(let id):
            if let customMart = CustomMartManager.shared.getCustomMart(byId: id) {
                return customMart.name
            }
            return "커스텀 마트"
        case .holiday:
            return "전국 마트 공휴일"
        }
    }
}

enum LargeMartBranch: Hashable, Codable, CaseIterable {
    case sunday      // 일요일 휴무 (전국 대부분)
    case wednesday   // 수요일 휴무 (경기 일부 지역, 청주)
    case mixed       // 혼합 (울산: 2번째 수요일 + 4번째 일요일)
    case jeju        // 제주 (2번째 금요일 + 4번째 토요일)

    var regionName: String {
        switch self {
        case .sunday:
            return "전국 대부분 지역"
        case .wednesday:
            return "경기 일부/청주"
        case .mixed:
            return "울산"
        case .jeju:
            return "제주"
        }
    }
}

enum CostcoBranch: Hashable, Codable, CaseIterable {
    case normal
    case daegu
    case ilsan
    case ulsan
    
    var storeName: String {
        switch self {
        case .normal:
            return "일반매장 - 양평점, 대전점, 양재점, \n상봉점, 부산점, 광명점, \n천안점, 의정부점, 공세점, \n송도점, 세종점, 하남점, \n김해점, 고척점"
        case .daegu:
            return "대구점, 대구혁신점"
        case .ilsan:
            return "일산점"
        case .ulsan:
            return "울산점"
        }
    }
    
    // AppStorage 때문에 Int로 일단 만들어 놓음
    var branchID: Int {
        switch self {
        case .normal:
            return 1
        case .daegu:
            return 2
        case .ilsan:
            return 3
        case .ulsan:
            return 4
        }
    }
    
    // branchID 값을 통해 해당 지점의 이름을 반환하는 프로퍼티
    static func branchName(forID id: Int) -> String? {
        switch id {
        case 0:
            return "일반"
        case 1:
            return "대구"
        case 2:
            return "일산"
        case 3:
            return "울산"
        default:
            return nil
        }
    }
}

/// Widget Model

struct MartHoliday: Hashable, Identifiable {
    let id: UUID = UUID()
    let type: MartType
    let month: Int
    let day: Int
}

/// Multi-Mart Selection Helper
class MartSelectionManager: ObservableObject {
    static let shared = MartSelectionManager()

    @Published var selectedMartTypes: Set<String> = []

    private let userDefaults = UserDefaults(suiteName: Utillity.appGroupId)
    private let storageKey = AppStorageKeys.selectedMartTypes

    init() {
        loadSelection()
    }

    func toggleMart(_ martType: MartType) {
        let key = martType.storageKey
        if selectedMartTypes.contains(key) {
            selectedMartTypes.remove(key)
        } else {
            selectedMartTypes.insert(key)
        }
        saveSelection()
    }

    func isSelected(_ martType: MartType) -> Bool {
        return selectedMartTypes.contains(martType.storageKey)
    }

    func getSelectedMartTypes() -> [MartType] {
        return selectedMartTypes.compactMap { key -> MartType? in
            if key.hasPrefix("normal_") {
                let branchString = key.replacingOccurrences(of: "normal_", with: "")
                switch branchString {
                case "sunday":
                    return .normal(type: .sunday)
                case "wednesday":
                    return .normal(type: .wednesday)
                case "mixed":
                    return .normal(type: .mixed)
                case "jeju":
                    return .normal(type: .jeju)
                default:
                    return nil
                }
            } else if key.hasPrefix("costco_") {
                let branchString = key.replacingOccurrences(of: "costco_", with: "")
                switch branchString {
                case "normal":
                    return .costco(type: .normal)
                case "daegu":
                    return .costco(type: .daegu)
                case "ilsan":
                    return .costco(type: .ilsan)
                case "ulsan":
                    return .costco(type: .ulsan)
                default:
                    return nil
                }
            } else if key.hasPrefix("custom_") {
                // 커스텀 마트 처리
                let id = String(key.dropFirst(7)) // "custom_" 제거
                return .custom(id: id)
            } else if key == "holiday" {
                return .holiday
            }
            return nil
        }
    }

    private func saveSelection() {
        let array = Array(selectedMartTypes)
        userDefaults?.set(array, forKey: storageKey)
        objectWillChange.send()
    }

    private func loadSelection() {
        if let array = userDefaults?.array(forKey: storageKey) as? [String] {
            selectedMartTypes = Set(array)
        } else {
            // 기본값: 일요일 휴무 대형마트 선택
            selectedMartTypes = ["normal_sunday"]
            saveSelection()
        }
    }
}

extension MartType {
    var storageKey: String {
        switch self {
        case .normal(let branch):
            switch branch {
            case .sunday:
                return "normal_sunday"
            case .wednesday:
                return "normal_wednesday"
            case .mixed:
                return "normal_mixed"
            case .jeju:
                return "normal_jeju"
            }
        case .costco(let branch):
            switch branch {
            case .normal:
                return "costco_normal"
            case .daegu:
                return "costco_daegu"
            case .ilsan:
                return "costco_ilsan"
            case .ulsan:
                return "costco_ulsan"
            }
        case .custom(let id):
            return "custom_\(id)"
        case .holiday:
            return "holiday"
        }
    }

    var displayName: String {
        switch self {
        case .normal(let branch):
            switch branch {
            case .sunday:
                return "대형마트 (일요일)"
            case .wednesday:
                return "대형마트 (수요일)"
            case .mixed:
                return "대형마트 (울산)"
            case .jeju:
                return "대형마트 (제주)"
            }
        case .costco(let branch):
            switch branch {
            case .normal:
                return "코스트코 일반매장"
            case .daegu:
                return "코스트코 대구점"
            case .ilsan:
                return "코스트코 일산점"
            case .ulsan:
                return "코스트코 울산점"
            }
        case .custom(let id):
            if let customMart = CustomMartManager.shared.getCustomMart(byId: id) {
                return customMart.name
            }
            return "커스텀 마트"
        case .holiday:
            return "전국 마트 공휴일"
        }
    }

    var operatingHours: String {
        switch self {
        case .normal:
            return "10:00 - 23:00"
        case .costco:
            return "10:00 - 20:00"
        case .custom:
            return "매장별 상이"
        case .holiday:
            return "전일 휴무"
        }
    }
}

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
    case normal
    case costco(type: CostcoBranch)
    
    var widgetDisplayName : String {
        switch self {
        case .normal :
            return "마트"
        case .costco :
            return "코스트코"
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

// MARK: - MartType Extensions for Notification

extension MartType {
    /// 알림용 매장명 (더 구체적인 매장명)
    var notificationStoreName: String {
        switch self {
        case .normal:
            return "대형마트"
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
        }
    }
}

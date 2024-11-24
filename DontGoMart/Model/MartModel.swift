//
//  MartModel.swift
//  DontGoMart
//
//  Created by 황석현 on 11/18/24.
//

import SwiftUI
import WidgetKit

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
struct DayEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct MartHoliday: Hashable, Identifiable {
    let id: UUID = UUID()
    let month: Int
    let day: Int
    let martType: MartType
}

//enum WidgetMartType: Codable {
//    case normal
//    case costcoNormal
//    case costcoDaegu
//    case costcoIlsan
//    case costcoUlsan
//    
//    var displayName: String {
//        switch self {
//        case .normal: return "마트"
//        case .costcoNormal, .costcoDaegu, .costcoIlsan, .costcoUlsan: return "코스트코"
//        }
//    }
//}

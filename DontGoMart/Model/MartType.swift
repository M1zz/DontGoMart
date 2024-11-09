//
//  MartType.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/17.
//

import SwiftUI

var tasks: [MetaMartsClosedDays] = []

enum MartType: Equatable {
    case normal
    case costco(type: CostcoBranch)
}

enum CostcoBranch: Equatable, Codable, CaseIterable {
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
            return 0
        case .daegu:
            return 1
        case .ilsan:
            return 2
        case .ulsan:
            return 3
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








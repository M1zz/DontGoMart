//
//  MartStore.swift
//  Klosed
//
//  Created by Claude Code
//

import Foundation
import CoreLocation

struct MartStore: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let martType: MartStoreType
    let latitude: Double
    let longitude: Double
    let address: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var displayName: String {
        switch martType {
        case .normalMart:
            return name
        case .costco(let branch):
            return "코스트코 \(branch.displayName)"
        }
    }

    var closingPattern: ClosingPattern {
        switch martType {
        case .normalMart:
            return .secondAndFourth(weekday: .sunday)
        case .costco(let branch):
            return branch.closingPattern
        }
    }
}

enum MartStoreType: Hashable, Codable {
    case normalMart
    case costco(branch: CostcoStoreLocation)
}

enum CostcoStoreLocation: String, Hashable, Codable, CaseIterable {
    case yangpyeong = "양평점"
    case daejeon = "대전점"
    case yangjae = "양재점"
    case sangbong = "상봉점"
    case busan = "부산점"
    case gwangmyeong = "광명점"
    case cheonan = "천안점"
    case uijeongbu = "의정부점"
    case gongseo = "공세점"
    case songdo = "송도점"
    case sejong = "세종점"
    case hanam = "하남점"
    case gimhae = "김해점"
    case gochuk = "고척점"
    case daegu = "대구점"
    case daeguInnovation = "대구혁신점"
    case ilsan = "일산점"
    case ulsan = "울산점"

    var displayName: String {
        return self.rawValue
    }

    var closingPattern: ClosingPattern {
        switch self {
        case .daegu, .daeguInnovation:
            return .secondAndFourth(weekday: .monday)
        case .ilsan:
            return .secondAndFourth(weekday: .wednesday)
        case .ulsan:
            return .custom(days: [
                (ordinal: .second, weekday: .wednesday),
                (ordinal: .fourth, weekday: .sunday)
            ])
        default:
            return .secondAndFourth(weekday: .sunday)
        }
    }
}

enum ClosingPattern {
    case secondAndFourth(weekday: Weekday)
    case custom(days: [(ordinal: Ordinal, weekday: Weekday)])

    enum Weekday: Int {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }

    enum Ordinal: Int {
        case first = 1
        case second = 2
        case third = 3
        case fourth = 4
    }
}

extension MartStore {
    static let allStores: [MartStore] = [
        // 일반 대형마트 (주요 위치만 샘플)
        MartStore(
            id: "normalmart_seoul_gangnam",
            name: "이마트 강남점",
            martType: .normalMart,
            latitude: 37.4979,
            longitude: 127.0276,
            address: "서울특별시 강남구 테헤란로"
        ),
        MartStore(
            id: "normalmart_seoul_gangdong",
            name: "홈플러스 강동점",
            martType: .normalMart,
            latitude: 37.5301,
            longitude: 127.1237,
            address: "서울특별시 강동구"
        ),

        // 코스트코 전 지점
        MartStore(
            id: "costco_yangpyeong",
            name: "코스트코 양평점",
            martType: .costco(branch: .yangpyeong),
            latitude: 37.5262,
            longitude: 127.1197,
            address: "서울특별시 영등포구 양평동5가 34-3"
        ),
        MartStore(
            id: "costco_daejeon",
            name: "코스트코 대전점",
            martType: .costco(branch: .daejeon),
            latitude: 36.3504,
            longitude: 127.3845,
            address: "대전광역시 서구 월평동"
        ),
        MartStore(
            id: "costco_yangjae",
            name: "코스트코 양재점",
            martType: .costco(branch: .yangjae),
            latitude: 37.4701,
            longitude: 127.0365,
            address: "서울특별시 서초구 양재동"
        ),
        MartStore(
            id: "costco_sangbong",
            name: "코스트코 상봉점",
            martType: .costco(branch: .sangbong),
            latitude: 37.5984,
            longitude: 127.0857,
            address: "서울특별시 중랑구 상봉동"
        ),
        MartStore(
            id: "costco_busan",
            name: "코스트코 부산점",
            martType: .costco(branch: .busan),
            latitude: 35.1796,
            longitude: 129.0756,
            address: "부산광역시 해운대구 재송동"
        ),
        MartStore(
            id: "costco_gwangmyeong",
            name: "코스트코 광명점",
            martType: .costco(branch: .gwangmyeong),
            latitude: 37.4788,
            longitude: 126.8644,
            address: "경기도 광명시 일직동"
        ),
        MartStore(
            id: "costco_cheonan",
            name: "코스트코 천안점",
            martType: .costco(branch: .cheonan),
            latitude: 36.8151,
            longitude: 127.1139,
            address: "충청남도 천안시 서북구"
        ),
        MartStore(
            id: "costco_uijeongbu",
            name: "코스트코 의정부점",
            martType: .costco(branch: .uijeongbu),
            latitude: 37.7384,
            longitude: 127.0475,
            address: "경기도 의정부시 의정부동"
        ),
        MartStore(
            id: "costco_gongseo",
            name: "코스트코 공세점",
            martType: .costco(branch: .gongseo),
            latitude: 37.2892,
            longitude: 126.9737,
            address: "경기도 화성시 동탄면"
        ),
        MartStore(
            id: "costco_songdo",
            name: "코스트코 송도점",
            martType: .costco(branch: .songdo),
            latitude: 37.3872,
            longitude: 126.6564,
            address: "인천광역시 연수구 송도동"
        ),
        MartStore(
            id: "costco_sejong",
            name: "코스트코 세종점",
            martType: .costco(branch: .sejong),
            latitude: 36.4800,
            longitude: 127.2890,
            address: "세종특별자치시 조치원읍"
        ),
        MartStore(
            id: "costco_hanam",
            name: "코스트코 하남점",
            martType: .costco(branch: .hanam),
            latitude: 37.5460,
            longitude: 127.2065,
            address: "경기도 하남시 풍산동"
        ),
        MartStore(
            id: "costco_gimhae",
            name: "코스트코 김해점",
            martType: .costco(branch: .gimhae),
            latitude: 35.2285,
            longitude: 128.8897,
            address: "경상남도 김해시 장유면"
        ),
        MartStore(
            id: "costco_gochuk",
            name: "코스트코 고척점",
            martType: .costco(branch: .gochuk),
            latitude: 37.5022,
            longitude: 126.8497,
            address: "서울특별시 구로구 고척동"
        ),
        MartStore(
            id: "costco_daegu",
            name: "코스트코 대구점",
            martType: .costco(branch: .daegu),
            latitude: 35.8714,
            longitude: 128.6014,
            address: "대구광역시 북구 칠성동2가"
        ),
        MartStore(
            id: "costco_daegu_innovation",
            name: "코스트코 대구혁신점",
            martType: .costco(branch: .daeguInnovation),
            latitude: 35.8931,
            longitude: 128.6891,
            address: "대구광역시 동구 혁신도시"
        ),
        MartStore(
            id: "costco_ilsan",
            name: "코스트코 일산점",
            martType: .costco(branch: .ilsan),
            latitude: 37.6584,
            longitude: 126.7689,
            address: "경기도 고양시 일산동구"
        ),
        MartStore(
            id: "costco_ulsan",
            name: "코스트코 울산점",
            martType: .costco(branch: .ulsan),
            latitude: 35.5384,
            longitude: 129.3114,
            address: "울산광역시 남구 삼산동"
        )
    ]
}

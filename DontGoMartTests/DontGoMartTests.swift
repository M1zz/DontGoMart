//
//  DontGoMartTests.swift
//  DontGoMartTests
//
//  Created by 황석현 on 11/18/24.
//

import Foundation
import Testing
@testable import DontGoMart

struct DontGoMartTests {
    
    @Test func checkFunction() {
        let main = DontGoMartApp()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        // 비교할 날짜를 설정
        let expectedDate2023 = dateFormatter.date(from: "2023-01-10 15:00:00") // 23년 1월 2번째 수요일
        let expectedDate2024 = dateFormatter.date(from: "2024-01-09 15:00:00") // 24년 1월 2번째 수요일
        
        let on2024 = main.generateBiweeklyTasks(forYear: 2024, monthRange: 1..<13, weekdays:
                                                    [(Calendar.Weekday.wednesday, Calendar.Ordinal.second, "2번째 수요일"),
                                                     (Calendar.Weekday.wednesday, Calendar.Ordinal.fourth, "4번째 수요일")],
                                                martType: MartType.normal)
        let on2023 = main.generateBiweeklyTasks(forYear: 2023, monthRange: 1..<13, weekdays:
                                                    [(Calendar.Weekday.wednesday, Calendar.Ordinal.second, "2번째 수요일"),
                                                     (Calendar.Weekday.wednesday, Calendar.Ordinal.fourth, "4번째 수요일")],
                                                martType: MartType.costco(type: .normal))
        // 12개월 * (2주차, 4주차) = 24
        print(on2023.count)
        print(on2024.count)
        // 현지시간화 전의 데이터라서 - 하루 하여서 예상값은
        // 2,4번째 수요일 값이면 올바른 로직임
        print(on2023[0].taskDate)
        print(on2023[1].taskDate)
        print(on2024[0].taskDate)
        print(on2024[1].taskDate)
        
        // 결과 비교
        #expect(on2023[0].taskDate == expectedDate2023)
        #expect(on2024[0].taskDate == expectedDate2024)
    }
}

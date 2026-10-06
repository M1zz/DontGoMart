//
//  RestaurantImportTests.swift
//  DontGoMartTests
//
//  단골 식당 가져오기: 공유 텍스트·휴무 문장 해석·7일 판정.
//

import Foundation
import Testing
@testable import DontGoMart

struct RestaurantImportTests {

    private func rules(_ text: String) -> [String] {
        ClosureTextParser.parse(text).map { pattern in
            let weeks = pattern.weeks.map(\.rawValue).sorted().map(String.init).joined(separator: ",")
            return "\(pattern.frequency.rawValue):\(pattern.weekday.rawValue):\(weeks)"
        }.sorted()
    }

    private let everyWeek = "1,2,3,4,5"

    @Test func naverShareText() {
        let text = "[네이버지도]\n청산한우\n경북 경주시 천강로 938 \nhttps://naver.me/FAAxfrI4"
        let result = RestaurantImporter.parseShareText(text)
        #expect(result.name == "청산한우")
        #expect(result.address == "경북 경주시 천강로 938")
        #expect(result.placeURL == "https://naver.me/FAAxfrI4")
    }

    @Test func naverPlaceIDFromLinks() {
        let pin = URL(string: "https://map.naver.com/?app=Y&title=x&pinId=15293270&pinType=site")!
        let entry = URL(string: "https://map.naver.com/p/entry/place/15293270")!
        let mobile = URL(string: "https://m.place.naver.com/restaurant/15293270/home")!
        #expect(RestaurantImporter.placeID(inNaverURL: pin) == "15293270")
        #expect(RestaurantImporter.placeID(inNaverURL: entry) == "15293270")
        #expect(RestaurantImporter.placeID(inNaverURL: mobile) == "15293270")
    }

    @Test func naverPlaceHTML() {
        let html = #"{"name":"청산한우","roadAddress":"경북 경주시 천강로 938","description":"가성비 맛집 월요일에 갔어요 휴무 아님","businessHours":[{"day":"화","description":"정기휴무 (매주 화요일)"}]}"#
        let info = RestaurantImporter.parseNaverPlaceHTML(html)
        #expect(info.name == "청산한우")
        #expect(info.closureTexts == ["정기휴무 (매주 화요일)"])
        #expect(rules(info.closureTexts[0]) == ["weekOfMonth:3:\(everyWeek)"])
    }

    @Test func weeklyPhrases() {
        #expect(rules("정기휴무 (매주 화요일)") == ["weekOfMonth:3:\(everyWeek)"])
        #expect(rules("월, 화요일 휴무") == ["weekOfMonth:2:\(everyWeek)", "weekOfMonth:3:\(everyWeek)"])
        #expect(rules("매주 일요일·월요일 쉽니다") == ["weekOfMonth:1:\(everyWeek)", "weekOfMonth:2:\(everyWeek)"])
    }

    @Test func monthlyOrdinalPhrases() {
        #expect(rules("정기휴무 (매월 둘째, 넷째 주 월요일)") == ["weekOfMonth:2:2,4"])
        #expect(rules("매월 2,4번째 일요일 정기휴일") == ["weekOfMonth:1:2,4"])
        #expect(rules("매월 첫째 주 수요일, 셋째 주 목요일 휴무") == ["weekOfMonth:4:1", "weekOfMonth:5:3"])
    }

    @Test func biweeklyAndUnsupported() {
        #expect(rules("격주 수요일 휴무") == ["biweekly:4:"])
        #expect(rules("매월 마지막 주 일요일 휴무").isEmpty)
        #expect(rules("연중무휴").isEmpty)
        #expect(rules("명절 당일 휴무").isEmpty)
    }

    @Test func screenshotTableLayout() {
        // 지도 앱 영업시간 표를 OCR 하면 요일과 '정기휴무' 가 줄로 나뉘어 나온다.
        let ocr = "청산한우\n영업시간\n화요일\n정기휴무\n수요일\n10:30 - 21:00"
        #expect(rules(ocr) == ["weekOfMonth:3:\(everyWeek)"])
        // 네이버지도 앱처럼 요일을 한 글자로 쓰는 표
        #expect(rules("월 10:30 - 21:00\n화 정기휴무\n수 10:30 - 21:00") == ["weekOfMonth:3:\(everyWeek)"])
        #expect(rules("월\n10:30 - 21:00\n화\n정기휴무") == ["weekOfMonth:3:\(everyWeek)"])
    }

    @Test func weekStripMarksClosedDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let tuesdayClosed = Restaurant(name: "청산한우",
                                       patterns: [ClosurePattern(weeks: Set(WeekOfMonth.allCases), weekday: .tuesday)])
        let secondMonday = Restaurant(name: "국밥집",
                                      patterns: [ClosurePattern(weeks: [.second], weekday: .monday)])
        // 2026-10-06 (화) 부터 7일: 10/6 화 휴무, 10/12 월 = 둘째 월요일 휴무
        let start = calendar.date(from: DateComponents(year: 2026, month: 10, day: 6))!
        let days = RestaurantStore.week(from: start, restaurants: [tuesdayClosed, secondMonday], calendar: calendar)
        #expect(days.count == 7)
        let closed = days.map { $0.closed.map(\.name) }
        #expect(closed == [["청산한우"], [], [], [], [], [], ["국밥집"]])
    }
}

//
//  RestaurantImporter.swift
//  DontGoMart
//
//  단골 식당을 손으로 입력하지 않고 가져오기.
//  1) 지도 앱 공유 텍스트/링크 붙여넣기 → 이름·주소 + (네이버지도면) 플레이스 페이지의 정기휴무
//  2) 스크린샷 → 기기 안에서 글자 인식(Vision) → "매주 화요일 휴무" 같은 문장 해석
//

import Foundation
import UIKit
import Vision

// MARK: - 저장소 (앱 화면용)

final class RestaurantManager: ObservableObject {
    static let shared = RestaurantManager()
    @Published private(set) var restaurants: [Restaurant] = RestaurantStore.load()

    private init() {}

    func upsert(_ restaurant: Restaurant) {
        if let index = restaurants.firstIndex(where: { $0.id == restaurant.id }) {
            restaurants[index] = restaurant
        } else {
            restaurants.append(restaurant)
        }
        RestaurantStore.save(restaurants)
    }

    func delete(_ restaurant: Restaurant) {
        restaurants.removeAll { $0.id == restaurant.id }
        RestaurantStore.save(restaurants)
    }

    func move(from source: IndexSet, to destination: Int) {
        restaurants.move(fromOffsets: source, toOffset: destination)
        RestaurantStore.save(restaurants)
    }

    var nextColor: String {
        Restaurant.palette[restaurants.count % Restaurant.palette.count]
    }
}

// MARK: - 가져오기 결과

struct RestaurantImportResult {
    var name: String = ""
    var address: String = ""
    var placeURL: String?
    var patterns: [ClosurePattern] = []
    /// 근거가 된 원문 ("정기휴무 (매주 화요일)") — 사용자가 맞는지 눈으로 확인하도록 보여준다.
    var evidence: String?
    /// 휴무 없이 매일 영업한다고 확인된 경우
    var isOpenEveryDay = false
}

enum RestaurantImporter {

    // MARK: 공유 텍스트 / 링크

    /// 지도 앱 공유 텍스트(예: "[네이버지도]\n청산한우\n경북 경주시 …\nhttps://naver.me/…")를 해석한다.
    /// 네이버지도 링크면 플레이스 페이지에서 정기휴무까지 읽어 온다.
    static func importShared(text: String) async -> RestaurantImportResult {
        var result = parseShareText(text)

        if let url = result.placeURL.flatMap(URL.init(string:)),
           let placeID = await naverPlaceID(from: url),
           let info = await fetchNaverPlace(id: placeID) {
            if result.name.isEmpty { result.name = info.name }
            if result.address.isEmpty { result.address = info.address }
            if !info.closureTexts.isEmpty {
                let joined = info.closureTexts.joined(separator: "\n")
                result.patterns = ClosureTextParser.parse(joined)
                result.evidence = info.closureTexts.first
                result.isOpenEveryDay = result.patterns.isEmpty && joined.contains("무휴")
            }
        }

        // 링크 없이 휴무 문장을 직접 붙여넣은 경우도 받아 준다.
        if result.patterns.isEmpty {
            let parsed = ClosureTextParser.parse(text)
            if !parsed.isEmpty {
                result.patterns = parsed
                result.evidence = ClosureTextParser.closureLines(in: text).first
            }
        }
        return result
    }

    /// 공유 텍스트에서 이름·주소·링크를 뽑는다.
    static func parseShareText(_ text: String) -> RestaurantImportResult {
        var result = RestaurantImportResult()
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        result.placeURL = detector?.firstMatch(in: text, range: range)?.url?.absoluteString

        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { line in
                !line.isEmpty
                && !line.lowercased().contains("http")
                && !(line.hasPrefix("[") && line.hasSuffix("]"))   // [네이버지도] 같은 머리말
            }
            .map { line -> String in
                // "[카카오맵] 청산한우" 처럼 머리말이 같은 줄에 붙은 형식
                if line.hasPrefix("["), let close = line.firstIndex(of: "]") {
                    return line[line.index(after: close)...].trimmingCharacters(in: .whitespaces)
                }
                return line
            }
            .filter { !ClosureTextParser.looksLikeClosure($0) }

        result.name = lines.first ?? ""
        if lines.count > 1 { result.address = lines[1] }
        return result
    }

    // MARK: 네이버 플레이스

    private static let mobileUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    /// naver.me 단축 링크 / map.naver.com / m.place.naver.com 링크에서 플레이스 ID 를 찾는다.
    static func naverPlaceID(from url: URL) async -> String? {
        if let id = placeID(inNaverURL: url) { return id }
        guard url.host?.contains("naver") == true else { return nil }

        // 단축 링크는 리다이렉트 Location 에 pinId 가 들어 있다. 끝까지 따라가지 않고 한 단계씩 본다.
        var current = url
        for _ in 0..<4 {
            var request = URLRequest(url: current, timeoutInterval: 8)
            request.setValue(mobileUserAgent, forHTTPHeaderField: "User-Agent")
            guard let (_, response) = try? await URLSession.shared.data(for: request, delegate: NoRedirectDelegate.shared),
                  let http = response as? HTTPURLResponse,
                  let location = http.value(forHTTPHeaderField: "Location"),
                  let next = URL(string: location, relativeTo: current)?.absoluteURL else {
                return nil
            }
            if let id = placeID(inNaverURL: next) { return id }
            current = next
        }
        return nil
    }

    static func placeID(inNaverURL url: URL) -> String? {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        for name in ["pinId", "id"] {
            if let value = items.first(where: { $0.name == name })?.value,
               !value.isEmpty, value.allSatisfy(\.isNumber) {
                return value
            }
        }
        // /p/entry/place/123, /restaurant/123/home, /place/123
        let parts = url.pathComponents
        for (index, part) in parts.enumerated()
        where ["place", "restaurant", "cafe", "hairshop", "hospital"].contains(part) && index + 1 < parts.count {
            let candidate = parts[index + 1]
            if candidate.allSatisfy(\.isNumber) { return candidate }
        }
        return nil
    }

    struct NaverPlaceInfo {
        var name: String
        var address: String
        var closureTexts: [String]
    }

    /// 모바일 플레이스 페이지에 실려 오는 영업시간 데이터에서 "정기휴무 (매주 화요일)" 을 찾는다.
    static func fetchNaverPlace(id: String) async -> NaverPlaceInfo? {
        guard let url = URL(string: "https://m.place.naver.com/place/\(id)/home") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue(mobileUserAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("ko-KR,ko;q=0.9", forHTTPHeaderField: "Accept-Language")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let html = String(data: data, encoding: .utf8) else { return nil }
        return parseNaverPlaceHTML(html)
    }

    static func parseNaverPlaceHTML(_ html: String) -> NaverPlaceInfo {
        let descriptions = matches(of: #""description":"((?:[^"\\]|\\.)*)""#, in: html).map(unescapeJSON)

        // 영업시간 항목의 "정기휴무 (…)" 가 가장 정확하다. 없으면 짧은 "… 휴무" 문구만 (리뷰 본문 제외).
        var closure = descriptions.filter { $0.contains("정기휴무") || $0.contains("무휴") }
        if closure.isEmpty {
            closure = descriptions.filter { $0.count <= 40 && $0.contains("휴무") && ClosureTextParser.looksLikeClosure($0) }
        }
        var unique: [String] = []
        for text in closure where !unique.contains(text) { unique.append(text) }

        let name = matches(of: #""name":"((?:[^"\\]|\\.)*)""#, in: html).first.map(unescapeJSON) ?? ""
        let address = matches(of: #""roadAddress":"((?:[^"\\]|\\.)*)""#, in: html).first.map(unescapeJSON) ?? ""
        return NaverPlaceInfo(name: name, address: address, closureTexts: unique)
    }

    private static func matches(of pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            Range(match.range(at: 1), in: text).map { String(text[$0]) }
        }
    }

    private static func unescapeJSON(_ raw: String) -> String {
        (try? JSONDecoder().decode(String.self, from: Data("\"\(raw)\"".utf8))) ?? raw
    }

    private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
        static let shared = NoRedirectDelegate()
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest) async -> URLRequest? {
            nil
        }
    }

    // MARK: 스크린샷 (기기 안 글자 인식)

    /// 지도 앱 스크린샷에서 글자를 읽어 휴무 규칙과 가게 이름 후보를 찾는다. 네트워크를 쓰지 않는다.
    static func importScreenshot(_ image: UIImage) async -> RestaurantImportResult {
        let lines = await recognizeText(in: image)
        var result = RestaurantImportResult()
        let fullText = lines.map(\.text).joined(separator: "\n")
        result.patterns = ClosureTextParser.parse(fullText)
        result.evidence = ClosureTextParser.closureLines(in: fullText).first
        result.isOpenEveryDay = result.patterns.isEmpty && fullText.contains("연중무휴")

        // 가게 이름 후보: 화면 위쪽 절반에서 가장 큰 글씨 (지도 앱 상세 화면의 제목)
        result.name = lines
            .filter { $0.top > 0.4 && $0.text.count >= 2 && !$0.text.contains(":")
                && !ClosureTextParser.looksLikeClosure($0.text) }
            .max { $0.height < $1.height }?
            .text ?? ""
        return result
    }

    struct RecognizedLine {
        let text: String
        let height: CGFloat   // 정규화 좌표 (0~1)
        let top: CGFloat      // 정규화 좌표, 1 = 화면 맨 위
    }

    static func recognizeText(in image: UIImage) async -> [RecognizedLine] {
        guard let cgImage = image.cgImage else { return [] }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        return await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ko-KR", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
            guard (try? handler.perform([request])) != nil else { return [] }
            let lines = (request.results ?? []).compactMap { observation -> RecognizedLine? in
                guard let text = observation.topCandidates(1).first?.string else { return nil }
                return RecognizedLine(text: text,
                                      height: observation.boundingBox.height,
                                      top: observation.boundingBox.maxY)
            }
            // 위 → 아래 순서로
            return lines.sorted { $0.top > $1.top }
        }.value
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// MARK: - 휴무 문장 해석

/// "정기휴무 (매주 화요일)", "매월 둘째·넷째 주 월요일 휴무", "2,4번째 일요일 정기휴일",
/// "격주 수요일 휴무", "월, 화요일 휴무" 같은 한국어 문장을 ClosurePattern 으로 바꾼다.
enum ClosureTextParser {

    private static let closureKeywords = ["휴무", "휴일", "쉽니다", "쉬어요", "휴점", "정기휴", "쉼"]

    static func looksLikeClosure(_ line: String) -> Bool {
        closureKeywords.contains { line.contains($0) } && line.range(of: "[일월화수목금토]요일", options: .regularExpression) != nil
    }

    /// 휴무를 말하는 줄만 골라낸다 (공휴일·명절 안내는 요일이 없어 자연히 빠진다).
    static func closureLines(in text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter(looksLikeClosure)
    }

    static func parse(_ text: String, today: Date = Date(), calendar: Calendar = .current) -> [ClosurePattern] {
        let all = text.components(separatedBy: .newlines).map(normalizeWeekdayToken)
        var lines = all.filter(looksLikeClosure)

        // 스크린샷 영업시간 표는 요일과 '정기휴무' 가 다른 줄로 읽히기도 한다 ("화요일" / "정기휴무").
        // 요일 없는 휴무 줄은 바로 앞(없으면 바로 뒤) 요일 줄과 짝지어 본다. 시간이 적힌 줄은 영업일이라 제외.
        let weekdayRegex = "[일월화수목금토]요일"
        for (index, line) in all.enumerated()
        where closureKeywords.contains(where: line.contains) && line.range(of: weekdayRegex, options: .regularExpression) == nil {
            let neighbors = [index - 1, index + 1].filter { all.indices.contains($0) }.map { all[$0] }
            if let partner = neighbors.first(where: {
                $0.range(of: weekdayRegex, options: .regularExpression) != nil && !$0.contains(":")
            }) {
                lines.append(partner + " " + line)
            }
        }

        var result: [ClosurePattern] = []
        for line in lines {
            for pattern in parseLine(line, today: today, calendar: calendar)
            where !result.contains(where: { $0.sameRule(as: pattern) }) {
                result.append(pattern)
            }
        }
        return result
    }

    /// 줄 맨 앞 요일 한 글자("화 정기휴무", "화")를 "화요일" 로 바꿔 같은 규칙으로 읽게 한다.
    private static func normalizeWeekdayToken(_ raw: String) -> String {
        let line = raw.trimmingCharacters(in: .whitespaces)
        guard let first = line.first, weekdayChars[first] != nil else { return line }
        let rest = line.dropFirst()
        if rest.isEmpty || rest.first == " " || rest.first == "(" {
            return "\(first)요일" + rest
        }
        return line
    }

    private static let weekdayChars: [Character: Weekday] = [
        "일": .sunday, "월": .monday, "화": .tuesday, "수": .wednesday,
        "목": .thursday, "금": .friday, "토": .saturday
    ]

    private static let ordinalWords: [(String, Int)] = [
        ("첫", 1), ("둘", 2), ("두", 2), ("셋", 3), ("세", 3), ("넷", 4), ("네", 4), ("다섯", 5)
    ]

    static func parseLine(_ line: String, today: Date = Date(), calendar: Calendar = .current) -> [ClosurePattern] {
        // "월, 화요일" / "월·화요일" / "월요일, 화요일" 를 모두 잡도록 요일 덩어리 단위로 찾는다.
        let groupRegex = try! NSRegularExpression(
            pattern: "([일월화수목금토](?:요일)?(?:\\s*[,·/및와과]\\s*[일월화수목금토](?:요일)?)*)\\s*요일")
        let ns = line as NSString
        let groups = groupRegex.matches(in: line, range: NSRange(location: 0, length: ns.length))

        var patterns: [ClosurePattern] = []
        var previousEnd = 0
        var lastWeeks: Set<WeekOfMonth>?
        let isBiweekly = line.contains("격주")

        for group in groups {
            let groupText = ns.substring(with: group.range(at: 1)).replacingOccurrences(of: "요일", with: "")
            let weekdays = groupText.compactMap { weekdayChars[$0] }
            guard !weekdays.isEmpty else { continue }

            // 이 요일 앞(이전 요일 덩어리 이후)의 주차 표현
            let before = ns.substring(with: NSRange(location: previousEnd, length: group.range.location - previousEnd))
            previousEnd = group.range.location + group.range.length

            // "마지막 주" 는 주차로 표현할 수 없어 틀리게 넣느니 건너뛰고 직접 고르게 한다.
            if before.contains("마지막") {
                lastWeeks = nil
                continue
            }

            var weeks = ordinals(in: before)
            if weeks.isEmpty, !before.contains("매주"), let inherited = lastWeeks {
                weeks = inherited   // "둘째 주 월요일, 화요일" → 화요일도 둘째 주
            }
            lastWeeks = weeks.isEmpty ? nil : weeks

            for weekday in weekdays {
                if isBiweekly && weeks.isEmpty {
                    patterns.append(ClosurePattern(weekday: weekday, frequency: .biweekly,
                                                   anchorDate: nextDate(of: weekday, from: today, calendar: calendar)))
                } else {
                    let set = weeks.isEmpty ? Set(WeekOfMonth.allCases) : weeks
                    patterns.append(ClosurePattern(weeks: set, weekday: weekday, frequency: .weekOfMonth))
                }
            }
        }
        return patterns
    }

    /// "2,4번째" "2·4주" "둘째, 넷째 주" "첫번째" "1주차" → 주차 집합
    static func ordinals(in text: String) -> Set<WeekOfMonth> {
        var result = Set<WeekOfMonth>()

        // 숫자형: 숫자 목록 뒤에 번째/째/주 가 붙은 경우만 (날짜·시간 숫자 오인 방지)
        let numberRegex = try! NSRegularExpression(pattern: "([1-5](?:\\s*[,·/및]\\s*[1-5])*)\\s*(?:번째|째|주차|주)")
        let ns = text as NSString
        for match in numberRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            for ch in ns.substring(with: match.range(at: 1)) {
                if let n = ch.wholeNumberValue, let week = WeekOfMonth(rawValue: n) { result.insert(week) }
            }
        }

        // 한글형: 첫째 / 둘째 / 두번째 / 넷째 …
        let wordRegex = try! NSRegularExpression(pattern: "(첫|둘|두|셋|세|넷|네|다섯)\\s*(?:번)?\\s*째")
        for match in wordRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let word = ns.substring(with: match.range(at: 1))
            if let n = ordinalWords.first(where: { $0.0 == word })?.1, let week = WeekOfMonth(rawValue: n) {
                result.insert(week)
            }
        }
        return result
    }

    /// 격주 기준일: 정보가 없으니 오늘 이후 가장 가까운 그 요일로 두고, 화면에서 확인·수정하게 한다.
    private static func nextDate(of weekday: Weekday, from today: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: today)
        let current = calendar.component(.weekday, from: start)
        let diff = (weekday.rawValue - current + 7) % 7
        return calendar.date(byAdding: .day, value: diff, to: start) ?? start
    }
}

extension ClosurePattern {
    /// id 를 빼고 같은 규칙인지 (중복 제거용)
    func sameRule(as other: ClosurePattern) -> Bool {
        frequency == other.frequency && weekday == other.weekday && weeks == other.weeks
            && anchorDate == other.anchorDate
    }
}

//
//  ShareCardView.swift
//  DontGoMart
//
//  공유용 휴무 알림 카드. 받는 사람이 한눈에 계획을 세울 수 있도록
//  주인공 휴무일 + 2주 달력 + 다가오는 휴무 + 장보기 팁을 담는다.
//  홈 화면에 위젯을 올려 둔 모습처럼 보이게 그린다 — 배경화면 위 흰 위젯 타일들.
//  인스타 규격(게시물 4:5, 스토리 9:16)으로 이미지·동영상 모두 만든다.
//

import SwiftUI
import UIKit

// MARK: - 공유 카드 데이터

struct ShareCardPayload {
    /// "오늘" / "내일" / "이번 주 일요일" 같은 상대 표현
    let phrase: String
    /// "7월 13일 일요일" 같은 날짜 표기
    let dateText: String
    /// 휴무 마트 이름 + 테마색
    let marts: [(name: String, color: Color)]
    let isToday: Bool
    /// 주인공 휴무일 — 달력 배지에 실제 월·일을 찍는다
    var heroDate: Date = Date()
    /// 이번 주 첫날부터 14칸
    var calendarDays: [ShareDay] = []
    /// 주인공 다음으로 다가오는 휴무 (최대 3)
    var upcoming: [ShareUpcoming] = []
    /// "장보기는 토요일까지 끝내세요" 같은 한 줄
    var tip: String?
}

struct ShareDay {
    let date: Date
    let closedColors: [Color]
    let isToday: Bool
    let isPast: Bool
}

struct ShareUpcoming {
    let phrase: String
    let dateText: String
    let marts: [(name: String, color: Color)]
}

/// 인스타그램 규격. 렌더링은 포인트 크기 × 3 (1080px 폭).
enum ShareFormat: String, CaseIterable, Identifiable {
    case post    // 4:5 피드 게시물 · 메신저
    case story   // 9:16 스토리 · 릴스

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .post:  return CGSize(width: 360, height: 450)
        case .story: return CGSize(width: 360, height: 640)
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .post:  return "게시물 4:5"
        case .story: return "스토리 9:16"
        }
    }
}

// MARK: - 카드 뷰 (렌더링 대상)

/// 다크모드와 무관하게 항상 같은 모습이 되도록 색을 고정한다.
/// progress(0~1)는 동영상용 등장 애니메이션 진행도 — 이미지는 1.
struct ShareCardView: View {
    let payload: ShareCardPayload
    var format: ShareFormat = .post
    var progress: Double = 1

    private static let ink = Color(red: 0.15, green: 0.12, blue: 0.14)
    private static let closedRed = Color(red: 0.93, green: 0.22, blue: 0.30)
    private static let gradient = LinearGradient(
        colors: [Color(red: 1.00, green: 0.42, blue: 0.58), Color(red: 0.98, green: 0.29, blue: 0.42)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    private var isStory: Bool { format == .story }

    /// iOS 홈 화면 위젯과 비슷한 모서리 곡률
    private static let widgetRadius: CGFloat = 22

    /// 주인공 휴무일까지 남은 날 (0 = 오늘)
    private var daysUntilHero: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return max(0, calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: payload.heroDate)).day ?? 0)
    }

    /// 위젯 속 가장 큰 글씨. 오늘·내일은 'D-0' 보다 말로 쓰는 게 바로 읽힌다.
    private var headline: String {
        switch daysUntilHero {
        case 0: return String(localized: "오늘 휴무", defaultValue: "Closed today")
        case 1: return String(localized: "내일 휴무", defaultValue: "Closed tomorrow")
        default: return "D-\(daysUntilHero)"
        }
    }

    /// 위젯 머리글. 오늘·내일은 큰 글씨가 이미 말하므로 일반 문구로 바꿔 같은 말이 두 번 나오지 않게 한다.
    private var caption: String {
        daysUntilHero <= 1
            ? String(localized: "마트 휴무 알림", defaultValue: "Store closure alert")
            : String(format: String(localized: "%@ 휴무", defaultValue: "%@ closed"), payload.phrase)
    }

    var body: some View {
        // 인스타 규격은 높이가 정해져 있다. 마트가 많거나 다가오는 휴무가 길면 넘쳐서 위아래가 잘리므로
        // 들어갈 때까지 다가오는 휴무 → 마트 칩 순으로 덜어낸 판을 차례로 시도한다.
        VStack(spacing: 0) {
            ViewThatFits(in: .vertical) {
                let chips = isStory ? 4 : 3
                ForEach(Array(layoutSteps(maxChips: chips).enumerated()), id: \.offset) { _, step in
                    content(upcomingLimit: step.upcoming, chipLimit: step.chips, showsTip: step.tip)
                }
            }

            Spacer(minLength: 8)

            Text("앱스토어에서 '돈꼬마트' 검색")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
                .reveal(progress, from: 0.85, length: 0.1)
        }
        .padding(.horizontal, 20)
        .padding(.top, isStory ? 26 : 16)
        .padding(.bottom, isStory ? 22 : 12)
        .frame(width: format.size.width, height: format.size.height)
        .background(wallpaper)
        .environment(\.colorScheme, .light)
    }

    /// 덜어낼 순서: 다가오는 휴무 3 → 0, 장보기 팁, 마지막으로 마트 칩을 하나씩.
    /// 오늘 쉬는 마트가 무엇인지가 카드의 핵심이라 마트 칩을 가장 늦게 줄인다.
    private func layoutSteps(maxChips: Int) -> [(upcoming: Int, chips: Int, tip: Bool)] {
        let upcoming = isStory ? min(3, payload.upcoming.count) : 0
        var steps = (0...upcoming).reversed().map { (upcoming: $0, chips: maxChips, tip: true) }
        steps.append((upcoming: 0, chips: maxChips, tip: false))
        steps += (1..<maxChips).reversed().map { (upcoming: 0, chips: $0, tip: false) }
        return steps
    }

    private func content(upcomingLimit: Int, chipLimit: Int, showsTip: Bool) -> some View {
        VStack(spacing: isStory ? 12 : 10) {
            brandRow
                .reveal(progress, from: 0, length: 0.12)

            hero(chipLimit: chipLimit)
                .reveal(progress, from: 0.06, length: 0.16)

            calendarPanel

            if upcomingLimit > 0 {
                upcomingPanel(limit: upcomingLimit)
            }

            if showsTip, let tip = payload.tip {
                tipPill(tip)
                    .reveal(progress, from: isStory ? 0.78 : 0.7, length: 0.12)
            }
        }
    }

    /// 홈 화면 배경화면 — 앱 색 그라데이션에 은은한 빛 번짐
    private var wallpaper: some View {
        ZStack {
            Self.gradient
            Circle()
                .fill(.white.opacity(0.20))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: -120, y: -format.size.height * 0.32)
            Circle()
                .fill(Color(red: 1.0, green: 0.85, blue: 0.55).opacity(0.28))
                .frame(width: 240, height: 240)
                .blur(radius: 70)
                .offset(x: 130, y: format.size.height * 0.36)
        }
    }

    private var brandRow: some View {
        HStack(spacing: 6) {
            Text("🛒")
            Text("돈꼬마트")
                .font(.system(size: 17, weight: .bold))
            Spacer()
            Text("마트 휴무 알림")
                .font(.system(size: 14, weight: .semibold))
                .opacity(0.9)
        }
        .foregroundColor(.white)
    }

    /// 주인공 휴무일 위젯 — 날짜 배지 + 큰 D-day + 날짜, 아래에 휴무 마트
    private func hero(chipLimit: Int) -> some View {
        VStack(alignment: .leading, spacing: isStory ? 10 : 8) {
            HStack(spacing: 12) {
                dateBadge
                VStack(alignment: .leading, spacing: 1) {
                    Text(caption)
                        .font(.system(size: isStory ? 15 : 13, weight: .semibold))
                        .foregroundColor(.gray)
                    Text(headline)
                        .font(.system(size: isStory ? 36 : 32, weight: .heavy))
                        .foregroundColor(Self.closedRed)
                    Text(payload.dateText)
                        .font(.system(size: isStory ? 16 : 14, weight: .semibold))
                        .foregroundColor(Self.ink)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                Spacer(minLength: 0)
            }

            // 휴무 마트 칩
            FlowChips(marts: visibleMarts(limit: chipLimit))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(isStory ? 14 : 12)
        .widgetTile(radius: Self.widgetRadius)
    }

    /// 칸이 모자라면 마지막 칸을 '외 N곳' 으로 바꿔, 빠진 마트가 있다는 걸 알린다
    private func visibleMarts(limit: Int) -> [(name: String, color: Color)] {
        guard payload.marts.count > limit, limit > 0 else { return Array(payload.marts.prefix(limit)) }
        let shown = Array(payload.marts.prefix(limit - 1))
        let more = String(format: String(localized: "외 %lld곳", defaultValue: "+%lld more"), payload.marts.count - shown.count)
        return shown + [(name: more, color: Color.gray.opacity(0.6))]
    }

    /// 실제 휴무 날짜가 찍힌 달력 한 장 (이모지 📅 는 늘 'JUL 17' 이라 헷갈린다)
    private var dateBadge: some View {
        let width: CGFloat = isStory ? 58 : 52
        return VStack(spacing: 0) {
            Text(payload.heroDate.formatted(.dateTime.month(.abbreviated)))
                .font(.system(size: isStory ? 15 : 13, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(Self.closedRed)
            Text("\(Calendar.current.component(.day, from: payload.heroDate))")
                .font(.system(size: isStory ? 30 : 26, weight: .heavy))
                .foregroundColor(Self.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: width, height: width * 1.05)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08), lineWidth: 1))
        .overlay(alignment: .topTrailing) {
            if payload.isToday {
                Text("🚫").font(.system(size: 22)).offset(x: 10, y: -10)
            }
        }
    }

    // MARK: 2주 달력

    private var calendarPanel: some View {
        let days = payload.calendarDays
        return VStack(spacing: 8) {
            HStack {
                Text("2주 휴무 달력")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Self.ink)
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Self.closedRed).frame(width: 9, height: 9)
                    Text("휴무")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            HStack(spacing: 0) {
                ForEach(Array(days.prefix(7).enumerated()), id: \.offset) { _, day in
                    let weekday = Calendar.current.component(.weekday, from: day.date)
                    Text(Weekday.symbol(calendarWeekday: weekday))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(weekday == 1 ? Self.closedRed : (weekday == 7 ? .blue : .gray))
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<(days.count + 6) / 7, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(row * 7..<min(days.count, row * 7 + 7), id: \.self) { index in
                        dayCell(days[index])
                            .stamp(progress, from: 0.18 + Double(index) * 0.03, length: 0.08,
                                   isClosed: !days[index].closedColors.isEmpty)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(14)
        .widgetTile(radius: Self.widgetRadius)
        .reveal(progress, from: 0.12, length: 0.12)
    }

    private func dayCell(_ day: ShareDay) -> some View {
        let closed = !day.closedColors.isEmpty
        let size: CGFloat = isStory ? 36 : 32
        return VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.system(size: 16, weight: closed || day.isToday ? .heavy : .medium))
                .foregroundColor(closed ? .white : Self.ink)
                .frame(width: size, height: size)
                .background(Circle().fill(closed ? Self.closedRed : .clear))
                .overlay(Circle().stroke(Self.closedRed, lineWidth: day.isToday && !closed ? 2 : 0))
            // 여러 마트가 겹치면 마트 색 점으로 구분
            HStack(spacing: 2) {
                ForEach(Array(day.closedColors.prefix(3).enumerated()), id: \.offset) { _, color in
                    Circle().fill(color).frame(width: 5, height: 5)
                }
            }
            .frame(height: 5)
        }
        .opacity(day.isPast ? 0.35 : 1)
    }

    // MARK: 다가오는 휴무 (스토리)

    private func upcomingPanel(limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("다가오는 휴무")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Self.ink)
                .reveal(progress, from: 0.6, length: 0.08)
            ForEach(Array(payload.upcoming.prefix(limit).enumerated()), id: \.offset) { index, item in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.phrase)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Self.closedRed)
                            // 영어 'in 3 weeks, Sun' 처럼 긴 표현이 잘리지 않게
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(item.dateText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 118, alignment: .leading)
                    Text(item.marts.map(\.name).joined(separator: ", "))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Self.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                }
                .reveal(progress, from: 0.64 + Double(index) * 0.05, length: 0.08)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetTile(radius: Self.widgetRadius)
    }

    private func tipPill(_ tip: String) -> some View {
        HStack(spacing: 8) {
            Text("💡")
            Text(tip)
                .font(.system(size: isStory ? 17 : 15, weight: .bold))
                .foregroundColor(Self.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(Color(red: 1.0, green: 0.93, blue: 0.62)))
    }
}

/// 마트 칩 — 가로로 놓고 넘치면 두 줄.
private struct FlowChips: View {
    let marts: [(name: String, color: Color)]

    var body: some View {
        let rows = marts.count > 2 ? [Array(marts.prefix(2)), Array(marts.dropFirst(2))] : [marts]
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, mart in
                        HStack(spacing: 5) {
                            Circle().fill(mart.color).frame(width: 8, height: 8)
                            Text(mart.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.24))
                                .lineLimit(1)
                                // 위젯 타일 안이라 폭이 좁다 — 잘리기 전에 글자를 줄인다
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(red: 0.96, green: 0.94, blue: 0.95)))
                    }
                }
            }
        }
    }
}

// MARK: - 등장 애니메이션 (progress 기반 — 동영상 프레임마다 결정적으로 그린다)

private func easedReveal(_ progress: Double, from start: Double, length: Double) -> Double {
    let t = min(max((progress - start) / length, 0), 1)
    return 1 - pow(1 - t, 3)   // easeOutCubic
}

private extension View {
    /// 홈 화면 위젯처럼 보이는 흰 타일 (연속 곡률 모서리 + 떠 있는 그림자)
    func widgetTile(radius: CGFloat) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.16), radius: 12, y: 5)
        )
    }

    func reveal(_ progress: Double, from start: Double, length: Double) -> some View {
        let r = easedReveal(progress, from: start, length: length)
        return self.opacity(r).offset(y: (1 - r) * 18)
    }

    /// 휴무일은 도장 찍히듯 크게 → 제자리로.
    func stamp(_ progress: Double, from start: Double, length: Double, isClosed: Bool) -> some View {
        let r = easedReveal(progress, from: start, length: length)
        return self.opacity(r).scaleEffect(isClosed ? 1 + (1 - r) * 0.8 : 0.85 + r * 0.15)
    }
}

// MARK: - 공유 시트

/// 카드 미리보기 + 형식(게시물/스토리) + 매체(사진/동영상) 선택 + 공유.
struct ShareCardSheet: View {
    let payload: ShareCardPayload
    /// 이미지와 함께 보낼 메시지 (메신저용, 이미지를 못 싣는 앱에서의 폴백 겸용)
    let messageText: String

    enum Medium: String, CaseIterable, Identifiable {
        case photo, video
        var id: String { rawValue }
        var title: LocalizedStringKey { self == .photo ? "사진" : "동영상" }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var format: ShareFormat = .story
    @State private var medium: Medium = .photo
    @State private var images: [ShareFormat: UIImage] = [:]
    @State private var videos: [ShareFormat: URL] = [:]
    @State private var videoProgress: Double?
    @State private var errorMessage: String?
    @State private var showsInstagramUnavailableAlert = false

    /// Meta 개발자 콘솔에서 발급받은 앱 ID. 채우면 '인스타 스토리' 버튼이 스토리 편집기로 바로 연다.
    /// 비어 있으면 공유 시트(인스타 게시물·스토리·릴스·DM 포함)로 보낸다.
    private static let metaAppID = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("형식", selection: $format) {
                    ForEach(ShareFormat.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker("매체", selection: $medium) {
                    ForEach(Medium.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                preview
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                actions
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .navigationTitle("휴무 소식 알리기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .task(id: "\(format.rawValue)-\(medium.rawValue)") { await prepareMedia() }
            .alert("인스타그램이 없어요", isPresented: $showsInstagramUnavailableAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("인스타그램 앱이 설치되어 있어야 스토리로 공유할 수 있어요.")
            }
        }
    }

    // MARK: 미리보기 — 동영상 모드는 실제 영상과 같은 애니메이션을 반복 재생

    private var preview: some View {
        GeometryReader { proxy in
            let size = format.size
            let scale = min(proxy.size.width / size.width, proxy.size.height / size.height)
            Group {
                if medium == .video && !reduceMotion {
                    TimelineView(.animation) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: ShareVideoExporter.duration)
                        ShareCardView(payload: payload, format: format,
                                      progress: min(t / ShareVideoExporter.animationDuration, 1))
                    }
                } else {
                    ShareCardView(payload: payload, format: format)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary))
    }

    private var accessibilitySummary: String {
        var parts = [String(format: String(localized: "휴무 알림 카드. %1$@ %2$@, %3$@ 휴무",
                                           defaultValue: "Closing card. %1$@ %2$@, %3$@ closed"),
                            payload.phrase, payload.dateText, payload.marts.map(\.name).joined(separator: ", "))]
        if let tip = payload.tip { parts.append(tip) }
        return parts.joined(separator: ". ")
    }

    // MARK: 공유 버튼

    @ViewBuilder
    private var actions: some View {
        if let videoProgress, medium == .video, videos[format] == nil {
            ProgressView(value: videoProgress) {
                Text("동영상을 만들고 있어요")
                    .font(.body)
            }
            .padding(.vertical, 14)
        } else if let item = shareItem {
            VStack(spacing: 10) {
                shareLink(item)

                Button {
                    shareToInstagram(item)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.circle.fill")
                        Text("인스타그램에 올리기")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Self.instagramGradient))
                    .foregroundColor(.white)
                }
                .accessibilityHint(Text(Self.metaAppID.isEmpty || format != .story
                    ? "공유 목록에서 인스타그램을 고르면 게시물·스토리·릴스로 올릴 수 있습니다"
                    : "인스타그램 스토리 편집기로 바로 엽니다"))
            }
        } else if let errorMessage {
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.vertical, 14)
        } else {
            ProgressView("카드를 준비하고 있어요")
                .padding(.vertical, 14)
        }
    }

    private enum ShareItem {
        case image(UIImage)
        case video(URL)

        var activityItem: Any {
            switch self {
            case .image(let image): return image
            case .video(let url): return url
            }
        }
    }

    private var shareItem: ShareItem? {
        switch medium {
        case .photo: return images[format].map(ShareItem.image)
        case .video: return videos[format].map(ShareItem.video)
        }
    }

    @ViewBuilder
    private func shareLink(_ item: ShareItem) -> some View {
        let label = HStack(spacing: 8) {
            Image(systemName: "paperplane.fill")
            Text("공유하기")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Capsule().fill(Color("Pink")))
        .foregroundColor(.white)

        switch item {
        case .image(let image):
            ShareLink(item: Image(uiImage: image), message: Text(messageText),
                      preview: SharePreview("마트 휴무일 알림", image: Image(uiImage: image))) { label }
                .accessibilityHint(Text("휴무 알림 카드 이미지를 공유합니다"))
        case .video(let url):
            ShareLink(item: url, message: Text(messageText),
                      preview: SharePreview("마트 휴무일 알림", image: Image(uiImage: images[format] ?? UIImage()))) { label }
                .accessibilityHint(Text("휴무 알림 동영상을 공유합니다"))
        }
    }

    private static let instagramGradient = LinearGradient(
        colors: [Color(red: 0.51, green: 0.23, blue: 0.71),
                 Color(red: 0.91, green: 0.26, blue: 0.42),
                 Color(red: 0.99, green: 0.55, blue: 0.24)],
        startPoint: .leading, endPoint: .trailing)

    // MARK: 만들기

    @MainActor
    private func prepareMedia() async {
        if images[format] == nil {
            images[format] = ShareVideoExporter.renderImage(payload: payload, format: format, progress: 1)
        }
        guard medium == .video, videos[format] == nil else { return }
        videoProgress = 0
        errorMessage = nil
        do {
            let url = try await ShareVideoExporter.export(payload: payload, format: format) { value in
                videoProgress = value
            }
            videos[format] = url
        } catch is CancellationError {
            // 형식을 바꾸는 중 — 새 작업이 이어받는다
        } catch {
            errorMessage = String(localized: "동영상을 만들지 못했어요. 사진으로 공유해 주세요.",
                                  defaultValue: "Couldn't make the video. Please share the photo instead.")
        }
        videoProgress = nil
    }

    // MARK: 인스타그램

    /// 스토리 형식 + Meta 앱 ID 가 있으면 스토리 편집기로 바로, 아니면 매체만 담은 공유 시트를 띄운다
    /// (공유 시트의 인스타그램 항목에서 게시물·스토리·릴스·DM 을 고를 수 있다. 메시지 텍스트를 빼야
    /// 인스타그램이 사진/영상으로 받는다).
    private func shareToInstagram(_ item: ShareItem) {
        if format == .story, !Self.metaAppID.isEmpty {
            shareToInstagramStories(item)
            return
        }
        let controller = UIActivityViewController(activityItems: [item.activityItem], applicationActivities: nil)
        guard let presenter = UIApplication.shared.topViewController else { return }
        controller.popoverPresentationController?.sourceView = presenter.view
        presenter.present(controller, animated: true)
    }

    private func shareToInstagramStories(_ item: ShareItem) {
        guard let url = URL(string: "instagram-stories://share?source_application=\(Self.metaAppID)"),
              UIApplication.shared.canOpenURL(url) else {
            showsInstagramUnavailableAlert = true
            return
        }
        var entry: [String: Any] = [:]
        switch item {
        case .image(let image):
            guard let data = image.pngData() else { return }
            entry["com.instagram.sharedSticker.backgroundImage"] = data
        case .video(let videoURL):
            guard let data = try? Data(contentsOf: videoURL) else { return }
            entry["com.instagram.sharedSticker.backgroundVideo"] = data
        }
        // 인스타그램이 페이스트보드에서 읽어가는 방식이라 만료 시간을 짧게 둔다
        UIPasteboard.general.setItems([entry], options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
        UIApplication.shared.open(url)
    }
}

private extension UIApplication {
    var topViewController: UIViewController? {
        let scene = connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
    let days = (0..<14).map { offset -> ShareDay in
        let date = calendar.date(byAdding: .day, value: offset, to: start)!
        let isSunday = calendar.component(.weekday, from: date) == 1
        return ShareDay(date: date, closedColors: isSunday ? [.blue] : [], isToday: date == today, isPast: date < today)
    }
    return ShareCardSheet(
        payload: ShareCardPayload(
            phrase: "이번 주 일요일",
            dateText: "7월 13일 일요일",
            marts: [("대형마트 (일요일)", .blue), ("코스트코 일반매장", .red)],
            isToday: false,
            calendarDays: days,
            upcoming: [ShareUpcoming(phrase: "2주 뒤 일요일", dateText: "7월 27일 (일)", marts: [("대형마트 (일요일)", .blue)])],
            tip: "장보기는 이번 주 토요일까지 끝내세요"
        ),
        messageText: "미리보기 메시지"
    )
}

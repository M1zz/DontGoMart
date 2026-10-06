//
//  AnnouncementManager.swift
//  DontGoMart
//
//  원격 공지 — 앱 업데이트 없이 메인 화면 위에 배너를 띄운다.
//  (명절 휴무 규칙 변경, 서비스 점검, 새 기능 안내 같은 '모두에게 한 번 알릴 일')
//
//  어디서 읽나: 피드백·사용통계·킬스위치와 같은 CloudKit 허브(iCloud.com.Ysoup.FeedbackHub)
//  공개 DB 의 레코드 하나. 새 인프라 없이 대시보드에서 레코드만 고치면 된다.
//
//  설계 원칙 (LeeoRemoteFlags 와 같다)
//   · 읽기는 네트워크를 타지 않는다 — 마지막으로 받은 공지를 캐시해 두고 즉시 보여 준다.
//   · 조회가 실패하면 캐시를 건드리지 않는다. 레코드가 없으면(unknownItem) 공지가 없는 것.
//   · 사용자가 닫은 공지는 다시 띄우지 않는다. 내용을 바꿔 다시 알리려면 noticeID 를 바꾼다.
//
//  CloudKit Dashboard 준비 → docs/ANNOUNCEMENT.md
//   레코드 타입 `Announcement` / recordName `notice_com.leeo.DontGoMart`
//   필드: noticeID(String) · message(String) · title(String, 선택) · linkURL(String, 선택)
//         isActive(Int64, 1=노출) · endsAt(Date/Time, 선택) · style(String, "info"|"warning", 선택)
//

import Foundation
import CloudKit

struct Announcement: Codable, Equatable {
    enum Style: String, Codable {
        case info, warning
        /// 앱이 스스로 띄우는 '곧 휴무' 배너 (원격 공지에서는 쓰지 않는다)
        case closingSoon
    }

    let id: String
    let title: String?
    let message: String
    let linkURL: URL?
    let style: Style
    let endsAt: Date?

    /// 지금 보여 줄 만한가 — 기한이 지났으면 숨긴다 (기한을 넘겨 켜 둔 공지가 남지 않게).
    func isLive(now: Date = Date()) -> Bool {
        if let endsAt, endsAt <= now { return false }
        return !message.isEmpty
    }
}

@MainActor
final class AnnouncementManager: ObservableObject {
    static let shared = AnnouncementManager()

    static let recordType = "Announcement"

    private static let cacheKey = "announcement.cached"
    private static let dismissedKey = "announcement.dismissedIDs"
    private static let lastFetchKey = "announcement.lastFetchAt"

    /// 앱을 자주 오가도 CloudKit 을 매번 두드리지 않도록 하는 최소 간격.
    /// 공지는 급할 수 있어 킬스위치(6시간)보다 짧게 둔다.
    private let refreshInterval: TimeInterval = 30 * 60

    private let defaults: UserDefaults
    private var isFetching = false

    /// 지금 배너로 띄울 공지. 없으면 nil.
    @Published private(set) var current: Announcement?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        current = visible(from: cached)
    }

    // MARK: - 읽기 (네트워크 없음)

    private var cached: Announcement? {
        guard let data = defaults.data(forKey: Self.cacheKey) else { return nil }
        return try? JSONDecoder().decode(Announcement.self, from: data)
    }

    private var dismissedIDs: Set<String> {
        Set(defaults.stringArray(forKey: Self.dismissedKey) ?? [])
    }

    private func visible(from announcement: Announcement?) -> Announcement? {
        guard let announcement, announcement.isLive(), !dismissedIDs.contains(announcement.id) else {
            return nil
        }
        return announcement
    }

    // MARK: - 닫기

    func dismiss(_ announcement: Announcement) {
        // 닫은 기록은 최근 것만 남긴다 (공지가 쌓여도 저장소가 커지지 않게)
        var ids = defaults.stringArray(forKey: Self.dismissedKey) ?? []
        ids.removeAll { $0 == announcement.id }
        ids.append(announcement.id)
        defaults.set(Array(ids.suffix(20)), forKey: Self.dismissedKey)
        current = nil
    }

    // MARK: - 갱신

    /// 앱 진입·포그라운드 복귀 때 호출. 간격 안이면 캐시만 다시 본다.
    func refresh(force: Bool = false) async {
        let last = defaults.double(forKey: Self.lastFetchKey)
        guard force || Date().timeIntervalSince1970 - last > refreshInterval, !isFetching else {
            current = visible(from: cached)
            return
        }
        isFetching = true
        defer { isFetching = false }

        let config = DontGoMartSpec.feedback
        let database = CKContainer(identifier: config.containerIdentifier).publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "notice_\(config.appIdentifier ?? "default")")

        do {
            let record = try await database.record(for: recordID)
            store(Self.announcement(from: record))
        } catch let error as CKError where error.code == .unknownItem {
            // 레코드가 없다 = 공지가 없다. 내려간 공지가 계속 떠 있지 않도록 캐시를 비운다.
            store(nil)
        } catch {
            // 네트워크·권한 실패 — 마지막으로 알던 공지를 그대로 둔다.
            debugLog("📢 공지 조회 실패: \(error.localizedDescription)")
            current = visible(from: cached)
        }
    }

    private func store(_ announcement: Announcement?) {
        if let announcement, let data = try? JSONEncoder().encode(announcement) {
            defaults.set(data, forKey: Self.cacheKey)
        } else {
            defaults.removeObject(forKey: Self.cacheKey)
        }
        defaults.set(Date().timeIntervalSince1970, forKey: Self.lastFetchKey)
        current = visible(from: announcement)
    }

    /// 레코드 → 공지. isActive 가 0 이거나 본문이 비면 '공지 없음'.
    /// noticeID 를 비워 두면 레코드 수정 시각을 ID 로 쓴다 (고칠 때마다 다시 뜬다).
    nonisolated static func announcement(from record: CKRecord) -> Announcement? {
        let isActive = (record["isActive"] as? Int64 ?? 1) != 0
        let message = (record["message"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard isActive, !message.isEmpty else { return nil }

        let explicitID = (record["noticeID"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackID = record.modificationDate.map { String(Int($0.timeIntervalSince1970)) } ?? message
        let title = (record["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        return Announcement(
            id: (explicitID?.isEmpty == false ? explicitID : nil) ?? fallbackID,
            title: (title?.isEmpty == false) ? title : nil,
            message: message,
            // 웹 링크만 연다 — 오타나 엉뚱한 스킴이 앱을 다른 곳으로 보내지 않게
            linkURL: (record["linkURL"] as? String)
                .flatMap { URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .flatMap { ["http", "https"].contains($0.scheme?.lowercased() ?? "") ? $0 : nil },
            style: (record["style"] as? String).flatMap(Announcement.Style.init(rawValue:)) ?? .info,
            endsAt: record["endsAt"] as? Date
        )
    }
}

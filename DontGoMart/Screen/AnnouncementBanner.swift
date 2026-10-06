//
//  AnnouncementBanner.swift
//  DontGoMart
//
//  메인 화면 위에 붙는 배너. 두 가지가 같은 모양으로 뜬다.
//   · 휴무 임박 — 고른 마트가 곧 쉬는 날이면 앱이 스스로 알린다 (누르면 캘린더)
//   · 원격 공지 — 운영자가 CloudKit 으로 올린 공지 (링크가 있으면 누르면 그 페이지)
//  닫으면 같은 배너는 다시 뜨지 않는다.
//

import SwiftUI

struct AnnouncementBanner: View {
    let announcement: Announcement
    let onDismiss: () -> Void
    /// 배너를 눌렀을 때 할 일. 없으면 공지 링크를 연다(링크도 없으면 누를 수 없다).
    var onTap: (() -> Void)? = nil
    var tapHint: LocalizedStringKey = "공지 내용을 자세히 봅니다"

    @Environment(\.openURL) private var openURL

    private var tint: Color {
        announcement.style == .warning ? .orange : Color("Pink")
    }

    private var symbolName: String {
        switch announcement.style {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .closingSoon: return "calendar.badge.exclamationmark"
        }
    }

    private var isTappable: Bool { onTap != nil || announcement.linkURL != nil }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 링크가 없는 공지는 버튼으로 만들지 않는다 (눌러도 반응 없는 버튼은 혼란스럽다)
            Group {
                if isTappable {
                    Button(action: { if let onTap { onTap() } else { openLink() } }) { content }
                        .buttonStyle(.plain)
                        .accessibilityHint(Text(tapHint))
                } else {
                    content
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(accessibilityText))

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("공지 닫기"))
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .background(
            // 스크롤되는 카드 위에 겹쳐도 글자가 비치지 않게 바탕을 깐다
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbolName)
                .font(.body)
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                if let title = announcement.title {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                }
                Text(announcement.message)
                    .font(.footnote)
                    .foregroundStyle(announcement.title == nil ? .primary : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isTappable {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
                    .accessibilityHidden(true)
            }
        }
        .multilineTextAlignment(.leading)
        .contentShape(Rectangle())
    }

    private var accessibilityText: String {
        // 휴무 임박 배너는 제목이 이미 무엇인지 말하므로 '공지' 를 붙이지 않는다
        let prefix = announcement.style == .closingSoon ? nil : String(localized: "공지", defaultValue: "Notice")
        return [prefix, announcement.title, announcement.message]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private func openLink() {
        guard let url = announcement.linkURL else { return }
        openURL(url)
    }
}

#Preview {
    VStack {
        AnnouncementBanner(
            announcement: Announcement(
                id: "preview",
                title: "추석 연휴 안내",
                message: "일부 지역은 추석 당일 의무휴업일이 바뀌었어요.",
                linkURL: URL(string: "https://m1zz.github.io/DontGoMart/"),
                style: .info,
                endsAt: nil
            ),
            onDismiss: {}
        )
        AnnouncementBanner(
            announcement: Announcement(
                id: "preview2", title: nil,
                message: "서버 점검으로 알림이 늦을 수 있어요.",
                linkURL: nil, style: .warning, endsAt: nil
            ),
            onDismiss: {}
        )
        Spacer()
    }
}

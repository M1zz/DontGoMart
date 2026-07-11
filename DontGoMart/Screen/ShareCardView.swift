//
//  ShareCardView.swift
//  DontGoMart
//
//  공유용 휴무 알림 카드. 밋밋한 텍스트 공유 대신,
//  ImageRenderer 로 이미지화한 카드를 미리보기와 함께 공유한다.
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
}

// MARK: - 카드 뷰 (렌더링 대상)

/// 정사각형에 가까운 공유 카드. 다크모드와 무관하게 항상 같은 모습으로 렌더링되도록
/// 색을 고정한다. 모서리는 투명 픽셀이 생기지 않도록 풀블리드로 채운다.
struct ShareCardView: View {
    let payload: ShareCardPayload

    var body: some View {
        VStack(spacing: 0) {
            // 브랜드 헤더
            HStack(spacing: 6) {
                Text("🛒")
                Text("돈꼬마트")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Spacer(minLength: 14)

            // 본문 카드
            VStack(spacing: 10) {
                Text(payload.isToday ? "🚫" : "📅")
                    .font(.system(size: 52))

                Text("\(payload.phrase) 휴무예요!")
                    .font(.title2.bold())
                    .foregroundColor(Color(red: 0.15, green: 0.12, blue: 0.14))
                    .multilineTextAlignment(.center)

                Text(payload.dateText)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // 휴무 마트 칩
                VStack(spacing: 6) {
                    ForEach(Array(payload.marts.prefix(4).enumerated()), id: \.offset) { _, mart in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(mart.color)
                                .frame(width: 9, height: 9)
                            Text(mart.name)
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.24))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color(red: 0.97, green: 0.94, blue: 0.95)))
                    }
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 22).fill(.white))
            .padding(.horizontal, 20)

            Spacer(minLength: 14)

            // 푸터 태그라인
            Text("마트 가기 전, 돈꼬마트에서 휴무일 확인 ✅")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.95))
                .padding(.bottom, 16)
        }
        .frame(width: 340, height: 380)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.42, blue: 0.58),
                    Color(red: 0.98, green: 0.29, blue: 0.42),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - 공유 시트

/// 카드 미리보기 + 공유 버튼. 시트가 뜨는 순간 카드를 이미지로 렌더링한다.
struct ShareCardSheet: View {
    let payload: ShareCardPayload
    /// 이미지와 함께 보낼 메시지 (이미지를 못 싣는 앱에서의 폴백 겸용)
    let messageText: String

    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer(minLength: 0)

                ShareCardView(payload: payload)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("휴무 알림 카드. \(payload.phrase) \(payload.dateText), \(payload.marts.map(\.name).joined(separator: ", ")) 휴무"))

                Spacer(minLength: 0)

                if let image = renderedImage {
                    ShareLink(
                        item: Image(uiImage: image),
                        message: Text(messageText),
                        preview: SharePreview("마트 휴무일 알림", image: Image(uiImage: image))
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                            Text("휴무 소식 알리기")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color("Pink")))
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .accessibilityHint(Text("휴무 알림 카드 이미지를 공유합니다"))
                } else {
                    ProgressView("카드를 준비하고 있어요")
                        .padding(.vertical, 14)
                }
            }
            .padding(.vertical, 20)
            .navigationTitle("휴무 소식 알리기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .onAppear(perform: renderCard)
        }
    }

    /// 카드를 3배 해상도 이미지로 렌더링한다 (공유 시 선명하게).
    @MainActor
    private func renderCard() {
        guard renderedImage == nil else { return }
        let renderer = ImageRenderer(content: ShareCardView(payload: payload))
        renderer.scale = 3
        renderer.isOpaque = true
        renderedImage = renderer.uiImage
    }
}

#Preview {
    ShareCardSheet(
        payload: ShareCardPayload(
            phrase: "이번 주 일요일",
            dateText: "7월 13일 일요일",
            marts: [("이마트 · 홈플러스", .blue), ("코스트코 일반매장", .red)],
            isToday: false
        ),
        messageText: "미리보기 메시지"
    )
}

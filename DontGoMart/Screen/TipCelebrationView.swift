//
//  TipCelebrationView.swift
//  DontGoMart
//
//  Created by hyunho lee on 7/14/26.
//

import SwiftUI

// MARK: - 부착용 Modifier

/// 팁(소모성 IAP) 구매 성공 시 콘페티 + 전면 감사 카드 연출을 재생하는 오버레이.
///
/// 심사 지적(2.1 — 소모성 구매 후 반응 없음) 대응: 결제가 끝나는 순간
/// '개발자의 감사' 가 화면 전체로 즉시 보이게 한다. 햅틱·VoiceOver 안내는
/// 중복 재생을 피하려고 CoffeeTipStore.celebrate() 가 한 번만 담당한다.
struct TipCelebrationOverlay: ViewModifier {
    @ObservedObject private var tipStore = CoffeeTipStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowing = false
    @State private var hideTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .overlay {
                if isShowing {
                    TipCelebrationView(
                        mode: .purchaseThanks(productID: tipStore.lastTippedProductID),
                        showsConfetti: !reduceMotion,
                        onDismiss: hide
                    )
                    .transition(.opacity)
                }
            }
            .onChange(of: tipStore.celebrationCount) {
                show()
            }
    }

    private func show() {
        hideTask?.cancel()
        withAnimation(.easeIn(duration: 0.2)) {
            isShowing = true
        }
        // 콘페티가 다 떨어질 때까지 보여준 뒤 알아서 닫는다 (탭으로 즉시 닫기 가능)
        hideTask = Task {
            try? await Task.sleep(for: .seconds(4.5))
            guard !Task.isCancelled else { return }
            hide()
        }
    }

    private func hide() {
        hideTask?.cancel()
        withAnimation(.easeOut(duration: 0.35)) {
            isShowing = false
        }
    }
}

extension View {
    /// 팁 구매가 일어날 수 있는 화면의 최상단 뷰에 붙인다.
    func tipCelebrationOverlay() -> some View {
        modifier(TipCelebrationOverlay())
    }
}

// MARK: - 연출 본체 (딤 배경 + 콘페티 + 감사 카드)

struct TipCelebrationView: View {
    enum Mode {
        /// 구매 직후의 감사 연출 — 잠시 보여주고 자동으로 닫힌다
        case purchaseThanks(productID: String?)
        /// 후원자 감사 리마인더(휴무일, 1년에 ~3번) — '기부의 감사함을 잊지 않았다' 는
        /// 축하와 함께 한 번 더 응원할 수 있는 버튼을 담는다
        case supporterReminder
    }

    let mode: Mode
    /// Reduce Motion 이 켜져 있으면 false — 콘페티 없이 감사 카드만 보여준다.
    let showsConfetti: Bool
    let onDismiss: () -> Void
    /// supporterReminder 모드의 '한 번 더 응원하기'. 상품 미로드 등으로 nil 이면 버튼을 숨긴다.
    var onTipAgain: (() -> Void)? = nil

    @State private var cardVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            if showsConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            Group {
                switch mode {
                case .purchaseThanks(let productID):
                    purchaseThanksCard(productID: productID)
                case .supporterReminder:
                    supporterReminderCard
                }
            }
            .scaleEffect(cardVisible ? 1 : 0.6)
            .opacity(cardVisible ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                cardVisible = true
            }
        }
    }

    private func purchaseThanksCard(productID: String?) -> some View {
        VStack(spacing: 14) {
            Text(SupporterManager.emoji(for: productID ?? ""))
                .font(.system(size: 64))
                .accessibilityHidden(true)

            Text("정말 감사합니다!")
                .font(.title2.bold())

            Text("보내주신 응원 덕분에 앱을 계속 만들어갈 수 있어요.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if SupporterManager.tipCount > 0 {
                tipCountBadge
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
        )
        .padding(.horizontal, 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("후원해주셔서 정말 감사합니다. 지금까지 커피 \(SupporterManager.tipCount)잔을 보내주셨습니다."))
        .accessibilityHint(Text("두 번 탭하면 닫힙니다"))
        .accessibilityAddTraits(.isButton)
    }

    private var supporterReminderCard: some View {
        VStack(spacing: 14) {
            Text("💛")
                .font(.system(size: 64))
                .accessibilityHidden(true)

            Text("후원자님, 잊지 않고 있어요!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("오늘도 헛걸음을 막아드렸어요.\n보내주신 기부의 감사함을 늘 기억하고 있습니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            tipCountBadge

            if let onTipAgain {
                Button(action: onTipAgain) {
                    Text("한 번 더 응원하기 ☕️")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.brown))
                        .foregroundColor(.white)
                }
                .padding(.top, 6)
                .accessibilityHint(Text("개발자에게 커피 한 잔 값을 후원합니다"))
            }

            Button(action: onDismiss) {
                Text("고마워요, 다음에 또 만나요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .accessibilityHint(Text("감사 인사를 닫습니다"))
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
        )
        .padding(.horizontal, 40)
    }

    private var tipCountBadge: some View {
        Text("지금까지 받은 응원 ☕️ ×\(SupporterManager.tipCount)")
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.brown.opacity(0.15)))
    }
}

// MARK: - 콘페티

/// 화면 위에서 색종이·이모지가 흩날리며 떨어지는 축하 연출.
/// TimelineView + Canvas 로 그려 뷰 트리 부담 없이 수십 개 조각을 애니메이션한다.
private struct ConfettiView: View {
    private let pieces = ConfettiPiece.makeBatch()
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                for piece in pieces {
                    guard let state = piece.state(at: elapsed, in: size) else { continue }
                    var ctx = context
                    ctx.translateBy(x: state.position.x, y: state.position.y)
                    ctx.rotate(by: .radians(state.rotation))
                    ctx.opacity = state.opacity
                    switch piece.content {
                    case .shape(let color):
                        let rect = CGRect(
                            x: -piece.size / 2, y: -piece.size / 3,
                            width: piece.size, height: piece.size * 0.66
                        )
                        ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
                    case .emoji(let symbol):
                        ctx.draw(Text(symbol).font(.system(size: piece.size)), at: .zero)
                    }
                }
            }
        }
    }
}

private struct ConfettiPiece {
    enum Content {
        case shape(Color)
        case emoji(String)
    }

    let content: Content
    /// 가로 위치 (화면 폭 대비 0...1)
    let relativeX: CGFloat
    /// 떨어지기 시작하는 시각 (초) — 조각마다 어긋나게 해 자연스러운 물결을 만든다
    let delay: Double
    /// 화면 위에서 아래까지 떨어지는 데 걸리는 시간 (초)
    let fallDuration: Double
    let swayAmplitude: CGFloat
    let swayFrequency: Double
    let spinSpeed: Double
    let size: CGFloat

    struct State {
        let position: CGPoint
        let rotation: Double
        let opacity: Double
    }

    /// 경과 시간에 따른 조각의 위치·회전·투명도. 아직 안 나왔거나 다 떨어졌으면 nil.
    func state(at elapsed: TimeInterval, in size: CGSize) -> State? {
        let t = elapsed - delay
        guard t >= 0 else { return nil }
        let progress = t / fallDuration
        guard progress <= 1.0 else { return nil }

        let y = -40 + progress * (size.height + 80)
        let x = relativeX * size.width + sin(t * swayFrequency * 2 * .pi) * swayAmplitude
        // 바닥에 닿기 직전 서서히 사라진다
        let opacity = progress > 0.8 ? max(0, (1.0 - progress) / 0.2) : 1
        return State(
            position: CGPoint(x: x, y: y),
            rotation: t * spinSpeed,
            opacity: opacity
        )
    }

    static func makeBatch(count: Int = 60) -> [ConfettiPiece] {
        let colors: [Color] = [Color("Pink"), .brown, .orange, .yellow, .mint, .purple]
        let emojis = ["🎉", "☕️", "🍰", "🍱", "💛", "✨"]
        return (0..<count).map { index in
            let isEmoji = index % 4 == 0
            return ConfettiPiece(
                content: isEmoji
                    ? .emoji(emojis[index / 4 % emojis.count])
                    : .shape(colors[index % colors.count]),
                relativeX: CGFloat.random(in: 0.02...0.98),
                delay: Double.random(in: 0...0.9),
                fallDuration: Double.random(in: 2.4...3.4),
                swayAmplitude: CGFloat.random(in: 12...40),
                swayFrequency: Double.random(in: 0.4...0.9),
                spinSpeed: Double.random(in: 2...6),
                size: isEmoji ? CGFloat.random(in: 18...26) : CGFloat.random(in: 8...14)
            )
        }
    }
}

#Preview("구매 감사") {
    TipCelebrationView(
        mode: .purchaseThanks(productID: "com.dontgomart.tip.coffee"),
        showsConfetti: true,
        onDismiss: {}
    )
}

#Preview("후원자 리마인더") {
    TipCelebrationView(
        mode: .supporterReminder,
        showsConfetti: true,
        onDismiss: {},
        onTipAgain: {}
    )
}

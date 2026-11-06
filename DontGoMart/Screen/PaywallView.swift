//
//  PaywallView.swift
//  DontGoMart
//
//  돈꼬마트 Plus · Pro 를 파는 한 장. 비교표 → 칸 카드(연 구독 / 평생, 주 · 월은 펼쳐서) → 약관.
//
//  **무료인 것을 먼저 보인다.** 마트 휴무를 확인하는 일은 사지 않아도 그대로 된다.
//  들어온 자리의 칸(Plus 또는 Pro)을 위에 세우고, 들어온 기능의 줄을 짚는다.
//  첫 해 할인(App Store 첫 구독 할인)과 "연 구독 N년치" 한 줄은 `LeeoTermPicker` 가 보인다.
//  App Store 에서 불러온 상품만 단추가 된다. 없는 상품은 자리가 비거나 줄이 서지 않는다.
//

import SwiftUI
import StoreKit
import LeeoKit

struct PaywallView: View {
    /// 어디서 들어왔는가. 그 기능의 칸을 위에 세우고 비교표의 그 줄을 짚는다. nil 이면 Plus 가 위.
    var highlight: PlanFeature?

    @ObservedObject private var plans = PlanManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.purchase) private var purchaseAction
    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var plusTerm: LeeoPlanTerm = .yearly
    @State private var proTerm: LeeoPlanTerm = .yearly
    @State private var loadingProducts = true

    private var tierOrder: [PlanTier] {
        highlight?.tier == .pro ? [.pro, .plus] : [.plus, .pro]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    comparison
                    plansStatus
                    ForEach(tierOrder, id: \.self) { tierCard($0) }
                    if let message = plans.failureMessage, !plans.products.isEmpty {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.body)
                            .foregroundStyle(.orange)
                    }
                    legal
                }
                .padding(20)
            }
            .navigationTitle("요금제")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Label("닫기", systemImage: "xmark") }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(Utillity.restorePurchases) {
                        Task { if await plans.restore() { dismiss() } }
                    }
                    .disabled(plans.isWorking)
                }
            }
            .task {
                LeeoAnalyticsCenter.track(.paywallShown(reason: highlight?.rawValue ?? "settings"))
                await loadPlans()
            }
        }
    }

    // MARK: 머리

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("돈꼬마트 Plus · Pro")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text("헛걸음 없는 장보기, 우리 동네 가게까지. 연 구독이나 평생 중에 고르세요.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: 비교표

    private enum Cell {
        case yes, no, count(Int), unlimited

        var text: String {
            switch self {
            case .yes: "✓"
            case .no: "–"
            case .count(let n): String(format: String(localized: "%lld곳"), n)
            case .unlimited: String(localized: "무제한")
            }
        }

        var spoken: String {
            switch self {
            case .yes: String(localized: "포함")
            case .no: String(localized: "없음")
            default: text
            }
        }

        var isNo: Bool { if case .no = self { return true }; return false }
    }

    private struct Row: Identifiable {
        let title: String
        let cells: [Cell]   // 무료 · Plus · Pro
        var feature: PlanFeature?
        var id: String { title }
    }

    private var rows: [Row] {[
        Row(title: String(localized: "마트 의무휴업일 · 오늘 영업 여부"), cells: [.yes, .yes, .yes]),
        Row(title: String(localized: "달력 · 휴무 알림 · 배너"), cells: [.yes, .yes, .yes]),
        Row(title: String(localized: "나만의 마트"), cells: [.count(PlanLimits.customMarts), .unlimited, .unlimited],
            feature: .moreMarts),
        Row(title: String(localized: "단골 식당 · 7일 휴무 카드"), cells: [.count(PlanLimits.restaurants), .unlimited, .unlimited],
            feature: .moreRestaurants),
        Row(title: String(localized: "공유 카드 (게시물)"), cells: [.yes, .yes, .yes]),
        Row(title: String(localized: "스토리 규격 · 동영상 공유"), cells: [.no, .yes, .yes], feature: .storyAndVideo),
        Row(title: String(localized: "가까운 휴무일 위젯"), cells: [.yes, .yes, .yes]),
        Row(title: String(localized: "추가 홈 위젯 3종"), cells: [.no, .no, .yes], feature: .moreWidgets),
        Row(title: String(localized: "잠금화면 위젯"), cells: [.no, .no, .yes], feature: .lockScreenWidgets),
        Row(title: String(localized: "식당 휴무 자동 가져오기"), cells: [.no, .no, .yes], feature: .restaurantImport),
    ]}

    private let columns = [PlanTier.free, .plus, .pro]

    /// 칸 머리. 표 안에서는 짧게 부른다(무료 · Plus · Pro).
    private func shortName(_ tier: PlanTier) -> String {
        switch tier {
        case .free: PlanTier.free.title
        case .plus: "Plus"
        case .pro:  "Pro"
        }
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !typeSize.isAccessibilitySize {
                HStack(spacing: 4) {
                    Spacer(minLength: 0)
                    ForEach(columns, id: \.self) { tier in
                        Text(verbatim: shortName(tier))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(tier == plans.tier ? Color("Pink") : .primary)
                            .frame(width: cellWidth)
                    }
                }
                .padding(.bottom, 6)
                .accessibilityHidden(true)
            }
            ForEach(rows) { row in
                rowView(row)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background {
                        if row.feature != nil, row.feature == highlight {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color("Pink").opacity(0.12))
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(spoken(row)))
                if row.id != rows.last?.id { Divider() }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
    }

    @ScaledMetric(relativeTo: .body) private var cellWidth: CGFloat = 58

    @ViewBuilder
    private func rowView(_ row: Row) -> some View {
        if typeSize.isAccessibilitySize {
            // 아주 큰 글자에서는 칸을 세로로 풀어 쓴다. 네 칸을 나란히 두면 글자가 꺾여 읽을 수 없다.
            VStack(alignment: .leading, spacing: 4) {
                Text(row.title).font(.body.weight(.semibold))
                ForEach(Array(row.cells.enumerated()), id: \.offset) { index, cell in
                    Text(verbatim: "\(shortName(columns[index]))  \(cell.text)")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 4) {
                Text(row.title)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(Array(row.cells.enumerated()), id: \.offset) { _, cell in
                    Text(cell.text)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(cell.isNo ? Color.secondary : Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: cellWidth)
                }
            }
        }
    }

    private func spoken(_ row: Row) -> String {
        ([row.title] + zip(columns, row.cells).map { "\($0.title) \($1.spoken)" }).joined(separator: ", ")
    }

    // MARK: 칸 카드

    private func tierCard(_ tier: PlanTier) -> some View {
        let highlighted = highlight?.tier == tier && plans.tier < tier
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(tier.title)
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                if plans.tier == tier {
                    Text("지금 쓰는 칸")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color("Pink"))
                }
                Spacer(minLength: 0)
            }
            Text(tier == .plus ? LocalizedStringKey("우리 동네 가게를 모두 챙기기") : LocalizedStringKey("앱을 안 열어도 알고, 입력은 알아서"))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            // 이미 이 칸 이상이면 살 것이 없다. 구독을 평생으로 바꾸는 길은 설정에 있다.
            if plans.tier < tier {
                LeeoTermPicker(term: term(tier), yearly: yearly(tier), lifetime: lifetime(tier))
                buyButton(tier)
                shortTerms(tier)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            shape.fill(Color(.secondarySystemBackground))
            shape.strokeBorder(highlighted ? Color("Pink") : .clear, lineWidth: 2)
        }
    }

    private func term(_ tier: PlanTier) -> Binding<LeeoPlanTerm> {
        tier == .plus ? $plusTerm : $proTerm
    }

    private func yearly(_ tier: PlanTier) -> Product? {
        plans.product(tier == .plus ? PlanProducts.plusYearly : PlanProducts.proYearly)
    }

    /// Plus 평생을 이미 산 사람에게는 Pro 평생 자리에 올리기 상품을 세운다. 같은 Pro 평생을 다 낸 값에 다시 사지 않게.
    private func lifetime(_ tier: PlanTier) -> Product? {
        if tier == .plus { return plans.product(PlanProducts.plusLifetime) }
        return plans.product(upgradesToPro ? PlanProducts.proUpgrade : PlanProducts.proLifetime)
    }

    private var upgradesToPro: Bool { plans.ownsLifetime(.plus) }

    private func buyButton(_ tier: PlanTier) -> some View {
        let chosen = term(tier).wrappedValue
        let product = chosen == .yearly ? yearly(tier) : lifetime(tier)
        let title: LocalizedStringKey = switch chosen {
        case .yearly: "연 구독 시작"
        case .lifetime where tier == .pro && upgradesToPro: "Pro 평생으로 올리기"
        case .lifetime: "평생으로 사기"
        }
        return Button {
            guard let product else { return }
            buy(product, opening: tier)
        } label: {
            Group {
                if plans.isWorking {
                    ProgressView().tint(Color("OnPink"))
                } else {
                    Text(title).font(.headline)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 28)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color("Pink")))
            .foregroundStyle(Color("OnPink"))
        }
        .buttonStyle(.plain)
        .disabled(plans.isWorking || product == nil)
        .opacity(product == nil ? 0.5 : 1)
    }

    /// 주 · 월 구독. 연 구독이 기본이라 펼쳐야 보인다. 불러온 상품만 줄이 선다.
    @ViewBuilder
    private func shortTerms(_ tier: PlanTier) -> some View {
        let weekly = plans.product(tier == .plus ? PlanProducts.plusWeekly : PlanProducts.proWeekly)
        let monthly = plans.product(tier == .plus ? PlanProducts.plusMonthly : PlanProducts.proMonthly)
        if weekly != nil || monthly != nil {
            DisclosureGroup("주 · 월 구독") {
                VStack(spacing: 8) {
                    if let weekly {
                        shortTermButton(String(format: String(localized: "주 구독 · %@"), weekly.displayPrice), weekly, tier)
                    }
                    if let monthly {
                        shortTermButton(String(format: String(localized: "월 구독 · %@"), monthly.displayPrice), monthly, tier)
                    }
                }
                .padding(.top, 8)
            }
            .font(.body)
            .tint(.primary)
        }
    }

    private func shortTermButton(_ title: String, _ product: Product, _ tier: PlanTier) -> some View {
        Button {
            buy(product, opening: tier)
        } label: {
            Text(title)
                .font(.body.weight(.semibold))
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .disabled(plans.isWorking)
    }

    private func buy(_ product: Product, opening tier: PlanTier) {
        Task {
            await plans.purchase(product, using: purchaseAction)
            if plans.tier >= tier { dismiss() }
        }
    }

    // MARK: 요금제를 못 불러왔을 때

    @ViewBuilder
    private var plansStatus: some View {
        if plans.products.isEmpty && loadingProducts {
            HStack(spacing: 10) {
                ProgressView()
                Text("값을 불러오는 중…")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        } else if plans.products.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("요금제를 불러오지 못했어요. 인터넷 연결을 확인하고 다시 불러와 주세요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Task { await loadPlans() }
                } label: {
                    Label("다시 불러오기", systemImage: "arrow.clockwise")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.bordered)
            }
        }
    }

    /// 첫 조회가 비어 오면 한 번 더 청한다. 샌드박스(심사 환경)는 첫 조회가 빈손인 일이 잦다.
    private func loadPlans() async {
        loadingProducts = true
        await plans.loadProducts()
        if plans.products.isEmpty {
            try? await Task.sleep(for: .seconds(1.5))
            await plans.loadProducts()
        }
        loadingProducts = false
    }

    // MARK: 약관 (구독을 파는 앱의 심사 필수 항목)

    private var legal: some View {
        VStack(alignment: .leading, spacing: 10) {
            if plans.products.contains(where: { $0.subscription != nil }) {
                Text("구독은 기간이 끝나기 24시간 전까지 해지하지 않으면 같은 요금으로 자동 갱신되며, Apple 계정으로 결제됩니다. 연 구독을 처음 시작하면 첫 해는 할인된 값으로 결제되고, 그 뒤에는 정가로 갱신됩니다. 해지와 관리는 App Store 계정 설정에서 합니다. 평생은 구독이 아니라 한 번 결제입니다.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 20) {
                if let terms = DontGoMartSpec.monetization.subscriptionTermsURL {
                    Button("이용약관") { openURL(terms) }
                }
                Button("개인정보 처리방침") { openURL(DontGoMartSpec.legal.privacyURL) }
            }
            .font(.body)
        }
    }
}

// MARK: - 잠긴 자리에서 부르는 길

extension View {
    /// `isPresented` 가 켜지면 그 기능의 페이월을 낸다. 닫힌 뒤 `onDismiss` 로 하던 일을 마저 한다.
    func paywall(for feature: PlanFeature?, isPresented: Binding<Bool>,
                 onDismiss: (() -> Void)? = nil) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            PaywallView(highlight: feature)
        }
    }
}

/// 잠긴 기능 옆의 작은 표시. 눌러 보기 전에 어느 칸에서 열리는지 안다.
struct PlanBadge: View {
    let tier: PlanTier

    var body: some View {
        Text(verbatim: tier == .plus ? "Plus" : "Pro")
            .font(.body.weight(.bold))
            .foregroundStyle(Color("OnPink"))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color("Pink")))
            .accessibilityLabel(Text(tier == .plus ? LocalizedStringKey("Plus에서 열려요") : LocalizedStringKey("Pro에서 열려요")))
    }
}

// MARK: - 메인 화면의 Plus 권유 (헛걸음을 막아 준 날, 무료 사용자에게)

/// 응원 부탁 카드가 서던 자리에, 아직 무료인 사람에게만 선다. '다음에' 를 누르면 30일 쉰다.
/// 응원 부탁은 이미 Pro 인 사람에게만 한다(`ClosedDaysView`).
struct PlusInviteCard: View {
    @AppStorage("plusInvite.dismissedAt") private var dismissedAt: Double = 0
    @State private var showingPaywall = false

    static let restDays = 30

    static func isDue(dismissedAt: Double, now: Date = Date()) -> Bool {
        guard dismissedAt > 0 else { return true }
        return now.timeIntervalSince1970 - dismissedAt >= Double(restDays) * 86_400
    }

    var body: some View {
        if Self.isDue(dismissedAt: dismissedAt) {
            VStack(alignment: .leading, spacing: 12) {
                Text("오늘 헛걸음을 막아드렸어요")
                    .font(.headline)
                Text("마트와 단골 식당을 몇 곳이든 챙기고, 휴무 소식을 스토리와 동영상으로 알려 보세요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    Button { showingPaywall = true } label: {
                        Text("Plus 보기")
                            .font(.headline)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color("Pink")))
                            .foregroundStyle(Color("OnPink"))
                    }
                    .buttonStyle(.plain)
                    Button(LeeoLadderText.later) {
                        dismissedAt = Date().timeIntervalSince1970
                    }
                    .font(.body)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
            .paywall(for: nil, isPresented: $showingPaywall)
        }
    }
}

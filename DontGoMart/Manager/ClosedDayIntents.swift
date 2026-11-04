//
//  ClosedDayIntents.swift
//  DontGoMart
//
//  장 보러 나서기 전에 말로 묻는다.
//   - "돈꼬마트 다음 휴무일": 고른 마트의 다음 의무휴업일과 며칠 남았는지.
//   - "돈꼬마트 이번 주 일요일 쉬어?": 이번 주 일요일에 문을 닫는지.
//  위젯과 같은 목록(WidgetClosedDayStore)을 읽는다. 앱이 마트를 고를 때마다 채워 둔다.
//   - 단골 식당은 Spotlight 에 싣는다(iOS 18+). 누르면 그 식당의 휴무 정보가 열린다.
//

import AppIntents
import CoreSpotlight
import Foundation

struct NextClosedDayIntent: AppIntent {
    static let title = LocalizedStringResource("다음 휴무일", comment: "Siri: the next mandatory closing day of the chosen marts")
    static let description = IntentDescription(
        LocalizedStringResource("고른 마트의 다음 휴무일을 알려 줍니다.", comment: "Siri: next closed day description")
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard WidgetClosedDayStore.hasSelectedMart else {
            return .result(dialog: IntentDialog(LocalizedStringResource("먼저 앱에서 마트를 골라 주세요.", comment: "Siri: no mart selected")))
        }
        guard let next = WidgetClosedDayStore.upcoming(onOrAfter: .now).first else {
            return .result(dialog: IntentDialog(LocalizedStringResource("다가오는 휴무일이 없어요.", comment: "Siri: no upcoming closed day")))
        }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: calendar.startOfDay(for: next.date)).day ?? 0
        let date = next.date.formatted(.dateTime.month().day().weekday())
        if days == 0 {
            return .result(dialog: IntentDialog(LocalizedStringResource("오늘 \(next.martName) 쉬는 날이에요.", comment: "Siri: closed today. Argument is the mart name")))
        }
        return .result(dialog: IntentDialog(LocalizedStringResource("\(next.martName)은 \(date)에 쉬어요. \(days)일 남았어요.", comment: "Siri: next closed day. Arguments: mart, date, days left")))
    }
}

struct SundayOpenIntent: AppIntent {
    static let title = LocalizedStringResource("이번 주 일요일 영업", comment: "Siri: is the mart open this Sunday")
    static let description = IntentDescription(
        LocalizedStringResource("이번 주 일요일에 고른 마트가 문을 여는지 알려 줍니다.", comment: "Siri: Sunday status description")
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard WidgetClosedDayStore.hasSelectedMart else {
            return .result(dialog: IntentDialog(LocalizedStringResource("먼저 앱에서 마트를 골라 주세요.", comment: "Siri: no mart selected")))
        }
        let status = WidgetClosedDayStore.sundayStatus(onOrAfter: .now)
        return .result(dialog: status.isClosed
            ? IntentDialog(LocalizedStringResource("이번 주 일요일은 쉬어요. 토요일에 다녀오세요.", comment: "Siri: closed this Sunday"))
            : IntentDialog(LocalizedStringResource("이번 주 일요일은 문을 열어요.", comment: "Siri: open this Sunday")))
    }
}

// MARK: - 단골 식당

/// Siri · Spotlight 가 연 식당. ClosedDaysView 가 시트로 열고 비운다.
@MainActor
final class DontGoMartRouter: ObservableObject {
    static let shared = DontGoMartRouter()
    @Published var restaurant: Restaurant?
}

struct RestaurantEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("단골 식당", comment: "Siri/Spotlight: a restaurant the user saved to track its regular closing days")
    )
    static let defaultQuery = RestaurantQuery()

    let id: UUID
    let name: String
    let address: String
    let closingDays: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(closingDays)")
    }

    init(_ restaurant: Restaurant) {
        id = restaurant.id
        name = restaurant.name
        address = restaurant.address
        closingDays = restaurant.patternSummary
    }
}

@available(iOS 18.0, *)
extension RestaurantEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let set = defaultAttributeSet
        set.contentDescription = closingDays
        set.keywords = [address].filter { !$0.isEmpty }
        return set
    }
}

struct RestaurantQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [RestaurantEntity] {
        let wanted = Set(identifiers)
        return RestaurantStore.load().filter { wanted.contains($0.id) }.map(RestaurantEntity.init)
    }

    func entities(matching string: String) async throws -> [RestaurantEntity] {
        RestaurantStore.load()
            .filter { $0.name.localizedCaseInsensitiveContains(string) || $0.address.localizedCaseInsensitiveContains(string) }
            .map(RestaurantEntity.init)
    }

    func suggestedEntities() async throws -> [RestaurantEntity] {
        RestaurantStore.load().map(RestaurantEntity.init)
    }

    /// Spotlight 에 싣는 식당을 지금 목록에 맞춘다. 앱을 열 때와 뒤로 보낼 때 부른다.
    static func reindex() async {
        guard #available(iOS 18.0, *) else { return }
        let index = CSSearchableIndex.default()
        try? await index.deleteAppEntities(ofType: RestaurantEntity.self)
        try? await index.indexAppEntities(RestaurantStore.load().map(RestaurantEntity.init))
    }
}

/// 단골 식당의 휴무 정보를 연다. Spotlight · Siri 결과를 누르면 여기로 온다.
struct OpenRestaurantIntent: OpenIntent {
    static let title = LocalizedStringResource("단골 식당 열기", comment: "Siri/Spotlight: open a saved restaurant")
    static let description = IntentDescription(
        LocalizedStringResource("저장한 단골 식당의 휴무 정보를 엽니다.", comment: "Siri: open restaurant description")
    )

    @Parameter(title: LocalizedStringResource("식당", comment: "Siri: restaurant parameter"),
               description: LocalizedStringResource("휴무 정보를 열어 볼 단골 식당", comment: "Siri: restaurant parameter description"))
    var target: RestaurantEntity

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        DontGoMartRouter.shared.restaurant = RestaurantStore.load().first { $0.id == target.id }
        return .result()
    }
}

// MARK: - Siri 문구

struct DontGoMartShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextClosedDayIntent(),
            phrases: ["Next closed day in \(.applicationName)", "When is the mart closed with \(.applicationName)"],
            shortTitle: "Next Closed Day",
            systemImageName: "calendar.badge.exclamationmark"
        )
        AppShortcut(
            intent: SundayOpenIntent(),
            phrases: ["Is the mart open this Sunday in \(.applicationName)", "\(.applicationName) this Sunday"],
            shortTitle: "This Sunday",
            systemImageName: "cart"
        )
    }
}

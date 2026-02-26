import SwiftUI
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
        
    private enum Constants {
        /// iOS 알림 제한 안전 임계값 (실제 제한: 64개)
        static let maxSafeNotificationCount = 60
        /// 알림 설정할 최대 일수 (앞으로 1년)
        static let maxNotificationDays = 365
    }
    
    // MARK: - Configuration Properties

    /// 첫 번째 알림: 며칠 전에 보낼지 (기본: 3일 전)
    static let firstNotificationDaysBefore: Int = 3
    /// 두 번째 알림: 며칠 전에 보낼지 (기본: 1일 전)
    static let secondNotificationDaysBefore: Int = 1

    /// 사용자 설정 알림 시간 가져오기
    var notificationHour: Int {
        UserDefaults(suiteName: Utillity.appGroupId)?.integer(forKey: AppStorageKeys.notificationHour) ?? 9
    }

    var notificationMinute: Int {
        UserDefaults(suiteName: Utillity.appGroupId)?.integer(forKey: AppStorageKeys.notificationMinute) ?? 0
    }

    var beforeDayNotificationEnabled: Bool {
        UserDefaults(suiteName: Utillity.appGroupId)?.bool(forKey: AppStorageKeys.beforeDayNotificationEnabled) ?? true
    }
    
    // MARK: - Notification Types

    enum NotificationType: String, CaseIterable {
        case firstNotification = "day1_before"
        case secondNotification = "day2_before"
        case beforeDayNotification = "before_day"
        case shoppingReminder = "shopping_reminder"

        var title: String {
            switch self {
            case .firstNotification, .secondNotification:
                return String(localized: "마트 휴무일 안내", defaultValue: "Store Closure Notice", table: "CodeStrings")
            case .beforeDayNotification:
                return String(localized: "🛒 장보기 좋은 날_notif", defaultValue: "🛒 Good Day to Shop", table: "CodeStrings")
            case .shoppingReminder:
                return String(localized: "장보기 알림_notif", defaultValue: "Shopping Reminder", table: "CodeStrings")
            }
        }

        func body(for martType: MartType) -> String {
            let storeName = martType.notificationStoreName
            let days1 = NotificationManager.firstNotificationDaysBefore
            let days2 = NotificationManager.secondNotificationDaysBefore
            switch self {
            case .firstNotification:
                let format = String(localized: "notification_first_body", defaultValue: "%@ will be closed in %lld days.", table: "CodeStrings")
                return String(format: format, storeName, days1)
            case .secondNotification:
                let format = String(localized: "notification_second_body", defaultValue: "%@ will be closed in %lld day(s).", table: "CodeStrings")
                return String(format: format, storeName, days2)
            case .beforeDayNotification:
                let format = String(localized: "notification_before_body", defaultValue: "%@ is closed tomorrow. Today is a good day to shop!", table: "CodeStrings")
                return String(format: format, storeName)
            case .shoppingReminder:
                return String(localized: "notification_shopping_body", defaultValue: "Don't forget to shop before the next closed day!", table: "CodeStrings")
            }
        }

        var daysToSubtract: Int {
            switch self {
            case .firstNotification:
                return NotificationManager.firstNotificationDaysBefore
            case .secondNotification:
                return NotificationManager.secondNotificationDaysBefore
            case .beforeDayNotification:
                return 1
            case .shoppingReminder:
                return 2
            }
        }
    }
    
    // MARK: - Authorization Management
    
    /// 알림 권한 요청
    func requestAuthorization() async -> Bool {
        do {
            let authorized = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            if authorized {
                print("✅ 알림 권한이 허용되었습니다.")
            } else {
                print("❌ 알림 권한이 거부되었습니다.")
            }
            
            return authorized
        } catch {
            print("❌ 알림 권한 요청 중 오류: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 현재 알림 권한 상태 확인
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Smart Notification Setup
    
    /// 사용자 선택 매장의 가까운 미래 휴무일에 대해서만 알림 설정 (iOS 64개 제한 고려)
    func setupSmartNotifications(for allTasks: [MetaMartsClosedDays]) async {
        guard await validateNotificationPrerequisites() else { return }
        
        clearExistingNotifications()
        
        let targetTasks = await filterNotificationTargets(from: allTasks)
        let scheduledCount = await scheduleNotificationsForTasks(targetTasks)
        
        await validateAndLogResults(scheduledCount: scheduledCount)
    }
    
    // MARK: - Private Methods
    
    /// 1단계: 알림 설정 사전 조건 확인
    private func validateNotificationPrerequisites() async -> Bool {
        // 사용자 알림 설정 확인
        let userDefaults = UserDefaults(suiteName: Utillity.appGroupId)
        let isNotificationEnabled = userDefaults?.bool(forKey: AppStorageKeys.notificationEnabled) ?? false
        
        guard isNotificationEnabled else {
            return false
        }
        
        // 권한 확인
        let status = await checkAuthorizationStatus()
        guard status == .authorized else {
            print("❌ 알림 권한이 없어 알림을 설정할 수 없습니다.")
            return false
        }
        
        return true
    }
    
    /// 2단계: 기존 알림 정리
    private func clearExistingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 3단계: 알림 대상 필터링
    private func filterNotificationTargets(from allTasks: [MetaMartsClosedDays]) async -> [MetaMartsClosedDays] {
        // 사용자 선택 매장만 필터링
        let userSelectedTasks = filterUserSelectedTasks(from: allTasks)
        
        // 가까운 미래의 휴무일만 필터링
        let nearFutureTasks = filterNearFutureTasks(from: userSelectedTasks)
        
        return nearFutureTasks
    }
    
    /// 4단계: 알림 스케줄링 실행
    private func scheduleNotificationsForTasks(_ tasks: [MetaMartsClosedDays]) async -> Int {
        var scheduledCount = 0
        
        for task in tasks {
            for notificationType in NotificationType.allCases {
                let success = await scheduleNotification(
                    for: task.taskDate,
                    type: notificationType,
                    martType: task.type
                )
                if success {
                    scheduledCount += 1
                }
            }
        }
        
        return scheduledCount
    }
    
    /// 5단계: 결과 검증 및 로깅
    private func validateAndLogResults(scheduledCount: Int) async {
        // iOS 64개 제한 체크
        if scheduledCount > Constants.maxSafeNotificationCount {
            print("⚠️ 알림 개수가 많습니다 (\(scheduledCount)개). iOS 제한으로 일부 알림이 누락될 수 있습니다.")
        }
    }
    
    /// 사용자가 선택한 매장의 휴무일만 필터링
    private func filterUserSelectedTasks(from tasks: [MetaMartsClosedDays]) -> [MetaMartsClosedDays] {
        // MartSelectionManager를 사용하여 선택된 마트 타입 가져오기
        let martSelection = MartSelectionManager.shared
        let selectedMartTypes = martSelection.getSelectedMartTypes()

        return tasks.filter { task in
            selectedMartTypes.contains(task.type)
        }
    }
    
    /// 가까운 미래의 휴무일만 필터링 (앞으로 90일)
    private func filterNearFutureTasks(from tasks: [MetaMartsClosedDays]) -> [MetaMartsClosedDays] {
        let today = Date()
        let futureLimit = Calendar.current.date(byAdding: .day, value: Constants.maxNotificationDays, to: today)!
        
        return tasks.filter { task in
            task.taskDate >= today && task.taskDate <= futureLimit
        }.sorted { $0.taskDate < $1.taskDate }
    }
    
    /// 개별 알림 스케줄링
    private func scheduleNotification(
        for closedDate: Date,
        type: NotificationType,
        martType: MartType
    ) async -> Bool {
        // 알림 날짜 계산
        guard let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -type.daysToSubtract,
            to: closedDate
        ) else {
            print("❌ 알림 날짜 계산 실패: \(closedDate)")
            return false
        }
        
        // 알림 시간 설정 (사용자 설정 시간 사용)
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = self.notificationHour
        dateComponents.minute = self.notificationMinute
        dateComponents.second = 0
        
        guard let finalNotificationDate = Calendar.current.date(from: dateComponents) else {
            print("❌ 최종 알림 시간 계산 실패")
            return false
        }
        
        // 과거 시간은 스킵
        if finalNotificationDate <= Date() {
            return false
        }
        
        // 알림 콘텐츠 생성
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = type.body(for: martType)
        content.sound = .default
        
        // 메타데이터 추가
        content.categoryIdentifier = "MART_CLOSURE"
        content.userInfo = [
            "martType": martType.widgetDisplayName,
            "closedDate": ISO8601DateFormatter().string(from: closedDate),
            "notificationType": type.rawValue
        ]
        
        // 트리거 생성
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        // 고유 식별자 생성
        let identifier = generateIdentifier(
            for: closedDate,
            type: type,
            martType: martType
        )
        
        // 알림 요청 생성 및 등록
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            return true
            
        } catch {
            print("❌ 알림 설정 실패: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    /// 알림 식별자 생성
    private func generateIdentifier(
        for closedDate: Date,
        type: NotificationType,
        martType: MartType
    ) -> String {
        let dateString = ISO8601DateFormatter().string(from: closedDate)
        let martTypeString = martType.widgetDisplayName.replacingOccurrences(of: " ", with: "_")
        return "mart_\(martTypeString)_\(dateString)_\(type.rawValue)"
    }
    
    /// 모든 알림 취소
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// UI 표시용 설정 문자열
    static var settingsDescription: String {
        let manager = NotificationManager.shared
        let notifHour = manager.notificationHour
        let notifMinute = manager.notificationMinute

        let hour = notifHour == 12 ? 12 : (notifHour > 12 ? notifHour - 12 : notifHour)
        let period = notifHour < 12 ? "AM" : "PM"
        let timeString = notifMinute == 0 ? "\(period) \(hour):00" : "\(period) \(hour):\(String(format: "%02d", notifMinute))"

        let format = String(localized: "settings_notification_desc", defaultValue: "You'll be notified %lld days and %lld day before closed days at %@.", table: "CodeStrings")
        return String(format: format, firstNotificationDaysBefore, secondNotificationDaysBefore, timeString)
    }

    /// 장보기 알림 스케줄링
    func scheduleShoppingReminder(for martType: MartType) async {
        guard await validateNotificationPrerequisites() else { return }

        let userDefaults = UserDefaults(suiteName: Utillity.appGroupId)
        let isShoppingReminderEnabled = userDefaults?.bool(forKey: AppStorageKeys.shoppingReminderEnabled) ?? false

        guard isShoppingReminderEnabled else { return }

        if let nextClosedDate = OperationStatusManager.shared.nextClosedDate(for: martType) {
            let _ = await scheduleNotification(
                for: nextClosedDate,
                type: .shoppingReminder,
                martType: martType
            )
        }
    }
}

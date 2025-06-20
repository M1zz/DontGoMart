import SwiftUI
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    // MARK: - 상수 정의
    
    private enum Constants {
        /// iOS 알림 제한 안전 임계값 (실제 제한: 64개)
        static let maxSafeNotificationCount = 60
    }
    
    // MARK: - 알림 설정 변수들
    
    /// 첫 번째 알림: 며칠 전에 보낼지 (기본: 3일 전)
    static var firstNotificationDaysBefore: Int = 3
    /// 두 번째 알림: 며칠 전에 보낼지 (기본: 1일 전)
    static var secondNotificationDaysBefore: Int = 1
    /// 알림 시간: 시 (24시간 형식)
    static var notificationHour: Int = 21
    /// 알림 분
    static var notificationMinute: Int = 0
    /// 알림 설정할 최대 일수 (앞으로 90일)
    static let maxNotificationDays: Int = 90
    
    // MARK: - 알림 타입
    
    enum NotificationType: String, CaseIterable {
        case firstNotification = "day1_before"
        case secondNotification = "day2_before"
        
        var title: String {
            switch self {
            case .firstNotification:
                return "마트 휴무일 안내"
            case .secondNotification:
                return "마트 휴무일 안내"
            }
        }
        
        func body(for martType: MartType) -> String {
            let storeName = martType.notificationStoreName
            switch self {
            case .firstNotification:
                return "\(NotificationManager.firstNotificationDaysBefore)일 뒤 \(storeName) 휴점일입니다."
            case .secondNotification:
                return "\(NotificationManager.secondNotificationDaysBefore)일 뒤 \(storeName) 휴점일입니다."
            }
        }
        
        var daysToSubtract: Int {
            switch self {
            case .firstNotification:
                return NotificationManager.firstNotificationDaysBefore
            case .secondNotification:
                return NotificationManager.secondNotificationDaysBefore
            }
        }
    }
    
    // MARK: - 권한 관리
    
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
    

    
    // MARK: - 핵심 알림 설정 로직
    
    /// 사용자 선택 매장의 가까운 미래 휴무일에 대해서만 알림 설정 (iOS 64개 제한 고려)
    func setupSmartNotifications(for allTasks: [MetaMartsClosedDays]) async {
        
        // 1. 사전 조건 확인
        guard await validateNotificationPrerequisites() else { return }
        
        // 2. 기존 알림 정리
        clearExistingNotifications()
        
        // 3. 알림 대상 필터링
        let targetTasks = await filterNotificationTargets(from: allTasks)
        
        // 4. 알림 스케줄링 실행
        let scheduledCount = await scheduleNotificationsForTasks(targetTasks)
        
        // 5. 결과 검증 및 로깅
        await validateAndLogResults(scheduledCount: scheduledCount)
    }
    
    // MARK: - 알림 설정 단계별 메서드
    
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
        // UserDefaults에서 사용자 선택 정보 읽기
        let userDefaults = UserDefaults(suiteName: Utillity.appGroupId)
        let isCostco = userDefaults?.bool(forKey: AppStorageKeys.isCostco) ?? false
        let selectedBranch = userDefaults?.integer(forKey: AppStorageKeys.selectedBranch) ?? 0
        
        return tasks.filter { task in
            switch task.type {
            case .normal:
                // 일반 마트는 코스트코를 선택하지 않았을 때만
                return !isCostco
                
            case .costco(let branch):
                // 코스트코를 선택했고, 해당 지점과 일치할 때만
                guard isCostco else { return false }
                
                let branchID = branch.branchID
                return branchID == selectedBranch
            }
        }
    }
    
    /// 가까운 미래의 휴무일만 필터링 (앞으로 90일)
    private func filterNearFutureTasks(from tasks: [MetaMartsClosedDays]) -> [MetaMartsClosedDays] {
        let today = Date()
        let futureLimit = Calendar.current.date(byAdding: .day, value: Self.maxNotificationDays, to: today)!
        
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
        
        // 알림 시간 설정
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = Self.notificationHour
        dateComponents.minute = Self.notificationMinute
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
    
    // MARK: - 유틸리티 메서드
    
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
        let hour = notificationHour == 12 ? 12 : (notificationHour > 12 ? notificationHour - 12 : notificationHour)
        let period = notificationHour < 12 ? "오전" : "오후"
        let timeString = notificationMinute == 0 ? "\(period) \(hour)시" : "\(period) \(hour)시 \(notificationMinute)분"
        
        return "휴무일 \(firstNotificationDaysBefore)일 전과 \(secondNotificationDaysBefore)일 전 \(timeString)에 알림 (앞으로 \(maxNotificationDays)일간)"
    }
    

}

//
//  WidgetManager.swift
//  DontGoMart
//
//  Created by 황석현 on 1/7/25.
//

import SwiftUI
import WidgetKit

class WidgetManager {
    static let shared = WidgetManager()
    private init() {}

    func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    func updateWidget() {
        debugLog("==========updateWidget==========")
        self.updateUpcomingClosedList()
        self.reloadWidget()
    }

    /// 앞으로의 휴무일 목록을 앱그룹에 단일 JSON 으로 저장한다.
    /// 위젯은 이 목록에서 '표시 중인 날(entry.date) 이후 가장 가까운 휴무일' 을 직접 골라
    /// D-Day 를 매일 다시 계산한다. 덕분에 앱을 실행하지 않아도 하루가 지나면
    /// 위젯의 날짜·D-Day 가 자동으로 다음 휴무일로 넘어간다.
    private func updateUpcomingClosedList() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let selectedMartTypes = MartSelectionManager.shared.getSelectedMartTypes()

        guard !selectedMartTypes.isEmpty else {
            WidgetClosedDayStore.save([])
            return
        }

        // 넉넉한 지평선(다음 24개)을 저장해 앱을 한동안 안 켜도 위젯이 스스로 굴러가도록 한다.
        let upcoming = tasks
            .filter { selectedMartTypes.contains($0.type) && $0.taskDate >= today }
            .sorted { $0.taskDate < $1.taskDate }
            .prefix(24)
            .map {
                UpcomingClosedDay(date: $0.taskDate,
                                  martName: $0.type.widgetDisplayName,
                                  martKey: $0.type.storageKey)
            }

        WidgetClosedDayStore.save(Array(upcoming))
        debugLog("Upcoming list saved: \(upcoming.count) dates")
    }
}

//
//  ProLockedWidget.swift
//  CalendarWidgetExtension
//
//  Pro 위젯(다음 두 번의 휴무 · 이번 주 일요일 · 단골 식당 7일, 잠금화면)을 아직 Pro 가 아닌 사람이 놓았을 때.
//  막다른 길이 되지 않게 무엇이 잠겼는지 말하고, 누르면 앱의 페이월이 그 줄을 짚고 열린다.
//  칸은 앱이 App Group 에 적어 둔 값만 읽는다(`PlanAccess`). 아직 모르면 잠그지 않는다.
//

import SwiftUI
import WidgetKit

/// Pro 가 아니면 내용 대신 잠금 안내를 그린다.
struct ProWidget<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        if PlanAccess.opensProWidgets {
            content
        } else {
            ProLockedWidgetView()
        }
    }
}

struct ProLockedWidgetView: View {
    @Environment(\.widgetFamily) private var family

    private var isLockScreen: Bool {
        family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline
    }

    var body: some View {
        content
            .containerBackground(.background, for: .widget)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Pro에서 열려요"))
            .widgetURL(PlanAccess.paywallLink(for: isLockScreen ? .lockScreenWidgets : .moreWidgets))
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            Label("Pro에서 열려요", systemImage: "lock.fill")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "lock.fill")
                    .font(.system(size: 20, weight: .bold))
            }
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .bold))
                    .widgetAccentable()
                Text("Pro에서 열려요")
                    .font(.headline)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
        default:
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.pink)
                Text("Pro에서 열려요")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

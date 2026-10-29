//
//  DontGoMartRoadmap.swift
//  DontGoMart
//
//  **앞으로 만들 것**의 원본. 설정 ▸ 앞으로 만들 기능(`LeeoRoadmapView`)이 이 목록을 그대로 보여 준다.
//
//  ⚠️ 개발하다 "이건 다음에" 가 생기면 **여기에 한 줄을 더한다.** 코드의 TODO 주석으로만 남기지 않는다.
//     - 새 항목: `.planned`. 손대기 시작하면 `.building`. 내보내면 `.shipped("1.2.0")`.
//     - id 는 한 번 정하면 바꾸지 않는다(문구는 바꿔도 된다).
//     - 문구는 사용자 말로 쓴다(내부 이름 · 기술 용어 금지). 키는 한국어 문구이고, 번역은 `Localizable.xcstrings` 의 모든 언어에 넣는다.
//     - 사용자에게 보일 만한 것만 적는다. 리팩터링 · 시험 · 빌드 설정은 `.sprintcommander/tasks.json` 의 몫이다.
//

import SwiftUI
import LeeoKit

extension DontGoMartSpec {
    static var roadmap: [LeeoRoadmapItem] {[
        // MARK: 지금 만들고 있어요 (손쉬운 사용)
        .init(id: "a11y.voiceover", status: .building,
              title: NSLocalizedString("VoiceOver로 더 편하게", comment: "Roadmap item: a11y.voiceover"),
              detail: NSLocalizedString("화면 읽기 기능이 휴무일과 단추를 빠짐없이, 알맞은 순서로 읽어 줘요.", comment: "Roadmap item detail: a11y.voiceover")),
        .init(id: "a11y.largetext", status: .building,
              title: NSLocalizedString("큰 글씨에 맞춘 화면", comment: "Roadmap item: a11y.largetext"),
              detail: NSLocalizedString("가장 큰 글자 크기에서도 잘리지 않고 보기 좋게 다시 배치돼요.", comment: "Roadmap item detail: a11y.largetext")),
        .init(id: "display.dark", status: .building,
              title: NSLocalizedString("다크 모드", comment: "Roadmap item: display.dark"),
              detail: NSLocalizedString("어두운 화면에서도 글자와 단추가 또렷하게 보여요.", comment: "Roadmap item detail: display.dark")),
        .init(id: "a11y.contrast", status: .building,
              title: NSLocalizedString("보기 편한 색과 대비", comment: "Roadmap item: a11y.contrast"),
              detail: NSLocalizedString("대비를 높이거나 색을 구별하기 어려워도 휴무일을 알아볼 수 있어요.", comment: "Roadmap item detail: a11y.contrast")),
        // MARK: 다음에 만들어요
        .init(id: "a11y.keyboard", status: .planned,
              title: NSLocalizedString("키보드로 조작하기", comment: "Roadmap item: a11y.keyboard"),
              detail: NSLocalizedString("아이패드에서 키보드만으로 마트를 고르고 달력을 넘겨요.", comment: "Roadmap item detail: a11y.keyboard")),
        .init(id: "lang.more", status: .planned,
              title: NSLocalizedString("더 많은 언어", comment: "Roadmap item: lang.more"),
              detail: NSLocalizedString("더 많은 나라 말로 앱을 쓸 수 있게 해요.", comment: "Roadmap item detail: lang.more")),
        .init(id: "onboarding", status: .planned,
              title: NSLocalizedString("처음 쓰는 분을 위한 안내", comment: "Roadmap item: onboarding"),
              detail: NSLocalizedString("처음 열었을 때 무엇을 할 수 있는지 짧게 보여 줘요.", comment: "Roadmap item detail: onboarding")),
        .init(id: "whatsnew", status: .planned,
              title: NSLocalizedString("업데이트 소식", comment: "Roadmap item: whatsnew"),
              detail: NSLocalizedString("업데이트 뒤 처음 열 때 무엇이 새로 생겼는지 알려 줘요.", comment: "Roadmap item detail: whatsnew")),
        .init(id: "tips", status: .planned,
              title: NSLocalizedString("쓰는 요령 알려 주기", comment: "Roadmap item: tips"),
              detail: NSLocalizedString("알아 두면 편한 기능을 알맞은 때에 살짝 알려 줘요.", comment: "Roadmap item detail: tips")),
        .init(id: "shortcuts", status: .planned,
              title: NSLocalizedString("Siri와 단축어", comment: "Roadmap item: shortcuts"),
              detail: NSLocalizedString("Siri에게 묻거나 단축어로 내 마트가 쉬는 날인지 바로 확인해요.", comment: "Roadmap item detail: shortcuts")),
        .init(id: "backup", status: .planned,
              title: NSLocalizedString("백업과 내보내기", comment: "Roadmap item: backup"),
              detail: NSLocalizedString("내가 추가한 마트를 파일로 저장하고 다시 불러올 수 있어요.", comment: "Roadmap item detail: backup")),
        .init(id: "fold", status: .planned,
              title: NSLocalizedString("펼치는 아이폰 화면", comment: "Roadmap item: fold"),
              detail: NSLocalizedString("펼치는 아이폰에서 넓은 화면을 두 쪽으로 나눠 써요.", comment: "Roadmap item detail: fold")),
        .init(id: "data.delete", status: .planned,
              title: NSLocalizedString("내 데이터 한 번에 지우기", comment: "Roadmap item: data.delete"),
              detail: NSLocalizedString("고른 마트와 추가한 마트, 알림 설정을 앱 안에서 한 번에 지워요.", comment: "Roadmap item detail: data.delete")),
        .init(id: "autosave", status: .planned,
              title: NSLocalizedString("하던 일 이어서 하기", comment: "Roadmap item: autosave"),
              detail: NSLocalizedString("마트를 추가하다 앱이 꺼져도 쓰던 내용이 남아 있어요.", comment: "Roadmap item detail: autosave")),
    ]}
}

// MARK: - 화면

/// 설정 ▸ 앞으로 만들 기능. "이런 기능이 있으면 좋겠어요" 는 LeeoKit 피드백 창을 연다.
struct RoadmapScreen: View {
    @State private var showFeedback = false

    var body: some View {
        LeeoRoadmapView<DontGoMartSpec>(onSuggest: { showFeedback = true })
            .sheet(isPresented: $showFeedback) {
                NavigationStack {
                    LeeoFeedbackView<DontGoMartSpec>()
                }
            }
    }
}

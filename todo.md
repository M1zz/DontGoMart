# 커피 카드가 안 보이던 문제 (DEBUG 가시성) — 완료

원인: 기본 DontGoMart 스킴에 StoreKit 설정이 없어 상품 0개 → 후원 UI 자동 숨김 (게이트 문제 아님).

- [x] 기본 DontGoMart 스킴 LaunchAction 에 CoffeeConfiguration.storekit 연결 (이제 ⌘R 로도 상품 로드)
- [x] CoffeeTipPrompt: DEBUG 빌드는 신뢰 게이트(실행 5회·액션 3회) 건너뜀 → 휴무일이면 바로 카드 확인 가능
- [x] DontGoMartTests: 사라진 generateBiweeklyTasks 참조로 깨져 있던 테스트를 ClosureRuleEngine 기준으로 교체 + SKTestSession 으로 팁 상품 3종(소모성/최저가=커피) 로드 검증 — TEST SUCCEEDED
- [x] 테스트 타깃 배포 타깃 17.6 → 18.6 (앱과 불일치로 테스트 빌드 실패하던 것 수정)
- 교훈: SKTestSession 은 XCTest 환경 전용 — 앱 프로세스에서 직접 생성하면 abort 크래시 (시도 후 롤백)
- 확인 방법: Xcode 에서 DontGoMart 스킴 ⌘R → 오늘이 휴무일이면 메인의 '오늘 휴무예요' 아래 커피 카드 표시

---

# 공유 업그레이드: 텍스트 → 휴무 알림 이미지 카드 — 완료

밋밋한 텍스트 공유 대신, 카드 미리보기 시트 + 이미지 공유로 변경.

- [x] ShareCardView.swift 신규 (pbxproj 수기 등록, 앱 타깃): 브랜드 그라데이션 + 흰 카드 + 휴무 마트 칩, 다크모드 무관 고정 색, 340×380 풀블리드
- [x] ShareCardSheet: 미리보기 + ImageRenderer(scale 3, opaque) 렌더링 + ShareLink(이미지 + 메시지 텍스트 동봉)
- [x] ClosedDaysView: sharePayload — 오늘 휴무면 오늘, 아니면 가장 가까운 휴무일(상대 표현 재사용). 마트 미선택 시 기존 텍스트 ShareLink 폴백
- [x] 공유 버튼 탭 = 유의미 액션(trackMeaningfulAction) — 리뷰/후원 게이트에 반영
- [x] 툴바 아이콘 버튼 → 핑크 캡슐 라벨 버튼 "📣 주변 사람에게 휴무소식 알려주기" (lineLimit 1 + minimumScaleFactor 0.75 로 작은 화면 대응)
- [x] 진입 3초 후 문구가 접히고 확성기 아이콘만 남는 스프링 애니메이션 (양 상태 시뮬레이터 스크린샷 검증)
- [x] DontGoMart 빌드 SUCCEEDED + 시뮬레이터 스크린샷으로 시각 확인
- 비고: 카드 시각 확인은 ShareCardView.swift 하단 #Preview 로 가능

---

# 반복 후원 (소모성 팁 티어 + 커피 카운트 배지 + iCloud 영속화) — 완료

기존 비소비성 Coffee 는 1회만 결제 가능 → 소모성(Consumable) 팁 3종으로 반복 후원 지원.
비소비성은 신규 판매 없이 '과거 구매자 배지 복원 앵커' 로만 유지 (하이브리드).

- [x] CoffeeConfiguration.storekit: 소모성 3종 추가 — tip.coffee($0.99)/tip.cake($3.99)/tip.meal($7.99), ko/en 로컬라이즈
- [x] SupporterManager: legacyProductID + tipProductIDs 분리, tipCount(누적 잔 수), recordTip() — UserDefaults + iCloud KVS 미러링(큰 값 병합)
- [x] SupporterManager.refresh(): legacy entitlement 복원(카운트 0이면 1잔 인정) + iCloud/로컬 병합 — 소모성은 entitlement 에 안 남으므로 KVS 가 재설치 영속화 담당
- [x] CoffeeTipStore: 다중 상품 로드(가격순), purchase(_:), Transaction.updates 리스너 + Transaction.unfinished 복구 (구매 중 앱 종료·Ask to Buy 대응)
- [x] ClosedDaysView 카드: 최저가 팁(커피) 원탭 구매, 감사 카드에 누적 ☕️ ×N 표시
- [x] SettingsView: 배지에 ☕️ ×N 캡슐, '응원하기' 섹션 상시 노출(후원자 재후원 가능) + 티어 3행(이모지/설명/가격)
- [x] DontGoMart.entitlements: com.apple.developer.ubiquity-kvstore-identifier 추가 (iCloud KVS)
- [x] DontGoMart 빌드 SUCCEEDED
- 남은 일 (사람 작업): App Store Connect 에 소모성 3종 등록 (ID 는 위와 동일하게), Xcode Signing & Capabilities 에서 iCloud Key-Value storage 켜기, 심사 노트에 "developer tip, no features unlocked, supporter badge shown" 기재

---

# 커피 후원 (감사의 순간 타겟) — 완료

전략: 기능이 아니라 감사에 과금. 앱이 헛걸음을 막아준 순간(오늘 휴무 확인)에만 후원을 요청한다.

- [x] CoffeeTipStore: StoreKit 2 로 com.dontgomart.Coffee 상품 로드·구매, 구매 성공 시 후원자 플래그(isLegacySupporter) 설정
- [x] CoffeeTipPrompt: 노출 판정 — 오늘 휴무 + 미후원자 + 리뷰와 동일 신뢰 게이트(앱 실행 5회·유의미 액션 3회) + '다음에' 후 30일 쿨다운
- [x] ClosedDaysView: todayStatusCard 바로 아래 커피 카드 (커피 사주기/다음에), 구매 직후 감사 카드 전환, VoiceOver 라벨
- [x] SettingsView: 미후원자용 '응원하기' 섹션(상시 구매 진입점, 무료 유지 안내 푸터), 구매 후 후원자 배지로 전환 ('초기 후원자' → '후원자' 문구 일반화)
- [x] ReviewManager: appOpenCount / meaningfulActionsCount 공개 접근자 (후원 게이트 공용)
- [x] DontGoMart 빌드 SUCCEEDED
- 비고: 기본 스킴은 StoreKit 설정이 없어 상품 로드 실패 → 후원 UI 자동 숨김(정상). 검증은 DontGoMart-store 스킴 + CoffeeConfiguration.storekit 구매 시뮬레이션

---

# 대규모 개선 ("다 해줘") — 대부분 완료

각 단계 빌드 검증 후 커밋 완료.

- [x] B-1 공휴일 자동화: 설날/추석 → 음력(.chinese) 자동 계산 (하드코딩 값과 일치 검증)
- [x] QW-1 Weekday 이중 정의 통합 + 요일 심볼 배열 단일화
- [x] QW-2 위젯 색상 중복 제거 → MartType(storageKey:) / themeColor(forStorageKey:) 단일화
- [x] QW-4 휴면 IAP 삭제 (SupporterManager 만 유지)
- [x] B-3 위젯 탭 → 앱 딥링크(widgetURL) + 캘린더 이동
- [x] B-4 알림 리드타임 프리셋 + 전날 토글 실제 반영 + 중복 알림 정리
- [x] QW-3 위젯 앱그룹 데이터 단일 Codable 블롭으로 통합 (키 10개 → 1개)
- [x] A-core(핵심) 내장·커스텀 휴무 규칙 단일 엔진(ClosureRuleEngine)으로 통일, 날짜 패리티 검증
- [ ] B-2 위젯별 특정 매장 지정 — intentdefinition + IntentHandler 필요(Xcode 툴링), 별도 보류
- [ ] A-core(전체) MartType→Store 정체성 병합 + UI 재배선 — UI 대량 변경, 회귀 위험으로 별도 세션 권장
- [ ] B-5 watchOS 컴플리케이션 — 새 watchOS 타깃 필요(pbxproj 수기 추가 위험), 별도

---

# 커스텀 마트 휴무 패턴 쉽게 (매주/격주/매월 주차) — 완료

목표: 매주 화요일 휴무를 쉽게 + 격주(2주에 한 번)도 지원. 2·4주차와 격주는 다름(월 무관 14일 주기).

- [x] 모델: ClosureFrequency(weekOfMonth/biweekly) + ClosurePattern 에 frequency/anchorDate 추가 (기존 저장 데이터 Codable 호환)
- [x] calculateClosedDates: 격주(anchor+14일) 계산 로직 추가, biweeklyDates 헬퍼
- [x] displayText: '매주 X요일' / '격주 X요일 · M/d 시작' 표시
- [x] PatternEditorView 3모드 재구성: 매주(요일 칩)/격주(첫 휴무일 DatePicker+미리보기)/매월 주차(기존 그리드), 안내문·접근성 라벨
- [x] 격주 날짜 알고리즘 독립 검증 (전부 해당 요일·14일 간격)
- [x] DontGoMart 빌드 SUCCEEDED

---

# 일요일 위젯 문자열 한/영 병기 수정 (언어 통일) — 완료

- [x] 원인: sourceLanguage=ko 카탈로그에 한국어 키+영어 defaultValue 로 추출되어 ko 슬롯에 영어값이 들어감
- [x] 새 위젯 문자열 7개를 ko=한국어, en=영어(translated)로 정정 → 재빌드 후에도 유지 확인

---

# 이번 주 일요일 영업/휴무 위젯 (홈 + 잠금화면) — 완료

목표: 내가 설정한 마트가 이번 주 일요일에 열면 초록색, 닫으면 빨간색으로 위젯/잠금화면에서 한눈에.

- [x] WidgetEntry: SundayStatusEntry + WidgetClosedDayStore.sundayStatus/nextSunday/hasSelectedMart 헬퍼 (저장된 다가오는 휴무일 목록에서 계산 → 앱 안 켜도 매주 자동 롤오버)
- [x] SundayStatusWidget.swift: 홈(systemSmall) + 잠금화면(accessoryCircular/Rectangular/Inline), 🟢/🔴 + 영업/휴무 텍스트, VoiceOver 단일 라벨
- [x] CalendarWidgetBundle 에 등록
- [x] pbxproj 에 새 파일 추가 (CalendarWidgetExtension 타깃)
- [x] DontGoMart / CalendarWidgetExtension 빌드 SUCCEEDED
- 비고: 잠금화면 액세서리는 시스템 틴트로 색이 단색화되므로 SF Symbol(체크/엑스) + "영업/휴무" 텍스트로 구분. 홈 위젯은 초록/빨강 배경 그대로.

---

# 후원자 배지 (과거 Pro 구매자) — 완료

- [x] AppStorageKeys.isLegacySupporter 추가
- [x] SupporterManager: Transaction.currentEntitlements 로 com.dontgomart.Coffee 구매 확인 → 플래그(한 번 true 유지)
- [x] 앱 시작 시 SupporterManager.refresh() 호출
- [x] SettingsView 상단에 후원자 배지 섹션(isSupporter 일 때만, 접근성 라벨 포함)
- [x] DontGoMart 빌드 SUCCEEDED
- 비고: 기본 스킴은 StoreKit 설정이 없어 배지 미표시(정상). 검증은 DontGoMart-store 스킴 + StoreKit 구매 시뮬레이션 또는 실제 구매자

---

# 위젯 매일 자동 갱신(날짜/D-Day 롤오버) — 완료

- [x] 원인: 위젯이 저장된 단일 '다음 휴무일' 만 읽어, 그 날이 지나면 다음으로 못 넘어감(앱 실행 시에만 갱신)
- [x] 앱: 다가오는 휴무일 24건을 앱그룹에 평행배열로 저장(WidgetManager.updateUpcomingClosedList)
- [x] 위젯: WidgetClosedDayStore 헬퍼로 entry.date 기준 '오늘 이후 가장 가까운 휴무일' 직접 선택
- [x] 두 프로바이더 16일치 일별 엔트리 + 자정 reload → 앱 안 켜도 매일 날짜·D-Day 자동 롤오버
- [x] DontGoMart / CalendarWidgetExtension 빌드 SUCCEEDED

---

# 유료 잠금 제거(전 기능 무료) + 다가오는 휴무일 직관화 — 완료

- [x] PremiumManager 잠금 제거 (전 기능 항상 허용)
- [x] SettingsView 페이월/배너/DEBUG 토글 제거, 나만의 마트·알림 항상 노출
- [x] ClosedDaysView 프리미엄 배너/페이월 시트 제거
- [x] 다가오는 휴무일 카드: 상대 표현(오늘/내일/이번주 X요일) 으로 직관화
- [x] DontGoMart / CalendarWidgetExtension 빌드 SUCCEEDED 검증
- 비고: PremiumUpgradeView / StoreKitManager 는 미참조 휴면 상태로 남김 (IAP 완전 삭제는 별도)

---

# 앱 단순화 + 접근성 (시각장애인 '한 번에 인지') — 완료

범위: 데이터 모델 단순화 + 장보기 제거 + 캘린더 리디자인 + 접근성. 검증: 메인/위젯 빌드 SUCCEEDED.

## 데이터 모델 단순화
- [x] 죽은 병렬 마트 모델 삭제: MartStore / CostcoStoreLocation / ClosingPattern
- [x] 미사용 매니저 삭제: LocationManager, FavoriteMartManager
- [x] 빌드에서 빠져있던 죽은 화면 삭제: ImprovedClosedDaysView, ImprovedSettingsView
- [x] 마트 색상 로직 중복 제거 → `MartType.themeColor` 단일 소스로 통합
- [x] 미사용 AppStorageKeys 정리 (favoriteMarts, shoppingReminderEnabled, locationEnabled, viewMode)
- [x] 실제 동작 모델은 `MartType` enum 기반 단일 체계로 유지 (다중 선택 유지)

## 장보기 목록 제거
- [x] ShoppingListView / ShoppingReminder 삭제
- [x] 메인 화면 빠른실행에서 장보기 버튼 제거 → 캘린더 단일 버튼
- [x] NotificationManager 장보기 알림(shoppingReminder, scheduleShoppingReminder) 제거

## 즐겨찾기 제거
- [x] 설정 화면 별표 버튼/로직 제거, 메인 다가오는 휴무일 별표·우선정렬 제거

## 캘린더 리디자인 (미니멀)
- [x] 큰 날짜 + 휴무일 색점, 선택일 분홍 라운드 채움, 오늘은 외곽선
- [x] 일요일 빨강, 넉넉한 셀(48pt)·여백, 군더더기 캡슐 배경 제거
- [x] 레거시 isCostco/selectedBranch 파라미터 의존 제거 → MartSelectionManager 직접 사용

## 메인 화면 단순화
- [x] '오늘 갈 수 있나요?' 큰 이모지 + 한 문장 상태 (음성 단일 라벨)
- [x] '다음 휴무일' 카드 군더더기 제거, 음성 단일 라벨
- [x] navigationTitle 레거시 지점명 의존 제거 → 고정 타이틀

## 검증
- [x] DontGoMart 빌드 BUILD SUCCEEDED
- [x] CalendarWidgetExtension 빌드 BUILD SUCCEEDED

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

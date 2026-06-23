# 브랜딩 되돌리기: Klosed → DontGoMart / 돈꼬마트

## 1. 사용자 노출 문자열 (완료)
- [x] 영문 표시명 Klosed → DontGoMart (InfoPlist.xcstrings, 페이월/Pro 명칭, 위치 권한 안내)
- [x] "휴무" 말장난 영문 Klosed → Closed (브랜드 아님)
- [x] 한글은 전부 이미 "돈꼬마트" → 변경 불필요

## 2. 프로젝트/파일명 리네이밍 (완료)
- [x] 폴더: Klosed/ → DontGoMart/, KlosedWidget/ → DontGoMartWidget/, KlosedTests/ → DontGoMartTests/
- [x] 프로젝트: Klosed.xcodeproj → DontGoMart.xcodeproj (빈 껍데기 DontGoMart.xcodeproj 제거)
- [x] 파일: KlosedApp.swift → DontGoMartApp.swift, Klosed.entitlements → DontGoMart.entitlements, KlosedTests.swift → DontGoMartTests.swift
- [x] 스킴: Klosed.xcscheme → DontGoMart.xcscheme, Klosed-store → DontGoMart-store
- [x] project.pbxproj / 스킴 / plist / swift 헤더·심볼 전부 Klosed → DontGoMart
- [x] @testable import Klosed → DontGoMart, struct KlosedApp/KlosedTests 리네이밍
- [x] 시뮬레이터 빌드 검증: BUILD SUCCEEDED (메인 + 위젯)

## 보존한 것 (의도적)
- 번들ID com.leeo.DontGoMart, App Group group.com.leeo.DontGoMart (이미 DontGoMart, 스토어 연속성)
- 위젯 타겟명 CalendarWidgetExtension (Klosed 무관)
- 라이브 URL: App Store(.../klosed/...), 랜딩(m1zz.github.io/Klosed) — README/docs/.sprintcommander project.json
- DontGoMart.xcodeproj/project.pbxproj.backup (구 백업 파일, 미사용)

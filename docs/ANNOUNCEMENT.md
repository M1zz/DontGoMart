# 공지 배너 올리는 법

앱 업데이트 없이 메인 화면 위에 공지 배너를 띄운다. 코드는 `DontGoMart/Manager/AnnouncementManager.swift`,
화면은 `DontGoMart/Screen/AnnouncementBanner.swift`.

## 1회 준비 (CloudKit Dashboard)

컨테이너 `iCloud.com.Ysoup.FeedbackHub` ▸ Schema ▸ Record Types 에 `Announcement` 를 만들고 아래 필드를 추가한 뒤
**Production 에 배포**한다. 배포 전에는 앱이 조회해도 레코드를 못 찾아서 공지가 뜨지 않는다.

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `message` | String | O | 배너 본문 |
| `title` | String | | 굵은 제목 (없으면 본문만) |
| `noticeID` | String | | 공지 식별자. 사용자가 닫으면 같은 ID 는 다시 안 뜬다 |
| `linkURL` | String | | 배너를 누르면 열 웹 주소 (http/https 만) |
| `isActive` | Int64 | | 0 이면 숨김 (없으면 노출) |
| `endsAt` | Date/Time | | 이 시각이 지나면 자동으로 숨김 |
| `style` | String | | `info`(분홍, 기본) 또는 `warning`(주황) |

## 공지 올리기

Production ▸ Public Database 에서 `Announcement` 레코드를 **recordName `notice_com.leeo.DontGoMart`** 로 만든다
(레코드는 하나만 쓴다 — 새 공지는 같은 레코드를 고친다).

- 새 공지로 바꿀 때는 `noticeID` 도 새 값으로 바꾼다 (예: `2026-10-chuseok`). 그래야 이전 공지를 닫은 사람에게도 뜬다.
  `noticeID` 를 비워 두면 레코드를 고칠 때마다 다시 뜬다.
- 내리기: `isActive` 를 0 으로 하거나 레코드를 지운다.
- 앱은 실행·포그라운드 복귀 때 30분에 한 번 조회한다. 조회에 실패하면 마지막으로 받은 공지를 그대로 둔다.

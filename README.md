# DontGoMart

(앱에 대한 설명이 필요함다!)

DontGoMart 프로젝트에 기여해주셔서 감사합니다.

아래 사항을 참고해주세요.

- [이슈 작성](#1-이슈-작성)
- [기여 프로세스](#2-기여-프로세스)
- [PR 가이드](#3-pr-가이드)
- [Commit 가이드](#4-commit-가이드)
- [코드 스타일 가이드](#5-코드-스타일-가이드)

# 컨트리뷰션 가이드

### 1. 이슈 작성

- 누구나 자유롭게 이슈를 작성할 수 있습니다.
- 버그 리포트, 기능 요청, 개선 제안 등 다양한 의견을 공유해주세요.
- 이슈는 프로젝트 개선에 큰 도움이 됩니다.

### 2. 기여 프로세스

#### 1단계: 이슈 확인 및 참여
1. [Issues 탭](https://github.com/your-username/DontGoMart/issues)에서 현재 진행 중인 이슈들을 확인합니다.
2. 관심 있는 이슈를 찾았다면, 해당 이슈에 댓글을 남겨 참여 의사를 표시합니다.
3. 이슈 담당자가 당신을 Assignee로 지정하면, 해당 이슈를 해결할 수 있는 권한이 부여됩니다.

#### 2단계: 프로젝트 Fork
1. GitHub에서 DontGoMart 저장소의 우측 상단에 있는 'Fork' 버튼을 클릭합니다.
2. Fork가 완료되면, 당신의 GitHub 계정에 DontGoMart 저장소가 복사됩니다.

#### 3단계: 로컬 개발 환경 설정
1. 로컬 컴퓨터에서 터미널을 엽니다.
2. 작업할 디렉토리로 이동합니다.
3. Fork한 저장소를 클론합니다.
```bash
git clone https://github.com/my-username/DontGoMart.git
```
4. DontGoMart 디렉토리로 이동 후, 원본 저장소를 upstream으로 추가합니다.
```bash
cd DontGoMart
git remote add upstream https://github.com/M1zz/DontGoMart.git
```

#### 4단계: 개발 브랜치 생성
1. develop 브랜치를 최신 상태로 유지합니다.
```bash
git checkout develop
git pull upstream develop
```
2. 새로운 기능 브랜치를 생성합니다.
```bash
git checkout -b feature/issue-number
```
   - issue-number는 작업할 이슈 번호입니다 (예: feature/123)

#### 5단계: 개발 및 테스트
1. Xcode에서 프로젝트를 열고 개발을 진행합니다.
2. 변경사항을 커밋합니다.
```bash
git add .
git commit -m "feat: 새로운 기능 추가"
```

#### 6단계: PR 생성
1. 변경사항을 Fork한 저장소에 푸시합니다.
```bash
git push origin feature/issue-number
```
2. GitHub에서 'Pull Request' 버튼을 클릭합니다.
3. PR 제목과 설명을 작성합니다.
   - 제목: type: 내용 요약
   - 설명: 변경사항, 구현 내용, 테스트 결과 등을 상세히 작성
4. 'Leeo'를 리뷰어로 할당합니다.
5. 'Create Pull Request' 버튼을 클릭하여 PR을 생성합니다.

#### 7단계: 리뷰 및 머지
1. 리뷰어의 피드백을 기다립니다.
2. 피드백이 있다면 수정사항을 반영하고 다시 커밋합니다.
3. 모든 리뷰어의 승인이 완료되면 PR이 머지됩니다.

#### 8단계: 정리
1. 로컬 브랜치를 정리합니다.
```bash
git checkout develop
git pull upstream develop
git branch -d feature/issue-number
```
2. Fork한 저장소의 브랜치도 삭제합니다.
```bash
git push origin --delete feature/issue-number
```

# 3. PR 가이드

#### PR 제목 형식
```
- type: feat, fix, docs, style, refactor, test, chore
- 내용 요약: 변경사항을 간단명료하게 설명

예시:
feat: 마트 방문 기록 기능 추가
fix: 메모리 누수 문제 해결
docs: README 업데이트
```
#### PR 설명 형식
```
Description
- 변경사항에 대한 상세 설명

Changes
- 구현한 기능 목록
- 수정된 파일 목록

Test Checklist
- [ ] 테스트 항목 1
- [ ] 테스트 항목 2
```
### 브랜치 전략
- 모든 PR은 `develop` 브랜치로 머지됩니다.
- 새로운 브랜치 생성 시 `develop` 브랜치에서 분기합니다.
- 브랜치 이름은 다음 형식을 따릅니다:
   - 기능 개발: `feature/이슈번호` (예: feature/123)
   - 버그 수정: `fix/이슈번호` (예: fix/456)
   - 리팩토링: `refactor/설명` (예: refactor/code-cleanup)
- `main` 브랜치로의 머지는 `develop` 브랜치에서만 가능합니다.
- `main`과 `develop` 브랜치에는 직접 커밋할 수 없습니다.
- `main` 브랜치로의 PR 생성 시, `develop`에 머지된 PR 목록을 상세히 기재합니다.

### 코드 리뷰 규칙
- 왜 개선이 필요한지 이유를 충분한 설명해주세요.

# 4. Commit 가이드

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

- type: feat, fix, docs, style, refactor, test, chore
- 제목과 본문은 한글로 작성해주세요.
- type은 영어로 작성해주세요.
- 커밋 로그를 보고 흐름을 이해할 수 있도록 작성해주세요.

예시:
```
feat: 마트 방문 기록 기능 추가

사용자의 마트 방문 기록을 저장하고 관리하는 기능을 추가했습니다.
- CoreData 모델 추가
- 방문 기록 저장 로직 구현
- 방문 기록 조회 UI 구현
```

### 5. 코드 스타일 가이드
Apple Developer Academy의 스타일 가이드를 따릅니다. 자세한 사항은 아래 링크를 참고해주세요.
- [Swift Style Guide](https://github.com/DeveloperAcademy-POSTECH/swift-style-guide)
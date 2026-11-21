#!/bin/sh
# 소개 페이지 다시 만들기 (docs/index.html · docs/<언어>/index.html).
# 공용 생성기(DeployBar 의 scripts/sitegen)를 돌린 뒤, 오른쪽에서 왼쪽으로 쓰는 언어(아랍어)에 dir 을 단다.
# 생성기는 글 방향을 모른다. 뒤집는 스타일은 docs/demo.css 의 [dir="rtl"] 에 있다.
#
# 사용법: scripts/build_site.sh        (생성기 자리가 다르면 SITEGEN=<sitegen.py 경로>)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITEGEN="${SITEGEN:-$HOME/Documents/workspace/개발중/DeployBar/scripts/sitegen/sitegen.py}"
python3 "$SITEGEN" "$ROOT"
for lang in ar; do
  page="$ROOT/docs/$lang/index.html"
  [ -f "$page" ] && sed -i '' "s/<html lang=\"$lang\">/<html lang=\"$lang\" dir=\"rtl\">/" "$page"
done
# 생성기는 "고마운 사람들" 칸(앱에서 응원한 분의 이름)을 모른다. 다시 만들 때마다 되돌려 놓는다.
python3 - "$ROOT" <<'PY'
import pathlib, sys
block = """  <!-- leeo-thanks -->
  <section id="leeo-thanks" data-app="donkko-mart" data-name="DontGoMart" data-mail="leeo@kakao.com"></section>
  <script src="https://m1zz.github.io/app-portfolio/thanks.js" defer></script>
  <!-- /leeo-thanks -->
"""
docs = pathlib.Path(sys.argv[1], "docs")
for page in [docs / "index.html"] + sorted(docs.glob("*/index.html")):
    text = page.read_text(encoding="utf-8")
    if "leeo-thanks" not in text and "  <footer>" in text:
        page.write_text(text.replace("  <footer>", block + "  <footer>", 1), encoding="utf-8")
PY
echo "완료: docs/<언어>/index.html"

#!/usr/bin/env python3
"""돈꼬마트 App Store 크리에이티브 자산(제품 페이지 헤더 · 검색 결과): HTML → 헤드리스 Chrome.

사용법: python3 scripts/make_creative_assets.py [언어 ...]     (없으면 전부: ko en)

자리
  docs/screenshots/creative/<스토어 로케일>/header.png   3840x1646  제품 페이지 맨 위
  docs/screenshots/creative/<스토어 로케일>/search.png   3840x2560  검색 결과 (없으면 스크린샷이 대신 보인다)

기기 화면: docs/screenshots/raw/<언어>/01-main · 02-calendar · 03-marts (마케팅 스크린샷과 같은 원본)

⚠️ 안전 영역 밖은 기기에 따라 잘린다. 글은 **반드시** 안전 영역 안에 둔다(배경 · 기기 그림은 넘쳐도 된다).
   수치는 Apple 공식 PSD 템플릿에서 잰 값이다(https://developer.apple.com/app-store/asset-best-practices/).
⚠️ 가격 · 할인 · 주소(URL) · 수상 · 다른 플랫폼 이름은 넣지 않는다(Apple 가이드).
"""
import subprocess, sys, pathlib, tempfile, time

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUT = ROOT / "docs" / "screenshots" / "creative"
ICON = ROOT / "DontGoMart" / "Assets.xcassets" / "AppIcon.appiconset" / "1024.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# 사용자가 쓰는 Chrome 과 프로필이 겹치면 헤드리스가 멈춘다 — 따로 쓴다
PROFILE = tempfile.mkdtemp(prefix="dontgomart-creative-chrome-")

# 앱 언어 코드(raw · marketing 폴더 이름) → App Store Connect 로케일 (--storetext 로 확인한 것)
STORE = {"en": "en-US"}

# (가로, 세로, 안전 영역 left, top, right, bottom)
SPEC = {
    "header": (3840, 1646, (1097, 493, 2743, 1154)),
    "search": (3840, 2560, (836, 765, 3004, 1795)),
}

# 헤더: 처음 온 사람에게 **한 가지 약속** — 부제("헛걸음 끝" / "Know before you go")와 같은 생각.
# ⚠️ 기계번역하지 않는다. 언어마다 따로 썼다.
HEADER = {
    "ko": ("마트 휴무일 알림", "문 닫은 마트 앞<br>헛걸음은 이제 끝"),
    "en": ("Store closed days", "Know it's open<br>before you go"),
}

# 검색 결과: 스크린샷 1장("마트 가기 전, 딱 3초")과 **같은 이야기**. 눈썹글은 그 나라 사람이 검색창에 치는 말.
SEARCH = {
    "ko": ("마트 쉬는날", "마트 가기 전,<br>딱 3초", "오늘 여는지 한눈에 확인하세요"),
    "en": ("Store closing days", "Check before<br>you go", "See at a glance if your store is open today"),
}

ACCENT = "#F0566A"   # 앱의 분홍(D-Day · 휴무 표시)
# ⚠️ 바탕 · 글자색은 마케팅 스크린샷(make_marketing_screenshots.py)과 같다.
BASE_CSS = """
* { margin:0; padding:0; box-sizing:border-box; }
html,body { width:%(W)dpx; height:%(H)dpx; overflow:hidden; }
body { background:#f6f5f3; position:relative;
  font-family:-apple-system,"Apple SD Gothic Neo","Helvetica Neue",sans-serif; }
.glow { position:absolute; border-radius:50%%; filter:blur(160px); pointer-events:none; }
.text { position:absolute; display:flex; flex-direction:column; justify-content:center; }
.eyebrow { font-weight:700; color:#F0566A; letter-spacing:-0.01em; line-height:1.15; }
.headline { font-weight:800; color:#141416; letter-spacing:-0.03em; line-height:1.16; text-wrap:balance; }
.sub { font-weight:500; color:#8a8a90; letter-spacing:-0.01em; line-height:1.35; text-wrap:balance; }
:lang(ko) .headline, :lang(ko) .sub, :lang(ko) .eyebrow { word-break:keep-all; }
.phone { position:absolute; background:#17171a; border:5px solid #3a3a3e; padding:40px; border-radius:190px;
  box-shadow:58px 86px 140px rgba(0,0,0,.24), 20px 30px 60px rgba(0,0,0,.14); }
.phone img { width:100%%; display:block; border-radius:152px; }
/* 앱 아이콘(금지 표시 카트)을 옅게 흩는다. 흰 바탕은 multiply 로 사라진다 */
.mark { position:absolute; mix-blend-mode:multiply; opacity:.13; }
"""
# 헤드리스 Chrome 은 -apple-system 을 못 찾아 다음 글꼴(한글)로 그린다 — 영어는 Helvetica Neue 로 먼저.
LATIN_FONT = 'body { font-family:"Helvetica Neue",-apple-system,sans-serif; }'

# 글이 상자를 넘지 않을 때까지 줄인다. 잘리는 글은 없다 - 끝까지 안 맞으면 표시하고 멈춘다.
FIT_JS = """
<script>
// 문구에 적은 줄(<br>)보다 더 쪼개지면 "Rispondi / con un / tocco" 처럼 읽기가 끊긴다.
// 적은 줄 수를 지킬 때까지 줄인다.
function lines(el) {
  return Math.round(el.getBoundingClientRect().height / parseFloat(getComputedStyle(el).lineHeight));
}
function fit(box, el, max, min) {
  const want = el.querySelectorAll('br').length + 1;
  let size = max;
  el.style.fontSize = size + 'px';
  while (size > min && (box.scrollHeight > box.clientHeight + 1 || box.scrollWidth > box.clientWidth + 1 ||
         lines(el) > want)) {
    size -= 4; el.style.fontSize = size + 'px';
  }
  if (box.scrollHeight > box.clientHeight + 1 || box.scrollWidth > box.clientWidth + 1 || lines(el) > want)
    document.body.dataset.overflow = '1';
}
document.fonts.ready.then(() => {
  const box = document.querySelector('.text');
  const h = document.querySelector('.headline');
  fit(box, h, +h.dataset.max, +h.dataset.min);
  document.body.dataset.done = '1';
});
</script>
"""


def raw(lang, name):
    p = RAW / lang / name
    if not p.exists():
        raise SystemExit(f"원본 없음: {p}")
    return p.as_uri()


def phone(img, left, top, width, rotate=0):
    return (f'<div class="phone" style="left:{left}px;top:{top}px;width:{width}px;'
            f'transform:rotate({rotate}deg)"><img src="{img}"></div>')


def marks(items):
    return "".join(f'<img class="mark" src="{ICON.as_uri()}" style="left:{x}px;top:{y}px;width:{w}px;'
                   f'transform:rotate({r}deg)">' for x, y, w, r in items)


def search_html(lang):
    W, H, (l, t, r, b) = SPEC["search"]
    eyebrow, headline, sub = SEARCH[lang]
    sw, sh = r - l, b - t
    col = int(sw * 0.56)
    ph_w = 1040
    ph_left = l + col + int(sw * 0.04)
    return f"""
<div class="glow" style="left:{ph_left - 300}px;top:500px;width:1700px;height:1700px;background:rgba(240,86,106,.12)"></div>
<div class="glow" style="left:{l - 700}px;top:{t + 300}px;width:1600px;height:1200px;background:rgba(52,199,89,.08)"></div>
{marks([(3260, 380, 380, 12), (220, 1980, 340, -10), (260, 200, 260, 8)])}
{phone(raw(lang, "01-main.png"), ph_left, t - 360, ph_w, 0)}
<div class="text" style="left:{l}px;top:{t}px;width:{col}px;height:{sh}px">
  <div class="eyebrow" style="font-size:96px">{eyebrow}</div>
  <div class="headline" data-max="240" data-min="130" style="margin-top:36px">{headline}</div>
  <div class="sub" style="font-size:80px;margin-top:52px">{sub}</div>
</div>"""


def header_html(lang):
    W, H, (l, t, r, b) = SPEC["header"]
    eyebrow, headline = HEADER[lang]
    sw, sh = r - l, b - t
    return f"""
<div class="glow" style="left:{l - 200}px;top:{t - 400}px;width:{sw + 400}px;height:{sh + 800}px;background:rgba(240,86,106,.09)"></div>
{marks([(-40, 60, 300, -12), (1020, 1280, 220, 10), (3400, 80, 280, 14), (2620, 1290, 230, -8), (3620, 1120, 260, -6)])}
{phone(raw(lang, "02-calendar.png"), 300, 360, 640, -9)}
{phone(raw(lang, "03-marts.png"), 2900, 360, 640, 9)}
<div class="text" style="left:{l}px;top:{t}px;width:{sw}px;height:{sh}px;align-items:center;text-align:center">
  <div class="eyebrow" style="font-size:76px">{eyebrow}</div>
  <div class="headline" data-max="200" data-min="100" style="margin-top:22px">{headline}</div>
</div>"""


def chrome(args, done, timeout=90):
    """헤드리스 Chrome 은 일을 다 하고도 끝나지 않을 때가 있다 — done() 이 참이 되면 끝낸다."""
    with tempfile.TemporaryFile("w+", encoding="utf-8") as out:
        proc = subprocess.Popen([CHROME, "--headless=new", "--force-device-scale-factor=1", "--hide-scrollbars",
                                 "--disable-gpu", "--virtual-time-budget=3000", "--allow-file-access-from-files",
                                 f"--user-data-dir={PROFILE}", *args], stdout=out, stderr=subprocess.DEVNULL)
        text = ""
        for _ in range(timeout * 2):
            out.seek(0)
            text = out.read()
            if proc.poll() is not None or done(text):
                break
            time.sleep(0.5)
        time.sleep(1)   # 쓰는 중일 수 있다
        if proc.poll() is None:
            proc.kill()
            proc.wait()
        out.seek(0)
        return out.read()


def render(lang, kind):
    W, H, _ = SPEC[kind]
    body = search_html(lang) if kind == "search" else header_html(lang)
    css = BASE_CSS % {"W": W, "H": H} + ("" if lang == "ko" else LATIN_FONT)
    page = (f'<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>'
            f'{css}</style></head><body>{body}{FIT_JS}</body></html>')
    html_path = pathlib.Path(tempfile.gettempdir()) / f"dontgomart-creative-{lang}-{kind}.html"
    html_path.write_text(page, encoding="utf-8")
    # 글이 끝까지 안 맞으면 그림을 만들지 않는다(잘린 글이 스토어에 올라가는 것보다 낫다).
    dom = chrome(["--dump-dom", f"--window-size={W},{H}", html_path.as_uri()], lambda t: "</html>" in t)
    if 'data-done="1"' not in dom:
        raise SystemExit(f"글 맞추기가 끝나지 않았다: {lang} {kind}")
    if 'data-overflow="1"' in dom:
        raise SystemExit(f"글이 안전 영역을 넘는다: {lang} {kind} - 문구를 줄일 것")
    out_dir = OUT / STORE.get(lang, lang)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_png = out_dir / f"{kind}.png"
    out_png.unlink(missing_ok=True)
    # ⚠️ Chrome 은 가끔 아무것도 안 그리고 끝나거나 멈춘다. 세 번까지 한다.
    for _ in range(3):
        chrome([f"--screenshot={out_png}", f"--window-size={W},{H}", html_path.as_uri()],
               lambda t: out_png.exists() and out_png.stat().st_size > 0)
        if out_png.exists() and out_png.stat().st_size > 0:
            break
        time.sleep(1)
    else:
        raise SystemExit(f"Chrome 이 그리지 못했다: {out_png}")
    html_path.unlink(missing_ok=True)
    print(f"rendered {out_png.relative_to(ROOT)}")


if __name__ == "__main__":
    langs = sys.argv[1:] or list(SEARCH)
    for lang in langs:
        if lang not in SEARCH or lang not in HEADER:
            raise SystemExit(f"모르는 언어: {lang} (아는 것: {', '.join(SEARCH)})")
        for kind in ("header", "search"):
            render(lang, kind)

#!/usr/bin/env python3
"""앱스토어 마케팅 스크린샷 생성: HTML 생성 → 헤드리스 Chrome 렌더링.

원본 캡처(docs/screenshots/raw/<locale>/)를 목업 위에 얹고 헤드라인을 붙여
App Store Connect 제출 규격(1242x2688)으로 바로 렌더링한다.

다음 릴리즈 때는 원본 스크린샷만 다시 찍고 이 스크립트를 재실행하면 된다.

사용법:
    python3 scripts/make_marketing_screenshots.py          # ko, en 전부
    python3 scripts/make_marketing_screenshots.py ko       # 특정 로케일만
"""
import subprocess, sys, pathlib, tempfile, time

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUT = ROOT / "docs" / "screenshots" / "marketing"
WORK = ROOT / "docs" / "screenshots" / ".html"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# 사용자가 쓰는 Chrome 과 프로필이 겹치면 헤드리스가 멈춘다 — 따로 쓴다
PROFILE = tempfile.mkdtemp(prefix="dontgomart-shots-chrome-")

# App Store Connect 제출 규격. 원본(1320x2868)을 리사이즈하지 않고
# 캔버스 자체를 이 크기로 잡아 렌더링해야 화질이 유지된다.
W, H = 1242, 2688

# (파일명, 레이아웃, 헤드라인, 서브카피) — 로케일별로 따로 쓴다(기계번역 금지)
SHOTS = {
    "ko": [
        ("01-main.png",     "hero-bleed",  "마트 가기 전,<br>딱 3초",   "오늘 여는지 한눈에 확인하세요"),
        ("02-calendar.png", "left-text",   "이번 달 휴무일을<br>한눈에", "달력에서 쉬는 날만 콕 집어드려요"),
        ("03-marts.png",    "text-bottom", "내가 가는 마트만 골라서",    "대형마트·코스트코·명절 휴무까지"),
        ("04-pattern.png",  "flat-rotate", "동네 마트도<br>직접 등록",   "2·4주 화요일 같은 패턴 그대로"),
        ("05-share.png",    "dark",        "휴무 소식,<br>카드 한 장으로", "가족과 이웃에게 바로 알려주세요"),
    ],
    "en": [
        ("01-main.png",     "hero-bleed",  "Check before<br>you go",      "See at a glance if the store is open"),
        ("02-calendar.png", "left-text",   "This month's<br>closings",    "Every closed day, right on the calendar"),
        ("03-marts.png",    "text-bottom", "Track only your stores",      "Supermarkets, Costco, holiday closings"),
        ("04-pattern.png",  "flat-rotate", "Add your<br>local store",     "Patterns like 2nd and 4th Tuesday"),
        ("05-share.png",    "dark",        "Share a closing<br>in one card", "Let family and neighbors know"),
    ],
    "en-GB": [
        ("01-main.png",     "hero-bleed",  "Check before<br>you go",      "See at a glance if the shop is open"),
        ("02-calendar.png", "left-text",   "This month's<br>closings",    "Every closed day, right on the calendar"),
        ("03-marts.png",    "text-bottom", "Track only your shops",       "Supermarkets, Costco, bank holiday closings"),
        ("04-pattern.png",  "flat-rotate", "Add your<br>local shop",      "Patterns like 2nd and 4th Tuesday"),
        ("05-share.png",    "dark",        "Share a closing<br>in one card", "Let family and neighbours know"),
    ],
    "ja": [
        ("01-main.png",     "hero-bleed",  "お出かけ前に、<br>3秒チェック",   "今日営業しているか、ひと目でわかります"),
        ("02-calendar.png", "left-text",   "今月の休業日を<br>ひと目で",       "カレンダーで休みの日だけをお知らせ"),
        ("03-marts.png",    "text-bottom", "行くお店だけを選べる",             "大型スーパー・コストコ・祝日の休みまで"),
        ("04-pattern.png",  "flat-rotate", "近所のお店も<br>自分で登録",       "第2・第4火曜日のパターンもそのまま"),
        ("05-share.png",    "dark",        "休業のお知らせを<br>カード1枚で",  "家族やご近所にすぐ伝えられます"),
    ],
    "ru": [
        ("01-main.png", "hero-bleed", "Проверьте до<br>выхода из дома", "Сразу видно, открыт ли магазин сегодня"),
        ("02-calendar.png", "left-text", "Выходные<br>этого месяца", "Все закрытые дни — прямо в календаре"),
        ("03-marts.png", "text-bottom", "Только ваши магазины", "Супермаркеты, Costco, праздничные выходные"),
        ("04-pattern.png", "flat-rotate", "Добавьте свой<br>магазин у дома", "Шаблоны вроде «второй и четвёртый вторник»"),
        ("05-share.png", "dark", "Рассказать о выходном<br>одной карточкой", "Сразу сообщите семье и соседям"),
    ],
    "zh-Hans": [
        ("01-main.png", "hero-bleed", "出门之前，<br>只要 3 秒", "今天营业与否，一眼看清"),
        ("02-calendar.png", "left-text", "本月休业日<br>一眼看清", "日历上只标出店铺休息的日子"),
        ("03-marts.png", "text-bottom", "只选你常去的店铺", "大型超市、Costco、节假日休业都有"),
        ("04-pattern.png", "flat-rotate", "附近的小店<br>也能自己添加", "像“每月第二、第四个周二”这样的规律也行"),
        ("05-share.png", "dark", "休业消息，<br>一张卡片搞定", "马上告诉家人和邻居"),
    ],
    "zh-Hant": [
        ("01-main.png", "hero-bleed", "出門之前，<br>只要 3 秒", "今天營業與否，一眼看清"),
        ("02-calendar.png", "left-text", "本月公休日<br>一眼看清", "行事曆上只標出店家休息的日子"),
        ("03-marts.png", "text-bottom", "只選你常去的店家", "大型超市、Costco、連假公休都有"),
        ("04-pattern.png", "flat-rotate", "附近的小店<br>也能自己新增", "像「每月第二、第四個週二」這樣的規律也行"),
        ("05-share.png", "dark", "公休消息，<br>一張卡片搞定", "馬上告訴家人與鄰居"),
    ],
    "es": [
        ("01-main.png", "hero-bleed", "Comprueba<br>antes de ir", "Mira de un vistazo si la tienda abre hoy"),
        ("02-calendar.png", "left-text", "Los cierres<br>de este mes", "Todos los días de cierre, en el calendario"),
        ("03-marts.png", "text-bottom", "Solo tus tiendas", "Supermercados, Costco y cierres por festivos"),
        ("04-pattern.png", "flat-rotate", "Añade tu tienda<br>de barrio", "Patrones como el segundo y el cuarto martes"),
        ("05-share.png", "dark", "Comparte un cierre<br>en una tarjeta", "Avisa a tu familia y a tus vecinos"),
    ],
    "de": [
        ("01-main.png", "hero-bleed", "Vorher prüfen,<br>dann losgehen", "Sieh auf einen Blick, ob der Markt offen ist"),
        ("02-calendar.png", "left-text", "Die Schließtage<br>dieses Monats", "Jeder Schließtag direkt im Kalender"),
        ("03-marts.png", "text-bottom", "Nur deine Märkte", "Supermärkte, Costco, Feiertagsschließungen"),
        ("04-pattern.png", "flat-rotate", "Füge deinen<br>Markt um die Ecke hinzu", "Muster wie zweiter und vierter Dienstag"),
        ("05-share.png", "dark", "Schließung teilen<br>mit einer Karte", "Sag Familie und Nachbarn Bescheid"),
    ],
    "fr": [
        ("01-main.png", "hero-bleed", "Vérifiez<br>avant de partir", "Voyez d’un coup d’œil si le magasin est ouvert"),
        ("02-calendar.png", "left-text", "Les fermetures<br>de ce mois", "Chaque jour de fermeture, dans le calendrier"),
        ("03-marts.png", "text-bottom", "Seulement vos magasins", "Supermarchés, Costco, fermetures des jours fériés"),
        ("04-pattern.png", "flat-rotate", "Ajoutez votre<br>magasin de quartier", "Des rythmes comme les 2e et 4e mardis"),
        ("05-share.png", "dark", "Annoncez une fermeture<br>en une carte", "Prévenez famille et voisins"),
    ],
    "it": [
        ("01-main.png", "hero-bleed", "Controlla<br>prima di uscire", "Vedi a colpo d’occhio se il negozio è aperto"),
        ("02-calendar.png", "left-text", "Le chiusure<br>di questo mese", "Ogni giorno di chiusura, nel calendario"),
        ("03-marts.png", "text-bottom", "Solo i tuoi negozi", "Supermercati, Costco, chiusure festive"),
        ("04-pattern.png", "flat-rotate", "Aggiungi il tuo<br>negozio di quartiere", "Schemi come il secondo e il quarto martedì"),
        ("05-share.png", "dark", "Condividi una chiusura<br>in una scheda", "Avvisa famiglia e vicini"),
    ],
    "pt-BR": [
        ("01-main.png", "hero-bleed", "Confira<br>antes de ir", "Veja num relance se a loja abre hoje"),
        ("02-calendar.png", "left-text", "Os fechamentos<br>deste mês", "Todos os dias de fechamento, no calendário"),
        ("03-marts.png", "text-bottom", "Só as suas lojas", "Supermercados, Costco, fechamentos em feriados"),
        ("04-pattern.png", "flat-rotate", "Adicione a loja<br>do seu bairro", "Padrões como a 2ª e a 4ª terça-feira"),
        ("05-share.png", "dark", "Avise sobre um fechamento<br>em um cartão", "Avise família e vizinhos"),
    ],
    "th": [
        ("01-main.png", "hero-bleed", "เช็กก่อนไป<br>แค่ 3 วินาที", "ดูได้ทันทีว่าวันนี้ร้านเปิดหรือไม่"),
        ("02-calendar.png", "left-text", "วันปิดของ<br>เดือนนี้ในที่เดียว", "ทุกวันปิดอยู่บนปฏิทิน"),
        ("03-marts.png", "text-bottom", "เลือกเฉพาะร้านที่คุณไป", "ซูเปอร์มาร์เก็ต Costco และวันหยุดเทศกาล"),
        ("04-pattern.png", "flat-rotate", "เพิ่มร้านในละแวกบ้าน<br>ด้วยตัวเอง", "รูปแบบอย่างวันอังคารที่สองและสี่ก็ทำได้"),
        ("05-share.png", "dark", "แจ้งร้านปิด<br>ด้วยการ์ดใบเดียว", "บอกครอบครัวและเพื่อนบ้านได้ทันที"),
    ],
    "vi": [
        ("01-main.png", "hero-bleed", "Kiểm tra<br>trước khi đi", "Xem ngay cửa hàng hôm nay có mở không"),
        ("02-calendar.png", "left-text", "Ngày đóng cửa<br>của tháng này", "Mọi ngày đóng cửa ngay trên lịch"),
        ("03-marts.png", "text-bottom", "Chỉ chọn cửa hàng bạn đi", "Siêu thị, Costco, ngày nghỉ lễ"),
        ("04-pattern.png", "flat-rotate", "Tự thêm cửa hàng<br>gần nhà", "Cả lịch như thứ Ba thứ hai và thứ tư"),
        ("05-share.png", "dark", "Báo tin đóng cửa<br>bằng một tấm thẻ", "Cho gia đình và hàng xóm biết ngay"),
    ],
    "cs": [
        ("01-main.png", "hero-bleed", "Zkontrolujte<br>před cestou", "Jedním pohledem uvidíte, jestli je obchod otevřený"),
        ("02-calendar.png", "left-text", "Dny zavření<br>tohoto měsíce", "Každý den zavření přímo v kalendáři"),
        ("03-marts.png", "text-bottom", "Jen vaše obchody", "Supermarkety, Costco, zavření o svátcích"),
        ("04-pattern.png", "flat-rotate", "Přidejte svůj<br>obchod z okolí", "Vzorce jako druhé a čtvrté úterý"),
        ("05-share.png", "dark", "Oznamte zavření<br>jednou kartou", "Dejte vědět rodině i sousedům"),
    ],
    "da": [
        ("01-main.png", "hero-bleed", "Tjek,<br>før du tager af sted", "Se med et blik, om butikken har åbent i dag"),
        ("02-calendar.png", "left-text", "Denne måneds<br>lukkedage", "Alle lukkedage lige i kalenderen"),
        ("03-marts.png", "text-bottom", "Kun dine butikker", "Supermarkeder, Costco, helligdagslukninger"),
        ("04-pattern.png", "flat-rotate", "Tilføj din<br>lokale butik", "Mønstre som anden og fjerde tirsdag"),
        ("05-share.png", "dark", "Del en lukning<br>på ét kort", "Giv familie og naboer besked"),
    ],
    "el": [
        ("01-main.png", "hero-bleed", "Ελέγξτε<br>πριν βγείτε", "Δείτε με μια ματιά αν το κατάστημα είναι ανοιχτό"),
        ("02-calendar.png", "left-text", "Τα κλεισίματα<br>του μήνα", "Κάθε ημέρα κλεισίματος στο ημερολόγιο"),
        ("03-marts.png", "text-bottom", "Μόνο τα δικά σας καταστήματα", "Σούπερ μάρκετ, Costco, κλεισίματα αργιών"),
        ("04-pattern.png", "flat-rotate", "Προσθέστε το<br>κατάστημα της γειτονιάς", "Προγράμματα όπως η δεύτερη και τέταρτη Τρίτη"),
        ("05-share.png", "dark", "Ανακοινώστε ένα κλείσιμο<br>με μία κάρτα", "Ενημερώστε οικογένεια και γείτονες"),
    ],
    "fi": [
        ("01-main.png", "hero-bleed", "Tarkista<br>ennen lähtöä", "Näe yhdellä silmäyksellä, onko kauppa auki"),
        ("02-calendar.png", "left-text", "Tämän kuun<br>sulkupäivät", "Kaikki sulkupäivät suoraan kalenterissa"),
        ("03-marts.png", "text-bottom", "Vain omat kauppasi", "Supermarketit, Costco, pyhäpäivien sulkemiset"),
        ("04-pattern.png", "flat-rotate", "Lisää oman<br>naapurustosi kauppa", "Kaavat kuten toinen ja neljäs tiistai"),
        ("05-share.png", "dark", "Kerro sulkemisesta<br>yhdellä kortilla", "Kerro perheelle ja naapureille"),
    ],
    "id": [
        ("01-main.png", "hero-bleed", "Cek dulu<br>sebelum pergi", "Lihat sekilas apakah tokonya buka hari ini"),
        ("02-calendar.png", "left-text", "Hari tutup<br>bulan ini", "Semua hari tutup langsung di kalender"),
        ("03-marts.png", "text-bottom", "Hanya toko yang kamu tuju", "Supermarket, Costco, tutup di hari libur"),
        ("04-pattern.png", "flat-rotate", "Tambahkan toko<br>di sekitarmu", "Pola seperti Selasa kedua dan keempat"),
        ("05-share.png", "dark", "Kabari hari tutup<br>dengan satu kartu", "Beri tahu keluarga dan tetangga"),
    ],
    "nb": [
        ("01-main.png", "hero-bleed", "Sjekk<br>før du drar", "Se med et blikk om butikken har åpent i dag"),
        ("02-calendar.png", "left-text", "Månedens<br>stengedager", "Alle stengedager rett i kalenderen"),
        ("03-marts.png", "text-bottom", "Bare butikkene dine", "Supermarkeder, Costco, stengt på helligdager"),
        ("04-pattern.png", "flat-rotate", "Legg til din<br>lokale butikk", "Mønstre som andre og fjerde tirsdag"),
        ("05-share.png", "dark", "Del en stenging<br>med ett kort", "Gi familie og naboer beskjed"),
    ],
    "nl": [
        ("01-main.png", "hero-bleed", "Check het<br>voordat je gaat", "Zie in één oogopslag of de winkel open is"),
        ("02-calendar.png", "left-text", "De sluitingen<br>van deze maand", "Elke sluitingsdag direct in de kalender"),
        ("03-marts.png", "text-bottom", "Alleen jouw winkels", "Supermarkten, Costco, sluitingen op feestdagen"),
        ("04-pattern.png", "flat-rotate", "Voeg je winkel<br>om de hoek toe", "Patronen zoals de tweede en vierde dinsdag"),
        ("05-share.png", "dark", "Deel een sluiting<br>met één kaart", "Laat familie en buren het weten"),
    ],
    "pl": [
        ("01-main.png", "hero-bleed", "Sprawdź<br>przed wyjściem", "Od razu zobacz, czy sklep jest dziś otwarty"),
        ("02-calendar.png", "left-text", "Zamknięcia<br>tego miesiąca", "Wszystkie dni zamknięcia w kalendarzu"),
        ("03-marts.png", "text-bottom", "Tylko Twoje sklepy", "Supermarkety, Costco, zamknięcia w święta"),
        ("04-pattern.png", "flat-rotate", "Dodaj swój<br>sklep z okolicy", "Wzory jak drugi i czwarty wtorek"),
        ("05-share.png", "dark", "Poinformuj o zamknięciu<br>jedną kartą", "Daj znać rodzinie i sąsiadom"),
    ],
    "sv": [
        ("01-main.png", "hero-bleed", "Kolla<br>innan du åker", "Se med en blick om butiken har öppet i dag"),
        ("02-calendar.png", "left-text", "Månadens<br>stängningsdagar", "Alla stängningsdagar direkt i kalendern"),
        ("03-marts.png", "text-bottom", "Bara dina butiker", "Stormarknader, Costco, stängt på helgdagar"),
        ("04-pattern.png", "flat-rotate", "Lägg till din<br>butik runt hörnet", "Mönster som andra och fjärde tisdagen"),
        ("05-share.png", "dark", "Dela en stängning<br>med ett kort", "Berätta för familj och grannar"),
    ],
    "tr": [
        ("01-main.png", "hero-bleed", "Gitmeden önce<br>kontrol et", "Mağazanın bugün açık olup olmadığını bir bakışta gör"),
        ("02-calendar.png", "left-text", "Bu ayın<br>kapalı günleri", "Tüm kapalı günler doğrudan takvimde"),
        ("03-marts.png", "text-bottom", "Yalnızca senin mağazaların", "Süpermarketler, Costco, tatil kapanışları"),
        ("04-pattern.png", "flat-rotate", "Mahalle mağazanı<br>kendin ekle", "İkinci ve dördüncü salı gibi düzenler"),
        ("05-share.png", "dark", "Kapanışı tek kartla<br>duyur", "Aileni ve komşularını hemen haberdar et"),
    ],
}

BASE_CSS = f"""
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:#f6f5f3; font-family:-apple-system, "Apple SD Gothic Neo", "Helvetica Neue", sans-serif;
  position:relative; }}
.headline {{ font-size:96px; font-weight:800; color:#141416; letter-spacing:-2px; line-height:1.22; }}
.sub {{ font-size:48px; font-weight:500; color:#9a9aa0; letter-spacing:-1px; }}
.phone {{ background:#17171a; border-radius:112px; border:3px solid #3a3a3e; padding:24px;
  box-shadow: 58px 86px 116px rgba(0,0,0,.28), 20px 30px 50px rgba(0,0,0,.18); }}
.phone img {{ width:100%; display:block; border-radius:89px; }}
"""

LAYOUTS = {
    # 1) 정면 대형, 하단 블리드
    "hero-bleed": """
.headline { text-align:center; margin-top:230px; padding:0 70px; }
.sub { text-align:center; margin-top:48px; }
.wrap { display:flex; justify-content:center; margin-top:150px; }
.phone { width:930px; }
""",
    # 2) 좌측 정렬 텍스트 + 오른쪽으로 기운 폰
    "left-text": """
.headline { text-align:left; margin:250px 0 0 100px; }
.sub { text-align:left; margin:44px 0 0 104px; }
.wrap { perspective:2600px; perspective-origin:30% 30%; position:absolute; left:250px; top:790px; }
.phone { width:880px; transform:rotateY(16deg) rotateX(2deg); }
""",
    # 3) 폰 상단, 텍스트 하단
    "text-bottom": """
.wrap { perspective:2800px; perspective-origin:50% 40%; display:flex; justify-content:center; margin-top:150px; }
.phone { width:830px; transform:rotateY(-10deg) rotateX(2deg); }
.headline { text-align:center; margin-top:110px; padding:0 70px; }
.sub { text-align:center; margin-top:44px; }
""",
    # 4) 평면 회전 + 하단 블리드
    "flat-rotate": """
.headline { text-align:center; margin-top:220px; padding:0 70px; }
.sub { text-align:center; margin-top:48px; }
.wrap { position:absolute; left:100px; top:880px; }
.phone { width:980px; transform:rotate(-6deg); }
""",
    # 5) 다크 배경 반전 (마지막 장 포인트)
    "dark": """
body { background:#131316; }
.headline { color:#f5f5f7; text-align:center; margin-top:230px; padding:0 70px; }
.sub { color:#77777d; text-align:center; margin-top:48px; }
.wrap { display:flex; justify-content:center; margin-top:140px; }
.phone { width:880px; border-color:#48484e;
  box-shadow: 0 0 160px rgba(255,90,120,.22), 40px 70px 110px rgba(0,0,0,.55); }
""",
}

BODY_TEXT_FIRST = ('<div class="headline">{headline}</div><div class="sub">{sub}</div>'
                   '<div class="wrap"><div class="phone"><img src="{img}"></div></div>')
BODY_PHONE_FIRST = ('<div class="wrap"><div class="phone"><img src="{img}"></div></div>'
                    '<div class="headline">{headline}</div><div class="sub">{sub}</div>')

HTML = """<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>
{base}{layout}
</style></head><body>{body}</body></html>"""


def render(locale):
    out_dir = OUT / locale
    out_dir.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    for fname, layout, headline, sub in SHOTS[locale]:
        src = RAW / locale / fname
        if not src.exists():
            raise SystemExit(f"원본 스크린샷이 없습니다: {src}")
        body_tpl = BODY_PHONE_FIRST if layout == "text-bottom" else BODY_TEXT_FIRST
        body = body_tpl.format(headline=headline, sub=sub, img=src.as_uri())
        html_path = WORK / f"{locale}-{fname.replace('.png', '.html')}"
        html_path.write_text(HTML.format(lang=locale, base=BASE_CSS, layout=LAYOUTS[layout], body=body), encoding="utf-8")
        out_png = out_dir / fname
        subprocess.run([CHROME, "--headless=new", f"--screenshot={out_png}",
                        f"--window-size={W},{H}", "--force-device-scale-factor=1",
                        "--hide-scrollbars", "--disable-gpu", f"--user-data-dir={PROFILE}",
                        "--allow-file-access-from-files", html_path.as_uri()],
                       check=True, capture_output=True, timeout=120)
        time.sleep(2)   # 한 Mac 을 여럿이 쓴다 — 렌더 사이를 띄운다
        print(f"rendered {out_png}")


if __name__ == "__main__":
    targets = sys.argv[1:] or list(SHOTS)
    for loc in targets:
        render(loc)

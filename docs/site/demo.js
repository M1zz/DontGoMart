// 돈꼬마트 웹 체험: 매장을 고르면 오늘 영업하는지, 다음 휴무일, 한 달 달력을 보여 준다.
// 규칙은 앱과 같다: DontGoMartApp.builtInMartRules (그달의 n번째 요일) + ClosureRuleEngine.
// 날짜는 앱처럼 이 기기의 달력(오늘 날짜)을 쓴다.
(() => {
  const root = document.getElementById("demo");
  if (!root) return;
  const T = JSON.parse(root.dataset.text);
  const lang = document.documentElement.lang;

  // [이름 순서는 T.marts 와 같다] 요일: 0=일 … 6=토, weeks: 그달 몇 번째 그 요일인지
  const RULES = [
    [[[2, 4], 0]],            // 대형마트 (일요일 휴무)
    [[[2, 4], 3]],            // 대형마트 (수요일 휴무)
    [[[2], 3], [[4], 0]],     // 대형마트 (울산)
    [[[2], 5], [[4], 6]],     // 대형마트 (제주)
    [[[2, 4], 0]],            // 코스트코 일반 매장
    [[[2, 4], 1]],            // 코스트코 대구점
    [[[2, 4], 3]],            // 코스트코 일산점
    [[[2], 3], [[4], 0]],     // 코스트코 울산점
  ];

  const today = new Date(); today.setHours(0, 0, 0, 0);
  const state = { mart: 0, y: today.getFullYear(), m: today.getMonth() };

  function closedDays(rules, y, m) {
    const days = new Set(), last = new Date(y, m + 1, 0).getDate();
    for (const [weeks, wd] of rules) {
      const hits = [];
      for (let d = 1; d <= last; d++) if (new Date(y, m, d).getDay() === wd) hits.push(d);
      weeks.forEach(w => w <= hits.length && days.add(hits[w - 1]));
    }
    return days;
  }
  function nextClosed(rules) {
    for (let i = 0; i < 3; i++) {
      const y = today.getFullYear(), m = today.getMonth() + i;
      const ds = [...closedDays(rules, y, m)].sort((a, b) => a - b);
      for (const d of ds) { const dt = new Date(y, m, d); if (dt >= today) return dt; }
    }
  }

  const fmtLong = new Intl.DateTimeFormat(lang, { month: "long", day: "numeric", weekday: "short" });
  const fmtMonth = new Intl.DateTimeFormat(lang, { year: "numeric", month: "long" });
  const fmtWd = new Intl.DateTimeFormat(lang, { weekday: "narrow" });
  const wdNames = Array.from({ length: 7 }, (_, i) => fmtWd.format(new Date(2024, 0, 7 + i)));

  root.innerHTML = `
    <div class="mart-pick" role="radiogroup" aria-label="${T.pick}">
      ${T.marts.map((n, i) => `<button type="button" class="chip" role="radio" data-i="${i}">${n}</button>`).join("")}
    </div>
    <div class="mart-board">
      <div class="mart-status" aria-live="polite"><p class="small mart-q">${T.question}</p><p class="mart-big"></p><p class="mart-next"></p></div>
      <div class="mart-cal">
        <div class="mart-head">
          <button type="button" class="mart-nav" data-step="-1" aria-label="${T.prev}">‹</button>
          <strong class="mart-month"></strong>
          <button type="button" class="mart-nav" data-step="1" aria-label="${T.next}">›</button>
        </div>
        <div class="mart-grid"></div>
        <p class="small muted mart-legend"><i></i>${T.closed}</p>
      </div>
    </div>
    <p class="muted small">${T.note}</p>`;

  const $ = s => root.querySelector(s);
  const dday = n => n === 0 ? T.today : n === 1 ? T.tomorrow : `D-${n}`;

  function render() {
    const rules = RULES[state.mart];
    root.querySelectorAll("[data-i]").forEach(b => b.setAttribute("aria-checked", +b.dataset.i === state.mart));

    const shut = closedDays(rules, today.getFullYear(), today.getMonth()).has(today.getDate());
    const status = $(".mart-status");
    status.classList.toggle("shut", shut);
    $(".mart-big").textContent = shut ? T.closedToday : T.openToday;
    const nx = nextClosed(rules), n = Math.round((nx - today) / 864e5);
    $(".mart-next").innerHTML = `${T.nextLabel} <b>${dday(n)}</b> · ${fmtLong.format(nx)}`;

    const { y, m } = state, days = closedDays(rules, y, m);
    $(".mart-month").textContent = fmtMonth.format(new Date(y, m, 1));
    const lead = new Date(y, m, 1).getDay(), last = new Date(y, m + 1, 0).getDate();
    let cells = wdNames.map((w, i) => `<span class="wd${i ? "" : " sun"}" aria-hidden="true">${w}</span>`).join("");
    cells += "<span></span>".repeat(lead);
    for (let d = 1; d <= last; d++) {
      const dt = new Date(y, m, d), off = days.has(d), now = +dt === +today;
      cells += `<span class="day${off ? " off" : ""}${now ? " now" : ""}${dt.getDay() ? "" : " sun"}"${off ? ` aria-label="${d} ${T.closed}"` : ""}>${d}</span>`;
    }
    $(".mart-grid").innerHTML = cells;
  }

  root.addEventListener("click", e => {
    const pick = e.target.closest("[data-i]"), nav = e.target.closest("[data-step]");
    if (pick) { state.mart = +pick.dataset.i; state.y = today.getFullYear(); state.m = today.getMonth(); }
    if (nav) { const d = new Date(state.y, state.m + +nav.dataset.step, 1); state.y = d.getFullYear(); state.m = d.getMonth(); }
    if (pick || nav) render();
  });
  // 방향키로 매장을 옮긴다(라디오 묶음처럼).
  $(".mart-pick").addEventListener("keydown", e => {
    const step = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
    if (!step) return;
    e.preventDefault();
    state.mart = (state.mart + step + RULES.length) % RULES.length;
    render();
    root.querySelector(`[data-i="${state.mart}"]`).focus();
  });

  render();
})();

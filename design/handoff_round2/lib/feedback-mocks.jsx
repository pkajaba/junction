// feedback-mocks.jsx — five focused improvement mocks
// Mirrors the SHIPPED chrome (top tab bar, not sidebar).

// ─── Window chrome (top-tab variant) ────────────────────────
function FBWindow({ activeTab = 'Rules', children, width = 1000, height = 660 }) {
  const tabs = ['Rules', 'Browsers', 'Handoff', 'Advanced', 'Activity'];
  return (
    <div style={{
      width, height, borderRadius: 12, overflow: 'hidden',
      background: 'white', display: 'flex', flexDirection: 'column',
      boxShadow: '0 30px 70px rgba(0,0,0,.18), 0 0 0 0.5px rgba(0,0,0,.12)',
      fontFamily: JFONT,
      position: 'relative',
    }}>
      {/* Title bar with centered tabs */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '10px 14px', background: 'rgba(245,245,247,1)',
        borderBottom: '0.5px solid rgba(0,0,0,.08)', height: 42,
        position: 'relative',
      }}>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexShrink: 0 }}>
          <div style={{ width: 12, height: 12, borderRadius: 6, background: '#ff5f57', border: '0.5px solid rgba(0,0,0,.12)' }} />
          <div style={{ width: 12, height: 12, borderRadius: 6, background: '#febc2e', border: '0.5px solid rgba(0,0,0,.12)' }} />
          <div style={{ width: 12, height: 12, borderRadius: 6, background: '#28c840', border: '0.5px solid rgba(0,0,0,.12)' }} />
        </div>
        <div style={{ fontSize: 13, fontWeight: 600, color: 'rgba(0,0,0,.75)', marginLeft: 8 }}>
          Junction Settings
        </div>
        {/* Centered tabs */}
        <div style={{
          position: 'absolute', left: '50%', top: '50%',
          transform: 'translate(-50%, -50%)',
          display: 'inline-flex', alignItems: 'center', gap: 2,
          padding: 2, borderRadius: 8, background: 'rgba(0,0,0,.05)',
        }}>
          {tabs.map((t, i) => {
            const sel = t === activeTab;
            return (
              <React.Fragment key={t}>
                <div style={{
                  padding: '4px 14px', borderRadius: 6, fontSize: 13, fontWeight: 500,
                  background: sel ? JBRAND.accent : 'transparent',
                  color: sel ? 'white' : 'rgba(0,0,0,.75)',
                  boxShadow: sel ? '0 1px 2px rgba(0,0,0,.08)' : 'none',
                }}>{t}</div>
                {i < tabs.length - 1 && !sel && i + 1 < tabs.length && tabs[i + 1] !== activeTab && (
                  <div style={{ width: 0.5, height: 14, background: 'rgba(0,0,0,.12)' }} />
                )}
              </React.Fragment>
            );
          })}
        </div>
      </div>
      <div style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column', background: 'white' }}>
        {children}
      </div>
    </div>
  );
}

function fbBtn(extra) {
  return {
    display: 'inline-flex', alignItems: 'center', gap: 5,
    padding: '5px 10px', borderRadius: 7, border: '0.5px solid rgba(0,0,0,.15)',
    background: 'white', fontFamily: JFONT, fontSize: 12, fontWeight: 500,
    color: '#1a1a1a', cursor: 'pointer', boxShadow: '0 1px 0 rgba(0,0,0,.04)',
    ...extra,
  };
}
function fbBtnPrimary(extra) {
  return {
    display: 'inline-flex', alignItems: 'center', gap: 5,
    padding: '5px 12px', borderRadius: 7, border: 'none',
    background: JBRAND.accent, color: 'white',
    fontFamily: JFONT, fontSize: 12, fontWeight: 600, cursor: 'pointer',
    boxShadow: '0 1px 0 rgba(0,0,0,.1)',
    ...extra,
  };
}

// ─────────────────────────────────────────────────────────────
// MOCK 1 — Activity as rule-builder
// ─────────────────────────────────────────────────────────────
const ACTIVITY_ROWS = [
  {
    time: '14:32:08',
    host: 'github.com', path: '/mantyx-io/mantyx-platform',
    matched: { rule: 'Always github.com → Chrome', target: 'Chrome · Work' },
    fromApp: 'Slack',
  },
  {
    time: '14:31:42',
    host: 'oidc.us-east-1.amazonaws.com', path: '/authorize?response_type=code…',
    matched: { rule: 'Always oidc.us-east-1.amazonaws.com → Chrome', target: 'Chrome' },
    fromApp: 'Mail',
  },
  {
    time: '14:28:14',
    host: 'news.ycombinator.com', path: '/item?id=39842110',
    matched: { rule: 'mega.nz → Safari', target: 'Safari', stale: true },
    fromApp: 'Messages',
  },
  {
    time: '14:24:09',
    host: 'linear.app', path: '/junction/issue/JNC-42',
    matched: null, // no rule, picker fallback
    pickedManually: 'Chrome',
    fromApp: 'Slack',
  },
  {
    time: '14:18:39',
    host: 'figma.com', path: '/design/abc/Junction',
    matched: null,
    pickedManually: 'Chrome',
    fromApp: 'Notion',
    repeated: 3, // user has chosen Chrome 3 times for figma.com
  },
  {
    time: '14:11:02',
    host: 'mailto:hello@example.com', path: '',
    matched: null, status: 'unsupported',
    fromApp: 'Reminders',
  },
  {
    time: '13:58:21',
    host: 'stripe.com', path: '/pricing',
    rewritten: '?utm_source=newsletter stripped',
    matched: null,
    pickedManually: 'Safari',
    fromApp: 'Mail',
  },
];

function ActivityRebuild() {
  const [filter, setFilter] = React.useState('all');
  return (
    <FBWindow activeTab="Activity">
      <ActivityHeader filter={filter} setFilter={setFilter} />
      <div style={{ flex: 1, overflow: 'auto' }}>
        {ACTIVITY_ROWS.map((row, i) => (
          <ActivityRow key={i} row={row} hoveredIndex={i === 3 ? true : false} />
        ))}
      </div>
    </FBWindow>
  );
}

function ActivityHeader({ filter, setFilter }) {
  const counts = { all: 7, nomatch: 4, errors: 1 };
  const chips = [
    { id: 'all',     label: 'All',                count: counts.all },
    { id: 'matched', label: 'Matched a rule',     count: 3 },
    { id: 'nomatch', label: 'No rule · picker',   count: counts.nomatch, hint: true },
    { id: 'errors',  label: 'Errors',             count: counts.errors },
  ];
  return (
    <div style={{ padding: '16px 22px 12px', borderBottom: '0.5px solid rgba(0,0,0,.08)' }}>
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 12 }}>
        <div>
          <div style={{ fontSize: 20, fontWeight: 600, color: '#1a1a1a', letterSpacing: -0.3 }}>Activity</div>
          <div style={{ fontSize: 12.5, color: 'rgba(0,0,0,.55)', marginTop: 2 }}>
            Every link Junction has handled. Hover any row to make it into a rule.
          </div>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <button style={fbBtn()}>Export…</button>
          <button style={fbBtn({ color: 'rgba(0,0,0,.6)' })}>Clear</button>
        </div>
      </div>
      <div style={{ marginTop: 12, display: 'flex', gap: 6, alignItems: 'center' }}>
        {chips.map((c) => {
          const sel = c.id === filter;
          return (
            <div key={c.id} onClick={() => setFilter(c.id)} style={{
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '4px 10px', borderRadius: 14,
              background: sel ? JBRAND.accent : 'rgba(0,0,0,.045)',
              color: sel ? 'white' : 'rgba(0,0,0,.75)',
              fontSize: 12, fontWeight: 500, cursor: 'pointer',
              border: c.hint && !sel ? '0.5px solid rgba(245,166,35,.5)' : '0.5px solid transparent',
            }}>
              {c.hint && !sel && <div style={{
                width: 6, height: 6, borderRadius: 3, background: '#f5a623',
              }} />}
              {c.label}
              <span style={{
                fontVariantNumeric: 'tabular-nums', fontSize: 11,
                color: sel ? 'rgba(255,255,255,.8)' : 'rgba(0,0,0,.45)',
              }}>{c.count}</span>
            </div>
          );
        })}
        <div style={{ flex: 1 }} />
        <div style={{ fontSize: 11.5, color: 'rgba(0,0,0,.5)' }}>
          Last 24h · live
        </div>
      </div>
    </div>
  );
}

function ActivityRow({ row, hoveredIndex }) {
  const noMatch = !row.matched && row.status !== 'unsupported';
  const unsupported = row.status === 'unsupported';
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 14,
      padding: '12px 22px',
      borderBottom: '0.5px solid rgba(0,0,0,.05)',
      background: hoveredIndex ? 'rgba(30,109,255,.04)' : 'transparent',
      position: 'relative',
    }}>
      {/* Time */}
      <div style={{
        width: 60, flexShrink: 0, fontFamily: JMONO, fontSize: 11,
        color: 'rgba(0,0,0,.45)',
      }}>{row.time}</div>

      {/* URL */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {!unsupported && <HostGlyph host={row.host} size={14} />}
          {unsupported && (
            <span style={{
              width: 14, height: 14, borderRadius: 3, background: 'rgba(0,0,0,.1)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <SFIcon name="x" size={9} color="rgba(0,0,0,.5)" weight={2.2} />
            </span>
          )}
          <div style={{
            fontFamily: JMONO, fontSize: 12.5, color: '#1a1a1a',
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>
            <span style={{ color: '#1a1a1a', fontWeight: 600 }}>{row.host}</span>
            <span style={{ color: 'rgba(0,0,0,.45)' }}>{row.path}</span>
          </div>
        </div>
        <div style={{
          marginTop: 4, display: 'flex', alignItems: 'center', gap: 8,
          fontSize: 11, color: 'rgba(0,0,0,.55)',
        }}>
          <span>from <b style={{ fontWeight: 600, color: 'rgba(0,0,0,.7)' }}>{row.fromApp}</b></span>
          {row.rewritten && (
            <>
              <span>·</span>
              <span style={{ color: '#1f7a4a' }}>cleaned ({row.rewritten})</span>
            </>
          )}
          {row.repeated && (
            <>
              <span>·</span>
              <span style={{
                color: '#c2622e', fontWeight: 600,
                padding: '0 5px', borderRadius: 3, background: 'rgba(245,166,35,.14)',
              }}>
                {row.repeated}× this week → Chrome
              </span>
            </>
          )}
        </div>
      </div>

      {/* Outcome */}
      <div style={{ minWidth: 220, flexShrink: 0, display: 'flex',
        flexDirection: 'column', alignItems: 'flex-end', gap: 3 }}>
        {row.matched && (
          <>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
              <SFIcon name="check" size={11} color="#1f7a4a" weight={2.2} />
              <span style={{ fontSize: 12, fontWeight: 600, color: '#1a1a1a' }}>{row.matched.target}</span>
            </div>
            <div style={{ fontSize: 11, color: 'rgba(0,0,0,.55)', maxWidth: 220,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              via {row.matched.rule}
            </div>
          </>
        )}
        {noMatch && (
          <>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
              <span style={{
                width: 6, height: 6, borderRadius: 3, background: '#f5a623',
              }} />
              <span style={{ fontSize: 12, fontWeight: 600, color: '#1a1a1a' }}>
                {row.pickedManually} <span style={{ color: 'rgba(0,0,0,.5)', fontWeight: 400 }}>· picked manually</span>
              </span>
            </div>
            <div style={{ fontSize: 11, color: 'rgba(0,0,0,.55)' }}>
              no rule matched
            </div>
          </>
        )}
        {unsupported && (
          <>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
              <span style={{ fontSize: 12, fontWeight: 600, color: 'rgba(0,0,0,.55)' }}>
                Skipped
              </span>
            </div>
            <div style={{ fontSize: 11, color: 'rgba(0,0,0,.5)' }}>
              not an http(s) link
            </div>
          </>
        )}
      </div>

      {/* Hover action — only shown on the highlighted row */}
      {hoveredIndex && noMatch && (
        <div style={{
          display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4,
        }}>
          <button style={fbBtnPrimary({ padding: '6px 12px' })}>
            <SFIcon name="plus" size={11} color="white" /> Create rule…
          </button>
          <span style={{ fontSize: 10.5, color: 'rgba(0,0,0,.5)' }}>
            <KeyCap style={{ fontSize: 10 }}>⌘R</KeyCap>
          </span>
        </div>
      )}
      {!hoveredIndex && noMatch && (
        <div style={{ width: 110, flexShrink: 0, opacity: 0.0 }} />
      )}
      {(row.matched || unsupported) && (
        <div style={{ width: 110, flexShrink: 0 }} />
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// MOCK 2 — Rules sidebar header restructure
// ─────────────────────────────────────────────────────────────
function RulesHeaderRebuild() {
  return (
    <FBWindow activeTab="Rules">
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
        {/* Left rail */}
        <div style={{
          width: 320, flexShrink: 0,
          borderRight: '0.5px solid rgba(0,0,0,.08)',
          background: 'rgba(250,250,252,1)',
          display: 'flex', flexDirection: 'column',
        }}>
          {/* HEADER — what changed: + sits next to title; grouping is now a dropdown */}
          <div style={{ padding: '14px 14px 10px' }}>
            <div style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              gap: 8,
            }}>
              <div style={{ fontSize: 22, fontWeight: 600, color: '#1a1a1a', letterSpacing: -0.3 }}>
                Rules
              </div>
              <div style={{ display: 'flex', gap: 4 }}>
                <button title="Remove rule" style={iconCircleBtn()}>
                  <SFIcon name="minus" size={12} color="rgba(0,0,0,.65)" />
                </button>
                <button title="New rule" style={iconCircleBtn({
                  background: JBRAND.accent, border: 'none',
                })}>
                  <SFIcon name="plus" size={12} color="white" weight={2} />
                </button>
              </div>
            </div>

            {/* meta with grouping dropdown */}
            <div style={{
              marginTop: 4,
              display: 'flex', alignItems: 'center', gap: 6,
              fontSize: 11.5, color: 'rgba(0,0,0,.55)',
            }}>
              <span style={{ fontVariantNumeric: 'tabular-nums' }}>26 rules</span>
              <span>·</span>
              <span>grouped by</span>
              <span style={{
                display: 'inline-flex', alignItems: 'center', gap: 3,
                padding: '1px 5px 1px 6px', borderRadius: 4,
                background: 'rgba(0,0,0,.06)', color: '#1a1a1a', fontWeight: 500,
                cursor: 'pointer',
              }}>
                destination
                <SFIcon name="chevronDown" size={8} color="rgba(0,0,0,.55)" />
              </span>
            </div>

            {/* filter — now visually a peer of the title (not the only header element) */}
            <div style={{
              marginTop: 10, display: 'flex', alignItems: 'center', gap: 6,
              padding: '5px 8px', borderRadius: 7, background: 'rgba(0,0,0,.05)',
              border: '0.5px solid rgba(0,0,0,.06)',
            }}>
              <SFIcon name="search" size={11} color="rgba(0,0,0,.5)" />
              <input placeholder="Filter all rules" readOnly style={{
                border: 'none', outline: 'none', background: 'transparent',
                flex: 1, fontFamily: JFONT, fontSize: 12, color: 'rgba(0,0,0,.85)',
              }} />
              <KeyCap style={{ fontSize: 10 }}>⌘F</KeyCap>
            </div>
          </div>

          {/* Grouping dropdown OPEN (annotation) */}
          <div style={{
            position: 'absolute', marginTop: 0, marginLeft: 156, zIndex: 10,
            transform: 'translateY(50px)',
            background: 'white', borderRadius: 8,
            boxShadow: '0 6px 24px rgba(0,0,0,.18), 0 0 0 0.5px rgba(0,0,0,.12)',
            padding: 4, width: 160, fontSize: 12.5,
          }}>
            {[
              { label: 'Destination', sub: 'browser', sel: true },
              { label: 'Source app',  sub: 'Slack, Mail…' },
              { label: 'Match type',  sub: 'host / regex' },
              { label: 'Nothing',     sub: 'flat list' },
            ].map((opt, i) => (
              <div key={opt.label} style={{
                display: 'flex', alignItems: 'center', gap: 8,
                padding: '6px 8px', borderRadius: 5,
                background: opt.sel ? JBRAND.accent : 'transparent',
                color: opt.sel ? 'white' : '#1a1a1a',
              }}>
                {opt.sel && <SFIcon name="check" size={10} color="white" weight={2.2} />}
                {!opt.sel && <div style={{ width: 10 }} />}
                <div>
                  <div style={{ fontSize: 12.5, fontWeight: 500 }}>{opt.label}</div>
                  <div style={{ fontSize: 10.5,
                    color: opt.sel ? 'rgba(255,255,255,.7)' : 'rgba(0,0,0,.45)' }}>{opt.sub}</div>
                </div>
              </div>
            ))}
          </div>

          {/* Rule list — preview only, faded behind the dropdown */}
          <div style={{ flex: 1, overflow: 'auto', padding: '6px 0', opacity: 0.55 }}>
            <FBGroupHeader name="Chrome" count={12} />
            <FBRule name="Always github.com → Chrome" sub="github.com" target="chrome" />
            <FBRule name="Always oidc.us-east-1.amazonaws.com" sub="oidc.us-east-1.amazonaws.com" target="chrome" selected />
            <FBRule name="Work Google (vetrofibe…)" sub="contains: vetrofibermap" target="chrome" />
            <FBRule name="Work Google (pavel.kaj…)" sub="contains: pavel.kajaba" target="chrome" />
            <FBGroupHeader name="Safari" count={4} />
            <FBRule name="mega.nz → Safari" sub="mega.nz" target="safari" />
          </div>
        </div>

        {/* Right — editor surface (placeholder, dimmed) */}
        <div style={{ flex: 1, padding: '22px 26px', opacity: 0.18, pointerEvents: 'none' }}>
          <div style={{ fontSize: 19, fontWeight: 600, marginBottom: 12 }}>
            Always oidc.us-east-1.amazonaws.com → Google Chrome
          </div>
          <div style={{ height: 12 }} />
          <div style={{ height: 80, background: 'rgba(0,0,0,.04)', borderRadius: 10, marginBottom: 12 }} />
          <div style={{ height: 80, background: 'rgba(0,0,0,.04)', borderRadius: 10, marginBottom: 12 }} />
          <div style={{ height: 120, background: 'rgba(0,0,0,.04)', borderRadius: 10 }} />
        </div>

        {/* Annotation callouts */}
        <Callout x={170} y={70} text="+ moved to header — adding a rule is a primary action" />
        <Callout x={170} y={120} text="Grouping is now a dropdown — 4 options" />
      </div>
    </FBWindow>
  );
}

function iconCircleBtn(extra) {
  return {
    width: 22, height: 22, borderRadius: 11,
    background: 'white', border: '0.5px solid rgba(0,0,0,.15)',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    boxShadow: '0 1px 0 rgba(0,0,0,.04)', cursor: 'pointer',
    ...extra,
  };
}

function FBGroupHeader({ name, count }) {
  return (
    <div style={{
      padding: '8px 14px 4px',
      display: 'flex', alignItems: 'center', gap: 6,
      fontSize: 10.5, fontWeight: 700, color: 'rgba(0,0,0,.45)',
      textTransform: 'uppercase', letterSpacing: 0.6,
    }}>
      <BrowserIcon name={name.toLowerCase()} size={12} />
      <span style={{ color: 'rgba(0,0,0,.55)' }}>{name}</span>
      <span style={{ color: 'rgba(0,0,0,.35)', fontVariantNumeric: 'tabular-nums' }}>{count}</span>
    </div>
  );
}

function FBRule({ name, sub, target, selected }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8, padding: '7px 12px',
      margin: '0 6px', borderRadius: 6,
      background: selected ? JBRAND.accent : 'transparent',
      color: selected ? 'white' : 'inherit',
    }}>
      <div style={{ width: 6, height: 6, borderRadius: 3,
        background: selected ? 'white' : '#34a853' }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 12.5, fontWeight: 500,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          color: selected ? 'white' : '#1a1a1a' }}>{name}</div>
        <div style={{ fontSize: 10.5, fontFamily: JMONO,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          color: selected ? 'rgba(255,255,255,.7)' : 'rgba(0,0,0,.5)' }}>{sub}</div>
      </div>
      <BrowserIcon name={target} size={14} />
    </div>
  );
}

function Callout({ x, y, text, w = 230 }) {
  return (
    <div style={{
      position: 'absolute', left: x, top: y, width: w,
      pointerEvents: 'none', zIndex: 30,
      display: 'flex', alignItems: 'flex-start', gap: 8,
    }}>
      <div style={{
        width: 18, height: 18, borderRadius: 9, flexShrink: 0,
        background: '#1e6dff', color: 'white',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 10, fontWeight: 700,
      }}>→</div>
      <div style={{
        padding: '6px 10px', borderRadius: 8,
        background: '#1e1e1e', color: 'white',
        fontSize: 11.5, lineHeight: 1.4, fontWeight: 500,
        boxShadow: '0 6px 18px rgba(0,0,0,.25)',
      }}>{text}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// MOCK 3 — Handoff with proper disabled states
// ─────────────────────────────────────────────────────────────
const HANDOFF_APPS = [
  { name: 'Zoom',            pattern: '*.zoom.us/j/...',         installed: true,  on: true,  iconBg: '#2d8cff', glyph: 'Z' },
  { name: 'Microsoft Teams', pattern: 'teams.microsoft.com/...', installed: false, iconBg: '#5059c9', glyph: 'T' },
  { name: 'Slack',           pattern: 'app.slack.com/client/...', installed: true, on: true,  iconBg: '#4a154b', glyph: 'S' },
  { name: 'Notion',          pattern: 'notion.so/...',           installed: false, iconBg: '#000',    glyph: 'N' },
  { name: 'Linear',          pattern: 'linear.app/...',          installed: false, iconBg: '#5e6ad2', glyph: 'L' },
  { name: 'Spotify',         pattern: 'open.spotify.com/track/...', installed: true, on: true, iconBg: '#1ed760', glyph: '♪' },
  { name: 'Discord',         pattern: 'discord.com/channels/...', installed: true, on: true,  iconBg: '#5865f2', glyph: 'D' },
];

function HandoffRebuild() {
  return (
    <FBWindow activeTab="Handoff">
      <div style={{ padding: '20px 24px', borderBottom: '0.5px solid rgba(0,0,0,.08)' }}>
        <div style={{ fontSize: 20, fontWeight: 600, color: '#1a1a1a', letterSpacing: -0.3 }}>Handoff</div>
        <div style={{ fontSize: 12.5, color: 'rgba(0,0,0,.55)', marginTop: 3, maxWidth: 600 }}>
          Send specific links straight to a native app instead of a browser. Handoff takes priority over your rules.
        </div>
      </div>
      <div style={{ flex: 1, overflow: 'auto', padding: '16px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          padding: '0 4px 8px' }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: 'rgba(0,0,0,.65)',
            textTransform: 'uppercase', letterSpacing: 0.4 }}>Hand off to native apps</div>
          <div style={{ fontSize: 11.5, color: 'rgba(0,0,0,.45)' }}>
            4 installed · 3 available
          </div>
        </div>
        <div style={{
          background: 'rgba(0,0,0,.025)', borderRadius: 12,
          border: '0.5px solid rgba(0,0,0,.06)', overflow: 'hidden',
        }}>
          {HANDOFF_APPS.map((app, i) => (
            <HandoffRow key={app.name} app={app} last={i === HANDOFF_APPS.length - 1} />
          ))}
        </div>
        {/* Removed footer hint — UI now self-explains */}
      </div>
    </FBWindow>
  );
}

function HandoffRow({ app, last }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '12px 14px',
      borderBottom: last ? 'none' : '0.5px solid rgba(0,0,0,.06)',
      opacity: app.installed ? 1 : 0.55,
      background: 'white',
    }}>
      <div style={{
        width: 28, height: 28, borderRadius: 7,
        background: app.installed ? app.iconBg : 'rgba(0,0,0,.08)',
        color: 'white',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontWeight: 700, fontSize: 14, flexShrink: 0,
        border: app.installed ? 'none' : '1px dashed rgba(0,0,0,.25)',
        boxShadow: app.installed ? '0 1px 2px rgba(0,0,0,.1)' : 'none',
      }}>
        {app.installed ? app.glyph : ''}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color: '#1a1a1a' }}>{app.name}</div>
        <div style={{ fontSize: 11.5, fontFamily: JMONO, color: 'rgba(0,0,0,.5)', marginTop: 1 }}>
          {app.pattern}
        </div>
      </div>
      {app.installed ? (
        <MacToggle on={app.on} size={0.85} />
      ) : (
        <button style={{
          display: 'inline-flex', alignItems: 'center', gap: 5,
          padding: '5px 11px', borderRadius: 6,
          background: 'rgba(0,0,0,.04)', color: 'rgba(0,0,0,.65)',
          border: '0.5px solid rgba(0,0,0,.12)',
          fontFamily: JFONT, fontSize: 11.5, fontWeight: 600,
          cursor: 'pointer', opacity: 1,
        }}>
          Not installed
          <SFIcon name="arrowDownRight" size={10} color="rgba(0,0,0,.5)" />
        </button>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// MOCK 4 — Browsers tab with proper empty space
// ─────────────────────────────────────────────────────────────
function BrowsersRebuild() {
  const browsers = [
    { name: 'Safari', bundle: 'com.apple.Safari', icon: 'safari', on: true, isDefault: true },
    { name: 'Google Chrome', bundle: 'com.google.Chrome', icon: 'chrome', on: true },
  ];
  return (
    <FBWindow activeTab="Browsers">
      <div style={{ padding: '20px 24px', borderBottom: '0.5px solid rgba(0,0,0,.08)',
        display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
        <div>
          <div style={{ fontSize: 20, fontWeight: 600, color: '#1a1a1a', letterSpacing: -0.3 }}>Browsers</div>
          <div style={{ fontSize: 12.5, color: 'rgba(0,0,0,.55)', marginTop: 3, maxWidth: 600 }}>
            Toggle which browsers appear in the picker. Hidden browsers can still be rule targets — they just won't clutter the picker for unmatched URLs.
          </div>
        </div>
        <button style={fbBtn()}>
          <SFIcon name="arrowDownRight" size={11} /> Refresh
        </button>
      </div>
      <div style={{ flex: 1, overflow: 'auto', padding: '16px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          padding: '0 4px 8px' }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: 'rgba(0,0,0,.65)',
            textTransform: 'uppercase', letterSpacing: 0.4 }}>Detected on this Mac</div>
          <div style={{ fontSize: 11.5, color: 'rgba(0,0,0,.45)' }}>2 browsers</div>
        </div>
        <div style={{
          background: 'rgba(0,0,0,.025)', borderRadius: 12,
          border: '0.5px solid rgba(0,0,0,.06)', overflow: 'hidden',
        }}>
          {browsers.map((b, i) => (
            <div key={b.bundle} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px',
              borderBottom: i < browsers.length - 1 ? '0.5px solid rgba(0,0,0,.06)' : 'none',
              background: 'white',
            }}>
              <BrowserIcon name={b.icon} size={28} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                  <div style={{ fontSize: 13.5, fontWeight: 600, color: '#1a1a1a' }}>{b.name}</div>
                  {b.isDefault && (
                    <span style={{
                      fontSize: 10, fontWeight: 700, color: JBRAND.accent,
                      padding: '1px 5px', borderRadius: 3,
                      background: 'rgba(30,109,255,.1)',
                      textTransform: 'uppercase', letterSpacing: 0.4,
                    }}>System default</span>
                  )}
                </div>
                <div style={{ fontSize: 11.5, fontFamily: JMONO, color: 'rgba(0,0,0,.5)', marginTop: 1 }}>
                  {b.bundle}
                </div>
              </div>
              <MacToggle on={b.on} size={0.85} />
            </div>
          ))}
        </div>

        {/* Proper empty state instead of phantom rows */}
        <div style={{
          marginTop: 18,
          padding: '20px 16px',
          borderRadius: 12,
          border: '1px dashed rgba(0,0,0,.18)',
          background: 'transparent',
          display: 'flex', alignItems: 'center', gap: 14,
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 8,
            background: 'rgba(0,0,0,.04)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: 'rgba(0,0,0,.4)', flexShrink: 0,
          }}>
            <SFIcon name="folderBadge" size={18} color="rgba(0,0,0,.5)" />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>
              That's everything Junction found.
            </div>
            <div style={{ fontSize: 12, color: 'rgba(0,0,0,.55)', marginTop: 2, lineHeight: 1.45 }}>
              Junction scans <code style={{ fontFamily: JMONO, fontSize: 11 }}>/Applications</code> and <code style={{ fontFamily: JMONO, fontSize: 11 }}>~/Applications</code>. Install another browser, then click Refresh — or add one by bundle ID.
            </div>
          </div>
          <button style={fbBtn()}>
            <SFIcon name="plus" size={11} /> Add manually
          </button>
        </div>
      </div>
    </FBWindow>
  );
}

// ─────────────────────────────────────────────────────────────
// MOCK 5 — Advanced restructured (toggle as headline)
// ─────────────────────────────────────────────────────────────
const TRACKING_PARAMS = ['_ga', '_hsenc', '_hsmi', 'dclid', 'fbclid', 'gbraid', 'gclid', 'mc_eid', 'mc_cid', 'utm_*', 'wbraid'];

function AdvancedRebuild() {
  return (
    <FBWindow activeTab="Advanced">
      <div style={{ padding: '20px 24px', borderBottom: '0.5px solid rgba(0,0,0,.08)' }}>
        <div style={{ fontSize: 20, fontWeight: 600, color: '#1a1a1a', letterSpacing: -0.3 }}>Advanced</div>
        <div style={{ fontSize: 12.5, color: 'rgba(0,0,0,.55)', marginTop: 3, maxWidth: 600 }}>
          URL rewriting runs before rule matching, so cleaned URLs are what your rules see.
        </div>
      </div>
      <div style={{ flex: 1, overflow: 'auto', padding: '20px 24px' }}>
        {/* Appearance — compact, top */}
        <SectionTitle>Appearance</SectionTitle>
        <Card>
          <Row label="Theme" hint='"System" follows macOS. Light and Dark override it for Junction only.'>
            <Segmented2 value="system" options={[
              { id: 'system', label: 'System' },
              { id: 'light', label: 'Light' },
              { id: 'dark', label: 'Dark' },
            ]} />
          </Row>
        </Card>

        <div style={{ height: 18 }} />

        {/* Tracking section — toggle is the SECTION header, list is indented config */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          marginBottom: 8, padding: '0 2px',
        }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>
              Strip tracking parameters
            </div>
            <div style={{ fontSize: 12, color: 'rgba(0,0,0,.55)', marginTop: 2 }}>
              Removes <code style={{ fontFamily: JMONO, fontSize: 11 }}>utm_*</code>, <code style={{ fontFamily: JMONO, fontSize: 11 }}>fbclid</code>, <code style={{ fontFamily: JMONO, fontSize: 11 }}>gclid</code>, and other tracking-only params before the URL hits a rule.
            </div>
          </div>
          <MacToggle on={true} />
        </div>

        {/* Indented list under the toggle */}
        <div style={{
          marginLeft: 0,
          padding: 4,
          background: 'rgba(0,0,0,.025)',
          borderRadius: 12,
          border: '0.5px solid rgba(0,0,0,.06)',
        }}>
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            padding: '6px 12px 4px',
          }}>
            <div style={{
              fontSize: 11, fontWeight: 600, color: 'rgba(0,0,0,.6)',
              textTransform: 'uppercase', letterSpacing: 0.4,
            }}>
              Parameters to strip
            </div>
            <div style={{ fontSize: 11, color: 'rgba(0,0,0,.45)' }}>
              {TRACKING_PARAMS.length} params · matched against query string
            </div>
          </div>
          <div style={{
            background: 'white', borderRadius: 9, margin: 4,
            border: '0.5px solid rgba(0,0,0,.06)', overflow: 'hidden',
          }}>
            {TRACKING_PARAMS.slice(0, 8).map((p, i) => (
              <div key={p} style={{
                display: 'flex', alignItems: 'center',
                padding: '8px 12px',
                borderBottom: i < 7 ? '0.5px solid rgba(0,0,0,.05)' : 'none',
              }}>
                <div style={{ flex: 1, fontFamily: JMONO, fontSize: 12.5, color: '#1a1a1a' }}>
                  {p}
                </div>
                <button style={iconCircleBtn({ width: 20, height: 20 })} title="Remove">
                  <SFIcon name="minus" size={10} color="rgba(0,0,0,.55)" weight={2} />
                </button>
              </div>
            ))}
            {/* Add input — first-class affordance */}
            <div style={{
              display: 'flex', alignItems: 'center', gap: 8,
              padding: '8px 12px', borderTop: '0.5px solid rgba(0,0,0,.05)',
              background: 'rgba(30,109,255,.04)',
            }}>
              <SFIcon name="plus" size={11} color={JBRAND.accent} weight={2.2} />
              <input
                placeholder="Add a parameter… (e.g. ref, source_id, *_token)"
                readOnly
                style={{
                  flex: 1, border: 'none', outline: 'none', background: 'transparent',
                  fontFamily: JMONO, fontSize: 12.5, color: 'rgba(0,0,0,.7)',
                }}
              />
              <KeyCap style={{ fontSize: 10 }}>⏎</KeyCap>
            </div>
          </div>
        </div>
      </div>
    </FBWindow>
  );
}

function SectionTitle({ children }) {
  return (
    <div style={{
      fontSize: 11, fontWeight: 600, color: 'rgba(0,0,0,.6)',
      textTransform: 'uppercase', letterSpacing: 0.4,
      padding: '0 2px 8px',
    }}>{children}</div>
  );
}
function Card({ children }) {
  return (
    <div style={{
      background: 'rgba(0,0,0,.025)', borderRadius: 12,
      border: '0.5px solid rgba(0,0,0,.06)',
      padding: '4px 14px',
    }}>{children}</div>
  );
}
function Row({ label, hint, children }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center',
      padding: '10px 0',
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, color: '#1a1a1a' }}>{label}</div>
        {hint && (
          <div style={{ fontSize: 11.5, color: 'rgba(0,0,0,.5)', marginTop: 2, lineHeight: 1.4 }}>
            {hint}
          </div>
        )}
      </div>
      {children}
    </div>
  );
}
function Segmented2({ value, options }) {
  return (
    <div style={{ display: 'inline-flex', borderRadius: 7, padding: 2,
      background: 'rgba(0,0,0,.06)', border: '0.5px solid rgba(0,0,0,.06)' }}>
      {options.map((o) => (
        <div key={o.id} style={{
          padding: '3px 14px', borderRadius: 5, fontSize: 12.5, fontWeight: 500,
          background: o.id === value ? JBRAND.accent : 'transparent',
          color: o.id === value ? 'white' : 'rgba(0,0,0,.7)',
          boxShadow: o.id === value ? '0 1px 2px rgba(0,0,0,.08)' : 'none',
        }}>{o.label}</div>
      ))}
    </div>
  );
}

Object.assign(window, {
  FBWindow,
  ActivityRebuild,
  RulesHeaderRebuild,
  HandoffRebuild,
  BrowsersRebuild,
  AdvancedRebuild,
});

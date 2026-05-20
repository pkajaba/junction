// extras.jsx — onboarding, debug log refresh, app icon explorations

// ─────────────────────────────────────────────────────────────
// First-launch onboarding
// • Three-card carousel in a borderless window
// • Step 1: Make Junction the default browser
// • Step 2: Detected browsers (visually confirms we found them)
// • Step 3: Add your first rule
// ─────────────────────────────────────────────────────────────
function OnboardingHero() {
  return (
    <DesktopBackdrop hue="slate">
      <div style={{
        width: 620, borderRadius: 18, overflow: 'hidden',
        background: 'rgba(252,252,254,0.92)',
        backdropFilter: 'blur(40px) saturate(180%)',
        boxShadow: '0 30px 80px rgba(20,30,60,.34), 0 0 0 0.5px rgba(0,0,0,.1), inset 0 0.5px 0 rgba(255,255,255,.7)',
        fontFamily: JFONT, padding: '36px 40px 24px',
      }}>
        {/* Big mark + name */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 18 }}>
          <JunctionMark size={56} radius={13} />
          <div>
            <div style={{ fontSize: 28, fontWeight: 700, color: '#1a1a1a', letterSpacing: -0.5 }}>Welcome to Junction</div>
            <div style={{ fontSize: 14, color: 'rgba(0,0,0,.6)', marginTop: 2 }}>
              Send every link to the right browser. Three quick steps.
            </div>
          </div>
        </div>

        {/* Steps */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginBottom: 22 }}>
          <Step n={1} state="active" title="Make me your default browser"
            body="So macOS sends every link clicked anywhere to Junction first.">
            <button style={{ ...btnPrimary(), padding: '7px 12px', fontSize: 12.5 }}>
              Set as default…
            </button>
          </Step>
          <Step n={2} state="done" title="Found 6 browsers"
            body="Toggle off the ones you don't want to clutter the picker.">
            <div style={{ display: 'flex', gap: 4 }}>
              {['safari', 'chrome', 'arc', 'firefox', 'brave', 'edge'].map((n) => (
                <BrowserIcon key={n} name={n} size={26} />
              ))}
            </div>
          </Step>
          <Step n={3} state="next" title="Add a rule (or skip)"
            body="Send github.com straight to Chrome, news to Safari, etc.">
            <button style={{ ...btnDefault(), padding: '7px 12px', fontSize: 12.5 }}>
              Start with examples…
            </button>
          </Step>
        </div>

        <div style={{ height: 0.5, background: 'rgba(0,0,0,.08)', margin: '4px 0 16px' }} />
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 11.5, color: 'rgba(0,0,0,.5)' }}>
            Junction is open source · stores rules in <code style={{ fontFamily: JMONO }}>rules.json</code> · no telemetry
          </span>
          <div style={{ flex: 1 }} />
          <button style={{ ...btnDefault(), padding: '6px 11px', fontSize: 12 }}>Skip setup</button>
          <button style={{ ...btnPrimary(), padding: '6px 14px', fontSize: 12 }}>Open Junction</button>
        </div>
      </div>
    </DesktopBackdrop>
  );
}

function Step({ n, state, title, body, children }) {
  const colors = {
    active: { ring: JBRAND.accent, num: JBRAND.accent, ringBg: 'rgba(30,109,255,.08)' },
    done:   { ring: '#34a853',     num: '#34a853',     ringBg: 'rgba(52,168,83,.06)' },
    next:   { ring: 'rgba(0,0,0,.12)', num: 'rgba(0,0,0,.5)', ringBg: 'rgba(0,0,0,.02)' },
  };
  const c = colors[state];
  return (
    <div style={{
      padding: 14, borderRadius: 12,
      background: c.ringBg,
      border: `1px solid ${c.ring}33`,
      display: 'flex', flexDirection: 'column', gap: 8, minHeight: 152,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{
          width: 22, height: 22, borderRadius: '50%',
          border: `1.5px solid ${c.ring}`,
          color: c.num, fontSize: 11, fontWeight: 700,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: state === 'done' ? c.ring : 'transparent',
        }}>
          {state === 'done' ? <SFIcon name="check" size={11} color="white" weight={2.6} /> : n}
        </div>
        <div style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>{title}</div>
      </div>
      <div style={{ fontSize: 12, color: 'rgba(0,0,0,.6)', lineHeight: 1.4, flex: 1 }}>{body}</div>
      <div>{children}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Debug log refresh
// • Timeline left rail (time + dot)
// • Status color-coded
// • Rewrite shows inline diff, not a separate row
// ─────────────────────────────────────────────────────────────
function DebugLog() {
  return (
    <SettingsWindow activeTab="Rules" toolbarTitle="Debug">
      {/* hijack the toolbar */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '14px 20px 10px', display: 'flex', alignItems: 'center', gap: 12 }}>
          <div>
            <div style={{ fontSize: 18, fontWeight: 600, color: '#1a1a1a' }}>Recent URLs</div>
            <div style={{ fontSize: 11.5, color: 'rgba(0,0,0,.55)', marginTop: 2 }}>
              9 rules loaded · live updates · pause to inspect
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <button style={{ ...btnDefault(), padding: '5px 10px', fontSize: 12 }}>
            <SFIcon name="clock" size={11} /> Last hour
          </button>
          <button style={{ ...btnDefault(), padding: '5px 10px', fontSize: 12 }}>Clear</button>
        </div>

        {/* Status pill row */}
        <div style={{ display: 'flex', gap: 6, padding: '0 20px 12px' }}>
          {[
            { label: 'All',         n: 47, active: true },
            { label: 'Routed',      n: 41, color: '#34a853' },
            { label: 'Picker',      n: 4,  color: '#1e6dff' },
            { label: 'Failed',      n: 1,  color: '#d23a2c' },
            { label: 'Unsupported', n: 1,  color: 'rgba(0,0,0,.45)' },
          ].map((f) => (
            <span key={f.label} style={{
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '4px 10px', borderRadius: 999, fontSize: 12,
              background: f.active ? '#1a1a1a' : 'rgba(0,0,0,.04)',
              color: f.active ? 'white' : 'rgba(0,0,0,.75)',
              fontWeight: f.active ? 600 : 500,
            }}>
              {f.color && <span style={{ width: 6, height: 6, borderRadius: 3, background: f.color }} />}
              {f.label}
              <span style={{ opacity: f.active ? 0.7 : 0.5,
                fontVariantNumeric: 'tabular-nums' }}>{f.n}</span>
            </span>
          ))}
        </div>

        <div style={{ flex: 1, overflow: 'auto', padding: '0 16px 14px' }}>
          {MOCK_LOG.map((e, i) => <LogEntry key={i} entry={e} />)}
        </div>
      </div>
    </SettingsWindow>
  );
}

function LogEntry({ entry }) {
  const tone = entry.status === 'unsupported'
    ? { dot: 'rgba(0,0,0,.4)', label: 'unsupported scheme', color: 'rgba(0,0,0,.5)' }
    : entry.via?.kind === 'rule'
      ? { dot: '#34a853', label: `routed via rule "${entry.via.name}"`, color: '#1f7a4a' }
      : entry.via?.kind === 'picker'
        ? { dot: '#1e6dff', label: 'routed via picker', color: JBRAND.accent }
        : { dot: 'rgba(0,0,0,.3)', label: '', color: 'rgba(0,0,0,.5)' };

  return (
    <div style={{ display: 'flex', gap: 14, padding: '12px 0',
      borderBottom: '0.5px solid rgba(0,0,0,.06)' }}>
      {/* timeline rail */}
      <div style={{ flexShrink: 0, width: 56, display: 'flex', alignItems: 'flex-start', gap: 8, paddingTop: 2 }}>
        <div style={{ fontFamily: JMONO, fontSize: 11, color: 'rgba(0,0,0,.5)' }}>{entry.time}</div>
        <div style={{ width: 8, height: 8, marginTop: 4, borderRadius: 4, background: tone.dot,
          boxShadow: `0 0 0 3px ${tone.dot}22` }} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: JMONO, fontSize: 12.5, color: '#1a1a1a',
          wordBreak: 'break-all', lineHeight: 1.4 }}>
          {entry.rewritten ? <RewriteLine before={entry.url} after={entry.rewritten} /> : entry.url}
        </div>
        <div style={{ marginTop: 4, display: 'flex', alignItems: 'center', gap: 8, fontSize: 11.5 }}>
          <span style={{ color: tone.color, fontWeight: 500 }}>{tone.label}</span>
          {entry.target && (
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5,
              padding: '1px 7px', borderRadius: 999,
              background: 'rgba(0,0,0,.04)', color: 'rgba(0,0,0,.7)', fontWeight: 500 }}>
              <SFIcon name="arrowRight" size={9} color="rgba(0,0,0,.5)" /> {entry.target}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}

function RewriteLine({ before, after }) {
  // Render a simple inline visual of "stripped" stuff. Brute approach: if the URL has a `?…`,
  // show the part before `?` normal, the dropped query in red strike-through, and the kept
  // URL on the next line in green.
  const q = before.indexOf('?');
  if (q < 0) return before;
  return (
    <div>
      <div>
        <span style={{ opacity: 0.85 }}>{before.slice(0, q + 1)}</span>
        <span style={{ textDecoration: 'line-through', color: '#d23a2c', opacity: 0.7 }}>
          {before.slice(q + 1)}
        </span>
      </div>
      <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, marginTop: 2,
        fontSize: 11, color: '#1f7a4a' }}>
        <SFIcon name="wand" size={10} color="#1f7a4a" /> {after}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// App icon explorations — 4 directions
// ─────────────────────────────────────────────────────────────
function IconSignpost({ size = 160 }) {
  // The shipped icon
  return (
    <div style={iconShell(size, `linear-gradient(155deg, ${JBRAND.slate600}, ${JBRAND.slate800})`)}>
      <svg width={size * 0.7} height={size * 0.7} viewBox="0 0 100 100" fill="none">
        <g stroke="white" strokeWidth="6" strokeLinecap="round" strokeLinejoin="round">
          <path d="M50 8 v84" />
          <path d="M20 28 h45 l10 9 l-10 9 h-45 z" fill="white" stroke="none" />
          <path d="M80 56 h-45 l-10 9 l10 9 h45 z" fill="white" stroke="none" />
        </g>
      </svg>
    </div>
  );
}

function IconBranch({ size = 160 }) {
  // Two arrows splitting from a single trunk — more "routing" than "signpost"
  return (
    <div style={iconShell(size, 'linear-gradient(155deg, #4a6ce0, #1e3a8a)')}>
      <svg width={size * 0.7} height={size * 0.7} viewBox="0 0 100 100" fill="none">
        <g stroke="white" strokeWidth="7" strokeLinecap="round" strokeLinejoin="round" fill="none">
          <path d="M50 88 V52" />
          <path d="M50 52 Q50 28 20 22" />
          <path d="M50 52 Q50 28 80 22" />
        </g>
        <g fill="white">
          <path d="M14 30 L20 8 L28 26 Z" />
          <path d="M86 30 L80 8 L72 26 Z" />
          <circle cx="50" cy="92" r="6" />
        </g>
      </svg>
    </div>
  );
}

function IconNode({ size = 160 }) {
  // Network/graph metaphor — junction = node
  return (
    <div style={iconShell(size, 'linear-gradient(155deg, #2d8e6f, #0e4f3d)')}>
      <svg width={size * 0.78} height={size * 0.78} viewBox="0 0 100 100" fill="none">
        <g stroke="white" strokeWidth="4.5" strokeLinecap="round" fill="none" opacity="0.85">
          <path d="M50 50 L22 22" />
          <path d="M50 50 L78 22" />
          <path d="M50 50 L78 78" />
          <path d="M50 50 L22 78" />
        </g>
        <g fill="white">
          <circle cx="50" cy="50" r="11" />
          <circle cx="22" cy="22" r="7" />
          <circle cx="78" cy="22" r="7" />
          <circle cx="78" cy="78" r="7" />
          <circle cx="22" cy="78" r="7" />
        </g>
        <circle cx="50" cy="50" r="11" fill="none" stroke="white" strokeWidth="2" opacity="0.4" strokeDasharray="3 4" />
      </svg>
    </div>
  );
}

function IconTypo({ size = 160 }) {
  // The "J" wordmark with a built-in fork at the bottom
  return (
    <div style={iconShell(size, 'linear-gradient(155deg, #e87a3a, #8a3a16)')}>
      <svg width={size * 0.78} height={size * 0.78} viewBox="0 0 100 100" fill="none">
        <path d="M62 10 V62 Q62 80 44 80 Q26 80 26 64"
          stroke="white" strokeWidth="14" strokeLinecap="round" fill="none" />
        <g fill="white">
          <circle cx="26" cy="64" r="5" />
          <circle cx="20" cy="76" r="5" />
        </g>
      </svg>
    </div>
  );
}

function iconShell(size, background) {
  return {
    width: size, height: size, borderRadius: size * 0.225,
    background, display: 'flex', alignItems: 'center', justifyContent: 'center',
    boxShadow: '0 12px 32px rgba(0,0,0,.22), inset 0 1px 0 rgba(255,255,255,.18)',
  };
}

function AppIconArtboard({ Variant, name, description }) {
  return (
    <div style={{
      padding: 32, display: 'flex', flexDirection: 'column',
      alignItems: 'center', gap: 16, height: '100%', justifyContent: 'center',
      background: 'linear-gradient(180deg, #e8eaf0 0%, #c2c6d0 100%)',
      fontFamily: JFONT,
    }}>
      <Variant size={160} />
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontSize: 15, fontWeight: 600, color: '#1a1a1a' }}>{name}</div>
        <div style={{ fontSize: 12, color: 'rgba(0,0,0,.55)', marginTop: 4, maxWidth: 260 }}>{description}</div>
      </div>
      {/* Dock-style preview */}
      <div style={{
        marginTop: 12, padding: '6px 10px', display: 'flex', gap: 8,
        background: 'rgba(255,255,255,.5)', backdropFilter: 'blur(20px)',
        borderRadius: 16, border: '0.5px solid rgba(255,255,255,.6)',
      }}>
        <BrowserIcon name="safari" size={36} />
        <BrowserIcon name="chrome" size={36} />
        <Variant size={36} />
        <BrowserIcon name="firefox" size={36} />
        <BrowserIcon name="arc" size={36} />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Cover/intro artboard for the design canvas
// ─────────────────────────────────────────────────────────────
function CoverArtboard() {
  return (
    <div style={{
      width: '100%', height: '100%',
      background: `linear-gradient(155deg, ${JBRAND.slate600}, ${JBRAND.slate900})`,
      color: 'white', padding: 40, fontFamily: JFONT,
      display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* faint signposts in the background */}
      <svg style={{ position: 'absolute', right: -40, top: -20, opacity: 0.07 }}
        width="380" height="380" viewBox="0 0 100 100" fill="none">
        <g stroke="white" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" fill="none">
          <path d="M50 8 v84" />
          <path d="M20 28 h45 l10 9 l-10 9 h-45 z" fill="white" />
          <path d="M80 56 h-45 l-10 9 l10 9 h45 z" fill="white" />
        </g>
      </svg>

      <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
        <JunctionMark size={48} radius={11} />
        <div>
          <div style={{ fontSize: 13, fontWeight: 600, opacity: 0.65,
            textTransform: 'uppercase', letterSpacing: 1.5 }}>Junction · design canvas</div>
          <div style={{ fontSize: 12, opacity: 0.5, marginTop: 2 }}>Pre-v0.1 · push-it explorations</div>
        </div>
      </div>

      <div>
        <h1 style={{ fontSize: 38, fontWeight: 700, margin: 0, letterSpacing: -1, lineHeight: 1.05 }}>
          Pick the right browser<br />for every link.
        </h1>
        <p style={{ fontSize: 15, opacity: 0.75, marginTop: 14, maxWidth: 380, lineHeight: 1.5 }}>
          Six picker directions, four rules-tab structures, two rule-editor takes,
          first-launch onboarding, a debug-log refresh, and four app icons.
          Pan / scroll to explore. Click any artboard to focus.
        </p>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 24, fontSize: 12, opacity: 0.65 }}>
        <span><b style={{ opacity: 0.9 }}>6</b> picker variants</span>
        <span><b style={{ opacity: 0.9 }}>4</b> rules-tab layouts</span>
        <span><b style={{ opacity: 0.9 }}>2</b> rule editors</span>
        <span><b style={{ opacity: 0.9 }}>4</b> app icons</span>
      </div>
    </div>
  );
}

Object.assign(window, {
  OnboardingHero, DebugLog,
  IconSignpost, IconBranch, IconNode, IconTypo, AppIconArtboard,
  CoverArtboard,
});

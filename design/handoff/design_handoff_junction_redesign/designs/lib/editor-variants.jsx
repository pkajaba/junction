// editor-variants.jsx — Rule editor explorations

// ─────────────────────────────────────────────────────────────
// E1 — Refined sheet
// Two-column layout (Match | Target), test bar at bottom is sticky
// More compact than the SwiftUI Form by collapsing labels above inputs.
// ─────────────────────────────────────────────────────────────
function EditorSheet() {
  return (
    <div style={{
      width: 580, borderRadius: 14, overflow: 'hidden',
      background: 'rgba(248,248,250,1)', display: 'flex', flexDirection: 'column',
      boxShadow: '0 30px 70px rgba(0,0,0,.22), 0 0 0 0.5px rgba(0,0,0,.12)',
      fontFamily: JFONT,
    }}>
      {/* Title bar */}
      <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 10,
        background: 'white', borderBottom: '0.5px solid rgba(0,0,0,.08)' }}>
        <div style={{ fontSize: 14, fontWeight: 600 }}>Edit Rule</div>
        <div style={{ flex: 1 }} />
        <span style={{ fontSize: 12, color: 'rgba(0,0,0,.6)' }}>Enabled</span>
        <MacToggle on size={0.8} />
      </div>

      {/* Name */}
      <div style={{ padding: 16, paddingBottom: 0, background: 'white' }}>
        <input value="Google Workspace" readOnly style={{
          width: '100%', border: 'none', outline: 'none', background: 'transparent',
          fontFamily: JFONT, fontSize: 22, fontWeight: 600, color: '#1a1a1a',
          padding: 0, letterSpacing: -0.3,
        }} />
        <div style={{ fontSize: 11, color: 'rgba(0,0,0,.5)', marginTop: 2 }}>
          Position #2 of 9 · evaluated after "GitHub → work Chrome"
        </div>
      </div>

      {/* Two columns */}
      <div style={{ display: 'flex', gap: 14, padding: 16, background: 'white' }}>
        <div style={{ flex: 1 }}>
          <EditorPanel title="Match">
            <Labeled label="Match by">
              <Segmented value="hostRegex" options={[
                { value: 'host', label: 'Host' },
                { value: 'hostRegex', label: 'Regex' },
                { value: 'urlContains', label: 'URL has' },
              ]} />
            </Labeled>
            <Labeled label="Pattern" hint="case-insensitive">
              <CodeInput value="^(mail|calendar|docs|drive|meet)\\.google\\.com$" />
            </Labeled>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 5, marginTop: 6 }}>
              {['mail.google.com', 'calendar.google.com', 'docs.google.com', 'drive.google.com', 'meet.google.com'].map(h => (
                <span key={h} style={{ fontSize: 11, fontFamily: JMONO,
                  padding: '2px 7px', borderRadius: 4, background: 'rgba(52,168,83,.12)', color: '#1f7a4a' }}>
                  ✓ {h}
                </span>
              ))}
            </div>
          </EditorPanel>
        </div>
        <div style={{ flex: 1 }}>
          <EditorPanel title="Target">
            <Labeled label="Browser">
              <BrowserPickerInline />
            </Labeled>
            <Labeled label="Profile" hint="detected from Local State">
              <ProfileDropdown value="Work" />
            </Labeled>
            <div style={{ marginTop: 4 }}>
              <label style={{ display: 'inline-flex', alignItems: 'center', gap: 7,
                fontSize: 12.5, color: 'rgba(0,0,0,.8)', cursor: 'pointer' }}>
                <MacCheck on={false} />
                Open in new window
              </label>
            </div>
            <div style={{ marginTop: 6 }}>
              <label style={{ display: 'inline-flex', alignItems: 'center', gap: 7,
                fontSize: 12.5, color: 'rgba(0,0,0,.8)', cursor: 'pointer' }}>
                <MacCheck on />
                Strip tracking params
              </label>
            </div>
          </EditorPanel>
        </div>
      </div>

      {/* Test bar (sticky-looking) */}
      <div style={{ padding: '12px 16px', background: 'rgba(0,0,0,.025)',
        borderTop: '0.5px solid rgba(0,0,0,.08)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: 'rgba(0,0,0,.55)',
          textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 6 }}>Test against this rule</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ flex: 1 }}>
            <CodeInput value="https://mail.google.com/mail/u/0/" />
          </div>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5,
            padding: '5px 9px', borderRadius: 6, background: 'rgba(52,168,83,.12)', color: '#1f7a4a',
            fontSize: 12, fontWeight: 600 }}>
            <SFIcon name="check" size={11} color="#1f7a4a" weight={2.2} /> Match
          </span>
          <span style={{ fontSize: 11, color: 'rgba(0,0,0,.55)' }}>→ Chrome · Work</span>
        </div>
      </div>

      {/* Action bar */}
      <div style={{ padding: '10px 14px', display: 'flex', gap: 8,
        background: 'white', borderTop: '0.5px solid rgba(0,0,0,.08)' }}>
        <button style={{ ...btnDefault(), padding: '5px 10px', color: '#d23a2c',
          borderColor: 'rgba(210,58,44,.3)' }}>
          <SFIcon name="minus" size={11} color="#d23a2c" /> Delete
        </button>
        <div style={{ flex: 1 }} />
        <button style={btnDefault()}>Cancel</button>
        <button style={btnPrimary()}>Save</button>
      </div>
    </div>
  );
}

function EditorPanel({ title, children }) {
  return (
    <div>
      <div style={{ fontSize: 11, fontWeight: 700, color: 'rgba(0,0,0,.55)',
        textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 8 }}>{title}</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>{children}</div>
    </div>
  );
}
function Labeled({ label, hint, children }) {
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginBottom: 4 }}>
        <span style={{ fontSize: 12, color: 'rgba(0,0,0,.7)' }}>{label}</span>
        {hint && <span style={{ fontSize: 10.5, color: 'rgba(0,0,0,.4)' }}>· {hint}</span>}
      </div>
      {children}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// E2 — Sentence builder
// • Reads like English: "When the host is github.com, open in Chrome (Work)."
// • Each segment is a tap-to-edit chip
// • Way more approachable for people who don't think in regex
// • Power users can still drop into "raw" mode
// ─────────────────────────────────────────────────────────────
function EditorSentence() {
  return (
    <div style={{
      width: 580, borderRadius: 14, overflow: 'hidden',
      background: 'white', display: 'flex', flexDirection: 'column',
      boxShadow: '0 30px 70px rgba(0,0,0,.22), 0 0 0 0.5px rgba(0,0,0,.12)',
      fontFamily: JFONT,
    }}>
      <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 10,
        borderBottom: '0.5px solid rgba(0,0,0,.08)', background: 'rgba(248,248,250,1)' }}>
        <div style={{ fontSize: 14, fontWeight: 600 }}>Edit Rule</div>
        <div style={{ flex: 1 }} />
        <button style={{ ...btnDefault(), padding: '4px 9px', fontSize: 11 }}>
          <SFIcon name="bolt" size={10} /> Raw
        </button>
        <span style={{ fontSize: 12, color: 'rgba(0,0,0,.6)' }}>Enabled</span>
        <MacToggle on size={0.8} />
      </div>

      <div style={{ padding: 22 }}>
        <input value="Google Workspace" readOnly style={{
          width: '100%', border: 'none', outline: 'none', background: 'transparent',
          fontFamily: JFONT, fontSize: 22, fontWeight: 600, color: '#1a1a1a',
          padding: 0, letterSpacing: -0.3, marginBottom: 16,
        }} />

        <div style={{
          padding: 16, borderRadius: 12, background: 'rgba(0,0,0,.03)',
          border: '0.5px solid rgba(0,0,0,.06)',
        }}>
          {/* When phrase */}
          <SentenceLine>
            <Word>When</Word>
            <Chip>the host</Chip>
            <Chip variant="op">matches the regex</Chip>
            <Chip variant="value" mono>^(mail|calendar|docs|drive|meet)\.google\.com$</Chip>
            <Word>,</Word>
          </SentenceLine>
          <SentenceLine>
            <Word>open in</Word>
            <Chip variant="browser">
              <BrowserIcon name="chrome" size={14} />
              <span style={{ fontWeight: 600 }}>Chrome</span>
            </Chip>
            <Word>with profile</Word>
            <Chip variant="profile">
              <span style={{ width: 7, height: 7, borderRadius: 4, background: '#1f7a4a' }} />
              Work
            </Chip>
            <Word>.</Word>
          </SentenceLine>
          <SentenceLine>
            <Chip variant="optional">+ optionally, open in a new window</Chip>
          </SentenceLine>
        </div>

        {/* Test */}
        <div style={{ marginTop: 18 }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: 'rgba(0,0,0,.55)',
            textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 8 }}>Try a URL</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ flex: 1 }}><CodeInput value="https://mail.google.com/mail/u/0/" /></div>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5,
              padding: '5px 9px', borderRadius: 6, background: 'rgba(52,168,83,.12)', color: '#1f7a4a',
              fontSize: 12, fontWeight: 600 }}>
              <SFIcon name="check" size={11} color="#1f7a4a" weight={2.2} /> Yes — Chrome · Work
            </span>
          </div>
          <div style={{ marginTop: 6, display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ flex: 1 }}><CodeInput value="https://other.google.com/x" /></div>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5,
              padding: '5px 9px', borderRadius: 6, background: 'rgba(0,0,0,.04)', color: 'rgba(0,0,0,.55)',
              fontSize: 12, fontWeight: 500 }}>
              <SFIcon name="x" size={11} color="rgba(0,0,0,.5)" /> Falls through
            </span>
          </div>
        </div>
      </div>

      <div style={{ padding: '10px 14px', display: 'flex', gap: 8,
        background: 'rgba(248,248,250,1)', borderTop: '0.5px solid rgba(0,0,0,.08)' }}>
        <button style={{ ...btnDefault(), color: '#d23a2c', borderColor: 'rgba(210,58,44,.3)' }}>
          <SFIcon name="minus" size={11} color="#d23a2c" /> Delete
        </button>
        <div style={{ flex: 1 }} />
        <button style={btnDefault()}>Cancel</button>
        <button style={btnPrimary()}>Save</button>
      </div>
    </div>
  );
}

function SentenceLine({ children }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap',
      lineHeight: 2, fontSize: 14.5, color: 'rgba(0,0,0,.85)',
    }}>{children}</div>
  );
}
function Word({ children }) {
  return <span style={{ color: 'rgba(0,0,0,.65)', fontWeight: 400 }}>{children}</span>;
}
function Chip({ children, variant = 'default', mono }) {
  const variants = {
    default:  { bg: 'white',                  fg: '#1a1a1a',     border: 'rgba(0,0,0,.18)' },
    op:       { bg: 'rgba(124,72,194,.1)',    fg: '#7848c2',     border: 'rgba(124,72,194,.25)' },
    value:    { bg: '#fffaf2',                fg: '#7a4a16',     border: 'rgba(194,98,46,.25)' },
    browser:  { bg: 'white',                  fg: '#1a1a1a',     border: 'rgba(0,0,0,.18)' },
    profile:  { bg: 'white',                  fg: '#1a1a1a',     border: 'rgba(0,0,0,.18)' },
    optional: { bg: 'rgba(0,0,0,.04)',        fg: 'rgba(0,0,0,.55)', border: 'rgba(0,0,0,.1)' },
  };
  const v = variants[variant] || variants.default;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '3px 9px', borderRadius: 7, maxWidth: '100%',
      background: v.bg, color: v.fg,
      border: `0.5px solid ${v.border}`,
      fontFamily: mono ? JMONO : JFONT,
      fontSize: mono ? 12.5 : 13.5, fontWeight: 500,
      boxShadow: variant === 'value' ? '0 1px 2px rgba(0,0,0,.04)' : 'none',
      cursor: 'pointer',
      overflowWrap: 'anywhere', wordBreak: mono ? 'break-all' : 'normal',
    }}>{children}</span>
  );
}

Object.assign(window, { EditorSheet, EditorSentence });

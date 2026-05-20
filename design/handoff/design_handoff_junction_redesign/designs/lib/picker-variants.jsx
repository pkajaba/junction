// picker-variants.jsx — 6 picker explorations
// All exported to window. Reads JFONT, JBRAND, BrowserIcon, etc. from junction-shared.

// Shared: a soft "desktop" backdrop so the floating picker reads as a real macOS panel.
function DesktopBackdrop({ children, hue = 'cool', tint = 0.5 }) {
  const hues = {
    cool: 'radial-gradient(120% 90% at 30% 20%, #d6e4f5 0%, #c4d0e8 30%, #8aa4c8 100%)',
    warm: 'radial-gradient(120% 90% at 70% 30%, #ffd5b0 0%, #e8aa86 35%, #8e5a78 100%)',
    slate: 'radial-gradient(120% 90% at 40% 30%, #c8d5e3 0%, #94a5be 40%, #4a5d7a 100%)',
    sunset: 'radial-gradient(120% 90% at 80% 20%, #fcd7a1 0%, #ec8a8a 40%, #6a5b9c 100%)',
    forest: 'radial-gradient(120% 90% at 25% 30%, #c5dcb7 0%, #7baa75 50%, #2f5c4a 100%)',
    night: 'radial-gradient(120% 90% at 50% 30%, #4d5c7d 0%, #2c3550 50%, #161c2e 100%)',
    // photographic — layered radials mimic a real desktop wallpaper so the
    // glass actually has something to refract.
    photo: [
      'radial-gradient(40% 30% at 18% 18%, rgba(255,250,220,.85), rgba(255,250,220,0) 70%)',
      'radial-gradient(50% 40% at 78% 28%, rgba(255,176,118,.65), rgba(255,176,118,0) 65%)',
      'radial-gradient(60% 50% at 30% 78%, rgba(80,140,190,.55), rgba(80,140,190,0) 70%)',
      'radial-gradient(80% 70% at 60% 60%, rgba(54,96,140,.0), rgba(20,40,68,.55) 100%)',
      'linear-gradient(180deg, #8cb6dc 0%, #5a7fa4 55%, #314c6e 100%)',
    ].join(','),
  };
  return (
    <div style={{
      position: 'absolute', inset: 0, background: hues[hue] || hues.cool,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      overflow: 'hidden',
    }}>
      {/* a couple of soft "windows" peeking behind the picker for context */}
      <div style={{
        position: 'absolute', left: '-8%', top: '14%', width: 360, height: 240,
        background: 'rgba(255,255,255,0.18)', borderRadius: 12,
        backdropFilter: 'blur(20px)', filter: 'blur(2px)',
      }} />
      <div style={{
        position: 'absolute', right: '-12%', bottom: '8%', width: 320, height: 200,
        background: 'rgba(255,255,255,0.14)', borderRadius: 12,
        backdropFilter: 'blur(20px)', filter: 'blur(2px)',
      }} />
      {children}
    </div>
  );
}

// Common URL we route through every variant.
const PICK_URL = 'https://news.ycombinator.com/item?id=39842110';
const PICK_HOST = 'news.ycombinator.com';

// ─────────────────────────────────────────────────────────────────────
// P1 — Native+ : the shipped picker, cleaned up
// • Default browser gets a star + subtle ring
// • URL bar shows host bold / path muted
// • Number badges become small SF-style numerals (no pills)
// • Pin button only on hover (here: shown on selected tile)
// ─────────────────────────────────────────────────────────────────────
function PickerNative() {
  const browsers = MOCK_BROWSERS.slice(0, 8);
  const defaultIdx = 0;
  const selectedIdx = 2;
  return (
    <DesktopBackdrop hue="cool">
      <div style={{
        width: 540, background: 'rgba(248,248,250,0.88)',
        backdropFilter: 'blur(40px) saturate(180%)',
        borderRadius: 16, overflow: 'hidden',
        boxShadow: '0 30px 70px rgba(20,30,60,.32), 0 0 0 0.5px rgba(0,0,0,.12), inset 0 0.5px 0 rgba(255,255,255,.6)',
        fontFamily: JFONT,
      }}>
        {/* URL bar */}
        <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <HostGlyph host={PICK_HOST} size={18} />
          <div style={{ flex: 1, minWidth: 0, fontFamily: JMONO, fontSize: 13, lineHeight: 1.3 }}>
            <span style={{ color: '#1a1a1a', fontWeight: 600 }}>{PICK_HOST}</span>
            <span style={{ color: 'rgba(0,0,0,.45)' }}>/item?id=39842110</span>
          </div>
          <span style={{
            fontFamily: JFONT, fontSize: 10.5, fontWeight: 500,
            color: 'rgba(0,0,0,.5)', padding: '2px 7px', borderRadius: 4,
            background: 'rgba(0,0,0,.05)',
          }}>no rule match</span>
        </div>
        <div style={{ height: 0.5, background: 'rgba(0,0,0,.08)' }} />

        {/* Grid */}
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)',
          gap: 4, padding: 14,
        }}>
          {browsers.map((b, i) => {
            const isDefault = i === defaultIdx;
            const isSelected = i === selectedIdx;
            return (
              <div key={b.id} style={{
                display: 'flex', flexDirection: 'column', alignItems: 'center',
                padding: '10px 6px', borderRadius: 10, position: 'relative',
                background: isSelected ? 'rgba(30,109,255,.10)' : 'transparent',
                border: isSelected ? `1.5px solid ${JBRAND.accent}` : '1.5px solid transparent',
              }}>
                {/* number badge — top left, tiny, no chip */}
                <div style={{
                  position: 'absolute', top: 6, left: 8,
                  fontSize: 10, fontWeight: 600, color: 'rgba(0,0,0,.5)',
                  fontVariantNumeric: 'tabular-nums',
                }}>{i + 1}</div>
                {/* default star — top right */}
                {isDefault && (
                  <div style={{ position: 'absolute', top: 6, right: 8, color: JBRAND.accent }}>
                    <SFIcon name="star.fill" size={10} color="#1e6dff" />
                  </div>
                )}
                {/* pin button on selected */}
                {isSelected && (
                  <div title="Always open here" style={{
                    position: 'absolute', top: 4, right: 4,
                    width: 22, height: 22, borderRadius: 6,
                    background: JBRAND.accent, color: 'white',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    boxShadow: '0 2px 6px rgba(30,109,255,.4)',
                  }}>
                    <SFIcon name="pin.fill" size={11} color="white" />
                  </div>
                )}
                <BrowserIcon name={b.icon} size={48} />
                <div style={{
                  marginTop: 6, fontSize: 11, color: '#1a1a1a',
                  fontWeight: isSelected ? 600 : 500, textAlign: 'center',
                }}>{b.name}</div>
              </div>
            );
          })}
        </div>

        <div style={{ height: 0.5, background: 'rgba(0,0,0,.08)' }} />
        {/* Footer */}
        <div style={{
          padding: '8px 16px', display: 'flex', alignItems: 'center', gap: 14,
          fontSize: 11, color: 'rgba(0,0,0,.55)',
        }}>
          <KeyHint k="1-8" label="pick" />
          <KeyHint k={<>←→↑↓</>} label="move" />
          <KeyHint k="↩" label="open" />
          <KeyHint k="⌥↩" label="always" />
          <div style={{ flex: 1 }} />
          <KeyHint k="esc" label="cancel" />
        </div>
      </div>
    </DesktopBackdrop>
  );
}

function KeyHint({ k, label }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5 }}>
      <KeyCap>{k}</KeyCap>
      <span>{label}</span>
    </span>
  );
}

// ─────────────────────────────────────────────────────────────────────
// P2 — Hero + Rail : the focused tile is huge, others are a horizontal rail
// • URL is the protagonist at the top
// • Focused tile shows browser + profile picker chip
// • Rail below scrolls but keeps numbers visible
// ─────────────────────────────────────────────────────────────────────
function PickerHero() {
  const browsers = MOCK_BROWSERS.slice(0, 8);
  const focusedIdx = 1; // Chrome
  const focused = browsers[focusedIdx];
  return (
    <DesktopBackdrop hue="sunset">
      <div style={{
        width: 580, background: 'rgba(252,252,254,0.9)',
        backdropFilter: 'blur(40px) saturate(180%)',
        borderRadius: 22, overflow: 'hidden',
        boxShadow: '0 30px 80px rgba(70,30,60,.32), 0 0 0 0.5px rgba(0,0,0,.1), inset 0 0.5px 0 rgba(255,255,255,.7)',
        fontFamily: JFONT,
      }}>
        {/* URL hero */}
        <div style={{ padding: '18px 22px 14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <HostGlyph host={PICK_HOST} size={22} />
            <div style={{ minWidth: 0, flex: 1 }}>
              <div style={{ fontSize: 17, fontWeight: 600, color: '#1a1a1a', lineHeight: 1.15 }}>{PICK_HOST}</div>
              <div style={{ fontSize: 12, color: 'rgba(0,0,0,.5)', fontFamily: JMONO,
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>/item?id=39842110</div>
            </div>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 6,
              padding: '5px 10px', borderRadius: 999,
              background: 'rgba(30,109,255,.1)', color: JBRAND.accent,
              fontSize: 11, fontWeight: 600,
            }}>
              <SFIcon name="pin" size={11} color={JBRAND.accent} />
              ⌥ for always
            </div>
          </div>
        </div>

        {/* Focused tile */}
        <div style={{
          margin: '0 22px 18px', padding: 18, borderRadius: 18,
          background: 'linear-gradient(180deg, rgba(255,255,255,.7), rgba(255,255,255,.4))',
          border: `2px solid ${JBRAND.accent}`,
          display: 'flex', alignItems: 'center', gap: 18,
          boxShadow: '0 8px 24px rgba(30,109,255,.15)',
        }}>
          <BrowserIcon name={focused.icon} size={88} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 20, fontWeight: 600, color: '#1a1a1a' }}>{focused.name}</div>
            <div style={{ marginTop: 6, display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
              <ProfileChip name="Work" selected />
              <ProfileChip name="Personal" />
              <ProfileChip name="vetrofibermap" muted />
            </div>
            <div style={{ marginTop: 10, fontSize: 11, color: 'rgba(0,0,0,.55)' }}>
              <KeyCap tone="strong">↩</KeyCap>&nbsp;&nbsp;to open
              <span style={{ marginLeft: 12 }}><KeyCap>⌥↩</KeyCap>&nbsp;&nbsp;always for {PICK_HOST}</span>
            </div>
          </div>
        </div>

        {/* Rail */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '0 14px 14px', overflowX: 'auto',
        }}>
          {browsers.map((b, i) => (
            <div key={b.id} style={{
              position: 'relative', padding: 8, borderRadius: 12,
              background: i === focusedIdx ? 'rgba(30,109,255,.08)' : 'transparent',
              border: i === focusedIdx ? `1px solid rgba(30,109,255,.3)` : '1px solid transparent',
              display: 'flex', flexDirection: 'column', alignItems: 'center',
              flexShrink: 0, width: 56,
            }}>
              <div style={{
                position: 'absolute', top: -4, left: -4,
                width: 18, height: 18, borderRadius: '50%',
                background: i === focusedIdx ? JBRAND.accent : 'rgba(0,0,0,.55)',
                color: 'white', fontSize: 10.5, fontWeight: 700,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{i + 1}</div>
              <BrowserIcon name={b.icon} size={36} />
              <div style={{ marginTop: 4, fontSize: 9.5, color: 'rgba(0,0,0,.6)',
                whiteSpace: 'nowrap', maxWidth: 50, overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.name}</div>
            </div>
          ))}
        </div>
      </div>
    </DesktopBackdrop>
  );
}

function ProfileChip({ name, selected, muted }) {
  return (
    <span style={{
      fontSize: 11, fontWeight: 600,
      padding: '3px 8px', borderRadius: 999,
      background: selected ? JBRAND.accent : (muted ? 'rgba(0,0,0,.04)' : 'rgba(0,0,0,.07)'),
      color: selected ? 'white' : (muted ? 'rgba(0,0,0,.45)' : 'rgba(0,0,0,.7)'),
      border: '0.5px solid rgba(0,0,0,.05)',
    }}>{name}</span>
  );
}

// ─────────────────────────────────────────────────────────────────────
// P3 — Command list (Raycast-style)
// • Type-ahead filter at top
// • Each row: icon · name · profile · shortcut
// • Most info-dense; pure keyboard surface
// ─────────────────────────────────────────────────────────────────────
function PickerCommand() {
  const browsers = MOCK_BROWSERS.slice(0, 8);
  const profilesOf = (b) => {
    if (b.icon === 'chrome') return ['Work', 'Personal', 'vetrofibermap'];
    if (b.icon === 'firefox') return ['Banking'];
    if (b.icon === 'arc') return ['Design'];
    if (b.icon === 'brave') return ['Default'];
    return null;
  };
  const selectedIdx = 1;
  return (
    <DesktopBackdrop hue="slate">
      <div style={{
        width: 560, background: 'rgba(250,250,252,0.92)',
        backdropFilter: 'blur(40px) saturate(180%)',
        borderRadius: 14, overflow: 'hidden',
        boxShadow: '0 30px 70px rgba(20,30,60,.4), 0 0 0 0.5px rgba(0,0,0,.12)',
        fontFamily: JFONT,
      }}>
        {/* search/url combo */}
        <div style={{
          padding: '14px 16px 12px', display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <HostGlyph host={PICK_HOST} size={20} />
          <input value={PICK_URL} readOnly style={{
            flex: 1, border: 'none', outline: 'none', background: 'transparent',
            fontFamily: JMONO, fontSize: 13, color: 'rgba(0,0,0,.75)',
          }} />
          <span style={{ fontSize: 10.5, color: 'rgba(0,0,0,.4)', fontWeight: 500 }}>type to filter →</span>
        </div>
        <div style={{ height: 0.5, background: 'rgba(0,0,0,.08)' }} />

        {/* list */}
        <div style={{ padding: '6px 6px' }}>
          {browsers.map((b, i) => {
            const profiles = profilesOf(b);
            const selected = i === selectedIdx;
            return (
              <div key={b.id} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '8px 10px', borderRadius: 8,
                background: selected ? JBRAND.accent : 'transparent',
                color: selected ? 'white' : 'inherit',
              }}>
                <BrowserIcon name={b.icon} size={28} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13.5, fontWeight: 500,
                    color: selected ? 'white' : '#1a1a1a' }}>{b.name}</div>
                  {profiles && (
                    <div style={{ display: 'flex', gap: 4, marginTop: 3, flexWrap: 'wrap' }}>
                      {profiles.map((p, j) => (
                        <span key={p} style={{
                          fontSize: 10.5, fontWeight: 500,
                          padding: '1px 6px', borderRadius: 4,
                          background: selected
                            ? (j === 0 ? 'rgba(255,255,255,.28)' : 'rgba(255,255,255,.12)')
                            : (j === 0 ? 'rgba(30,109,255,.12)' : 'rgba(0,0,0,.05)'),
                          color: selected ? 'white' : (j === 0 ? JBRAND.accent : 'rgba(0,0,0,.55)'),
                        }}>{p}</span>
                      ))}
                    </div>
                  )}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  {i === 0 && <span style={{ fontSize: 10, color: selected ? 'rgba(255,255,255,.7)' : 'rgba(0,0,0,.4)',
                    fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>default</span>}
                  <KeyCap tone={selected ? 'strong' : 'default'}
                    style={selected ? { background: 'rgba(255,255,255,.25)', color: 'white', borderColor: 'rgba(255,255,255,.3)' } : {}}>
                    {i + 1}
                  </KeyCap>
                </div>
              </div>
            );
          })}
        </div>

        <div style={{ height: 0.5, background: 'rgba(0,0,0,.08)' }} />
        <div style={{ padding: '8px 16px', display: 'flex', alignItems: 'center', gap: 14,
          fontSize: 11, color: 'rgba(0,0,0,.55)' }}>
          <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
            <KeyCap>↩</KeyCap> open
          </span>
          <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
            <KeyCap>⌥</KeyCap>+<KeyCap>↩</KeyCap> always for {PICK_HOST}
          </span>
          <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
            <KeyCap>⇥</KeyCap> pick profile
          </span>
          <div style={{ flex: 1 }} />
          <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}><KeyCap>esc</KeyCap> cancel</span>
        </div>
      </div>
    </DesktopBackdrop>
  );
}

// ─────────────────────────────────────────────────────────────────────
// P4 — Liquid Glass radial
// • macOS 26 glass card
// • Browsers arrayed in an arc around a center URL pill
// • Default at 12 o'clock, indexed clockwise
// • Push it: very visual, very macOS-26
// ─────────────────────────────────────────────────────────────────────
function PickerRadial() {
  const browsers = MOCK_BROWSERS.slice(0, 8);
  const R = 150;
  // start from 12 o'clock, distribute over 360deg
  const angle = (i) => -90 + (360 / browsers.length) * i;
  const selectedIdx = 1;
  return (
    <DesktopBackdrop hue="warm">
      <div style={{
        width: 480, height: 480, borderRadius: 240,
        background: 'rgba(255,255,255,.4)',
        backdropFilter: 'blur(48px) saturate(200%)',
        border: '0.5px solid rgba(255,255,255,.65)',
        boxShadow: '0 30px 80px rgba(80,40,30,.35), 0 0 0 0.5px rgba(0,0,0,.06), inset 0 1px 0 rgba(255,255,255,.7)',
        position: 'relative', fontFamily: JFONT,
      }}>
        {/* center URL pill */}
        <div style={{
          position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)',
          textAlign: 'center', maxWidth: 200,
        }}>
          <div style={{ fontSize: 11, color: 'rgba(0,0,0,.55)', fontWeight: 600,
            textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 6 }}>Open this link</div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '8px 14px', borderRadius: 999, background: 'rgba(255,255,255,.6)',
            boxShadow: '0 2px 10px rgba(0,0,0,.06), inset 0 0.5px 0 rgba(255,255,255,.9)',
          }}>
            <HostGlyph host={PICK_HOST} size={18} />
            <div style={{ fontSize: 13, color: '#1a1a1a', fontWeight: 600 }}>{PICK_HOST}</div>
          </div>
          <div style={{ marginTop: 14, fontSize: 11, color: 'rgba(0,0,0,.5)',
            display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            hold <KeyCap tone="strong">⌥</KeyCap> to always
          </div>
        </div>

        {/* arc tiles */}
        {browsers.map((b, i) => {
          const a = angle(i);
          const x = Math.cos((a * Math.PI) / 180) * R;
          const y = Math.sin((a * Math.PI) / 180) * R;
          const selected = i === selectedIdx;
          return (
            <div key={b.id} style={{
              position: 'absolute', top: '50%', left: '50%',
              transform: `translate(calc(${x}px - 50%), calc(${y}px - 50%))`,
              width: 64, height: 64,
            }}>
              <div style={{
                position: 'relative', width: 64, height: 64, borderRadius: 16,
                background: selected ? 'rgba(255,255,255,.95)' : 'rgba(255,255,255,.55)',
                backdropFilter: 'blur(20px)',
                border: selected ? `2px solid ${JBRAND.accent}` : '0.5px solid rgba(255,255,255,.7)',
                boxShadow: selected
                  ? '0 12px 28px rgba(30,109,255,.32), 0 0 0 4px rgba(30,109,255,.12)'
                  : '0 4px 12px rgba(0,0,0,.1), inset 0 0.5px 0 rgba(255,255,255,.8)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <BrowserIcon name={b.icon} size={42} />
                <div style={{
                  position: 'absolute', top: -6, right: -6,
                  width: 20, height: 20, borderRadius: '50%',
                  background: selected ? JBRAND.accent : 'rgba(40,40,50,.92)',
                  color: 'white', fontSize: 11, fontWeight: 700,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: '0 1px 3px rgba(0,0,0,.18)',
                }}>{i + 1}</div>
                {i === 0 && (
                  <div style={{
                    position: 'absolute', top: -6, left: -6,
                    width: 18, height: 18, borderRadius: '50%',
                    background: '#ffce42', color: '#7d5600',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    boxShadow: '0 1px 3px rgba(0,0,0,.18)',
                  }}>
                    <SFIcon name="star.fill" size={10} color="#7d5600" />
                  </div>
                )}
              </div>
              <div style={{ marginTop: 6, fontSize: 11, fontWeight: selected ? 600 : 500,
                color: '#1a1a1a', textAlign: 'center',
                textShadow: '0 1px 2px rgba(255,255,255,.6)' }}>{b.name}</div>
            </div>
          );
        })}
      </div>
    </DesktopBackdrop>
  );
}

// ─────────────────────────────────────────────────────────────────────
// P5 — Domain-smart suggestion
// • A hero "Suggested" row at top: inferred from "you usually open
//   github.com-style sites in Chrome (Work)"
// • Below: standard grid as a fallback
// • "Always" is right next to Open — first-class affordance
// ─────────────────────────────────────────────────────────────────────
function PickerSmart({ browserCount = 2, suggestions = true } = {}) {
  // Adapts to however many browsers the user actually has installed.
  // With 2 browsers the suggestion is the hero and the single alternate is a
  // proper wide card — no awkward grid of one tile.
  // When `suggestions` is off, this becomes a plain numbered list — the fallback
  // for users who disable smart suggestions in Settings.
  const all = MOCK_BROWSERS.slice(0, Math.max(2, browserCount));
  const suggested = all[1]; // Chrome
  const others = all.filter((b) => b.id !== suggested.id);
  return (
    <DesktopBackdrop hue="photo">
      <div style={{
        width: 560,
        // Liquid-glass panel: very translucent, strong blur, top sheen + edge highlight
        background: 'linear-gradient(180deg, rgba(255,255,255,.38) 0%, rgba(255,255,255,.18) 60%, rgba(255,255,255,.22) 100%)',
        backdropFilter: 'blur(60px) saturate(200%) brightness(108%)',
        WebkitBackdropFilter: 'blur(60px) saturate(200%) brightness(108%)',
        borderRadius: 26, overflow: 'hidden',
        border: '0.5px solid rgba(255,255,255,.55)',
        boxShadow:
          '0 40px 80px rgba(20,40,30,.38),' +
          ' 0 2px 0 rgba(255,255,255,.22) inset,' +
          ' 0 -1px 0 rgba(0,0,0,.04) inset,' +
          ' 0 0 0 0.5px rgba(0,0,0,.04)',
        fontFamily: JFONT,
      }}>
        {/* URL bar */}
        <div style={{ padding: '14px 18px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <HostGlyph host={PICK_HOST} size={18} />
          <div style={{ flex: 1, minWidth: 0, fontFamily: JMONO, fontSize: 12.5,
            textShadow: '0 1px 1px rgba(255,255,255,.4)' }}>
            <span style={{ color: '#1a1a1a', fontWeight: 600 }}>{PICK_HOST}</span>
            <span style={{ color: 'rgba(0,0,0,.55)' }}>/item?id=39842110</span>
          </div>
          {!suggestions && (
            <span style={{
              fontFamily: JFONT, fontSize: 10.5, fontWeight: 500,
              color: 'rgba(0,0,0,.55)', padding: '2px 7px', borderRadius: 4,
              background: 'rgba(255,255,255,.4)',
              border: '0.5px solid rgba(255,255,255,.5)',
            }}>no rule match</span>
          )}
        </div>
        <div style={{ height: 0.5, background: 'rgba(255,255,255,.4)' }} />

        {suggestions ? <SmartBody suggested={suggested} others={others} />
                     : <FallbackBody all={all} />}

        {/* Keyboard shortcuts footer — shared by both modes */}
        <div style={{ height: 0.5, background: 'rgba(0,0,0,.06)' }} />
        <div style={{
          padding: '8px 18px', display: 'flex', alignItems: 'center', gap: 14,
          fontSize: 11, color: 'rgba(0,0,0,.6)', flexWrap: 'wrap',
          background: 'rgba(255,255,255,.18)',
        }}>
          <KeyHint k={`1-${all.length}`} label="pick" />
          <KeyHint k={<>↑↓</>} label="move" />
          <KeyHint k="↩" label="open" />
          <KeyHint k="⌥↩" label="always" />
          <div style={{ flex: 1 }} />
          <KeyHint k="esc" label="cancel" />
        </div>
      </div>
    </DesktopBackdrop>
  );
}

// Smart-suggestion body (P5 default)
function SmartBody({ suggested, others }) {
  return (
    <>
      <div style={{ padding: '16px 18px 14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 10 }}>
          <SFIcon name="sparkle" size={12} color={JBRAND.accent} />
          <div style={{ fontSize: 11, fontWeight: 700, color: JBRAND.accent,
            textTransform: 'uppercase', letterSpacing: 0.6 }}>Junction suggests</div>
          <div style={{ flex: 1, height: 0.5, background: 'rgba(30,109,255,.2)' }} />
        </div>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 14, padding: 14, borderRadius: 16,
          background: 'linear-gradient(180deg, rgba(255,255,255,.55), rgba(255,255,255,.25))',
          backdropFilter: 'blur(20px) saturate(160%)',
          border: '0.5px solid rgba(255,255,255,.5)',
          boxShadow: '0 4px 14px rgba(30,109,255,.12), inset 0 1px 0 rgba(255,255,255,.6)',
        }}>
          <BrowserIcon name={suggested.icon} size={56} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 15, fontWeight: 600, color: '#1a1a1a' }}>
              {suggested.name}
              {suggested.icon === 'chrome' && (<>
                {' '}<span style={{ color: 'rgba(0,0,0,.5)', fontWeight: 500 }}>·</span>{' '}
                <span style={{ color: 'rgba(0,0,0,.7)' }}>Work</span>
              </>)}
            </div>
            <div style={{ fontSize: 11.5, color: 'rgba(0,0,0,.65)', marginTop: 2 }}>
              You opened <b>news.ycombinator.com</b> here 7 of the last 9 times
            </div>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <button style={{
              padding: '7px 12px', fontSize: 12.5, fontWeight: 600,
              borderRadius: 8, border: 'none', cursor: 'pointer',
              background: JBRAND.accent, color: 'white',
              display: 'flex', alignItems: 'center', gap: 5,
              boxShadow: '0 2px 8px rgba(30,109,255,.35), inset 0 1px 0 rgba(255,255,255,.25)',
            }}>
              Open <KeyCap tone="strong" style={{ background: 'rgba(255,255,255,.22)', color: 'white', borderColor: 'rgba(255,255,255,.3)' }}>↩</KeyCap>
            </button>
            <button style={{
              padding: '7px 12px', fontSize: 12.5, fontWeight: 600,
              borderRadius: 8, border: '0.5px solid rgba(255,255,255,.6)', cursor: 'pointer',
              background: 'rgba(255,255,255,.55)', color: '#1a1a1a',
              backdropFilter: 'blur(20px)',
              display: 'flex', alignItems: 'center', gap: 5,
              boxShadow: 'inset 0 1px 0 rgba(255,255,255,.7)',
            }}>
              <SFIcon name="pin" size={11} color="#1a1a1a" />
              Always
            </button>
          </div>
        </div>
      </div>

      <div style={{ padding: '0 18px 12px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, color: 'rgba(0,0,0,.65)',
          textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 8 }}>
          {others.length === 1 ? 'Or open in' : 'Or pick another'}
        </div>
        {others.length === 1 ? (
          <button style={{
            width: '100%', display: 'flex', alignItems: 'center', gap: 12,
            padding: '10px 14px', borderRadius: 14, cursor: 'pointer',
            background: 'rgba(255,255,255,.4)',
            backdropFilter: 'blur(20px) saturate(150%)',
            border: '0.5px solid rgba(255,255,255,.5)',
            boxShadow: 'inset 0 1px 0 rgba(255,255,255,.6)',
            textAlign: 'left', fontFamily: JFONT,
          }}>
            <BrowserIcon name={others[0].icon} size={36} />
            <div style={{ flex: 1, fontSize: 13.5, fontWeight: 600, color: '#1a1a1a' }}>
              {others[0].name}
            </div>
            <KeyCap>2</KeyCap>
          </button>
        ) : others.length <= 3 ? (
          <div style={{ display: 'flex', gap: 8 }}>
            {others.map((b, i) => (
              <div key={b.id} style={{
                flex: 1, display: 'flex', alignItems: 'center', gap: 10,
                padding: '9px 12px', borderRadius: 12, cursor: 'pointer',
                background: 'rgba(255,255,255,.4)',
                backdropFilter: 'blur(20px) saturate(150%)',
                border: '0.5px solid rgba(255,255,255,.5)',
                boxShadow: 'inset 0 1px 0 rgba(255,255,255,.6)',
              }}>
                <BrowserIcon name={b.icon} size={28} />
                <div style={{ flex: 1, minWidth: 0, fontSize: 12.5, fontWeight: 600,
                  color: '#1a1a1a', whiteSpace: 'nowrap',
                  overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.name}</div>
                <KeyCap>{i + 2}</KeyCap>
              </div>
            ))}
          </div>
        ) : (
          <div style={{
            display: 'grid',
            gridTemplateColumns: `repeat(${Math.min(others.length, 7)}, 1fr)`,
            gap: 6,
          }}>
            {others.map((b, i) => (
              <div key={b.id} style={{
                display: 'flex', flexDirection: 'column', alignItems: 'center',
                padding: '8px 4px', borderRadius: 8, cursor: 'pointer',
                position: 'relative',
              }}>
                <div style={{ position: 'absolute', top: 4, left: 4,
                  fontSize: 9.5, color: 'rgba(0,0,0,.55)', fontWeight: 600 }}>{i + 2}</div>
                <BrowserIcon name={b.icon} size={32} />
                <div style={{ marginTop: 4, fontSize: 10, color: 'rgba(0,0,0,.75)',
                  textAlign: 'center', whiteSpace: 'nowrap', overflow: 'hidden',
                  maxWidth: 56, textOverflow: 'ellipsis' }}>{b.name}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </>
  );
}

// Fallback body — plain numbered list, what you see if you turn off Suggestions
function FallbackBody({ all }) {
  const selectedIdx = 0;
  return (
    <div style={{ padding: '10px 10px 14px' }}>
      {all.map((b, i) => {
        const isSel = i === selectedIdx;
        return (
          <div key={b.id} style={{
            display: 'flex', alignItems: 'center', gap: 12,
            padding: '10px 12px', borderRadius: 12, cursor: 'pointer',
            background: isSel
              ? 'linear-gradient(180deg, rgba(30,109,255,.85), rgba(30,109,255,.95))'
              : 'transparent',
            color: isSel ? 'white' : 'inherit',
            marginBottom: 2,
            boxShadow: isSel ? '0 2px 10px rgba(30,109,255,.3), inset 0 1px 0 rgba(255,255,255,.25)' : 'none',
          }}>
            <BrowserIcon name={b.icon} size={36} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 600,
                color: isSel ? 'white' : '#1a1a1a' }}>
                {b.name}
                {b.icon === 'chrome' && (
                  <span style={{ marginLeft: 6, fontWeight: 500,
                    color: isSel ? 'rgba(255,255,255,.8)' : 'rgba(0,0,0,.6)' }}>
                    · Work
                  </span>
                )}
              </div>
              {i === 0 && (
                <div style={{ fontSize: 10.5, fontWeight: 600,
                  color: isSel ? 'rgba(255,255,255,.75)' : 'rgba(0,0,0,.55)',
                  textTransform: 'uppercase', letterSpacing: 0.4, marginTop: 2 }}>
                  Default
                </div>
              )}
            </div>
            <KeyCap tone={isSel ? 'strong' : 'default'}
              style={isSel ? { background: 'rgba(255,255,255,.22)', color: 'white',
                borderColor: 'rgba(255,255,255,.3)' } : {}}>
              {i + 1}
            </KeyCap>
          </div>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// P6 — Profile-first
// • Treats "Chrome (Work)" and "Chrome (Personal)" as separate first-class
//   targets in the picker — because they usually are different routing
//   destinations.
// • Browsers without profiles still get a single tile.
// ─────────────────────────────────────────────────────────────────────
function PickerProfile() {
  const tiles = [
    { browser: 'chrome', name: 'Chrome', profile: 'Work', color: '#1f7a4a' },
    { browser: 'chrome', name: 'Chrome', profile: 'Personal', color: '#7848c2' },
    { browser: 'chrome', name: 'Chrome', profile: 'vetrofibermap', color: '#c2622e' },
    { browser: 'firefox', name: 'Firefox', profile: 'Banking', color: '#206a9c' },
    { browser: 'arc', name: 'Arc', profile: 'Design', color: '#c75aa0' },
    { browser: 'safari', name: 'Safari', profile: null },
    { browser: 'brave', name: 'Brave', profile: null },
    { browser: 'edge', name: 'Edge', profile: null },
  ];
  const selectedIdx = 0;
  return (
    <DesktopBackdrop hue="cool">
      <div style={{
        width: 560, background: 'rgba(248,248,250,0.9)',
        backdropFilter: 'blur(40px) saturate(180%)',
        borderRadius: 16, overflow: 'hidden',
        boxShadow: '0 30px 70px rgba(20,30,60,.32), 0 0 0 0.5px rgba(0,0,0,.12)',
        fontFamily: JFONT,
      }}>
        <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <HostGlyph host={PICK_HOST} size={18} />
          <div style={{ flex: 1, minWidth: 0, fontFamily: JMONO, fontSize: 12.5 }}>
            <span style={{ color: '#1a1a1a', fontWeight: 600 }}>{PICK_HOST}</span>
            <span style={{ color: 'rgba(0,0,0,.45)' }}>/item?id=39842110</span>
          </div>
        </div>
        <div style={{ height: 0.5, background: 'rgba(0,0,0,.08)' }} />

        <div style={{ padding: 14, display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 }}>
          {tiles.map((t, i) => {
            const selected = i === selectedIdx;
            return (
              <div key={i} style={{
                position: 'relative', padding: '10px 8px 8px',
                borderRadius: 12, textAlign: 'center',
                background: selected ? 'rgba(30,109,255,.08)' : 'transparent',
                border: selected ? `1.5px solid ${JBRAND.accent}` : '1.5px solid transparent',
              }}>
                <div style={{ position: 'absolute', top: 6, left: 8,
                  fontSize: 10, color: 'rgba(0,0,0,.5)', fontWeight: 600 }}>{i + 1}</div>
                <BrowserIcon name={t.browser} size={44} />
                {/* tiny profile color dot bottom-right of icon */}
                {t.profile && (
                  <div style={{
                    position: 'absolute', top: 32, left: '50%', marginLeft: 8,
                    width: 14, height: 14, borderRadius: '50%',
                    background: t.color, border: '2px solid white',
                    boxShadow: '0 0.5px 1px rgba(0,0,0,.2)',
                  }} />
                )}
                <div style={{ marginTop: 6, fontSize: 11.5, color: '#1a1a1a', fontWeight: 600 }}>{t.name}</div>
                <div style={{ marginTop: 1, fontSize: 10, color: t.profile ? t.color : 'rgba(0,0,0,.4)',
                  fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {t.profile || '—'}
                </div>
              </div>
            );
          })}
        </div>
        <div style={{ height: 0.5, background: 'rgba(0,0,0,.08)' }} />
        <div style={{ padding: '8px 16px', display: 'flex', gap: 14, fontSize: 11, color: 'rgba(0,0,0,.55)' }}>
          <span><KeyCap>1-8</KeyCap> pick</span>
          <span><KeyCap>↩</KeyCap> open</span>
          <span><KeyCap>⌥↩</KeyCap> always</span>
          <span><KeyCap>⌘P</KeyCap> hide profiles</span>
          <div style={{ flex: 1 }} />
          <span><KeyCap>esc</KeyCap> cancel</span>
        </div>
      </div>
    </DesktopBackdrop>
  );
}

Object.assign(window, {
  PickerNative, PickerHero, PickerCommand, PickerRadial, PickerSmart, PickerProfile,
  DesktopBackdrop,
});

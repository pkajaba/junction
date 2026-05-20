// rules-variants.jsx — 4 explorations of the Rules settings tab
// Wraps each in a macOS Settings window shell.

// ─────────────────────────────────────────────────────────────
// Shared: macOS Settings window chrome
// ─────────────────────────────────────────────────────────────
function SettingsWindow({ activeTab = 'Rules', children, width = 880, height = 620, toolbarTitle = 'Rules' }) {
  return (
    <div style={{
      width, height, borderRadius: 12, overflow: 'hidden',
      background: 'white', display: 'flex', flexDirection: 'column',
      boxShadow: '0 30px 70px rgba(0,0,0,.18), 0 0 0 0.5px rgba(0,0,0,.12)',
      fontFamily: JFONT,
    }}>
      {/* Title bar */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '11px 14px', background: 'rgba(245,245,247,1)',
        borderBottom: '0.5px solid rgba(0,0,0,.08)', height: 38,
      }}>
        <TrafficLights />
        <div style={{ flex: 1, textAlign: 'center', fontSize: 13, fontWeight: 600,
          color: 'rgba(0,0,0,.75)', marginRight: 60 }}>Junction · Settings</div>
      </div>
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
        <SettingsSidebar activeTab={activeTab} />
        <div style={{ flex: 1, minWidth: 0, background: 'white', display: 'flex', flexDirection: 'column' }}>
          {children}
        </div>
      </div>
    </div>
  );
}

function TrafficLights() {
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexShrink: 0 }}>
      <div style={{ width: 12, height: 12, borderRadius: 6, background: '#ff5f57', border: '0.5px solid rgba(0,0,0,.12)' }} />
      <div style={{ width: 12, height: 12, borderRadius: 6, background: '#febc2e', border: '0.5px solid rgba(0,0,0,.12)' }} />
      <div style={{ width: 12, height: 12, borderRadius: 6, background: '#28c840', border: '0.5px solid rgba(0,0,0,.12)' }} />
    </div>
  );
}

function SettingsSidebar({ activeTab }) {
  const items = [
    { label: 'General',  icon: <SFIcon name="gear" size={13} color="white" />,         color: '#9aa0a8' },
    { label: 'Rules',    icon: <SFIcon name="listBullet" size={13} color="white" />,   color: JBRAND.accent },
    { label: 'Browsers', icon: <SFIcon name="folderBadge" size={13} color="white" />,  color: '#f5a623' },
    { label: 'Advanced', icon: <SFIcon name="sliders" size={13} color="white" />,      color: '#34a853' },
    { label: 'About',    icon: <SFIcon name="info" size={13} color="white" />,         color: '#888' },
  ];
  return (
    <div style={{
      width: 200, flexShrink: 0, padding: '12px 0',
      background: 'rgba(246,246,248,1)',
      borderRight: '0.5px solid rgba(0,0,0,.08)',
      display: 'flex', flexDirection: 'column', gap: 1,
    }}>
      {items.map((it) => (
        <SettingsSidebarRow key={it.label} icon={it.icon} label={it.label}
          selected={it.label === activeTab} color={it.color} />
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Header used inside the Rules content area
// ─────────────────────────────────────────────────────────────
function RulesHeader({ subtitle, action, search }) {
  return (
    <div style={{ padding: '18px 22px 14px' }}>
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 12 }}>
        <div>
          <div style={{ fontSize: 22, fontWeight: 600, color: '#1a1a1a', letterSpacing: -0.3 }}>Rules</div>
          <div style={{ fontSize: 12.5, color: 'rgba(0,0,0,.55)', marginTop: 3, maxWidth: 480 }}>{subtitle}</div>
        </div>
        {action}
      </div>
      {search}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// R1 — Native+ (refined baseline)
// • Status dot replaced with a slim left rail that doubles as enabled toggle
// • Search at top; count + actions at bottom
// • Better separation of matcher → target with proper arrow + chip
// • Grouped striped rows look quieter at 20+ rules
// ─────────────────────────────────────────────────────────────
function RulesNative() {
  return (
    <SettingsWindow activeTab="Rules">
      <RulesHeader
        subtitle="Evaluated top-to-bottom; the first enabled match wins. Anything that doesn't match pops the picker."
        action={
          <div style={{ display: 'flex', gap: 8 }}>
            <button style={btnDefault()}><SFIcon name="doc.text" size={11} /> rules.json</button>
            <button style={btnPrimary()}><SFIcon name="plus" size={11} color="white" /> New rule</button>
          </div>
        }
        search={
          <div style={{ marginTop: 14, display: 'flex', alignItems: 'center', gap: 10,
            padding: '6px 10px', borderRadius: 8, background: 'rgba(0,0,0,.04)' }}>
            <SFIcon name="search" size={13} color="rgba(0,0,0,.5)" />
            <input placeholder="Filter rules" readOnly style={{
              flex: 1, border: 'none', outline: 'none', background: 'transparent',
              fontFamily: JFONT, fontSize: 13, color: 'rgba(0,0,0,.85)',
            }} />
            <span style={{ fontSize: 11, color: 'rgba(0,0,0,.4)' }}>
              {MOCK_RULES.filter(r => r.enabled).length} of {MOCK_RULES.length} enabled
            </span>
          </div>
        }
      />
      <div style={{ height: 0.5, background: 'rgba(0,0,0,.08)' }} />
      <div style={{ flex: 1, overflow: 'auto', padding: '0 12px' }}>
        {MOCK_RULES.slice(0, 9).map((rule, i) => (
          <NativeRow key={rule.id} rule={rule} selected={i === 0} />
        ))}
      </div>
      <RuleFooterBar />
    </SettingsWindow>
  );
}

function NativeRow({ rule, selected }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '10px 10px',
      borderRadius: 8, background: selected ? 'rgba(30,109,255,.08)' : 'transparent',
      borderBottom: '0.5px solid rgba(0,0,0,.06)',
      opacity: rule.enabled ? 1 : 0.5,
    }}>
      {/* enabled rail */}
      <div style={{ width: 3, height: 28, borderRadius: 2,
        background: rule.enabled ? '#34a853' : 'rgba(0,0,0,.18)' }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color: '#1a1a1a',
          textDecoration: rule.enabled ? 'none' : 'line-through' }}>{rule.name}</div>
        <div style={{ marginTop: 3, display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
          <MatcherChip m={rule.match} />
          <SFIcon name="arrowRight" size={10} color="rgba(0,0,0,.4)" />
          <TargetChip t={rule.target} />
        </div>
      </div>
      <MacToggle on={rule.enabled} size={0.8} />
    </div>
  );
}

function MatcherChip({ m }) {
  const kindLabel = { host: 'host', hostRegex: 'regex', urlContains: 'contains' }[m.kind];
  const kindColor = { host: '#1f7a4a', hostRegex: '#c2622e', urlContains: '#7848c2' }[m.kind];
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5,
      fontFamily: JFONT, fontSize: 11, lineHeight: 1.2 }}>
      <span style={{
        padding: '1px 6px', borderRadius: 4, fontSize: 10, fontWeight: 700,
        background: `${kindColor}1a`, color: kindColor, textTransform: 'uppercase', letterSpacing: 0.4,
      }}>{kindLabel}</span>
      <span style={{ fontFamily: JMONO, fontSize: 11.5, color: 'rgba(0,0,0,.7)' }}>{m.value}</span>
    </span>
  );
}

function TargetChip({ t }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5,
      padding: '1px 6px 1px 4px', borderRadius: 6,
      background: 'rgba(0,0,0,.04)', border: '0.5px solid rgba(0,0,0,.06)' }}>
      <BrowserIcon name={t.browser} size={14} />
      <span style={{ fontSize: 11.5, fontWeight: 600, color: '#1a1a1a' }}>{t.browserName}</span>
      {t.profile && (
        <span style={{ fontSize: 10.5, color: 'rgba(0,0,0,.55)' }}>· {t.profile}</span>
      )}
    </span>
  );
}

function btnDefault(extra) {
  return {
    display: 'inline-flex', alignItems: 'center', gap: 5,
    padding: '6px 11px', borderRadius: 7, border: '0.5px solid rgba(0,0,0,.15)',
    background: 'white', fontFamily: JFONT, fontSize: 12, fontWeight: 500,
    color: '#1a1a1a', cursor: 'pointer', boxShadow: '0 1px 0 rgba(0,0,0,.04)',
    ...extra,
  };
}
function btnPrimary(extra) {
  return {
    display: 'inline-flex', alignItems: 'center', gap: 5,
    padding: '6px 12px', borderRadius: 7, border: 'none',
    background: JBRAND.accent, color: 'white',
    fontFamily: JFONT, fontSize: 12, fontWeight: 600, cursor: 'pointer',
    boxShadow: '0 1px 0 rgba(0,0,0,.1)',
    ...extra,
  };
}

function RuleFooterBar() {
  return (
    <div style={{
      borderTop: '0.5px solid rgba(0,0,0,.08)',
      padding: '8px 14px', display: 'flex', alignItems: 'center', gap: 6,
      background: 'rgba(248,248,250,1)',
    }}>
      <button style={iconBtn()}><SFIcon name="plus" size={12} /></button>
      <button style={iconBtn()}><SFIcon name="minus" size={12} /></button>
      <button style={iconBtn()}><SFIcon name="pencil" size={12} /></button>
      <div style={{ width: 0.5, height: 18, background: 'rgba(0,0,0,.12)', margin: '0 4px' }} />
      <button style={{ ...iconBtn(), width: 'auto', padding: '0 8px', gap: 4 }}>
        <SFIcon name="wand" size={11} /><span style={{ fontSize: 11 }}>Test URL…</span>
      </button>
      <div style={{ flex: 1 }} />
      <span style={{ fontSize: 11, color: 'rgba(0,0,0,.5)' }}>
        Stored in <code style={{ fontFamily: JMONO }}>~/Library/Application Support/Junction/rules.json</code>
      </span>
    </div>
  );
}

function iconBtn() {
  return {
    width: 26, height: 22, borderRadius: 5, border: 'none',
    background: 'transparent', cursor: 'pointer',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    color: 'rgba(0,0,0,.7)',
  };
}

// ─────────────────────────────────────────────────────────────
// R2 — Grouped by target browser
// • Each browser is a collapsible group with its rules under it
// • The header shows the icon + count; rules show only the matcher
//   (target is implied by the group)
// • "0 rules for Firefox" rows nudge toward adding more
// ─────────────────────────────────────────────────────────────
function RulesGrouped() {
  // Group by browser
  const groups = {};
  MOCK_RULES.forEach((r) => {
    const k = r.target.browserName;
    if (!groups[k]) groups[k] = { browser: r.target, rules: [] };
    groups[k].rules.push(r);
  });
  const order = ['Chrome', 'Safari', 'Arc', 'Firefox'];
  return (
    <SettingsWindow activeTab="Rules">
      <RulesHeader
        subtitle="Grouped by destination. Each group is the browser a matched URL ends up in — drag rules between groups to reroute."
        action={<button style={btnPrimary()}><SFIcon name="plus" size={11} color="white" /> New rule</button>}
      />
      <div style={{ height: 0.5, background: 'rgba(0,0,0,.08)' }} />
      <div style={{ flex: 1, overflow: 'auto', padding: '6px 0' }}>
        {order.map((key) => {
          const g = groups[key];
          if (!g) return null;
          return <RuleGroup key={key} group={g} />;
        })}
        <div style={{ padding: '8px 22px' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10, padding: 12,
            borderRadius: 10, border: '1px dashed rgba(0,0,0,.18)',
            color: 'rgba(0,0,0,.55)', fontSize: 12.5,
          }}>
            <SFIcon name="plus" size={14} color="rgba(0,0,0,.45)" />
            <span><b style={{ color: 'rgba(0,0,0,.75)' }}>Add a group</b> · choose a browser to start collecting rules for</span>
          </div>
        </div>
      </div>
      <RuleFooterBar />
    </SettingsWindow>
  );
}

function RuleGroup({ group }) {
  const t = group.browser;
  return (
    <div style={{ padding: '4px 16px 12px' }}>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '8px 10px', borderRadius: 8,
        background: 'rgba(0,0,0,.03)',
      }}>
        <SFIcon name="chevronDown" size={11} color="rgba(0,0,0,.5)" />
        <BrowserIcon name={t.browser} size={20} />
        <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>{t.browserName}</div>
        {t.profile && (
          <span style={{ fontSize: 11, color: 'rgba(0,0,0,.55)',
            padding: '1px 6px', borderRadius: 4, background: 'rgba(0,0,0,.06)' }}>{t.profile}</span>
        )}
        <div style={{ flex: 1 }} />
        <span style={{ fontSize: 11, color: 'rgba(0,0,0,.5)', fontVariantNumeric: 'tabular-nums' }}>
          {group.rules.length} rule{group.rules.length === 1 ? '' : 's'}
        </span>
        <button style={iconBtn()}><SFIcon name="plus" size={12} /></button>
      </div>
      <div style={{ marginTop: 4, paddingLeft: 14 }}>
        {group.rules.map((r) => (
          <div key={r.id} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '8px 8px 8px 12px', borderBottom: '0.5px solid rgba(0,0,0,.05)',
            opacity: r.enabled ? 1 : 0.5,
          }}>
            <SFIcon name="handDraggable" size={12} color="rgba(0,0,0,.3)" />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 500, color: '#1a1a1a' }}>{r.name}</div>
              <div style={{ marginTop: 2 }}><MatcherChip m={r.match} /></div>
            </div>
            <MacToggle on={r.enabled} size={0.75} />
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// R3 — Two-pane editor (list + inline rule detail)
// • No sheet, no modal: rule editor lives in the right pane
// • Live test field always visible in the editor
// • Picking another rule in the list switches the pane
// ─────────────────────────────────────────────────────────────
function RulesTwoPane() {
  const selected = MOCK_RULES[1]; // Google Workspace
  return (
    <SettingsWindow activeTab="Rules">
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
        {/* Rule list pane */}
        <div style={{
          width: 280, flexShrink: 0, borderRight: '0.5px solid rgba(0,0,0,.08)',
          display: 'flex', flexDirection: 'column', background: 'rgba(250,250,252,1)',
        }}>
          <div style={{ padding: '14px 14px 8px' }}>
            <div style={{ fontSize: 16, fontWeight: 600, color: '#1a1a1a' }}>Rules</div>
            <div style={{ fontSize: 11, color: 'rgba(0,0,0,.5)', marginTop: 2 }}>
              {MOCK_RULES.length} rules · {MOCK_RULES.filter(r => r.enabled).length} enabled
            </div>
            <div style={{ marginTop: 10, display: 'flex', alignItems: 'center', gap: 6,
              padding: '5px 8px', borderRadius: 6, background: 'rgba(0,0,0,.05)' }}>
              <SFIcon name="search" size={11} color="rgba(0,0,0,.45)" />
              <input placeholder="Filter" readOnly style={{ border: 'none', outline: 'none',
                background: 'transparent', flex: 1, fontFamily: JFONT, fontSize: 12 }} />
            </div>
          </div>
          <div style={{ flex: 1, overflow: 'auto', padding: '4px 6px' }}>
            {MOCK_RULES.slice(0, 9).map((r) => (
              <div key={r.id} style={{
                display: 'flex', alignItems: 'center', gap: 8, padding: '7px 10px',
                borderRadius: 6, marginBottom: 1, cursor: 'pointer',
                background: r.id === selected.id ? JBRAND.accent : 'transparent',
                color: r.id === selected.id ? 'white' : 'inherit',
                opacity: r.enabled ? 1 : 0.55,
              }}>
                <div style={{ width: 6, height: 6, borderRadius: 3, flexShrink: 0,
                  background: r.enabled ? (r.id === selected.id ? 'white' : '#34a853') : 'rgba(0,0,0,.25)' }} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 12.5, fontWeight: 500,
                    whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                    color: r.id === selected.id ? 'white' : '#1a1a1a' }}>{r.name}</div>
                  <div style={{ fontSize: 10.5, fontFamily: JMONO,
                    whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                    color: r.id === selected.id ? 'rgba(255,255,255,.7)' : 'rgba(0,0,0,.5)' }}>
                    {r.match.value}
                  </div>
                </div>
                <BrowserIcon name={r.target.browser} size={16} />
              </div>
            ))}
          </div>
          <div style={{ padding: 8, borderTop: '0.5px solid rgba(0,0,0,.08)',
            display: 'flex', alignItems: 'center', gap: 4 }}>
            <button style={iconBtn()}><SFIcon name="plus" size={12} /></button>
            <button style={iconBtn()}><SFIcon name="minus" size={12} /></button>
            <div style={{ flex: 1 }} />
            <button style={{ ...btnDefault(), padding: '4px 9px', fontSize: 11 }}>
              <SFIcon name="doc.text" size={10} /> rules.json
            </button>
          </div>
        </div>

        {/* Editor pane */}
        <div style={{ flex: 1, minWidth: 0, overflow: 'auto', padding: 22 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
            <input value={selected.name} readOnly style={{
              flex: 1, border: 'none', outline: 'none', background: 'transparent',
              fontFamily: JFONT, fontSize: 19, fontWeight: 600, color: '#1a1a1a',
              padding: 0,
            }} />
            <span style={{ fontSize: 11, color: 'rgba(0,0,0,.55)' }}>Enabled</span>
            <MacToggle on size={0.85} />
          </div>

          <FormSection title="Match">
            <FormRow label="Type">
              <Segmented value="hostRegex" options={[
                { value: 'host', label: 'Host' },
                { value: 'hostRegex', label: 'Regex' },
                { value: 'urlContains', label: 'Contains' },
              ]} />
            </FormRow>
            <FormRow label="Pattern">
              <CodeInput value={selected.match.value} />
            </FormRow>
            <FormRow label="">
              <div style={{ fontSize: 11.5, color: 'rgba(0,0,0,.55)', lineHeight: 1.45 }}>
                Matches the URL's host, case-insensitive. Use parentheses for alternatives.
              </div>
            </FormRow>
          </FormSection>

          <FormSection title="Target">
            <FormRow label="Browser">
              <BrowserPickerInline />
            </FormRow>
            <FormRow label="Profile">
              <ProfileDropdown value="Work" />
            </FormRow>
            <FormRow label="">
              <label style={{ display: 'inline-flex', alignItems: 'center', gap: 7,
                fontSize: 12.5, color: 'rgba(0,0,0,.8)', cursor: 'pointer' }}>
                <MacCheck on={false} />
                Open in new window
              </label>
            </FormRow>
          </FormSection>

          <FormSection title="Test a URL">
            <CodeInput value="https://mail.google.com/mail/u/0/" />
            <div style={{ marginTop: 8, display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '5px 9px', borderRadius: 6, background: 'rgba(52,168,83,.12)', color: '#1f7a4a',
              fontSize: 12, fontWeight: 600 }}>
              <SFIcon name="check" size={11} color="#1f7a4a" weight={2.2} />
              Matches — routes to Chrome (Work)
            </div>
          </FormSection>
        </div>
      </div>
    </SettingsWindow>
  );
}

function FormSection({ title, children }) {
  return (
    <div style={{ marginBottom: 22 }}>
      <div style={{ fontSize: 11, fontWeight: 700, color: 'rgba(0,0,0,.55)',
        textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 8 }}>{title}</div>
      <div style={{ background: 'rgba(0,0,0,.025)', borderRadius: 10,
        border: '0.5px solid rgba(0,0,0,.06)', padding: '4px 12px' }}>
        {children}
      </div>
    </div>
  );
}
function FormRow({ label, children }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12,
      padding: '8px 0', borderBottom: '0.5px solid rgba(0,0,0,.06)' }}>
      <div style={{ width: 90, fontSize: 12, color: 'rgba(0,0,0,.65)', paddingTop: 4 }}>{label}</div>
      <div style={{ flex: 1, minWidth: 0 }}>{children}</div>
    </div>
  );
}
function Segmented({ value, options }) {
  return (
    <div style={{ display: 'inline-flex', borderRadius: 6, padding: 1.5,
      background: 'rgba(0,0,0,.05)', border: '0.5px solid rgba(0,0,0,.06)' }}>
      {options.map((o) => (
        <div key={o.value} style={{
          padding: '3px 12px', borderRadius: 5, fontSize: 12, fontWeight: 500,
          background: o.value === value ? 'white' : 'transparent',
          color: o.value === value ? '#1a1a1a' : 'rgba(0,0,0,.65)',
          boxShadow: o.value === value ? '0 1px 2px rgba(0,0,0,.06)' : 'none',
        }}>{o.label}</div>
      ))}
    </div>
  );
}
function CodeInput({ value }) {
  return (
    <div style={{
      padding: '5px 10px', borderRadius: 6,
      background: 'white', border: '0.5px solid rgba(0,0,0,.18)',
      fontFamily: JMONO, fontSize: 12.5, color: '#1a1a1a', lineHeight: 1.5,
      boxShadow: 'inset 0 1px 0 rgba(0,0,0,.02)',
      overflowWrap: 'anywhere', wordBreak: 'break-all',
    }}>{value}</div>
  );
}
function BrowserPickerInline() {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 8,
      padding: '4px 8px 4px 6px', borderRadius: 6, background: 'white',
      border: '0.5px solid rgba(0,0,0,.18)', fontSize: 13, fontWeight: 500,
      color: '#1a1a1a', minWidth: 200,
    }}>
      <BrowserIcon name="chrome" size={18} />
      <span>Chrome</span>
      <div style={{ flex: 1 }} />
      <SFIcon name="chevronDown" size={11} color="rgba(0,0,0,.55)" />
    </div>
  );
}
function ProfileDropdown({ value }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 8,
      padding: '4px 8px 4px 10px', borderRadius: 6, background: 'white',
      border: '0.5px solid rgba(0,0,0,.18)', fontSize: 13, fontWeight: 500,
      color: '#1a1a1a', minWidth: 200,
    }}>
      <span style={{ width: 8, height: 8, borderRadius: 4, background: '#1f7a4a' }} />
      <span>{value}</span>
      <div style={{ flex: 1 }} />
      <SFIcon name="chevronDown" size={11} color="rgba(0,0,0,.55)" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// R4 — Pipeline / Flow
// • Rules visualized as a column of "filters" that a URL drops through
// • The first that matches catches the URL; rest fall through
// • Reorder = drag a card up/down
// • Below: a catch-all "→ Picker" terminator
// • Bolder visual: makes the precedence-of-rules model concrete
// ─────────────────────────────────────────────────────────────
function RulesFlow() {
  const rules = MOCK_RULES.slice(0, 5);
  return (
    <SettingsWindow activeTab="Rules">
      <RulesHeader
        subtitle="A URL flows top-to-bottom. The first rule that catches it wins; anything that falls through ends up at the picker."
        action={
          <div style={{ display: 'flex', gap: 8 }}>
            <button style={btnDefault()}>List view</button>
            <button style={btnPrimary()}><SFIcon name="plus" size={11} color="white" /> New rule</button>
          </div>
        }
      />
      <div style={{ height: 0.5, background: 'rgba(0,0,0,.08)' }} />
      <div style={{
        flex: 1, overflow: 'auto', padding: '20px 24px',
        background: 'linear-gradient(180deg, rgba(0,0,0,0) 0%, rgba(0,0,0,.02) 100%)',
      }}>
        <div style={{ maxWidth: 560, margin: '0 auto', position: 'relative' }}>
          {/* URL entry chip */}
          <FlowChip>
            <HostGlyph host={PICK_HOST} size={16} />
            <span style={{ fontFamily: JMONO, fontSize: 12.5 }}>{PICK_HOST}/item?…</span>
            <span style={{ marginLeft: 'auto', fontSize: 10.5, color: 'rgba(0,0,0,.5)',
              textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 700 }}>Incoming URL</span>
          </FlowChip>
          <FlowArrow />
          {rules.map((r, i) => (
            <React.Fragment key={r.id}>
              <FlowRule rule={r} caught={i === 2} skipped={i < 2} />
              <FlowArrow muted={i >= 2} />
            </React.Fragment>
          ))}
          <FlowChip terminator>
            <SFIcon name="signpost" size={16} color="rgba(0,0,0,.55)" />
            <span style={{ fontSize: 12.5, fontWeight: 600 }}>Show the picker</span>
            <span style={{ marginLeft: 'auto', fontSize: 11, color: 'rgba(0,0,0,.5)' }}>fallback</span>
          </FlowChip>
        </div>
      </div>
      <RuleFooterBar />
    </SettingsWindow>
  );
}

function FlowChip({ children, terminator }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '10px 14px', borderRadius: 10,
      background: terminator ? 'rgba(0,0,0,.04)' : 'white',
      border: terminator ? '1px dashed rgba(0,0,0,.18)' : '0.5px solid rgba(0,0,0,.12)',
      boxShadow: terminator ? 'none' : '0 1px 3px rgba(0,0,0,.04)',
    }}>{children}</div>
  );
}

function FlowArrow({ muted }) {
  return (
    <div style={{ height: 18, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ width: 1, height: '100%',
        background: muted ? 'rgba(0,0,0,.08)' : 'rgba(0,0,0,.18)' }} />
    </div>
  );
}

function FlowRule({ rule, caught, skipped }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'stretch', gap: 0, position: 'relative',
      borderRadius: 12,
      background: caught
        ? 'linear-gradient(180deg, rgba(52,168,83,.07), rgba(52,168,83,.02))'
        : (skipped ? 'rgba(0,0,0,.02)' : 'white'),
      border: caught
        ? '1.5px solid rgba(52,168,83,.5)'
        : '0.5px solid rgba(0,0,0,.12)',
      boxShadow: caught ? '0 4px 16px rgba(52,168,83,.15)' : '0 1px 2px rgba(0,0,0,.03)',
      opacity: skipped ? 0.55 : 1,
    }}>
      {/* drag rail */}
      <div style={{ width: 24, display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: 'rgba(0,0,0,.25)' }}>
        <SFIcon name="handDraggable" size={12} color="rgba(0,0,0,.3)" />
      </div>
      <div style={{ flex: 1, padding: '10px 12px 12px 0' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>{rule.name}</div>
          {caught && (
            <span style={{ fontSize: 10.5, fontWeight: 700, color: '#1f7a4a',
              padding: '1px 6px', borderRadius: 4, background: 'rgba(52,168,83,.15)',
              textTransform: 'uppercase', letterSpacing: 0.4 }}>
              caught
            </span>
          )}
          {skipped && (
            <span style={{ fontSize: 10.5, color: 'rgba(0,0,0,.45)' }}>didn't match</span>
          )}
          <div style={{ flex: 1 }} />
          <MacToggle on={rule.enabled} size={0.7} />
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <MatcherChip m={rule.match} />
          <SFIcon name="arrowRight" size={11} color="rgba(0,0,0,.4)" />
          <TargetChip t={rule.target} />
        </div>
      </div>
      {caught && (
        <div style={{
          position: 'absolute', right: -10, top: '50%', transform: 'translateY(-50%)',
          width: 20, height: 20, borderRadius: 10,
          background: '#34a853', color: 'white',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 2px 6px rgba(52,168,83,.4)',
        }}>
          <SFIcon name="check" size={11} color="white" weight={2.5} />
        </div>
      )}
    </div>
  );
}

Object.assign(window, {
  SettingsWindow, SettingsSidebar, RulesHeader,
  RulesNative, RulesGrouped, RulesTwoPane, RulesFlow, RulesHybrid,
  MatcherChip, TargetChip,
});

// ─────────────────────────────────────────────────────────────
// R5 — Hybrid: R3's two-pane editor + R2's grouped sidebar
// • Left pane: rules grouped under their target browser
// • Right pane: inline editor with live URL test (no modal)
// • Scales well past 50 rules: groups stay compact, search filters
//   across all groups, picking a rule swaps the right pane.
// ─────────────────────────────────────────────────────────────
function RulesHybrid() {
  const selected = MOCK_RULES[1]; // Google Workspace
  // Group by browser, preserve list order within each group
  const groups = {};
  MOCK_RULES.forEach((r) => {
    const k = r.target.browserName;
    if (!groups[k]) groups[k] = { browser: r.target, rules: [] };
    groups[k].rules.push(r);
  });
  const order = ['Chrome', 'Safari', 'Arc', 'Firefox'];

  return (
    <SettingsWindow activeTab="Rules">
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
        {/* Rule list pane (grouped) */}
        <div style={{
          width: 300, flexShrink: 0, borderRight: '0.5px solid rgba(0,0,0,.08)',
          display: 'flex', flexDirection: 'column', background: 'rgba(250,250,252,1)',
        }}>
          <div style={{ padding: '14px 14px 8px' }}>
            <div style={{ fontSize: 16, fontWeight: 600, color: '#1a1a1a' }}>Rules</div>
            <div style={{ fontSize: 11, color: 'rgba(0,0,0,.5)', marginTop: 2 }}>
              {MOCK_RULES.length} rules · grouped by destination
            </div>
            <div style={{ marginTop: 10, display: 'flex', alignItems: 'center', gap: 6,
              padding: '5px 8px', borderRadius: 6, background: 'rgba(0,0,0,.05)' }}>
              <SFIcon name="search" size={11} color="rgba(0,0,0,.45)" />
              <input placeholder="Filter all rules" readOnly style={{ border: 'none', outline: 'none',
                background: 'transparent', flex: 1, fontFamily: JFONT, fontSize: 12 }} />
            </div>
          </div>
          <div style={{ flex: 1, overflow: 'auto', padding: '4px 0 8px' }}>
            {order.map((key) => {
              const g = groups[key];
              if (!g) return null;
              return (
                <HybridGroup key={key} group={g} selectedId={selected.id} />
              );
            })}
          </div>
          <div style={{ padding: 8, borderTop: '0.5px solid rgba(0,0,0,.08)',
            display: 'flex', alignItems: 'center', gap: 4 }}>
            <button style={iconBtn()}><SFIcon name="plus" size={12} /></button>
            <button style={iconBtn()}><SFIcon name="minus" size={12} /></button>
            <div style={{ flex: 1 }} />
            <button style={{ ...btnDefault(), padding: '4px 9px', fontSize: 11 }}>
              <SFIcon name="doc.text" size={10} /> rules.json
            </button>
          </div>
        </div>

        {/* Editor pane (visual matcher — no regex by default) */}
        <div style={{ flex: 1, minWidth: 0, overflow: 'auto', padding: 22 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 18 }}>
            <input value={selected.name} readOnly style={{
              flex: 1, border: 'none', outline: 'none', background: 'transparent',
              fontFamily: JFONT, fontSize: 19, fontWeight: 600, color: '#1a1a1a',
              padding: 0,
            }} />
            <span style={{ fontSize: 11, color: 'rgba(0,0,0,.55)' }}>Enabled</span>
            <MacToggle on size={0.85} />
          </div>

          {/* Match — visual chips, no rigid label column */}
          <SectionHeader>When a link goes to</SectionHeader>
          <div style={{
            padding: '12px 14px', borderRadius: 10,
            background: 'rgba(0,0,0,.025)', border: '0.5px solid rgba(0,0,0,.06)',
            marginBottom: 18,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
              {[
                'mail.google.com',
                'calendar.google.com',
                'docs.google.com',
                'drive.google.com',
                'meet.google.com',
              ].map((h) => (
                <HostChip key={h} host={h} />
              ))}
              <button style={addChipBtn()}>
                <SFIcon name="plus" size={10} color="rgba(0,0,0,.6)" />
                Add host
              </button>
            </div>
            <div style={{
              marginTop: 10, paddingTop: 10,
              borderTop: '0.5px solid rgba(0,0,0,.06)',
              display: 'flex', flexDirection: 'column', gap: 6,
            }}>
              <label style={inlineOptStyle()}>
                <MacCheck on />
                <span><b style={{ fontWeight: 500 }}>Include subdomains</b>
                  <span style={{ color: 'rgba(0,0,0,.45)' }}>
                    {' '}— so <code style={{ fontFamily: JMONO, fontSize: 11 }}>m.mail.google.com</code> matches too
                  </span>
                </span>
              </label>
              <label style={inlineOptStyle()}>
                <MacCheck on={false} />
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                  <span style={{ fontWeight: 500 }}>Only if the URL contains</span>
                  <input placeholder="e.g. /mail/u/0" readOnly style={{
                    padding: '2px 8px', fontFamily: JMONO, fontSize: 11.5,
                    width: 140, borderRadius: 5, border: '0.5px solid rgba(0,0,0,.18)',
                    background: 'white', color: 'rgba(0,0,0,.7)', outline: 'none',
                  }} />
                </span>
              </label>
              <details style={{ marginTop: 2 }}>
                <summary style={{
                  cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 5,
                  fontSize: 11.5, color: 'rgba(0,0,0,.55)', userSelect: 'none',
                  listStyle: 'none',
                }}>
                  <SFIcon name="chevronDown" size={9} color="rgba(0,0,0,.5)" />
                  Edit as regex (advanced)
                </summary>
                <div style={{ marginTop: 8, marginLeft: 14 }}>
                  <CodeInput value={selected.match.value} />
                  <div style={{ marginTop: 4, fontSize: 11, color: 'rgba(0,0,0,.5)',
                    lineHeight: 1.45 }}>
                    Switching to raw mode disables the chips. Simple host lists can be
                    converted back automatically.
                  </div>
                </div>
              </details>
            </div>
          </div>

          {/* Target */}
          <SectionHeader>Open it in</SectionHeader>
          <div style={{
            padding: '8px 14px', borderRadius: 10,
            background: 'rgba(0,0,0,.025)', border: '0.5px solid rgba(0,0,0,.06)',
            marginBottom: 18, display: 'flex', flexDirection: 'column', gap: 10,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, paddingTop: 6 }}>
              <span style={{ width: 64, fontSize: 12, color: 'rgba(0,0,0,.6)' }}>Browser</span>
              <BrowserPickerInline />
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ width: 64, fontSize: 12, color: 'rgba(0,0,0,.6)' }}>Profile</span>
              <ProfileDropdown value="Work" />
            </div>
            <label style={{ ...inlineOptStyle(), paddingBottom: 6 }}>
              <MacCheck on={false} />
              <span style={{ fontWeight: 500 }}>Open in a new window</span>
            </label>
          </div>

          {/* Test */}
          <SectionHeader>Test a URL</SectionHeader>
          <div style={{
            padding: '12px 14px', borderRadius: 10,
            background: 'rgba(0,0,0,.025)', border: '0.5px solid rgba(0,0,0,.06)',
          }}>
            <CodeInput value="https://mail.google.com/mail/u/0/" />
            <div style={{ marginTop: 8, display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '5px 9px', borderRadius: 6, background: 'rgba(52,168,83,.12)', color: '#1f7a4a',
              fontSize: 12, fontWeight: 600 }}>
              <SFIcon name="check" size={11} color="#1f7a4a" weight={2.2} />
              Matches <code style={{ fontFamily: JMONO, fontWeight: 500 }}>mail.google.com</code> — routes to Chrome (Work)
            </div>
          </div>
        </div>
      </div>
    </SettingsWindow>
  );
}

function SectionHeader({ children }) {
  return (
    <div style={{ fontSize: 11, fontWeight: 700, color: 'rgba(0,0,0,.55)',
      textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 8 }}>{children}</div>
  );
}

function inlineOptStyle() {
  return {
    display: 'inline-flex', alignItems: 'center', gap: 7,
    fontSize: 12.5, color: 'rgba(0,0,0,.8)', cursor: 'pointer',
    fontFamily: JFONT,
  };
}

// Visual host chip used by the matcher
function HostChip({ host }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '4px 6px 4px 8px', borderRadius: 7,
      background: 'white', border: '0.5px solid rgba(0,0,0,.18)',
      fontFamily: JMONO, fontSize: 12, fontWeight: 500, color: '#1a1a1a',
      boxShadow: '0 1px 2px rgba(0,0,0,.04)',
    }}>
      <HostGlyph host={host} size={12} />
      {host}
      <span style={{
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        width: 14, height: 14, borderRadius: 7, marginLeft: 2,
        color: 'rgba(0,0,0,.4)', cursor: 'pointer',
      }}>
        <SFIcon name="x" size={9} color="rgba(0,0,0,.5)" weight={2.2} />
      </span>
    </span>
  );
}

function addChipBtn() {
  return {
    display: 'inline-flex', alignItems: 'center', gap: 4,
    padding: '4px 9px', borderRadius: 7,
    background: 'rgba(0,0,0,.03)', border: '0.5px dashed rgba(0,0,0,.22)',
    fontFamily: JFONT, fontSize: 12, fontWeight: 500, color: 'rgba(0,0,0,.65)',
    cursor: 'pointer',
  };
}

function HybridGroup({ group, selectedId }) {
  const t = group.browser;
  return (
    <div style={{ marginBottom: 4 }}>
      {/* Group header */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 7,
        padding: '6px 12px 6px 10px',
        fontSize: 11, fontWeight: 700,
        color: 'rgba(0,0,0,.55)', textTransform: 'uppercase', letterSpacing: 0.5,
      }}>
        <SFIcon name="chevronDown" size={9} color="rgba(0,0,0,.45)" />
        <BrowserIcon name={t.browser} size={14} />
        <span style={{ color: '#1a1a1a', textTransform: 'none', letterSpacing: 0,
          fontWeight: 600, fontSize: 12.5 }}>{t.browserName}</span>
        <div style={{ flex: 1 }} />
        <span style={{ fontVariantNumeric: 'tabular-nums', color: 'rgba(0,0,0,.4)',
          fontSize: 10.5, fontWeight: 600 }}>{group.rules.length}</span>
      </div>
      {/* Rules in this group */}
      <div style={{ padding: '0 6px' }}>
        {group.rules.map((r) => {
          const isSel = r.id === selectedId;
          return (
            <div key={r.id} style={{
              display: 'flex', alignItems: 'center', gap: 8, padding: '7px 10px 7px 22px',
              borderRadius: 6, marginBottom: 1, cursor: 'pointer',
              background: isSel ? JBRAND.accent : 'transparent',
              color: isSel ? 'white' : 'inherit',
              opacity: r.enabled ? 1 : 0.55,
              position: 'relative',
            }}>
              <div style={{
                position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)',
                width: 6, height: 6, borderRadius: 3,
                background: r.enabled
                  ? (isSel ? 'white' : '#34a853')
                  : 'rgba(0,0,0,.25)',
              }} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12.5, fontWeight: 500,
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                  color: isSel ? 'white' : '#1a1a1a' }}>{r.name}</div>
                <div style={{ fontSize: 10.5, fontFamily: JMONO,
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                  color: isSel ? 'rgba(255,255,255,.7)' : 'rgba(0,0,0,.5)' }}>
                  {r.match.value}
                </div>
              </div>
              {t.profile && r.target.profile && (
                <span style={{
                  fontSize: 9.5, fontWeight: 600,
                  padding: '1px 5px', borderRadius: 3,
                  background: isSel ? 'rgba(255,255,255,.18)' : 'rgba(0,0,0,.05)',
                  color: isSel ? 'rgba(255,255,255,.85)' : 'rgba(0,0,0,.55)',
                  whiteSpace: 'nowrap',
                }}>{r.target.profile}</span>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

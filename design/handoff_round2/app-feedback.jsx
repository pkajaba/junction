// app-feedback.jsx — design canvas dedicated to the 5 improvement mocks
function FeedbackApp() {
  return (
    <DesignCanvas>
      <DCSection id="intro" title="Junction · Settings improvements"
        subtitle="Five focused changes to the shipped Settings window, prioritized by user value. Each mock is a direct replacement for one screen — same chrome, same vocabulary, surgical edits.">
        <DCArtboard id="readme" label="What's in here" width={760} height={520}>
          <FBReadme />
        </DCArtboard>
      </DCSection>

      <DCSection id="m1" title="① Activity → rule-builder"
        subtitle="Highest leverage. Today Activity is empty-state-only. After: every received URL becomes either proof your rules work, or a one-click 'make a rule for this' moment.">
        <DCArtboard id="activity" label="✓ Activity · rebuilt" width={1000} height={660}>
          <ActivityRebuild />
        </DCArtboard>
      </DCSection>

      <DCSection id="m2" title="② Rules sidebar header"
        subtitle="Today the sidebar's whole top corner is empty and +/− are exiled to the bottom. Move + to the title row; expose grouping as a real dropdown (4 options).">
        <DCArtboard id="rules-header" label="✓ Rules · sidebar header" width={1000} height={660}>
          <RulesHeaderRebuild />
        </DCArtboard>
      </DCSection>

      <DCSection id="m3" title="③ Handoff disabled states"
        subtitle="Not-installed rows currently look identical to enabled ones. After: 'Install' affordance, lower opacity, no footer note needed.">
        <DCArtboard id="handoff" label="✓ Handoff · disabled states" width={1000} height={660}>
          <HandoffRebuild />
        </DCArtboard>
      </DCSection>

      <DCSection id="m4" title="④ Browsers empty state"
        subtitle="Six gray phantom rows below Safari/Chrome look like a loading bug. Replace with an explicit 'that's everything we found' card and a manual-add path.">
        <DCArtboard id="browsers" label="✓ Browsers · empty state" width={1000} height={660}>
          <BrowsersRebuild />
        </DCArtboard>
      </DCSection>

      <DCSection id="m5" title="⑤ Advanced hierarchy"
        subtitle="'Strip tracking parameters' is the headline feature; the param list is its config. Indent the list under the toggle and add an Add-param input.">
        <DCArtboard id="advanced" label="✓ Advanced · restructured" width={1000} height={660}>
          <AdvancedRebuild />
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

function FBReadme() {
  const items = [
    { n: '①', tag: 'Activity', title: 'Rule-builder, not a log',
      what: 'Each row shows matched-rule outcome OR a "no match · picker fallback" state. Hover any no-match row → "Create rule…" button. Filter chips highlight "No rule" in amber so attention goes where rules are needed.',
      impact: 'Turns the passive log into the fastest path to a new rule. The amber dot on the No-rule chip surfaces a backlog you didn\'t know you had.' },
    { n: '②', tag: 'Rules', title: 'Sidebar header carries the actions',
      what: 'Move + (primary, blue) and − to the title row. Replace static "grouped by destination" text with a real dropdown: Destination / Source app / Match type / Nothing. Filter input gets a ⌘F hint.',
      impact: 'No more wasted top-left corner; no more bottom-of-window toolbar. Grouping becomes a power tool instead of a label.' },
    { n: '③', tag: 'Handoff', title: 'Disabled rows look disabled',
      what: 'Installed: full opacity, working toggle. Not-installed: 55% opacity, dashed-outline icon placeholder, "Not installed ↗" button (links to vendor download) instead of a toggle. Footer note removed.',
      impact: 'You can tell at a glance which integrations are live. "Install" is a real call-to-action instead of dead text.' },
    { n: '④', tag: 'Browsers', title: 'Empty space, not phantom rows',
      what: 'Replace the gray skeleton rows with a dashed-outline card: "That\'s everything Junction found. Scans /Applications and ~/Applications. Add manually →"',
      impact: 'Stops looking like a loading bug. Surfaces the rare-but-real "add a custom browser" path.' },
    { n: '⑤', tag: 'Advanced', title: 'Toggle is the section header',
      what: '"Strip tracking parameters" promoted to a peer-of-the-page heading with the toggle inline. The param list nests under it as a card with header + add-row at the bottom. Appearance moved up as a compact card.',
      impact: 'Reads as one feature with config, not two parallel settings. The Add-param input fixes the missing affordance.' },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', boxSizing: 'border-box',
      padding: '24px 26px', background: 'white',
      fontFamily: JFONT, color: '#1a1a1a', overflow: 'auto',
    }}>
      <div style={{ marginBottom: 14 }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: JBRAND.accent,
          textTransform: 'uppercase', letterSpacing: 0.7 }}>Round 2 · post-build</div>
        <div style={{ fontSize: 22, fontWeight: 600, letterSpacing: -0.3, marginTop: 2 }}>
          Five surgical edits to the shipped Settings window
        </div>
        <div style={{ fontSize: 12.5, color: 'rgba(0,0,0,.6)', marginTop: 4, lineHeight: 1.5 }}>
          None of these change the IA or break the existing chrome. They fix specific moments where the current UI is either dead space, ambiguous state, or hiding affordances behind text.
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {items.map((it) => (
          <div key={it.n} style={{
            display: 'flex', gap: 12, padding: '10px 12px', borderRadius: 9,
            background: 'rgba(30,109,255,.04)', border: '0.5px solid rgba(30,109,255,.15)',
          }}>
            <div style={{
              width: 22, height: 22, flexShrink: 0,
              fontSize: 13, fontWeight: 700, color: JBRAND.accent,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>{it.n}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 7 }}>
                <span style={{
                  fontSize: 9.5, fontWeight: 700, color: JBRAND.accent,
                  textTransform: 'uppercase', letterSpacing: 0.7,
                  padding: '1px 6px', borderRadius: 3, background: 'rgba(30,109,255,.1)',
                }}>{it.tag}</span>
                <span style={{ fontSize: 13.5, fontWeight: 600 }}>{it.title}</span>
              </div>
              <div style={{ fontSize: 11.5, color: 'rgba(0,0,0,.7)', lineHeight: 1.5, marginTop: 3 }}>
                <b style={{ color: 'rgba(0,0,0,.55)', fontWeight: 600 }}>What changes:</b> {it.what}
              </div>
              <div style={{ fontSize: 11.5, color: 'rgba(0,0,0,.55)', lineHeight: 1.5, marginTop: 3 }}>
                <b style={{ color: 'rgba(0,0,0,.55)', fontWeight: 600 }}>Why:</b> {it.impact}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<FeedbackApp />);

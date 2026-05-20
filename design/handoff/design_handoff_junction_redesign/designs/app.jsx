// app.jsx — the design canvas composition

function App() {
  return (
    <DesignCanvas>
      <DCSection id="cover" title="Junction · Redesign Explorations"
        subtitle="A native-mac browser router. Picker, Rules tab, Editor, Onboarding, App icon.">
        <DCArtboard id="cover" label="Brief" width={720} height={460}>
          <CoverArtboard />
        </DCArtboard>
        <DCArtboard id="picks-summary" label="My picks" width={720} height={460}>
          <PicksSummary />
        </DCArtboard>
      </DCSection>

      <DCSection id="picks" title="✓ Recommended direction"
        subtitle="Three surfaces — the editor now lives inside the Rules right pane, so it’s not a separate destination.">
        <DCArtboard id="pick-picker" label="✓ Picker · Smart suggestion" width={760} height={560}>
          <PickerSmart />
        </DCArtboard>
        <DCArtboard id="pick-picker-fallback" label="✓ Picker · Suggestions off (fallback)" width={760} height={560}>
          <PickerSmart suggestions={false} />
        </DCArtboard>
        <DCArtboard id="pick-rules" label="✓ Rules + Editor · Grouped two-pane w/ visual matcher" width={920} height={640}>
          <RulesHybrid />
        </DCArtboard>
        <DCArtboard id="pick-icon" label="✓ Icon · Branch" width={340} height={420}>
          <AppIconArtboard Variant={IconBranch} name="Branch" description="A trunk splitting into two arrows — says “routing,” not “signpost.”" />
        </DCArtboard>
      </DCSection>

      <DCSection id="picker" title="Picker · alternates"
        subtitle="Six directions explored. P5 wins because making “Always” first-class and learning from history attacks the core friction.">
        <DCArtboard id="p5" label="✓ P5 · Smart suggestion (picked)" width={720} height={520}>
          <PickerSmart />
        </DCArtboard>
        <DCArtboard id="p3" label="P3 · Command list" width={720} height={520}>
          <PickerCommand />
        </DCArtboard>
        <DCArtboard id="p1" label="P1 · Native+" width={720} height={520}>
          <PickerNative />
        </DCArtboard>
        <DCArtboard id="p6" label="P6 · Profile-first" width={720} height={520}>
          <PickerProfile />
        </DCArtboard>
        <DCArtboard id="p2" label="P2 · Hero + Rail" width={720} height={520}>
          <PickerHero />
        </DCArtboard>
        <DCArtboard id="p4" label="P4 · Liquid Glass radial" width={720} height={520}>
          <PickerRadial />
        </DCArtboard>
      </DCSection>

      <DCSection id="rules" title="Settings · Rules · alternates"
        subtitle="R5 (grouped two-pane) wins — it combines the two best ideas: no modal sheet, and the sidebar stays scannable past 50 rules.">
        <DCArtboard id="r5" label="✓ R5 · Grouped two-pane (picked, R3+R2)" width={880} height={620}>
          <RulesHybrid />
        </DCArtboard>
        <DCArtboard id="r3" label="R3 · Two-pane (flat list)" width={880} height={620}>
          <RulesTwoPane />
        </DCArtboard>
        <DCArtboard id="r2" label="R2 · Grouped by target (modal editor)" width={880} height={620}>
          <RulesGrouped />
        </DCArtboard>
        <DCArtboard id="r1" label="R1 · Native+" width={880} height={620}>
          <RulesNative />
        </DCArtboard>
        <DCArtboard id="r4" label="R4 · Pipeline / Flow" width={880} height={620}>
          <RulesFlow />
        </DCArtboard>
      </DCSection>

      <DCSection id="editor-legacy" title="Rule editor · earlier (modal) explorations"
        subtitle="Superseded — the editor now lives in the right pane of Rules. Kept here for reference; both assumed a modal sheet, which we no longer need.">
        <DCArtboard id="e2" label="E2 · Sentence builder (chip idea folded into R5)" width={620} height={580}>
          <CenterFrame><EditorSentence /></CenterFrame>
        </DCArtboard>
        <DCArtboard id="e1" label="E1 · Refined sheet" width={620} height={580}>
          <CenterFrame><EditorSheet /></CenterFrame>
        </DCArtboard>
      </DCSection>

      <DCSection id="extras" title="Onboarding & Debug log"
        subtitle="Two surfaces the original brief doesn't lean on but should — first-run sets expectations, log proves trust.">
        <DCArtboard id="onb" label="First launch" width={720} height={520}>
          <OnboardingHero />
        </DCArtboard>
        <DCArtboard id="log" label="Debug log refresh" width={880} height={620}>
          <DebugLog />
        </DCArtboard>
      </DCSection>

      <DCSection id="icon" title="App icon · alternates"
        subtitle="I2 wins because the metaphor matches what Junction does: one URL splits into two destinations.">
        <DCArtboard id="i2" label="✓ I2 · Branch (picked)" width={340} height={420}>
          <AppIconArtboard Variant={IconBranch} name="Branch" description="A trunk splitting into two arrows. More “routing” than “signpost.”" />
        </DCArtboard>
        <DCArtboard id="i1" label="I1 · Signpost (current)" width={340} height={420}>
          <AppIconArtboard Variant={IconSignpost} name="Signpost" description="Shipped. Literal junction; reads instantly at every size." />
        </DCArtboard>
        <DCArtboard id="i3" label="I3 · Node" width={340} height={420}>
          <AppIconArtboard Variant={IconNode} name="Node" description="A graph junction. Works as a tech-y dock neighbor to Chrome/Safari." />
        </DCArtboard>
        <DCArtboard id="i4" label="I4 · Wordmark J" width={340} height={420}>
          <AppIconArtboard Variant={IconTypo} name="Wordmark J" description={`The letter J with the dot rebuilt as a small fork. Most "brand-able."`} />
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

// Center a fixed-size sheet inside its artboard
function CenterFrame({ children }) {
  return (
    <div style={{
      width: '100%', height: '100%', background: 'rgba(232,232,238,1)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20,
    }}>{children}</div>
  );
}

// A one-page summary of the picks + reasoning, sized to slot in next to the Brief.
function PicksSummary() {
  const picks = [
    {
      tag: 'Picker', pick: 'P5 · Smart suggestion',
      why: 'Promotes "Always" to a first-class button next to Open, and learns from history so the picker progressively recedes for hosts you route the same way every time. Adapts to your real browser count — with 2 browsers, the alternate is a full-width card not a sparse grid.',
      runner: 'P3 (Command list) — fold its inline profile chips into P5.',
    },
    {
      tag: 'Rules + Editor', pick: 'R5 · Grouped two-pane w/ visual matcher',
      why: 'Sidebar groups rules by destination browser so 50 rules stay scannable. Picking a rule swaps the right pane to an inline editor — no modal. The matcher is a visual host-chip list with “Include subdomains,” so casual users never write regex. “Edit as regex” disclosure preserves the power-user path.',
      runner: 'R3 (flat two-pane) if grouping feels heavy at low rule counts.',
    },
    {
      tag: 'Icon', pick: 'I2 · Branch',
      why: 'The metaphor matches what the app actually does — a URL splits into two destinations. The current Signpost reads "directions" not "routing."',
      runner: 'I1 (Signpost) — keep if brand recognition matters more than metaphor accuracy.',
    },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', boxSizing: 'border-box',
      padding: '22px 26px', background: 'white',
      fontFamily: JFONT, color: '#1a1a1a', overflow: 'auto',
      display: 'flex', flexDirection: 'column', gap: 14,
    }}>
      <div>
        <div style={{ fontSize: 11, fontWeight: 700, color: JBRAND.accent,
          textTransform: 'uppercase', letterSpacing: 0.7 }}>Picked for you</div>
        <div style={{ fontSize: 22, fontWeight: 600, letterSpacing: -0.3, marginTop: 2 }}>
          Three surfaces, picked to compose.
        </div>
        <div style={{ fontSize: 12.5, color: 'rgba(0,0,0,.6)', marginTop: 4, lineHeight: 1.5 }}>
          The editor isn’t its own destination anymore — it lives in the right pane of Rules, with a visual host-chip matcher instead of regex. The smart picker learns from those rules, and the Branch icon names the verb the rest of the product performs.
        </div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, flex: 1, minHeight: 0 }}>
        {picks.map(p => (
          <div key={p.tag} style={{
            padding: '12px 14px', borderRadius: 10,
            background: 'rgba(30,109,255,.04)', border: '0.5px solid rgba(30,109,255,.2)',
            display: 'flex', flexDirection: 'column', gap: 5,
          }}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 7 }}>
              <span style={{
                fontSize: 9.5, fontWeight: 700, color: JBRAND.accent,
                textTransform: 'uppercase', letterSpacing: 0.7,
                padding: '1px 6px', borderRadius: 3, background: 'rgba(30,109,255,.1)',
              }}>{p.tag}</span>
              <span style={{ fontSize: 13, fontWeight: 600 }}>{p.pick}</span>
            </div>
            <div style={{ fontSize: 11.5, color: 'rgba(0,0,0,.7)', lineHeight: 1.45 }}>{p.why}</div>
            <div style={{ fontSize: 10.5, color: 'rgba(0,0,0,.45)', marginTop: 'auto', paddingTop: 4 }}>
              <b style={{ color: 'rgba(0,0,0,.55)' }}>Runner-up:</b> {p.runner}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);

// junction-shared.jsx — primitives + browser icons + mock data
// Everything in this file is exported to window so subsequent .jsx scripts can read it.

// ─── Type & color tokens ─────────────────────────────────────────────────
const JFONT = '-apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro", "Helvetica Neue", sans-serif';
const JMONO = 'ui-monospace, "SF Mono", Menlo, Consolas, monospace';

// Junction brand slates — pulled from render_icon.swift (475569 → 1E293B)
const JBRAND = {
  slate100: '#f1f5f9',
  slate200: '#e2e8f0',
  slate300: '#cbd5e1',
  slate400: '#94a3b8',
  slate500: '#64748b',
  slate600: '#475569',
  slate700: '#334155',
  slate800: '#1e293b',
  slate900: '#0f172a',
  accent: '#1e6dff', // macOS system blue
  accentSoft: 'rgba(30,109,255,0.12)',
};

// ─── Junction signpost mark ──────────────────────────────────────────────
function JunctionMark({ size = 28, radius = 7 }) {
  // Mirrors the shipped icon (signpost.right.and.left on slate gradient)
  return (
    <div style={{
      width: size, height: size, borderRadius: radius,
      background: `linear-gradient(155deg, ${JBRAND.slate600}, ${JBRAND.slate800})`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: '0 1px 2px rgba(0,0,0,.18), inset 0 0.5px 0 rgba(255,255,255,.16)',
      flexShrink: 0,
    }}>
      <svg width={size * 0.72} height={size * 0.72} viewBox="0 0 24 24" fill="none">
        <g stroke="white" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
          <path d="M12 3v18" />
          <path d="M5 7h11l2.5 2L16 11H5z" />
          <path d="M19 13H8l-2.5 2L8 17h11z" />
        </g>
      </svg>
    </div>
  );
}

// ─── Browser icons ───────────────────────────────────────────────────────
// Stylized, recognizable browser glyphs. Drawn as SVG to avoid loading
// vendor binaries. Each takes `size` prop.
function BrowserIcon({ name, size = 64 }) {
  const S = size;
  const wrap = (children) => (
    <div style={{ width: S, height: S, position: 'relative', flexShrink: 0 }}>{children}</div>
  );
  switch (name) {
    case 'safari': return wrap(<SafariIcon size={S} />);
    case 'chrome': return wrap(<ChromeIcon size={S} />);
    case 'chrome-canary': return wrap(<ChromeIcon size={S} canary />);
    case 'firefox': return wrap(<FirefoxIcon size={S} />);
    case 'arc': return wrap(<ArcIcon size={S} />);
    case 'edge': return wrap(<EdgeIcon size={S} />);
    case 'brave': return wrap(<BraveIcon size={S} />);
    case 'vivaldi': return wrap(<VivaldiIcon size={S} />);
    case 'opera': return wrap(<OperaIcon size={S} />);
    case 'orion': return wrap(<OrionIcon size={S} />);
    case 'librewolf': return wrap(<LibreWolfIcon size={S} />);
    case 'zen': return wrap(<ZenIcon size={S} />);
    default: return wrap(<UnknownIcon size={S} label={name} />);
  }
}

function SafariIcon({ size }) {
  const r = size * 0.5 - 1;
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <defs>
        <radialGradient id="saf-bg" cx="0.35" cy="0.3" r="0.85">
          <stop offset="0" stopColor="#e7f3ff" />
          <stop offset="1" stopColor="#9ec8f0" />
        </radialGradient>
        <linearGradient id="saf-ring" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#d0d7e0" />
          <stop offset="1" stopColor="#7f8a99" />
        </linearGradient>
      </defs>
      <circle cx="32" cy="32" r={r} fill="url(#saf-ring)" />
      <circle cx="32" cy="32" r={r - 2.4} fill="url(#saf-bg)" />
      {/* tick marks */}
      {Array.from({ length: 24 }).map((_, i) => {
        const a = (i * 360) / 24;
        const isMajor = i % 6 === 0;
        return (
          <line key={i}
            x1={32 + Math.cos((a * Math.PI) / 180) * (r - 4)}
            y1={32 + Math.sin((a * Math.PI) / 180) * (r - 4)}
            x2={32 + Math.cos((a * Math.PI) / 180) * (r - (isMajor ? 7 : 6))}
            y2={32 + Math.sin((a * Math.PI) / 180) * (r - (isMajor ? 7 : 6))}
            stroke="#5a6573" strokeWidth={isMajor ? 1.2 : 0.7} />
        );
      })}
      {/* needle */}
      <g transform="translate(32,32) rotate(45)">
        <path d="M -2 -16 L 2 0 L -2 0 Z" fill="#e74c3c" />
        <path d="M 2 -16 L 2 0 L -2 0 Z" fill="#c0392b" />
        <path d="M -2 0 L 2 0 L 2 16 L -2 16 Z" fill="#ecf0f1" stroke="#bdc3c7" strokeWidth="0.5" />
      </g>
      <circle cx="32" cy="32" r="2.4" fill="#34495e" />
    </svg>
  );
}

function ChromeIcon({ size, canary }) {
  // 3-segment ring + center blue
  const C = canary
    ? ['#f7d358', '#f5a623', '#e08e1f']
    : ['#ea4335', '#fbbc05', '#34a853'];
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <defs>
        <radialGradient id={`cr-${canary ? 'c' : 'n'}-blue`} cx="0.5" cy="0.5" r="0.5">
          <stop offset="0" stopColor="#4285f4" />
          <stop offset="1" stopColor="#1f6cd0" />
        </radialGradient>
      </defs>
      <circle cx="32" cy="32" r="30" fill="#fff" />
      {/* three colored arcs */}
      <path d="M32 4 a28 28 0 0 1 24.25 14 L32 32 Z" fill={C[0]} />
      <path d="M56.25 18 a28 28 0 0 1 -3.5 32 L32 32 Z" fill={C[1]} />
      <path d="M52.75 50 a28 28 0 0 1 -45 0 L32 32 Z" fill={C[2]} />
      <path d="M7.75 50 a28 28 0 0 1 24.25 -46 L32 32 Z" fill={C[0]} opacity="0" />
      <circle cx="32" cy="32" r="10" fill="#fff" />
      <circle cx="32" cy="32" r="8" fill={`url(#cr-${canary ? 'c' : 'n'}-blue)`} />
    </svg>
  );
}

function FirefoxIcon({ size }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <defs>
        <radialGradient id="ff-bg" cx="0.5" cy="0.5" r="0.55">
          <stop offset="0" stopColor="#ffd84d" />
          <stop offset="0.55" stopColor="#ff8a1e" />
          <stop offset="1" stopColor="#e3411c" />
        </radialGradient>
        <radialGradient id="ff-inner" cx="0.6" cy="0.6" r="0.45">
          <stop offset="0" stopColor="#3a8fd6" />
          <stop offset="1" stopColor="#1e60a8" />
        </radialGradient>
      </defs>
      <circle cx="32" cy="32" r="30" fill="url(#ff-bg)" />
      <path d="M32 12 c-9 0-17 7-17 17 c0 11 9 19 19 19 c9 0 16-6 17-15 c-4 5-10 7-15 5 c-7-3-9-12-3-17 c4-4 11-3 14 2 c0-7-6-11-15-11z"
        fill="url(#ff-inner)" />
      <circle cx="42" cy="22" r="3" fill="#fff" opacity="0.5" />
    </svg>
  );
}

function ArcIcon({ size }) {
  // Arc's icon is colorful gradient blob with curves
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <defs>
        <linearGradient id="arc-g" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#f0a16f" />
          <stop offset="0.4" stopColor="#e0617e" />
          <stop offset="0.75" stopColor="#7752c2" />
          <stop offset="1" stopColor="#3858b9" />
        </linearGradient>
      </defs>
      <rect x="2" y="2" width="60" height="60" rx="14" fill="url(#arc-g)" />
      <path d="M16 44 c4 -14 16 -22 32 -22" stroke="white" strokeWidth="5" fill="none" strokeLinecap="round" opacity="0.92" />
      <circle cx="22" cy="26" r="3.5" fill="white" opacity="0.85" />
    </svg>
  );
}

function EdgeIcon({ size }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <defs>
        <linearGradient id="ed-g" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#3cd6e7" />
          <stop offset="0.5" stopColor="#1f9ed8" />
          <stop offset="1" stopColor="#0b5cab" />
        </linearGradient>
      </defs>
      <circle cx="32" cy="32" r="30" fill="url(#ed-g)" />
      <path d="M14 36 c0 -12 9 -22 22 -22 c11 0 16 7 14 13 c-3 -3 -8 -5 -13 -3 c-5 2 -8 7 -8 13 c0 5 4 9 9 9 c4 0 7 -1 10 -3 c-3 6 -10 10 -18 10 c-9 0 -16 -7 -16 -17z"
        fill="white" />
    </svg>
  );
}

function BraveIcon({ size }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <defs>
        <linearGradient id="br-g" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#fb7e3e" />
          <stop offset="1" stopColor="#e83e0c" />
        </linearGradient>
      </defs>
      {/* shield with mane */}
      <path d="M32 4 L18 8 L12 14 L18 18 L18 30 L24 42 L32 50 L40 42 L46 30 L46 18 L52 14 L46 8 Z"
        fill="url(#br-g)" stroke="#a82805" strokeWidth="1" />
      <path d="M32 18 L28 28 L32 32 L36 28 Z" fill="#a82805" opacity="0.4" />
    </svg>
  );
}

function VivaldiIcon({ size }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <circle cx="32" cy="32" r="30" fill="#ef3939" />
      <path d="M32 50 L18 26 L26 26 L32 38 L38 26 L46 26 Z" fill="white" />
    </svg>
  );
}

function OperaIcon({ size }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <defs>
        <linearGradient id="op-g" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#ff5252" />
          <stop offset="1" stopColor="#c70039" />
        </linearGradient>
      </defs>
      <circle cx="32" cy="32" r="30" fill="url(#op-g)" />
      <ellipse cx="32" cy="32" rx="11" ry="18" fill="white" />
    </svg>
  );
}

function OrionIcon({ size }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <defs>
        <linearGradient id="or-g" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#3b3b3b" />
          <stop offset="1" stopColor="#0a0a0a" />
        </linearGradient>
      </defs>
      <rect x="2" y="2" width="60" height="60" rx="14" fill="url(#or-g)" />
      <circle cx="32" cy="32" r="14" fill="none" stroke="#c8a96a" strokeWidth="3" />
      <circle cx="38" cy="26" r="3.5" fill="#c8a96a" />
    </svg>
  );
}

function LibreWolfIcon({ size }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <circle cx="32" cy="32" r="30" fill="#3a5b80" />
      <path d="M22 22 L32 14 L42 22 L42 32 C42 38 38 44 32 46 C26 44 22 38 22 32 Z" fill="#9eb6cd" />
      <circle cx="28" cy="28" r="2" fill="#1a2a40" />
      <circle cx="36" cy="28" r="2" fill="#1a2a40" />
    </svg>
  );
}

function ZenIcon({ size }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64">
      <defs>
        <linearGradient id="zen-g" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#f6b9e0" />
          <stop offset="1" stopColor="#c75aa0" />
        </linearGradient>
      </defs>
      <rect x="2" y="2" width="60" height="60" rx="14" fill="url(#zen-g)" />
      <path d="M18 22 L46 22 L20 42 L46 42" stroke="white" strokeWidth="4" fill="none" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function UnknownIcon({ size, label }) {
  const letter = (label || '?').trim()[0]?.toUpperCase() || '?';
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.22,
      background: '#bbb',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: '#fff', fontSize: size * 0.5, fontWeight: 600, fontFamily: JFONT,
    }}>{letter}</div>
  );
}

// ─── Favicon-style host glyph (for URL bars) ─────────────────────────────
function HostGlyph({ host, size = 16 }) {
  // Crude deterministic favicon based on host's first letter + a hash color
  const ch = (host || 'x').replace(/^www\./, '')[0]?.toUpperCase() || '?';
  let hash = 0;
  for (let i = 0; i < (host || '').length; i++) hash = (hash * 31 + host.charCodeAt(i)) | 0;
  const hue = Math.abs(hash) % 360;
  return (
    <div style={{
      width: size, height: size, borderRadius: 3,
      background: `hsl(${hue} 55% 45%)`,
      color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: size * 0.65, fontWeight: 700, fontFamily: JFONT, lineHeight: 1,
      flexShrink: 0,
    }}>{ch}</div>
  );
}

// ─── Keyboard cap glyph ─────────────────────────────────────────────────
function KeyCap({ children, style = {}, tone = 'default' }) {
  const tones = {
    default: { bg: 'rgba(0,0,0,0.06)', fg: '#4a4a4a', border: 'rgba(0,0,0,0.08)' },
    accent:  { bg: 'rgba(30,109,255,0.12)', fg: JBRAND.accent, border: 'rgba(30,109,255,0.25)' },
    strong:  { bg: 'rgba(0,0,0,0.85)', fg: 'white', border: 'rgba(0,0,0,0.85)' },
  };
  const t = tones[tone] || tones.default;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      minWidth: 16, height: 18, padding: '0 5px',
      borderRadius: 4, background: t.bg, color: t.fg,
      border: `0.5px solid ${t.border}`,
      fontFamily: JFONT, fontSize: 11, fontWeight: 600, letterSpacing: 0,
      ...style,
    }}>{children}</span>
  );
}

// ─── A tiny SF-symbol-flavored icon set (line glyphs) ───────────────────
function SFIcon({ name, size = 14, color = 'currentColor', weight = 1.6 }) {
  const p = {
    fill: 'none', stroke: color, strokeWidth: weight,
    strokeLinecap: 'round', strokeLinejoin: 'round',
  };
  const S = size;
  const paths = {
    link: <><path d="M9 5 a3 3 0 0 0 0 4 l1.5 1.5" {...p} /><path d="M15 19 a3 3 0 0 0 0 -4 l-1.5 -1.5" {...p} /><path d="M8 16 l8 -8" {...p} /></>,
    pin: <><path d="M12 2 l3 5 v4 l3 3 H6 l3 -3 V7 z" {...p} /><path d="M12 14 v8" {...p} /></>,
    plus: <><path d="M12 5 v14 M5 12 h14" {...p} /></>,
    minus: <path d="M5 12 h14" {...p} />,
    pencil: <><path d="M4 20 l4 -1 l11 -11 l-3 -3 l-11 11 z" {...p} /></>,
    chevronDown: <path d="M6 9 l6 6 l6 -6" {...p} />,
    chevronRight: <path d="M9 6 l6 6 l-6 6" {...p} />,
    chevronUp: <path d="M6 15 l6 -6 l6 6" {...p} />,
    arrowRight: <><path d="M5 12 h14 M13 6 l6 6 l-6 6" {...p} /></>,
    check: <path d="M5 12 l4 4 l10 -10" {...p} />,
    x: <path d="M6 6 l12 12 M18 6 l-12 12" {...p} />,
    search: <><circle cx="11" cy="11" r="6" {...p} /><path d="M16 16 l4 4" {...p} /></>,
    sliders: <><path d="M3 6 h13 M19 6 h2 M8 6 a2 2 0 1 0 0 .01" {...p} /><path d="M3 12 h7 M13 12 h8 M11 12 a2 2 0 1 0 0 .01" {...p} /><path d="M3 18 h11 M17 18 h4 M15 18 a2 2 0 1 0 0 .01" {...p} /></>,
    bolt: <path d="M13 3 L4 14 h6 L9 21 l9 -11 h-6 z" {...p} />,
    gear: <><circle cx="12" cy="12" r="3" {...p} /><path d="M19 12 a7 7 0 0 0 -0.1 -1.2 l2 -1.4 l-2 -3.4 l-2.3 0.8 a7 7 0 0 0 -2 -1.2 l-0.4 -2.4 h-4 l-0.4 2.4 a7 7 0 0 0 -2 1.2 l-2.3 -0.8 l-2 3.4 l2 1.4 a7 7 0 0 0 0 2.4 l-2 1.4 l2 3.4 l2.3 -0.8 a7 7 0 0 0 2 1.2 l0.4 2.4 h4 l0.4 -2.4 a7 7 0 0 0 2 -1.2 l2.3 0.8 l2 -3.4 l-2 -1.4 a7 7 0 0 0 0.1 -1.2 z" {...p} /></>,
    listBullet: <><path d="M9 6 h12 M9 12 h12 M9 18 h12" {...p} /><circle cx="4.5" cy="6" r="0.8" fill={color} /><circle cx="4.5" cy="12" r="0.8" fill={color} /><circle cx="4.5" cy="18" r="0.8" fill={color} /></>,
    info: <><circle cx="12" cy="12" r="9" {...p} /><path d="M12 11 v6 M12 8 v0.5" {...p} /></>,
    wand: <><path d="M5 19 L15 9 l-2 -2 L3 17 z" {...p} /><path d="M16 4 l1 2 l2 1 l-2 1 l-1 2 l-1 -2 l-2 -1 l2 -1 z" {...p} /></>,
    star: <path d="M12 3 l2.6 5.5 l6 0.7 l-4.4 4.2 l1.2 6 L12 16.7 L6.6 19.4 l1.2 -6 l-4.4 -4.2 l6 -0.7 z" {...p} />,
    signpost: <><path d="M12 3 v18" {...p} /><path d="M5 7 h10 l2 2 l-2 2 H5 z" {...p} /><path d="M19 13 H9 l-2 2 l2 2 h10 z" {...p} /></>,
    'pin.fill': <path d="M12 2 l3 5 v4 l3 3 H6 l3 -3 V7 z M12 14 v8" fill={color} stroke="none" />,
    'star.fill': <path d="M12 3 l2.6 5.5 l6 0.7 l-4.4 4.2 l1.2 6 L12 16.7 L6.6 19.4 l1.2 -6 l-4.4 -4.2 l6 -0.7 z" fill={color} stroke="none" />,
    handDraggable: <><circle cx="9" cy="6" r="1.2" fill={color} /><circle cx="15" cy="6" r="1.2" fill={color} /><circle cx="9" cy="12" r="1.2" fill={color} /><circle cx="15" cy="12" r="1.2" fill={color} /><circle cx="9" cy="18" r="1.2" fill={color} /><circle cx="15" cy="18" r="1.2" fill={color} /></>,
    folderBadge: <><path d="M3 7 a2 2 0 0 1 2 -2 h4 l2 2 h8 a2 2 0 0 1 2 2 v9 a2 2 0 0 1 -2 2 H5 a2 2 0 0 1 -2 -2 z" {...p} /></>,
    branch: <><circle cx="6" cy="6" r="2" {...p} /><circle cx="18" cy="6" r="2" {...p} /><circle cx="12" cy="18" r="2" {...p} /><path d="M6 8 v3 a3 3 0 0 0 3 3 h6 a3 3 0 0 0 3 -3 V8" {...p} /><path d="M12 14 v2" {...p} /></>,
    eye: <><path d="M2 12 s4 -7 10 -7 s10 7 10 7 s-4 7 -10 7 s-10 -7 -10 -7 z" {...p} /><circle cx="12" cy="12" r="3" {...p} /></>,
    'eye.slash': <><path d="M3 3 l18 18" {...p} /><path d="M9.5 5.3 a10 10 0 0 1 2.5 -0.3 c6 0 10 7 10 7 a16 16 0 0 1 -2.3 3" {...p} /><path d="M6 7.5 A14 14 0 0 0 2 12 s4 7 10 7 a10 10 0 0 0 4 -0.8" {...p} /></>,
    'doc.text': <><path d="M6 3 h8 l4 4 v14 a1 1 0 0 1 -1 1 H6 a1 1 0 0 1 -1 -1 V4 a1 1 0 0 1 1 -1 z" {...p} /><path d="M14 3 v4 h4 M8 12 h8 M8 16 h6" {...p} /></>,
    clock: <><circle cx="12" cy="12" r="9" {...p} /><path d="M12 7 v5 l3 2" {...p} /></>,
    cmd: <><path d="M8 8 h8 v8 h-8 z" {...p} /><circle cx="6" cy="6" r="2" {...p} /><circle cx="18" cy="6" r="2" {...p} /><circle cx="6" cy="18" r="2" {...p} /><circle cx="18" cy="18" r="2" {...p} /></>,
    bell: <><path d="M6 16 V11 a6 6 0 0 1 12 0 v5 l2 2 H4 z" {...p} /><path d="M10 20 a2 2 0 0 0 4 0" {...p} /></>,
    arrowDownRight: <path d="M5 5 l14 14 M19 11 v8 h-8" {...p} />,
    lightning: <path d="M13 3 L4 14 h6 L9 21 l9 -11 h-6 z" fill={color} stroke={color} strokeWidth="0.5" strokeLinejoin="round" />,
    sparkle: <path d="M12 3 l1.4 4.6 L18 9 l-4.6 1.4 L12 15 l-1.4 -4.6 L6 9 l4.6 -1.4 z" {...p} />,
  };
  return (
    <svg width={S} height={S} viewBox="0 0 24 24">{paths[name] || null}</svg>
  );
}

// ─── macOS-style controls (subset) ──────────────────────────────────────
function MacToggle({ on, accent = JBRAND.accent, size = 1 }) {
  const W = 36 * size, H = 21 * size, R = H / 2;
  return (
    <div style={{
      width: W, height: H, borderRadius: R,
      background: on ? accent : 'rgba(120,120,128,0.32)',
      position: 'relative', transition: 'background .15s',
      boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,.04)',
      flexShrink: 0,
    }}>
      <div style={{
        position: 'absolute', top: 1, left: on ? W - H + 1 : 1,
        width: H - 2, height: H - 2, borderRadius: '50%',
        background: 'white',
        boxShadow: '0 2px 4px rgba(0,0,0,.15), 0 0 0 0.5px rgba(0,0,0,.04)',
        transition: 'left .15s',
      }} />
    </div>
  );
}

function MacRadio({ on, accent = JBRAND.accent }) {
  return (
    <div style={{
      width: 16, height: 16, borderRadius: '50%',
      background: on ? accent : 'white',
      border: on ? `1px solid ${accent}` : '1px solid rgba(0,0,0,.18)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: on ? 'none' : 'inset 0 1px 1px rgba(0,0,0,.04)',
    }}>
      {on && <div style={{ width: 5, height: 5, borderRadius: '50%', background: 'white' }} />}
    </div>
  );
}

function MacCheck({ on, accent = JBRAND.accent }) {
  return (
    <div style={{
      width: 14, height: 14, borderRadius: 3,
      background: on ? accent : 'white',
      border: on ? `1px solid ${accent}` : '1px solid rgba(0,0,0,.2)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      {on && <SFIcon name="check" size={10} color="white" weight={2.4} />}
    </div>
  );
}

function MacButton({ children, kind = 'default', size = 'sm', style = {}, icon }) {
  // kind: default | primary | borderless | destructive
  const bySize = { xs: [6, 2, 11], sm: [10, 4, 12], md: [14, 6, 13] };
  const [px, py, fs] = bySize[size];
  const base = {
    display: 'inline-flex', alignItems: 'center', gap: 5,
    padding: `${py}px ${px}px`,
    borderRadius: 6,
    fontFamily: JFONT, fontSize: fs, fontWeight: 500,
    lineHeight: 1.2,
  };
  const looks = {
    default: { background: 'white', color: 'rgba(0,0,0,.85)', border: '0.5px solid rgba(0,0,0,.15)', boxShadow: '0 1px 0 rgba(0,0,0,.04)' },
    primary: { background: JBRAND.accent, color: 'white', border: 'none', boxShadow: '0 1px 0 rgba(0,0,0,.1)' },
    borderless: { background: 'transparent', color: 'rgba(0,0,0,.7)', border: 'none' },
    destructive: { background: 'white', color: '#d23a2c', border: '0.5px solid rgba(210,58,44,.3)' },
  };
  return (
    <span style={{ ...base, ...looks[kind], ...style }}>
      {icon}
      {children}
    </span>
  );
}

// ─── Macos Settings sidebar item ─────────────────────────────────────────
function SettingsSidebarRow({ icon, label, selected, color = JBRAND.accent }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8,
      padding: '5px 10px', borderRadius: 6, margin: '0 8px',
      background: selected ? 'rgba(0,0,0,.07)' : 'transparent',
      fontFamily: JFONT, fontSize: 13, color: 'rgba(0,0,0,.85)',
      fontWeight: selected ? 500 : 400,
    }}>
      <div style={{
        width: 20, height: 20, borderRadius: 5,
        background: color, color: 'white',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 0.5px 0 rgba(0,0,0,.15) inset',
      }}>{icon}</div>
      <span>{label}</span>
    </div>
  );
}

// ─── Mock data ───────────────────────────────────────────────────────────
const MOCK_BROWSERS = [
  { id: 'com.apple.Safari', name: 'Safari', icon: 'safari' },
  { id: 'com.google.Chrome', name: 'Chrome', icon: 'chrome' },
  { id: 'company.thebrowser.Browser', name: 'Arc', icon: 'arc' },
  { id: 'org.mozilla.firefox', name: 'Firefox', icon: 'firefox' },
  { id: 'com.brave.Browser', name: 'Brave', icon: 'brave' },
  { id: 'com.microsoft.edgemac', name: 'Edge', icon: 'edge' },
  { id: 'com.vivaldi.Vivaldi', name: 'Vivaldi', icon: 'vivaldi' },
  { id: 'com.operasoftware.Opera', name: 'Opera', icon: 'opera' },
];

const MOCK_RULES = [
  { id: 'r1', name: 'GitHub → work Chrome', enabled: true,
    match: { kind: 'host', value: 'github.com' },
    target: { browser: 'chrome', browserName: 'Chrome', profile: 'Work' } },
  { id: 'r2', name: 'Google Workspace', enabled: true,
    match: { kind: 'hostRegex', value: '^(mail|calendar|docs|drive|meet)\\.google\\.com$' },
    target: { browser: 'chrome', browserName: 'Chrome', profile: 'Work' } },
  { id: 'r3', name: 'Hacker News → Safari', enabled: true,
    match: { kind: 'urlContains', value: 'news.ycombinator.com' },
    target: { browser: 'safari', browserName: 'Safari' } },
  { id: 'r4', name: 'Figma files', enabled: true,
    match: { kind: 'host', value: 'figma.com' },
    target: { browser: 'arc', browserName: 'Arc', profile: 'Design' } },
  { id: 'r5', name: 'Internal apps', enabled: true,
    match: { kind: 'hostRegex', value: '\\.acmecorp\\.internal$' },
    target: { browser: 'chrome', browserName: 'Chrome', profile: 'Work' } },
  { id: 'r6', name: 'Banking → Firefox (containers)', enabled: true,
    match: { kind: 'hostRegex', value: '(chase|wellsfargo|amex)\\.com$' },
    target: { browser: 'firefox', browserName: 'Firefox', profile: 'Banking' } },
  { id: 'r7', name: 'Notion → personal', enabled: false,
    match: { kind: 'host', value: 'notion.so' },
    target: { browser: 'chrome', browserName: 'Chrome', profile: 'Personal' } },
  { id: 'r8', name: 'Localhost dev', enabled: true,
    match: { kind: 'hostRegex', value: '^(localhost|127\\.0\\.0\\.1|0\\.0\\.0\\.0)$' },
    target: { browser: 'chrome', browserName: 'Chrome', profile: 'Dev' } },
  { id: 'r9', name: 'YouTube → personal', enabled: true,
    match: { kind: 'host', value: 'youtube.com' },
    target: { browser: 'firefox', browserName: 'Firefox' } },
  { id: 'r10', name: 'Old archive links', enabled: false,
    match: { kind: 'urlContains', value: 'web.archive.org' },
    target: { browser: 'safari', browserName: 'Safari' } },
];

const MOCK_LOG = [
  { url: 'https://github.com/pkajaba/junction/pull/142', time: '14:32:08', via: { kind: 'rule', name: 'GitHub → work Chrome' }, target: 'Chrome · Work' },
  { url: 'https://docs.google.com/document/d/1aBCd…/edit', rewritten: 'https://docs.google.com/document/d/1aBCd/edit', time: '14:31:51', via: { kind: 'rule', name: 'Google Workspace' }, target: 'Chrome · Work' },
  { url: 'https://news.ycombinator.com/item?id=39842110', time: '14:28:14', via: { kind: 'rule', name: 'Hacker News → Safari' }, target: 'Safari' },
  { url: 'https://www.figma.com/design/abc/Junction-Redesign?node-id=1-2', time: '14:24:02', via: { kind: 'rule', name: 'Figma files' }, target: 'Arc · Design' },
  { url: 'https://anthropic.com/research/agentic-misalignment', rewritten: 'https://anthropic.com/research/agentic-misalignment', time: '14:18:39', via: { kind: 'picker' }, target: 'Safari' },
  { url: 'mailto:hello@example.com', time: '14:11:02', via: null, target: null, status: 'unsupported' },
  { url: 'https://stripe.com/pricing?utm_source=newsletter&utm_campaign=q2', rewritten: 'https://stripe.com/pricing', time: '13:58:21', via: { kind: 'picker' }, target: 'Chrome · Personal' },
];

Object.assign(window, {
  JFONT, JMONO, JBRAND,
  JunctionMark, BrowserIcon, HostGlyph, KeyCap, SFIcon,
  MacToggle, MacRadio, MacCheck, MacButton, SettingsSidebarRow,
  MOCK_BROWSERS, MOCK_RULES, MOCK_LOG,
});

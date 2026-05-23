"use client";

import { useMemo } from "react";

// ─── time utils ────────────────────────────────────────────────
export function hhmm(str) {
  if (!str) return 0;
  const [h, m] = str.split(":").map(Number);
  return h * 60 + m;
}

export function toHHMM(mins) {
  const m = ((mins % 1440) + 1440) % 1440;
  return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
}

export function fmtTime(str) {
  if (!str) return "";
  const [h, m] = str.split(":").map(Number);
  return `${h % 12 || 12}:${String(m).padStart(2, "0")} ${h >= 12 ? "PM" : "AM"}`;
}

export function calcLog(log) {
  let inBed = hhmm(log.inBed);
  let outBed = hhmm(log.outBed);
  if (outBed <= inBed) outBed += 1440;
  const tib = outBed - inBed;
  const tst = Math.max(0, tib - (log.latency || 0) - (log.wakeMin || 0));
  const se = tib > 0 ? Math.round((tst / tib) * 100) : 0;
  return { tib, tst, se };
}

export function seColor(se) {
  if (se >= 85) return "var(--good-400)";
  if (se >= 75) return "var(--warn-400)";
  return "var(--crit-400)";
}

// ─── icons (stroke-based, minimal) ─────────────────────────────
export const Icon = {
  moon: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M21 12.5A9 9 0 0 1 11.5 3a7 7 0 1 0 9.5 9.5Z"/></svg>,
  sun: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><circle cx="12" cy="12" r="4"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6 7 7M17 17l1.4 1.4M5.6 18.4 7 17M17 7l1.4-1.4"/></svg>,
  chart: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M4 19V5M4 19h16M8 15l3-4 3 2 4-7"/></svg>,
  tools: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><circle cx="12" cy="12" r="2.5"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.9 2.9l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 0 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1A2 2 0 1 1 4.1 17l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1A2 2 0 1 1 7 4.1l.1.1a1.7 1.7 0 0 0 1.8.3H9A1.7 1.7 0 0 0 10 3v-.1a2 2 0 1 1 4 0V3a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1A2 2 0 1 1 19.9 7l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 0 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z"/></svg>,
  book: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20V3H6.5A2.5 2.5 0 0 0 4 5.5v14ZM4 19.5A2.5 2.5 0 0 0 6.5 22H20v-5"/></svg>,
  brain: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M9 4.5a3 3 0 0 0-3 3v.5a3 3 0 0 0-2 2.8c0 1.1.6 2 1.5 2.5A3 3 0 0 0 7 18.5 3 3 0 0 0 12 20a3 3 0 0 0 5-1.5 3 3 0 0 0 1.5-5.2 3 3 0 0 0 1.5-2.5 3 3 0 0 0-2-2.8V7.5a3 3 0 0 0-3-3 3 3 0 0 0-3 1.5 3 3 0 0 0-3-1.5Z"/><path d="M12 6v14"/></svg>,
  wind: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M3 8h12a3 3 0 1 0-3-3M3 12h17a3 3 0 1 1-3 3M3 16h10a2 2 0 1 1-2 2"/></svg>,
  leaf: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M11 20A7 7 0 0 1 4 13c0-3 1-9 9-9 0 8-2 16-9 16Z"/><path d="M4 21c2-5 7-9 11-12"/></svg>,
  note: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8l-5-5Z"/><path d="M14 3v5h5M9 13h6M9 17h4"/></svg>,
  check: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M4 12l5 5 11-11"/></svg>,
  arrow: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M5 12h14M13 6l6 6-6 6"/></svg>,
  chevron: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M9 6l6 6-6 6"/></svg>,
  flame: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M12 22c4 0 7-3 7-7 0-3-2-5-3-7-1 2-2 3-3 3-2 0-2-3-1-6-3 2-7 6-7 10 0 4 3 7 7 7Z"/></svg>,
  spark: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><path d="M12 3v4M12 17v4M3 12h4M17 12h4M5.6 5.6 8 8M16 16l2.4 2.4M5.6 18.4 8 16M16 8l2.4-2.4"/></svg>,
  watch: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><circle cx="12" cy="12" r="6"/><path d="M8 4h8M8 20h8M12 9v3l2 1"/></svg>,
  settings: (p) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...p}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.9 2.9l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 0 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1A2 2 0 1 1 4.1 17l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1A2 2 0 1 1 7 4.1l.1.1a1.7 1.7 0 0 0 1.8.3H9A1.7 1.7 0 0 0 10 3v-.1a2 2 0 1 1 4 0V3a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1A2 2 0 1 1 19.9 7l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 0 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z"/></svg>,
};

// ─── shared primitives ─────────────────────────────────────────
export function Ring({ value, max = 100, size = 120, stroke = 10, color = "var(--accent)", trackColor = "rgba(255,255,255,0.06)", children }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const dash = c * Math.min(1, value / max);
  return (
    <div style={{ position: "relative", width: size, height: size, flexShrink: 0 }}>
      <svg width={size} height={size} style={{ transform: "rotate(-90deg)" }}>
        <circle cx={size/2} cy={size/2} r={r} stroke={trackColor} strokeWidth={stroke} fill="none" />
        <circle cx={size/2} cy={size/2} r={r}
          stroke={color} strokeWidth={stroke} fill="none"
          strokeLinecap="round"
          strokeDasharray={`${dash} ${c}`}
          style={{ transition: "stroke-dasharray 600ms cubic-bezier(.4,.2,.2,1)" }}
        />
      </svg>
      <div style={{
        position: "absolute", inset: 0, display: "flex",
        flexDirection: "column", alignItems: "center", justifyContent: "center",
        color: "var(--fg-1)",
      }}>
        {children}
      </div>
    </div>
  );
}

export function StarField({ count = 50, opacity = 0.7 }) {
  const stars = useMemo(() => {
    function rng(i) { return Math.abs(Math.sin(42 * 9301 + i * 49297) * 233280) % 1; }
    return Array.from({ length: count }, (_, i) => ({
      x: rng(i) * 100,
      y: rng(i + 999) * 100,
      size: 0.6 + rng(i + 333) * 1.6,
      delay: rng(i + 77) * 6,
      duration: 3 + rng(i + 222) * 6,
    }));
  }, [count]);
  return (
    <div style={{ position: "absolute", inset: 0, pointerEvents: "none", opacity, overflow: "hidden" }}>
      {stars.map((s, i) => (
        <div key={i} style={{
          position: "absolute", left: `${s.x}%`, top: `${s.y}%`,
          width: s.size, height: s.size, borderRadius: "50%",
          background: i % 7 === 0 ? "var(--warm-300)" : "var(--night-100)",
          animation: `star-twinkle ${s.duration}s ease-in-out ${s.delay}s infinite`,
        }} />
      ))}
    </div>
  );
}

export function PageShell({ children, withStars = false }) {
  return (
    <div style={{
      position: "relative",
      minHeight: "100dvh",
      background: withStars
        ? "radial-gradient(120% 60% at 50% -10%, rgba(121,171,224,0.18) 0%, transparent 60%), var(--bg-app)"
        : "var(--bg-app)",
      color: "var(--fg-1)",
      overflow: "hidden",
    }}>
      {withStars && <StarField count={50} opacity={0.7} />}
      <div className="no-scrollbar" style={{
        position: "relative", zIndex: 1,
        padding: "44px 18px 110px",
      }}>
        {children}
      </div>
    </div>
  );
}

// ─── sparkline / bar chart ─────────────────────────────────────
export function SparkArea({ data, width = 320, height = 130, accent = "var(--accent)", type = "bar" }) {
  if (!data || data.length === 0) return null;
  const max = 100, min = 0;
  const pad = { l: 8, r: 8, t: 6, b: 6 };
  const w = width - pad.l - pad.r;
  const h = height - pad.t - pad.b;
  const stepX = w / Math.max(1, data.length - 1);
  const points = data.map((v, i) => ({
    x: pad.l + i * stepX,
    y: pad.t + h - ((v - min) / (max - min)) * h,
    v,
  }));
  const linePath = points.map((p, i) => `${i === 0 ? "M" : "L"}${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(" ");
  const areaPath = `${linePath} L${points[points.length-1].x},${pad.t + h} L${pad.l},${pad.t + h} Z`;
  const barW = Math.max(6, stepX * 0.55);

  return (
    <svg width={width} height={height} style={{ overflow: "visible", width: "100%" }} viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="none">
      {[25, 50, 75].map(y => (
        <line key={y}
          x1={pad.l} x2={pad.l + w}
          y1={pad.t + h - (y/100) * h} y2={pad.t + h - (y/100) * h}
          stroke="rgba(255,255,255,0.04)" strokeWidth="1" strokeDasharray="2 3"
        />
      ))}
      <line x1={pad.l} x2={pad.l + w}
        y1={pad.t + h - 0.85 * h} y2={pad.t + h - 0.85 * h}
        stroke="rgba(122,183,139,0.5)" strokeDasharray="4 3" strokeWidth="1" />
      {type === "area" && (
        <>
          <defs>
            <linearGradient id="sparkGrad" x1="0" x2="0" y1="0" y2="1">
              <stop offset="0%" stopColor={accent} stopOpacity="0.35"/>
              <stop offset="100%" stopColor={accent} stopOpacity="0"/>
            </linearGradient>
          </defs>
          <path d={areaPath} fill="url(#sparkGrad)" />
          <path d={linePath} fill="none" stroke={accent} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          {points.map((p, i) => (
            <circle key={i} cx={p.x} cy={p.y} r="2.5" fill="var(--bg-app)" stroke={accent} strokeWidth="1.5"/>
          ))}
        </>
      )}
      {type === "bar" && points.map((p, i) => {
        const col = p.v >= 85 ? "var(--good-400)" : p.v >= 75 ? "var(--warn-400)" : "var(--crit-400)";
        return (
          <rect key={i}
            x={p.x - barW/2}
            y={p.y}
            width={barW}
            height={Math.max(2, pad.t + h - p.y)}
            rx={Math.min(barW/3, 4)}
            fill={col} opacity="0.85"
          />
        );
      })}
    </svg>
  );
}

// ─── form inputs ───────────────────────────────────────────────
export function Stepper({ value, onChange, unit = "", step = 5, min = 0 }) {
  return (
    <div style={{
      display: "inline-flex", alignItems: "center", gap: 6,
      background: "var(--bg-elev-2)", border: "1px solid var(--border)",
      borderRadius: 999, padding: 2,
    }}>
      <button onClick={() => onChange(Math.max(min, value - step))} className="reset press"
        style={{ width: 28, height: 28, borderRadius: 999, color: "var(--fg-2)", fontSize: 16, fontWeight: 500 }}>−</button>
      <div style={{ minWidth: 56, textAlign: "center", fontSize: 14, fontVariantNumeric: "tabular-nums", color: "var(--fg-1)" }}>
        {value} <span style={{ color: "var(--fg-4)", fontSize: 11 }}>{unit}</span>
      </div>
      <button onClick={() => onChange(value + step)} className="reset press"
        style={{ width: 28, height: 28, borderRadius: 999, color: "var(--fg-2)", fontSize: 16, fontWeight: 500 }}>+</button>
    </div>
  );
}

export function ScaleRow({ value, onChange }) {
  return (
    <div style={{ display: "flex", gap: 4 }}>
      {[1,2,3,4,5,6,7,8,9,10].map(n => (
        <button key={n} onClick={() => onChange(n)} className="reset press"
          aria-label={`${n}`}
          style={{
            width: 14, height: 28, borderRadius: 4,
            background: n <= value ? "var(--accent)" : "var(--bg-elev-2)",
            border: "none",
          }}/>
      ))}
    </div>
  );
}

export function LogRow({ label, sublabel, children }) {
  return (
    <div style={{
      padding: "12px 14px",
      background: "var(--bg-surface)",
      border: "1px solid var(--border-soft)",
      borderRadius: 14,
      marginBottom: 8,
      display: "flex", alignItems: "center", gap: 12,
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, color: "var(--fg-1)", fontWeight: 500 }}>{label}</div>
        {sublabel && <div className="meta" style={{ marginTop: 2 }}>{sublabel}</div>}
      </div>
      <div style={{ flexShrink: 0 }}>{children}</div>
    </div>
  );
}

export const WEEKS = [
  {
    title: "Sleep restriction + stimulus control",
    theme: "Build sleep pressure",
    bedOffset: -360, // 6 hours before wake
    rules: [
      "Get into bed at your scheduled time only — not before, even if exhausted.",
      "Get out of bed at your anchor time every single day, including weekends. Non-negotiable.",
      "If you're awake in bed more than 20 minutes, get up and go to another room until sleepy.",
      "Bed is for sleep only — no phone, no TV, no reading, no lying awake worrying.",
      "No naps. Daytime sleepiness is building the sleep pressure you need.",
      "Fill in your morning log within 30 minutes of waking — estimates are fine.",
    ],
    expect: "This week is the hardest. You'll feel sleep-deprived — that's intentional. The goal is consolidating your fragmented sleep into a solid block before expanding the window.",
    cognitive: null,
  },
  {
    title: "Add relaxation for racing thoughts",
    theme: "Calm the nervous system",
    bedOffset: -360,
    rules: [
      "Continue all Week 1 rules — they remain in effect for the whole program.",
      "Start a 10-minute wind-down routine 15m before bed (dim lights, no screens, quiet).",
      "Practice 4-7-8 breathing before lights out (Tools tab).",
      "During night wakings, use the body scan instead of checking the clock (Tools tab).",
      "If SE ≥85% for 5 consecutive nights, move bedtime 15 minutes earlier.",
    ],
    expect: "Sleep should start consolidating. Night wakings may feel shorter even before they fully resolve. The breathing and body scan work on the nervous system activation that drives racing thoughts.",
    cognitive: "Start noticing your thoughts at night — don't fight them yet, just observe. Write them down in the morning. We'll work with them next week.",
  },
  {
    title: "Cognitive restructuring",
    theme: "Challenge the beliefs",
    bedOffset: -390, // 6.5 hours
    rules: [
      "Continue all core sleep restriction and stimulus control rules.",
      "Each morning, identify one thought you had during the night and write it down.",
      "Look at the Sleep beliefs tool and find which one matches your thought.",
      "Practice the worry postponement technique before bed (Tools tab).",
      "Check your SE and adjust bedtime if warranted.",
    ],
    expect: "Racing thoughts often reduce significantly once you stop arguing with them and start examining the beliefs underneath. This is where the real cognitive shift begins.",
    cognitive: "Key belief to examine this week: 'I need 8 hours to function.' Most adults function adequately on 6–7 hours. The anxiety about the number causes more impairment than the lost sleep itself.",
  },
  {
    title: "Defusion from anxious thoughts",
    theme: "Stop fighting the thoughts",
    bedOffset: -420, // 7 hours
    rules: [
      "Continue all core rules.",
      "Practice thought defusion — see the Defusion tool. Thoughts are events, not facts.",
      "Use the 'leaves on a stream' visualization during any night waking.",
      "Stop checking the clock at night. Cover it if needed. Stop the sleep-time math.",
      "Notice and reduce other safety behaviors (calculating hours left, reassurance-seeking).",
    ],
    expect: "By now most people are seeing SE above 80% and the window has likely expanded to 6.5–7 hours. The quality shift — deeper, more restorative sleep — often becomes noticeable this week.",
    cognitive: "Safety behaviors — clock-checking, calculating 'how much sleep I'll get' — are the engine of sleep anxiety. Each check is a small experiment that confirms sleep is dangerous. Stop the experiment.",
  },
  {
    title: "Consolidation + window expansion",
    theme: "Earn back your sleep time",
    bedOffset: -450, // 7.5 hours
    rules: [
      "For every 5-night stretch with SE ≥85%, move bedtime 15–30 minutes earlier.",
      "Keep wake time fixed — only ever adjust bedtime.",
      "Maintain stimulus control even as things improve — the association is still being built.",
      "Begin thinking about your maintenance habits for after the program ends.",
    ],
    expect: "Sleep should feel qualitatively different — deeper and more restorative even if the total hours are similar to before. Most people are at 6.5–7 hours of solid sleep by week 5.",
    cognitive: null,
  },
  {
    title: "Maintenance planning",
    theme: "Make this permanent",
    bedOffset: -480, // 8 hours (or settled)
    rules: [
      "Identify your personal warning signs: two bad nights in a row, anxiety creeping in, compensating with early bedtime.",
      "Have a re-engagement plan: if SE drops below 80% for a week, do a 1-week sleep restriction reset.",
      "Keep a weekly (not daily) sleep log as ongoing monitoring.",
      "The stimulus control association — bed = sleep only — must be maintained long-term.",
      "Sleep is now a skill you've built. It responds to the same principles forever.",
    ],
    expect: "You now have the full toolkit. The program ends but the approach is permanent. One bad stretch doesn't erase the gains — just re-apply the tools.",
    cognitive: "Relapse is not failure — it's information. Something changed (stress, illness, travel, schedule shift). Identify it, re-apply sleep restriction for a week, and the gains come back.",
  },
];

export const TOOLS = {
  breathing: {
    title: "4-7-8 breathing",
    when: "Before lights out · During night wakings",
    desc: "Activates the parasympathetic nervous system within 2–3 cycles. Works by extending the exhale, which directly triggers the vagal brake on arousal.",
    icon: "wind", color: "var(--sky-400)", time: "2 min",
    steps: [
      "Exhale completely and slowly through your mouth.",
      "Close your mouth and inhale through your nose for 4 counts.",
      "Hold your breath for 7 counts.",
      "Exhale through your mouth slowly for 8 counts.",
      "Repeat 4 full cycles. Don't force it — let it be gentle.",
    ],
  },
  bodyscan: {
    title: "Body scan (5 min)",
    when: "During night wakings · When mind is racing",
    desc: "Shifts attention from anxious thought-loops into physical sensation. Doesn't require relaxation — just observation. More effective than trying to 'think yourself calm.'",
    icon: "spark", color: "var(--warm-400)", time: "5 min",
    steps: [
      "Lie still, eyes closed, arms at sides.",
      "Bring attention to the top of your head. Just notice — any warmth, pressure, tingling, or nothing.",
      "Slowly move attention down: forehead → jaw → neck → shoulders → chest.",
      "Continue: arms → hands → stomach → lower back → hips → thighs → calves → feet.",
      "No judgment, no trying to relax. Just observe each area for a few seconds.",
      "When the mind wanders (it will), gently return to wherever you were in the body.",
    ],
  },
  worrypost: {
    title: "Worry postponement",
    when: "Wind-down routine",
    desc: "Racing thoughts at night are often about real problems. This technique doesn't suppress them — it parks them with a plan, removing their urgency from the sleep window.",
    icon: "note", color: "var(--good-400)", time: "10 min",
    steps: [
      "Spend 10 minutes writing down everything on your mind.",
      "For each item, write one sentence: what (if anything) you can do about it tomorrow.",
      "Close the notebook physically. The problems are parked until morning.",
      "When thoughts intrude in bed, remind yourself: 'Written down. Dealt with at 7 AM.'",
      "If a new worry comes, let it — it's just a thought, not an emergency requiring night action.",
      "Over time, the brain learns that night is not problem-solving time.",
    ],
  },
  defusion: {
    title: "Leaves on a stream (defusion)",
    when: "Night wakings · Any thought-loop moment",
    desc: "An ACT technique. Creates psychological distance from thoughts without suppressing them. Fighting thoughts gives them energy; watching them float by removes it.",
    icon: "leaf", color: "var(--accent)", time: "5 min",
    steps: [
      "Imagine sitting on the bank of a slow, quiet stream.",
      "Each thought that arises — place it on a leaf floating by.",
      "Watch the leaf carry the thought downstream. Don't grab it. Don't push it away.",
      "Example: 'I'll be useless tomorrow' → place it on a leaf → watch it float.",
      "If you find yourself absorbed by a thought (hooked), simply notice: 'I got hooked.' Return to the stream.",
      "The goal is not to stop thoughts. It's to stop engaging with them as if they're facts.",
    ],
  },
  beliefs: {
    title: "Sleep beliefs to examine",
    when: "Morning reflection · Week 3 onwards",
    desc: "CBT-I targets the beliefs that maintain insomnia. These aren't irrational — they feel completely true. That's what makes them worth examining.",
    icon: "brain", color: "var(--warm-400)", time: "Self-paced",
    items: [
      { belief: "I need 8 hours to function",
        reframe: "Sleep need is individual and usually 6–7 hours for most adults. The anxiety about hitting 8 hours creates hyperarousal that prevents sleep — the belief is self-fulfilling." },
      { belief: "One bad night will ruin tomorrow",
        reframe: "Sleep deprivation studies consistently show performance drops are smaller than people predict. Adrenaline, motivation, and context compensate substantially. You've managed before." },
      { belief: "I can't cope without sleep",
        reframe: "You are coping — you're doing it right now. The belief amplifies distress and arousal, making sleep harder. This is the exact cycle CBT-I breaks." },
      { belief: "Lying in bed resting is almost as good as sleep",
        reframe: "It's not equivalent — and this is precisely why getting up when awake matters. Passive wakefulness in bed trains the brain that bed = wakefulness." },
      { belief: "I should be able to control my sleep",
        reframe: "Sleep is involuntary. The harder you try to force it, the more you prevent it. Your role is to set up conditions — sleep is an automatic process that takes over from there." },
    ],
  },
};

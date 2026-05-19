"use client";

import { useState, useEffect, useMemo } from "react";

// ─── time utils ────────────────────────────────────────────────
function hhmm(str) {
  if (!str) return 0;
  const [h, m] = str.split(":").map(Number);
  return h * 60 + m;
}
function toHHMM(mins) {
  const m = ((mins % 1440) + 1440) % 1440;
  return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
}
function fmtTime(str) {
  if (!str) return "";
  const [h, m] = str.split(":").map(Number);
  return `${h % 12 || 12}:${String(m).padStart(2, "0")} ${h >= 12 ? "PM" : "AM"}`;
}
function calcLog(log) {
  let inBed = hhmm(log.inBed);
  let outBed = hhmm(log.outBed);
  if (outBed <= inBed) outBed += 1440;
  const tib = outBed - inBed;
  const tst = Math.max(0, tib - (log.latency || 0) - (log.wakeMin || 0));
  const se = tib > 0 ? Math.round((tst / tib) * 100) : 0;
  return { tib, tst, se };
}
function seColor(se) {
  if (se >= 85) return "var(--good-400)";
  if (se >= 75) return "var(--warn-400)";
  return "var(--crit-400)";
}

// ─── icons (stroke-based, minimal) ─────────────────────────────
const Icon = {
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
};

// ─── program content (preserved from original) ─────────────────
const WEEKS = [
  {
    title: "Sleep restriction + stimulus control",
    theme: "Build sleep pressure",
    bedtime: "11:45 PM",
    rules: [
      "Get into bed at 11:45 PM only — not before, even if exhausted.",
      "Get out of bed at 5:45 AM every single day, including weekends. Non-negotiable.",
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
    bedtime: "11:45 PM (or 11:15 if SE ≥85% for 5 nights)",
    rules: [
      "Continue all Week 1 rules — they remain in effect for the whole program.",
      "Start a 10-minute wind-down routine at 11:30 PM (dim lights, no screens, quiet).",
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
    bedtime: "Adjust per SE — see Progress tab",
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
    bedtime: "Adjust per SE",
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
    bedtime: "Target: 10:30–11:00 PM range",
    rules: [
      "For every 5-night stretch with SE ≥85%, move bedtime 15–30 minutes earlier.",
      "Keep wake time fixed at 5:45 AM — only ever adjust bedtime.",
      "Maintain stimulus control even as things improve — the association is still being built.",
      "Begin thinking about your maintenance habits for after the program ends.",
    ],
    expect: "Sleep should feel qualitatively different — deeper and more restorative even if the total hours are similar to before. Most people are at 6.5–7 hours of solid sleep by week 5.",
    cognitive: null,
  },
  {
    title: "Maintenance planning",
    theme: "Make this permanent",
    bedtime: "Your settled natural window",
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

const TOOLS = {
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
    when: "11:30 PM pre-bed routine",
    desc: "Racing thoughts at night are often about real problems. This technique doesn't suppress them — it parks them with a plan, removing their urgency from the sleep window.",
    icon: "note", color: "var(--good-400)", time: "10 min",
    steps: [
      "At 11:30 PM, spend 10 minutes writing down everything on your mind.",
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

const TAB_ITEMS = [
  { id: "today", label: "Today", icon: "moon" },
  { id: "program", label: "Program", icon: "book" },
  { id: "log", label: "Log", icon: "sun" },
  { id: "progress", label: "Progress", icon: "chart" },
  { id: "tools", label: "Tools", icon: "tools" },
];

// ─── ring (Apple-watch style) ──────────────────────────────────
function Ring({ value, max = 100, size = 120, stroke = 10, color = "var(--accent)", trackColor = "rgba(255,255,255,0.06)", children }) {
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

// ─── sparkline / bar chart ─────────────────────────────────────
function SparkArea({ data, width = 320, height = 130, accent = "var(--accent)", type = "bar" }) {
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

// ─── star field (subtle home backdrop) ─────────────────────────
function StarField({ count = 50, opacity = 0.7 }) {
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

// ─── form inputs ───────────────────────────────────────────────
function Stepper({ value, onChange, unit = "", step = 5, min = 0 }) {
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
function ScaleRow({ value, onChange }) {
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
function LogRow({ label, sublabel, children }) {
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

// ─── component ─────────────────────────────────────────────────
export default function CBTIProgram() {
  const [tab, setTab] = useState("today");
  const [logs, setLogs] = useState([]);
  const [startDate, setStartDate] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saveFeedback, setSaveFeedback] = useState("");
  const [activeWeek, setActiveWeek] = useState(0);
  const [activeTool, setActiveTool] = useState(null);

  const today = new Date().toISOString().split("T")[0];
  const todayLogged = logs.some((l) => l.date === today);

  const [form, setForm] = useState({
    date: today,
    inBed: "23:45",
    lightsOut: "23:45",
    latency: 20,
    wakeCount: 2,
    wakeMin: 45,
    finalWake: "05:45",
    outBed: "05:45",
    quality: 5,
    mood: 5,
  });

  useEffect(() => {
    try {
      const stored = localStorage.getItem("cbti:logs");
      if (stored) setLogs(JSON.parse(stored));
    } catch (e) {}
    try {
      const stored = localStorage.getItem("cbti:start");
      if (stored) setStartDate(stored);
    } catch (e) {}
    setLoading(false);
  }, []);

  function currentWeekNum() {
    if (!startDate) return 1;
    const diff = Math.floor((Date.now() - new Date(startDate).getTime()) / 86400000 / 7);
    return Math.min(6, diff + 1);
  }

  function saveLog() {
    const newLogs = [...logs.filter((l) => l.date !== form.date), { ...form }].sort((a, b) =>
      a.date.localeCompare(b.date)
    );
    setLogs(newLogs);
    try { localStorage.setItem("cbti:logs", JSON.stringify(newLogs)); } catch (e) {}
    if (!startDate) {
      setStartDate(form.date);
      try { localStorage.setItem("cbti:start", form.date); } catch (e) {}
    }
    setSaveFeedback("Saved");
    setTimeout(() => setSaveFeedback(""), 2000);
  }

  const chartData = logs.slice(-14).map((log) => {
    const { tst, se } = calcLog(log);
    return {
      date: log.date.slice(5),
      se,
      hrs: Math.round((tst / 60) * 10) / 10,
      quality: log.quality,
    };
  });
  const seSeries = chartData.map(d => d.se);
  const qSeries = chartData.map(d => d.quality * 10);

  const recent5 = logs.slice(-5);
  const avgSE = recent5.length
    ? Math.round(recent5.reduce((sum, l) => sum + calcLog(l).se, 0) / recent5.length)
    : null;

  // streak: consecutive days logged backward from today
  const streak = useMemo(() => {
    if (logs.length === 0) return 0;
    const set = new Set(logs.map(l => l.date));
    let s = 0;
    const d = new Date();
    for (;;) {
      const key = d.toISOString().split("T")[0];
      if (set.has(key)) { s++; d.setDate(d.getDate() - 1); } else break;
    }
    return s;
  }, [logs]);

  const preview = calcLog(form);
  const curWeek = currentWeekNum();
  const lastLog = logs.length ? logs[logs.length - 1] : null;
  const lastSE = lastLog ? calcLog(lastLog).se : null;
  const lastHrs = lastLog ? Math.round((calcLog(lastLog).tst / 60) * 10) / 10 : null;

  // tonight's bedtime from current week
  const tonightAtRaw = (WEEKS[curWeek - 1]?.bedtime || "11:45 PM").match(/\d{1,2}:\d{2}\s*[AP]M/i)?.[0] || "11:45 PM";

  // wind-down: minutes until bedtime - 15
  const windDownIn = useMemo(() => {
    const m = tonightAtRaw.match(/(\d{1,2}):(\d{2})\s*([AP])M/i);
    if (!m) return null;
    let h = Number(m[1]); const mm = Number(m[2]);
    if (/p/i.test(m[3]) && h !== 12) h += 12;
    if (/a/i.test(m[3]) && h === 12) h = 0;
    const target = h * 60 + mm - 15;
    const now = new Date();
    const cur = now.getHours() * 60 + now.getMinutes();
    let diff = target - cur;
    if (diff < 0) diff += 1440;
    return diff;
  }, [tonightAtRaw]);

  if (loading) {
    return (
      <div style={{ padding: "2rem", color: "var(--fg-3)", fontSize: 14, textAlign: "center" }}>
        Loading...
      </div>
    );
  }

  return (
    <div style={{
      minHeight: "100dvh",
      display: "flex", justifyContent: "center",
      background: "var(--bg-app)",
    }}>
      <div style={{
        width: "100%", maxWidth: 480,
        position: "relative",
        background: "var(--bg-app)",
        minHeight: "100dvh",
      }}>
        {tab === "today" && (
          <TodayView
            tonightAt={tonightAtRaw}
            windDownIn={windDownIn}
            streak={streak}
            weekNum={curWeek}
            lastSE={lastSE}
            lastHrs={lastHrs}
            avgSE={avgSE}
            hasLogged={todayLogged}
            onAction={(a) => {
              if (a === "program") setTab("program");
              else if (a === "log") setTab("log");
              else if (a === "tools") setTab("tools");
              else setTab("tools");
            }}
          />
        )}

        {tab === "program" && (
          <ProgramView curWeek={curWeek} activeWeek={activeWeek} setActiveWeek={setActiveWeek} />
        )}

        {tab === "log" && (
          <LogView
            form={form}
            setForm={setForm}
            preview={preview}
            todayLogged={todayLogged}
            saveFeedback={saveFeedback}
            saveLog={saveLog}
          />
        )}

        {tab === "progress" && (
          <ProgressView
            logs={logs}
            chartData={chartData}
            seSeries={seSeries}
            qSeries={qSeries}
            avgSE={avgSE}
            curWeek={curWeek}
            tonightAt={tonightAtRaw}
          />
        )}

        {tab === "tools" && (
          <ToolsView activeTool={activeTool} setActiveTool={setActiveTool} />
        )}

        <BottomTabBar tab={tab} onChange={setTab} />
      </div>
    </div>
  );
}

// ─── shared shell ──────────────────────────────────────────────
function PageShell({ children, withStars = false }) {
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

// ─── TODAY ─────────────────────────────────────────────────────
function TodayView({ tonightAt, windDownIn, streak, weekNum, lastSE, lastHrs, avgSE, hasLogged, onAction }) {
  const dayName = new Date().toLocaleDateString(undefined, { weekday: "long" });
  const hour = new Date().getHours();
  const greet = hour < 4 ? "Good night" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening";
  const week = WEEKS[weekNum - 1] || WEEKS[0];
  const cleanBedtime = tonightAt.replace(/\s*PM|\s*AM/i, "");

  return (
    <PageShell withStars>
      {/* Greeting */}
      <div style={{ marginBottom: 18 }}>
        <div className="kicker" style={{ marginBottom: 6 }}>{dayName} · Week {weekNum}</div>
        <div className="display">{greet}.</div>
        <div className="body" style={{ marginTop: 8, color: "var(--fg-3)", fontStyle: "italic", fontFamily: "var(--font-serif)" }}>
          &ldquo;Sleep is set up, not chased.&rdquo;
        </div>
      </div>

      {/* Hero: tonight's window */}
      <div style={{
        position: "relative",
        background: "linear-gradient(160deg, rgba(121,171,224,0.18) 0%, rgba(22,32,58,0.4) 100%)",
        border: "1px solid rgba(121,171,224,0.22)",
        borderRadius: 28,
        padding: "22px 22px 20px",
        marginBottom: 14,
        overflow: "hidden",
      }}>
        <div style={{ position: "absolute", top: -40, right: -40, width: 180, height: 180,
          background: "radial-gradient(circle, rgba(229,191,153,0.18) 0%, transparent 70%)",
          pointerEvents: "none",
        }} />
        <div className="kicker" style={{ color: "var(--sky-300)", marginBottom: 8 }}>Tonight&rsquo;s window</div>
        <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}>
          <div style={{ fontSize: 44, fontWeight: 600, letterSpacing: "-0.025em", color: "var(--fg-1)", fontVariantNumeric: "tabular-nums" }}>
            {cleanBedtime}
          </div>
          <div style={{ fontSize: 18, color: "var(--fg-3)" }}>{/PM/i.test(tonightAt) ? "PM" : "AM"}</div>
        </div>
        <div className="small" style={{ marginTop: 2 }}>
          {windDownIn != null && windDownIn < 240
            ? <>Wind-down begins in <span style={{ color: "var(--warm)", fontWeight: 600 }}>{windDownIn} min</span> · wake 5:45 AM</>
            : <>Wake at 5:45 AM · {week.theme}</>}
        </div>

        <button className="press reset" onClick={() => onAction?.("tools")}
          style={{
            marginTop: 16, width: "100%",
            padding: "12px 14px",
            background: "var(--accent)",
            color: "var(--night-950)",
            fontSize: 15, fontWeight: 600,
            borderRadius: 14,
            display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
          }}>
          <Icon.moon width={18} height={18} /> Start wind-down
        </button>
      </div>

      {/* Status row */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 14 }}>
        <div className="card" style={{ padding: 14 }}>
          <div className="kicker">Last night</div>
          {lastSE != null ? (
            <>
              <div style={{ fontSize: 28, fontWeight: 600, marginTop: 4, color: seColor(lastSE), fontVariantNumeric: "tabular-nums" }}>
                {lastSE}<span style={{ fontSize: 16, color: "var(--fg-4)" }}>%</span>
              </div>
              <div className="meta">{lastHrs}h sleep · SE</div>
            </>
          ) : (
            <>
              <div style={{ fontSize: 22, fontWeight: 500, marginTop: 4, color: "var(--fg-3)", fontFamily: "var(--font-serif)" }}>—</div>
              <div className="meta">Log to begin</div>
            </>
          )}
        </div>
        <div className="card" style={{ padding: 14 }}>
          <div className="kicker">Streak</div>
          <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 4 }}>
            <Icon.flame width={20} height={20} style={{ color: "var(--warm)" }}/>
            <div style={{ fontSize: 28, fontWeight: 600, fontVariantNumeric: "tabular-nums" }}>{streak}</div>
          </div>
          <div className="meta">nights logged</div>
        </div>
      </div>

      {/* Tonight's practice */}
      <div className="card" style={{ marginBottom: 14 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
          <div className="kicker">Tonight&rsquo;s practice</div>
          <button className="reset small press" style={{ color: "var(--accent)" }} onClick={() => onAction?.("program")}>
            See week →
          </button>
        </div>
        {(week.rules.slice(0, 3)).map((rule, i) => (
          <div key={i} style={{
            display: "flex", alignItems: "center", gap: 12,
            padding: "10px 2px",
            borderTop: i ? "1px solid var(--border-soft)" : "none",
          }}>
            <div style={{
              width: 32, height: 32, borderRadius: 10,
              background: "var(--accent-soft)",
              display: "flex", alignItems: "center", justifyContent: "center",
              color: "var(--accent-strong)",
              flexShrink: 0, fontSize: 13, fontWeight: 600,
            }}>{i + 1}</div>
            <div className="body" style={{ flex: 1, color: "var(--fg-2)", fontSize: 13 }}>{rule}</div>
          </div>
        ))}
      </div>

      {/* Morning log CTA */}
      {!hasLogged && (
        <button onClick={() => onAction?.("log")} className="press reset"
          style={{
            width: "100%",
            background: "var(--warm-soft)",
            border: "1px dashed rgba(219,168,122,0.4)",
            borderRadius: 18,
            padding: "14px 16px",
            display: "flex", alignItems: "center", gap: 12,
            marginBottom: 14,
            textAlign: "left",
          }}>
          <Icon.sun width={22} height={22} style={{ color: "var(--warm)" }}/>
          <div style={{ flex: 1 }}>
            <div className="h3" style={{ color: "var(--warm-200)", fontSize: 14 }}>Log today&rsquo;s night</div>
            <div className="meta">Fill in within 30 min of waking</div>
          </div>
          <Icon.chevron width={16} height={16} style={{ color: "var(--warm)" }}/>
        </button>
      )}

      {/* Quick tools */}
      <div className="kicker" style={{ marginBottom: 10 }}>Quick tools</div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10 }}>
        {[
          { id: "breathing", label: "Breathing", icon: "wind", c: "var(--sky-400)" },
          { id: "bodyscan", label: "Body scan", icon: "spark", c: "var(--warm-400)" },
          { id: "worrypost", label: "Worry park", icon: "note", c: "var(--good-400)" },
        ].map(t => {
          const Ico = Icon[t.icon];
          return (
            <button key={t.id} className="press reset" onClick={() => onAction?.("tools")}
              style={{
                background: "var(--bg-surface)",
                border: "1px solid var(--border-soft)",
                borderRadius: 16, padding: "14px 8px",
                display: "flex", flexDirection: "column",
                alignItems: "center", gap: 6,
                color: "var(--fg-2)",
              }}>
              <div style={{ color: t.c }}><Ico width={22} height={22}/></div>
              <div style={{ fontSize: 11, fontWeight: 500 }}>{t.label}</div>
            </button>
          );
        })}
      </div>
    </PageShell>
  );
}

// ─── PROGRAM ───────────────────────────────────────────────────
function ProgramView({ curWeek, activeWeek, setActiveWeek }) {
  const w = WEEKS[activeWeek];
  const stateOf = (i) => i + 1 < curWeek ? "done" : i + 1 === curWeek ? "current" : "upcoming";

  return (
    <PageShell>
      <div className="kicker" style={{ marginBottom: 6 }}>6-week program</div>
      <div className="h1" style={{ marginBottom: 18 }}>Restructure sleep, gently.</div>

      {/* Timeline */}
      <div style={{ position: "relative", marginBottom: 22 }}>
        <div style={{
          position: "absolute", left: 19, top: 14, bottom: 14,
          width: 2, background: "var(--border-soft)",
        }}/>
        {WEEKS.map((wk, i) => {
          const sel = activeWeek === i;
          const s = stateOf(i);
          const done = s === "done";
          const cur = s === "current";
          return (
            <button key={i} onClick={() => setActiveWeek(i)} className="press reset"
              style={{
                display: "flex", alignItems: "center", gap: 14,
                width: "100%", padding: "8px 10px 8px 0",
                background: sel ? "var(--accent-soft)" : "transparent",
                borderRadius: 14,
                marginBottom: 2,
                textAlign: "left",
                position: "relative",
              }}>
              <div style={{
                width: 40, height: 40, borderRadius: 999, flexShrink: 0,
                background: done ? "var(--accent)" : cur ? "var(--bg-app)" : "var(--bg-surface)",
                border: cur ? "2px solid var(--accent)" : "1px solid var(--border)",
                display: "flex", alignItems: "center", justifyContent: "center",
                color: done ? "var(--night-950)" : cur ? "var(--accent-strong)" : "var(--fg-4)",
                fontWeight: 600, fontSize: 14,
                position: "relative", zIndex: 1,
                boxShadow: cur ? "0 0 0 6px rgba(229,188,146,0.12)" : "none",
              }}>
                {done ? <Icon.check width={18} height={18}/> : i + 1}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 15, fontWeight: 600, color: sel || cur ? "var(--fg-1)" : "var(--fg-2)" }}>
                  {wk.theme}
                  {cur && <span className="chip chip-accent" style={{ marginLeft: 8, fontSize: 10, padding: "1px 7px" }}>now</span>}
                </div>
                <div className="meta" style={{ marginTop: 2 }}>{wk.title}</div>
              </div>
            </button>
          );
        })}
      </div>

      {/* Selected week detail */}
      <div className="card-elev" style={{ marginBottom: 14, padding: 0, overflow: "hidden" }}>
        <div style={{ padding: "18px 18px 12px" }}>
          <div className="kicker" style={{ color: "var(--accent-strong)" }}>Week {activeWeek + 1}</div>
          <div className="h2" style={{ marginTop: 4 }}>{w.theme}</div>
          <div className="small" style={{ marginTop: 4 }}>{w.title}</div>
          <div style={{ display: "flex", gap: 8, marginTop: 12, flexWrap: "wrap" }}>
            <div className="chip"><Icon.moon width={12} height={12}/> Bed {w.bedtime}</div>
            <div className="chip"><Icon.sun width={12} height={12}/> Wake 5:45 AM</div>
          </div>
        </div>
        <div style={{ borderTop: "1px solid var(--border-soft)", padding: "14px 18px" }}>
          <div className="kicker" style={{ marginBottom: 10 }}>Rules this week</div>
          {w.rules.map((r, i) => (
            <div key={i} style={{
              display: "flex", gap: 12, alignItems: "flex-start",
              padding: "8px 0",
              borderTop: i ? "1px solid var(--border-soft)" : "none",
            }}>
              <div style={{
                width: 4, height: 4, borderRadius: 999,
                background: "var(--accent)", marginTop: 9, flexShrink: 0,
              }}/>
              <div className="body" style={{ fontSize: 13, color: "var(--fg-2)" }}>{r}</div>
            </div>
          ))}
        </div>
        <div style={{
          padding: "12px 18px",
          background: "rgba(229,188,146,0.05)",
          borderTop: "1px solid var(--border-soft)",
        }}>
          <div className="kicker" style={{ color: "var(--warm)" }}>What to expect</div>
          <div className="body" style={{ marginTop: 6, fontSize: 13 }}>{w.expect}</div>
        </div>
        {w.cognitive && (
          <div style={{
            padding: "12px 18px",
            background: "rgba(121,171,224,0.06)",
            borderTop: "1px solid var(--border-soft)",
          }}>
            <div className="kicker" style={{ color: "var(--sky-300)" }}>Cognitive focus</div>
            <div className="body" style={{ marginTop: 6, fontSize: 13 }}>{w.cognitive}</div>
          </div>
        )}
      </div>
    </PageShell>
  );
}

// ─── MORNING LOG ───────────────────────────────────────────────
function LogView({ form, setForm, preview, todayLogged, saveFeedback, saveLog }) {
  const set = (k, val) => setForm((f) => ({ ...f, [k]: val }));
  const now = new Date();
  const timeNow = `${now.getHours() % 12 || 12}:${String(now.getMinutes()).padStart(2, "0")} ${now.getHours() >= 12 ? "PM" : "AM"}`;
  const dayName = now.toLocaleDateString(undefined, { weekday: "long" });

  // segment widths for visualizer
  const tibSafe = Math.max(1, preview.tib);
  const half = Math.max(0, (preview.tib - (form.latency || 0) - (form.wakeMin || 0)) / 2);
  const segs = [
    { w: (form.latency || 0) / tibSafe, c: "rgba(219,168,122,0.5)" },
    { w: half / tibSafe, c: "var(--sky-500)" },
    { w: (form.wakeMin || 0) / tibSafe, c: "rgba(217,124,124,0.6)" },
    { w: half / tibSafe, c: "var(--sky-500)" },
  ];

  return (
    <PageShell>
      <div className="kicker" style={{ marginBottom: 6 }}>{dayName} · {timeNow}</div>
      <div className="h1" style={{ marginBottom: 6 }}>How was the night?</div>
      <div className="small" style={{ marginBottom: 22 }}>
        Estimates are fine — better than checking a clock.
      </div>

      {/* Sleep block visualizer */}
      <div style={{
        position: "relative",
        background: "var(--bg-surface)",
        border: "1px solid var(--border-soft)",
        borderRadius: 20,
        padding: "16px 16px 18px",
        marginBottom: 16,
        overflow: "hidden",
      }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12 }}>
          <div className="kicker">Last night</div>
          <div className="meta">{Math.floor(preview.tib/60)}h {preview.tib%60}m in bed</div>
        </div>

        <div style={{
          height: 44, position: "relative",
          background: "linear-gradient(180deg, rgba(11,17,30,0.6) 0%, rgba(22,32,58,0.6) 100%)",
          borderRadius: 14, padding: "8px 12px",
          display: "flex", alignItems: "center",
        }}>
          {segs.map((s, i) => (
            <div key={i} style={{
              width: `${Math.max(0, s.w * 100)}%`,
              height: 28, background: s.c,
              borderRadius: i === 0 ? "10px 0 0 10px" : i === segs.length - 1 ? "0 10px 10px 0" : 0,
            }}/>
          ))}
        </div>
        <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8 }}>
          <div className="meta">{fmtTime(form.inBed)}</div>
          <div className="meta">{fmtTime(form.outBed)}</div>
        </div>

        <div style={{
          display: "grid", gridTemplateColumns: "1fr 1fr 1fr",
          gap: 8, marginTop: 14,
          padding: "10px 0 0", borderTop: "1px solid var(--border-soft)",
        }}>
          <div>
            <div style={{ fontSize: 16, fontWeight: 600, color: "var(--fg-1)", fontVariantNumeric: "tabular-nums" }}>
              {Math.floor(preview.tst/60)}h {preview.tst%60}m
            </div>
            <div className="meta">Asleep</div>
          </div>
          <div>
            <div style={{ fontSize: 16, fontWeight: 600, color: "var(--fg-1)", fontVariantNumeric: "tabular-nums" }}>
              {form.wakeMin}m
            </div>
            <div className="meta">Awake</div>
          </div>
          <div>
            <div style={{ fontSize: 16, fontWeight: 600, color: seColor(preview.se), fontVariantNumeric: "tabular-nums" }}>
              {preview.se}%
            </div>
            <div className="meta">Efficiency</div>
          </div>
        </div>
      </div>

      {/* Fields */}
      <LogRow label="In bed" sublabel="when you got under covers">
        <input type="time" value={form.inBed} onChange={(e) => set("inBed", e.target.value)} />
      </LogRow>
      <LogRow label="Lights out" sublabel="tried to fall asleep">
        <input type="time" value={form.lightsOut} onChange={(e) => set("lightsOut", e.target.value)} />
      </LogRow>
      <LogRow label="Time to fall asleep" sublabel="estimate, no clock-checking">
        <Stepper value={form.latency} onChange={(v) => set("latency", v)} unit="min" step={5}/>
      </LogRow>
      <LogRow label="Wakings during the night">
        <Stepper value={form.wakeCount} onChange={(v) => set("wakeCount", v)} unit={form.wakeCount === 1 ? "time" : "times"} step={1} min={0}/>
      </LogRow>
      <LogRow label="Total minutes awake">
        <Stepper value={form.wakeMin} onChange={(v) => set("wakeMin", v)} unit="min" step={5}/>
      </LogRow>
      <LogRow label="Final wake-up">
        <input type="time" value={form.finalWake} onChange={(e) => set("finalWake", e.target.value)} />
      </LogRow>
      <LogRow label="Out of bed">
        <input type="time" value={form.outBed} onChange={(e) => set("outBed", e.target.value)} />
      </LogRow>

      <LogRow label="Sleep quality" sublabel="how restorative did it feel?">
        <ScaleRow value={form.quality} onChange={(v) => set("quality", v)} />
      </LogRow>
      <LogRow label="Morning mood">
        <ScaleRow value={form.mood} onChange={(v) => set("mood", v)} />
      </LogRow>

      <button onClick={saveLog} className="press reset"
        style={{
          width: "100%", marginTop: 14,
          padding: "14px",
          background: "var(--accent)",
          color: "var(--night-950)",
          fontSize: 15, fontWeight: 600,
          borderRadius: 16,
          display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
        }}>
        <Icon.check width={18} height={18}/>
        {saveFeedback === "Saved" ? "Saved" : todayLogged ? "Update today's log" : "Save morning log"}
      </button>
    </PageShell>
  );
}

// ─── PROGRESS ──────────────────────────────────────────────────
function ProgressView({ logs, chartData, seSeries, qSeries, avgSE, curWeek, tonightAt }) {
  if (logs.length < 2) {
    return (
      <PageShell>
        <div className="kicker" style={{ marginBottom: 6 }}>Progress</div>
        <div className="h1" style={{ marginBottom: 18 }}>Charts unlock at 2 nights.</div>
        <div className="card">
          <div className="body" style={{ color: "var(--fg-2)" }}>
            Log at least 2 nights to see your trends. Your morning log builds the picture.
          </div>
        </div>
      </PageShell>
    );
  }

  const last5avg = avgSE;
  const earlyBedtime = (() => {
    const m = tonightAt.match(/(\d{1,2}):(\d{2})\s*([AP])M/i);
    if (!m) return tonightAt;
    let h = Number(m[1]); const mm = Number(m[2]);
    if (/p/i.test(m[3]) && h !== 12) h += 12;
    if (/a/i.test(m[3]) && h === 12) h = 0;
    const total = h * 60 + mm - 15;
    return fmtTime(toHHMM(total));
  })();

  return (
    <PageShell>
      <div className="kicker" style={{ marginBottom: 6 }}>{logs.length} nights</div>
      <div className="h1" style={{ marginBottom: 22 }}>
        {last5avg >= 85 ? "Your sleep is consolidating." : last5avg >= 75 ? "Steady progress — hold the line." : "Build pressure. It will land."}
      </div>

      {/* Rings hero */}
      <div className="card-elev" style={{
        background: "linear-gradient(160deg, rgba(229,188,146,0.10) 0%, rgba(22,32,58,0.3) 100%)",
        padding: "18px 16px",
        marginBottom: 14,
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <Ring value={last5avg} size={110} stroke={10} color={seColor(last5avg)}>
            <div style={{ fontSize: 26, fontWeight: 600, color: "var(--fg-1)", fontVariantNumeric: "tabular-nums" }}>
              {last5avg}<span style={{ fontSize: 13, color: "var(--fg-3)" }}>%</span>
            </div>
            <div className="meta">5-night SE</div>
          </Ring>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="kicker" style={{ color: seColor(last5avg) }}>
              {last5avg >= 85 ? "On target" : last5avg >= 75 ? "Building" : "Hold position"}
            </div>
            <div className="body" style={{ marginTop: 6, fontSize: 13, color: "var(--fg-2)" }}>
              {last5avg >= 85
                ? "You've crossed 85% — time to expand the window."
                : last5avg >= 75
                ? "Improvement is happening. Don't go to bed early."
                : "Sleep pressure is the engine. Keep restriction strict."}
            </div>
            {last5avg >= 85 && (
              <div style={{
                marginTop: 10, padding: "10px 12px",
                background: "rgba(122,183,139,0.10)",
                border: "1px solid rgba(122,183,139,0.22)",
                borderRadius: 12,
              }}>
                <div className="kicker" style={{ color: "var(--good-400)" }}>Suggested change</div>
                <div style={{ fontSize: 13, color: "var(--fg-1)", marginTop: 4 }}>
                  Move bedtime to <strong style={{ color: "var(--good-300)" }}>{earlyBedtime}</strong>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* SE chart */}
      <div className="card" style={{ marginBottom: 14 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
          <div className="h3">Sleep efficiency</div>
          <div className="chip" style={{ fontSize: 10 }}>Avg {last5avg}%</div>
        </div>
        <div className="meta" style={{ marginBottom: 12 }}>{logs.length > 14 ? "Last 14 nights" : `${logs.length} nights`} · target 85%</div>
        <SparkArea data={seSeries} width={336} height={130} type="bar" accent="var(--accent)"/>
      </div>

      {/* Quality chart */}
      <div className="card" style={{ marginBottom: 14 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
          <div className="h3">Sleep quality</div>
          <div className="chip" style={{ fontSize: 10 }}>/ 10</div>
        </div>
        <div className="meta" style={{ marginBottom: 12 }}>How restorative it felt</div>
        <SparkArea data={qSeries} width={336} height={110} type="area" accent="var(--sky-400)"/>
      </div>

      {/* Stats row */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10, marginBottom: 14 }}>
        {[
          ["Current", `Week ${curWeek}`],
          ["Logged", `${logs.length}`],
          ["5-night SE", last5avg ? `${last5avg}%` : "—"],
        ].map(([label, val]) => (
          <div key={label} className="card" style={{ padding: 12, textAlign: "center" }}>
            <div style={{ fontSize: 18, fontWeight: 600, color: "var(--fg-1)", fontVariantNumeric: "tabular-nums" }}>{val}</div>
            <div className="meta" style={{ marginTop: 2 }}>{label}</div>
          </div>
        ))}
      </div>
    </PageShell>
  );
}

// ─── TOOLS ─────────────────────────────────────────────────────
function ToolsView({ activeTool, setActiveTool }) {
  if (activeTool) {
    return <ToolDetailView toolId={activeTool} onBack={() => setActiveTool(null)} />;
  }
  const tools = Object.entries(TOOLS).map(([id, t]) => ({ id, ...t }));
  return (
    <PageShell>
      <div className="kicker" style={{ marginBottom: 6 }}>Toolkit</div>
      <div className="h1" style={{ marginBottom: 22 }}>What do you need right now?</div>

      {tools.map((t) => {
        const Ico = Icon[t.icon];
        return (
          <button key={t.id} onClick={() => setActiveTool(t.id)} className="press reset"
            style={{
              width: "100%", padding: 16,
              background: "var(--bg-surface)",
              border: "1px solid var(--border-soft)",
              borderRadius: 16,
              display: "flex", gap: 14, alignItems: "center", textAlign: "left",
              marginBottom: 10,
            }}>
            <div style={{
              width: 44, height: 44, borderRadius: 12,
              background: `${t.color}1f`,
              display: "flex", alignItems: "center", justifyContent: "center",
              color: t.color, flexShrink: 0,
            }}>
              <Ico width={22} height={22}/>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <div className="h3" style={{ fontSize: 14 }}>{t.title}</div>
                <div className="meta" style={{ fontSize: 10 }}>· {t.time}</div>
              </div>
              <div className="meta" style={{ marginTop: 2 }}>{t.when}</div>
            </div>
            <Icon.chevron width={14} height={14} style={{ color: "var(--fg-4)", flexShrink: 0 }}/>
          </button>
        );
      })}
    </PageShell>
  );
}

function ToolDetailView({ toolId, onBack }) {
  const t = TOOLS[toolId];
  const Ico = Icon[t.icon];

  return (
    <PageShell>
      <button onClick={onBack} className="reset press"
        style={{
          display: "inline-flex", alignItems: "center", gap: 6,
          color: "var(--fg-3)", fontSize: 13, marginBottom: 14,
        }}>
        ← Toolkit
      </button>

      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 6 }}>
        <div style={{
          width: 40, height: 40, borderRadius: 12,
          background: `${t.color}1f`,
          display: "flex", alignItems: "center", justifyContent: "center",
          color: t.color, flexShrink: 0,
        }}>
          <Ico width={20} height={20}/>
        </div>
        <div className="kicker">{t.time}</div>
      </div>

      <div className="h1" style={{ marginBottom: 4 }}>{t.title}</div>
      <div className="chip chip-accent" style={{ marginBottom: 14 }}>{t.when}</div>
      <div className="body" style={{ marginBottom: 22, color: "var(--fg-2)" }}>{t.desc}</div>

      {toolId !== "beliefs" ? (
        <>
          <div className="kicker" style={{ marginBottom: 10 }}>How to practice</div>
          {t.steps.map((s, i) => (
            <div key={i} className="card" style={{ marginBottom: 8, display: "flex", gap: 12, alignItems: "flex-start", padding: "14px 16px" }}>
              <div style={{
                width: 26, height: 26, borderRadius: 999,
                background: "var(--accent-soft)", color: "var(--accent-strong)",
                fontSize: 12, fontWeight: 600, flexShrink: 0,
                display: "flex", alignItems: "center", justifyContent: "center",
              }}>{i + 1}</div>
              <div className="body" style={{ fontSize: 13, color: "var(--fg-2)" }}>{s}</div>
            </div>
          ))}
        </>
      ) : (
        <>
          <div className="kicker" style={{ marginBottom: 10 }}>Five beliefs to examine</div>
          {t.items.map((item, i) => (
            <div key={i} className="card" style={{ marginBottom: 10 }}>
              <div style={{ fontSize: 15, fontWeight: 500, color: "var(--fg-1)", marginBottom: 10, fontFamily: "var(--font-serif)", fontStyle: "italic" }}>
                &ldquo;{item.belief}&rdquo;
              </div>
              <div className="kicker" style={{ marginBottom: 4, color: "var(--accent)" }}>Reframe</div>
              <div className="body" style={{ fontSize: 13, color: "var(--fg-2)" }}>{item.reframe}</div>
            </div>
          ))}
        </>
      )}
    </PageShell>
  );
}

// ─── BOTTOM TAB BAR ────────────────────────────────────────────
function BottomTabBar({ tab, onChange }) {
  return (
    <div style={{
      position: "fixed", left: 0, right: 0, bottom: 0,
      paddingBottom: 22, paddingTop: 10,
      background: "linear-gradient(180deg, rgba(26,20,16,0) 0%, var(--bg-app) 40%)",
      zIndex: 30,
      display: "flex", justifyContent: "center",
      pointerEvents: "none",
    }}>
      <div style={{
        margin: "0 12px",
        width: "100%", maxWidth: 456,
        background: "rgba(34,26,20,0.78)",
        backdropFilter: "blur(28px) saturate(180%)",
        WebkitBackdropFilter: "blur(28px) saturate(180%)",
        borderRadius: 28,
        border: "1px solid rgba(245,220,188,0.10)",
        boxShadow: "0 12px 32px rgba(0,0,0,0.4)",
        display: "flex", justifyContent: "space-around",
        padding: "8px 6px",
        pointerEvents: "auto",
      }}>
        {TAB_ITEMS.map(({ id, label, icon }) => {
          const Ico = Icon[icon];
          const active = tab === id;
          return (
            <button key={id} onClick={() => onChange(id)} className="press reset"
              aria-label={label}
              style={{
                flex: 1, display: "flex", flexDirection: "column", alignItems: "center",
                gap: 2, padding: "6px 4px",
                color: active ? "var(--accent-strong)" : "var(--fg-4)",
              }}>
              <Ico width={26} height={26} />
            </button>
          );
        })}
      </div>
    </div>
  );
}

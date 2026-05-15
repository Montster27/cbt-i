"use client";

import { useState, useEffect } from "react";
import { LineChart, Line, XAxis, YAxis, ReferenceLine, Tooltip, ResponsiveContainer } from "recharts";

// ─── time utils ────────────────────────────────────────────────────────────
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
  if (se >= 85) return "#3B6D11";
  if (se >= 75) return "#854F0B";
  return "#A32D2D";
}

// ─── program content ────────────────────────────────────────────────────────
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
    items: [
      {
        belief: "I need 8 hours to function",
        reframe: "Sleep need is individual and usually 6–7 hours for most adults. The anxiety about hitting 8 hours creates hyperarousal that prevents sleep — the belief is self-fulfilling.",
      },
      {
        belief: "One bad night will ruin tomorrow",
        reframe: "Sleep deprivation studies consistently show performance drops are smaller than people predict. Adrenaline, motivation, and context compensate substantially. You've managed before.",
      },
      {
        belief: "I can't cope without sleep",
        reframe: "You are coping — you're doing it right now. The belief amplifies distress and arousal, making sleep harder. This is the exact cycle CBT-I breaks.",
      },
      {
        belief: "Lying in bed resting is almost as good as sleep",
        reframe: "It's not equivalent — and this is precisely why getting up when awake matters. Passive wakefulness in bed trains the brain that bed = wakefulness.",
      },
      {
        belief: "I should be able to control my sleep",
        reframe: "Sleep is involuntary. The harder you try to force it, the more you prevent it. Your role is to set up conditions — sleep is an automatic process that takes over from there.",
      },
    ],
  },
};

// ─── component ─────────────────────────────────────────────────────────────
export default function CBTIProgram() {
  const [tab, setTab] = useState("program");
  const [logs, setLogs] = useState([]);
  const [startDate, setStartDate] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saveFeedback, setSaveFeedback] = useState("");
  const [activeWeek, setActiveWeek] = useState(0);
  const [activeTool, setActiveTool] = useState("breathing");

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

  const recent5 = logs.slice(-5);
  const avgSE = recent5.length
    ? Math.round(recent5.reduce((sum, l) => sum + calcLog(l).se, 0) / recent5.length)
    : null;

  const preview = calcLog(form);
  const curWeek = currentWeekNum();

  const tabStyle = (id) => ({
    padding: "6px 14px",
    borderRadius: 999,
    border: `0.5px solid ${tab === id ? "var(--color-border-primary)" : "var(--color-border-secondary)"}`,
    background: tab === id ? "var(--color-background-tertiary)" : "var(--color-background-primary)",
    color: tab === id ? "var(--color-text-primary)" : "var(--color-text-secondary)",
    fontSize: 13,
    fontWeight: tab === id ? 500 : 400,
    cursor: "pointer",
  });

  const pillStyle = (active) => ({
    padding: "4px 12px",
    borderRadius: 999,
    border: `0.5px solid ${active ? "var(--color-border-primary)" : "var(--color-border-tertiary)"}`,
    background: active ? "var(--color-background-secondary)" : "var(--color-background-primary)",
    color: active ? "var(--color-text-primary)" : "var(--color-text-secondary)",
    fontSize: 12,
    fontWeight: active ? 500 : 400,
    cursor: "pointer",
  });

  const card = {
    background: "var(--color-background-primary)",
    border: "0.5px solid var(--color-border-tertiary)",
    borderRadius: "var(--border-radius-lg)",
    padding: "1rem 1.25rem",
    marginBottom: 12,
  };

  if (loading) {
    return <div style={{ padding: "2rem", color: "var(--color-text-secondary)", fontSize: 14 }}>Loading...</div>;
  }

  return (
    <div style={{ paddingTop: "1rem" }}>
      <h2 className="sr-only">CBT-I 6-week sleep restructuring program</h2>

      <div style={{ marginBottom: "1.25rem" }}>
        <div style={{ fontSize: 11, color: "var(--color-text-tertiary)", letterSpacing: "0.06em", textTransform: "uppercase", marginBottom: 4 }}>
          CBT-I Program
        </div>
        <div style={{ fontSize: 20, fontWeight: 500, color: "var(--color-text-primary)" }}>6-week sleep restructuring</div>
        <div style={{ fontSize: 13, color: "var(--color-text-secondary)", marginTop: 4 }}>
          Fixed wake: 5:45 AM · Start bedtime: 11:45 PM · Focus: racing thoughts
        </div>
      </div>

      <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginBottom: "1.5rem" }}>
        {[["program", "Program"], ["log", `Morning log${!todayLogged ? " ·" : ""}`], ["progress", "Progress"], ["tools", "Tools"]].map(
          ([id, label]) => (
            <button key={id} onClick={() => setTab(id)} style={tabStyle(id)}>
              {label}
            </button>
          )
        )}
      </div>

      {tab === "program" && (
        <div>
          <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginBottom: "1rem" }}>
            {WEEKS.map((w, i) => (
              <button
                key={i}
                onClick={() => setActiveWeek(i)}
                style={{
                  ...pillStyle(activeWeek === i),
                  background:
                    i === curWeek - 1
                      ? "var(--color-background-info)"
                      : activeWeek === i
                      ? "var(--color-background-secondary)"
                      : "var(--color-background-primary)",
                  color:
                    i === curWeek - 1
                      ? "var(--color-text-info)"
                      : activeWeek === i
                      ? "var(--color-text-primary)"
                      : "var(--color-text-secondary)",
                  border: `0.5px solid ${i === curWeek - 1 ? "var(--color-border-info)" : activeWeek === i ? "var(--color-border-primary)" : "var(--color-border-tertiary)"}`,
                }}
              >
                Week {i + 1}{i === curWeek - 1 ? " ←" : ""}
              </button>
            ))}
          </div>

          {(() => {
            const w = WEEKS[activeWeek];
            return (
              <div>
                <div style={card}>
                  <div style={{ fontSize: 11, color: "var(--color-text-tertiary)", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: 4 }}>
                    Week {activeWeek + 1}
                  </div>
                  <div style={{ fontSize: 16, fontWeight: 500, color: "var(--color-text-primary)", marginBottom: 2 }}>{w.title}</div>
                  <div style={{ fontSize: 13, color: "var(--color-text-secondary)", marginBottom: "1rem" }}>{w.theme}</div>

                  <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: "1rem" }}>
                    {[["Bedtime", w.bedtime], ["Wake time", "5:45 AM"]].map(([label, val]) => (
                      <div key={label} style={{ background: "var(--color-background-secondary)", borderRadius: "var(--border-radius-md)", padding: "10px 12px" }}>
                        <div style={{ fontSize: 11, color: "var(--color-text-tertiary)" }}>{label}</div>
                        <div style={{ fontSize: 14, fontWeight: 500, color: "var(--color-text-primary)", marginTop: 2 }}>{val}</div>
                      </div>
                    ))}
                  </div>

                  <div style={{ fontSize: 13, fontWeight: 500, color: "var(--color-text-primary)", marginBottom: 10 }}>Rules for this week</div>
                  {w.rules.map((r, i) => (
                    <div key={i} style={{ display: "flex", gap: 10, marginBottom: 10, alignItems: "flex-start" }}>
                      <div style={{ minWidth: 22, height: 22, borderRadius: "50%", background: "var(--color-background-info)", color: "var(--color-text-info)", fontSize: 11, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 500, flexShrink: 0 }}>
                        {i + 1}
                      </div>
                      <div style={{ fontSize: 13, color: "var(--color-text-secondary)", lineHeight: 1.6, paddingTop: 2 }}>{r}</div>
                    </div>
                  ))}
                </div>

                <div style={{ background: "var(--color-background-secondary)", border: "0.5px solid var(--color-border-tertiary)", borderRadius: "var(--border-radius-md)", padding: "12px 14px", marginBottom: 12 }}>
                  <div style={{ fontSize: 12, fontWeight: 500, color: "var(--color-text-secondary)", marginBottom: 4 }}>What to expect</div>
                  <div style={{ fontSize: 13, color: "var(--color-text-secondary)", lineHeight: 1.6 }}>{w.expect}</div>
                </div>

                {w.cognitive && (
                  <div style={{ borderLeft: "3px solid #378ADD", padding: "10px 14px", fontSize: 13, color: "var(--color-text-primary)", lineHeight: 1.6 }}>
                    <div style={{ fontSize: 11, fontWeight: 500, color: "var(--color-text-tertiary)", marginBottom: 4 }}>Cognitive focus</div>
                    {w.cognitive}
                  </div>
                )}
              </div>
            );
          })()}
        </div>
      )}

      {tab === "log" && (
        <div>
          <div style={{ fontSize: 13, color: "var(--color-text-secondary)", lineHeight: 1.6, marginBottom: "1.25rem" }}>
            Fill this in each morning within 30 minutes of waking. Use estimates — do not check the clock at night.
          </div>

          {[
            ["inBed", "Time you got into bed", "time"],
            ["lightsOut", "Time you tried to sleep (lights out)", "time"],
            ["latency", "Minutes to fall asleep (estimate)", "number"],
            ["wakeCount", "Number of times you woke during the night", "number"],
            ["wakeMin", "Total minutes awake during the night (estimate)", "number"],
            ["finalWake", "Time of your final wake-up", "time"],
            ["outBed", "Time you got out of bed", "time"],
          ].map(([key, label, type]) => (
            <div key={key} style={{ marginBottom: 14 }}>
              <div style={{ fontSize: 13, color: "var(--color-text-secondary)", marginBottom: 5 }}>{label}</div>
              <input
                type={type === "time" ? "time" : "number"}
                value={form[key]}
                min={type === "number" ? 0 : undefined}
                onChange={(e) =>
                  setForm((f) => ({ ...f, [key]: type === "number" ? Number(e.target.value) : e.target.value }))
                }
                style={{ width: type === "time" ? 140 : 90 }}
              />
            </div>
          ))}

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 16 }}>
            {[["quality", "Sleep quality (1–10)"], ["mood", "Morning mood (1–10)"]].map(([key, label]) => (
              <div key={key}>
                <div style={{ fontSize: 13, color: "var(--color-text-secondary)", marginBottom: 6 }}>
                  {label}: <span style={{ fontWeight: 500, color: "var(--color-text-primary)" }}>{form[key]}</span>
                </div>
                <input
                  type="range"
                  min={1}
                  max={10}
                  step={1}
                  value={form[key]}
                  onChange={(e) => setForm((f) => ({ ...f, [key]: Number(e.target.value) }))}
                  style={{ width: "100%" }}
                />
              </div>
            ))}
          </div>

          <div style={{ background: "var(--color-background-secondary)", borderRadius: "var(--border-radius-md)", padding: "12px 14px", marginBottom: 14, display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 8 }}>
            {[
              ["Time in bed", `${Math.floor(preview.tib / 60)}h ${preview.tib % 60}m`, null],
              ["Est. sleep", `${Math.floor(preview.tst / 60)}h ${preview.tst % 60}m`, null],
              ["Sleep efficiency", `${preview.se}%`, seColor(preview.se)],
            ].map(([label, val, color]) => (
              <div key={label} style={{ textAlign: "center" }}>
                <div style={{ fontSize: 18, fontWeight: 500, color: color || "var(--color-text-primary)" }}>{val}</div>
                <div style={{ fontSize: 11, color: "var(--color-text-tertiary)", marginTop: 2 }}>{label}</div>
              </div>
            ))}
          </div>

          <button onClick={saveLog} style={{ width: "100%", padding: "10px", fontSize: 14 }}>
            {saveFeedback === "Saved" ? "✓ Saved" : todayLogged ? "Update today's log" : "Save today's log"}
          </button>
        </div>
      )}

      {tab === "progress" && (
        <div>
          {logs.length < 2 ? (
            <div style={{ fontSize: 13, color: "var(--color-text-secondary)", padding: "1.5rem 0", lineHeight: 1.6 }}>
              Log at least 2 nights to see your progress charts. The Morning log tab has a dot when today hasn't been logged yet.
            </div>
          ) : (
            <>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 10, marginBottom: "1.25rem" }}>
                {[
                  ["Current week", `Week ${curWeek}`],
                  ["Nights logged", `${logs.length}`],
                  ["5-night avg SE", avgSE ? `${avgSE}%` : "—"],
                ].map(([label, val]) => (
                  <div key={label} style={{ background: "var(--color-background-secondary)", borderRadius: "var(--border-radius-md)", padding: "12px", textAlign: "center" }}>
                    <div style={{ fontSize: 20, fontWeight: 500, color: "var(--color-text-primary)" }}>{val}</div>
                    <div style={{ fontSize: 11, color: "var(--color-text-secondary)", marginTop: 2 }}>{label}</div>
                  </div>
                ))}
              </div>

              {avgSE !== null && (
                <div style={{
                  background: avgSE >= 85 ? "var(--color-background-success)" : "var(--color-background-warning)",
                  border: `0.5px solid ${avgSE >= 85 ? "var(--color-border-success)" : "var(--color-border-warning)"}`,
                  borderRadius: "var(--border-radius-md)", padding: "10px 14px", marginBottom: "1.25rem",
                  fontSize: 13, lineHeight: 1.6,
                  color: avgSE >= 85 ? "var(--color-text-success)" : "var(--color-text-warning)",
                }}>
                  {avgSE >= 85
                    ? `SE ≥85% — move bedtime earlier to ${fmtTime(toHHMM(hhmm("23:45") - 15))} for the next 5 nights.`
                    : avgSE >= 75
                    ? "SE 75–84% — stay at current window. Improvement is happening, hold the line."
                    : "SE below 75% — maintain strict sleep restriction. Don't go to bed early. The pressure is building."}
                </div>
              )}

              <div style={{ fontSize: 13, fontWeight: 500, color: "var(--color-text-primary)", marginBottom: 8 }}>
                Sleep efficiency (last 14 nights)
              </div>
              <div style={{ height: 180, marginBottom: "1.5rem" }}>
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={chartData} margin={{ top: 4, right: 12, left: -20, bottom: 0 }}>
                    <XAxis dataKey="date" tick={{ fontSize: 11, fill: "var(--color-text-tertiary)" }} />
                    <YAxis domain={[0, 100]} tick={{ fontSize: 11, fill: "var(--color-text-tertiary)" }} />
                    <ReferenceLine y={85} stroke="#3B6D11" strokeDasharray="4 2" label={{ value: "85%", position: "right", fontSize: 10, fill: "#3B6D11" }} />
                    <Tooltip formatter={(v, n) => [n === "se" ? `${v}%` : n === "hrs" ? `${v} hrs` : `${v}/10`, n === "se" ? "Efficiency" : n === "hrs" ? "Sleep" : "Quality"]} contentStyle={{ fontSize: 12 }} />
                    <Line type="monotone" dataKey="se" stroke="#185FA5" strokeWidth={2} dot={{ r: 3, fill: "#185FA5" }} name="se" />
                  </LineChart>
                </ResponsiveContainer>
              </div>

              <div style={{ fontSize: 13, fontWeight: 500, color: "var(--color-text-primary)", marginBottom: 8 }}>
                Sleep quality rating
              </div>
              <div style={{ height: 140 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={chartData} margin={{ top: 4, right: 12, left: -20, bottom: 0 }}>
                    <XAxis dataKey="date" tick={{ fontSize: 11, fill: "var(--color-text-tertiary)" }} />
                    <YAxis domain={[1, 10]} tick={{ fontSize: 11, fill: "var(--color-text-tertiary)" }} />
                    <Tooltip formatter={(v) => [`${v}/10`, "Quality"]} contentStyle={{ fontSize: 12 }} />
                    <Line type="monotone" dataKey="quality" stroke="#1D9E75" strokeWidth={2} dot={{ r: 3, fill: "#1D9E75" }} />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </>
          )}
        </div>
      )}

      {tab === "tools" && (
        <div>
          <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginBottom: "1rem" }}>
            {[["breathing", "Breathing"], ["bodyscan", "Body scan"], ["worrypost", "Worry postponement"], ["defusion", "Defusion"], ["beliefs", "Sleep beliefs"]].map(
              ([id, label]) => (
                <button key={id} onClick={() => setActiveTool(id)} style={pillStyle(activeTool === id)}>
                  {label}
                </button>
              )
            )}
          </div>

          {activeTool !== "beliefs" ? (
            (() => {
              const t = TOOLS[activeTool];
              return (
                <div style={card}>
                  <div style={{ fontSize: 15, fontWeight: 500, color: "var(--color-text-primary)", marginBottom: 4 }}>{t.title}</div>
                  <div style={{ fontSize: 11, color: "var(--color-text-info)", background: "var(--color-background-info)", display: "inline-block", padding: "2px 10px", borderRadius: 999, marginBottom: 10 }}>
                    {t.when}
                  </div>
                  <div style={{ fontSize: 13, color: "var(--color-text-secondary)", lineHeight: 1.6, marginBottom: "1rem" }}>{t.desc}</div>
                  {t.steps.map((s, i) => (
                    <div key={i} style={{ display: "flex", gap: 10, marginBottom: 10, alignItems: "flex-start" }}>
                      <div style={{ minWidth: 22, height: 22, borderRadius: "50%", background: "var(--color-background-tertiary)", color: "var(--color-text-secondary)", fontSize: 11, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 500, flexShrink: 0 }}>
                        {i + 1}
                      </div>
                      <div style={{ fontSize: 13, color: "var(--color-text-secondary)", lineHeight: 1.6, paddingTop: 2 }}>{s}</div>
                    </div>
                  ))}
                </div>
              );
            })()
          ) : (
            <div>
              <div style={{ fontSize: 13, color: "var(--color-text-secondary)", lineHeight: 1.6, marginBottom: "1rem" }}>
                {TOOLS.beliefs.desc}
              </div>
              {TOOLS.beliefs.items.map((item, i) => (
                <div key={i} style={card}>
                  <div style={{ fontSize: 13, fontWeight: 500, color: "var(--color-text-primary)", marginBottom: 8 }}>
                    &quot;{item.belief}&quot;
                  </div>
                  <div style={{ fontSize: 11, color: "var(--color-text-tertiary)", marginBottom: 4 }}>Reframe</div>
                  <div style={{ fontSize: 13, color: "var(--color-text-secondary)", lineHeight: 1.6 }}>{item.reframe}</div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

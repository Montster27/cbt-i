import { useMemo } from "react";
import { Icon, PageShell, WEEKS, fmtTime, toHHMM } from "./Common";

export default function ProgramView({ curWeek, activeWeek, setActiveWeek, anchorWakeTime }) {
  const w = WEEKS[activeWeek];
  const stateOf = (i) => i + 1 < curWeek ? "done" : i + 1 === curWeek ? "current" : "upcoming";

  const bedtimeForActive = useMemo(() => {
    const [h, m] = anchorWakeTime.split(":").map(Number);
    const wakeMins = h * 60 + m;
    return wakeMins + w.bedOffset;
  }, [anchorWakeTime, w.bedOffset]);

  return (
    <PageShell>
      <div className="kicker" style={{ marginBottom: 6 }}>6-week program</div>
      <div className="h1" style={{ marginBottom: 18 }}>Restructure sleep, gently.</div>

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

      <div className="card-elev" style={{ marginBottom: 14, padding: 0, overflow: "hidden" }}>
        <div style={{ padding: "18px 18px 12px" }}>
          <div className="kicker" style={{ color: "var(--accent-strong)" }}>Week {activeWeek + 1}</div>
          <div className="h2" style={{ marginTop: 4 }}>{w.theme}</div>
          <div className="small" style={{ marginTop: 4 }}>{w.title}</div>
          <div style={{ display: "flex", gap: 8, marginTop: 12, flexWrap: "wrap" }}>
            <div className="chip"><Icon.moon width={12} height={12}/> Bed {fmtTime(toHHMM(bedtimeForActive))}</div>
            <div className="chip"><Icon.sun width={12} height={12}/> Wake {fmtTime(anchorWakeTime)}</div>
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

// Helper for useMemo inside component

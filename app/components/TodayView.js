import { useMemo } from "react";
import { Icon, PageShell, fmtTime, toHHMM, seColor, WEEKS, calcLog } from "./Common";

export default function TodayView({ anchorWakeTime, weekNum, logs, onAction }) {
  const dayName = new Date().toLocaleDateString(undefined, { weekday: "long" });
  const hour = new Date().getHours();
  const greet = hour < 4 ? "Good night" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening";
  const week = WEEKS[weekNum - 1] || WEEKS[0];
  
  const tonightBedtimeMins = useMemo(() => {
    const [h, m] = anchorWakeTime.split(":").map(Number);
    const wakeMins = h * 60 + m;
    return wakeMins + week.bedOffset;
  }, [anchorWakeTime, week.bedOffset]);

  const tonightAt = fmtTime(toHHMM(tonightBedtimeMins));
  const cleanBedtime = tonightAt.replace(/\s*PM|\s*AM/i, "");

  const lastLog = logs.length ? logs[logs.length - 1] : null;
  const lastSE = lastLog ? calcLog(lastLog).se : null;
  const lastHrs = lastLog ? Math.round((calcLog(lastLog).tst / 60) * 10) / 10 : null;

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

  const windDownIn = useMemo(() => {
    const now = new Date();
    const cur = now.getHours() * 60 + now.getMinutes();
    let diff = tonightBedtimeMins - 15 - cur;
    if (diff < 0) diff += 1440;
    return diff;
  }, [tonightBedtimeMins]);

  const hasLoggedToday = logs.some(l => l.date === new Date().toISOString().split("T")[0]);

  return (
    <PageShell withStars>
      <div style={{ marginBottom: 18 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <div>
            <div className="kicker" style={{ marginBottom: 6 }}>{dayName} · Week {weekNum}</div>
            <div className="display">{greet}.</div>
          </div>
          <button className="press reset" onClick={() => onAction?.("settings")}
            style={{ padding: 8, background: "var(--bg-elev)", borderRadius: 12 }}>
            <Icon.settings width={20} height={20} style={{ color: "var(--fg-3)" }} />
          </button>
        </div>
        <div className="body" style={{ marginTop: 8, color: "var(--fg-3)", fontStyle: "italic", fontFamily: "var(--font-serif)" }}>
          &ldquo;Sleep is set up, not chased.&rdquo;
        </div>
      </div>

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
          <div style={{ fontSize: 18, color: "var(--fg-3)" }}>{tonightAt.includes("PM") ? "PM" : "AM"}</div>
        </div>
        <div className="small" style={{ marginTop: 2 }}>
          {windDownIn != null && windDownIn < 240
            ? <>Wind-down begins in <span style={{ color: "var(--warm)", fontWeight: 600 }}>{windDownIn} min</span> · wake {fmtTime(anchorWakeTime)}</>
            : <>Wake at {fmtTime(anchorWakeTime)} · {week.theme}</>}
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

      {!hasLoggedToday && (
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

      <div className="kicker" style={{ marginBottom: 10 }}>Quick tools</div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10 }}>
        {[
          { id: "breathing", label: "Breathing", icon: "wind", c: "var(--sky-400)" },
          { id: "bodyscan", label: "Body scan", icon: "spark", c: "var(--warm-400)" },
          { id: "worrypost", label: "Worry park", icon: "note", c: "var(--good-400)" },
        ].map(t => {
          const Ico = Icon[t.icon];
          return (
            <button key={t.id} className="press reset" onClick={() => onAction?.("tools", t.id)}
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

"use client";

import { Icon, PageShell, fmtTime, seColor, LogRow, Stepper, ScaleRow } from "./Common";

export default function LogView({ form, setForm, preview, todayLogged, saveFeedback, saveLog }) {
  const set = (k, val) => setForm((f) => ({ ...f, [k]: val }));
  const now = new Date();
  const timeNow = `${now.getHours() % 12 || 12}:${String(now.getMinutes()).padStart(2, "0")} ${now.getHours() >= 12 ? "PM" : "AM"}`;
  const dayName = now.toLocaleDateString(undefined, { weekday: "long" });

  // segment widths for visualizer
  const tibSafe = Math.max(1, preview.tib);
  const half = Math.max(0, (preview.tib - (form.latency || 0) - (form.wakeMin || 0)) / 2);
  const segs = [
    { w: (form.latency || 0) / tibSafe, c: "rgba(219,168,122,0.5)" }, // Latency
    { w: half / tibSafe, c: "var(--sky-500)" }, // Sleep 1
    { w: (form.wakeMin || 0) / tibSafe, c: "rgba(217,124,124,0.6)" }, // Awake
    { w: half / tibSafe, c: "var(--sky-500)" }, // Sleep 2
  ];

  return (
    <PageShell>
      <div className="kicker" style={{ marginBottom: 6 }}>{dayName} · {timeNow}</div>
      <div className="h1" style={{ marginBottom: 6 }}>How was the night?</div>
      <div className="small" style={{ marginBottom: 22 }}>
        Estimates are fine — better than checking a clock.
      </div>

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

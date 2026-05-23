"use client";

import { useMemo } from "react";
import { PageShell, Ring, SparkArea, seColor, fmtTime, toHHMM } from "./Common";

export default function ProgressView({ logs, chartData, seSeries, qSeries, avgSE, curWeek, anchorWakeTime, weekOffset }) {
  const suggestedBedtime = useMemo(() => {
    if (!anchorWakeTime) return "";
    const [h, m] = anchorWakeTime.split(":").map(Number);
    const wakeMins = h * 60 + m;
    // suggest 15m earlier if SE is good
    const currentOffset = weekOffset;
    const newOffset = avgSE >= 85 ? currentOffset - 15 : currentOffset;
    return fmtTime(toHHMM(wakeMins + newOffset));
  }, [anchorWakeTime, weekOffset, avgSE]);

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
                  Move bedtime to <strong style={{ color: "var(--good-300)" }}>{suggestedBedtime}</strong>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="card" style={{ marginBottom: 14 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
          <div className="h3">Sleep efficiency</div>
          <div className="chip" style={{ fontSize: 10 }}>Avg {last5avg}%</div>
        </div>
        <div className="meta" style={{ marginBottom: 12 }}>{logs.length > 14 ? "Last 14 nights" : `${logs.length} nights`} · target 85%</div>
        <SparkArea data={seSeries} width={336} height={130} type="bar" accent="var(--accent)"/>
      </div>

      <div className="card" style={{ marginBottom: 14 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
          <div className="h3">Sleep quality</div>
          <div className="chip" style={{ fontSize: 10 }}>/ 10</div>
        </div>
        <div className="meta" style={{ marginBottom: 12 }}>How restorative it felt</div>
        <SparkArea data={qSeries} width={336} height={110} type="area" accent="var(--sky-400)"/>
      </div>

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

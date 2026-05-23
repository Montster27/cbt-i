"use client";

import { useState, useEffect } from "react";
import { PageShell, Icon, TOOLS } from "./Common";
import BreathingTimer from "./BreathingTimer";

export default function ToolsView({ activeTool, setActiveTool }) {
  const [showBreathingTimer, setShowBreathingTimer] = useState(false);

  const [prevActiveTool, setPrevActiveTool] = useState(activeTool);
  if (activeTool !== prevActiveTool) {
    setPrevActiveTool(activeTool);
    if (activeTool !== "breathing") {
      setShowBreathingTimer(false);
    }
  }

  if (activeTool === "breathing" && showBreathingTimer) {
    return (
      <PageShell>
        <button onClick={() => setShowBreathingTimer(false)} className="reset press"
          style={{ display: "inline-flex", alignItems: "center", gap: 6, color: "var(--fg-3)", fontSize: 13, marginBottom: 14 }}>
          ← Back to Tutorial
        </button>
        <BreathingTimer onBack={() => setShowBreathingTimer(false)} />
      </PageShell>
    );
  }

  if (activeTool) {
    return (
      <ToolDetailView
        toolId={activeTool}
        onBack={() => setActiveTool(null)}
        onStartTimer={() => setShowBreathingTimer(true)}
      />
    );
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

function ToolDetailView({ toolId, onBack, onStartTimer }) {
  const t = TOOLS[toolId];
  if (!t) return null;
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

      {toolId === "breathing" && (
        <button onClick={onStartTimer} className="press reset"
          style={{
            width: "100%", padding: "14px 20px",
            background: "linear-gradient(135deg, var(--sky-500), var(--accent))",
            color: "var(--night-950)",
            borderRadius: 12, fontWeight: 600, fontSize: 15,
            display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
            marginBottom: 24, boxShadow: "0 4px 12px rgba(14, 165, 233, 0.2)"
          }}>
          <Icon.wind width={18} height={18} />
          Start Interactive Timer
        </button>
      )}

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

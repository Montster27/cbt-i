"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { Icon } from "./Common";

const PHASES = {
  inhale: { duration: 4, text: "Inhale", color: "var(--sky-400)" },
  hold: { duration: 7, text: "Hold", color: "var(--accent)" },
  exhale: { duration: 8, text: "Exhale", color: "var(--warm-500)" },
};

export default function BreathingTimer({ onBack }) {
  const [phase, setPhase] = useState("ready"); // ready, inhale, hold, exhale
  const [count, setCount] = useState(0);
  const [cycle, setCycle] = useState(0);
  const timerRef = useRef(null);

  const nextPhase = useCallback((current) => {
    setPhase(current);
    setCount(PHASES[current].duration);
  }, []);

  const start = () => {
    setCycle(1);
    nextPhase("inhale");
  };

  useEffect(() => {
    if (phase === "ready") return;

    timerRef.current = setInterval(() => {
      setCount((c) => {
        if (c <= 1) {
          if (phase === "inhale") nextPhase("hold");
          else if (phase === "hold") nextPhase("exhale");
          else if (phase === "exhale") {
            if (cycle < 4) {
              setCycle((cy) => cy + 1);
              nextPhase("inhale");
            } else {
              setPhase("complete");
              return 0;
            }
          }
          return 0;
        }
        return c - 1;
      });
    }, 1000);

    return () => clearInterval(timerRef.current);
  }, [phase, cycle, nextPhase]);

  const reset = () => {
    clearInterval(timerRef.current);
    setPhase("ready");
    setCount(0);
    setCycle(0);
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", minHeight: "60vh" }}>
      {phase === "ready" ? (
        <div style={{ textAlign: "center" }}>
          <div style={{
            width: 120, height: 120, borderRadius: "50%",
            background: "var(--sky-400)", opacity: 0.2,
            display: "flex", alignItems: "center", justifyContent: "center",
            margin: "0 auto 32px",
            animation: "pulse-soft 3s infinite ease-in-out"
          }}>
            <Icon.wind width={48} height={48} style={{ color: "var(--sky-400)" }} />
          </div>
          <div className="h1" style={{ marginBottom: 12 }}>4-7-8 Breathing</div>
          <div className="body" style={{ maxWidth: 280, margin: "0 auto 32px", color: "var(--fg-3)" }}>
            Inhale for 4s, hold for 7s, exhale for 8s. Repeat for 4 cycles.
          </div>
          <button className="press reset" onClick={start}
            style={{
              padding: "16px 48px", background: "var(--accent)", color: "var(--night-950)",
              borderRadius: 100, fontWeight: 600, fontSize: 16
            }}>
            Begin
          </button>
        </div>
      ) : phase === "complete" ? (
        <div style={{ textAlign: "center" }}>
          <div style={{
             width: 80, height: 80, borderRadius: "50%",
             background: "var(--good-400)", color: "var(--night-950)",
             display: "flex", alignItems: "center", justifyContent: "center",
             margin: "0 auto 24px"
          }}>
            <Icon.check width={40} height={40} />
          </div>
          <div className="h1" style={{ marginBottom: 12 }}>Session Complete</div>
          <div className="body" style={{ marginBottom: 32 }}>Feeling calmer?</div>
          <button className="press reset" onClick={onBack}
            style={{ color: "var(--accent)", fontWeight: 500 }}>
            Back to Tools
          </button>
        </div>
      ) : (
        <div style={{ textAlign: "center" }}>
          <div style={{ position: "relative", width: 220, height: 220, margin: "0 auto 40px" }}>
            <div style={{
              position: "absolute", inset: 0, borderRadius: "50%",
              background: PHASES[phase].color,
              opacity: 0.15,
              transform: phase === "inhale" ? "scale(1.2)" : phase === "hold" ? "scale(1.2)" : "scale(1)",
              transition: `transform ${PHASES[phase].duration}s linear, background-color 0.5s ease`
            }} />
            <div style={{
              position: "absolute", inset: 40, borderRadius: "50%",
              border: `2px solid ${PHASES[phase].color}`,
              display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
              transition: "border-color 0.5s ease"
            }}>
              <div style={{ fontSize: 40, fontWeight: 700, color: "var(--fg-1)" }}>{count}</div>
              <div className="kicker" style={{ color: PHASES[phase].color }}>{PHASES[phase].text}</div>
            </div>
          </div>
          <div className="meta" style={{ marginBottom: 24 }}>Cycle {cycle} of 4</div>
          <button className="press reset" onClick={reset}
            style={{ color: "var(--fg-4)", fontSize: 13 }}>
            Stop
          </button>
        </div>
      )}
    </div>
  );
}

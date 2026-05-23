"use client";

import { useState, useEffect, useMemo } from "react";
import { Icon, calcLog, WEEKS } from "./components/Common";
import TodayView from "./components/TodayView";
import ProgramView from "./components/ProgramView";
import LogView from "./components/LogView";
import ProgressView from "./components/ProgressView";
import ToolsView from "./components/ToolsView";

const TAB_ITEMS = [
  { id: "today", label: "Today", icon: "moon" },
  { id: "program", label: "Program", icon: "book" },
  { id: "log", label: "Log", icon: "sun" },
  { id: "progress", label: "Progress", icon: "chart" },
  { id: "tools", label: "Tools", icon: "tools" },
];

export default function CBTIProgram() {
  const [tab, setTab] = useState("today");
  const [logs, setLogs] = useState([]);
  const [startDate, setStartDate] = useState(null);
  const [anchorWakeTime, setAnchorWakeTime] = useState("05:45");
  const [loading, setLoading] = useState(true);
  const [saveFeedback, setSaveFeedback] = useState("");
  const [activeWeek, setActiveWeek] = useState(0);
  const [activeTool, setActiveTool] = useState(null);
  const [curWeek, setCurWeek] = useState(1);

  useEffect(() => {
    const timer = setTimeout(() => {
      try {
        const storedLogs = localStorage.getItem("cbti:logs");
        if (storedLogs) setLogs(JSON.parse(storedLogs));
        
        const storedStart = localStorage.getItem("cbti:start");
        if (storedStart) {
          setStartDate(storedStart);
          const diff = Math.floor((Date.now() - new Date(storedStart).getTime()) / 86400000 / 7);
          setCurWeek(Math.min(6, diff + 1));
        }
        
        const storedAnchor = localStorage.getItem("cbti:anchor");
        if (storedAnchor) setAnchorWakeTime(storedAnchor);
      } catch (e) {}
      setLoading(false);
    }, 0);
    return () => clearTimeout(timer);
  }, []);

  function saveLog(formData) {
    const newLogs = [...logs.filter((l) => l.date !== formData.date), { ...formData }].sort((a, b) =>
      a.date.localeCompare(b.date)
    );
    setLogs(newLogs);
    try { localStorage.setItem("cbti:logs", JSON.stringify(newLogs)); } catch (e) {}
    if (!startDate) {
      setStartDate(formData.date);
      try { localStorage.setItem("cbti:start", formData.date); } catch (e) {}
      const diff = Math.floor((Date.now() - new Date(formData.date).getTime()) / 86400000 / 7);
      setCurWeek(Math.min(6, diff + 1));
    }
    setSaveFeedback("Saved");
    setTimeout(() => setSaveFeedback(""), 2000);
  }

  function handleAnchorChange(time) {
    setAnchorWakeTime(time);
    try { localStorage.setItem("cbti:anchor", time); } catch (e) {}
  }

  const chartData = useMemo(() => logs.slice(-14).map((log) => {
    const { tst, se } = calcLog(log);
    return {
      date: log.date.slice(5),
      se,
      hrs: Math.round((tst / 60) * 10) / 10,
      quality: log.quality,
    };
  }), [logs]);

  const seSeries = useMemo(() => chartData.map(d => d.se), [chartData]);
  const qSeries = useMemo(() => chartData.map(d => d.quality * 10), [chartData]);

  const recent5 = logs.slice(-5);
  const avgSE = recent5.length
    ? Math.round(recent5.reduce((sum, l) => sum + calcLog(l).se, 0) / recent5.length)
    : null;

  const todayDate = new Date().toISOString().split("T")[0];
  const [form, setForm] = useState({
    date: todayDate,
    inBed: "23:45",
    lightsOut: "23:45",
    latency: 20,
    wakeCount: 2,
    wakeMin: 45,
    finalWake: anchorWakeTime,
    outBed: anchorWakeTime,
    quality: 5,
    mood: 5,
  });

  const [prevAnchorWakeTime, setPrevAnchorWakeTime] = useState(anchorWakeTime);
  if (anchorWakeTime !== prevAnchorWakeTime) {
    setPrevAnchorWakeTime(anchorWakeTime);
    setForm(f => ({ ...f, finalWake: anchorWakeTime, outBed: anchorWakeTime }));
  }

  if (loading) {
    return (
      <div style={{ padding: "2rem", color: "var(--fg-3)", fontSize: 14, textAlign: "center" }}>
        Loading...
      </div>
    );
  }

  return (
    <div style={{ minHeight: "100dvh", display: "flex", justifyContent: "center", background: "var(--bg-app)" }}>
      <div style={{ width: "100%", maxWidth: 480, position: "relative", background: "var(--bg-app)", minHeight: "100dvh" }}>
        
        {tab === "today" && (
          <TodayView 
            anchorWakeTime={anchorWakeTime} 
            weekNum={curWeek} 
            logs={logs} 
            onAction={(a, id) => {
              if (a === "settings") setTab("settings");
              else if (a === "log") setTab("log");
              else if (a === "tools") {
                setTab("tools");
                if (id) setActiveTool(id);
              }
              else if (a === "program") setTab("program");
            }} 
          />
        )}

        {tab === "program" && (
          <ProgramView 
            curWeek={curWeek} 
            activeWeek={activeWeek} 
            setActiveWeek={setActiveWeek} 
            anchorWakeTime={anchorWakeTime} 
          />
        )}

        {tab === "log" && (
          <LogView
            form={form}
            setForm={setForm}
            preview={calcLog(form)}
            todayLogged={logs.some(l => l.date === todayDate)}
            saveFeedback={saveFeedback}
            saveLog={() => saveLog(form)}
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
            anchorWakeTime={anchorWakeTime}
            weekOffset={WEEKS[curWeek - 1]?.bedOffset || -360}
          />
        )}

        {tab === "tools" && (
          <ToolsView activeTool={activeTool} setActiveTool={setActiveTool} />
        )}

        {tab === "settings" && (
          <SettingsView 
            anchorWakeTime={anchorWakeTime} 
            onAnchorChange={handleAnchorChange} 
            onBack={() => setTab("today")} 
          />
        )}

        <BottomTabBar tab={tab} onChange={(t) => { setTab(t); setActiveTool(null); }} />
      </div>
    </div>
  );
}

function SettingsView({ anchorWakeTime, onAnchorChange, onBack }) {
  return (
    <div style={{ padding: "44px 18px", color: "var(--fg-1)" }}>
      <button onClick={onBack} className="reset press" style={{ color: "var(--fg-3)", marginBottom: 24 }}>← Back</button>
      <div className="h1" style={{ marginBottom: 32 }}>Settings</div>
      
      <div className="card" style={{ marginBottom: 24 }}>
        <div className="kicker" style={{ marginBottom: 12 }}>Personalization</div>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div>
            <div style={{ fontSize: 16, fontWeight: 500 }}>Anchor Wake Time</div>
            <div className="meta">Keep this fixed, even on weekends.</div>
          </div>
          <input type="time" value={anchorWakeTime} onChange={(e) => onAnchorChange(e.target.value)} />
        </div>
      </div>

      <div className="body" style={{ color: "var(--fg-4)", fontSize: 13 }}>
        CBT-I relies on a consistent wake-up time. Changing this mid-program is generally discouraged but occasionally necessary for schedule shifts.
      </div>
    </div>
  );
}

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

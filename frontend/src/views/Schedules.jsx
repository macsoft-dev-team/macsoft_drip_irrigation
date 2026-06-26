
import React, { useState, useEffect } from "react"
import { Clock, Plus, Trash2, Calendar, Droplets, GripVertical, PlusCircle, ArrowRight, Activity, Grid } from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

const zoneValvesMap = {
  "Front Lawn": [
    { id: "v1", name: "Valve FL-1 (Spray)" },
    { id: "v2", name: "Valve FL-2 (Rotor)" },
    { id: "v3", name: "Valve FL-3 (Drip Edge)" }
  ],
  "Orchard & Vines": [
    { id: "v4", name: "Valve OV-1 (Root Soak)" },
    { id: "v5", name: "Valve OV-2 (Micro-Sprays)" }
  ],
  "Vegetable Beds": [
    { id: "v6", name: "Valve VB-1 (Direct Drip)" },
    { id: "v7", name: "Valve VB-2 (Drip Line 2)" }
  ],
  "Greenhouse Herbs": [
    { id: "v8", name: "Valve GH-1 (Herbs Mist)" },
    { id: "v9", name: "Valve GH-2 (Veg Mist)" }
  ]
};

const availableItems = [
  { type: "zone", id: "z1", name: "Front Lawn" },
  { type: "zone", id: "z2", name: "Orchard & Vines" },
  { type: "zone", id: "z3", name: "Vegetable Beds" },
  { type: "zone", id: "z4", name: "Greenhouse Herbs" },
  { type: "valve", id: "v1", name: "Valve FL-1 (Spray)" },
  { type: "valve", id: "v2", name: "Valve FL-2 (Rotor)" },
  { type: "valve", id: "v3", name: "Valve FL-3 (Drip Edge)" },
  { type: "valve", id: "v4", name: "Valve OV-1 (Root Soak)" },
  { type: "valve", id: "v5", name: "Valve OV-2 (Micro-Sprays)" },
  { type: "valve", id: "v6", name: "Valve VB-1 (Direct Drip)" },
  { type: "valve", id: "v7", name: "Valve VB-2 (Drip Line 2)" },
  { type: "valve", id: "v8", name: "Valve GH-1 (Herbs Mist)" },
  { type: "valve", id: "v9", name: "Valve GH-2 (Veg Mist)" },
];

const getTimerSequenceTimes = (startTimeStr, sequence) => {
  if (!startTimeStr || !sequence || sequence.length === 0) return [];
  
  let currentHour = 8;
  let currentMinute = 0;
  
  try {
    const isAmPm = startTimeStr.toUpperCase().includes("AM") || startTimeStr.toUpperCase().includes("PM");
    let timePart = startTimeStr.split(" ")[0];
    const parts = timePart.split(":").map(Number);
    currentHour = parts[0];
    currentMinute = parts[1];
    
    if (isAmPm) {
      const isPm = startTimeStr.toUpperCase().includes("PM");
      if (isPm && currentHour < 12) currentHour += 12;
      if (!isPm && currentHour === 12) currentHour = 0;
    }
  } catch (_) {
    currentHour = 8;
    currentMinute = 0;
  }

  const result = [];
  sequence.forEach(item => {
    const startH = currentHour.toString().padStart(2, '0');
    const startM = currentMinute.toString().padStart(2, '0');
    
    const duration = parseInt(item.duration) || 15;
    currentMinute += duration;
    while (currentMinute >= 60) {
      currentHour = (currentHour + 1) % 24;
      currentMinute -= 60;
    }
    
    const endH = currentHour.toString().padStart(2, '0');
    const endM = currentMinute.toString().padStart(2, '0');
    
    result.push({
      ...item,
      startTime: `${startH}:${startM}`,
      endTime: `${endH}:${endM}`
    });
  });
  
  return result;
};

export default function Schedules({ preselectedZone, setPreselectedZone }) {
  const [schedules, setSchedules] = useState([
    { id: 1, name: "Morning Soak", zone: "Front Lawn", time: "06:00 AM", duration: 25, days: ["Mon", "Wed", "Fri"], active: true, scheduleType: "timeBased" },
    { 
      id: 2, 
      name: "Orchard & Lawn Cycle", 
      zone: "Orchard & Vines", 
      time: "08:30 AM", 
      duration: 50, 
      days: ["Tue", "Thu", "Sat"], 
      active: true, 
      scheduleType: "rtcBased",
      sequenceData: [
        {
          zoneId: "z2",
          zoneName: "Orchard & Vines",
          valves: [
            { valveId: "v4", valveName: "Valve OV-1 (Root Soak)", startTime: "08:30", endTime: "08:50" },
            { valveId: "v5", valveName: "Valve OV-2 (Micro-Sprays)", startTime: "08:50", endTime: "09:05" }
          ]
        },
        {
          zoneId: "z1",
          zoneName: "Front Lawn",
          valves: [
            { valveId: "v1", valveName: "Valve FL-1 (Spray)", startTime: "09:05", endTime: "09:20" }
          ]
        }
      ]
    },
    { 
      id: 3, 
      name: "Vegetable Sequence", 
      zone: "Vegetable Beds", 
      time: "05:30 PM", 
      duration: 30, 
      days: ["Daily"], 
      active: true, 
      scheduleType: "timerBased",
      sequenceData: [
        { type: "zone", id: "z3", name: "Vegetable Beds", duration: 15 },
        { type: "valve", id: "v6", name: "Valve VB-1 (Direct Drip)", duration: 15 }
      ]
    }
  ])

  // Form states
  const [name, setName] = useState("")
  const [zone, setZone] = useState("Front Lawn")
  const [time, setTime] = useState("08:00 AM")
  const [duration, setDuration] = useState(15)
  const [days, setDays] = useState("Daily")
  const [scheduleType, setScheduleType] = useState("timeBased") // timeBased, rtcBased, timerBased

  // RTC State: selected zones list, each with its valves: { zoneId, zoneName, valves: [{valveId, valveName, startTime, endTime}] }
  const [rtcZones, setRtcZones] = useState([]);

  // Timer Sequence State
  const [timerSequence, setTimerSequence] = useState([]);

  // Load preselected zone
  useEffect(() => {
    if (preselectedZone) {
      setZone(preselectedZone)
      if (setPreselectedZone) {
        setPreselectedZone("")
      }
    }
  }, [preselectedZone, setPreselectedZone])

  // Helper to load default valves for a zone in RTC
  const getDefaultValvesForZone = (zoneName, startHour = 6, startMinute = 0) => {
    if (!zoneValvesMap[zoneName]) return [];
    let currentHour = startHour;
    let currentMinute = startMinute;

    return zoneValvesMap[zoneName].map(v => {
      const startH = currentHour.toString().padStart(2, '0');
      const startM = currentMinute.toString().padStart(2, '0');
      
      currentMinute += 15;
      if (currentMinute >= 60) {
        currentHour += 1;
        currentMinute -= 60;
      }

      const endH = currentHour.toString().padStart(2, '0');
      const endM = currentMinute.toString().padStart(2, '0');

      return {
        valveId: v.id,
        valveName: v.name,
        startTime: `${startH}:${startM}`,
        endTime: `${endH}:${endM}`,
        checked: true
      };
    });
  };

  // Drag and Drop helpers
  const handleDragStart = (e, index) => {
    e.dataTransfer.setData("text/plain", index);
  };

  const handleDragOver = (e) => {
    e.preventDefault();
  };

  const handleDrop = (e, targetIndex, list, setList) => {
    e.preventDefault();
    const sourceIndex = parseInt(e.dataTransfer.getData("text/plain"), 10);
    if (sourceIndex === targetIndex) return;

    const newList = [...list];
    const [movedItem] = newList.splice(sourceIndex, 1);
    newList.splice(targetIndex, 0, movedItem);
    setList(newList);
  };

  const handleValveDragStart = (e, zoneIdx, valveIdx) => {
    e.stopPropagation();
    e.dataTransfer.setData("application/json", JSON.stringify({ zoneIdx, valveIdx }));
  };

  const handleValveDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleValveDrop = (e, targetZoneIdx, targetValveIdx) => {
    e.preventDefault();
    e.stopPropagation();
    try {
      const dataStr = e.dataTransfer.getData("application/json");
      if (!dataStr) return;
      const { zoneIdx, valveIdx } = JSON.parse(dataStr);
      
      if (zoneIdx !== targetZoneIdx) return;
      if (valveIdx === targetValveIdx) return;

      const updated = [...rtcZones];
      const zoneValves = [...updated[zoneIdx].valves];
      const [movedValve] = zoneValves.splice(valveIdx, 1);
      zoneValves.splice(targetValveIdx, 0, movedValve);
      updated[zoneIdx].valves = zoneValves;
      setRtcZones(updated);
    } catch (err) {
      console.error("Valve drop error:", err);
    }
  };

  // Helper to calculate total minutes from all selected RTC zones/valves
  const calculateRtcTotalDuration = (zonesList) => {
    if (zonesList.length === 0) return 0;
    try {
      let minVal = 24 * 60;
      let maxVal = 0;
      zonesList.forEach(z => {
        z.valves.forEach(v => {
          if (v.checked === false) return;
          const startParts = v.startTime.split(':').map(Number);
          const endParts = v.endTime.split(':').map(Number);
          const startMins = startParts[0] * 60 + startParts[1];
          const endMins = endParts[0] * 60 + endParts[1];
          if (startMins < minVal) minVal = startMins;
          if (endMins > maxVal) maxVal = endMins;
        });
      });
      return maxVal > minVal ? maxVal - minVal : 30;
    } catch (_) {
      return 30;
    }
  };

  const toggleRtcZoneSelection = (zoneId, zoneName) => {
    const exists = rtcZones.some(z => z.zoneId === zoneId);
    if (exists) {
      setRtcZones(rtcZones.filter(z => z.zoneId !== zoneId));
    } else {
      // Find the last valve's end time to cascade start times cleanly
      let lastHour = 6;
      let lastMinute = 0;
      if (rtcZones.length > 0) {
        const lastZoneValves = rtcZones[rtcZones.length - 1].valves;
        if (lastZoneValves.length > 0) {
          const lastTime = lastZoneValves[lastZoneValves.length - 1].endTime;
          const parts = lastTime.split(':').map(Number);
          lastHour = parts[0];
          lastMinute = parts[1];
        }
      }
      const newZone = {
        zoneId,
        zoneName,
        valves: getDefaultValvesForZone(zoneName, lastHour, lastMinute)
      };
      setRtcZones([...rtcZones, newZone]);
    }
  };

  const addSchedule = (e) => {
    e.preventDefault()
    if (!name.trim()) return

    let finalDuration = parseInt(duration) || 15;
    let seqData = null;
    let finalTime = time;
    let primaryZone = zone;

    if (scheduleType === "rtcBased") {
      if (rtcZones.length === 0) return;
      seqData = rtcZones;
      finalDuration = calculateRtcTotalDuration(rtcZones);
      primaryZone = rtcZones[0].zoneName;
      // Format first valve start time into AM/PM
      const firstZone = rtcZones[0];
      const activeValves = firstZone.valves.filter(v => v.checked !== false);
      if (activeValves.length > 0) {
        const rawStart = activeValves[0].startTime;
        const parts = rawStart.split(':').map(Number);
        const ampm = parts[0] >= 12 ? 'PM' : 'AM';
        const h = parts[0] % 12 || 12;
        const m = parts[1].toString().padStart(2, '0');
        finalTime = `${h.toString().padStart(2, '0')}:${m} ${ampm}`;
      }
    } else if (scheduleType === "timerBased") {
      if (timerSequence.length === 0) return;
      seqData = timerSequence;
      finalDuration = timerSequence.reduce((sum, item) => sum + (parseInt(item.duration) || 15), 0);
      primaryZone = timerSequence[0]?.name || zone;
    }

    const newSched = {
      id: Date.now(),
      name,
      zone: primaryZone,
      time: finalTime,
      duration: finalDuration,
      days: days === "Daily" ? ["Daily"] : days.split(",").map(d => d.trim()),
      active: true,
      scheduleType,
      sequenceData: seqData
    }

    setSchedules([...schedules, newSched])
    setName("")
    setTimerSequence([])
    setRtcZones([])
  }

  const deleteSchedule = (id) => {
    setSchedules(schedules.filter(s => s.id !== id))
  }

  const toggleSchedule = (id) => {
    setSchedules(schedules.map(s => s.id === id ? { ...s, active: !s.active } : s))
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-border/60">
        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 shadow-xs">
            <Calendar className="h-6 w-6" />
          </div>
          <div>
            <h2 className="text-xl font-bold tracking-tight text-foreground">Watering Schedules</h2>
            <p className="text-xs text-muted-foreground mt-0.5">Watering rules and sequential automation sequences deployed to the controller.</p>
          </div>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        {/* Schedule List */}
        <div className="md:col-span-2 flex flex-col gap-4">
          <div className="flex flex-col gap-3">
            {schedules.map((s) => (
              <Card key={s.id} className={`shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border relative overflow-hidden transition-all duration-300 hover:shadow-xs hover:border-emerald-500/10 ${
                !s.active ? "opacity-60 bg-muted/20" : ""
              }`}>
                <CardContent className="p-4 flex flex-col gap-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className={`p-2.5 rounded-xl border transition-all ${
                        s.scheduleType === "rtcBased" 
                          ? "bg-purple-500/10 text-purple-600 dark:text-purple-400 border-purple-500/20"
                          : s.scheduleType === "timerBased"
                          ? "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20"
                          : "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20"
                      }`}>
                        <Clock className="h-4.5 w-4.5" />
                      </div>
                      <div>
                        <h3 className="text-xs font-bold text-foreground">{s.name}</h3>
                        <div className="text-[10px] text-muted-foreground mt-0.5 flex flex-wrap gap-x-2 gap-y-0.5">
                          <span className="font-semibold text-emerald-700 dark:text-emerald-400">Zone: {s.zone}</span>
                          <span>•</span>
                          <span>Start: {s.time}</span>
                          <span>•</span>
                          <span>Total: {s.duration} min</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      {/* Type Pill */}
                      <span className={`text-[9px] font-bold px-2 py-0.5 rounded-md uppercase tracking-wider font-mono ${
                        s.scheduleType === "rtcBased"
                          ? "bg-purple-100 dark:bg-purple-950/40 text-purple-700 dark:text-purple-400"
                          : s.scheduleType === "timerBased"
                          ? "bg-amber-100 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400"
                          : "bg-emerald-100 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400"
                      }`}>
                        {s.scheduleType === "rtcBased" ? "RTC SEQ" : s.scheduleType === "timerBased" ? "TIMER SEQ" : "PARALLEL"}
                      </span>

                      {/* Days pill */}
                      <span className="text-[9px] font-bold bg-muted text-muted-foreground px-2 py-0.5 rounded-md uppercase tracking-wider font-mono">
                        {s.days.join(", ")}
                      </span>
                      
                      {/* Toggle Switch */}
                      <button 
                        type="button"
                        onClick={() => toggleSchedule(s.id)}
                        className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out outline-hidden ${
                          s.active ? "bg-emerald-500" : "bg-border"
                        }`}
                      >
                        <span className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow-sm ring-0 transition duration-200 ease-in-out ${
                          s.active ? "translate-x-4" : "translate-x-0"
                        }`} />
                      </button>

                      {/* Delete Button */}
                      <button 
                        type="button"
                        onClick={() => deleteSchedule(s.id)}
                        className="p-1.5 text-muted-foreground hover:text-red-500 rounded-md transition-colors"
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  </div>

                  {/* Render sequence flow for RTC and Timer schedules */}
                  {s.sequenceData && s.sequenceData.length > 0 && (
                    <div className="mt-1 bg-muted/40 dark:bg-muted/10 rounded-lg p-2.5 border border-border/40">
                      <div className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider mb-1.5 flex items-center gap-1">
                        <Activity className="h-3 w-3" />
                        <span>Execution Sequence Flow</span>
                      </div>
                      
                      {s.scheduleType === "rtcBased" ? (
                        <div className="flex flex-col gap-2">
                          {s.sequenceData.map((zItem, zIdx) => (
                            <div key={zIdx} className="flex flex-col gap-1 border-l-2 border-purple-500/30 pl-2">
                              <span className="text-[9px] font-bold text-purple-700 dark:text-purple-400 uppercase tracking-wider">
                                {zItem.zoneName}
                              </span>
                              <div className="flex flex-wrap items-center gap-1.5 text-[10px]">
                                {zItem.valves.filter(v => v.checked !== false).map((v, vIdx) => (
                                  <div key={vIdx} className="bg-background text-foreground border border-border px-2 py-0.5 rounded flex items-center gap-1 font-medium text-[9px]">
                                    <span>{v.valveName}</span>
                                    <span className="bg-purple-500/10 text-purple-600 dark:text-purple-400 px-1 rounded text-[8px] font-bold">
                                      {v.startTime}-{v.endTime}
                                    </span>
                                  </div>
                                ))}
                              </div>
                            </div>
                          ))}
                        </div>
                      ) : (
                        <div className="flex flex-wrap items-center gap-1.5 text-[10px]">
                          {getTimerSequenceTimes(s.time, s.sequenceData).map((item, idx) => (
                            <React.Fragment key={idx}>
                              <div className="bg-background text-foreground border border-border px-2 py-1 rounded-md flex items-center gap-1 shadow-2xs font-medium">
                                <span className="text-muted-foreground font-bold">{idx + 1}.</span>
                                <span>{item.name}</span>
                                <span className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 px-1 rounded text-[9px] font-bold">
                                  {item.startTime}-{item.endTime} ({item.duration}m)
                                </span>
                              </div>
                              {idx < s.sequenceData.length - 1 && (
                                <ArrowRight className="h-3.5 w-3.5 text-muted-foreground" />
                              )}
                            </React.Fragment>
                          ))}
                        </div>
                      )}
                    </div>
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        </div>

        {/* Add Schedule Form */}
        <div>
          <Card className="shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border sticky top-6">
            <CardHeader className="pb-3">
              <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
                <Calendar className="h-4 w-4 text-emerald-500" />
                <span>Create Schedule</span>
              </CardTitle>
              <CardDescription className="text-[10px]">Configure automation rules and zone sequence schedules</CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={addSchedule} className="flex flex-col gap-3.5 text-xs">
                
                {/* Rule Name */}
                <div className="flex flex-col gap-1">
                  <label className="font-semibold text-muted-foreground">Rule Name</label>
                  <input 
                    type="text" 
                    placeholder="e.g. Tomato Drip Sequence" 
                    value={name} 
                    required
                    onChange={(e) => setName(e.target.value)}
                    className="p-2.5 border border-border rounded-lg bg-background text-foreground outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-muted-foreground/60"
                  />
                </div>

                {/* Schedule Type Chips */}
                <div className="flex flex-col gap-1.5">
                  <label className="font-semibold text-muted-foreground">Schedule Configuration</label>
                  <div className="grid grid-cols-3 gap-1 bg-muted/65 p-0.5 rounded-lg text-[9px] font-bold">
                    <button 
                      type="button"
                      onClick={() => setScheduleType("timeBased")}
                      className={`py-1.5 rounded-md transition-all ${
                        scheduleType === "timeBased" 
                          ? "bg-background text-foreground shadow-2xs" 
                          : "text-muted-foreground hover:text-foreground"
                      }`}
                    >
                      Parallel (Time)
                    </button>
                    <button 
                      type="button"
                      onClick={() => setScheduleType("rtcBased")}
                      className={`py-1.5 rounded-md transition-all ${
                        scheduleType === "rtcBased" 
                          ? "bg-background text-foreground shadow-2xs" 
                          : "text-muted-foreground hover:text-foreground"
                      }`}
                    >
                      RTC (Valves)
                    </button>
                    <button 
                      type="button"
                      onClick={() => setScheduleType("timerBased")}
                      className={`py-1.5 rounded-md transition-all ${
                        scheduleType === "timerBased" 
                          ? "bg-background text-foreground shadow-2xs" 
                          : "text-muted-foreground hover:text-foreground"
                      }`}
                    >
                      Timer (Seq)
                    </button>
                  </div>
                </div>

                {/* TARGET ZONE SELECT - Used for timeBased only now */}
                {scheduleType === "timeBased" && (
                  <div className="flex flex-col gap-1">
                    <label className="font-semibold text-muted-foreground">Target Zone</label>
                    <select 
                      value={zone} 
                      onChange={(e) => setZone(e.target.value)}
                      className="p-2.5 border border-border rounded-lg bg-background text-foreground outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all"
                    >
                      <option value="Front Lawn">Front Lawn</option>
                      <option value="Orchard & Vines">Orchard & Vines</option>
                      <option value="Vegetable Beds">Vegetable Beds</option>
                      <option value="Greenhouse Herbs">Greenhouse Herbs</option>
                    </select>
                  </div>
                )}

                {/* RTC MULTI-ZONE SELECT AND TIMINGS FORM */}
                {scheduleType === "rtcBased" && (
                  <div className="flex flex-col gap-3">
                    <div className="flex flex-col gap-1.5">
                      <label className="font-semibold text-muted-foreground">Select Multiple Zones</label>
                      <div className="flex flex-wrap gap-1 bg-muted/30 p-2 rounded-lg border border-border">
                        {Object.keys(zoneValvesMap).map((zName, i) => {
                          const isChecked = rtcZones.some(z => z.zoneName === zName);
                          return (
                            <label key={i} className="flex items-center gap-1.5 bg-background border border-border/80 px-2.5 py-1 rounded-md text-[10px] cursor-pointer hover:border-emerald-500/20 transition-all select-none font-medium">
                              <input 
                                type="checkbox"
                                checked={isChecked}
                                onChange={() => toggleRtcZoneSelection(`z${i + 1}`, zName)}
                                className="accent-emerald-600 rounded"
                              />
                              <span>{zName}</span>
                            </label>
                          );
                        })}
                      </div>
                    </div>

                    {rtcZones.length > 0 ? (
                      <div className="flex flex-col gap-2.5 bg-muted/20 border border-border p-2.5 rounded-lg">
                        <label className="font-bold text-muted-foreground text-[10px] uppercase tracking-wider block mb-1">
                          Zone Sequences (Drag up/down to reorder zones)
                        </label>
                        <div className="flex flex-col gap-3">
                          {rtcZones.map((zItem, zIdx) => (
                            <div 
                              key={zItem.zoneId}
                              draggable
                              onDragStart={(e) => handleDragStart(e, zIdx)}
                              onDragOver={handleDragOver}
                              onDrop={(e) => handleDrop(e, zIdx, rtcZones, setRtcZones)}
                              className="bg-background border border-border rounded-xl p-3 flex flex-col gap-2 cursor-grab active:cursor-grabbing hover:border-purple-500/30 transition-all shadow-2xs select-none"
                            >
                              <div className="flex items-center gap-2 border-b border-border/60 pb-1.5 font-bold text-foreground text-[11px]">
                                <GripVertical className="h-4 w-4 text-muted-foreground/60 shrink-0 cursor-grab" />
                                <Grid className="h-3.5 w-3.5 text-purple-500" />
                                <span className="truncate">{zItem.zoneName}</span>
                              </div>
                              
                              {/* Valves Timing list under zone */}
                              <div className="flex flex-col gap-2 mt-1 select-text cursor-default" onClick={(e) => e.stopPropagation()}>
                                {zItem.valves.map((vItem, vIdx) => {
                                  const isValveChecked = vItem.checked !== false;
                                  return (
                                    <div 
                                      key={vItem.valveId}
                                      draggable
                                      onDragStart={(e) => handleValveDragStart(e, zIdx, vIdx)}
                                      onDragOver={handleValveDragOver}
                                      onDrop={(e) => handleValveDrop(e, zIdx, vIdx)}
                                      className={`bg-muted/25 border rounded-lg p-2.5 flex flex-col gap-1.5 cursor-grab active:cursor-grabbing hover:border-purple-500/20 transition-all select-none ${
                                        !isValveChecked ? "opacity-50 border-dashed border-border" : "border-border/50"
                                      }`}
                                    >
                                      <div className="flex items-center justify-between font-semibold text-foreground text-[10px]">
                                        <div className="flex items-center gap-1.5 min-w-0">
                                          <GripVertical className="h-3.5 w-3.5 text-muted-foreground/60 shrink-0 cursor-grab" />
                                          <input 
                                            type="checkbox" 
                                            checked={isValveChecked}
                                            onChange={(e) => {
                                              const updated = [...rtcZones];
                                              updated[zIdx].valves[vIdx].checked = e.target.checked;
                                              setRtcZones(updated);
                                            }}
                                            className="accent-purple-600 rounded cursor-pointer"
                                          />
                                          <span className="truncate">{vItem.valveName}</span>
                                        </div>
                                      </div>
                                      
                                      {isValveChecked && (
                                        <div className="grid grid-cols-2 gap-1.5 select-text" onClick={(e) => e.stopPropagation()}>
                                          <div>
                                            <span className="text-[7px] text-muted-foreground uppercase font-bold block mb-0.5">Start Time</span>
                                            <input 
                                              type="time" 
                                              value={vItem.startTime} 
                                              onChange={(e) => {
                                                const updated = [...rtcZones];
                                                updated[zIdx].valves[vIdx].startTime = e.target.value;
                                                setRtcZones(updated);
                                              }}
                                              className="w-full p-1 border border-border/80 rounded bg-background text-[9px] font-bold text-foreground outline-hidden focus:border-purple-500"
                                            />
                                          </div>
                                          <div>
                                            <span className="text-[7px] text-muted-foreground uppercase font-bold block mb-0.5">End Time</span>
                                            <input 
                                              type="time" 
                                              value={vItem.endTime} 
                                              onChange={(e) => {
                                                const updated = [...rtcZones];
                                                updated[zIdx].valves[vIdx].endTime = e.target.value;
                                                setRtcZones(updated);
                                              }}
                                              className="w-full p-1 border border-border/80 rounded bg-background text-[9px] font-bold text-foreground outline-hidden focus:border-purple-500"
                                            />
                                          </div>
                                        </div>
                                      )}
                                    </div>
                                  );
                                })}
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    ) : (
                      <div className="text-center py-4 border border-dashed border-border rounded-lg text-muted-foreground text-[10px]">
                        No zones selected. Check the zones above to build your sequence.
                      </div>
                    )}
                  </div>
                )}

                {/* TIMER BASED SEQUENTIAL RUN BUILDER */}
                {scheduleType === "timerBased" && (
                  <div className="flex flex-col gap-2 bg-muted/20 border border-border p-2.5 rounded-lg">
                    <label className="font-bold text-muted-foreground text-[10px] uppercase tracking-wider">
                      Sequence items
                    </label>

                    {/* Add options wrap */}
                    <div className="flex flex-col gap-1.5">
                      <span className="text-[8px] text-muted-foreground uppercase font-bold">Add Zone/Valve to Sequence:</span>
                      <div className="flex flex-wrap gap-1 max-h-24 overflow-y-auto p-1 bg-background border border-border rounded-md">
                        {availableItems.map((item) => (
                          <button
                            key={`${item.type}-${item.id}`}
                            type="button"
                            onClick={() => {
                              setTimerSequence([...timerSequence, {
                                type: item.type,
                                id: item.id,
                                name: item.name,
                                duration: 15
                              }]);
                            }}
                            className={`text-[9px] font-semibold px-2 py-0.5 rounded-full flex items-center gap-1 border hover:-translate-y-0.2 active:translate-y-0 transition-all ${
                              item.type === "zone" 
                                ? "bg-emerald-50 text-emerald-700 border-emerald-500/20 hover:bg-emerald-100" 
                                : "bg-teal-50 text-teal-700 border-teal-500/20 hover:bg-teal-100"
                            }`}
                          >
                            <PlusCircle className="h-2.5 w-2.5" />
                            <span>{item.name}</span>
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Sequence draggable list */}
                    {timerSequence.length > 0 ? (
                      <div className="flex flex-col gap-2 mt-2 border-t border-border/60 pt-2">
                        <span className="text-[8px] text-muted-foreground uppercase font-bold block mb-1">Drag to reorder runtime sequence:</span>
                        {getTimerSequenceTimes(time, timerSequence).map((item, idx) => (
                          <div 
                            key={idx}
                            draggable
                            onDragStart={(e) => handleDragStart(e, idx)}
                            onDragOver={handleDragOver}
                            onDrop={(e) => handleDrop(e, idx, timerSequence, setTimerSequence)}
                            className="bg-background border border-border rounded-lg p-2 flex items-center justify-between gap-1.5 cursor-grab active:cursor-grabbing hover:border-emerald-500/30 transition-all select-none"
                          >
                            <div className="flex items-center gap-1.5 min-w-0">
                              <GripVertical className="h-3.5 w-3.5 text-muted-foreground/60 shrink-0" />
                              <div className="min-w-0">
                                <div className="font-bold text-foreground text-[10px] truncate">{item.name}</div>
                                <div className="flex items-center gap-1 mt-0.5">
                                  <span className={`text-[8px] px-1 py-0.2 rounded-md font-bold uppercase ${
                                    item.type === "zone" ? "bg-emerald-50 text-emerald-700" : "bg-teal-50 text-teal-700"
                                  }`}>
                                    {item.type}
                                  </span>
                                  <span className="text-[8px] bg-purple-50 text-purple-700 dark:bg-purple-950/40 px-1 py-0.2 rounded-md font-bold font-mono">
                                    {item.startTime}-{item.endTime}
                                  </span>
                                </div>
                              </div>
                            </div>
                            
                            <div className="flex items-center gap-1 shrink-0">
                              <input 
                                type="number" 
                                value={item.duration} 
                                onChange={(e) => {
                                  const updated = [...timerSequence];
                                  updated[idx].duration = parseInt(e.target.value) || 10;
                                  setTimerSequence(updated);
                                }}
                                className="w-10 p-0.5 border border-border/80 rounded bg-muted/30 text-[10px] font-bold text-center text-foreground outline-hidden"
                              />
                              <span className="text-[9px] font-bold text-muted-foreground">m</span>
                              <button 
                                type="button" 
                                onClick={() => setTimerSequence(timerSequence.filter((_, i) => i !== idx))}
                                className="p-1 text-muted-foreground hover:text-red-500 rounded"
                              >
                                <Trash2 className="h-3.5 w-3.5" />
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="text-center py-4 border border-dashed border-border rounded-lg text-muted-foreground text-[10px]">
                        No sequence items added. Click chips above to build your sequencing.
                      </div>
                    )}
                  </div>
                )}

                {/* DURATION & START TIME FOR STANDARD / TIMER SCHEDULES */}
                {scheduleType === "timeBased" && (
                  <div className="grid grid-cols-2 gap-2">
                    <div className="flex flex-col gap-1">
                      <label className="font-semibold text-muted-foreground">Start Time</label>
                      <input 
                        type="text" 
                        placeholder="e.g. 08:00 AM" 
                        value={time} 
                        onChange={(e) => setTime(e.target.value)}
                        className="p-2.5 border border-border rounded-lg bg-background text-foreground outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-muted-foreground/60"
                      />
                    </div>
                    <div className="flex flex-col gap-1">
                      <label className="font-semibold text-muted-foreground">Duration (mins)</label>
                      <input 
                        type="number" 
                        value={duration} 
                        onChange={(e) => setDuration(e.target.value)}
                        className="p-2.5 border border-border rounded-lg bg-background text-foreground outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all"
                      />
                    </div>
                  </div>
                )}

                {scheduleType === "timerBased" && (
                  <div className="flex flex-col gap-1">
                    <label className="font-semibold text-muted-foreground">Sequence Start Time</label>
                    <input 
                      type="text" 
                      placeholder="e.g. 06:00 AM" 
                      value={time} 
                      onChange={(e) => setTime(e.target.value)}
                      className="p-2.5 border border-border rounded-lg bg-background text-foreground outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-muted-foreground/60"
                    />
                  </div>
                )}

                {/* Watering Days */}
                <div className="flex flex-col gap-1">
                  <label className="font-semibold text-muted-foreground">Watering Days</label>
                  <input 
                    type="text" 
                    placeholder="Daily, or Mon, Wed, Fri" 
                    value={days} 
                    onChange={(e) => setDays(e.target.value)}
                    className="p-2.5 border border-border rounded-lg bg-background text-foreground outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-muted-foreground/60"
                  />
                </div>

                <button 
                  type="submit" 
                  className="w-full bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white font-bold py-2.5 rounded-lg transition-all flex items-center justify-center gap-1 mt-2 shadow-md shadow-emerald-500/10 hover:-translate-y-0.5 active:translate-y-0"
                >
                  <Plus className="h-4 w-4" />
                  <span>Save Schedule</span>
                </button>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}

import React, { useState } from "react"
import { 
  Droplet, 
  Sprout, 
  Clock, 
  AlertTriangle, 
  Activity, 
  ArrowUpRight, 
  Power,
  LayoutDashboard,
  Users,
  Cpu,
  Plus,
  TrendingUp,
  FileText
} from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

export default function Dashboard({ navigate, db, setDb, setSelectedFarmerId, setSelectedFieldId }) {
  
  // 1. Calculate system metrics
  const farmersCount = db?.farmers?.length || 0
  
  // Calculate active master controllers count
  const onlineMasters = db?.fields?.filter(f => f.masterDevice?.status === "Online").length || 0
  const totalMasters = db?.fields?.filter(f => f.masterDevice).length || 0

  // Calculate active irrigation lines (valves that are Open)
  let activeIrrigationCount = 0
  db?.fields?.forEach(f => {
    f.valves?.forEach(v => {
      if (v.status === "Open") activeIrrigationCount++
    })
  })

  // Calculate average soil moisture across all zones
  let moistureSum = 0
  let moistureCount = 0
  db?.fields?.forEach(f => {
    f.zones?.forEach(z => {
      moistureSum += z.moisture
      moistureCount++
    })
  })
  const avgMoisture = moistureCount > 0 ? (moistureSum / moistureCount).toFixed(1) : "N/A"

  // Quick actions handlers
  const handleQuickAction = (action) => {
    if (action === "add-farmer") {
      navigate("/farmers")
      // We can set a temporary session flag to open the register modal
      sessionStorage.setItem("drip_open_register_modal", "true")
    } else if (action === "add-field") {
      // Direct them to the first active farmer's profile to create a field
      if (db.farmers.length > 0) {
        setSelectedFarmerId(db.farmers[0].id)
        navigate("/farmers")
        sessionStorage.setItem("drip_open_add_field_modal", "true")
      } else {
        navigate("/farmers")
      }
    } else if (action === "start-irrigation") {
      // Navigate to the first online field workspace to trigger irrigation
      const onlineField = db.fields.find(f => f.masterDevice?.status === "Online")
      if (onlineField) {
        setSelectedFarmerId(onlineField.farmerId)
        setSelectedFieldId(onlineField.id)
        localStorage.setItem("drip_workspace_tab", "irrigation")
        navigate("/field-workspace")
      } else if (db.fields.length > 0) {
        setSelectedFarmerId(db.fields[0].farmerId)
        setSelectedFieldId(db.fields[0].id)
        navigate("/field-workspace")
      } else {
        navigate("/farmers")
      }
    } else if (action === "view-alerts") {
      navigate("/support")
    }
  }

  // Get running irrigation lines data
  const runningLines = []
  db?.fields?.forEach(f => {
    f.zones?.forEach(z => {
      const activeValves = (f.valves || []).filter(v => (z.valveIds || []).includes(v.id) && v.status === "Open")
      if (activeValves.length > 0) {
        runningLines.push({
          fieldName: f.name,
          zoneName: z.name,
          valvesCount: activeValves.length,
          flowRate: activeValves.reduce((sum, v) => sum + (v.flowRate || 0), 0).toFixed(1)
        })
      }
    })
  })

  // Get active alerts (open tickets + extremely dry zones < 25%)
  const activeAlerts = []
  const openTickets = db?.tickets?.filter(t => t.status === "Open") || []
  openTickets.forEach(t => {
    const farmer = db?.farmers?.find(f => f.id === t.farmerId)
    activeAlerts.push({
      title: t.title,
      source: farmer ? farmer.name : "System Ticket",
      severity: t.priority === "High" ? "danger" : "warning",
      desc: t.description
    })
  })

  db?.fields?.forEach(f => {
    f.zones?.forEach(z => {
      if (z.moisture < 25) {
        activeAlerts.push({
          title: `Low Hydration Alert: ${z.name}`,
          source: f.name,
          severity: "warning",
          desc: `Current soil moisture is ${z.moisture}%, below threshold (25%).`
        })
      }
    })
  })

  // Recent commands/activity logs
  const recentLogs = db?.logs?.slice(0, 5) || []

  // Metrics Array for rendering cards
  const metrics = [
    {
      title: "Average Moisture",
      value: `${avgMoisture}%`,
      description: "Across all fields & zones",
      icon: Sprout,
      color: "text-emerald-600 dark:text-emerald-400 bg-gradient-to-tr from-emerald-500/10 to-teal-500/10 dark:from-emerald-500/20 dark:to-teal-500/20 border-emerald-500/10 dark:border-emerald-500/20",
    },
    {
      title: "Active Farmers",
      value: farmersCount,
      description: "Onboarded client farmers",
      icon: Users,
      color: "text-teal-600 dark:text-teal-400 bg-gradient-to-tr from-teal-500/10 to-sky-500/10 dark:from-teal-500/20 dark:to-sky-500/20 border-teal-500/10 dark:border-teal-500/20",
    },
    {
      title: "Devices Online",
      value: `${onlineMasters} / ${totalMasters}`,
      description: "Active IoT controllers",
      icon: Cpu,
      color: "text-indigo-600 dark:text-indigo-400 bg-gradient-to-tr from-indigo-500/10 to-violet-500/10 dark:from-indigo-500/20 dark:to-violet-500/20 border-indigo-500/10 dark:border-indigo-500/20",
    },
    {
      title: "Active Watering Lines",
      value: activeIrrigationCount,
      description: "Valves currently open",
      icon: Droplet,
      color: "text-emerald-500 dark:text-emerald-400 bg-gradient-to-tr from-emerald-500/10 to-cyan-500/10 dark:from-emerald-500/20 dark:to-cyan-500/20 border-emerald-500/10 dark:border-emerald-500/20",
    },
  ]

  return (
    <div className="flex flex-col gap-6 font-sans">
      {/* Upper Metrics Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {metrics.map((m) => (
          <Card key={m.title} className="shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border/80 hover:-translate-y-1 hover:shadow-md hover:border-emerald-500/20 transition-all duration-300 group bg-card">
            <CardHeader className="flex flex-row items-center justify-between pb-2 space-y-0">
              <CardTitle className="text-xs font-bold text-muted-foreground group-hover:text-foreground transition-colors uppercase tracking-wider">{m.title}</CardTitle>
              <div className={`p-2 rounded-xl border ${m.color} transition-all duration-300 group-hover:scale-110`}>
                <m.icon className="h-4.5 w-4.5" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-extrabold tracking-tight text-foreground">{m.value}</div>
              <p className="text-[10px] text-muted-foreground mt-1 font-semibold">{m.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Quick Actions Panel */}
      <Card className="shadow-xs border border-border/85 bg-card">
        <CardHeader className="pb-3">
          <CardTitle className="text-sm font-extrabold text-foreground uppercase tracking-wider">Quick Actions</CardTitle>
          <CardDescription className="text-[10px] text-muted-foreground">Standard business operations and hardware commissioning links</CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <button
            onClick={() => handleQuickAction("add-farmer")}
            className="flex items-center gap-2.5 p-3 rounded-xl border border-border/80 hover:border-emerald-500/25 hover:bg-emerald-500/5 text-xs text-foreground font-bold transition-all hover:-translate-y-0.5 cursor-pointer bg-muted/20"
          >
            <div className="h-8 w-8 rounded-lg bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
              <Plus className="h-4.5 w-4.5" />
            </div>
            <span>Add Farmer</span>
          </button>

          <button
            onClick={() => handleQuickAction("add-field")}
            className="flex items-center gap-2.5 p-3 rounded-xl border border-border/80 hover:border-emerald-500/25 hover:bg-emerald-500/5 text-xs text-foreground font-bold transition-all hover:-translate-y-0.5 cursor-pointer bg-muted/20"
          >
            <div className="h-8 w-8 rounded-lg bg-teal-500/10 text-teal-600 flex items-center justify-center">
              <Plus className="h-4.5 w-4.5" />
            </div>
            <span>Add Field</span>
          </button>

          <button
            onClick={() => handleQuickAction("start-irrigation")}
            className="flex items-center gap-2.5 p-3 rounded-xl border border-border/80 hover:border-emerald-500/25 hover:bg-emerald-500/5 text-xs text-foreground font-bold transition-all hover:-translate-y-0.5 cursor-pointer bg-muted/20"
          >
            <div className="h-8 w-8 rounded-lg bg-indigo-500/10 text-indigo-600 flex items-center justify-center">
              <Power className="h-4.5 w-4.5" />
            </div>
            <span>Start Irrigation</span>
          </button>

          <button
            onClick={() => handleQuickAction("view-alerts")}
            className="flex items-center gap-2.5 p-3 rounded-xl border border-border/80 hover:border-emerald-500/25 hover:bg-emerald-500/5 text-xs text-foreground font-bold transition-all hover:-translate-y-0.5 cursor-pointer bg-muted/20"
          >
            <div className="h-8 w-8 rounded-lg bg-amber-500/10 text-amber-600 flex items-center justify-center">
              <AlertTriangle className="h-4.5 w-4.5" />
            </div>
            <span>View Alerts</span>
          </button>
        </CardContent>
      </Card>

      {/* Main Graph & Alert panels */}
      <div className="grid gap-6 md:grid-cols-3">
        {/* SVG Flow Rate Chart */}
        <Card className="md:col-span-2 shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border bg-card">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-sm font-extrabold uppercase tracking-wider text-foreground">Water Usage Timeline</CardTitle>
                <CardDescription className="text-[10px] text-muted-foreground">Aggregated flow rate telemetry over the past 6 hours</CardDescription>
              </div>
              <div className="flex items-center gap-2 text-[10px] bg-emerald-500/5 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 px-2.5 py-1 rounded-full border border-emerald-500/15">
                <span className="relative flex h-1.5 w-1.5">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-1.5 w-1.5 bg-emerald-500"></span>
                </span>
                <span className="font-extrabold text-[8px] uppercase tracking-wider">Live Telemetry</span>
              </div>
            </div>
          </CardHeader>
          <CardContent className="h-[220px] flex items-end">
            <div className="w-full h-full relative flex flex-col justify-between">
              {/* SVG Chart */}
              <div className="absolute inset-0 pt-2 pb-6">
                <svg className="w-full h-full overflow-visible" viewBox="0 0 500 200" preserveAspectRatio="none">
                  <defs>
                    <linearGradient id="chart-fill" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#10b981" stopOpacity="0.25" />
                      <stop offset="100%" stopColor="#10b981" stopOpacity="0.0" />
                    </linearGradient>
                    <linearGradient id="line-gradient" x1="0" y1="0" x2="1" y2="0">
                      <stop offset="0%" stopColor="#10b981" />
                      <stop offset="50%" stopColor="#14b8a6" />
                      <stop offset="100%" stopColor="#0ea5e9" />
                    </linearGradient>
                  </defs>
                  
                  {/* Grid Lines */}
                  <line x1="0" y1="50" x2="500" y2="50" stroke="currentColor" strokeOpacity="0.05" strokeWidth="1" strokeDasharray="4" />
                  <line x1="0" y1="100" x2="500" y2="100" stroke="currentColor" strokeOpacity="0.05" strokeWidth="1" strokeDasharray="4" />
                  <line x1="0" y1="150" x2="500" y2="150" stroke="currentColor" strokeOpacity="0.05" strokeWidth="1" strokeDasharray="4" />

                  {/* Gradient Area */}
                  <path
                    d="M0 200 L0 120 C50 150, 100 80, 150 100 C200 120, 250 40, 300 60 C350 80, 400 160, 450 130 C480 110, 500 140, 500 140 L500 200 Z"
                    fill="url(#chart-fill)"
                  />

                  {/* Flow Line */}
                  <path
                    d="M0 120 C50 150, 100 80, 150 100 C200 120, 250 40, 300 60 C350 80, 400 160, 450 130 C480 110, 500 140, 500 140"
                    fill="none"
                    stroke="url(#line-gradient)"
                    strokeWidth="3"
                    strokeLinecap="round"
                  />
                  
                  {/* Highlight dots */}
                  <circle cx="300" cy="60" r="5" fill="#14b8a6" stroke="white" strokeWidth="2" />
                  <circle cx="450" cy="130" r="5" fill="#0ea5e9" stroke="white" strokeWidth="2" />
                </svg>
              </div>
              {/* X Axis Labels */}
              <div className="flex justify-between w-full text-[8px] text-muted-foreground font-mono mt-auto pt-2 border-t border-border">
                <span>12:00 PM</span>
                <span>01:00 PM</span>
                <span>02:00 PM</span>
                <span>03:00 PM</span>
                <span>04:00 PM</span>
                <span>05:00 PM</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Live Device Status */}
        <Card className="shadow-xs border border-border bg-card">
          <CardHeader>
            <CardTitle className="text-sm font-extrabold uppercase tracking-wider text-foreground flex items-center gap-1.5">
              <Cpu className="h-4.5 w-4.5 text-emerald-500" />
              <span>Live Device Status</span>
            </CardTitle>
            <CardDescription className="text-[10px] text-muted-foreground">Connected hardware heartbeats</CardDescription>
          </CardHeader>
          <CardContent className="flex flex-col gap-3 py-1">
            {db?.fields?.map((f) => (
              <div 
                key={f.id} 
                onClick={() => {
                  setSelectedFarmerId(f.farmerId)
                  setSelectedFieldId(f.id)
                  localStorage.setItem("drip_workspace_tab", "monitoring")
                  navigate("/field-workspace")
                }}
                className="p-2.5 rounded-xl border border-border/80 hover:border-emerald-500/25 transition-all flex items-center justify-between cursor-pointer hover:bg-muted/15"
              >
                <div className="min-w-0">
                  <div className="font-bold text-[11px] text-foreground truncate">{f.name}</div>
                  <div className="text-[8px] text-muted-foreground font-mono font-semibold mt-0.5">{f.masterDevice?.mqttTopic || f.masterDevice?.imei || "MQTT Broker Link"}</div>
                </div>
                <div className="flex items-center gap-1.5 shrink-0">
                  <span className={`h-2 w-2 rounded-full ${f.masterDevice?.status === "Online" ? "bg-green-500 animate-pulse" : "bg-red-400"}`}></span>
                  <span className="text-[9px] font-extrabold text-foreground">{f.masterDevice?.status}</span>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>

      {/* Lower Row: Running Irrigation, Alerts, Command History */}
      <div className="grid gap-6 md:grid-cols-3">
        
        {/* Running Irrigation */}
        <Card className="shadow-xs border border-border bg-card">
          <CardHeader>
            <CardTitle className="text-sm font-extrabold uppercase tracking-wider text-foreground flex items-center gap-1.5">
              <Droplet className="h-4.5 w-4.5 text-emerald-500" />
              <span>Active Irrigation</span>
            </CardTitle>
            <CardDescription className="text-[10px] text-muted-foreground">Watering lines currently active</CardDescription>
          </CardHeader>
          <CardContent className="flex flex-col gap-3">
            {runningLines.length === 0 ? (
              <div className="text-center py-8 text-xs text-muted-foreground italic">
                No active irrigation lines running.
              </div>
            ) : (
              runningLines.map((line, idx) => (
                <div key={idx} className="p-3 rounded-xl border border-blue-500/10 bg-blue-500/5 text-blue-800 dark:text-blue-300 flex items-center justify-between text-xs font-semibold">
                  <div>
                    <div className="font-bold text-foreground text-[11px]">{line.fieldName}</div>
                    <div className="text-[9px] text-muted-foreground font-medium mt-0.5">{line.zoneName} ({line.valvesCount} valves)</div>
                  </div>
                  <div className="text-right">
                    <div className="font-extrabold text-blue-600 dark:text-blue-400 font-mono text-[11px]">{line.flowRate} L/m</div>
                    <div className="text-[8px] text-muted-foreground uppercase font-bold tracking-wider mt-0.5">Flowing</div>
                  </div>
                </div>
              ))
            )}
          </CardContent>
        </Card>

        {/* Active Alerts */}
        <Card className="shadow-xs border border-border bg-card">
          <CardHeader>
            <CardTitle className="text-sm font-extrabold uppercase tracking-wider text-foreground flex items-center gap-1.5">
              <AlertTriangle className="h-4.5 w-4.5 text-amber-500" />
              <span>Active Alerts</span>
            </CardTitle>
            <CardDescription className="text-[10px] text-muted-foreground">Warnings requiring immediate review</CardDescription>
          </CardHeader>
          <CardContent className="flex flex-col gap-3">
            {activeAlerts.length === 0 ? (
              <div className="text-center py-8 text-xs text-muted-foreground italic">
                All systems reporting normal limits.
              </div>
            ) : (
              activeAlerts.map((alert, idx) => (
                <div key={idx} className={`p-3 rounded-xl border flex flex-col gap-0.5 text-xs font-semibold ${
                  alert.severity === "danger" 
                    ? "bg-red-500/5 border-red-500/15 text-red-900 dark:text-red-400" 
                    : "bg-amber-500/5 border-amber-500/15 text-amber-900 dark:text-amber-400"
                }`}>
                  <div className="font-extrabold flex items-center gap-1.5 text-[11px]">
                    <span className={`h-1.5 w-1.5 rounded-full ${alert.severity === "danger" ? "bg-red-500 animate-ping" : "bg-amber-500"}`}></span>
                    {alert.title}
                  </div>
                  <div className="text-[9px] text-muted-foreground font-medium mt-0.5">Source: {alert.source}</div>
                  <div className="text-[9px] text-muted-foreground font-medium mt-0.5 italic">{alert.desc}</div>
                </div>
              ))
            )}
          </CardContent>
        </Card>

        {/* Recent Commands Logs */}
        <Card className="shadow-xs border border-border bg-card">
          <CardHeader>
            <CardTitle className="text-sm font-extrabold uppercase tracking-wider text-foreground flex items-center gap-1.5">
              <FileText className="h-4.5 w-4.5 text-emerald-500" />
              <span>Recent Commands</span>
            </CardTitle>
            <CardDescription className="text-[10px] text-muted-foreground">Admin panel audit trails</CardDescription>
          </CardHeader>
          <CardContent className="flex flex-col gap-3.5">
            {recentLogs.map((log) => (
              <div key={log.id} className="text-xs border-b border-border/40 pb-2 last:border-0 last:pb-0">
                <div className="flex items-center justify-between text-[10px]">
                  <span className="font-bold text-foreground">{log.user}</span>
                  <span className="text-muted-foreground font-semibold font-mono">{log.timestamp.split(" ")[1]}</span>
                </div>
                <div className="font-extrabold text-[10.5px] mt-0.5 text-emerald-700 dark:text-emerald-400">{log.action}</div>
                <div className="text-[9px] text-muted-foreground font-medium mt-0.5">{log.details}</div>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

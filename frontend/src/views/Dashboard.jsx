import React, { useState, useEffect } from "react"
import { 
  Droplet, 
  Sprout, 
  Clock, 
  AlertTriangle, 
  Activity, 
  ArrowUpRight, 
  Power,
  LayoutDashboard,
  Users
} from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
import { initialFields, initialUsers } from "@/lib/mockData"

export default function Dashboard() {
  const [fields, setFields] = useState(() => {
    const saved = localStorage.getItem("drip_fields")
    return saved ? JSON.parse(saved) : initialFields
  })
  const [users, setUsers] = useState(() => {
    const saved = localStorage.getItem("drip_users")
    return saved ? JSON.parse(saved) : initialUsers
  })

  // Poll localStorage every second to get live telemetry updates
  useEffect(() => {
    const interval = setInterval(() => {
      const savedFields = localStorage.getItem("drip_fields")
      if (savedFields) setFields(JSON.parse(savedFields))

      const savedUsers = localStorage.getItem("drip_users")
      if (savedUsers) setUsers(JSON.parse(savedUsers))
    }, 1000)
    return () => clearInterval(interval)
  }, [])

  // Parse farmer filter from URL query params
  const queryParams = new URLSearchParams(window.location.search)
  const farmerIdParam = queryParams.get("farmerId")
  const farmerId = farmerIdParam ? Number(farmerIdParam) : null
  
  const farmer = farmerId ? users.find(u => u.id === farmerId) : null
  const farmerField = farmer ? fields.find(f => f.id === farmer.fieldId) : null

  // Filter fields based on farmer
  const filteredFields = farmerField ? [farmerField] : fields

  // Calculations
  // Average moisture
  let moistureSum = 0
  let moistureCount = 0
  filteredFields.forEach(f => {
    (f.zones || []).forEach(z => {
      if (z.moisture !== undefined) {
        moistureSum += z.moisture
        moistureCount++
      }
    })
  })
  const avgMoisture = moistureCount > 0 ? (moistureSum / moistureCount).toFixed(1) : "0.0"

  // Active Flow Rate
  let totalFlowRate = 0
  filteredFields.forEach(f => {
    (f.zones || []).forEach(z => {
      (z.valves || []).forEach(v => {
        if (v.status === "Open") {
          totalFlowRate += v.flowRate || v.capacity || 0
        }
      })
    })
  })

  // System Status
  const activePumps = filteredFields.filter(f => f.motorStatus === "On").length
  const totalPumps = filteredFields.length

  let systemStatusValue = "Fully Operational"
  let systemStatusDesc = "No leaks detected"

  if (farmerField) {
    systemStatusValue = farmerField.motorStatus === "On" ? "Pump Motor ON" : "Pump Motor OFF"
    systemStatusDesc = farmerField.motorStatus === "On" ? "Flowing water to active lines" : "Pump standby"
  } else {
    systemStatusValue = activePumps > 0 ? `${activePumps} / ${totalPumps} Pumps ON` : "All Pumps OFF"
    systemStatusDesc = activePumps > 0 ? "Irrigation cycles running" : "System in standby mode"
  }

  // Next event details
  let nextEventVal = "05:30 PM"
  let nextEventDesc = "Zone 3 (Vegetables)"
  if (farmerField) {
    const firstZone = farmerField.zones?.[0]
    nextEventVal = "06:00 PM"
    nextEventDesc = firstZone ? `Zone: ${firstZone.name}` : "No configured lines"
  }

  const metrics = [
    {
      title: "Average Moisture",
      value: `${avgMoisture}%`,
      description: farmerField ? `For ${farmerField.name}` : "Across all active zones",
      icon: Sprout,
      color: "text-emerald-600 dark:text-emerald-400 bg-gradient-to-tr from-emerald-500/10 to-teal-500/10 dark:from-emerald-500/20 dark:to-teal-500/20 border-emerald-500/10 dark:border-emerald-500/20",
    },
    {
      title: "Flow Rate",
      value: `${totalFlowRate.toFixed(1)} L/m`,
      description: farmerField ? "Farmer sector consumption" : "Targeting active lines",
      icon: Droplet,
      color: "text-teal-600 dark:text-teal-400 bg-gradient-to-tr from-teal-500/10 to-sky-500/10 dark:from-teal-500/20 dark:to-sky-500/20 border-teal-500/10 dark:border-teal-500/20",
    },
    {
      title: "Next Event",
      value: nextEventVal,
      description: nextEventDesc,
      icon: Clock,
      color: "text-indigo-600 dark:text-indigo-400 bg-gradient-to-tr from-indigo-500/10 to-violet-500/10 dark:from-indigo-500/20 dark:to-violet-500/20 border-indigo-500/10 dark:border-indigo-500/20",
    },
    {
      title: "System Status",
      value: systemStatusValue,
      description: systemStatusDesc,
      icon: Activity,
      color: activePumps > 0 
        ? "text-emerald-500 dark:text-emerald-400 bg-gradient-to-tr from-emerald-500/10 to-cyan-500/10 dark:from-emerald-500/20 dark:to-cyan-500/20 border-emerald-500/10 dark:border-emerald-500/20 animate-pulse"
        : "text-slate-500 dark:text-slate-400 bg-gradient-to-tr from-slate-500/10 to-slate-400/10 dark:from-slate-500/20 dark:to-slate-400/20 border-slate-500/10 dark:border-slate-500/20",
    },
  ]

  // Dynamic Alerts
  const activeAlerts = []
  filteredFields.forEach(f => {
    (f.zones || []).forEach(z => {
      if (z.moisture < 25) {
        activeAlerts.push({
          zone: `${z.name} (${f.name})`,
          type: "Low Moisture Alert",
          value: `Current hydration at ${z.moisture}% (Threshold: 25%)`,
          severity: "warning"
        })
      }
    })
  })

  // Fallback alerts if empty
  if (activeAlerts.length === 0) {
    activeAlerts.push({
      zone: farmerField ? farmerField.name : "System Calibrator",
      type: "All Nodes Clean",
      value: "Moisture parameters within optimal operating range",
      severity: "info"
    })
  }

  // Dynamic SVG Path
  const areaPath = totalFlowRate > 0
    ? "M0 200 L0 120 C50 150, 100 80, 150 100 C200 120, 250 40, 300 60 C350 80, 400 160, 450 130 C480 110, 500 140, 500 140 L500 200 Z"
    : "M0 200 L0 170 Q 125 174, 250 170 T 500 172 L500 200 Z"

  const linePath = totalFlowRate > 0
    ? "M0 120 C50 150, 100 80, 150 100 C200 120, 250 40, 300 60 C350 80, 400 160, 450 130 C480 110, 500 140, 500 140"
    : "M0 170 Q 125 174, 250 170 T 500 172"

  return (
    <div className="flex flex-col gap-6">
      {/* Farmer Dashboard Header Banner */}
      {farmer && (
        <div className="bg-gradient-to-r from-emerald-500/15 via-teal-500/10 to-blue-500/5 dark:from-emerald-950/40 dark:via-teal-950/20 dark:to-blue-950/10 border border-emerald-500/25 p-4 rounded-2xl flex items-center justify-between shadow-xs animate-in slide-in-from-top duration-300">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-500 text-white shadow-md shadow-emerald-500/20">
              <Users className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-foreground">
                Viewing Dashboard: <span className="text-emerald-600 dark:text-emerald-400">{farmer.name}</span>
              </h3>
              <p className="text-[10px] text-muted-foreground font-medium mt-0.5">
                Showing telemetry data filtered for field sector <strong className="text-foreground">{farmerField?.name || "Unassigned"}</strong> ({farmerField?.location || "N/A"}).
              </p>
            </div>
          </div>
          <button
            onClick={() => {
              window.history.pushState({}, "", "/dashboard")
              window.location.reload()
            }}
            className="px-3 py-1.5 rounded-lg border border-emerald-500/20 hover:bg-emerald-500 hover:text-white transition-all text-xs font-bold text-emerald-600 dark:text-emerald-400 cursor-pointer hover:shadow-md"
          >
            Clear Filter
          </button>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-border/60">
        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 shadow-xs">
            <LayoutDashboard className="h-6 w-6" />
          </div>
          <div>
            <h2 className="text-xl font-bold tracking-tight text-foreground">
              {farmer ? `${farmer.name}'s Dashboard Overview` : "Dashboard Overview"}
            </h2>
            <p className="text-xs text-muted-foreground mt-0.5">Real-time soil hydration levels, water usage timeline, and active alerts.</p>
          </div>
        </div>
      </div>
      
      {/* Metrics Row */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {metrics.map((m) => (
          <Card key={m.title} className="shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border/80 hover:-translate-y-1 hover:shadow-md hover:border-emerald-500/20 transition-all duration-300 group">
            <CardHeader className="flex flex-row items-center justify-between pb-2 space-y-0">
              <CardTitle className="text-xs font-semibold text-muted-foreground group-hover:text-foreground transition-colors">{m.title}</CardTitle>
              <div className={`p-2 rounded-xl border ${m.color} transition-all duration-300 group-hover:scale-110`}>
                <m.icon className="h-4.5 w-4.5" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold tracking-tight text-foreground">{m.value}</div>
              <p className="text-[10px] text-muted-foreground mt-1 font-medium">{m.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Main Graph & Alert panels */}
      <div className="grid gap-4 md:grid-cols-3">
        {/* SVG Flow Rate Chart */}
        <Card className="md:col-span-2 shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-sm font-semibold">Water Usage Timeline</CardTitle>
                <CardDescription className="text-[11px]">Real-time flow rate logs over the past 6 hours</CardDescription>
              </div>
              <div className="flex items-center gap-2 text-xs bg-emerald-500/5 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 px-2.5 py-1 rounded-full border border-emerald-500/15">
                <span className="relative flex h-1.5 w-1.5">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-1.5 w-1.5 bg-emerald-500"></span>
                </span>
                <span className="font-semibold text-[9px] uppercase tracking-wider">Live Telemetry</span>
              </div>
            </div>
          </CardHeader>
          <CardContent className="h-[240px] flex items-end">
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
                    d={areaPath}
                    fill="url(#chart-fill)"
                  />

                  {/* Flow Line */}
                  <path
                    d={linePath}
                    fill="none"
                    stroke="url(#line-gradient)"
                    strokeWidth="3"
                    strokeLinecap="round"
                  />
                  
                  {/* Highlight dots */}
                  {totalFlowRate > 0 && (
                    <>
                      <circle cx="300" cy="60" r="5" fill="#14b8a6" stroke="white" strokeWidth="2" />
                      <circle cx="450" cy="130" r="5" fill="#0ea5e9" stroke="white" strokeWidth="2" />
                    </>
                  )}
                </svg>
              </div>
              {/* X Axis Labels */}
              <div className="flex justify-between w-full text-[9px] text-muted-foreground font-mono mt-auto pt-2 border-t border-border">
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

        {/* System Warnings Panel */}
        <Card className="shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border flex flex-col justify-between">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-semibold flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-amber-500" />
              <span>Active Alerts</span>
            </CardTitle>
            <CardDescription className="text-[11px]">System warnings requiring attention</CardDescription>
          </CardHeader>
          <CardContent className="flex-1 flex flex-col gap-3 py-2">
            {activeAlerts.map((alert, idx) => (
              <div key={idx} className={`p-3 rounded-xl border flex flex-col gap-1 text-xs transition-all duration-300 hover:shadow-xs ${
                alert.severity === "warning" 
                  ? "bg-amber-500/5 dark:bg-amber-500/10 border-amber-500/20 text-amber-800 dark:text-amber-300" 
                  : "bg-sky-500/5 dark:bg-sky-500/10 border-sky-500/20 text-sky-800 dark:text-sky-300"
              }`}>
                <div className="font-semibold flex items-center gap-1.5">
                  <span className={`h-2 w-2 rounded-full ${alert.severity === "warning" ? "bg-amber-500" : "bg-sky-500 animate-pulse"}`}></span>
                  {alert.zone}
                </div>
                <div className="text-[10px] text-muted-foreground mt-0.5">{alert.type}: {alert.value}</div>
              </div>
            ))}
          </CardContent>
          <div className="p-4 border-t border-border mt-auto">
            <button className="w-full flex items-center justify-center gap-1 text-[11px] font-bold text-emerald-600 dark:text-emerald-400 hover:text-emerald-700 dark:hover:text-emerald-300 transition-colors">
              <span>View detailed logs</span>
              <ArrowUpRight className="h-3.5 w-3.5" />
            </button>
          </div>
        </Card>
      </div>
    </div>
  )
}

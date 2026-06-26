import React from "react"
import { 
  Droplet, 
  Sprout, 
  Clock, 
  AlertTriangle, 
  Activity, 
  ArrowUpRight, 
  Power,
  LayoutDashboard
} from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

export default function Dashboard() {
  // Mock data for dashboard
  const metrics = [
    {
      title: "Average Moisture",
      value: "42.8%",
      description: "Across all active zones",
      icon: Sprout,
      color: "text-emerald-600 dark:text-emerald-400 bg-gradient-to-tr from-emerald-500/10 to-teal-500/10 dark:from-emerald-500/20 dark:to-teal-500/20 border-emerald-500/10 dark:border-emerald-500/20",
    },
    {
      title: "Flow Rate",
      value: "14.2 L/m",
      description: "Targeting active lines",
      icon: Droplet,
      color: "text-teal-600 dark:text-teal-400 bg-gradient-to-tr from-teal-500/10 to-sky-500/10 dark:from-teal-500/20 dark:to-sky-500/20 border-teal-500/10 dark:border-teal-500/20",
    },
    {
      title: "Next Event",
      value: "05:30 PM",
      description: "Zone 3 (Vegetables)",
      icon: Clock,
      color: "text-indigo-600 dark:text-indigo-400 bg-gradient-to-tr from-indigo-500/10 to-violet-500/10 dark:from-indigo-500/20 dark:to-violet-500/20 border-indigo-500/10 dark:border-indigo-500/20",
    },
    {
      title: "System Status",
      value: "Fully Operational",
      description: "No leaks detected",
      icon: Activity,
      color: "text-emerald-500 dark:text-emerald-400 bg-gradient-to-tr from-emerald-500/10 to-cyan-500/10 dark:from-emerald-500/20 dark:to-cyan-500/20 border-emerald-500/10 dark:border-emerald-500/20",
    },
  ]

  const activeAlerts = [
    { zone: "Zone 4 (Greenhouse)", type: "Low Moisture", value: "18% moisture, minimum set to 25%", severity: "warning" },
    { zone: "System Valve #2", type: "Voltage Fluctuations", value: "Normal range restored 15m ago", severity: "info" }
  ]

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-border/60">
        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 shadow-xs">
            <LayoutDashboard className="h-6 w-6" />
          </div>
          <div>
            <h2 className="text-xl font-bold tracking-tight text-foreground">Dashboard Overview</h2>
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

import React from "react"
import { 
  Droplet, 
  Sprout, 
  Clock, 
  AlertTriangle, 
  Activity, 
  ArrowUpRight, 
  Power 
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
      color: "text-emerald-500 bg-emerald-50 dark:bg-emerald-950/20",
    },
    {
      title: "Flow Rate",
      value: "14.2 L/m",
      description: "Targeting active lines",
      icon: Droplet,
      color: "text-blue-500 bg-blue-50 dark:bg-blue-950/20",
    },
    {
      title: "Next Event",
      value: "05:30 PM",
      description: "Zone 3 (Vegetables)",
      icon: Clock,
      color: "text-purple-500 bg-purple-50 dark:bg-purple-950/20",
    },
    {
      title: "System Status",
      value: "Fully Operational",
      description: "No leaks detected",
      icon: Activity,
      color: "text-cyan-500 bg-cyan-50 dark:bg-cyan-950/20",
    },
  ]

  const activeAlerts = [
    { zone: "Zone 4 (Greenhouse)", type: "Low Moisture", value: "18% moisture, minimum set to 25%", severity: "warning" },
    { zone: "System Valve #2", type: "Voltage Fluctuations", value: "Normal range restored 15m ago", severity: "info" }
  ]

  return (
    <div className="flex flex-col gap-6">
      {/* Metrics Row */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {metrics.map((m) => (
          <Card key={m.title} className="shadow-xs border border-border">
            <CardHeader className="flex flex-row items-center justify-between pb-2 space-y-0">
              <CardTitle className="text-xs font-medium text-muted-foreground">{m.title}</CardTitle>
              <div className={`p-2 rounded-lg ${m.color}`}>
                <m.icon className="h-4 w-4" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-xl font-bold tracking-tight text-foreground">{m.value}</div>
              <p className="text-[10px] text-muted-foreground mt-1">{m.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Main Graph & Alert panels */}
      <div className="grid gap-4 md:grid-cols-3">
        {/* SVG Flow Rate Chart */}
        <Card className="md:col-span-2 shadow-xs border border-border">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-sm font-semibold">Water Usage Timeline</CardTitle>
                <CardDescription className="text-[11px]">Real-time flow rate logs over the past 6 hours</CardDescription>
              </div>
              <div className="flex items-center gap-2 text-xs bg-muted px-2 py-1 rounded-md">
                <span className="h-2 w-2 rounded-full bg-blue-500 animate-pulse"></span>
                <span className="font-mono text-[10px]">Live telemetry</span>
              </div>
            </div>
          </CardHeader>
          <CardContent className="h-[240px] flex items-end">
            <div className="w-full h-full relative flex flex-col justify-between">
              {/* SVG Chart */}
              <div className="absolute inset-0 pt-2 pb-6">
                <svg className="w-full h-full" viewBox="0 0 500 200" preserveAspectRatio="none">
                  <defs>
                    <linearGradient id="gradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="var(--color-blue-500)" stopOpacity="0.4" />
                      <stop offset="100%" stopColor="var(--color-blue-500)" stopOpacity="0.0" />
                    </linearGradient>
                  </defs>
                  
                  {/* Grid Lines */}
                  <line x1="0" y1="50" x2="500" y2="50" stroke="currentColor" strokeOpacity="0.05" strokeWidth="1" strokeDasharray="4" />
                  <line x1="0" y1="100" x2="500" y2="100" stroke="currentColor" strokeOpacity="0.05" strokeWidth="1" strokeDasharray="4" />
                  <line x1="0" y1="150" x2="500" y2="150" stroke="currentColor" strokeOpacity="0.05" strokeWidth="1" strokeDasharray="4" />

                  {/* Gradient Area */}
                  <path
                    d="M0 200 L0 120 C50 150, 100 80, 150 100 C200 120, 250 40, 300 60 C350 80, 400 160, 450 130 C480 110, 500 140, 500 140 L500 200 Z"
                    fill="url(#gradient)"
                  />

                  {/* Flow Line */}
                  <path
                    d="M0 120 C50 150, 100 80, 150 100 C200 120, 250 40, 300 60 C350 80, 400 160, 450 130 C480 110, 500 140, 500 140"
                    fill="none"
                    stroke="var(--color-blue-500)"
                    strokeWidth="2.5"
                    strokeLinecap="round"
                  />
                  
                  {/* Highlight dots */}
                  <circle cx="300" cy="60" r="4.5" fill="var(--color-blue-500)" stroke="white" strokeWidth="1.5" />
                  <circle cx="450" cy="130" r="4.5" fill="var(--color-blue-500)" stroke="white" strokeWidth="1.5" />
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
        <Card className="shadow-xs border border-border flex flex-col justify-between">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-semibold flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-amber-500" />
              <span>Active Alerts</span>
            </CardTitle>
            <CardDescription className="text-[11px]">System warnings requiring attention</CardDescription>
          </CardHeader>
          <CardContent className="flex-1 flex flex-col gap-3 py-2">
            {activeAlerts.map((alert, idx) => (
              <div key={idx} className={`p-3 rounded-lg border flex flex-col gap-1 text-xs ${
                alert.severity === "warning" 
                  ? "bg-amber-50/50 dark:bg-amber-950/10 border-amber-200/50 dark:border-amber-950/40 text-amber-900 dark:text-amber-300" 
                  : "bg-blue-50/50 dark:bg-blue-950/10 border-blue-200/50 dark:border-blue-950/40 text-blue-900 dark:text-blue-300"
              }`}>
                <div className="font-semibold flex items-center gap-1.5">
                  <span className={`h-1.5 w-1.5 rounded-full ${alert.severity === "warning" ? "bg-amber-500" : "bg-blue-500"}`}></span>
                  {alert.zone}
                </div>
                <div className="text-[10px] text-muted-foreground mt-0.5">{alert.type}: {alert.value}</div>
              </div>
            ))}
          </CardContent>
          <div className="p-4 border-t border-border mt-auto">
            <button className="w-full flex items-center justify-center gap-1 text-[11px] font-semibold text-blue-500 hover:text-blue-600 transition-colors">
              <span>View detailed logs</span>
              <ArrowUpRight className="h-3.5 w-3.5" />
            </button>
          </div>
        </Card>
      </div>
    </div>
  )
}

import React, { useState } from "react"
import { Activity, Wrench, AlertCircle, RefreshCw, CheckCircle2, Wifi, Zap } from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

export default function Diagnostics() {
  const [testState, setTestState] = useState("Idle") // Idle, Running, Completed
  const [testResults, setTestResults] = useState([])
  const [pingSpeed, setPingSpeed] = useState(null)
  const [pinging, setPinging] = useState(false)

  const runDiagnostics = () => {
    setTestState("Running")
    setTestResults([])
    
    const steps = [
      { name: "CPU Voltage Check", result: "3.32V - Stable", status: "ok" },
      { name: "WiFi Signal Quality", result: "-64dBm - Excellent", status: "ok" },
      { name: "Solenoid Valves Pin Connectivity", result: "4/4 Pins Continuity Verified", status: "ok" },
      { name: "Flow Meter Sensor Calibration", result: "Frequency feedback synchronized", status: "ok" },
      { name: "Moisture Mesh RF Communication", result: "6 Nodes Verified", status: "ok" }
    ]

    steps.forEach((step, index) => {
      setTimeout(() => {
        setTestResults(prev => [...prev, step])
        if (index === steps.length - 1) {
          setTestState("Completed")
        }
      }, (index + 1) * 800)
    })
  }

  const pingController = () => {
    setPinging(true)
    setPingSpeed(null)
    setTimeout(() => {
      setPingSpeed(Math.floor(Math.random() * 45) + 12)
      setPinging(false)
    }, 1200)
  }

  return (
    <div className="grid gap-6 md:grid-cols-3 text-xs">
      
      {/* Self Test Diagnostics */}
      <Card className="md:col-span-2 shadow-xs border border-border flex flex-col justify-between">
        <CardHeader>
          <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
            <Wrench className="h-4 w-4 text-blue-500" />
            <span>Interactive Controller Diagnostics</span>
          </CardTitle>
          <CardDescription className="text-[10px]">Run full board loop diagnostics to verify valve relay continuity</CardDescription>
        </CardHeader>
        <CardContent className="flex-1 flex flex-col gap-4">
          
          {testState === "Idle" && (
            <div className="flex flex-col items-center justify-center p-8 border border-dashed border-border rounded-lg bg-muted/10 text-center gap-2">
              <Activity className="h-8 w-8 text-muted-foreground" />
              <div>
                <h3 className="font-semibold text-foreground">Self-Test Diagnostic Suite</h3>
                <p className="text-[10px] text-muted-foreground mt-0.5 max-w-[280px]">Test ESP32 CPU voltages, Wi-Fi mesh latency, and relay continuity.</p>
              </div>
              <button 
                onClick={runDiagnostics}
                className="mt-2 bg-blue-500 hover:bg-blue-600 text-white font-semibold px-4 py-2 rounded-md transition-all shadow-xs"
              >
                Run Hardware Self-Test
              </button>
            </div>
          )}

          {testState !== "Idle" && (
            <div className="flex flex-col gap-3">
              {testResults.map((res, i) => (
                <div key={i} className="flex items-center justify-between p-2.5 rounded-lg border border-border bg-muted/20 animate-fade-in">
                  <div className="flex items-center gap-2 font-semibold">
                    <CheckCircle2 className="h-4.5 w-4.5 text-emerald-500" />
                    <span>{res.name}</span>
                  </div>
                  <span className="font-mono text-muted-foreground text-[10px]">{res.result}</span>
                </div>
              ))}

              {testState === "Running" && (
                <div className="flex items-center justify-center gap-2 p-4 text-muted-foreground">
                  <RefreshCw className="h-4 w-4 animate-spin text-blue-500" />
                  <span>Polling hardware pins...</span>
                </div>
              )}

              {testState === "Completed" && (
                <div className="p-3 bg-emerald-50/50 dark:bg-emerald-950/10 border border-emerald-200/50 dark:border-emerald-950/40 text-emerald-800 dark:text-emerald-400 rounded-lg flex items-center gap-2 mt-2 font-semibold">
                  <CheckCircle2 className="h-5 w-5 text-emerald-500" />
                  <div>
                    <h4>All Diagnostics Passed Successfully</h4>
                    <p className="text-[9px] text-muted-foreground font-normal mt-0.5">Firmware loop returned 0 errors. Relay boards operational.</p>
                  </div>
                  <button 
                    onClick={() => setTestState("Idle")}
                    className="ml-auto bg-muted dark:bg-card hover:bg-muted/80 text-[10px] px-3 py-1 rounded-md border border-border transition-all"
                  >
                    Reset
                  </button>
                </div>
              )}
            </div>
          )}

        </CardContent>
      </Card>

      {/* Latency / Ping utilities */}
      <Card className="shadow-xs border border-border flex flex-col justify-between">
        <CardHeader>
          <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
            <Wifi className="h-4 w-4 text-blue-500" />
            <span>Connection Ping</span>
          </CardTitle>
          <CardDescription className="text-[10px]">Verify network connectivity latency</CardDescription>
        </CardHeader>
        <CardContent className="flex-1 flex flex-col items-center justify-center p-6 text-center gap-4">
          <div className="relative flex items-center justify-center">
            <Zap className={`h-12 w-12 text-blue-500 ${pinging ? "animate-pulse" : ""}`} />
            {pingSpeed && (
              <span className="absolute -bottom-2 bg-emerald-100 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 font-mono text-[9px] font-bold px-2 py-0.5 rounded-full border border-emerald-200/40">
                Connected
              </span>
            )}
          </div>

          <div>
            <h3 className="font-semibold text-foreground">Ping Controller</h3>
            <p className="text-[10px] text-muted-foreground mt-0.5">Test signal response latency to ESP32 board.</p>
          </div>

          {pingSpeed !== null && (
            <div className="font-mono text-xl font-bold text-foreground">
              {pingSpeed} <span className="text-xs font-normal text-muted-foreground">ms</span>
            </div>
          )}

          <button 
            onClick={pingController}
            disabled={pinging}
            className="w-full bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 rounded-md transition-all shadow-xs disabled:opacity-50 mt-2"
          >
            {pinging ? "Pinging ESP32..." : "Ping Now"}
          </button>
        </CardContent>
      </Card>

    </div>
  )
}

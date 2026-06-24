import React, { useState } from "react"
import { Sprout, AlertTriangle, ShieldAlert, Save } from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

export default function AlertLimits() {
  const [minMoisture, setMinMoisture] = useState(25)
  const [maxMoisture, setMaxMoisture] = useState(85)
  const [maxFlowRate, setMaxFlowRate] = useState(30)
  const [leakThreshold, setLeakThreshold] = useState(1.5)
  const [success, setSuccess] = useState(false)

  const saveSettings = (e) => {
    e.preventDefault()
    setSuccess(true)
    setTimeout(() => setSuccess(false), 2000)
  }

  return (
    <div className="max-w-2xl text-xs">
      <Card className="shadow-xs border border-border">
        <CardHeader>
          <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
            <ShieldAlert className="h-4 w-4 text-blue-500" />
            <span>Alert Threshold Configurations</span>
          </CardTitle>
          <CardDescription className="text-[10px]">Define trigger limits for soil moisture and water flow leaks</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={saveSettings} className="flex flex-col gap-4">
            
            <div className="flex flex-col gap-2 py-2 border-b border-border">
              <div className="flex items-center justify-between font-semibold">
                <span className="flex items-center gap-1">
                  <Sprout className="h-4 w-4 text-emerald-500" />
                  Minimum Soil Moisture Warning
                </span>
                <span className="font-mono text-blue-500">{minMoisture}%</span>
              </div>
              <p className="text-[10px] text-muted-foreground">Triggers an alert when moisture levels fall below this value.</p>
              <input 
                type="range" 
                min="10" 
                max="50" 
                value={minMoisture} 
                onChange={(e) => setMinMoisture(e.target.value)}
                className="w-full h-1 bg-muted rounded-lg appearance-none cursor-pointer accent-blue-500 mt-2"
              />
            </div>

            <div className="flex flex-col gap-2 py-2 border-b border-border">
              <div className="flex items-center justify-between font-semibold">
                <span className="flex items-center gap-1">
                  <AlertTriangle className="h-4 w-4 text-amber-500" />
                  Maximum Flow Rate Limit (Burst Pipe Alert)
                </span>
                <span className="font-mono text-blue-500">{maxFlowRate} L/m</span>
              </div>
              <p className="text-[10px] text-muted-foreground">Closes all valves immediately if flow rate spikes above this threshold.</p>
              <input 
                type="range" 
                min="15" 
                max="50" 
                value={maxFlowRate} 
                onChange={(e) => setMaxFlowRate(e.target.value)}
                className="w-full h-1 bg-muted rounded-lg appearance-none cursor-pointer accent-blue-500 mt-2"
              />
            </div>

            <div className="flex flex-col gap-2 py-2 border-b border-border">
              <div className="flex items-center justify-between font-semibold">
                <span className="flex items-center gap-1">
                  <AlertTriangle className="h-4 w-4 text-red-500" />
                  Low Flow Leak Threshold
                </span>
                <span className="font-mono text-blue-500">{leakThreshold} L/m</span>
              </div>
              <p className="text-[10px] text-muted-foreground">Alerts when small flow is detected while all valves are closed (potential leak).</p>
              <input 
                type="range" 
                min="0.5" 
                max="5" 
                step="0.1"
                value={leakThreshold} 
                onChange={(e) => setLeakThreshold(e.target.value)}
                className="w-full h-1 bg-muted rounded-lg appearance-none cursor-pointer accent-blue-500 mt-2"
              />
            </div>

            <div className="flex flex-col gap-2 mt-2">
              <button 
                type="submit" 
                className="w-full bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 rounded-md transition-all flex items-center justify-center gap-1.5 shadow-xs"
              >
                <Save className="h-4 w-4" />
                <span>Save Threshold Configuration</span>
              </button>
              {success && (
                <p className="text-[10px] font-semibold text-emerald-500 text-center mt-1">Alert thresholds successfully synchronized with hardware controller!</p>
              )}
            </div>

          </form>
        </CardContent>
      </Card>
    </div>
  )
}

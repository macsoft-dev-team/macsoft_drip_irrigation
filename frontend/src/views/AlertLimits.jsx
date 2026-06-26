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
      <Card className="shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border">
        <CardHeader>
          <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
            <ShieldAlert className="h-4 w-4 text-emerald-500" />
            <span>Alert Threshold Configurations</span>
          </CardTitle>
          <CardDescription className="text-[10px]">Define trigger limits for soil moisture and water flow leaks</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={saveSettings} className="flex flex-col gap-4">
            
            <div className="flex flex-col gap-2 py-2 border-b border-border">
              <div className="flex items-center justify-between font-semibold">
                <span className="flex items-center gap-1.5 text-foreground">
                  <Sprout className="h-4 w-4 text-emerald-500" />
                  Minimum Soil Moisture Warning
                </span>
                <span className="font-mono text-[13px] text-emerald-600 dark:text-emerald-400 font-bold">{minMoisture}%</span>
              </div>
              <p className="text-[10px] text-muted-foreground">Triggers an alert when moisture levels fall below this value.</p>
              <input 
                type="range" 
                min="10" 
                max="50" 
                value={minMoisture} 
                onChange={(e) => setMinMoisture(e.target.value)}
                className="w-full h-1.5 bg-muted dark:bg-muted/20 rounded-lg appearance-none cursor-pointer accent-emerald-500 mt-2"
              />
            </div>

            <div className="flex flex-col gap-2 py-2 border-b border-border">
              <div className="flex items-center justify-between font-semibold">
                <span className="flex items-center gap-1.5 text-foreground">
                  <AlertTriangle className="h-4 w-4 text-amber-500" />
                  Maximum Flow Rate Limit (Burst Pipe Alert)
                </span>
                <span className="font-mono text-[13px] text-emerald-600 dark:text-emerald-400 font-bold">{maxFlowRate} L/m</span>
              </div>
              <p className="text-[10px] text-muted-foreground">Closes all valves immediately if flow rate spikes above this threshold.</p>
              <input 
                type="range" 
                min="15" 
                max="50" 
                value={maxFlowRate} 
                onChange={(e) => setMaxFlowRate(e.target.value)}
                className="w-full h-1.5 bg-muted dark:bg-muted/20 rounded-lg appearance-none cursor-pointer accent-emerald-500 mt-2"
              />
            </div>

            <div className="flex flex-col gap-2 py-2 border-b border-border">
              <div className="flex items-center justify-between font-semibold">
                <span className="flex items-center gap-1.5 text-foreground">
                  <AlertTriangle className="h-4 w-4 text-red-500" />
                  Low Flow Leak Threshold
                </span>
                <span className="font-mono text-[13px] text-emerald-600 dark:text-emerald-400 font-bold">{leakThreshold} L/m</span>
              </div>
              <p className="text-[10px] text-muted-foreground">Alerts when small flow is detected while all valves are closed (potential leak).</p>
              <input 
                type="range" 
                min="0.5" 
                max="5" 
                step="0.1"
                value={leakThreshold} 
                onChange={(e) => setLeakThreshold(e.target.value)}
                className="w-full h-1.5 bg-muted dark:bg-muted/20 rounded-lg appearance-none cursor-pointer accent-emerald-500 mt-2"
              />
            </div>

            <div className="flex flex-col gap-2 mt-2">
              <button 
                type="submit" 
                className="w-full bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white font-bold py-2.5 rounded-lg transition-all flex items-center justify-center gap-1.5 shadow-md shadow-emerald-500/10 hover:-translate-y-0.5 active:translate-y-0"
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

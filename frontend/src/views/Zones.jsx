import React, { useState, useEffect } from "react"
import { Play, Square, Droplet, Sprout, AlertCircle, ThermometerSun, Plus } from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

export default function Zones({ navigate, setPreselectedZone }) {
  // Zone states
  const [zones, setZones] = useState([
    { id: 1, name: "Front Lawn", location: "Sector A-1", status: "Idle", moisture: 45, flowRate: 0, durationLeft: 0 },
    { id: 2, name: "Orchard & Vines", location: "Sector B-3", status: "Idle", moisture: 38, flowRate: 0, durationLeft: 0 },
    { id: 3, name: "Vegetable Beds", location: "Sector C-2", status: "Watering", moisture: 48, flowRate: 8.5, durationLeft: 240 },
    { id: 4, name: "Greenhouse Herbs", location: "Greenhouse-1", status: "Idle", moisture: 21, flowRate: 0, durationLeft: 0 }
  ])

  // Simulation of countdown timer for active watering zones
  useEffect(() => {
    const timer = setInterval(() => {
      setZones(prevZones => 
        prevZones.map(zone => {
          if (zone.status === "Watering") {
            const nextDuration = zone.durationLeft - 1
            if (nextDuration <= 0) {
              return { ...zone, status: "Idle", durationLeft: 0, flowRate: 0, moisture: Math.min(zone.moisture + 5, 80) }
            }
            return { 
              ...zone, 
              durationLeft: nextDuration,
              moisture: Math.min(zone.moisture + 0.05, 90) // Moisture increases slowly during watering
            }
          }
          return zone
        })
      )
    }, 1000)

    return () => clearInterval(timer)
  }, [])

  const toggleWatering = (id) => {
    setZones(prevZones => 
      prevZones.map(zone => {
        if (zone.id === id) {
          if (zone.status === "Watering") {
            // Stop watering
            return { ...zone, status: "Idle", durationLeft: 0, flowRate: 0 }
          } else {
            // Start watering for 5 minutes (300 seconds)
            return { ...zone, status: "Watering", durationLeft: 300, flowRate: 12.0 }
          }
        }
        return zone
      })
    )
  }

  // Format countdown duration
  const formatTime = (secs) => {
    const m = Math.floor(secs / 60)
    const s = secs % 60
    return `${m}:${s < 10 ? '0' : ''}${s}`
  }

    return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-border/60">
        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 shadow-xs">
            <Droplet className="h-6 w-6" />
          </div>
          <div>
            <h2 className="text-xl font-bold tracking-tight text-foreground">Zone Valves Control</h2>
            <p className="text-xs text-muted-foreground mt-0.5">Monitor soil moisture levels and manually actuate irrigation valve relays.</p>
          </div>
        </div>
      </div>
  
        <div className="grid gap-4 md:grid-cols-2">
          {zones.map((zone) => {
            const isWatering = zone.status === "Watering"
            const isLowMoisture = zone.moisture < 25
            
            // Soil moisture visual levels
            const progressColor = zone.moisture > 70 
              ? "bg-blue-500 shadow-sm shadow-blue-500/25" 
              : zone.moisture >= 25 
              ? "bg-emerald-500 shadow-sm shadow-emerald-500/25" 
              : "bg-amber-500 shadow-sm shadow-amber-500/25 animate-pulse"
  
            return (
              <Card key={zone.id} className={`shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-transparent relative overflow-hidden transition-all duration-300 ${
                isWatering 
                  ? "ring-2 ring-emerald-500/30 border-emerald-500/20 shadow-md shadow-emerald-500/5 hover:scale-[1.01]" 
                  : "hover:-translate-y-0.5 hover:shadow-md hover:border-gray-300"
              }`}>
                {/* Dynamic watering background pulse */}
                {isWatering && (
                  <div className="absolute inset-0 bg-emerald-500/5 dark:bg-emerald-500/2 pointer-events-none animate-pulse"></div>
                )}
  
                <CardHeader className="pb-3 z-10 relative">
                  <div className="flex items-start justify-between">
                    <div>
                      <span className="text-[9px] font-bold text-emerald-600 dark:text-emerald-400 uppercase tracking-widest bg-emerald-500/5 dark:bg-emerald-500/10 px-2 py-0.5 rounded-md">{zone.location}</span>
                      <CardTitle className="text-sm font-semibold mt-1.5">{zone.name}</CardTitle>
                    </div>
                    <div className={`text-[10px] px-2 py-0.5 rounded-full font-semibold flex items-center gap-1.5 border ${
                      isWatering 
                        ? "bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border-emerald-500/20" 
                        : isLowMoisture 
                        ? "bg-amber-100 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 border-amber-500/20 animate-pulse"
                        : "bg-muted text-muted-foreground border-border/20"
                    }`}>
                      {isWatering && <Droplet className="h-3 w-3 animate-bounce text-emerald-500" />}
                      {isLowMoisture && !isWatering && <AlertCircle className="h-3 w-3" />}
                      <span>{isWatering ? "Watering" : isLowMoisture ? "Dry" : "Idle"}</span>
                    </div>
                  </div>
                </CardHeader>
                
                <CardContent className="flex flex-col gap-4 z-10 relative">
                  {/* Stats layout */}
                  <div className="grid grid-cols-3 gap-2 border-y border-border py-3 text-xs bg-muted/20 rounded-xl px-2.5">
                    <div className="flex flex-col gap-0.5">
                      <span className="text-[10px] text-muted-foreground font-semibold">Moisture</span>
                      <span className="font-bold text-foreground flex items-center gap-1">
                        <Sprout className="h-3.5 w-3.5 text-emerald-500" />
                        {zone.moisture.toFixed(1)}%
                      </span>
                    </div>
                    <div className="flex flex-col gap-0.5 border-x border-border/80 px-2.5">
                      <span className="text-[10px] text-muted-foreground font-semibold">Flow Rate</span>
                      <span className="font-bold text-foreground flex items-center gap-1">
                        <Droplet className="h-3.5 w-3.5 text-teal-500" />
                        {zone.flowRate.toFixed(1)} L/m
                      </span>
                    </div>
                    <div className="flex flex-col gap-0.5 pl-1">
                      <span className="text-[10px] text-muted-foreground font-semibold">Time Left</span>
                      <span className="font-mono font-bold text-foreground flex items-center gap-1">
                        <ThermometerSun className="h-3.5 w-3.5 text-amber-500" />
                        {isWatering ? formatTime(zone.durationLeft) : "--:--"}
                      </span>
                    </div>
                  </div>
  
                  {/* Moisture Progress Gauge */}
                  <div className="flex flex-col gap-1.5 bg-muted/5 p-2 rounded-xl border border-border/30">
                    <div className="flex justify-between text-[9px] text-muted-foreground font-bold uppercase tracking-wider">
                      <span>Soil Hydration Gauge</span>
                      <span className="font-mono text-[10px] text-foreground">{zone.moisture.toFixed(0)}%</span>
                    </div>
                    <div className="w-full h-2 bg-muted dark:bg-muted/20 rounded-full overflow-hidden border border-border/10">
                      <div 
                        className={`h-full rounded-full transition-all duration-500 ${progressColor}`}
                        style={{ width: `${Math.min(zone.moisture, 100)}%` }}
                      ></div>
                    </div>
                  </div>
  
                  {/* Valve action button grid */}
                  <div className="grid grid-cols-2 gap-2 mt-1">
                    <button 
                      onClick={() => toggleWatering(zone.id)}
                      className={`py-2 rounded-lg font-bold text-xs flex items-center justify-center gap-1.5 border transition-all hover:-translate-y-0.5 active:translate-y-0 ${
                        isWatering 
                          ? "bg-red-500/10 hover:bg-red-500/15 text-red-600 dark:text-red-400 border-red-500/20 shadow-xs" 
                          : "bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white border-transparent shadow-md shadow-emerald-500/10"
                      }`}
                    >
                      {isWatering ? (
                        <>
                          <Square className="h-3.5 w-3.5 fill-current" />
                          <span>Stop Valve</span>
                        </>
                      ) : (
                        <>
                          <Play className="h-3.5 w-3.5 fill-current" />
                          <span>Water Zone</span>
                        </>
                      )}
                    </button>
  
                    <button 
                      onClick={() => {
                        if (setPreselectedZone) {
                          setPreselectedZone(zone.name)
                        }
                        if (navigate) {
                          navigate("/schedules")
                        }
                      }}
                      className="py-2 rounded-lg font-bold text-xs flex items-center justify-center gap-1.5 border border-transparent bg-card hover:bg-muted/50 hover:border-gray-300 text-foreground transition-all hover:-translate-y-0.5 active:translate-y-0"
                    >
                      <Plus className="h-3.5 w-3.5" />
                      <span>Schedule</span>
                    </button>
                  </div>
                </CardContent>
              </Card>
            )
          })}
        </div>
      </div>
    )
}

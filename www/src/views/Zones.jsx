import React, { useState, useEffect } from "react"
import { Play, Square, Droplet, Sprout, AlertCircle, ThermometerSun } from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

export default function Zones() {
  // Zone states
  const [zones, setZones] = useState([
    { id: 1, name: "Front Lawn & Turf", location: "Sector A-1", status: "Idle", moisture: 45, flowRate: 0, durationLeft: 0 },
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
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-sm font-semibold tracking-tight">Zone Valves Control</h2>
          <p className="text-[11px] text-muted-foreground">Monitor soil moisture sensors and manually trigger specific valves</p>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        {zones.map((zone) => {
          const isWatering = zone.status === "Watering"
          const isLowMoisture = zone.moisture < 25
          
          return (
            <Card key={zone.id} className={`shadow-xs border border-border relative overflow-hidden transition-all duration-300 ${
              isWatering ? "ring-1 ring-blue-500/50 border-blue-200/50 dark:border-blue-950/50" : ""
            }`}>
              {/* Dynamic watering background pulse */}
              {isWatering && (
                <div className="absolute inset-0 bg-blue-50/10 dark:bg-blue-950/5 pointer-events-none animate-pulse"></div>
              )}

              <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                  <div>
                    <span className="text-[9px] font-semibold text-muted-foreground uppercase tracking-widest">{zone.location}</span>
                    <CardTitle className="text-sm font-semibold mt-0.5">{zone.name}</CardTitle>
                  </div>
                  <div className={`text-[10px] px-2 py-0.5 rounded-full font-semibold flex items-center gap-1.5 ${
                    isWatering 
                      ? "bg-blue-100 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400" 
                      : isLowMoisture 
                      ? "bg-amber-100 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 animate-pulse"
                      : "bg-muted text-muted-foreground"
                  }`}>
                    {isWatering && <Droplet className="h-3 w-3 animate-bounce" />}
                    {isLowMoisture && !isWatering && <AlertCircle className="h-3 w-3" />}
                    <span>{isWatering ? "Active" : isLowMoisture ? "Dry" : "Idle"}</span>
                  </div>
                </div>
              </CardHeader>
              
              <CardContent className="flex flex-col gap-4">
                {/* Stats layout */}
                <div className="grid grid-cols-3 gap-2 border-y border-border py-3 text-xs bg-muted/20 rounded-md px-2">
                  <div className="flex flex-col gap-0.5">
                    <span className="text-[10px] text-muted-foreground">Moisture</span>
                    <span className="font-semibold text-foreground flex items-center gap-1">
                      <Sprout className="h-3.5 w-3.5 text-emerald-500" />
                      {zone.moisture.toFixed(1)}%
                    </span>
                  </div>
                  <div className="flex flex-col gap-0.5 border-x border-border/80 px-2">
                    <span className="text-[10px] text-muted-foreground">Flow Rate</span>
                    <span className="font-semibold text-foreground flex items-center gap-1">
                      <Droplet className="h-3.5 w-3.5 text-blue-500" />
                      {zone.flowRate.toFixed(1)} L/m
                    </span>
                  </div>
                  <div className="flex flex-col gap-0.5 pl-1">
                    <span className="text-[10px] text-muted-foreground">Time Left</span>
                    <span className="font-mono font-semibold text-foreground flex items-center gap-1">
                      <ThermometerSun className="h-3.5 w-3.5 text-amber-500" />
                      {isWatering ? formatTime(zone.durationLeft) : "--:--"}
                    </span>
                  </div>
                </div>

                {/* Valve action button */}
                <button 
                  onClick={() => toggleWatering(zone.id)}
                  className={`w-full py-2 rounded-md font-semibold text-xs flex items-center justify-center gap-2 border transition-all ${
                    isWatering 
                      ? "bg-red-50 hover:bg-red-100 dark:bg-red-950/20 dark:hover:bg-red-950/30 text-red-600 dark:text-red-400 border-red-200/60 dark:border-red-950/50" 
                      : "bg-blue-500 hover:bg-blue-600 text-white border-transparent shadow-xs"
                  }`}
                >
                  {isWatering ? (
                    <>
                      <Square className="h-3.5 w-3.5 fill-current" />
                      <span>Shut Off Valve</span>
                    </>
                  ) : (
                    <>
                      <Play className="h-3.5 w-3.5 fill-current" />
                      <span>Open Valve Now</span>
                    </>
                  )}
                </button>
              </CardContent>
            </Card>
          )
        })}
      </div>
    </div>
  )
}

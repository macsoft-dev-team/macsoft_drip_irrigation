import React from "react"
import { Activity, Battery, Sun, Thermometer, Droplet, Sprout } from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

export default function Sensors() {
  const sensorNodes = [
    { id: "SN-101", zone: "Front Lawn", moisture: "48%", temp: "22°C", battery: "92%", type: "LoRa Soil Node", health: "Excellent" },
    { id: "SN-102", zone: "Front Lawn", moisture: "42%", temp: "22°C", battery: "88%", type: "LoRa Soil Node", health: "Excellent" },
    { id: "SN-201", zone: "Orchard Section A", moisture: "39%", temp: "24°C", battery: "74%", type: "LoRa Soil Node", health: "Good" },
    { id: "SN-202", zone: "Orchard Section B", moisture: "37%", temp: "25°C", battery: "12%", type: "LoRa Soil Node", health: "Low Battery" },
    { id: "SN-301", zone: "Vegetable Garden", moisture: "51%", temp: "23°C", battery: "95%", type: "LoRa Soil Node", health: "Excellent" },
    { id: "SN-401", zone: "Greenhouse Bench 1", moisture: "22%", temp: "29°C", battery: "81%", type: "SHT Mesh Sensor", health: "Warning (Dry)" }
  ]

  return (
    <div className="flex flex-col gap-6 text-xs">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-border/60">
        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 shadow-xs">
            <Activity className="h-6 w-6" />
          </div>
          <div>
            <h2 className="text-xl font-bold tracking-tight text-foreground">Sensor Telemetry</h2>
            <p className="text-xs text-muted-foreground mt-0.5">Moisture readings, battery status, and solar panels health monitor.</p>
          </div>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        {/* Environmental Overview cards */}
        <Card className="shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border hover:-translate-y-1 hover:shadow-md hover:border-amber-500/20 transition-all duration-300 group">
          <CardHeader className="pb-3">
            <CardTitle className="text-xs font-semibold text-muted-foreground uppercase tracking-wider group-hover:text-foreground transition-colors">Average Temperature</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center gap-3">
            <div className="p-3 bg-gradient-to-tr from-amber-500/10 to-yellow-500/10 dark:from-amber-500/20 dark:to-yellow-500/20 border border-amber-500/10 dark:border-amber-500/20 text-amber-500 rounded-xl transition-all duration-300 group-hover:scale-110">
              <Thermometer className="h-5 w-5" />
            </div>
            <div>
              <div className="text-2xl font-bold text-foreground">24.2°C</div>
              <p className="text-[10px] text-muted-foreground font-medium">Optimal temperature for irrigation</p>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border hover:-translate-y-1 hover:shadow-md hover:border-yellow-500/20 transition-all duration-300 group">
          <CardHeader className="pb-3">
            <CardTitle className="text-xs font-semibold text-muted-foreground uppercase tracking-wider group-hover:text-foreground transition-colors">Solar Radiation</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center gap-3">
            <div className="p-3 bg-gradient-to-tr from-yellow-500/10 to-orange-500/10 dark:from-yellow-500/20 dark:to-orange-500/20 border border-yellow-500/10 dark:border-yellow-500/20 text-yellow-500 rounded-xl transition-all duration-300 group-hover:scale-110">
              <Sun className="h-5 w-5" />
            </div>
            <div>
              <div className="text-2xl font-bold text-foreground">640 W/m²</div>
              <p className="text-[10px] text-muted-foreground font-medium">Normal solar panel charging</p>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border hover:-translate-y-1 hover:shadow-md hover:border-emerald-500/20 transition-all duration-300 group">
          <CardHeader className="pb-3">
            <CardTitle className="text-xs font-semibold text-muted-foreground uppercase tracking-wider group-hover:text-foreground transition-colors">Moisture Status</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center gap-3">
            <div className="p-3 bg-gradient-to-tr from-emerald-500/10 to-teal-500/10 dark:from-emerald-500/20 dark:to-teal-500/20 border border-emerald-500/10 dark:border-emerald-500/20 text-emerald-500 rounded-xl transition-all duration-300 group-hover:scale-110">
              <Sprout className="h-5 w-5" />
            </div>
            <div>
              <div className="text-2xl font-bold text-foreground">Normal</div>
              <p className="text-[10px] text-muted-foreground font-medium">5 nodes online, 1 reporting warning</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Sensors Table */}
      <Card className="shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border">
        <CardHeader className="pb-3">
          <CardTitle className="text-xs font-bold uppercase tracking-wider text-foreground">Wireless Sensor Nodes Network</CardTitle>
        </CardHeader>
        <CardContent className="p-0 border-t border-border overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-muted/30 border-b border-border text-muted-foreground text-[10px] font-bold uppercase tracking-wider">
                <th className="p-3">Node ID</th>
                <th className="p-3">Zone Location</th>
                <th className="p-3">Soil Moisture</th>
                <th className="p-3">Temperature</th>
                <th className="p-3">Battery Level</th>
                <th className="p-3">Type</th>
                <th className="p-3">Status / Health</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border text-[11px] font-medium text-foreground">
              {sensorNodes.map((sensor) => {
                const battVal = parseInt(sensor.battery)
                const isBatteryCritical = battVal < 20
                const isBatteryMedium = battVal >= 20 && battVal <= 75
                
                let batteryColor = "text-emerald-500"
                if (isBatteryCritical) batteryColor = "text-red-500 animate-pulse font-bold"
                else if (isBatteryMedium) batteryColor = "text-amber-500 font-semibold"

                return (
                  <tr key={sensor.id} className="hover:bg-emerald-500/5 dark:hover:bg-emerald-500/2 transition-colors">
                    <td className="p-3 font-mono font-bold text-emerald-600 dark:text-emerald-400">{sensor.id}</td>
                    <td className="p-3">{sensor.zone}</td>
                    <td className="p-3 font-semibold">
                      <span className="flex items-center gap-1.5 text-blue-500">
                        <Droplet className="h-3.5 w-3.5 fill-current" />
                        {sensor.moisture}
                      </span>
                    </td>
                    <td className="p-3">{sensor.temp}</td>
                    <td className={`p-3 font-mono ${batteryColor}`}>
                      <span className="flex items-center gap-1">
                        <Battery className={`h-3.5 w-3.5 ${isBatteryCritical ? "animate-bounce" : ""}`} />
                        {sensor.battery}
                      </span>
                    </td>
                    <td className="p-3 text-muted-foreground">{sensor.type}</td>
                    <td className="p-3">
                      <span className={`px-2 py-0.5 rounded-md text-[9px] font-bold border ${
                        sensor.health === "Excellent" || sensor.health === "Good"
                          ? "bg-emerald-500/10 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 border-emerald-500/15"
                          : isBatteryCritical
                          ? "bg-red-500/10 dark:bg-red-500/20 text-red-600 dark:text-red-400 border-red-500/15 animate-pulse"
                          : "bg-amber-500/10 dark:bg-amber-500/20 text-amber-600 dark:text-amber-400 border-amber-500/15"
                      }`}>
                        {sensor.health}
                      </span>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  )
}

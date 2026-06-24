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
      <div>
        <h2 className="text-sm font-semibold tracking-tight">Telemetry Sensors Node</h2>
        <p className="text-[11px] text-muted-foreground">Moisture readings and system hardware monitoring</p>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        {/* Environmental Overview card */}
        <Card className="shadow-xs border border-border">
          <CardHeader className="pb-3">
            <CardTitle className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Average Temperature</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center gap-3">
            <div className="p-3 bg-amber-50 dark:bg-amber-950/20 text-amber-500 rounded-lg">
              <Thermometer className="h-5 w-5" />
            </div>
            <div>
              <div className="text-xl font-bold">24.2°C</div>
              <p className="text-[10px] text-muted-foreground">Optimal temperature for irrigation</p>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-xs border border-border">
          <CardHeader className="pb-3">
            <CardTitle className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Solar Radiation</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center gap-3">
            <div className="p-3 bg-yellow-50 dark:bg-yellow-950/20 text-yellow-500 rounded-lg">
              <Sun className="h-5 w-5" />
            </div>
            <div>
              <div className="text-xl font-bold">640 W/m²</div>
              <p className="text-[10px] text-muted-foreground">Normal solar panel charging</p>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-xs border border-border">
          <CardHeader className="pb-3">
            <CardTitle className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Moisture Status</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center gap-3">
            <div className="p-3 bg-emerald-50 dark:bg-emerald-950/20 text-emerald-500 rounded-lg">
              <Sprout className="h-5 w-5" />
            </div>
            <div>
              <div className="text-xl font-bold">Normal</div>
              <p className="text-[10px] text-muted-foreground">5 nodes online, 1 reporting warning</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Sensors Table */}
      <Card className="shadow-xs border border-border">
        <CardHeader>
          <CardTitle className="text-xs font-semibold uppercase tracking-wider">Wireless Sensor Nodes Network</CardTitle>
        </CardHeader>
        <CardContent className="p-0 border-t border-border overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-muted/30 border-b border-border text-muted-foreground text-[10px] font-semibold uppercase">
                <th className="p-3">Node ID</th>
                <th className="p-3">Zone Location</th>
                <th className="p-3">Soil Moisture</th>
                <th className="p-3">Temperature</th>
                <th className="p-3">Battery Level</th>
                <th className="p-3">Type</th>
                <th className="p-3">Status / Health</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border text-[11px]">
              {sensorNodes.map((sensor) => {
                const isBatteryLow = parseInt(sensor.battery) < 20
                const isDry = sensor.health.includes("Warning")
                
                return (
                  <tr key={sensor.id} className="hover:bg-muted/10">
                    <td className="p-3 font-mono font-semibold">{sensor.id}</td>
                    <td className="p-3">{sensor.zone}</td>
                    <td className="p-3 font-semibold flex items-center gap-1">
                      <Droplet className="h-3 w-3 text-blue-500" />
                      {sensor.moisture}
                    </td>
                    <td className="p-3">{sensor.temp}</td>
                    <td className={`p-3 font-mono font-semibold ${isBatteryLow ? "text-red-500 font-bold" : "text-muted-foreground"}`}>
                      <span className="flex items-center gap-1">
                        <Battery className={`h-3.5 w-3.5 ${isBatteryLow ? "animate-pulse" : ""}`} />
                        {sensor.battery}
                      </span>
                    </td>
                    <td className="p-3 text-muted-foreground">{sensor.type}</td>
                    <td className="p-3">
                      <span className={`px-2 py-0.5 rounded-full text-[9px] font-semibold ${
                        sensor.health === "Excellent" || sensor.health === "Good"
                          ? "bg-emerald-50 dark:bg-emerald-950/20 text-emerald-600 dark:text-emerald-400"
                          : isBatteryLow
                          ? "bg-red-50 dark:bg-red-950/20 text-red-600 dark:text-red-400"
                          : "bg-amber-50 dark:bg-amber-950/20 text-amber-600 dark:text-amber-400"
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

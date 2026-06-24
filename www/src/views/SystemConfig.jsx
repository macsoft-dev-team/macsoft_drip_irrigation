import React, { useState } from "react"
import { Cpu, Wifi, Globe, Shield, RefreshCw } from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

export default function SystemConfig() {
  const [wifiSSID, setWifiSSID] = useState("Irrigation_Mesh_West")
  const [ipAddress, setIpAddress] = useState("192.168.1.60")
  const [endpoint, setEndpoint] = useState("https://api.dripcontrol.io/v2")
  const [isUpdating, setIsUpdating] = useState(false)
  const [successMsg, setSuccessMsg] = useState("")

  const handleUpdate = () => {
    setIsUpdating(true)
    setSuccessMsg("")
    setTimeout(() => {
      setIsUpdating(false)
      setSuccessMsg("Firmware updated successfully to v2.4.1!")
    }, 2000)
  }

  return (
    <div className="grid gap-6 md:grid-cols-2 text-xs">
      <Card className="shadow-xs border border-border">
        <CardHeader>
          <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
            <Wifi className="h-4 w-4 text-blue-500" />
            <span>Network Settings</span>
          </CardTitle>
          <CardDescription className="text-[10px]">Configure wireless and IP connections</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col gap-4">
          <div className="flex flex-col gap-1">
            <label className="font-semibold text-muted-foreground">Local Mesh SSID</label>
            <input 
              type="text" 
              value={wifiSSID} 
              onChange={(e) => setWifiSSID(e.target.value)}
              className="p-2 border border-border rounded-md bg-transparent text-foreground outline-hidden focus:border-blue-500"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="font-semibold text-muted-foreground">Controller IP Address</label>
            <input 
              type="text" 
              value={ipAddress} 
              onChange={(e) => setIpAddress(e.target.value)}
              className="p-2 border border-border rounded-md bg-transparent text-foreground outline-hidden focus:border-blue-500"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="font-semibold text-muted-foreground">Central Cloud Gateway Endpoint</label>
            <input 
              type="text" 
              value={endpoint} 
              onChange={(e) => setEndpoint(e.target.value)}
              className="p-2 border border-border rounded-md bg-transparent text-foreground outline-hidden focus:border-blue-500"
            />
          </div>
        </CardContent>
      </Card>

      <Card className="shadow-xs border border-border">
        <CardHeader>
          <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
            <Cpu className="h-4 w-4 text-blue-500" />
            <span>Controller Board Diagnostics</span>
          </CardTitle>
          <CardDescription className="text-[10px]">Hardware specification and firmware upgrades</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col gap-4">
          <div className="grid grid-cols-2 gap-4 py-2 border-b border-border">
            <div>
              <span className="text-[10px] text-muted-foreground">Board Model</span>
              <div className="font-bold text-foreground mt-0.5">ESP32-S3 WROOM-1</div>
            </div>
            <div>
              <span className="text-[10px] text-muted-foreground">Firmware Version</span>
              <div className="font-bold text-foreground mt-0.5">v2.4.0-stable</div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4 py-2 border-b border-border">
            <div>
              <span className="text-[10px] text-muted-foreground">Wi-Fi Signal Strength</span>
              <div className="font-bold text-foreground mt-0.5 text-emerald-500">-64 dBm (Stable)</div>
            </div>
            <div>
              <span className="text-[10px] text-muted-foreground">Allocated Valves</span>
              <div className="font-bold text-foreground mt-0.5">4 Configured (Max 8)</div>
            </div>
          </div>

          <div className="flex flex-col gap-2 mt-2">
            <button 
              onClick={handleUpdate}
              disabled={isUpdating}
              className="w-full bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 rounded-md transition-all flex items-center justify-center gap-2 outline-hidden disabled:opacity-50"
            >
              <RefreshCw className={`h-4 w-4 ${isUpdating ? "animate-spin" : ""}`} />
              <span>{isUpdating ? "Checking OTA..." : "Check for Updates"}</span>
            </button>
            {successMsg && (
              <p className="text-[10px] font-semibold text-emerald-500 text-center mt-1">{successMsg}</p>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

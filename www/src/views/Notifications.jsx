import React, { useState } from "react"
import { Bell, Mail, MessageSquare, ShieldAlert, Save } from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

export default function Notifications() {
  const [emailAlerts, setEmailAlerts] = useState(true)
  const [smsAlerts, setSmsAlerts] = useState(true)
  const [leakWarning, setLeakWarning] = useState(true)
  const [dailyDigest, setDailyDigest] = useState(false)
  const [saved, setSaved] = useState(false)

  const handleSave = (e) => {
    e.preventDefault()
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  return (
    <div className="max-w-2xl text-xs">
      <Card className="shadow-xs border border-border">
        <CardHeader>
          <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
            <Bell className="h-4 w-4 text-blue-500" />
            <span>Alert & Log Deliveries</span>
          </CardTitle>
          <CardDescription className="text-[10px]">Configure preferred channels for receiving telemetry reports</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSave} className="flex flex-col gap-4">
            
            <div className="flex items-center justify-between py-3 border-b border-border">
              <div className="flex items-start gap-2.5">
                <Mail className="h-4.5 w-4.5 text-muted-foreground mt-0.5" />
                <div>
                  <h3 className="font-semibold text-foreground">Email Status Summaries</h3>
                  <p className="text-[10px] text-muted-foreground mt-0.5">Receive detailed diagnostic logs every morning.</p>
                </div>
              </div>
              <button 
                type="button"
                onClick={() => setEmailAlerts(!emailAlerts)}
                className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out outline-hidden ${
                  emailAlerts ? "bg-blue-500" : "bg-border"
                }`}
              >
                <span className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow-sm ring-0 transition duration-200 ease-in-out ${
                  emailAlerts ? "translate-x-4" : "translate-x-0"
                }`} />
              </button>
            </div>

            <div className="flex items-center justify-between py-3 border-b border-border">
              <div className="flex items-start gap-2.5">
                <MessageSquare className="h-4.5 w-4.5 text-muted-foreground mt-0.5" />
                <div>
                  <h3 className="font-semibold text-foreground">SMS Crisis Dispatches</h3>
                  <p className="text-[10px] text-muted-foreground mt-0.5">Receive instant SMS warnings for high flow rates (possible burst pipe).</p>
                </div>
              </div>
              <button 
                type="button"
                onClick={() => setSmsAlerts(!smsAlerts)}
                className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out outline-hidden ${
                  smsAlerts ? "bg-blue-500" : "bg-border"
                }`}
              >
                <span className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow-sm ring-0 transition duration-200 ease-in-out ${
                  smsAlerts ? "translate-x-4" : "translate-x-0"
                }`} />
              </button>
            </div>

            <div className="flex items-center justify-between py-3 border-b border-border">
              <div className="flex items-start gap-2.5">
                <ShieldAlert className="h-4.5 w-4.5 text-muted-foreground mt-0.5" />
                <div>
                  <h3 className="font-semibold text-foreground">Leak Detection Alarms</h3>
                  <p className="text-[10px] text-muted-foreground mt-0.5">Trigger warning logs if low-flow usage is detected while valves are shut.</p>
                </div>
              </div>
              <button 
                type="button"
                onClick={() => setLeakWarning(!leakWarning)}
                className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out outline-hidden ${
                  leakWarning ? "bg-blue-500" : "bg-border"
                }`}
              >
                <span className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow-sm ring-0 transition duration-200 ease-in-out ${
                  leakWarning ? "translate-x-4" : "translate-x-0"
                }`} />
              </button>
            </div>

            <div className="flex items-center justify-between py-3 border-b border-border">
              <div className="flex items-start gap-2.5">
                <Bell className="h-4.5 w-4.5 text-muted-foreground mt-0.5" />
                <div>
                  <h3 className="font-semibold text-foreground">Daily Soil Health Audit</h3>
                  <p className="text-[10px] text-muted-foreground mt-0.5">Receive alert notifications if specific zone moisture falls below optimal.</p>
                </div>
              </div>
              <button 
                type="button"
                onClick={() => setDailyDigest(!dailyDigest)}
                className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out outline-hidden ${
                  dailyDigest ? "bg-blue-500" : "bg-border"
                }`}
              >
                <span className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow-sm ring-0 transition duration-200 ease-in-out ${
                  dailyDigest ? "translate-x-4" : "translate-x-0"
                }`} />
              </button>
            </div>

            <div className="flex flex-col gap-2 mt-2">
              <button 
                type="submit" 
                className="w-full bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 rounded-md transition-all flex items-center justify-center gap-1.5 shadow-xs"
              >
                <Save className="h-4 w-4" />
                <span>Save Notification Rules</span>
              </button>
              {saved && (
                <p className="text-[10px] font-semibold text-emerald-500 text-center mt-1">Notification preferences successfully updated!</p>
              )}
            </div>

          </form>
        </CardContent>
      </Card>
    </div>
  )
}

import React, { useState } from "react"
import { 
  Settings as SettingsIcon, 
  Cpu, 
  Wifi, 
  Globe, 
  Shield, 
  Save, 
  CloudLightning,
  RefreshCw,
  Building,
  Sliders
} from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
import { addLog } from "@/lib/mockDb"

export default function Settings({ db, setDb }) {
  const [activeTab, setActiveTab] = useState("company") // company, mqtt, general
  const settings = db?.settings || {}

  // Local Form state synced to settings
  const [companyForm, setCompanyForm] = useState(settings.company || {
    name: "", email: "", phone: "", address: "", logo: ""
  })

  const [mqttForm, setMqttForm] = useState(settings.mqtt || {
    brokerUrl: "", clientId: "", username: "", password: "", sslEnabled: true, keepAlive: 60, cleanSession: true
  })

  const [generalForm, setGeneralForm] = useState(settings.general || {
    systemLogsRetentionDays: 90, autoBackupEnabled: true, backupIntervalHours: 24, defaultTimeZone: "Asia/Kolkata",
    notificationChannels: { email: true, sms: true, push: false }
  })

  const [isSaving, setIsSaving] = useState(false)
  const [successMsg, setSuccessMsg] = useState("")

  const handleSaveSettings = (section, formData) => {
    setIsSaving(true)
    setSuccessMsg("")

    setTimeout(() => {
      const updatedSettings = {
        ...db.settings,
        [section]: formData
      }

      let updatedDb = { ...db, settings: updatedSettings }
      updatedDb = addLog(updatedDb, "Super Admin", "Settings Updated", `Configured ${section} parameter updates`)
      setDb(updatedDb)
      
      setIsSaving(false)
      setSuccessMsg("Settings updated successfully!")
      setTimeout(() => setSuccessMsg(""), 3000)
    }, 1000)
  }

  return (
    <div className="flex flex-col gap-6 font-sans text-xs">
      
      {/* Navigation tabs */}
      <div className="flex border-b border-border">
        <button
          onClick={() => {
            setActiveTab("company")
            setSuccessMsg("")
          }}
          className={`px-4 py-2 font-bold relative -mb-px transition-all cursor-pointer flex items-center gap-1.5 ${
            activeTab === "company" 
              ? "text-emerald-600 dark:text-emerald-400 border-b-2 border-emerald-500" 
              : "text-muted-foreground hover:text-foreground"
          }`}
        >
          <Building className="h-4 w-4" />
          <span>Company Profile</span>
        </button>

        <button
          onClick={() => {
            setActiveTab("mqtt")
            setSuccessMsg("")
          }}
          className={`px-4 py-2 font-bold relative -mb-px transition-all cursor-pointer flex items-center gap-1.5 ${
            activeTab === "mqtt" 
              ? "text-emerald-600 dark:text-emerald-400 border-b-2 border-emerald-500" 
              : "text-muted-foreground hover:text-foreground"
          }`}
        >
          <Globe className="h-4 w-4" />
          <span>MQTT IoT Gateway</span>
        </button>

        <button
          onClick={() => {
            setActiveTab("general")
            setSuccessMsg("")
          }}
          className={`px-4 py-2 font-bold relative -mb-px transition-all cursor-pointer flex items-center gap-1.5 ${
            activeTab === "general" 
              ? "text-emerald-600 dark:text-emerald-400 border-b-2 border-emerald-500" 
              : "text-muted-foreground hover:text-foreground"
          }`}
        >
          <Sliders className="h-4 w-4" />
          <span>General Preferences</span>
        </button>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        
        {/* Main Settings Forms */}
        <div className="md:col-span-2 flex flex-col gap-4">
          
          {activeTab === "company" && (
            <Card className="shadow-xs border border-border bg-card">
              <CardHeader>
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Company Information</CardTitle>
                <CardDescription className="text-[10px] text-muted-foreground">Standard SaaS owner profile metrics used in ticket logs & billing templates</CardDescription>
              </CardHeader>
              <CardContent>
                <form 
                  onSubmit={(e) => {
                    e.preventDefault()
                    handleSaveSettings("company", companyForm)
                  }}
                  className="flex flex-col gap-4 font-bold"
                >
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Company Name</label>
                    <input
                      type="text"
                      required
                      value={companyForm.name}
                      onChange={(e) => setCompanyForm({ ...companyForm, name: e.target.value })}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="flex flex-col gap-1.5">
                      <label className="text-muted-foreground">Business Email</label>
                      <input
                        type="email"
                        required
                        value={companyForm.email}
                        onChange={(e) => setCompanyForm({ ...companyForm, email: e.target.value })}
                        className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 font-mono"
                      />
                    </div>
                    <div className="flex flex-col gap-1.5">
                      <label className="text-muted-foreground">Support Contact Phone</label>
                      <input
                        type="tel"
                        required
                        value={companyForm.phone}
                        onChange={(e) => setCompanyForm({ ...companyForm, phone: e.target.value })}
                        className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 font-mono"
                      />
                    </div>
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Headquarters Address</label>
                    <textarea
                      required
                      value={companyForm.address}
                      onChange={(e) => setCompanyForm({ ...companyForm, address: e.target.value })}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 h-16 resize-none"
                    />
                  </div>

                  <div className="flex items-center justify-between mt-2">
                    <button
                      type="submit"
                      disabled={isSaving}
                      className="flex items-center gap-1.5 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold transition-all shadow-xs cursor-pointer disabled:opacity-50"
                    >
                      <Save className="h-4 w-4" />
                      <span>{isSaving ? "Saving..." : "Save Profile"}</span>
                    </button>
                    {successMsg && (
                      <span className="text-emerald-600 font-bold">{successMsg}</span>
                    )}
                  </div>
                </form>
              </CardContent>
            </Card>
          )}

          {activeTab === "mqtt" && (
            <Card className="shadow-xs border border-border bg-card">
              <CardHeader>
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">MQTT Broker Credentials</CardTitle>
                <CardDescription className="text-[10px] text-muted-foreground">Gateway connection details used to establish telemetry loop updates</CardDescription>
              </CardHeader>
              <CardContent>
                <form 
                  onSubmit={(e) => {
                    e.preventDefault()
                    handleSaveSettings("mqtt", mqttForm)
                  }}
                  className="flex flex-col gap-4 font-bold"
                >
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Broker endpoint URL</label>
                    <input
                      type="text"
                      required
                      value={mqttForm.brokerUrl}
                      onChange={(e) => setMqttForm({ ...mqttForm, brokerUrl: e.target.value })}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 font-mono"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="flex flex-col gap-1.5">
                      <label className="text-muted-foreground">Client ID prefix</label>
                      <input
                        type="text"
                        required
                        value={mqttForm.clientId}
                        onChange={(e) => setMqttForm({ ...mqttForm, clientId: e.target.value })}
                        className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 font-mono"
                      />
                    </div>
                    <div className="flex flex-col gap-1.5">
                      <label className="text-muted-foreground">Username</label>
                      <input
                        type="text"
                        required
                        value={mqttForm.username}
                        onChange={(e) => setMqttForm({ ...mqttForm, username: e.target.value })}
                        className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 font-mono"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="flex flex-col gap-1.5">
                      <label className="text-muted-foreground">Password Credentials</label>
                      <input
                        type="password"
                        required
                        value={mqttForm.password}
                        onChange={(e) => setMqttForm({ ...mqttForm, password: e.target.value })}
                        className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 font-mono"
                      />
                    </div>
                    <div className="flex flex-col gap-1.5">
                      <label className="text-muted-foreground">Keep Alive Interval (seconds)</label>
                      <input
                        type="number"
                        required
                        value={mqttForm.keepAlive}
                        onChange={(e) => setMqttForm({ ...mqttForm, keepAlive: parseInt(e.target.value) || 60 })}
                        className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 text-center font-mono"
                      />
                    </div>
                  </div>

                  <div className="flex items-center gap-6 py-2 border-b border-border/40 text-[11px]">
                    <label className="flex items-center gap-1.5 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={mqttForm.sslEnabled}
                        onChange={(e) => setMqttForm({ ...mqttForm, sslEnabled: e.target.checked })}
                        className="accent-emerald-600 rounded"
                      />
                      <span>Enable Secure SSL Connection (TLS v1.3)</span>
                    </label>
                    
                    <label className="flex items-center gap-1.5 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={mqttForm.cleanSession}
                        onChange={(e) => setMqttForm({ ...mqttForm, cleanSession: e.target.checked })}
                        className="accent-emerald-600 rounded"
                      />
                      <span>Clean Session on disconnect</span>
                    </label>
                  </div>

                  <div className="flex items-center justify-between mt-2">
                    <button
                      type="submit"
                      disabled={isSaving}
                      className="flex items-center gap-1.5 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold transition-all shadow-xs cursor-pointer disabled:opacity-50"
                    >
                      <Save className="h-4 w-4" />
                      <span>{isSaving ? "Saving..." : "Save Broker Settings"}</span>
                    </button>
                    {successMsg && (
                      <span className="text-emerald-600 font-bold">{successMsg}</span>
                    )}
                  </div>
                </form>
              </CardContent>
            </Card>
          )}

          {activeTab === "general" && (
            <Card className="shadow-xs border border-border bg-card">
              <CardHeader>
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">General Preferences</CardTitle>
                <CardDescription className="text-[10px] text-muted-foreground">Configure global system defaults, retention logs, and backups</CardDescription>
              </CardHeader>
              <CardContent>
                <form 
                  onSubmit={(e) => {
                    e.preventDefault()
                    handleSaveSettings("general", generalForm)
                  }}
                  className="flex flex-col gap-4 font-bold"
                >
                  <div className="grid grid-cols-2 gap-4">
                    <div className="flex flex-col gap-1.5">
                      <label className="text-muted-foreground">Default System Timezone</label>
                      <select
                        value={generalForm.defaultTimeZone}
                        onChange={(e) => setGeneralForm({ ...generalForm, defaultTimeZone: e.target.value })}
                        className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 font-bold cursor-pointer"
                      >
                        <option value="Asia/Kolkata">Asia/Kolkata (IST)</option>
                        <option value="UTC">Coordinated Universal Time (UTC)</option>
                        <option value="America/New_York">America/New_York (EST)</option>
                      </select>
                    </div>

                    <div className="flex flex-col gap-1.5">
                      <label className="text-muted-foreground">Command logs retention duration (days)</label>
                      <input
                        type="number"
                        required
                        value={generalForm.systemLogsRetentionDays}
                        onChange={(e) => setGeneralForm({ ...generalForm, systemLogsRetentionDays: parseInt(e.target.value) || 90 })}
                        className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 text-center font-mono"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="flex flex-col gap-1.5">
                      <label className="text-muted-foreground">Automated database backups</label>
                      <select
                        value={generalForm.autoBackupEnabled ? "yes" : "no"}
                        onChange={(e) => setGeneralForm({ ...generalForm, autoBackupEnabled: e.target.value === "yes" })}
                        className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 font-bold cursor-pointer"
                      >
                        <option value="yes">Enabled</option>
                        <option value="no">Disabled</option>
                      </select>
                    </div>

                    {generalForm.autoBackupEnabled && (
                      <div className="flex flex-col gap-1.5">
                        <label className="text-muted-foreground">Backup Interval Frequency (Hours)</label>
                        <input
                          type="number"
                          required
                          value={generalForm.backupIntervalHours}
                          onChange={(e) => setGeneralForm({ ...generalForm, backupIntervalHours: parseInt(e.target.value) || 24 })}
                          className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 text-center font-mono"
                        />
                      </div>
                    )}
                  </div>

                  <div className="flex flex-col gap-2 py-2 border-b border-border/40 text-[11px]">
                    <span className="text-muted-foreground">Default Alert Alert Channels</span>
                    <div className="flex gap-4 mt-1">
                      <label className="flex items-center gap-1.5 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={generalForm.notificationChannels.email}
                          onChange={(e) => setGeneralForm({ 
                            ...generalForm, 
                            notificationChannels: { ...generalForm.notificationChannels, email: e.target.checked } 
                          })}
                          className="accent-emerald-600 rounded"
                        />
                        <span>Email Reports</span>
                      </label>
                      
                      <label className="flex items-center gap-1.5 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={generalForm.notificationChannels.sms}
                          onChange={(e) => setGeneralForm({ 
                            ...generalForm, 
                            notificationChannels: { ...generalForm.notificationChannels, sms: e.target.checked } 
                          })}
                          className="accent-emerald-600 rounded"
                        />
                        <span>SMS Alerts</span>
                      </label>
                    </div>
                  </div>

                  <div className="flex items-center justify-between mt-2">
                    <button
                      type="submit"
                      disabled={isSaving}
                      className="flex items-center gap-1.5 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold transition-all shadow-xs cursor-pointer disabled:opacity-50"
                    >
                      <Save className="h-4 w-4" />
                      <span>{isSaving ? "Saving..." : "Save Preferences"}</span>
                    </button>
                    {successMsg && (
                      <span className="text-emerald-600 font-bold">{successMsg}</span>
                    )}
                  </div>
                </form>
              </CardContent>
            </Card>
          )}

        </div>

        {/* Info card help section */}
        <div className="flex flex-col gap-6">
          <Card className="shadow-xs border border-border bg-card">
            <CardHeader>
              <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">SaaS configuration Help</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-3 font-semibold text-muted-foreground leading-relaxed">
              <p>
                <strong>Company Profile</strong> settings populate report summaries, billing contexts, and distributor assignments.
              </p>
              <p>
                The <strong>MQTT IoT Gateway</strong> connects the web application to physical field controllers. Verify host endpoints and port settings with your local network engineer.
              </p>
              <p>
                SSL settings encrypt all serial commands sent over local GPRS modems. Keep these enabled in production.
              </p>
            </CardContent>
          </Card>
        </div>

      </div>

    </div>
  )
}

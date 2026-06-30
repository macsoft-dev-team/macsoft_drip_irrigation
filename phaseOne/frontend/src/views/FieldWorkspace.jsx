import React, { useState, useEffect } from "react"
import { 
  Sprout, 
  Droplet, 
  Cpu, 
  Layers, 
  Calendar, 
  Activity, 
  Settings2, 
  Plus, 
  Trash2, 
  Power, 
  AlertTriangle,
  Clock, 
  Wifi, 
  Gauge,
  ListFilter,
  CheckCircle,
  Play,
  RotateCw,
  Terminal,
  Grid,
  GripVertical,
  PlusCircle,
  ArrowRight,
  X
} from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { addLog } from "@/lib/mockDb"

export default function FieldWorkspace({ 
  navigate, 
  db, 
  setDb, 
  selectedFarmerId, 
  selectedFieldId, 
  activeTab = "overview", 
  setActiveTab 
}) {

  // 1. Fetch current field context
  const field = db?.fields?.find(f => f.id === selectedFieldId)
  const farmer = db?.farmers?.find(f => f.id === selectedFarmerId)

  // Heartbeat live simulation feed state
  const [heartbeatLogs, setHeartbeatLogs] = useState([
    `[${new Date().toLocaleTimeString()}] Raspberry Pi MQTT Gateway Connected. System healthy.`,
    `[${new Date().toLocaleTimeString()}] Heartbeat acknowledged. Latency: 45ms.`,
  ])

  // Modals inside workspace
  const [activeModal, setActiveModal] = useState(null) // add-slave, add-valve, create-zone, create-schedule, edit-registers, null
  
  // Direct AP connection provisioning state (mobile app to master)
  const [provisioningState, setProvisioningState] = useState("idle") // idle, broadcasting, connected, completed
  
  // Local Form States
  const [slaveForm, setSlaveForm] = useState({ name: "", ipAddress: "", port: "502", unitId: "", outputs: "8" })
  const [valveForm, setValveForm] = useState({ name: "", type: "Drip", capacity: "12.0", modbusAddress: "", slaveId: "" })
  const [zoneForm, setZoneForm] = useState({ name: "", location: "", selectedValves: [] })
  
  // Schedules Form States
  const [schedForm, setSchedForm] = useState({
    name: "", type: "timeBased", zoneName: "", startTime: "08:00 AM", duration: 15, days: "Daily",
    rtcZones: [], timerSequence: []
  })

  // Command console messages
  const [consoleInput, setConsoleInput] = useState("")
  const [consoleOutput, setConsoleOutput] = useState([
    "DripAdmin IoT Terminal v1.0.0",
    "Enter raw commands or use buttons above for automated execution."
  ])

  // Generate simulated heartbeat logs
  useEffect(() => {
    if (!field || field.masterDevice?.status !== "Online") return

    const interval = setInterval(() => {
      const time = new Date().toLocaleTimeString()
      const connectionInfo = field.masterDevice.latency || field.masterDevice.signalStrength || "45ms"
      const pumpState = field.pump?.status || "Off"
      const activeValvesCount = field.valves?.filter(v => v.status === "Open").length || 0
      
      const logMsg = `[${time}] Heartbeat: Latency=${connectionInfo}, Pump=${pumpState}, ActiveValves=${activeValvesCount}, SoilAvg=${
        field.zones?.length > 0 
          ? (field.zones.reduce((sum, z) => sum + z.moisture, 0) / field.zones.length).toFixed(1)
          : "N/A"
      }%`
      
      setHeartbeatLogs(prev => [logMsg, ...prev.slice(0, 15)])
    }, 5000)

    return () => clearInterval(interval)
  }, [field])

  if (!field) {
    return (
      <div className="flex flex-col items-center justify-center p-12 bg-card rounded-2xl border border-dashed text-center">
        <AlertTriangle className="h-8 w-8 text-amber-500 mb-3" />
        <h3 className="text-sm font-bold text-foreground">No Field Context</h3>
        <p className="text-xs text-muted-foreground mt-1">Please select a farmer and field to enter workspace.</p>
        <button onClick={() => navigate("/farmers")} className="mt-4 px-4 py-2 bg-emerald-600 text-white rounded-lg font-bold hover:bg-emerald-700 cursor-pointer">
          Go to Farmers
        </button>
      </div>
    )
  }

  // --- Dynamic Tab Layout Selectors ---

  // Actuate (Open/Close) Valve manually
  const handleToggleValve = (valveId, name, currentStatus) => {
    const nextStatus = currentStatus === "Open" ? "Closed" : "Open"
    const updatedValves = field.valves.map(v => v.id === valveId ? { ...v, status: nextStatus, flowRate: nextStatus === "Open" ? v.capacity : 0 } : v)
    
    // Save in DB
    const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, valves: updatedValves } : f)
    let updatedDb = { ...db, fields: updatedFields }
    updatedDb = addLog(updatedDb, "Super Admin", `Valve ${nextStatus === "Open" ? "Opened" : "Closed"}`, `Manual actuation of: ${name} on ${field.name}`)
    setDb(updatedDb)

    const valve = field.valves.find(v => v.id === valveId)
    const slave = field.slaves.find(s => s.id === valve?.slaveId)

    // Log the full communication flow from flow.md in the terminal console!
    setConsoleOutput(prev => [
      `[Slave TCP] Output Relay ${nextStatus === "Open" ? "ON" : "OFF"}. GPIO state = ${nextStatus === "Open" ? "HIGH" : "LOW"}. Valve '${name}' ${nextStatus === "Open" ? "Opened" : "Closed"}.`,
      `[Master Pi] Write Single Coil (Unit ID: ${slave?.unitId || 1}, Coil Address: ${valve?.modbusAddress || "40001"}, Value: ${nextStatus === "Open" ? "1" : "0"})`,
      `[Master Pi] Connecting to Modbus TCP Server at ${slave?.ipAddress || "192.168.1.101"}:${slave?.port || 502}...`,
      `[Backend] POST /master/execute (Target: Raspberry Pi Master)`,
      `[HTTP POST] /api/irrigation/actuate-valve`,
      ...prev
    ])
  }

  // Emergency Stop: Shut off all valves
  const handleEmergencyStop = () => {
    const updatedValves = field.valves.map(v => ({ ...v, status: "Closed", flowRate: 0 }))
    const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, valves: updatedValves, pump: { ...f.pump, status: "Off", loadAmps: 0 } } : f)
    let updatedDb = { ...db, fields: updatedFields }
    updatedDb = addLog(updatedDb, "Super Admin", "EMERGENCY SHUTDOWN", `Triggered E-Stop for ${field.name}`)
    setDb(updatedDb)

    setConsoleOutput(prev => [
      `[Slave TCP] Shutdown command received. Relays open.`,
      `[Master Pi] Connection E-Stop broadcast sent to Modbus TCP network.`,
      `[Backend] POST /master/emergency-stop`,
      `[HTTP POST] /api/irrigation/emergency-stop`,
      ...prev
    ])
  }

  // Add Slave Board configuration
  const handleAddSlave = (e) => {
    e.preventDefault()
    const newSlave = {
      id: Date.now(),
      name: slaveForm.name,
      ipAddress: slaveForm.ipAddress || `192.168.1.${100 + field.slaves.length + 1}`,
      port: parseInt(slaveForm.port) || 502,
      unitId: parseInt(slaveForm.unitId) || (field.slaves.length + 1),
      outputs: parseInt(slaveForm.outputs) || 8,
      status: "Online"
    }

    const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, slaves: [...f.slaves, newSlave] } : f)
    let updatedDb = { ...db, fields: updatedFields }
    updatedDb = addLog(updatedDb, "Super Admin", "Modbus TCP Slave Commissioned", `Added slave ${newSlave.name} (IP: ${newSlave.ipAddress}, Unit ID: ${newSlave.unitId}) to ${field.name}`)
    setDb(updatedDb)
    setActiveModal(null)
  }

  // Add Valve mapping
  const handleAddValve = (e) => {
    e.preventDefault()
    const newValve = {
      id: Date.now(),
      name: valveForm.name,
      type: valveForm.type,
      status: "Closed",
      flowRate: 0,
      capacity: parseFloat(valveForm.capacity) || 12.0,
      modbusAddress: valveForm.modbusAddress || "40001",
      slaveId: parseInt(valveForm.slaveId) || 1,
      zoneId: null
    }

    // Add mapped Modbus coil register to settings
    const newReg = {
      register: newValve.modbusAddress,
      description: `${newValve.name} Coil Status (Read/Write)`,
      type: "Coil",
      value: "0"
    }

    const updatedFields = db.fields.map(f => {
      if (f.id === selectedFieldId) {
        return {
          ...f,
          valves: [...f.valves, newValve],
          modbusRegisters: [...f.modbusRegisters, newReg]
        }
      }
      return f
    })

    let updatedDb = { ...db, fields: updatedFields }
    updatedDb = addLog(updatedDb, "Super Admin", "Valve Mapped", `Configured Modbus Coil ${newValve.modbusAddress} for valve ${newValve.name}`)
    setDb(updatedDb)
    setActiveModal(null)
  }

  // Delete Slave Board
  const handleDeleteSlave = (id, name) => {
    if (confirm(`Remove slave board: ${name}? All mapped valves will be unlinked.`)) {
      const updatedSlaves = field.slaves.filter(s => s.id !== id)
      const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, slaves: updatedSlaves } : f)
      let updatedDb = { ...db, fields: updatedFields }
      updatedDb = addLog(updatedDb, "Super Admin", "Slave Removed", `De-commissioned slave board ${name}`)
      setDb(updatedDb)
    }
  }

  // Delete Valve
  const handleDeleteValve = (id, name) => {
    if (confirm(`Delete valve: ${name}?`)) {
      const updatedValves = field.valves.filter(v => v.id !== id)
      const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, valves: updatedValves } : f)
      let updatedDb = { ...db, fields: updatedFields }
      updatedDb = addLog(updatedDb, "Super Admin", "Valve Removed", `De-commissioned valve ${name}`)
      setDb(updatedDb)
    }
  }

  // Create Zone
  const handleCreateZone = (e) => {
    e.preventDefault()
    const newZone = {
      id: Date.now(),
      name: zoneForm.name,
      location: zoneForm.location || "Sector",
      moisture: 45.0,
      valveIds: zoneForm.selectedValves.map(Number)
    }

    // Update valves mapped to this zone
    const updatedValves = field.valves.map(v => 
      newZone.valveIds.includes(v.id) ? { ...v, zoneId: newZone.id } : v
    )

    const updatedFields = db.fields.map(f => {
      if (f.id === selectedFieldId) {
        return {
          ...f,
          zones: [...f.zones, newZone],
          valves: updatedValves
        }
      }
      return f
    })

    let updatedDb = { ...db, fields: updatedFields }
    updatedDb = addLog(updatedDb, "Super Admin", "Zone Created", `Configured new irrigation zone: ${newZone.name}`)
    setDb(updatedDb)
    setActiveModal(null)
  }

  // Test communication with a Modbus slave
  const testCommunication = (slave) => {
    setConsoleOutput(prev => [
      `[HTTP GET] /api/irrigation/test-slave?ip=${slave.ipAddress}&port=${slave.port || 502}`,
      `[Master Pi] Connecting to Modbus TCP Server at ${slave.ipAddress}:${slave.port || 502}...`,
      ...prev
    ])
    setTimeout(() => {
      setConsoleOutput(prev => [
        `[SUCCESS] Modbus TCP connection test with Slave '${slave.name}' succeeded! Latency: 18ms. CRC OK.`,
        ...prev
      ])
    }, 600)
  }

  // Test a single Valve
  const testValve = (valve) => {
    const slave = field.slaves.find(s => s.id === valve.slaveId)
    setConsoleOutput(prev => [
      `[HTTP POST] /api/irrigation/actuate-valve`,
      `[Backend] POST /master/execute (Target: Slave ID ${slave?.unitId || 1})`,
      `[Master Pi] Connecting to Modbus TCP Server at ${slave?.ipAddress || "192.168.1.101"}:502...`,
      `[Master Pi] Write Single Coil (Unit ID: ${slave?.unitId || 1}, Coil: ${valve.modbusAddress}, Value: 1)`,
      `[Slave TCP] Output Relay Actuated. GPIO = HIGH. Valve '${valve.name}' open.`,
      ...prev
    ])
    handleToggleValve(valve.id, `${valve.name} (Test Pulse)`, "Closed")
    setTimeout(() => {
      setConsoleOutput(prev => [
        `[Master Pi] Write Single Coil (Unit ID: ${slave?.unitId || 1}, Coil: ${valve.modbusAddress}, Value: 0)`,
        `[Slave TCP] Output Relay Released. GPIO = LOW. Valve '${valve.name}' closed.`,
        ...prev
      ])
      handleToggleValve(valve.id, `${valve.name} (Test Pulse Ended)`, "Open")
    }, 4000)
  }

  // Execute terminal console commands
  const executeConsoleCommand = (e) => {
    e.preventDefault()
    if (!consoleInput.trim()) return

    const cmd = consoleInput.trim().toUpperCase()
    let out = `> ${consoleInput}`
    let response = ""

    if (cmd === "HELP") {
      response = "Available Commands: HELP, STATUS, STOP, OPEN <valve_id>, CLOSE <valve_id>, SCAN"
    } else if (cmd === "STATUS") {
      response = `MASTER STATE: ${field.masterDevice?.status || "Unknown"}, IP: ${field.masterDevice?.ipAddress}, PUMP: ${field.pump?.status}`
    } else if (cmd === "STOP") {
      handleEmergencyStop()
      response = "E-Stop triggered successfully."
    } else if (cmd.startsWith("OPEN ")) {
      const vid = parseInt(cmd.split(" ")[1])
      const vObj = field.valves.find(v => v.id === vid)
      if (vObj) {
        handleToggleValve(vid, vObj.name, "Closed")
        response = `Command executed: Opened valve ${vid}`
      } else {
        response = `Error: Valve ID ${vid} not found.`
      }
    } else if (cmd.startsWith("CLOSE ")) {
      const vid = parseInt(cmd.split(" ")[1])
      const vObj = field.valves.find(v => v.id === vid)
      if (vObj) {
        handleToggleValve(vid, vObj.name, "Open")
        response = `Command executed: Closed valve ${vid}`
      } else {
        response = `Error: Valve ID ${vid} not found.`
      }
    } else if (cmd === "SCAN") {
      response = "Scanning Modbus serial loops... Found 2 slave boards active."
    } else {
      response = `Command not recognized: '${cmd}'. Type HELP for options.`
    }

    setConsoleOutput(prev => [response, out, ...prev])
    setConsoleInput("")
  }

  // Save Modbus Register changes
  const updateRegisterValue = (regAddress, val) => {
    const updatedRegs = field.modbusRegisters.map(r => r.register === regAddress ? { ...r, value: val } : r)
    const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, modbusRegisters: updatedRegs } : f)
    setDb({ ...db, fields: updatedFields })
  }

  return (
    <div className="flex flex-col gap-6 font-sans">
      
      {/* -------------------- 1. OVERVIEW TAB -------------------- */}
      {activeTab === "overview" && (
        <div className="grid gap-6 md:grid-cols-3">
          
          {/* Main Info Card */}
          <Card className="md:col-span-2 shadow-xs border border-border bg-card">
            <CardHeader>
              <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Field Configuration Overview</CardTitle>
            </CardHeader>
            <CardContent className="grid gap-4 md:grid-cols-2 text-xs">
              <div className="flex flex-col gap-1 border-b border-border/40 pb-2">
                <span className="font-semibold text-muted-foreground">Area Acreage</span>
                <span className="font-extrabold text-foreground">{field.area}</span>
              </div>
              <div className="flex flex-col gap-1 border-b border-border/40 pb-2">
                <span className="font-semibold text-muted-foreground">Crop Variety</span>
                <span className="font-extrabold text-foreground">{field.cropType}</span>
              </div>
              <div className="flex flex-col gap-1 border-b border-border/40 pb-2">
                <span className="font-semibold text-muted-foreground">Soil Profile Type</span>
                <span className="font-extrabold text-foreground">{field.soilType}</span>
              </div>
              <div className="flex flex-col gap-1 border-b border-border/40 pb-2">
                <span className="font-semibold text-muted-foreground">Water Feed Source</span>
                <span className="font-extrabold text-foreground">{field.waterSource}</span>
              </div>
              <div className="flex flex-col gap-1 border-b border-border/40 pb-2">
                <span className="font-semibold text-muted-foreground">Master Board Model</span>
                <span className="font-extrabold text-foreground font-mono">{field.masterDevice?.model || "Raspberry Pi"}</span>
              </div>
              <div className="flex flex-col gap-1 border-b border-border/40 pb-2">
                <span className="font-semibold text-muted-foreground">MQTT Topic Connection</span>
                <span className="font-extrabold text-emerald-600 dark:text-emerald-400 font-mono">{field.masterDevice?.mqttTopic || field.masterDevice?.imei}</span>
              </div>
            </CardContent>
          </Card>

          {/* Moisture Gauge Visualizer */}
          <Card className="shadow-xs border border-border bg-card flex flex-col justify-between">
            <CardHeader>
              <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Avg Hydration Level</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col items-center justify-center p-4">
              <div className="relative flex items-center justify-center">
                {/* SVG circular progress indicator */}
                <svg className="w-32 h-32 overflow-visible transform -rotate-90">
                  <circle cx="64" cy="64" r="50" fill="none" stroke="currentColor" strokeOpacity="0.05" strokeWidth="10" />
                  <circle 
                    cx="64" 
                    cy="64" 
                    r="50" 
                    fill="none" 
                    stroke="#10b981" 
                    strokeWidth="10" 
                    strokeDasharray="314"
                    strokeDashoffset={314 - (314 * (field.zones?.length > 0 ? (field.zones.reduce((sum, z) => sum + z.moisture, 0) / field.zones.length) : 0)) / 100}
                    strokeLinecap="round"
                    className="transition-all duration-1000"
                  />
                </svg>
                <div className="absolute flex flex-col items-center justify-center">
                  <span className="text-2xl font-black text-foreground">
                    {field.zones?.length > 0 
                      ? (field.zones.reduce((sum, z) => sum + z.moisture, 0) / field.zones.length).toFixed(1)
                      : "N/A"
                    }%
                  </span>
                  <span className="text-[8px] text-muted-foreground uppercase font-bold tracking-widest mt-0.5">Hydrated</span>
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4 w-full mt-6 text-center text-[10px] font-bold text-muted-foreground border-t border-border/40 pt-3">
                <div>
                  <div>Zones Configured</div>
                  <div className="text-foreground text-sm font-black mt-0.5">{field.zones?.length || 0}</div>
                </div>
                <div>
                  <div>Actuators Connected</div>
                  <div className="text-foreground text-sm font-black mt-0.5">{field.valves?.length || 0}</div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* -------------------- 2. DEVICES TAB -------------------- */}
      {activeTab === "devices" && (
        <div className="grid gap-6">
          
          {/* Master Controller and Pump Row */}
          <div className="grid gap-6 md:grid-cols-3">
            {/* Master Controller Config */}
            <Card className="shadow-xs border border-border bg-card">
              <CardHeader>
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground flex items-center gap-1.5">
                  <Cpu className="h-4.5 w-4.5 text-emerald-500" />
                  <span>Master Board (Raspberry Pi)</span>
                </CardTitle>
                <CardDescription className="text-[9px] text-muted-foreground">Primary edge gateway hardware publishing via MQTT</CardDescription>
              </CardHeader>
              <CardContent className="flex flex-col gap-3 text-xs">
                <div className="flex justify-between py-1.5 border-b border-border/40">
                  <span className="font-semibold text-muted-foreground">Board Model</span>
                  <span className="font-extrabold text-foreground">{field.masterDevice?.model || "Raspberry Pi 4 Model B"}</span>
                </div>
                <div className="flex justify-between py-1.5 border-b border-border/40">
                  <span className="font-semibold text-muted-foreground">MQTT Broker Topic</span>
                  <span className="font-extrabold text-foreground font-mono">{field.masterDevice?.mqttTopic || field.masterDevice?.imei}</span>
                </div>
                <div className="flex justify-between py-1.5 border-b border-border/40">
                  <span className="font-semibold text-muted-foreground">Link Latency</span>
                  <span className="font-extrabold text-emerald-600 font-mono flex items-center gap-1">
                    <Wifi className="h-3.5 w-3.5" />
                    {field.masterDevice?.latency || "45ms"}
                  </span>
                </div>
                <div className="flex justify-between py-1.5">
                  <span className="font-semibold text-muted-foreground">Firmware OTA Version</span>
                  <span className="font-extrabold text-foreground font-mono">{field.masterDevice?.firmware}</span>
                </div>
              </CardContent>
            </Card>

            {/* Direct WiFi Provisioning Helper */}
            <Card className="shadow-xs border border-border bg-card">
              <CardHeader>
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground flex items-center gap-1.5">
                  <Wifi className="h-4.5 w-4.5 text-emerald-500" />
                  <span>WiFi Provisioning Gateway</span>
                </CardTitle>
                <CardDescription className="text-[9px] text-muted-foreground">Mobile-to-Master direct AP network setup</CardDescription>
              </CardHeader>
              <CardContent className="flex flex-col gap-2.5 text-xs font-semibold">
                <div className="flex justify-between py-1 border-b border-border/40 font-bold text-[10px]">
                  <span className="text-muted-foreground">Local AP SSID</span>
                  <span className="font-mono text-foreground font-black">DripMaster_{field.masterDevice?.mqttTopic?.split("/").pop() || "RPi"}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-border/40 font-bold text-[10px]">
                  <span className="text-muted-foreground">AP Mode Status</span>
                  <span className={`inline-flex items-center gap-1 ${
                    provisioningState === "broadcasting" ? "text-amber-500 animate-pulse" : 
                    provisioningState === "connected" ? "text-indigo-500" :
                    provisioningState === "completed" ? "text-green-600 animate-pulse" : "text-muted-foreground"
                  }`}>
                    {provisioningState === "broadcasting" ? "Broadcasting AP..." : 
                     provisioningState === "connected" ? "Mobile Connected" :
                     provisioningState === "completed" ? "WiFi Credentials Sent" : "Inactive"}
                  </span>
                </div>

                <div className="flex flex-col gap-1.5 mt-1 leading-relaxed text-[9px] font-semibold text-muted-foreground bg-muted/20 p-2.5 rounded-lg border border-border/50">
                  <div className="flex items-start gap-1">
                    <span className="text-emerald-500 font-bold">1.</span>
                    <span>Hold Master's reboot key for 5s to host local WiFi access point.</span>
                  </div>
                  <div className="flex items-start gap-1">
                    <span className="text-emerald-500 font-bold">2.</span>
                    <span>Connect mobile app to local SSID and enter orchard WiFi credentials.</span>
                  </div>
                  <div className="flex items-start gap-1">
                    <span className="text-emerald-500 font-bold">3.</span>
                    <span>Credentials sync automatically, establishing MQTT online link status.</span>
                  </div>
                </div>

                <div className="flex gap-2 mt-1">
                  {provisioningState === "idle" ? (
                    <button
                      onClick={() => {
                        setProvisioningState("broadcasting")
                        setConsoleOutput(prev => [
                          `[INFO] Direct AP broadcast enabled: SSID=DripMaster_${field.masterDevice?.mqttTopic?.split("/").pop() || "RPi"}`,
                          `[INFO] Direct WiFi Provisioning Mode is waiting for mobile app connection...`,
                          ...prev
                        ])
                        setTimeout(() => {
                          setProvisioningState("connected")
                          setConsoleOutput(prev => [
                            `[INFO] Mobile App connected over direct WiFi local AP.`,
                            `[INFO] Awaiting credentials payload submit from mobile device...`,
                            ...prev
                          ])
                        }, 3500)
                      }}
                      className="w-full py-1.5 bg-emerald-600/10 hover:bg-emerald-600/20 text-emerald-600 rounded-lg text-[10px] font-bold text-center cursor-pointer border border-emerald-500/10 transition-all"
                    >
                      Trigger AP Mode
                    </button>
                  ) : (
                    <button
                      onClick={() => {
                        setProvisioningState("completed")
                        setConsoleOutput(prev => [
                          `[SUCCESS] Master received SSID credentials payload from mobile device. Connecting to router...`,
                          `[SUCCESS] Connection established! Master IP allocated: ${field.masterDevice?.ipAddress || "192.168.1.65"}.`,
                          `[SUCCESS] MQTT Client logged onto broker topic ${field.masterDevice?.mqttTopic || "macsoft/drip"}.`,
                          ...prev
                        ])
                        setTimeout(() => setProvisioningState("idle"), 4000)
                      }}
                      disabled={provisioningState === "completed"}
                      className="w-full py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-[10px] font-bold text-center cursor-pointer disabled:opacity-50 transition-all"
                    >
                      {provisioningState === "broadcasting" ? "Awaiting Mobile Connection..." :
                       provisioningState === "connected" ? "Submit Wifi Credentials" : "WiFi Provisioned!"}
                    </button>
                  )}
                </div>
              </CardContent>
            </Card>

            {/* Pump & Motor Status */}
            <Card className="shadow-xs border border-border bg-card">
              <CardHeader>
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground flex items-center gap-1.5">
                  <Power className="h-4.5 w-4.5 text-indigo-500" />
                  <span>Submersible Pump Controller</span>
                </CardTitle>
                <CardDescription className="text-[9px] text-muted-foreground">Motor load load, voltage and phase metrics</CardDescription>
              </CardHeader>
              <CardContent className="flex flex-col gap-3 text-xs">
                <div className="flex justify-between py-1.5 border-b border-border/40 font-bold">
                  <span className="font-semibold text-muted-foreground">Motor State</span>
                  <span className={`inline-flex items-center px-1.5 py-0.2 rounded-md ${
                    field.pump?.status === "On" ? "bg-green-500/10 text-green-600 animate-pulse" : "bg-muted text-muted-foreground"
                  }`}>
                    {field.pump?.status}
                  </span>
                </div>
                <div className="flex justify-between py-1.5 border-b border-border/40">
                  <span className="font-semibold text-muted-foreground">Load Current (Amperes)</span>
                  <span className="font-extrabold text-foreground font-mono">{field.pump?.loadAmps} A</span>
                </div>
                <div className="flex justify-between py-1.5 border-b border-border/40">
                  <span className="font-semibold text-muted-foreground">Line Voltage / Freq</span>
                  <span className="font-extrabold text-foreground font-mono">{field.pump?.voltage} V @ {field.pump?.frequency} Hz</span>
                </div>
                <div className="flex justify-between py-1.5 font-bold">
                  <span className="font-semibold text-muted-foreground">Control Mode</span>
                  <button 
                    onClick={() => {
                      const nextMode = field.pump?.mode === "Auto" ? "Manual" : "Auto"
                      const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, pump: { ...f.pump, mode: nextMode } } : f)
                      setDb({ ...db, fields: updatedFields })
                    }}
                    className="text-emerald-600 dark:text-emerald-400 hover:underline cursor-pointer"
                  >
                    {field.pump?.mode} (Toggle)
                  </button>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Slave Boards Loop Section */}
          <Card className="shadow-xs border border-border bg-card">
            <CardHeader className="flex flex-row justify-between items-center pb-2 space-y-0">
              <div>
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Modbus Slave Boards</CardTitle>
                <CardDescription className="text-[9px] text-muted-foreground">Serial loop RTU controllers mapped over RS485</CardDescription>
              </div>
              <button 
                onClick={() => {
                  setSlaveForm({ name: "", ipAddress: `192.168.1.${100 + field.slaves.length + 1}`, port: "502", unitId: (field.slaves.length + 1).toString(), outputs: "8" })
                  setActiveModal("add-slave")
                }}
                className="flex items-center gap-1 px-2.5 py-1 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-600 rounded-lg text-[10px] font-bold cursor-pointer transition-all"
              >
                <Plus className="h-3 w-3" />
                <span>Add Slave Board</span>
              </button>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader className="bg-muted/10 border-b border-border/60">
                  <TableRow>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Slave Name</TableHead>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Modbus TCP IP Address</TableHead>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Unit ID (Port)</TableHead>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Outputs / Pins</TableHead>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Status</TableHead>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider text-right pr-6">LAN Tests & Removal</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {field.slaves?.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan="6" className="text-center py-6 text-muted-foreground text-xs italic">
                        No Modbus TCP server boards mapped yet.
                      </TableCell>
                    </TableRow>
                  ) : (
                    field.slaves.map(slave => (
                      <TableRow key={slave.id} className="hover:bg-muted/5 font-semibold text-xs">
                        <TableCell className="font-extrabold text-foreground">{slave.name}</TableCell>
                        <TableCell className="font-mono text-muted-foreground">{slave.ipAddress}</TableCell>
                        <TableCell className="text-muted-foreground">ID {slave.unitId} (:{slave.port || 502})</TableCell>
                        <TableCell className="text-muted-foreground">{slave.outputs || 8} Relays</TableCell>
                        <TableCell>
                          <span className={`inline-flex items-center gap-1 ${
                            slave.status === "Online" ? "text-green-600" : "text-red-500"
                          }`}>
                            <span className={`h-1.5 w-1.5 rounded-full ${slave.status === "Online" ? "bg-green-500" : "bg-red-500"}`}></span>
                            {slave.status}
                          </span>
                        </TableCell>
                        <TableCell className="text-right pr-6">
                          <div className="flex items-center justify-end gap-2">
                            <button 
                              onClick={() => testCommunication(slave)}
                              className="px-2 py-0.5 border border-border hover:bg-emerald-500/10 text-emerald-600 rounded text-[9px] font-bold cursor-pointer"
                            >
                              Test Comm
                            </button>
                            <button 
                              onClick={() => handleDeleteSlave(slave.id, slave.name)}
                              className="p-1 border border-border hover:bg-red-500 hover:text-white text-red-500 rounded cursor-pointer"
                              title="Delete Board"
                            >
                              <Trash2 className="h-3 w-3" />
                            </button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>

          {/* Solenoid Valves mapping */}
          <Card className="shadow-xs border border-border bg-card">
            <CardHeader className="flex flex-row justify-between items-center pb-2 space-y-0">
              <div>
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Solenoid & Drip Valves</CardTitle>
                <CardDescription className="text-[9px] text-muted-foreground">Physical flow actuating coils and Modbus registry targets</CardDescription>
              </div>
              <button 
                onClick={() => {
                  setValveForm({ name: "", type: "Drip", capacity: "12.0", modbusAddress: (40001 + field.valves.length).toString(), slaveId: field.slaves[0]?.id || "1" })
                  setActiveModal("add-valve")
                }}
                className="flex items-center gap-1 px-2.5 py-1 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-600 rounded-lg text-[10px] font-bold cursor-pointer transition-all"
              >
                <Plus className="h-3 w-3" />
                <span>Map Valve</span>
              </button>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader className="bg-muted/10 border-b border-border/60">
                  <TableRow>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Valve Name</TableHead>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Type</TableHead>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Register Address</TableHead>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Slave Link</TableHead>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider text-center">Tested State</TableHead>
                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider text-right pr-6">Pulse Test & Remove</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {field.valves?.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan="6" className="text-center py-6 text-muted-foreground text-xs italic">
                        No solenoid valves mapped to Modbus address blocks yet.
                      </TableCell>
                    </TableRow>
                  ) : (
                    field.valves.map(valve => {
                      const slave = field.slaves.find(s => s.id === valve.slaveId)
                      return (
                        <TableRow key={valve.id} className="hover:bg-muted/5 font-semibold text-xs">
                          <TableCell className="font-extrabold text-foreground">{valve.name}</TableCell>
                          <TableCell className="text-muted-foreground">{valve.type}</TableCell>
                          <TableCell className="font-mono text-muted-foreground">Coil: {valve.modbusAddress}</TableCell>
                          <TableCell className="text-muted-foreground">{slave?.name || `Slave #${valve.slaveId}`}</TableCell>
                          <TableCell className="text-center">
                            <span className={`inline-flex items-center px-1.5 py-0.2 rounded-md ${
                              valve.status === "Open" ? "bg-green-500/10 text-green-600" : "bg-muted text-muted-foreground"
                            }`}>
                              {valve.status}
                            </span>
                          </TableCell>
                          <TableCell className="text-right pr-6">
                            <div className="flex items-center justify-end gap-2">
                              <button 
                                onClick={() => testValve(valve)}
                                className="px-2 py-0.5 border border-border hover:bg-indigo-500/10 text-indigo-600 rounded text-[9px] font-bold cursor-pointer"
                              >
                                Test Pulse
                              </button>
                              <button 
                                onClick={() => handleDeleteValve(valve.id, valve.name)}
                                className="p-1 border border-border hover:bg-red-500 hover:text-white text-red-500 rounded cursor-pointer"
                                title="Remove Valve"
                              >
                                <Trash2 className="h-3 w-3" />
                              </button>
                            </div>
                          </TableCell>
                        </TableRow>
                      )
                    })
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </div>
      )}

      {/* -------------------- 3. ZONES TAB -------------------- */}
      {activeTab === "zones" && (
        <div className="flex flex-col gap-4">
          <div className="flex justify-between items-center bg-muted/10 p-3 border border-border/40 rounded-xl">
            <span className="font-bold text-foreground">{field.zones?.length || 0} Zones Grouped</span>
            <button
              onClick={() => {
                setZoneForm({ name: "", location: "", selectedValves: [] })
                setActiveModal("create-zone")
              }}
              className="flex items-center gap-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold px-3 py-1.5 rounded-lg text-xs cursor-pointer shadow-xs"
            >
              <Plus size={14} />
              <span>Create Zone</span>
            </button>
          </div>

          {field.zones?.length === 0 ? (
            <div className="text-center py-12 border border-dashed border-border rounded-2xl bg-card">
              <Layers size={24} className="text-muted-foreground mb-2" />
              <h4 className="font-bold text-foreground">No Irrigation Zones</h4>
              <p className="text-muted-foreground mt-1">Configure groups of valves into zones for scheduling.</p>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {field.zones.map(zone => {
                const zoneValves = field.valves.filter(v => zone.valveIds.includes(v.id))
                const activeValvesCount = zoneValves.filter(v => v.status === "Open").length

                return (
                  <Card key={zone.id} className="shadow-xs border border-border bg-card flex flex-col justify-between">
                    <CardHeader className="pb-2">
                      <div className="flex justify-between items-center">
                        <span className="font-extrabold text-sm text-foreground">{zone.name}</span>
                        <span className={`inline-flex items-center px-1.5 py-0.2 rounded-md text-[8px] font-bold ${
                          activeValvesCount > 0 ? "bg-green-500/10 text-green-600" : "bg-muted text-muted-foreground"
                        }`}>
                          {activeValvesCount > 0 ? "Active" : "Idle"}
                        </span>
                      </div>
                      <CardDescription className="text-[9px] font-semibold">{zone.location}</CardDescription>
                    </CardHeader>
                    
                    <CardContent className="flex flex-col gap-2 py-2 text-xs">
                      <div className="flex justify-between py-1 border-b border-border/40">
                        <span className="text-muted-foreground font-semibold">Soil Hydration</span>
                        <span className={`font-black font-mono ${zone.moisture < 25 ? "text-amber-500 animate-pulse" : "text-emerald-500"}`}>{zone.moisture}%</span>
                      </div>
                      <div className="flex flex-col gap-1 mt-1">
                        <span className="text-[9px] text-muted-foreground uppercase font-bold tracking-wider">Mapped Valves:</span>
                        <div className="flex flex-wrap gap-1">
                          {zoneValves.map(v => (
                            <span key={v.id} className="inline-flex items-center px-2 py-0.5 rounded-md text-[9px] bg-muted border border-border font-bold text-foreground">
                              {v.name}
                            </span>
                          ))}
                        </div>
                      </div>
                    </CardContent>

                    <div className="p-3 border-t border-border/60 bg-muted/5 flex gap-2">
                      <button
                        onClick={() => {
                          zoneValves.forEach(v => {
                            handleToggleValve(v.id, v.name, v.status === "Open" ? "Open" : "Closed")
                          })
                        }}
                        className="flex-1 py-1 rounded-lg border border-border text-[9px] font-bold text-foreground hover:bg-muted/20 cursor-pointer text-center"
                      >
                        {activeValvesCount > 0 ? "Shut Zone" : "Activate Zone"}
                      </button>
                      <button
                        onClick={() => {
                          if (confirm("Delete this zone configuration? Linked valves will be unmapped.")) {
                            const updatedZones = field.zones.filter(z => z.id !== zone.id)
                            const updatedValves = field.valves.map(v => v.zoneId === zone.id ? { ...v, zoneId: null } : v)
                            const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, zones: updatedZones, valves: updatedValves } : f)
                            setDb({ ...db, fields: updatedFields })
                          }
                        }}
                        className="p-1 border border-border rounded text-red-500 hover:bg-red-50 cursor-pointer"
                      >
                        <Trash2 size={12} />
                      </button>
                    </div>
                  </Card>
                )
              })}
            </div>
          )}
        </div>
      )}

      {/* -------------------- 4. IRRIGATION TAB -------------------- */}
      {activeTab === "irrigation" && (
        <div className="grid gap-6 md:grid-cols-3 text-xs">
          
          {/* Manual Valve Actuations */}
          <Card className="md:col-span-2 shadow-xs border border-border bg-card">
            <CardHeader className="flex flex-row justify-between items-center pb-2 space-y-0 border-b border-border/40 mb-3">
              <div>
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Manual Valve Control</CardTitle>
                <CardDescription className="text-[9px] text-muted-foreground">Direct manual override of solenoid coils</CardDescription>
              </div>
              <button 
                onClick={handleEmergencyStop}
                className="flex items-center gap-1 px-3 py-1.5 bg-red-600 hover:bg-red-700 text-white rounded-lg text-[10px] font-black uppercase tracking-wider cursor-pointer shadow-md shadow-red-500/10 animate-bounce"
              >
                <AlertTriangle className="h-3.5 w-3.5" />
                <span>Emergency Stop</span>
              </button>
            </CardHeader>
            <CardContent className="flex flex-col gap-3 py-1">
              {field.valves?.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground italic">
                  No valves mapped. Go to the "Devices" tab to add valves.
                </div>
              ) : (
                field.valves.map(valve => (
                  <div key={valve.id} className="p-3 rounded-xl border border-border/80 flex items-center justify-between font-bold bg-muted/5">
                    <div>
                      <div className="font-extrabold text-[11px] text-foreground">{valve.name}</div>
                      <div className="text-[9px] text-muted-foreground font-semibold mt-0.5">Modbus Coil: {valve.modbusAddress} | Cap: {valve.capacity} L/m</div>
                    </div>
                    
                    <div className="flex items-center gap-3">
                      {valve.status === "Open" && (
                        <span className="text-[10px] text-blue-600 dark:text-blue-400 font-mono font-black animate-pulse">
                          {valve.flowRate.toFixed(1)} L/m
                        </span>
                      )}
                      <button
                        onClick={() => handleToggleValve(valve.id, valve.name, valve.status)}
                        className={`px-3 py-1.5 rounded-lg text-[10px] font-extrabold transition-all cursor-pointer ${
                          valve.status === "Open" 
                            ? "bg-red-500/10 text-red-600 border border-red-500/15" 
                            : "bg-green-500/10 text-green-600 border border-green-500/15"
                        }`}
                      >
                        {valve.status === "Open" ? "Close Valve" : "Open Valve"}
                      </button>
                    </div>
                  </div>
                ))
              )}
            </CardContent>
          </Card>

          {/* Running Zones & Recent Runs */}
          <div className="flex flex-col gap-6">
            
            {/* Running Zones Card */}
            <Card className="shadow-xs border border-border bg-card">
              <CardHeader>
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Running Zones</CardTitle>
              </CardHeader>
              <CardContent className="flex flex-col gap-2">
                {field.zones?.filter(zone => field.valves.some(v => zone.valveIds.includes(v.id) && v.status === "Open")).length === 0 ? (
                  <div className="text-center py-4 text-muted-foreground italic text-[10px]">
                    No zone lines currently active.
                  </div>
                ) : (
                  field.zones.filter(zone => field.valves.some(v => zone.valveIds.includes(v.id) && v.status === "Open")).map(zone => (
                    <div key={zone.id} className="p-3 bg-blue-500/5 border border-blue-500/10 text-blue-800 dark:text-blue-300 rounded-xl flex items-center justify-between font-bold">
                      <div>
                        <div className="text-[10px] text-foreground">{zone.name}</div>
                        <div className="text-[8px] text-muted-foreground mt-0.5">Hydration level: {zone.moisture}%</div>
                      </div>
                      <div className="flex items-center gap-1 text-[10px] font-black text-blue-600 dark:text-blue-400 font-mono">
                        <Droplet className="h-3.5 w-3.5 animate-bounce" />
                        <span>Active</span>
                      </div>
                    </div>
                  ))
                )}
              </CardContent>
            </Card>

            {/* Run History Card */}
            <Card className="shadow-xs border border-border bg-card">
              <CardHeader>
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Irrigation History</CardTitle>
              </CardHeader>
              <CardContent className="flex flex-col gap-3.5">
                {field.irrigationHistory?.length === 0 ? (
                  <div className="text-center py-4 text-muted-foreground italic text-[10px]">
                    No irrigation logs found.
                  </div>
                ) : (
                  field.irrigationHistory.map((run) => (
                    <div key={run.id} className="text-[10px] border-b border-border/40 pb-2 last:border-0 last:pb-0 font-semibold">
                      <div className="flex items-center justify-between text-[9px] text-muted-foreground">
                        <span>{run.date}</span>
                        <span className="font-extrabold text-green-600">{run.status}</span>
                      </div>
                      <div className="font-extrabold text-foreground mt-0.5">{run.zone}</div>
                      <div className="text-[9px] text-muted-foreground font-medium mt-0.5">Duration: {run.duration} | Water Used: {run.waterUsed}</div>
                    </div>
                  ))
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      )}

      {/* -------------------- 5. SCHEDULES TAB -------------------- */}
      {activeTab === "schedules" && (
        <div className="grid gap-6 md:grid-cols-3 text-xs">
          
          {/* Schedule List */}
          <div className="md:col-span-2 flex flex-col gap-4">
            {field.schedules?.length === 0 ? (
              <div className="text-center py-12 border border-dashed border-border rounded-2xl bg-card">
                <Calendar size={24} className="text-muted-foreground mb-2" />
                <h4 className="font-bold text-foreground">No Automations Scheduled</h4>
                <p className="text-muted-foreground mt-1">Configure parallel time-based, RTC, or Timer schedules on the right.</p>
              </div>
            ) : (
              field.schedules.map(sched => (
                <Card key={sched.id} className={`shadow-xs border border-border hover:border-emerald-500/10 transition-all bg-card ${
                  !sched.active ? "opacity-60 bg-muted/20" : ""
                }`}>
                  <CardContent className="p-4 flex flex-col gap-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className={`p-2.5 rounded-xl border ${
                          sched.scheduleType === "rtcBased" 
                            ? "bg-purple-500/10 text-purple-600 dark:text-purple-400 border-purple-500/20"
                            : sched.scheduleType === "timerBased"
                            ? "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20"
                            : "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20"
                        }`}>
                          <Clock className="h-4.5 w-4.5" />
                        </div>
                        <div>
                          <h3 className="text-xs font-bold text-foreground">{sched.name}</h3>
                          <div className="text-[10px] text-muted-foreground mt-0.5 flex flex-wrap gap-x-2 gap-y-0.5">
                            <span className="font-bold text-emerald-700 dark:text-emerald-400">Target: {sched.zone}</span>
                            <span>•</span>
                            <span>Start: {sched.time}</span>
                            <span>•</span>
                            <span>Total: {sched.duration} min</span>
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center gap-3">
                        <span className={`text-[8px] font-extrabold px-1.5 py-0.2 rounded-md uppercase tracking-wider font-mono ${
                          sched.scheduleType === "rtcBased"
                            ? "bg-purple-100 dark:bg-purple-950/40 text-purple-700 dark:text-purple-400 border border-purple-500/10"
                            : sched.scheduleType === "timerBased"
                            ? "bg-amber-100 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border border-amber-500/10"
                            : "bg-emerald-100 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-500/10"
                        }`}>
                          {sched.scheduleType === "rtcBased" ? "RTC SEQ" : sched.scheduleType === "timerBased" ? "TIMER SEQ" : "PARALLEL"}
                        </span>
                        
                        <span className="text-[8px] font-bold bg-muted text-muted-foreground px-2 py-0.5 rounded-md uppercase tracking-wider font-mono">
                          {sched.days}
                        </span>

                        <button 
                          onClick={() => {
                            const updatedSchedules = field.schedules.map(s => s.id === sched.id ? { ...s, active: !s.active } : s)
                            const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, schedules: updatedSchedules } : f)
                            setDb({ ...db, fields: updatedFields })
                          }}
                          className={`relative inline-flex h-4.5 w-8 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out outline-hidden ${
                            sched.active ? "bg-emerald-500" : "bg-border"
                          }`}
                        >
                          <span className={`pointer-events-none inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow-sm ring-0 transition duration-200 ease-in-out ${
                            sched.active ? "translate-x-3.5" : "translate-x-0"
                          }`} />
                        </button>

                        <button 
                          onClick={() => {
                            if (confirm("Delete this schedule?")) {
                              const updatedSchedules = field.schedules.filter(s => s.id !== sched.id)
                              const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, schedules: updatedSchedules } : f)
                              setDb({ ...db, fields: updatedFields })
                            }
                          }}
                          className="p-1 text-muted-foreground hover:text-red-500 rounded transition-colors"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>

          {/* Add Schedule Form */}
          <Card className="shadow-xs border border-border bg-card">
            <CardHeader className="pb-2">
              <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Create Schedule Rule</CardTitle>
            </CardHeader>
            <CardContent>
              <form 
                onSubmit={(e) => {
                  e.preventDefault()
                  if (!schedForm.name.trim()) return

                  const newSched = {
                    id: Date.now(),
                    name: schedForm.name,
                    scheduleType: schedForm.type,
                    zone: schedForm.type === "timeBased" ? schedForm.zoneName || field.zones[0]?.name || "Main Zone" : "Sequential Loop",
                    time: schedForm.startTime,
                    duration: parseInt(schedForm.duration) || 15,
                    days: schedForm.days,
                    active: true
                  }

                  const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, schedules: [...f.schedules, newSched] } : f)
                  let updatedDb = { ...db, fields: updatedFields }
                  updatedDb = addLog(updatedDb, "Super Admin", "Schedule Programmed", `Created automated schedule: ${newSched.name} on ${field.name}`)
                  setDb(updatedDb)

                  setSchedForm({
                    name: "", type: "timeBased", zoneName: "", startTime: "08:00 AM", duration: 15, days: "Daily", rtcZones: [], timerSequence: []
                  })
                }}
                className="flex flex-col gap-3 font-bold text-xs"
              >
                <div className="flex flex-col gap-1">
                  <label className="text-muted-foreground">Schedule Rule Name</label>
                  <input
                    type="text"
                    required
                    value={schedForm.name}
                    onChange={(e) => setSchedForm({ ...schedForm, name: e.target.value })}
                    className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/25"
                    placeholder="Morning Sprinkler Run"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Automation Mode</label>
                  <div className="grid grid-cols-3 gap-1 bg-muted/50 p-0.5 rounded-lg text-[9px] font-bold">
                    <button
                      type="button"
                      onClick={() => setSchedForm({ ...schedForm, type: "timeBased" })}
                      className={`py-1.5 rounded-md transition-all ${
                        schedForm.type === "timeBased" 
                          ? "bg-background text-foreground shadow-2xs" 
                          : "text-muted-foreground hover:text-foreground"
                      }`}
                    >
                      Parallel (Time)
                    </button>
                    <button
                      type="button"
                      onClick={() => setSchedForm({ ...schedForm, type: "rtcBased" })}
                      className={`py-1.5 rounded-md transition-all ${
                        schedForm.type === "rtcBased" 
                          ? "bg-background text-foreground shadow-2xs" 
                          : "text-muted-foreground hover:text-foreground"
                      }`}
                    >
                      RTC (Sequence)
                    </button>
                    <button
                      type="button"
                      onClick={() => setSchedForm({ ...schedForm, type: "timerBased" })}
                      className={`py-1.5 rounded-md transition-all ${
                        schedForm.type === "timerBased" 
                          ? "bg-background text-foreground shadow-2xs" 
                          : "text-muted-foreground hover:text-foreground"
                      }`}
                    >
                      Timer (Seq)
                    </button>
                  </div>
                </div>

                {schedForm.type === "timeBased" && (
                  <div className="flex flex-col gap-1">
                    <label className="text-muted-foreground">Target Field Zone</label>
                    <select
                      value={schedForm.zoneName}
                      onChange={(e) => setSchedForm({ ...schedForm, zoneName: e.target.value })}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500"
                    >
                      <option value="">Select Zone</option>
                      {field.zones?.map(z => (
                        <option key={z.id} value={z.name}>{z.name}</option>
                      ))}
                    </select>
                  </div>
                )}

                <div className="grid grid-cols-2 gap-3">
                  <div className="flex flex-col gap-1">
                    <label className="text-muted-foreground">Start Time</label>
                    <input
                      type="text"
                      required
                      value={schedForm.startTime}
                      onChange={(e) => setSchedForm({ ...schedForm, startTime: e.target.value })}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 font-mono text-center"
                      placeholder="08:00 AM"
                    />
                  </div>
                  <div className="flex flex-col gap-1">
                    <label className="text-muted-foreground">Duration (mins)</label>
                    <input
                      type="number"
                      required
                      value={schedForm.duration}
                      onChange={(e) => setSchedForm({ ...schedForm, duration: e.target.value })}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 text-center"
                    />
                  </div>
                </div>

                <div className="flex flex-col gap-1">
                  <label className="text-muted-foreground">Watering Frequency Days</label>
                  <input
                    type="text"
                    required
                    value={schedForm.days}
                    onChange={(e) => setSchedForm({ ...schedForm, days: e.target.value })}
                    className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500"
                    placeholder="Daily or Mon, Wed, Fri"
                  />
                </div>

                <button 
                  type="submit"
                  className="w-full py-2.5 bg-gradient-to-r from-emerald-600 to-teal-500 text-white rounded-lg hover:from-emerald-700 hover:to-teal-600 font-bold transition-all shadow-md shadow-emerald-500/10 cursor-pointer text-center"
                >
                  Schedule Program
                </button>
              </form>
            </CardContent>
          </Card>
        </div>
      )}

      {/* -------------------- 6. MONITORING TAB -------------------- */}
      {activeTab === "monitoring" && (
        <div className="grid gap-6 md:grid-cols-3 text-xs">
          
          {/* Telemetry charts list */}
          <div className="md:col-span-2 flex flex-col gap-6">
            {/* Live moisture trend */}
            <Card className="shadow-xs border border-border bg-card">
              <CardHeader className="pb-2">
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Real-time Soil Moisture Trend</CardTitle>
                <CardDescription className="text-[9px] text-muted-foreground">Historical charts mapping zone moisture levels</CardDescription>
              </CardHeader>
              <CardContent className="h-[180px] flex items-end">
                <div className="w-full h-full relative flex flex-col justify-between pt-2">
                  <svg className="w-full h-full overflow-visible" viewBox="0 0 500 150" preserveAspectRatio="none">
                    <defs>
                      <linearGradient id="moist-gradient" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#10b981" stopOpacity="0.2" />
                        <stop offset="100%" stopColor="#10b981" stopOpacity="0.0" />
                      </linearGradient>
                    </defs>
                    {/* Grid lines */}
                    <line x1="0" y1="37" x2="500" y2="37" stroke="currentColor" strokeOpacity="0.05" strokeDasharray="3" />
                    <line x1="0" y1="75" x2="500" y2="75" stroke="currentColor" strokeOpacity="0.05" strokeDasharray="3" />
                    <line x1="0" y1="112" x2="500" y2="112" stroke="currentColor" strokeOpacity="0.05" strokeDasharray="3" />
                    {/* Area */}
                    <path d="M 0,150 L 0,80 Q 120,40 250,90 T 500,60 L 500,150 Z" fill="url(#moist-gradient)" />
                    {/* Line */}
                    <path d="M 0,80 Q 120,40 250,90 T 500,60" fill="none" stroke="#10b981" strokeWidth="2.5" strokeLinecap="round" />
                    <circle cx="250" cy="90" r="4.5" fill="#10b981" stroke="white" strokeWidth="1.5" />
                    <circle cx="500" cy="60" r="4.5" fill="#10b981" stroke="white" strokeWidth="1.5" />
                  </svg>
                  <div className="flex justify-between text-[8px] text-muted-foreground font-mono mt-2 border-t border-border/45 pt-1.5">
                    <span>12:00 PM (40%)</span>
                    <span>02:00 PM (41%)</span>
                    <span>04:00 PM (43.5%)</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* IoT Console Terminal */}
            <Card className="shadow-xs border border-border bg-card">
              <CardHeader className="pb-2">
                <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground flex items-center gap-1">
                  <Terminal className="h-4.5 w-4.5 text-emerald-500" />
                  <span>IoT Command Console</span>
                </CardTitle>
                <CardDescription className="text-[9px] text-muted-foreground">Direct connection feed loop interface with Master</CardDescription>
              </CardHeader>
              <CardContent className="flex flex-col gap-3 font-mono">
                <div className="h-48 overflow-y-auto bg-[#1e1e24] text-emerald-400 p-4.5 rounded-lg border border-border/80 text-[10px] leading-relaxed flex flex-col gap-1.5 select-text">
                  {consoleOutput.map((outLine, idx) => (
                    <div key={idx} className={outLine.startsWith(">") ? "text-slate-400" : outLine.includes("[CRITICAL]") ? "text-red-400" : ""}>
                      {outLine}
                    </div>
                  ))}
                </div>
                <form onSubmit={executeConsoleCommand} className="flex gap-2">
                  <input
                    type="text"
                    value={consoleInput}
                    onChange={(e) => setConsoleInput(e.target.value)}
                    className="flex-1 p-2 bg-background border border-border rounded-lg text-foreground outline-hidden focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-[10px]"
                    placeholder="E.g. SCAN, STATUS, STOP, OPEN 201..."
                  />
                  <button type="submit" className="px-4 bg-emerald-600 text-white rounded-lg font-bold hover:bg-emerald-700 cursor-pointer text-[10px]">
                    Send Command
                  </button>
                </form>
              </CardContent>
            </Card>
          </div>

          {/* Heartbeat feed */}
          <Card className="shadow-xs border border-border bg-card">
            <CardHeader>
              <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">MQTT Broker Heartbeats</CardTitle>
              <CardDescription className="text-[9px] text-muted-foreground">Raw heartbeats incoming over MQTT broker</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex flex-col gap-2 font-mono text-[9px] bg-muted/30 p-3 rounded-lg border border-border/50 max-h-96 overflow-y-auto leading-normal select-text">
                {heartbeatLogs.map((logLine, idx) => (
                  <div key={idx} className="border-b border-border/30 pb-1.5 last:border-0 last:pb-0">
                    {logLine}
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* -------------------- 7. SETTINGS TAB -------------------- */}
      {activeTab === "settings" && (
        <div className="grid gap-6 md:grid-cols-3 text-xs">
          
          {/* Field Settings Form */}
          <Card className="md:col-span-2 shadow-xs border border-border bg-card">
            <CardHeader>
              <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Field Parameters Configuration</CardTitle>
            </CardHeader>
            <CardContent>
              <form 
                onSubmit={(e) => {
                  e.preventDefault()
                  let updatedDb = { ...db }
                  updatedDb = addLog(updatedDb, "Super Admin", "Field Config Updated", `Updated crop metrics on field ${field.name}`)
                  setDb(updatedDb)
                  alert("Field configurations updated successfully.")
                }}
                className="flex flex-col gap-4 font-bold"
              >
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Rename Field</label>
                  <input
                    type="text"
                    required
                    value={field.name}
                    onChange={(e) => {
                      const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, name: e.target.value } : f)
                      setDb({ ...db, fields: updatedFields })
                    }}
                    className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Area size</label>
                    <input
                      type="text"
                      required
                      value={field.area}
                      onChange={(e) => {
                        const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, area: e.target.value } : f)
                        setDb({ ...db, fields: updatedFields })
                      }}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Crop Variety Type</label>
                    <input
                      type="text"
                      required
                      value={field.cropType}
                      onChange={(e) => {
                        const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, cropType: e.target.value } : f)
                        setDb({ ...db, fields: updatedFields })
                      }}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Soil Profile Type</label>
                    <select
                      value={field.soilType}
                      onChange={(e) => {
                        const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, soilType: e.target.value } : f)
                        setDb({ ...db, fields: updatedFields })
                      }}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 transition-all cursor-pointer font-bold"
                    >
                      <option value="Sandy Loam">Sandy Loam</option>
                      <option value="Clay Loam">Clay Loam</option>
                      <option value="Black Cotton Soil">Black Cotton Soil</option>
                      <option value="Peat Mix">Peat Mix</option>
                    </select>
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Water Source</label>
                    <input
                      type="text"
                      required
                      value={field.waterSource}
                      onChange={(e) => {
                        const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, waterSource: e.target.value } : f)
                        setDb({ ...db, fields: updatedFields })
                      }}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden"
                    />
                  </div>
                </div>

                <button 
                  type="submit"
                  className="px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold transition-all shadow-xs w-fit cursor-pointer"
                >
                  Save Configurations
                </button>
              </form>
            </CardContent>
          </Card>

          {/* Master Board Device Configuration */}
          <Card className="md:col-span-2 shadow-xs border border-border bg-card">
            <CardHeader>
              <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">IoT Master Board Device Configuration</CardTitle>
            </CardHeader>
            <CardContent>
              <form 
                onSubmit={(e) => {
                  e.preventDefault()
                  let updatedDb = { ...db }
                  updatedDb = addLog(updatedDb, "Super Admin", "IoT Gateway Config Updated", `Updated Master Board settings on field ${field.name}`)
                  setDb(updatedDb)
                  alert("IoT Master Board configurations updated successfully.")
                }}
                className="flex flex-col gap-4 font-bold"
              >
                <div className="grid grid-cols-2 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Master Board Model</label>
                    <input
                      type="text"
                      required
                      value={field.masterDevice?.model || ""}
                      onChange={(e) => {
                        const updatedDevice = { ...field.masterDevice, model: e.target.value }
                        const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, masterDevice: updatedDevice } : f)
                        setDb({ ...db, fields: updatedFields })
                      }}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/25 font-semibold text-xs text-foreground"
                      placeholder="Raspberry Pi 4 Model B"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">MQTT Broker Connection Topic</label>
                    <input
                      type="text"
                      required
                      value={field.masterDevice?.mqttTopic || ""}
                      onChange={(e) => {
                        const updatedDevice = { ...field.masterDevice, mqttTopic: e.target.value }
                        const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, masterDevice: updatedDevice } : f)
                        setDb({ ...db, fields: updatedFields })
                      }}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/25 font-mono text-xs text-foreground"
                      placeholder="macsoft/drip/field/101"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Controller Local IP</label>
                    <input
                      type="text"
                      required
                      value={field.masterDevice?.ipAddress || ""}
                      onChange={(e) => {
                        const updatedDevice = { ...field.masterDevice, ipAddress: e.target.value }
                        const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, masterDevice: updatedDevice } : f)
                        setDb({ ...db, fields: updatedFields })
                      }}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/25 font-mono text-xs text-foreground"
                      placeholder="192.168.1.65"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Firmware OTA Version</label>
                    <input
                      type="text"
                      required
                      value={field.masterDevice?.firmware || ""}
                      onChange={(e) => {
                        const updatedDevice = { ...field.masterDevice, firmware: e.target.value }
                        const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, masterDevice: updatedDevice } : f)
                        setDb({ ...db, fields: updatedFields })
                      }}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/25 font-mono text-xs text-foreground"
                      placeholder="v2.4.2-stable"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Connection Latency (ms)</label>
                    <input
                      type="text"
                      required
                      value={field.masterDevice?.latency || ""}
                      onChange={(e) => {
                        const updatedDevice = { ...field.masterDevice, latency: e.target.value }
                        const updatedFields = db.fields.map(f => f.id === selectedFieldId ? { ...f, masterDevice: updatedDevice } : f)
                        setDb({ ...db, fields: updatedFields })
                      }}
                      className="p-2 border border-border bg-background rounded-lg outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/25 font-mono text-xs text-foreground"
                      placeholder="45ms"
                    />
                  </div>
                </div>

                <button 
                  type="submit"
                  className="px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold transition-all shadow-xs w-fit cursor-pointer"
                >
                  Save Device Configuration
                </button>
              </form>
            </CardContent>
          </Card>

          {/* Modbus registers mappings */}
          <Card className="shadow-xs border border-border bg-card">
            <CardHeader>
              <CardTitle className="text-xs font-extrabold uppercase tracking-wider text-foreground">Modbus Register Registry</CardTitle>
              <CardDescription className="text-[9px] text-muted-foreground">Registry address maps parsed by gateway controller</CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              {field.modbusRegisters?.length === 0 ? (
                <div className="text-center py-4 text-muted-foreground italic text-[10px]">
                  No coils mapped yet. Add slave devices or valves to generate registries.
                </div>
              ) : (
                field.modbusRegisters.map((reg) => (
                  <div key={reg.register} className="p-2.5 rounded-lg border border-border bg-muted/15 flex items-center justify-between gap-2">
                    <div className="min-w-0">
                      <div className="flex items-center gap-1">
                        <span className="font-mono text-emerald-600 dark:text-emerald-400 font-extrabold text-[10.5px]">{reg.register}</span>
                        <span className="text-[7.5px] uppercase font-bold bg-muted text-muted-foreground px-1 py-0.2 rounded border border-border/60">{reg.type}</span>
                      </div>
                      <div className="text-[9px] text-muted-foreground font-semibold mt-0.5 truncate">{reg.description}</div>
                    </div>
                    
                    <div className="shrink-0 flex items-center gap-1.5">
                      <input
                        type="text"
                        value={reg.value}
                        onChange={(e) => updateRegisterValue(reg.register, e.target.value)}
                        className="w-16 p-1 border border-border bg-background rounded text-center font-mono font-bold text-[10px] text-foreground"
                      />
                    </div>
                  </div>
                ))
              )}
            </CardContent>
          </Card>
        </div>
      )}

      {/* -------------------- DYNAMIC MODALS -------------------- */}

      {/* Add Slave Modal */}
      {activeModal === "add-slave" && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-card text-card-foreground w-full max-w-md rounded-xl shadow-lg border border-border flex flex-col animate-in zoom-in-95 duration-200 text-xs font-bold">
            <div className="flex items-center justify-between p-6 border-b border-border">
              <h3 className="text-lg font-bold text-foreground">Add Modbus Slave Board</h3>
              <button onClick={() => setActiveModal(null)} className="text-muted-foreground hover:text-foreground transition-colors p-1 rounded-md hover:bg-muted">
                <X className="h-5 w-5" />
              </button>
            </div>
            
            <form onSubmit={handleAddSlave} className="p-6 flex flex-col gap-4 text-xs font-semibold">
              <div className="flex flex-col gap-1.5">
                <label className="text-muted-foreground">Slave Board Name</label>
                <input
                  type="text"
                  required
                  value={slaveForm.name}
                  onChange={(e) => setSlaveForm({ ...slaveForm, name: e.target.value })}
                  className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold"
                  placeholder="E.g. Solenoid Board #2"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Modbus TCP IP Address</label>
                  <input
                    type="text"
                    required
                    value={slaveForm.ipAddress}
                    onChange={(e) => setSlaveForm({ ...slaveForm, ipAddress: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold font-mono text-center"
                    placeholder="192.168.1.103"
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Port (default 502)</label>
                  <input
                    type="number"
                    required
                    value={slaveForm.port}
                    onChange={(e) => setSlaveForm({ ...slaveForm, port: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold font-mono text-center"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Unit ID Address</label>
                  <input
                    type="number"
                    required
                    value={slaveForm.unitId}
                    onChange={(e) => setSlaveForm({ ...slaveForm, unitId: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold font-mono text-center"
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Outputs Count (Relays)</label>
                  <input
                    type="number"
                    required
                    value={slaveForm.outputs}
                    onChange={(e) => setSlaveForm({ ...slaveForm, outputs: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold font-mono text-center"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-3 mt-4">
                <button type="button" onClick={() => setActiveModal(null)} className="px-4 py-2 rounded-lg border border-border bg-background hover:bg-accent text-foreground font-bold transition-all cursor-pointer">
                  Cancel
                </button>
                <button type="submit" className="px-4 py-2 rounded-lg bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white font-bold transition-all cursor-pointer shadow-md shadow-emerald-500/10">
                  Register Slave
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Valve Modal */}
      {activeModal === "add-valve" && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-card text-card-foreground w-full max-w-md rounded-xl shadow-lg border border-border flex flex-col animate-in zoom-in-95 duration-200 text-xs font-bold">
            <div className="flex items-center justify-between p-6 border-b border-border">
              <h3 className="text-lg font-bold text-foreground">Map Solenoid Flow Valve</h3>
              <button onClick={() => setActiveModal(null)} className="text-muted-foreground hover:text-foreground p-1 rounded-md hover:bg-muted">
                <X className="h-5 w-5" />
              </button>
            </div>
            
            <form onSubmit={handleAddValve} className="p-6 flex flex-col gap-4 text-xs font-semibold">
              <div className="flex flex-col gap-1.5">
                <label className="text-muted-foreground">Valve Identifier Name</label>
                <input
                  type="text"
                  required
                  value={valveForm.name}
                  onChange={(e) => setValveForm({ ...valveForm, name: e.target.value })}
                  className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold"
                  placeholder="E.g. South Citrus Spray Valve"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Valve Category Type</label>
                  <select
                    value={valveForm.type}
                    onChange={(e) => setValveForm({ ...valveForm, type: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold cursor-pointer"
                  >
                    <option value="Drip">Drip Line</option>
                    <option value="Sprinkler">Sprinkler</option>
                    <option value="Solenoid">General Solenoid</option>
                    <option value="Mister">Misting Valve</option>
                  </select>
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Capacity flowRate (L/m)</label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={valveForm.capacity}
                    onChange={(e) => setValveForm({ ...valveForm, capacity: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold font-mono text-center"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Modbus register Coil Address</label>
                  <input
                    type="text"
                    required
                    value={valveForm.modbusAddress}
                    onChange={(e) => setValveForm({ ...valveForm, modbusAddress: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold font-mono text-center"
                    placeholder="E.g. 40003"
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Associated Slave Board</label>
                  <select
                    value={valveForm.slaveId}
                    onChange={(e) => setValveForm({ ...valveForm, slaveId: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold cursor-pointer"
                  >
                    {field.slaves?.map(s => (
                      <option key={s.id} value={s.id}>{s.name} (ID: {s.address})</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="flex justify-end gap-3 mt-4">
                <button type="button" onClick={() => setActiveModal(null)} className="px-4 py-2 rounded-lg border border-border bg-background hover:bg-accent text-foreground font-bold transition-all cursor-pointer">
                  Cancel
                </button>
                <button type="submit" className="px-4 py-2 rounded-lg bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white font-bold transition-all cursor-pointer shadow-md shadow-emerald-500/10">
                  Map Valve Address
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Create Zone Modal */}
      {activeModal === "create-zone" && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-card text-card-foreground w-full max-w-md rounded-xl shadow-lg border border-border flex flex-col animate-in zoom-in-95 duration-200 text-xs font-bold">
            <div className="flex items-center justify-between p-6 border-b border-border">
              <h3 className="text-lg font-bold text-foreground">Create Irrigation Zone</h3>
              <button onClick={() => setActiveModal(null)} className="text-muted-foreground hover:text-foreground p-1 rounded-md hover:bg-muted">
                <X className="h-5 w-5" />
              </button>
            </div>
            
            <form onSubmit={handleCreateZone} className="p-6 flex flex-col gap-4 text-xs font-semibold">
              <div className="flex flex-col gap-1.5">
                <label className="text-muted-foreground">Zone Sector Name</label>
                <input
                  type="text"
                  required
                  value={zoneForm.name}
                  onChange={(e) => setZoneForm({ ...zoneForm, name: e.target.value })}
                  className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold"
                  placeholder="E.g. South Sugarcane Block B"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-muted-foreground">Line / Row Coverage Location</label>
                <input
                  type="text"
                  required
                  value={zoneForm.location}
                  onChange={(e) => setZoneForm({ ...zoneForm, location: e.target.value })}
                  className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold"
                  placeholder="E.g. Rows 30-45"
                />
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-muted-foreground block">Assign Valves (Multi-select)</label>
                <div className="flex flex-wrap gap-2 max-h-36 overflow-y-auto p-2 border border-border bg-background rounded-lg">
                  {field.valves?.filter(v => !v.zoneId).map(valve => {
                    const isChecked = zoneForm.selectedValves.includes(valve.id.toString())
                    return (
                      <label key={valve.id} className="flex items-center gap-1.5 px-2.5 py-1 rounded bg-muted/30 border border-border text-[10px] font-bold text-foreground select-none cursor-pointer">
                        <input
                          type="checkbox"
                          checked={isChecked}
                          onChange={(e) => {
                            const valIdStr = valve.id.toString()
                            if (e.target.checked) {
                              setZoneForm({ ...zoneForm, selectedValves: [...zoneForm.selectedValves, valIdStr] })
                            } else {
                              setZoneForm({ ...zoneForm, selectedValves: zoneForm.selectedValves.filter(id => id !== valIdStr) })
                            }
                          }}
                          className="accent-emerald-600 rounded"
                        />
                        <span>{valve.name}</span>
                      </label>
                    )
                  })}
                  {field.valves?.filter(v => !v.zoneId).length === 0 && (
                    <span className="text-[10px] text-muted-foreground italic">No unassigned valves available.</span>
                  )}
                </div>
              </div>

              <div className="flex justify-end gap-3 mt-4">
                <button type="button" onClick={() => setActiveModal(null)} className="px-4 py-2 rounded-lg border border-border bg-background hover:bg-accent text-foreground font-bold transition-all cursor-pointer">
                  Cancel
                </button>
                <button type="submit" className="px-4 py-2 rounded-lg bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white font-bold transition-all cursor-pointer shadow-md shadow-emerald-500/10">
                  Onboard Zone
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  )
}

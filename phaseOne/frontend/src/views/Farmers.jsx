import React, { useState, useEffect } from "react"
import { 
  Users as UsersIcon, 
  Plus, 
  Pencil, 
  Search, 
  Ban, 
  CheckCircle2, 
  ShieldCheck, 
  MapPin, 
  Eye, 
  X, 
  Phone, 
  Mail, 
  ArrowLeft,
  ArrowRight,
  Sprout,
  Wrench,
  Activity,
  User,
  ExternalLink
} from "lucide-react"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
import { addLog } from "@/lib/mockDb"

export default function Farmers({ navigate, db, setDb, selectedFarmerId, setSelectedFarmerId, setSelectedFieldId }) {
  const [viewMode, setViewMode] = useState("list") // list, details
  const [searchQuery, setSearchQuery] = useState("")
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [modalMode, setModalMode] = useState("create") // create, edit, add-field
  
  // Tab within details view
  const [activeDetailTab, setActiveDetailTab] = useState("overview") // overview, fields, support, activity

  // Form states for farmer
  const [formData, setFormData] = useState({
    name: "", phone: "", email: "", state: "Maharashtra", district: "", village: "", pincode: "", distributor: "Macro Drip Distributors", status: "Active", servicePlan: "Starter"
  })

  // Form states for field
  const [fieldFormData, setFieldFormData] = useState({
    name: "", location: "", area: "", soilType: "Sandy Loam", cropType: "", waterSource: "Well Water", masterMqttTopic: ""
  })

  const farmers = db?.farmers || []
  const selectedFarmer = farmers.find(f => f.id === selectedFarmerId)

  // Listen to Quick Actions from Dashboard
  useEffect(() => {
    const checkRegisterFlag = sessionStorage.getItem("drip_open_register_modal")
    const checkFieldFlag = sessionStorage.getItem("drip_open_add_field_modal")

    if (checkRegisterFlag === "true") {
      sessionStorage.removeItem("drip_open_register_modal")
      handleOpenModal("create")
    } else if (checkFieldFlag === "true") {
      sessionStorage.removeItem("drip_open_add_field_modal")
      // Ensure we are viewing details of the farmer first
      setViewMode("details")
      setActiveDetailTab("fields")
      handleOpenModal("add-field")
    }
  }, [selectedFarmerId])

  // Filter based on search query
  const filteredFarmers = farmers.filter(f =>
    f.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    f.phone.includes(searchQuery) ||
    f.district.toLowerCase().includes(searchQuery.toLowerCase()) ||
    f.village.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const handleOpenModal = (mode, farmer = null) => {
    setModalMode(mode)
    if (mode === "edit" && farmer) {
      setFormData({
        name: farmer.name, phone: farmer.phone, email: farmer.email, state: farmer.state, district: farmer.district, village: farmer.village, pincode: farmer.pincode, distributor: farmer.distributor, status: farmer.status, servicePlan: farmer.servicePlan
      })
    } else if (mode === "create") {
      setFormData({
        name: "", phone: "", email: "", state: "Maharashtra", district: "", village: "", pincode: "", distributor: "Macro Drip Distributors", status: "Active", servicePlan: "Starter"
      })
    } else if (mode === "add-field") {
      setFieldFormData({
        name: "", location: "", area: "", soilType: "Sandy Loam", cropType: "", waterSource: "Well Water", masterMqttTopic: `macsoft/drip/field/${Math.floor(100 + Math.random() * 900)}`
      })
    }
    setIsModalOpen(true)
  }

  const handleCloseModal = () => {
    setIsModalOpen(false)
  }

  const handleSaveFarmer = (e) => {
    e.preventDefault()
    if (modalMode === "create") {
      const newId = Date.now()
      const newFarmer = {
        id: newId,
        ...formData,
        registeredAt: new Date().toISOString().split("T")[0]
      }
      
      const updatedFarmers = [newFarmer, ...db.farmers]
      let updatedDb = { ...db, farmers: updatedFarmers }
      updatedDb = addLog(updatedDb, "Super Admin", "Farmer Onboarded", `Registered new farmer: ${newFarmer.name}`)
      setDb(updatedDb)
      setSelectedFarmerId(newId)
      setViewMode("details")
    } else if (modalMode === "edit") {
      const updatedFarmers = db.farmers.map(f => f.id === selectedFarmerId ? { ...f, ...formData } : f)
      let updatedDb = { ...db, farmers: updatedFarmers }
      updatedDb = addLog(updatedDb, "Super Admin", "Farmer Profile Updated", `Updated farmer contact for: ${formData.name}`)
      setDb(updatedDb)
    }
    handleCloseModal()
  }

  const handleAddField = (e) => {
    e.preventDefault()
    const newFieldId = Date.now()
    const newField = {
      id: newFieldId,
      farmerId: selectedFarmerId,
      name: fieldFormData.name,
      location: fieldFormData.location || "N/A",
      area: fieldFormData.area || "5.0 acres",
      soilType: fieldFormData.soilType,
      cropType: fieldFormData.cropType || "General Crops",
      waterSource: fieldFormData.waterSource,
      masterDevice: {
        model: "Raspberry Pi 4 Model B",
        status: "Online",
        connectionType: "MQTT Broker",
        mqttTopic: fieldFormData.masterMqttTopic,
        latency: "45ms",
        lastHeartbeat: "Just now",
        firmware: "v2.4.2-stable",
        ipAddress: `192.168.1.${Math.floor(60 + Math.random() * 50)}`
      },
      slaves: [],
      valves: [],
      pump: { status: "Off", loadAmps: 0.0, mode: "Auto", voltage: 415, frequency: 50.0 },
      zones: [],
      schedules: [],
      irrigationHistory: [],
      telemetry: {
        moistureHistory: [40, 40, 40],
        flowRateHistory: [0, 0, 0],
        pressureHistory: [0, 0, 0],
        timestamps: ["12:00 PM", "01:00 PM", "02:00 PM"]
      },
      modbusRegisters: []
    }

    const updatedFields = [...db.fields, newField]
    let updatedDb = { ...db, fields: updatedFields }
    updatedDb = addLog(updatedDb, "Super Admin", "Field Added", `Commissioned field: ${newField.name} for farmer ${selectedFarmer.name}`)
    setDb(updatedDb)
    handleCloseModal()
  }

  const handleToggleStatus = (id, name, currentStatus) => {
    const nextStatus = currentStatus === "Active" ? "Suspended" : "Active"
    const updatedFarmers = db.farmers.map(f => f.id === id ? { ...f, status: nextStatus } : f)
    let updatedDb = { ...db, farmers: updatedFarmers }
    updatedDb = addLog(updatedDb, "Super Admin", "Farmer Status Toggled", `Set status of ${name} to ${nextStatus}`)
    setDb(updatedDb)
  }

  // Filter fields, tickets, and logs for selected farmer
  const farmerFields = db?.fields?.filter(f => f.farmerId === selectedFarmerId) || []
  const farmerTickets = db?.tickets?.filter(t => t.farmerId === selectedFarmerId) || []
  
  // Filter activity logs containing farmer's name
  const farmerLogs = db?.logs?.filter(log => 
    log.details.toLowerCase().includes(selectedFarmer?.name?.toLowerCase())
  ) || []

  return (
    <div className="flex flex-col gap-6 font-sans text-xs">
      {viewMode === "list" ? (
        // --- 1. Farmer Directory List View ---
        <div className="flex flex-col gap-4">
          
          {/* Header Metric Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Card className="shadow-xs border border-border bg-card">
              <CardContent className="p-4 flex items-center gap-4">
                <div className="p-2.5 bg-emerald-500/5 text-emerald-600 rounded-xl border border-emerald-500/10">
                  <UsersIcon size={20} />
                </div>
                <div>
                  <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Registered Farmers</p>
                  <h3 className="text-xl font-black text-foreground mt-0.5">{farmers.length}</h3>
                </div>
              </CardContent>
            </Card>

            <Card className="shadow-xs border border-border bg-card">
              <CardContent className="p-4 flex items-center gap-4">
                <div className="p-2.5 bg-teal-500/5 text-teal-600 rounded-xl border border-teal-500/10">
                  <ShieldCheck size={20} />
                </div>
                <div>
                  <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Active Subscriptions</p>
                  <h3 className="text-xl font-black text-foreground mt-0.5">
                    {farmers.filter(f => f.status === "Active" && f.servicePlan !== "None (Expired)").length}
                  </h3>
                </div>
              </CardContent>
            </Card>

            <Card className="shadow-xs border border-border bg-card">
              <CardContent className="p-4 flex items-center gap-4">
                <div className="p-2.5 bg-red-500/5 text-red-600 rounded-xl border border-red-500/10">
                  <Ban size={20} />
                </div>
                <div>
                  <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Suspended Accounts</p>
                  <h3 className="text-xl font-black text-foreground mt-0.5">
                    {farmers.filter(f => f.status === "Suspended").length}
                  </h3>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Table Container */}
          <div className="bg-card rounded-xl border border-border/80 shadow-[0_8px_30px_rgb(0,0,0,0.02)] overflow-hidden">
            {/* Search and onboarding bar */}
            <div className="p-4 border-b border-border/60 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <div className="relative flex-1 max-w-md">
                <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-muted-foreground" />
                <input
                  type="text"
                  placeholder="Search by name, contact, region..."
                  className="pl-9 pr-4 py-1.5 w-full border border-border/80 rounded-lg bg-background focus:outline-none focus:ring-2 focus:ring-emerald-500/25 focus:border-emerald-500 text-xs font-bold"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
              <button
                onClick={() => handleOpenModal("create")}
                className="flex items-center gap-1.5 bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white px-4 py-2 rounded-lg text-xs font-bold transition-all hover:-translate-y-0.5 active:translate-y-0 shadow-md shadow-emerald-500/10 cursor-pointer"
              >
                <Plus size={14} />
                <span>Register Farmer</span>
              </button>
            </div>

            {/* Table */}
            <div className="overflow-x-auto">
              <Table>
                <TableHeader className="bg-muted/10 border-b border-border/60">
                  <TableRow>
                    <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Farmer Name</TableHead>
                    <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Contact</TableHead>
                    <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Region / Village</TableHead>
                    <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Distributor</TableHead>
                    <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Service Plan</TableHead>
                    <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Status</TableHead>
                    <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider text-right pr-6">Manage</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredFarmers.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={7} className="text-center py-8 text-muted-foreground italic">
                        No farmer profiles matching your criteria.
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredFarmers.map((f) => {
                      return (
                        <TableRow key={f.id} className="hover:bg-muted/10 font-medium">
                          <TableCell className="font-extrabold text-foreground py-3">
                            <div>
                              <div>{f.name}</div>
                              <div className="text-[9px] text-muted-foreground font-semibold">Registered: {f.registeredAt}</div>
                            </div>
                          </TableCell>
                          <TableCell>
                            <div>
                              <div className="flex items-center gap-1 text-muted-foreground font-mono">
                                <Phone size={10} />
                                <span>{f.phone}</span>
                              </div>
                              {f.email && (
                                <div className="flex items-center gap-1 text-[9px] text-muted-foreground mt-0.5">
                                  <Mail size={10} />
                                  <span>{f.email}</span>
                                </div>
                              )}
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-1 text-muted-foreground">
                              <MapPin size={10} />
                              <span>{f.village}, {f.district}</span>
                            </div>
                          </TableCell>
                          <TableCell className="text-muted-foreground">{f.distributor}</TableCell>
                          <TableCell>
                            <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[9px] font-extrabold bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/15">
                              {f.servicePlan}
                            </span>
                          </TableCell>
                          <TableCell>
                            <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-[9px] font-extrabold border ${
                              f.status === "Active" 
                                ? "bg-green-500/10 text-green-600 dark:text-green-400 border-green-500/15" 
                                : "bg-red-500/10 text-red-600 dark:text-red-400 border-red-500/15"
                            }`}>
                              {f.status}
                            </span>
                          </TableCell>
                          <TableCell className="text-right pr-6">
                            <div className="flex items-center justify-end gap-1.5">
                              <button
                                onClick={() => {
                                  setSelectedFarmerId(f.id)
                                  setViewMode("details")
                                }}
                                className="p-1 rounded-md border border-border hover:bg-emerald-500 hover:text-white text-emerald-600 transition-colors cursor-pointer"
                                title="Open Farmer Profile"
                              >
                                <Eye size={13} />
                              </button>
                              <button
                                onClick={() => handleOpenModal("edit", f)}
                                className="p-1 rounded-md border border-border hover:bg-emerald-500 hover:text-white text-emerald-600 transition-colors cursor-pointer"
                                title="Edit Profile"
                              >
                                <Pencil size={13} />
                              </button>
                              <button
                                onClick={() => handleToggleStatus(f.id, f.name, f.status)}
                                className={`p-1 rounded-md border border-border transition-colors cursor-pointer ${
                                  f.status === "Active" 
                                    ? "hover:bg-red-500 hover:text-white text-red-500" 
                                    : "hover:bg-green-500 hover:text-white text-green-500"
                                }`}
                                title={f.status === "Active" ? "Suspend Farmer" : "Activate Farmer"}
                              >
                                {f.status === "Active" ? <Ban size={13} /> : <CheckCircle2 size={13} />}
                              </button>
                            </div>
                          </TableCell>
                        </TableRow>
                      )
                    })
                  )}
                </TableBody>
              </Table>
            </div>
          </div>
        </div>
      ) : (
        // --- 2. Farmer Details Tabbed Dashboard View ---
        <div className="flex flex-col gap-6">
          {/* Back button and profile overview */}
          <div className="flex items-center justify-between border-b border-border/60 pb-4">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setViewMode("list")}
                className="p-2 border border-border bg-card rounded-lg text-muted-foreground hover:text-foreground cursor-pointer hover:bg-muted/15"
              >
                <ArrowLeft size={14} />
              </button>
              <div>
                <h2 className="text-lg font-black text-foreground">{selectedFarmer?.name}</h2>
                <p className="text-[10px] text-muted-foreground font-semibold mt-0.5">Farmer Profile & Field Operations Context</p>
              </div>
            </div>

            <div className="flex gap-2">
              <button
                onClick={() => handleOpenModal("edit", selectedFarmer)}
                className="px-3 py-1.5 bg-card border border-border text-foreground hover:bg-muted/15 rounded-lg text-xs font-bold cursor-pointer"
              >
                Edit Profile
              </button>
            </div>
          </div>

          {/* Tabs bar */}
          <div className="flex border-b border-border">
            {["overview", "fields", "support", "activity"].map(tab => (
              <button
                key={tab}
                onClick={() => setActiveDetailTab(tab)}
                className={`px-4 py-2 font-bold text-xs capitalize relative -mb-px transition-all cursor-pointer ${
                  activeDetailTab === tab 
                    ? "text-emerald-600 dark:text-emerald-400 border-b-2 border-emerald-500" 
                    : "text-muted-foreground hover:text-foreground"
                }`}
              >
                {tab}
              </button>
            ))}
          </div>

          {/* Tab contents */}
          <div className="grid gap-6">
            {activeDetailTab === "overview" && (
              <div className="grid gap-6 md:grid-cols-3">
                {/* Farmer Information */}
                <Card className="md:col-span-2 shadow-xs border border-border bg-card">
                  <CardHeader>
                    <CardTitle className="text-xs font-extrabold uppercase tracking-wider">Account Information</CardTitle>
                  </CardHeader>
                  <CardContent className="grid gap-4 md:grid-cols-2 text-xs">
                    <div className="flex flex-col gap-1 border-b border-border/40 pb-2">
                      <span className="font-semibold text-muted-foreground">Mobile Contact</span>
                      <span className="font-extrabold text-foreground font-mono">{selectedFarmer?.phone}</span>
                    </div>
                    <div className="flex flex-col gap-1 border-b border-border/40 pb-2">
                      <span className="font-semibold text-muted-foreground">Email Address</span>
                      <span className="font-extrabold text-foreground font-mono">{selectedFarmer?.email || "N/A"}</span>
                    </div>
                    <div className="flex flex-col gap-1 border-b border-border/40 pb-2">
                      <span className="font-semibold text-muted-foreground">Distributor / Retailer</span>
                      <span className="font-extrabold text-foreground">{selectedFarmer?.distributor}</span>
                    </div>
                    <div className="flex flex-col gap-1 border-b border-border/40 pb-2">
                      <span className="font-semibold text-muted-foreground">Service Plan Subscription</span>
                      <span className="font-extrabold text-blue-600 dark:text-blue-400">{selectedFarmer?.servicePlan}</span>
                    </div>
                    <div className="flex flex-col gap-1 md:col-span-2">
                      <span className="font-semibold text-muted-foreground">Regional Address</span>
                      <span className="font-extrabold text-foreground">
                        {selectedFarmer?.village}, District: {selectedFarmer?.district}, State: {selectedFarmer?.state} - {selectedFarmer?.pincode}
                      </span>
                    </div>
                  </CardContent>
                </Card>

                {/* Quick Field Summary */}
                <Card className="shadow-xs border border-border bg-card flex flex-col justify-between">
                  <CardHeader>
                    <CardTitle className="text-xs font-extrabold uppercase tracking-wider">Field Operations Summary</CardTitle>
                  </CardHeader>
                  <CardContent className="flex-1 flex flex-col gap-3 py-2">
                    <div className="p-3 bg-muted/20 border border-border rounded-xl flex items-center justify-between font-bold">
                      <div className="flex items-center gap-2">
                        <Sprout size={16} className="text-emerald-500" />
                        <span>Fields Count</span>
                      </div>
                      <span className="text-sm font-black">{farmerFields.length}</span>
                    </div>
                    <div className="p-3 bg-muted/20 border border-border rounded-xl flex items-center justify-between font-bold">
                      <div className="flex items-center gap-2">
                        <Wrench size={16} className="text-indigo-500" />
                        <span>Active Tickets</span>
                      </div>
                      <span className="text-sm font-black text-red-500">
                        {farmerTickets.filter(t => t.status !== "Closed").length}
                      </span>
                    </div>
                  </CardContent>
                  <div className="p-4 border-t border-border mt-auto">
                    <button
                      onClick={() => setActiveDetailTab("fields")}
                      className="w-full bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 font-bold py-2 rounded-lg text-center cursor-pointer transition-all flex items-center justify-center gap-1"
                    >
                      <span>Manage Fields</span>
                      <ArrowRight size={13} />
                    </button>
                  </div>
                </Card>
              </div>
            )}

            {activeDetailTab === "fields" && (
              <div className="flex flex-col gap-4">
                {/* Actions Row */}
                <div className="flex justify-between items-center bg-muted/10 p-3 border border-border/40 rounded-xl">
                  <span className="font-extrabold text-foreground">{farmerFields.length} Fields Configured</span>
                  <button
                    onClick={() => handleOpenModal("add-field")}
                    className="flex items-center gap-1 bg-emerald-600 hover:bg-emerald-700 text-white font-bold px-3 py-1.5 rounded-lg text-xs cursor-pointer transition-all shadow-xs"
                  >
                    <Plus size={14} />
                    <span>Onboard Field</span>
                  </button>
                </div>

                {/* Fields Cards Grid */}
                {farmerFields.length === 0 ? (
                  <div className="text-center py-12 border border-dashed border-border rounded-2xl bg-card">
                    <Sprout size={24} className="text-muted-foreground mb-2 animate-bounce" />
                    <h4 className="font-bold text-foreground">No Registered Fields</h4>
                    <p className="text-muted-foreground mt-1">This farmer doesn't have any drip sectors commissioned yet.</p>
                  </div>
                ) : (
                  <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                    {farmerFields.map((field) => {
                      const activeValves = field.valves?.filter(v => v.status === "Open").length || 0
                      const avgMoisture = field.zones?.length > 0 
                        ? (field.zones.reduce((sum, z) => sum + z.moisture, 0) / field.zones.length).toFixed(1)
                        : "N/A"

                      return (
                        <Card key={field.id} className="shadow-xs border border-border hover:border-emerald-500/35 transition-all bg-card flex flex-col justify-between group">
                          <CardHeader className="pb-2">
                            <div className="flex justify-between items-start">
                              <span className="font-extrabold text-sm text-foreground group-hover:text-emerald-600 transition-colors">{field.name}</span>
                              <span className={`inline-flex items-center px-1.5 py-0.2 rounded-md text-[8px] font-bold ${
                                field.masterDevice?.status === "Online" ? "bg-green-500/10 text-green-600" : "bg-red-500/10 text-red-600"
                              }`}>
                                {field.masterDevice?.status}
                              </span>
                            </div>
                            <CardDescription className="text-[9px] font-bold font-mono">{field.masterDevice?.mqttTopic || field.masterDevice?.imei}</CardDescription>
                          </CardHeader>
                          
                          <CardContent className="flex flex-col gap-2 py-2">
                            <div className="grid grid-cols-2 gap-2 text-[10px] bg-muted/10 p-2 rounded-lg border border-border/40 font-semibold text-muted-foreground">
                              <div>
                                <span>Area: </span>
                                <span className="font-extrabold text-foreground">{field.area}</span>
                              </div>
                              <div>
                                <span>Crop: </span>
                                <span className="font-extrabold text-foreground">{field.cropType}</span>
                              </div>
                              <div>
                                <span>Moisture: </span>
                                <span className={`font-extrabold ${Number(avgMoisture) < 25 ? "text-amber-500" : "text-emerald-500"}`}>{avgMoisture}%</span>
                              </div>
                              <div>
                                <span>Valves Open: </span>
                                <span className="font-extrabold text-foreground">{activeValves}</span>
                              </div>
                            </div>
                          </CardContent>

                          <div className="p-3 border-t border-border/60 bg-muted/5 flex items-center justify-between">
                            <button
                              onClick={() => {
                                setSelectedFarmerId(selectedFarmerId)
                                setSelectedFieldId(field.id)
                                setActiveDetailTab("overview") // reset farmer details tab state
                                navigate("/field-workspace")
                              }}
                              className="w-full flex items-center justify-center gap-1.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-[10px] font-bold cursor-pointer transition-all shadow-xs"
                            >
                              <span>Enter Field Workspace</span>
                              <ExternalLink size={11} />
                            </button>
                          </div>
                        </Card>
                      )
                    })}
                  </div>
                )}
              </div>
            )}

            {activeDetailTab === "support" && (
              <div className="flex flex-col gap-4">
                <div className="bg-card rounded-xl border border-border shadow-xs overflow-hidden">
                  <Table>
                    <TableHeader className="bg-muted/10 border-b border-border/60">
                      <TableRow>
                        <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Ticket Title</TableHead>
                        <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Category</TableHead>
                        <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Priority</TableHead>
                        <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Assigned Tech</TableHead>
                        <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Status</TableHead>
                        <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider text-right pr-6">Open</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {farmerTickets.length === 0 ? (
                        <TableRow>
                          <TableCell colSpan={6} className="text-center py-8 text-muted-foreground italic">
                            No open support requests for this farmer.
                          </TableCell>
                        </TableRow>
                      ) : (
                        farmerTickets.map((t) => (
                          <TableRow key={t.id} className="hover:bg-muted/5 font-medium">
                            <TableCell className="font-extrabold text-foreground py-3">
                              <div>
                                <div>{t.title}</div>
                                <div className="text-[9px] text-muted-foreground font-semibold">Logged: {t.createdAt}</div>
                              </div>
                            </TableCell>
                            <TableCell className="text-muted-foreground">{t.category}</TableCell>
                            <TableCell>
                              <span className={`inline-flex items-center px-1.5 py-0.2 rounded text-[8px] font-bold border ${
                                t.priority === "High" ? "bg-red-500/10 text-red-500 border-red-500/15 animate-pulse" : "bg-amber-500/10 text-amber-500 border-amber-500/15"
                              }`}>
                                {t.priority}
                              </span>
                            </TableCell>
                            <TableCell className="font-mono text-muted-foreground">{t.assignedTechnician}</TableCell>
                            <TableCell>
                              <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-[9px] font-extrabold border ${
                                t.status === "Open" 
                                  ? "bg-red-500/10 text-red-500 border-red-500/15" 
                                  : t.status === "In Progress"
                                  ? "bg-amber-500/10 text-amber-500 border-amber-500/15"
                                  : "bg-green-500/10 text-green-500 border-green-500/15"
                              }`}>
                                {t.status}
                              </span>
                            </TableCell>
                            <TableCell className="text-right pr-6">
                              <button
                                onClick={() => navigate("/support")}
                                className="p-1 border border-border rounded text-muted-foreground hover:text-foreground cursor-pointer hover:bg-muted/20"
                                title="Go to Support center"
                              >
                                <ArrowRight size={12} />
                              </button>
                            </TableCell>
                          </TableRow>
                        ))
                      )}
                    </TableBody>
                  </Table>
                </div>
              </div>
            )}

            {activeDetailTab === "activity" && (
              <Card className="shadow-xs border border-border bg-card">
                <CardHeader>
                  <CardTitle className="text-xs font-extrabold uppercase tracking-wider">Farmer Activity Timeline</CardTitle>
                </CardHeader>
                <CardContent className="flex flex-col gap-4">
                  {farmerLogs.length === 0 ? (
                    <div className="text-center py-6 text-muted-foreground italic">
                      No logs matching this farmer's footprint.
                    </div>
                  ) : (
                    farmerLogs.map((log) => (
                      <div key={log.id} className="flex gap-3 text-xs border-b border-border/40 pb-2 last:border-0 last:pb-0 font-semibold">
                        <div className="flex flex-col items-center shrink-0">
                          <div className="h-6 w-6 rounded-full bg-emerald-500/10 text-emerald-600 flex items-center justify-center border border-emerald-500/20">
                            <Activity size={12} />
                          </div>
                        </div>
                        <div className="flex-1">
                          <div className="flex justify-between items-center text-[10px] text-muted-foreground">
                            <span>Actor: {log.user}</span>
                            <span className="font-mono">{log.timestamp}</span>
                          </div>
                          <div className="font-extrabold text-[11px] mt-0.5 text-foreground">{log.action}</div>
                          <div className="text-[10px] text-muted-foreground font-medium mt-0.5">{log.details}</div>
                        </div>
                      </div>
                    ))
                  )}
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      )}

      {/* Onboarding Farmer or Field Modals */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-card text-card-foreground w-full max-w-md rounded-xl shadow-lg border border-border flex flex-col animate-in zoom-in-95 duration-200">
            
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-border">
              <h3 className="text-lg font-bold text-foreground">
                {modalMode === "create" ? "Register New Farmer" : modalMode === "edit" ? "Edit Profile" : `Commission Field: ${selectedFarmer?.name}`}
              </h3>
              <button onClick={handleCloseModal} className="text-muted-foreground hover:text-foreground transition-colors p-1 rounded-md hover:bg-muted">
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Form */}
            {modalMode === "add-field" ? (
              // Commission Field Form
              <form onSubmit={handleAddField} className="p-6 flex flex-col gap-4 text-xs font-bold">
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Field Block Name</label>
                  <input
                    type="text"
                    required
                    value={fieldFormData.name}
                    onChange={(e) => setFieldFormData({ ...fieldFormData, name: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-muted-foreground/60"
                    placeholder="E.g. South Pasture Block"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Acreage Area</label>
                    <input
                      type="text"
                      required
                      value={fieldFormData.area}
                      onChange={(e) => setFieldFormData({ ...fieldFormData, area: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all"
                      placeholder="E.g. 8.5 acres"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Crop Variety</label>
                    <input
                      type="text"
                      required
                      value={fieldFormData.cropType}
                      onChange={(e) => setFieldFormData({ ...fieldFormData, cropType: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all"
                      placeholder="E.g. Tomatoes"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Soil Profile</label>
                    <select
                      value={fieldFormData.soilType}
                      onChange={(e) => setFieldFormData({ ...fieldFormData, soilType: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 transition-all cursor-pointer"
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
                      value={fieldFormData.waterSource}
                      onChange={(e) => setFieldFormData({ ...fieldFormData, waterSource: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all"
                      placeholder="Canal Lift, Well, Borewell"
                    />
                  </div>
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Master Board Raspberry Pi MQTT Topic</label>
                  <input
                    type="text"
                    required
                    value={fieldFormData.masterMqttTopic}
                    onChange={(e) => setFieldFormData({ ...fieldFormData, masterMqttTopic: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all font-mono"
                  />
                </div>

                <div className="flex justify-end gap-3 mt-4">
                  <button type="button" onClick={handleCloseModal} className="px-4 py-2 rounded-lg border border-border bg-background hover:bg-accent text-foreground font-bold transition-all cursor-pointer">
                    Cancel
                  </button>
                  <button type="submit" className="px-4 py-2 rounded-lg bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white font-bold transition-all cursor-pointer shadow-md shadow-emerald-500/10">
                    Commission Field
                  </button>
                </div>
              </form>
            ) : (
              // Onboard Farmer / Edit Form
              <form onSubmit={handleSaveFarmer} className="p-6 flex flex-col gap-4 text-xs font-bold">
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Farmer Full Name</label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-muted-foreground/60"
                    placeholder="E.g. Ramesh Kumar"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Mobile Contact</label>
                    <input
                      type="tel"
                      required
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all font-mono"
                      placeholder="9876543210"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Email Address</label>
                    <input
                      type="email"
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all font-mono"
                      placeholder="ramesh@gmail.com"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Village</label>
                    <input
                      type="text"
                      required
                      value={formData.village}
                      onChange={(e) => setFormData({ ...formData, village: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all"
                      placeholder="Manchar"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">District</label>
                    <input
                      type="text"
                      required
                      value={formData.district}
                      onChange={(e) => setFormData({ ...formData, district: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all"
                      placeholder="Pune"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Pincode</label>
                    <input
                      type="text"
                      required
                      value={formData.pincode}
                      onChange={(e) => setFormData({ ...formData, pincode: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all font-mono"
                      placeholder="410503"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Distributor Channel</label>
                    <select
                      value={formData.distributor}
                      onChange={(e) => setFormData({ ...formData, distributor: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 transition-all cursor-pointer"
                    >
                      <option value="Macro Drip Distributors">Macro Drip Distributors</option>
                      <option value="Agri Drip Retailers">Agri Drip Retailers</option>
                    </select>
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-muted-foreground">Subscription Plan</label>
                    <select
                      value={formData.servicePlan}
                      onChange={(e) => setFormData({ ...formData, servicePlan: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 transition-all cursor-pointer"
                    >
                      <option value="Starter">Starter</option>
                      <option value="Standard Growth">Standard Growth</option>
                      <option value="Premium Pro">Premium Pro</option>
                      <option value="None (Expired)">None (Expired)</option>
                    </select>
                  </div>
                </div>

                <div className="flex justify-end gap-3 mt-4">
                  <button type="button" onClick={handleCloseModal} className="px-4 py-2 rounded-lg border border-border bg-background hover:bg-accent text-foreground font-bold transition-all cursor-pointer">
                    Cancel
                  </button>
                  <button type="submit" className="px-4 py-2 rounded-lg bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white font-bold transition-all cursor-pointer shadow-md shadow-emerald-500/10">
                    Save Profile
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

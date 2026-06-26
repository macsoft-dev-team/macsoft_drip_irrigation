import React, { useState, useEffect } from "react"
import {
  Sprout,
  Droplet,
  Plus,
  Trash2,
  Search,
  MapPin,
  Layers,
  Power,
  ThermometerSun,
  AlertCircle,
  X,
  ChevronDown,
  ChevronUp,
  Info,
  TrendingDown,
  TrendingUp,
  Activity,
  FolderOpen
} from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import {
  Table,
  TableHeader,
  TableBody,
  TableHead,
  TableRow,
  TableCell,
} from "@/components/ui/table"

// Sparkline component that animates a live miniature moisture trend wave
function MoistureSparkline({ moisture }) {
  // Simple deterministic paths representing history/trend
  let path = "";
  if (moisture > 70) {
    // Wet: generally rising/high trend
    path = "M 2,12 Q 15,6 30,10 T 58,3"
  } else if (moisture < 25) {
    // Dry: generally dropping/low trend
    path = "M 2,4 Q 15,8 30,7 T 58,13"
  } else {
    // Stable: normal mild waves
    path = "M 2,8 Q 15,3 30,11 T 58,7"
  }

  const strokeColor = moisture > 70
    ? "text-blue-500"
    : moisture >= 25
      ? "text-emerald-500"
      : "text-amber-500 animate-pulse"

  return (
    <svg width="60" height="16" className="inline-block overflow-visible opacity-75">
      <path
        d={path}
        fill="none"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        className={strokeColor}
      />
    </svg>
  )
}

import { initialFields } from "@/lib/mockData"

export default function Fields({ navigate }) {
  // Load fields from localStorage or use initial data
  const [fields, setFields] = useState(() => {
    const saved = localStorage.getItem("drip_fields")
    return saved ? JSON.parse(saved) : initialFields
  })

  // State for search/filter query
  const [searchQuery, setSearchQuery] = useState("")

  // Form modals state: 'field' | 'zone' | 'valve' | null
  const [activeModal, setActiveModal] = useState(null)

  // Collapse states for individual fields card accordion views
  const [collapsedFields, setCollapsedFields] = useState({})

  // Collapse states for individual zones nested inside fields
  const [collapsedZones, setCollapsedZones] = useState({})

  // Form field states
  // 1. Field Form
  const [fieldName, setFieldName] = useState("")
  const [fieldLocation, setFieldLocation] = useState("")
  const [fieldArea, setFieldArea] = useState("")
  const [fieldSoilType, setFieldSoilType] = useState("")

  // 2. Zone Form
  const [zoneFieldId, setZoneFieldId] = useState("")
  const [zoneName, setZoneName] = useState("")
  const [zoneLocation, setZoneLocation] = useState("")
  const [zoneMoisture, setZoneMoisture] = useState("45")

  // 3. Valve Form
  const [valveFieldId, setValveFieldId] = useState("")
  const [valveZoneId, setValveZoneId] = useState("")
  const [valveName, setValveName] = useState("")
  const [valveType, setValveType] = useState("Solenoid")
  const [valveCapacity, setValveCapacity] = useState("10.0")

  // Save fields state to local storage when updated
  useEffect(() => {
    localStorage.setItem("drip_fields", JSON.stringify(fields))
  }, [fields])

  // Real-time Moisture and Valve simulation
  useEffect(() => {
    const interval = setInterval(() => {
      setFields(prevFields =>
        prevFields.map(field => {
          const updatedZones = (field.zones || []).map(zone => {
            // Check if there are any open valves in this zone
            const openValves = (zone.valves || []).filter(v => v.status === "Open")

            let nextMoisture = zone.moisture
            if (openValves.length > 0) {
              // Increase moisture slowly if watering
              const increaseRate = 0.05 * openValves.length
              nextMoisture = Math.min(nextMoisture + increaseRate, 90.0)
            } else {
              // Decrease moisture slowly over time to simulate absorption and evaporation
              nextMoisture = Math.max(nextMoisture - 0.01, 10.0)
            }

            // Update valve flow rates based on status
            const updatedValves = (zone.valves || []).map(valve => {
              if (valve.status === "Open") {
                // Add minor fluctuation to simulated flow rate (+/- 5%)
                const fluctuation = (Math.random() - 0.5) * 0.1 * valve.capacity
                const currentFlow = Math.max(0, valve.capacity + fluctuation)
                return { ...valve, flowRate: parseFloat(currentFlow.toFixed(1)) }
              }
              return { ...valve, flowRate: 0 }
            })

            return { ...zone, moisture: parseFloat(nextMoisture.toFixed(2)), valves: updatedValves }
          })

          // If any valve in the field is open, pump motor must be in ON state
          const isAnyValveOpen = updatedZones.some(z => (z.valves || []).some(v => v.status === "Open"))
          const nextMotorStatus = isAnyValveOpen ? "On" : (field.motorStatus || "Off")

          return { ...field, zones: updatedZones, motorStatus: nextMotorStatus }
        })
      )
    }, 1000)

    return () => clearInterval(interval)
  }, [])

  // Toggle Collapse
  const toggleCollapse = (id) => {
    setCollapsedFields(prev => ({
      ...prev,
      [id]: !prev[id]
    }))
  }

  // Toggle Zone Collapse
  const toggleZoneCollapse = (id) => {
    setCollapsedZones(prev => ({
      ...prev,
      [id]: !prev[id]
    }))
  }

  // Toggle Pump Motor
  const toggleMotor = (fieldId) => {
    setFields(prevFields =>
      prevFields.map(field => {
        if (field.id === fieldId) {
          const nextStatus = field.motorStatus === "On" ? "Off" : "On"
          
          // If turning OFF the motor, shut off all valves in the field automatically
          let updatedZones = field.zones
          if (nextStatus === "Off") {
            updatedZones = (field.zones || []).map(zone => {
              const updatedValves = (zone.valves || []).map(valve => ({
                ...valve,
                status: "Closed",
                flowRate: 0
              }))
              return { ...zone, valves: updatedValves }
            })
          }
          
          return {
            ...field,
            motorStatus: nextStatus,
            zones: updatedZones
          }
        }
        return field
      })
    )
  }

  // Actuate (Open/Close) Valve
  const toggleValve = (fieldId, zoneId, valveId) => {
    setFields(prevFields =>
      prevFields.map(field => {
        if (field.id === fieldId) {
          const updatedZones = field.zones.map(zone => {
            if (zone.id === zoneId) {
              const updatedValves = zone.valves.map(valve => {
                if (valve.id === valveId) {
                  const newStatus = valve.status === "Open" ? "Closed" : "Open"
                  return {
                    ...valve,
                    status: newStatus,
                    flowRate: newStatus === "Open" ? valve.capacity : 0
                  }
                }
                return valve
              })
              return { ...zone, valves: updatedValves }
            }
            return zone
          })

          const isAnyValveOpenNow = updatedZones.some(z => (z.valves || []).some(v => v.status === "Open"))
          const nextMotorStatus = isAnyValveOpenNow ? "On" : field.motorStatus

          return { ...field, zones: updatedZones, motorStatus: nextMotorStatus }
        }
        return field
      })
    )
  }

  // Add Field handler
  const handleAddField = (e) => {
    e.preventDefault()
    if (!fieldName.trim()) return

    const newField = {
      id: Date.now(),
      name: fieldName,
      location: fieldLocation || "N/A",
      area: fieldArea || "0.0 acres",
      soilType: fieldSoilType || "N/A",
      motorStatus: "Off",
      zones: []
    }

    setFields([...fields, newField])
    resetFieldForm()
    setActiveModal(null)
  }

  // Add Zone handler
  const handleAddZone = (e) => {
    e.preventDefault()
    if (!zoneName.trim() || !zoneFieldId) return

    const newZone = {
      id: Date.now(),
      name: zoneName,
      location: zoneLocation || "N/A",
      moisture: parseFloat(zoneMoisture) || 45.0,
      valves: []
    }

    setFields(prev => prev.map(field => {
      if (field.id === Number(zoneFieldId)) {
        return {
          ...field,
          zones: [...(field.zones || []), newZone]
        }
      }
      return field
    }))

    resetZoneForm()
    setActiveModal(null)
  }

  // Add Valve handler
  const handleAddValve = (e) => {
    e.preventDefault()
    if (!valveName.trim() || !valveFieldId || !valveZoneId) return

    const newValve = {
      id: Date.now(),
      name: valveName,
      type: valveType,
      status: "Closed",
      flowRate: 0,
      capacity: parseFloat(valveCapacity) || 10.0
    }

    setFields(prev => prev.map(field => {
      if (field.id === Number(valveFieldId)) {
        const updatedZones = field.zones.map(zone => {
          if (zone.id === Number(valveZoneId)) {
            return {
              ...zone,
              valves: [...(zone.valves || []), newValve]
            }
          }
          return zone
        })
        return { ...field, zones: updatedZones }
      }
      return field
    }))

    resetValveForm()
    setActiveModal(null)
  }

  // Delete Field
  const handleDeleteField = (fieldId) => {
    if (confirm("Are you sure you want to delete this field and all its zones and valves?")) {
      setFields(fields.filter(f => f.id !== fieldId))
    }
  }

  // Delete Zone
  const handleDeleteZone = (fieldId, zoneId) => {
    if (confirm("Are you sure you want to delete this zone and its valves?")) {
      setFields(prev => prev.map(field => {
        if (field.id === fieldId) {
          return {
            ...field,
            zones: field.zones.filter(z => z.id !== zoneId)
          }
        }
        return field
      }))
    }
  }

  // Delete Valve
  const handleDeleteValve = (fieldId, zoneId, valveId) => {
    if (confirm("Are you sure you want to delete this valve?")) {
      setFields(prev => prev.map(field => {
        if (field.id === fieldId) {
          const updatedZones = field.zones.map(zone => {
            if (zone.id === zoneId) {
              return {
                ...zone,
                valves: zone.valves.filter(v => v.id !== valveId)
              }
            }
            return zone
          })
          return { ...field, zones: updatedZones }
        }
        return field
      }))
    }
  }

  // Form Resets
  const resetFieldForm = () => {
    setFieldName("")
    setFieldLocation("")
    setFieldArea("")
    setFieldSoilType("")
  }

  const resetZoneForm = () => {
    setZoneFieldId("")
    setZoneName("")
    setZoneLocation("")
    setZoneMoisture("45")
  }

  const resetValveForm = () => {
    setValveFieldId("")
    setValveZoneId("")
    setValveName("")
    setValveType("Solenoid")
    setValveCapacity("10.0")
  }

  // Filter fields based on search query AND active tab selection
  const filteredFields = fields.filter(field => {
    const q = searchQuery.toLowerCase()

    // Search query matches field or zone details
    return field.name.toLowerCase().includes(q) ||
      field.location.toLowerCase().includes(q) ||
      field.soilType.toLowerCase().includes(q) ||
      field.zones?.some(z => z.name.toLowerCase().includes(q) || z.location.toLowerCase().includes(q))
  })

  // Open modally pre-filled for field or zone
  const openAddZoneForField = (fieldId) => {
    setZoneFieldId(fieldId.toString())
    setActiveModal("zone")
  }

  const openAddValveForZone = (fieldId, zoneId) => {
    setValveFieldId(fieldId.toString())
    setValveZoneId(zoneId.toString())
    setActiveModal("valve")
  }

  // Find active zones list based on selected Field ID in valve form
  const getSelectedFieldZones = () => {
    if (!valveFieldId) return []
    const selectedField = fields.find(f => f.id === Number(valveFieldId))
    return selectedField ? selectedField.zones || [] : []
  }

  // Pre-select the first zone of selected field if not set
  useEffect(() => {
    const selectedFieldZones = getSelectedFieldZones()
    if (selectedFieldZones.length > 0 && !valveZoneId) {
      setValveZoneId(selectedFieldZones[0].id.toString())
    }
  }, [valveFieldId])

  // Aggregate statistics for stats cards
  const totalFields = fields.length
  const totalZones = fields.reduce((acc, f) => acc + (f.zones?.length || 0), 0)
  const totalValves = fields.reduce((acc, f) => acc + (f.zones?.reduce((zacc, z) => zacc + (z.valves?.length || 0), 0) || 0), 0)
  const activeValves = fields.reduce((acc, f) => acc + (f.zones?.reduce((zacc, z) => zacc + (z.valves?.filter(v => v.status === "Open").length || 0), 0) || 0), 0)

  const allMoistures = fields.flatMap(f => f.zones?.map(z => z.moisture) || [])
  const systemAvgMoisture = allMoistures.length > 0
    ? (allMoistures.reduce((sum, val) => sum + val, 0) / allMoistures.length).toFixed(1)
    : "N/A"

  // Helper to color code Valve classes
  const getValveTypeStyle = (type) => {
    switch (type) {
      case "Solenoid":
        return "bg-indigo-500/10 text-indigo-600 dark:bg-indigo-500/20 dark:text-indigo-400 border-indigo-500/20"
      case "Drip":
        return "bg-sky-500/10 text-sky-600 dark:bg-sky-500/20 dark:text-sky-400 border-sky-500/20"
      case "Sprinkler":
        return "bg-amber-500/10 text-amber-600 dark:bg-amber-500/20 dark:text-amber-400 border-amber-500/20"
      case "Mister":
        return "bg-pink-500/10 text-pink-600 dark:bg-pink-500/20 dark:text-pink-400 border-pink-500/20"
      default:
        return "bg-muted text-muted-foreground border-gray-200/40"
    }
  }

  return (
    <div className="flex flex-col gap-6">
      {/* 1. Header Section */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b border-gray-200">
        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-tr from-emerald-500 to-teal-400 text-white shadow-md shadow-emerald-500/20">
            <Sprout className="h-6 w-6" />
          </div>
          <div>
            <h2 className="text-xl font-bold tracking-tight text-foreground">Sectors & Fields</h2>
            <p className="text-xs text-muted-foreground mt-0.5">Hierarchical index of fields, zones, and valves. Monitor metrics and actuate flow lines.</p>
          </div>
        </div>

        {/* Top Actions: Smaller & User-Friendly */}
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => {
              resetFieldForm()
              setActiveModal("field")
            }}
            className="px-2.5 py-1.5 rounded-md font-bold text-[10px] uppercase tracking-wider flex items-center justify-center gap-1 border border-transparent bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white shadow-xs transition-all hover:-translate-y-0.5 active:translate-y-0 cursor-pointer animate-in fade-in duration-200"
          >
            <Plus className="h-3 w-3" />
            <span>Add Field</span>
          </button>
          <button
            onClick={() => {
              resetZoneForm()
              if (fields.length > 0) setZoneFieldId(fields[0].id.toString())
              setActiveModal("zone")
            }}
            className="px-2.5 py-1.5 rounded-md font-bold text-[10px] uppercase tracking-wider flex items-center justify-center gap-1 border border-transparent bg-card hover:bg-muted/50 hover:border-gray-300 text-foreground transition-all hover:-translate-y-0.5 active:translate-y-0 cursor-pointer animate-in fade-in duration-200"
          >
            <Plus className="h-3 w-3 text-emerald-500" />
            <span>Add Zone</span>
          </button>
          <button
            onClick={() => {
              resetValveForm()
              if (fields.length > 0) {
                setValveFieldId(fields[0].id.toString())
                if (fields[0].zones?.length > 0) {
                  setValveZoneId(fields[0].zones[0].id.toString())
                }
              }
              setActiveModal("valve")
            }}
            className="px-2.5 py-1.5 rounded-md font-bold text-[10px] uppercase tracking-wider flex items-center justify-center gap-1 border border-transparent bg-card hover:bg-muted/50 hover:border-gray-300 text-foreground transition-all hover:-translate-y-0.5 active:translate-y-0 cursor-pointer animate-in fade-in duration-200"
          >
            <Plus className="h-3 w-3 text-teal-500" />
            <span>Map Valve</span>
          </button>
        </div>
      </div>

      {/* 2. Stats Dashboard Overview Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card className="shadow-xs border border-transparent bg-background hover:-translate-y-0.5 hover:shadow-md hover:border-emerald-500/30 transition-all duration-300">
          <CardContent className="p-4 flex items-center gap-4">
            <div className="p-3 rounded-xl bg-emerald-500/5 text-emerald-600 dark:text-emerald-400 border border-emerald-500/10">
              <FolderOpen className="h-5 w-5" />
            </div>
            <div>
              <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Total Sectors</p>
              <h3 className="text-xl font-black text-foreground mt-0.5">{totalFields} Fields</h3>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-xs border border-transparent bg-background hover:-translate-y-0.5 hover:shadow-md hover:border-teal-500/30 transition-all duration-300">
          <CardContent className="p-4 flex items-center gap-4">
            <div className="p-3 rounded-xl bg-teal-500/5 text-teal-600 dark:text-teal-400 border border-teal-500/10">
              <Layers className="h-5 w-5" />
            </div>
            <div>
              <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Configured Zones</p>
              <h3 className="text-xl font-black text-foreground mt-0.5">{totalZones} Zones</h3>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-xs border border-transparent bg-background hover:-translate-y-0.5 hover:shadow-md hover:border-blue-500/30 transition-all duration-300">
          <CardContent className="p-4 flex items-center gap-4">
            <div className="p-3 rounded-xl bg-blue-500/5 text-blue-600 dark:text-blue-400 border border-blue-500/10">
              <Droplet className={`h-5 w-5 ${activeValves > 0 ? "animate-bounce" : ""}`} />
            </div>
            <div>
              <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Active Actuators</p>
              <h3 className="text-xl font-black text-foreground mt-0.5">
                {activeValves} / {totalValves} <span className="text-[10px] font-bold text-emerald-600 dark:text-emerald-400 ml-1">Open</span>
              </h3>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-xs border border-transparent bg-background hover:-translate-y-0.5 hover:shadow-md hover:border-amber-500/30 transition-all duration-300">
          <CardContent className="p-4 flex items-center gap-4">
            <div className="p-3 rounded-xl bg-amber-500/5 text-amber-600 dark:text-amber-400 border border-amber-500/10">
              <ThermometerSun className="h-5 w-5" />
            </div>
            <div>
              <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Avg Soil Hydration</p>
              <h3 className="text-xl font-black text-foreground mt-0.5">
                {systemAvgMoisture}%
              </h3>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 3. Search toolbar - Smaller inputs for user-friendliness */}
      <div className="flex bg-muted/10 p-3 rounded-xl border border-gray-200/40">
        {/* Search */}
        <div className="relative w-full md:w-80">
          <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-muted-foreground" />
          <Input
            placeholder="Search sectors, zones or soil types..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-8.5 h-8.5 w-full bg-background border-gray-200/80 focus-visible:border-ring text-xs"
          />
        </div>
      </div>

      {/* 4. Tabular Hierarchy Index */}
      {filteredFields.length === 0 ? (
        <div className="flex flex-col items-center justify-center p-12 border border-dashed border-gray-200/60 rounded-2xl bg-card">
          <Info className="h-8 w-8 text-muted-foreground animate-pulse mb-3" />
          <h3 className="text-sm font-bold text-foreground">No Sectors Matching Criteria</h3>
          <p className="text-xs text-muted-foreground text-center mt-1 max-w-sm">No records found. Try modifying your query string.</p>
          <Button
            variant="outline"
            size="sm"
            onClick={() => {
              setSearchQuery("")
            }}
            className="mt-4 border-emerald-500/20 text-emerald-600 dark:text-emerald-400 font-semibold cursor-pointer"
          >
            Reset Filters
          </Button>
        </div>
      ) : (
        <div className="border border-gray-200/80 rounded-2xl bg-card overflow-hidden shadow-xs backdrop-blur-md">
          <Table>
            <TableHeader className="bg-muted/20 border-b border-gray-200/80">
              <TableRow>
                <TableHead className="w-12 text-center"></TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground">Field / Sector Name</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground">Location</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground">Acreage</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground">Soil Profile</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground text-center">Pump Motor</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground text-center">Zones</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground text-right pr-6">Manage</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredFields.map((field) => {
                const isCollapsed = collapsedFields[field.id] ?? true
                const fieldZones = field.zones || []

                // Calculate average soil moisture
                const avgMoisture = fieldZones.length > 0
                  ? (fieldZones.reduce((sum, z) => sum + z.moisture, 0) / fieldZones.length).toFixed(1)
                  : "N/A"

                return (
                  <React.Fragment key={field.id}>
                    {/* Primary Field Row */}
                    <TableRow className={`hover:bg-muted/20 font-medium ${!isCollapsed ? "bg-muted/5 border-b-transparent" : "border-b border-gray-200/60"}`}>
                      <TableCell className="text-center">
                        <button
                          onClick={() => toggleCollapse(field.id)}
                          className={`p-1 rounded-md hover:bg-muted text-muted-foreground transition-all duration-200 cursor-pointer ${!isCollapsed ? "bg-muted/80 text-emerald-600 rotate-180" : ""
                            }`}
                          title={isCollapsed ? "Show Zones" : "Hide Zones"}
                        >
                          <ChevronDown className="h-3.5 w-3.5 transition-transform" />
                        </button>
                      </TableCell>
                      <TableCell className="font-bold text-foreground py-3">
                        <span className="flex items-center gap-2">
                          <div className="h-7 w-7 rounded-lg bg-emerald-500/10 flex items-center justify-center border border-emerald-500/20 text-emerald-600">
                            <Sprout className="h-4 w-4" />
                          </div>
                          <span>{field.name}</span>
                        </span>
                      </TableCell>
                      <TableCell>
                        <span className="inline-flex items-center gap-1 text-[10px] font-bold text-muted-foreground bg-muted/70 px-2 py-0.5 rounded border border-gray-200/30 font-mono">
                          <MapPin className="h-2.5 w-2.5 text-emerald-500" />
                          {field.location}
                        </span>
                      </TableCell>
                      <TableCell className="text-xs text-foreground font-semibold">{field.area}</TableCell>
                      <TableCell className="text-xs text-muted-foreground font-medium">{field.soilType}</TableCell>
                      <TableCell className="text-center py-3">
                        <div className="flex items-center justify-center gap-2">
                          <button
                            onClick={() => toggleMotor(field.id)}
                            className={`p-1.5 rounded-lg transition-all duration-300 border flex items-center justify-center gap-1 ${
                              field.motorStatus === "On"
                                ? "bg-emerald-500/10 border-emerald-500/35 text-emerald-600 dark:text-emerald-400 shadow-[0_0_12px_rgba(16,185,129,0.15)]"
                                : "bg-muted border-border text-muted-foreground hover:bg-muted/80"
                            } cursor-pointer`}
                            title={field.motorStatus === "On" ? "Shut off Motor (Closes all valves)" : "Turn Motor On"}
                          >
                            <Power className={`h-3.5 w-3.5 ${field.motorStatus === "On" ? "animate-pulse" : ""}`} />
                          </button>
                          <span className={`text-[10px] font-black tracking-wider uppercase ${
                            field.motorStatus === "On"
                              ? "text-emerald-600 dark:text-emerald-400 animate-pulse font-black"
                              : "text-muted-foreground"
                          }`}>
                            {field.motorStatus === "On" ? "ON" : "OFF"}
                          </span>
                        </div>
                      </TableCell>
                      <TableCell className="text-center">
                        <span className="text-xs font-bold bg-muted px-2 py-0.5 rounded border border-gray-200/20">
                          {fieldZones.length} Zones
                        </span>
                      </TableCell>
                      <TableCell className="text-right pr-6">
                        <div className="flex items-center justify-end gap-1">
                          {/* Small Table Actions */}
                          <button
                            onClick={() => openAddZoneForField(field.id)}
                            className="p-1 rounded-md hover:bg-emerald-500 hover:text-white dark:hover:bg-emerald-950/40 text-emerald-600 border border-gray-200/40 transition-all cursor-pointer"
                            title="Add Zone"
                          >
                            <Plus className="h-3 w-3" />
                          </button>
                          <button
                            onClick={() => handleDeleteField(field.id)}
                            className="p-1 rounded-md hover:bg-red-500 hover:text-white text-red-500 border border-border/40 transition-all cursor-pointer"
                            title="Delete Field"
                          >
                            <Trash2 className="h-3 w-3" />
                          </button>
                        </div>
                      </TableCell>
                    </TableRow>

                    {/* Zones Sub-Table (Revealed under Field Row) */}
                    {!isCollapsed && (
                      <TableRow className="bg-muted/10 border-b border-gray-200/60 hover:bg-transparent">
                        <TableCell colSpan={9} className="p-3 pl-12 pr-6">
                          {fieldZones.length === 0 ? (
                            <div className="text-xs text-muted-foreground italic py-3 text-center bg-background border border-dashed border-gray-200/50 rounded-xl">
                              No irrigation zones configured.
                              <button
                                onClick={() => openAddZoneForField(field.id)}
                                className="text-emerald-600 font-bold ml-1 hover:underline cursor-pointer"
                              >
                                Create Zone
                              </button>
                            </div>
                          ) : (
                            <div className="border border-gray-200/50 rounded-xl overflow-hidden bg-background shadow-xs">
                              <Table>
                                <TableHeader className="bg-muted/30">
                                  <TableRow>
                                    <TableHead className="w-12 text-center"></TableHead>
                                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Zone Sector</TableHead>
                                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Line Range</TableHead>
                                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Soil Moisture Gauge</TableHead>
                                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider text-center">Mapped Valves</TableHead>
                                    <TableHead className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider text-right pr-4">Configure</TableHead>
                                  </TableRow>
                                </TableHeader>
                                <TableBody>
                                  {fieldZones.map((zone) => {
                                    const isZoneCollapsed = collapsedZones[zone.id] ?? true
                                    const zoneValves = zone.valves || []
                                    const isDry = zone.moisture < 25
                                    const activeValvesCount = zoneValves.filter(v => v.status === "Open").length

                                    const hydrationColor = zone.moisture > 70
                                      ? "bg-blue-500 shadow-xs shadow-blue-500/25"
                                      : zone.moisture >= 25
                                        ? "bg-emerald-500 shadow-xs shadow-emerald-500/25"
                                        : "bg-amber-500 shadow-xs shadow-amber-500/25 animate-pulse"

                                    return (
                                      <React.Fragment key={zone.id}>
                                        {/* Zone Row */}
                                        <TableRow className={`hover:bg-muted/10 ${!isZoneCollapsed ? "bg-muted/5 border-b-transparent" : "border-b border-border/40"}`}>
                                          <TableCell className="text-center">
                                            <span className="flex items-center justify-center gap-1">
                                              {/* Styled vector line guide representing branch connector */}
                                              <div className="w-3.5 h-3 border-l border-b border-border/80 rounded-bl-sm select-none -translate-y-0.5" />
                                              <button
                                                onClick={() => toggleZoneCollapse(zone.id)}
                                                className={`p-0.5 rounded-md hover:bg-muted text-muted-foreground transition-all duration-200 cursor-pointer ${!isZoneCollapsed ? "bg-muted/80 text-teal-600 rotate-180" : ""
                                                  }`}
                                                title={isZoneCollapsed ? "Open Valve Panel" : "Close Valve Panel"}
                                              >
                                                <ChevronDown className="h-3 w-3" />
                                              </button>
                                            </span>
                                          </TableCell>
                                          <TableCell className="font-bold text-xs text-foreground">
                                            <span className="flex items-center gap-1.5">
                                              <Layers className="h-3.5 w-3.5 text-emerald-600" />
                                              {zone.name}
                                            </span>
                                          </TableCell>
                                          <TableCell className="text-xs text-muted-foreground font-mono font-semibold">{zone.location}</TableCell>
                                          <TableCell className="w-64">
                                            <div className="flex items-center gap-3">
                                              <div className="w-28 bg-muted dark:bg-muted/20 h-2 rounded-full overflow-hidden border border-border/10">
                                                <div
                                                  className={`h-full rounded-full transition-all duration-500 ${hydrationColor}`}
                                                  style={{ width: `${Math.min(zone.moisture, 100)}%` }}
                                                ></div>
                                              </div>

                                              <div className="inline-flex items-center gap-1 font-mono font-bold text-xs">
                                                <span className={isDry ? "text-amber-500 animate-pulse font-black" : "text-foreground"}>
                                                  {zone.moisture}%
                                                </span>
                                                {isDry ? (
                                                  <TrendingDown className="h-3 w-3 text-amber-500 animate-bounce" />
                                                ) : activeValvesCount > 0 ? (
                                                  <TrendingUp className="h-3 w-3 text-emerald-500 animate-pulse" />
                                                ) : null}
                                              </div>

                                              {isDry && (
                                                <span className="text-[7px] text-amber-500 bg-amber-500/10 px-1 py-0.5 rounded border border-amber-500/20 uppercase tracking-widest font-black animate-pulse">
                                                  Dry
                                                </span>
                                              )}
                                            </div>
                                          </TableCell>
                                          <TableCell className="text-center">
                                            <span className={`text-[10px] font-bold px-2 py-0.5 rounded-md border ${activeValvesCount > 0
                                              ? "bg-emerald-50 border-emerald-500/20 text-emerald-600 dark:bg-emerald-950/40 dark:text-emerald-400 animate-pulse"
                                              : "bg-muted border-border/40 text-muted-foreground"
                                              }`}>
                                              {zoneValves.length} Valves {activeValvesCount > 0 && `(${activeValvesCount} watering)`}
                                            </span>
                                          </TableCell>
                                          <TableCell className="text-right pr-4">
                                            <div className="flex items-center justify-end gap-1">
                                              <button
                                                onClick={() => openAddValveForZone(field.id, zone.id)}
                                                className="p-1 rounded-md hover:bg-teal-500 hover:text-white dark:hover:bg-teal-950/40 text-teal-600 border border-border/40 transition-all cursor-pointer"
                                                title="Add Valve"
                                              >
                                                <Plus className="h-3 w-3" />
                                              </button>
                                              <button
                                                onClick={() => handleDeleteZone(field.id, zone.id)}
                                                className="p-1 rounded-md hover:bg-red-500 hover:text-white text-red-500 border border-border/40 transition-all cursor-pointer"
                                                title="Delete Zone"
                                              >
                                                <Trash2 className="h-3 w-3" />
                                              </button>
                                            </div>
                                          </TableCell>
                                        </TableRow>

                                        {/* Valves Sub-Table (Revealed under Zone Row) */}
                                        {!isZoneCollapsed && (
                                          <TableRow className="bg-muted/5 hover:bg-transparent">
                                            <TableCell colSpan={6} className="p-3 pl-10 pr-4">
                                              {zoneValves.length === 0 ? (
                                                <div className="text-[10px] text-muted-foreground italic py-3 text-center bg-background border border-border/40 rounded-xl">
                                                  No valves currently mapped to this zone line.
                                                  <button
                                                    onClick={() => openAddValveForZone(field.id, zone.id)}
                                                    className="text-teal-600 font-bold ml-1 hover:underline cursor-pointer"
                                                  >
                                                    Map New Valve
                                                  </button>
                                                </div>
                                              ) : (
                                                <div className="border border-border/40 rounded-xl overflow-hidden bg-background shadow-xs animate-in slide-in-from-top-1 duration-150">
                                                  <Table>
                                                    <TableHeader className="bg-muted/10">
                                                      <TableRow>
                                                        <TableHead className="w-10"></TableHead>
                                                        <TableHead className="h-9 text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Valve Label</TableHead>
                                                        <TableHead className="h-9 text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Class Type</TableHead>
                                                        <TableHead className="h-9 text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Capacity Rating</TableHead>
                                                        <TableHead className="h-9 text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Simulated Live Flow</TableHead>
                                                        <TableHead className="h-9 text-[9px] font-bold text-muted-foreground uppercase tracking-wider text-center">Manual Actuator</TableHead>
                                                        <TableHead className="h-9 text-[9px] font-bold text-muted-foreground uppercase tracking-wider text-right pr-4">Unmap</TableHead>
                                                      </TableRow>
                                                    </TableHeader>
                                                    <TableBody>
                                                      {zoneValves.map((valve) => {
                                                        const isOpen = valve.status === "Open"
                                                        return (
                                                          <TableRow key={valve.id} className="hover:bg-muted/10 h-10 border-b border-border/30 last:border-b-0">
                                                            <TableCell className="text-center w-10 py-1">
                                                              {/* Styled nested branch connector tick representing second tier guide */}
                                                              <div className="w-3.5 h-3 border-l border-b border-border/80 rounded-bl-sm select-none -translate-y-1 ml-4" />
                                                            </TableCell>
                                                            <TableCell className="py-1 text-xs font-bold text-foreground">
                                                              <span className="flex items-center gap-1.5">
                                                                <Power className={`h-3 w-3 ${isOpen ? "text-emerald-500 animate-pulse" : "text-muted-foreground/50"}`} />
                                                                {valve.name}
                                                              </span>
                                                            </TableCell>
                                                            <TableCell className="py-1">
                                                              <span className={`text-[8px] font-black border px-1.5 py-0.5 rounded-md uppercase tracking-wider ${getValveTypeStyle(valve.type)}`}>
                                                                {valve.type}
                                                              </span>
                                                            </TableCell>
                                                            <TableCell className="py-1 text-xs font-mono font-medium text-foreground">{valve.capacity.toFixed(1)} L/m</TableCell>
                                                            <TableCell className="py-1 text-xs font-mono">
                                                              {isOpen ? (
                                                                <span className="text-emerald-600 dark:text-emerald-400 font-bold flex items-center gap-1.5 animate-pulse">
                                                                  <span className="relative flex h-1.5 w-1.5">
                                                                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                                                                    <span className="relative inline-flex rounded-full h-1.5 w-1.5 bg-emerald-500"></span>
                                                                  </span>
                                                                  {valve.flowRate.toFixed(1)} L/m
                                                                </span>
                                                              ) : (
                                                                <span className="text-muted-foreground text-[10px]">0.0 L/m (Idle)</span>
                                                              )}
                                                            </TableCell>
                                                            <TableCell className="py-1 text-center">
                                                              <button
                                                                onClick={() => toggleValve(field.id, zone.id, valve.id)}
                                                                className={`px-2 py-0.5 rounded text-[8px] font-black tracking-wider transition-all duration-200 ${isOpen
                                                                  ? "bg-red-500 hover:bg-red-600 text-white shadow-xs"
                                                                  : "bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white shadow-xs"
                                                                  } cursor-pointer hover:-translate-y-0.5 active:translate-y-0`}
                                                              >
                                                                {isOpen ? "CLOSE" : "OPEN"}
                                                              </button>
                                                            </TableCell>
                                                            <TableCell className="py-1 text-right pr-4">
                                                              <button
                                                                onClick={() => handleDeleteValve(field.id, zone.id, valve.id)}
                                                                className="p-1 rounded hover:bg-red-50 text-red-500 hover:text-red-600 transition-colors border border-transparent hover:border-red-500/10 cursor-pointer"
                                                                title="Unmap Valve"
                                                              >
                                                                <X className="h-3 w-3" />
                                                              </button>
                                                            </TableCell>
                                                          </TableRow>
                                                        )
                                                      })}
                                                    </TableBody>
                                                  </Table>
                                                </div>
                                              )}
                                            </TableCell>
                                          </TableRow>
                                        )}
                                      </React.Fragment>
                                    )
                                  })}
                                </TableBody>
                              </Table>
                            </div>
                          )}
                        </TableCell>
                      </TableRow>
                    )}
                  </React.Fragment>
                )
              })}
            </TableBody>
          </Table>
        </div>
      )}

      {/* ============================================================== */}
      {/* 5. GORGEOUS CREATION MODALS BACKDROP OVERLAYS */}
      {/* ============================================================== */}
      {activeModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/80 backdrop-blur-md animate-in fade-in duration-300">
          <Card className="w-full max-w-md shadow-2xl border border-emerald-500/20 bg-background/95 animate-in zoom-in-95 duration-200 overflow-hidden relative">
            {/* Soft decorative header mesh */}
            <div className="absolute top-0 inset-x-0 h-1.5 bg-gradient-to-r from-emerald-500 via-teal-400 to-blue-500"></div>

            <CardHeader className="flex flex-row items-center justify-between pb-4 border-b border-border/60 pt-6">
              <div>
                <CardTitle className="text-sm font-bold flex items-center gap-2">
                  <div className="h-5 w-5 rounded-md bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
                    <Plus className="h-3.5 w-3.5" />
                  </div>
                  {activeModal === "field" && "Create Field Sector"}
                  {activeModal === "zone" && "Add Watering Zone"}
                  {activeModal === "valve" && "Map Actuator Valve"}
                </CardTitle>
                <CardDescription className="text-[10px] mt-1 font-medium">
                  {activeModal === "field" && "Add a physical field segment or property layout."}
                  {activeModal === "zone" && "Define a core hydration area inside a primary field."}
                  {activeModal === "valve" && "Link a hardware valve solenoid/dripline to a zone pipeline."}
                </CardDescription>
              </div>
              <button
                onClick={() => setActiveModal(null)}
                className="p-1 rounded-md hover:bg-muted text-muted-foreground transition-colors cursor-pointer"
              >
                <X className="h-4 w-4" />
              </button>
            </CardHeader>

            <CardContent className="pt-4 pb-6">
              {/* Field Form */}
              {activeModal === "field" && (
                <form onSubmit={handleAddField} className="flex flex-col gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Field Sector Label</label>
                    <Input
                      placeholder="e.g. North Ridge Orchard, East Vineyard"
                      value={fieldName}
                      onChange={(e) => setFieldName(e.target.value)}
                      required
                      className="border-border/80 focus-visible:border-ring text-xs animate-in fade-in"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="flex flex-col gap-1.5">
                      <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Sector Location Code</label>
                      <Input
                        placeholder="e.g. Sector A-3"
                        value={fieldLocation}
                        onChange={(e) => setFieldLocation(e.target.value)}
                        className="border-border/80 focus-visible:border-ring text-xs font-mono"
                      />
                    </div>
                    <div className="flex flex-col gap-1.5">
                      <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Total Area (Acreage)</label>
                      <Input
                        placeholder="e.g. 10.0 acres"
                        value={fieldArea}
                        onChange={(e) => setFieldArea(e.target.value)}
                        className="border-border/80 focus-visible:border-ring text-xs"
                      />
                    </div>
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Soil Profile Type</label>
                    <Input
                      placeholder="e.g. Sandy Loam, Clay Mixture"
                      value={fieldSoilType}
                      onChange={(e) => setFieldSoilType(e.target.value)}
                      className="border-border/80 focus-visible:border-ring text-xs"
                    />
                  </div>

                  <div className="flex justify-end gap-2 border-t border-border/50 pt-4 mt-2">
                    <Button type="button" variant="outline" onClick={() => setActiveModal(null)} className="h-8 px-3 rounded-md text-[9px] font-bold tracking-wider cursor-pointer">
                      Cancel
                    </Button>
                    <Button type="submit" className="h-8 px-3 rounded-md bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white text-[9px] font-bold tracking-wider cursor-pointer">
                      Save Field
                    </Button>
                  </div>
                </form>
              )}

              {/* Zone Form */}
              {activeModal === "zone" && (
                <form onSubmit={handleAddZone} className="flex flex-col gap-4">
                  {fields.length === 0 ? (
                    <div className="p-4 text-xs text-amber-600 bg-amber-500/10 border border-amber-500/25 rounded-xl font-semibold flex items-center gap-2">
                      <AlertCircle className="h-4 w-4 shrink-0" />
                      <span>Please configure a Field Sector first before mapping a hydration zone.</span>
                    </div>
                  ) : (
                    <>
                      <div className="flex flex-col gap-1.5">
                        <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Parent Field Sector</label>
                        <select
                          className="h-10 w-full border border-transparent border-b-input bg-transparent text-xs font-semibold focus:border-b-ring outline-none text-foreground py-1"
                          value={zoneFieldId}
                          onChange={(e) => setZoneFieldId(e.target.value)}
                          required
                        >
                          {fields.map(f => (
                            <option key={f.id} value={f.id} className="bg-card text-foreground">{f.name}</option>
                          ))}
                        </select>
                      </div>
                      <div className="flex flex-col gap-1.5">
                        <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Zone Identifier Label</label>
                        <Input
                          placeholder="e.g. Row 1-15 Cabernet Sauvignon"
                          value={zoneName}
                          onChange={(e) => setZoneName(e.target.value)}
                          required
                          className="border-border/80 focus-visible:border-ring text-xs"
                        />
                      </div>
                      <div className="grid grid-cols-2 gap-4">
                        <div className="flex flex-col gap-1.5">
                          <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Row Layout Ranges</label>
                          <Input
                            placeholder="e.g. Row 12-24"
                            value={zoneLocation}
                            onChange={(e) => setZoneLocation(e.target.value)}
                            className="border-border/80 focus-visible:border-ring text-xs font-mono"
                          />
                        </div>
                        <div className="flex flex-col gap-1.5">
                          <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Initial Moisture (%)</label>
                          <Input
                            type="number"
                            min="10"
                            max="90"
                            placeholder="45"
                            value={zoneMoisture}
                            onChange={(e) => setZoneMoisture(e.target.value)}
                            className="border-border/80 focus-visible:border-ring text-xs font-mono"
                          />
                        </div>
                      </div>

                      <div className="flex justify-end gap-2 border-t border-border/50 pt-4 mt-2">
                        <Button type="button" variant="outline" onClick={() => setActiveModal(null)} className="h-8 px-3 rounded-md text-[9px] font-bold tracking-wider cursor-pointer">
                          Cancel
                        </Button>
                        <Button type="submit" className="h-8 px-3 rounded-md bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white text-[9px] font-bold tracking-wider cursor-pointer">
                          Save Zone
                        </Button>
                      </div>
                    </>
                  )}
                </form>
              )}

              {/* Valve Form */}
              {activeModal === "valve" && (
                <form onSubmit={handleAddValve} className="flex flex-col gap-4">
                  {fields.length === 0 ? (
                    <div className="p-4 text-xs text-amber-600 bg-amber-500/10 border border-amber-500/25 rounded-xl font-semibold flex items-center gap-2">
                      <AlertCircle className="h-4 w-4 shrink-0" />
                      <span>Configure a Field and Zone first.</span>
                    </div>
                  ) : (
                    <>
                      <div className="grid grid-cols-2 gap-4">
                        <div className="flex flex-col gap-1.5">
                          <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Target Field Sector</label>
                          <select
                            className="h-10 w-full border border-transparent border-b-input bg-transparent text-xs font-semibold focus:border-b-ring outline-none text-foreground py-1"
                            value={valveFieldId}
                            onChange={(e) => {
                              setValveFieldId(e.target.value)
                              setValveZoneId("") // Reset zone when field changes
                            }}
                            required
                          >
                            {fields.map(f => (
                              <option key={f.id} value={f.id} className="bg-card text-foreground">{f.name}</option>
                            ))}
                          </select>
                        </div>

                        <div className="flex flex-col gap-1.5">
                          <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Watering Line Zone</label>
                          <select
                            className="h-10 w-full border border-transparent border-b-input bg-transparent text-xs font-semibold focus:border-b-ring outline-none text-foreground py-1"
                            value={valveZoneId}
                            onChange={(e) => setValveZoneId(e.target.value)}
                            required
                          >
                            <option value="" disabled className="bg-card text-muted-foreground">Select zone...</option>
                            {getSelectedFieldZones().map(z => (
                              <option key={z.id} value={z.id} className="bg-card text-foreground">{z.name}</option>
                            ))}
                          </select>
                          {getSelectedFieldZones().length === 0 && (
                            <span className="text-[8px] text-amber-500 mt-1 font-bold">No active zones inside selected field.</span>
                          )}
                        </div>
                      </div>

                      <div className="flex flex-col gap-1.5">
                        <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Valve Label Designation</label>
                        <Input
                          placeholder="e.g. Master Solenoid Valve, Dripline Block D"
                          value={valveName}
                          onChange={(e) => setValveName(e.target.value)}
                          required
                          className="border-border/80 focus-visible:border-ring text-xs"
                        />
                      </div>

                      <div className="grid grid-cols-2 gap-4">
                        <div className="flex flex-col gap-1.5">
                          <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Actuator Hardware Class</label>
                          <select
                            className="h-10 w-full border border-transparent border-b-input bg-transparent text-xs font-semibold focus:border-b-ring outline-none text-foreground py-1"
                            value={valveType}
                            onChange={(e) => setValveType(e.target.value)}
                            required
                          >
                            <option value="Solenoid" className="bg-card">Solenoid Valve</option>
                            <option value="Drip" className="bg-card">Drip Line Relay</option>
                            <option value="Sprinkler" className="bg-card">Sprinkler Head</option>
                            <option value="Mister" className="bg-card">Micro-Misting Spray</option>
                          </select>
                        </div>

                        <div className="flex flex-col gap-1.5">
                          <label className="text-[9px] font-bold text-muted-foreground uppercase tracking-wider">Max Capacity Flow Rate (L/m)</label>
                          <Input
                            type="number"
                            step="0.1"
                            placeholder="12.0"
                            value={valveCapacity}
                            onChange={(e) => setValveCapacity(e.target.value)}
                            required
                            className="border-border/80 focus-visible:border-ring text-xs font-mono"
                          />
                        </div>
                      </div>

                      <div className="flex justify-end gap-2 border-t border-border/50 pt-4 mt-2">
                        <Button type="button" variant="outline" onClick={() => setActiveModal(null)} className="h-8 px-3 rounded-md text-[9px] font-bold tracking-wider cursor-pointer">
                          Cancel
                        </Button>
                        <Button
                          type="submit"
                          disabled={!valveZoneId}
                          className="h-8 px-3 rounded-md bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white text-[9px] font-bold tracking-wider cursor-pointer disabled:opacity-50"
                        >
                          Save Valve
                        </Button>
                      </div>
                    </>
                  )}
                </form>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}

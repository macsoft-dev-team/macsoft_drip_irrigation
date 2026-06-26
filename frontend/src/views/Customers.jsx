import React, { useState, useEffect } from "react"
import { 
  Users, 
  Mail, 
  Phone, 
  MapPin, 
  Droplet, 
  Layers, 
  TrendingUp,
  Activity, 
  ArrowRight,
  ExternalLink,
  ShieldCheck,
  Power
} from "lucide-react"
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table"
import { initialUsers, initialFields } from "@/lib/mockData"

export default function Customers({ navigate }) {
  const [farmers, setFarmers] = useState([])
  const [fields, setFields] = useState([])

  useEffect(() => {
    // Load from localStorage or defaults
    const savedUsers = localStorage.getItem("drip_users")
    const loadedUsers = savedUsers ? JSON.parse(savedUsers) : initialUsers
    const farmerUsers = loadedUsers.filter(u => u.role?.toLowerCase() === "farmer")
    setFarmers(farmerUsers)

    const savedFields = localStorage.getItem("drip_fields")
    const loadedFields = savedFields ? JSON.parse(savedFields) : initialFields
    setFields(loadedFields)
  }, [])

  // Helper to get stats of a field
  const getFieldStats = (fieldId) => {
    if (!fieldId) return { name: "N/A", location: "N/A", zonesCount: 0, activeValves: 0, avgMoisture: "N/A", motorStatus: "Off" }
    
    const field = fields.find(f => f.id === fieldId)
    if (!field) return { name: "N/A", location: "N/A", zonesCount: 0, activeValves: 0, avgMoisture: "N/A", motorStatus: "Off" }

    const zones = field.zones || []
    const zonesCount = zones.length
    
    let activeValves = 0
    let moistureSum = 0
    let moistureCount = 0

    zones.forEach(zone => {
      activeValves += (zone.valves || []).filter(v => v.status === "Open").length
      if (zone.moisture !== undefined) {
        moistureSum += zone.moisture
        moistureCount++
      }
    })

    const avgMoisture = moistureCount > 0 
      ? (moistureSum / moistureCount).toFixed(1) + "%" 
      : "N/A"

    return {
      name: field.name,
      location: field.location,
      zonesCount,
      activeValves,
      avgMoisture,
      motorStatus: field.motorStatus || "Off"
    }
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-border/60">
        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 shadow-xs">
            <Users className="h-6 w-6" />
          </div>
          <div>
            <h2 className="text-xl font-bold tracking-tight text-foreground">Farmers & Customers</h2>
            <p className="text-xs text-muted-foreground mt-0.5">Manage customer portals, review individual irrigation parameters, and launch dedicated dashboards.</p>
          </div>
        </div>
      </div>

      {/* Farmers Table */}
      {farmers.length === 0 ? (
        <div className="flex flex-col items-center justify-center p-12 border border-dashed border-border rounded-2xl bg-card">
          <Users className="h-8 w-8 text-muted-foreground animate-pulse mb-3" />
          <h3 className="text-sm font-bold text-foreground">No Registered Customers</h3>
          <p className="text-xs text-muted-foreground text-center mt-1 max-w-sm">No user accounts with the role "Farmer" were found. Add some in the User Management page.</p>
          <button
            onClick={() => navigate("/users")}
            className="mt-4 px-4 py-2 text-xs font-bold bg-gradient-to-r from-emerald-600 to-teal-500 text-white rounded-lg hover:-translate-y-0.5 active:translate-y-0 transition-all cursor-pointer"
          >
            Manage Users
          </button>
        </div>
      ) : (
        <div className="border border-border rounded-xl bg-card overflow-hidden shadow-xs backdrop-blur-md">
          <Table>
            <TableHeader className="bg-muted/15 border-b border-border/80">
              <TableRow>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground uppercase">Farmer / Customer</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground uppercase">Contact Details</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground uppercase">Field Sector</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground uppercase text-center">Moisture Status</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground uppercase text-center">Infrastructure</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground uppercase text-center">Pump Status</TableHead>
                <TableHead className="text-[10px] font-bold tracking-wider text-muted-foreground uppercase text-right pr-6">Portal Access</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {farmers.map(farmer => {
                const stats = getFieldStats(farmer.fieldId)
                const isActive = farmer.status === "Active"

                return (
                  <TableRow key={farmer.id} className="hover:bg-emerald-500/5 dark:hover:bg-emerald-500/2 transition-colors">
                    {/* Customer */}
                    <TableCell className="py-3 font-semibold">
                      <div className="flex flex-col gap-1">
                        <span className="font-bold text-sm text-foreground">{farmer.name}</span>
                        <div className="flex items-center gap-1.5">
                          <span className={`inline-flex items-center gap-1 text-[8px] font-black border px-1.5 py-0.5 rounded-full uppercase tracking-wider ${
                            isActive 
                              ? "bg-emerald-500/10 text-emerald-600 dark:bg-emerald-500/20 dark:text-emerald-400 border-emerald-500/20" 
                              : "bg-slate-500/10 text-slate-500 border-slate-500/20"
                          }`}>
                            {farmer.status}
                          </span>
                          <span className="text-[9px] text-muted-foreground font-mono">ID: #{farmer.id}</span>
                        </div>
                      </div>
                    </TableCell>

                    {/* Contact details */}
                    <TableCell>
                      <div className="flex flex-col gap-1 text-[11px] text-muted-foreground">
                        <div className="flex items-center gap-1.5">
                          <Mail className="h-3 w-3 text-emerald-500/60" />
                          <span className="font-mono">{farmer.email}</span>
                        </div>
                        {farmer.mobile && (
                          <div className="flex items-center gap-1.5">
                            <Phone className="h-3 w-3 text-emerald-500/60" />
                            <span className="font-mono">{farmer.mobile}</span>
                          </div>
                        )}
                      </div>
                    </TableCell>

                    {/* Field Sector */}
                    <TableCell>
                      {stats.name !== "N/A" ? (
                        <div className="flex flex-col gap-1">
                          <span className="font-bold text-xs text-foreground flex items-center gap-1">
                            <MapPin className="h-3 w-3 text-emerald-500" />
                            {stats.name}
                          </span>
                          <span className="text-[9px] font-mono text-muted-foreground bg-muted/50 px-1.5 py-0.5 rounded border border-border/20 w-fit">{stats.location}</span>
                        </div>
                      ) : (
                        <span className="text-xs text-muted-foreground italic">No sector assigned</span>
                      )}
                    </TableCell>

                    {/* Soil Moisture */}
                    <TableCell className="text-center">
                      {stats.avgMoisture !== "N/A" ? (
                        <div className="inline-flex flex-col gap-0.5">
                          <span className="text-xs font-bold text-foreground">{stats.avgMoisture}</span>
                          <span className="text-[9px] text-muted-foreground">soil hydration</span>
                        </div>
                      ) : (
                        <span className="text-xs text-muted-foreground">N/A</span>
                      )}
                    </TableCell>

                    {/* Infrastructure */}
                    <TableCell className="text-center">
                      <div className="inline-flex flex-col gap-0.5 text-center">
                        <span className="text-xs font-bold text-foreground">
                          {stats.zonesCount} Zones
                        </span>
                        <span className={`text-[9px] font-bold ${stats.activeValves > 0 ? "text-blue-500 animate-pulse font-black" : "text-muted-foreground"}`}>
                          {stats.activeValves} Active Valves
                        </span>
                      </div>
                    </TableCell>

                    {/* Pump Status */}
                    <TableCell className="text-center">
                      <div className="inline-flex items-center justify-center gap-1.5">
                        <Power className={`h-3.5 w-3.5 ${stats.motorStatus === "On" ? "text-emerald-500 animate-pulse" : "text-muted-foreground/60"}`} />
                        <span className={`text-[10px] font-black uppercase tracking-wider ${
                          stats.motorStatus === "On" ? "text-emerald-600 dark:text-emerald-400 animate-pulse font-black" : "text-muted-foreground"
                        }`}>
                          {stats.motorStatus}
                        </span>
                      </div>
                    </TableCell>

                    {/* Portal Access Actions */}
                    <TableCell className="text-right pr-6">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          onClick={() => navigate(`/dashboard?farmerId=${farmer.id}`)}
                          className="px-2.5 py-1.5 rounded-lg bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white font-bold text-[9px] uppercase tracking-wider flex items-center justify-center gap-1 hover:-translate-y-0.5 active:translate-y-0 shadow-sm cursor-pointer transition-all duration-200"
                          title="Open specific farmer portal"
                        >
                          <span>Portal</span>
                          <ArrowRight className="h-3 w-3" />
                        </button>
                        <button
                          onClick={() => navigate("/fields")}
                          className="p-1.5 bg-muted hover:bg-muted/80 text-foreground border border-border rounded-lg text-[9px] font-bold cursor-pointer transition-colors"
                          title="Configure field sectors"
                        >
                          <ExternalLink className="h-3 w-3" />
                        </button>
                      </div>
                    </TableCell>
                  </TableRow>
                )
              })}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  )
}

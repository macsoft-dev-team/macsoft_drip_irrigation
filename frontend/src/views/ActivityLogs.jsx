import React, { useState, useEffect } from "react"
import { 
  ClipboardList, 
  Search, 
  Filter, 
  RefreshCw, 
  User, 
  Clock, 
  Tag, 
  SlidersHorizontal,
  FileSpreadsheet,
  AlertCircle
} from "lucide-react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"

export default function ActivityLogs() {
  const [logs, setLogs] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [searchQuery, setSearchQuery] = useState("")
  const [filterAction, setFilterAction] = useState("all")
  const [filterEntity, setFilterEntity] = useState("all")

  // Fallback Mock Data for high-fidelity offline preview
  const mockLogs = [
    {
      id: "8",
      action: "trigger",
      entityType: "command",
      entityId: "8",
      details: JSON.stringify({ targetType: "zone", targetId: "1", action: "open", name: "Tomato" }),
      createdAt: "2026-06-27T09:48:51.000Z",
      user: { name: "Farmer John", role: "farmer" }
    },
    {
      id: "7",
      action: "create",
      entityType: "schedule",
      entityId: "2",
      details: JSON.stringify({ name: "Tomato Early Morning", targetType: "zone" }),
      createdAt: "2026-06-27T09:44:03.000Z",
      user: { name: "Farmer John", role: "farmer" }
    },
    {
      id: "6",
      action: "update",
      entityType: "valve",
      entityId: "1",
      details: JSON.stringify({ name: "Valve A", status: "open", coilAddress: 0 }),
      createdAt: "2026-06-27T09:43:55.000Z",
      user: { name: "Support Agent", role: "technician" }
    },
    {
      id: "5",
      action: "create",
      entityType: "valve",
      entityId: "4",
      details: JSON.stringify({ name: "Valve D", coilAddress: 1, slaveBoardId: "1" }),
      createdAt: "2026-06-27T09:40:12.000Z",
      user: { name: "Admin Manager", role: "admin" }
    },
    {
      id: "4",
      action: "create",
      entityType: "zone",
      entityId: "1",
      details: JSON.stringify({ name: "Tomato", description: "North Field Drip" }),
      createdAt: "2026-06-27T09:36:38.000Z",
      user: { name: "Farmer John", role: "farmer" }
    },
    {
      id: "3",
      action: "create",
      entityType: "field",
      entityId: "1",
      details: JSON.stringify({ name: "North Farm" }),
      createdAt: "2026-06-27T09:36:16.000Z",
      user: { name: "Admin Manager", role: "admin" }
    }
  ]

  const fetchLogs = async () => {
    setLoading(true)
    setError(null)
    try {
      // Fetch token from local storage (or default placeholder in simulation)
      const token = localStorage.getItem("drip_admin_token") || "mock-token-admin"
      const res = await fetch("http://localhost:4000/api/admin/activity-logs", {
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json"
        }
      })
      if (!res.ok) {
        throw new Error(`API responded with status ${res.status}`)
      }
      const data = await res.json()
      // Unwrap if envelope exists
      const logsList = data.data || data.activityLogs || data
      if (Array.isArray(logsList)) {
        setLogs(logsList)
      } else {
        throw new Error("Invalid array data format returned")
      }
    } catch (err) {
      console.warn("Backend API offline or unauthorized. Using local fallback mock logs.", err)
      setLogs(mockLogs)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchLogs()
  }, [])

  // Filter & Search Logic
  const filteredLogs = logs.filter(log => {
    const matchesAction = filterAction === "all" || log.action === filterAction
    const matchesEntity = filterEntity === "all" || log.entityType === filterEntity
    
    let parsedDetails = ""
    try {
      if (log.details) {
        const parsed = typeof log.details === "string" ? JSON.parse(log.details) : log.details
        parsedDetails = JSON.stringify(parsed)
      }
    } catch (_) {}

    const textString = `${log.user?.name || ""} ${log.user?.role || ""} ${log.action} ${log.entityType} ${log.entityId} ${parsedDetails}`.toLowerCase()
    const matchesSearch = textString.includes(searchQuery.toLowerCase())
    
    return matchesAction && matchesEntity && matchesSearch
  })

  // Format Helper for Details column
  const renderDetails = (log) => {
    try {
      if (!log.details) return <span className="text-muted-foreground italic">No details</span>
      const data = typeof log.details === "string" ? JSON.parse(log.details) : log.details
      
      if (log.entityType === "command" && log.action === "trigger") {
        return (
          <span>
            Triggered <strong>{data.action}</strong> on {data.targetType} <strong>{data.name || `#${data.targetId}`}</strong>
          </span>
        )
      }
      if (log.entityType === "schedule") {
        return (
          <span>
            {log.action === "create" ? "Set up" : "Updated"} schedule <strong>"{data.name}"</strong> targeting {data.targetType}
          </span>
        )
      }
      if (log.entityType === "valve") {
        return (
          <span>
            {log.action === "create" ? "Added" : "Modified"} valve <strong>"{data.name}"</strong> (Coil {data.coilAddress})
          </span>
        )
      }
      if (log.entityType === "zone") {
        return (
          <span>
            {log.action === "create" ? "Added" : "Updated"} Zone <strong>"{data.name}"</strong>
          </span>
        )
      }
      if (log.entityType === "field") {
        return (
          <span>
            {log.action === "create" ? "Registered" : "Updated"} Field <strong>"{data.name}"</strong>
          </span>
        )
      }
      return <span className="font-mono text-[10px] text-muted-foreground">{JSON.stringify(data)}</span>
    } catch (_) {
      return <span className="font-mono text-[10px] text-muted-foreground">{String(log.details)}</span>
    }
  }

  const getActionColor = (action) => {
    switch (action) {
      case "create":
        return "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20"
      case "update":
        return "bg-sky-500/10 text-sky-600 dark:text-sky-400 border-sky-500/20"
      case "delete":
        return "bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20"
      case "trigger":
        return "bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border-indigo-500/20"
      default:
        return "bg-muted text-muted-foreground"
    }
  }

  const getRoleColor = (role) => {
    switch (role?.toLowerCase()) {
      case "admin":
        return "bg-red-500/15 text-red-600 dark:text-red-400"
      case "technician":
        return "bg-amber-500/15 text-amber-600 dark:text-amber-400"
      case "farmer":
        return "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
      default:
        return "bg-muted text-muted-foreground"
    }
  }

  const formatTime = (isoString) => {
    try {
      const d = new Date(isoString)
      return d.toLocaleString("en-US", {
        month: "short",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit"
      })
    } catch (_) {
      return isoString
    }
  }

  return (
    <div className="flex flex-col gap-6 text-xs">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-border/60">
        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 shadow-xs">
            <ClipboardList className="h-6 w-6" />
          </div>
          <div>
            <h2 className="text-xl font-bold tracking-tight text-foreground">System Activity Logs</h2>
            <p className="text-xs text-muted-foreground mt-0.5">Audit trail of all administrative events, zone triggers, and device configuration updates.</p>
          </div>
        </div>
        
        <button 
          onClick={fetchLogs}
          disabled={loading}
          className="flex items-center justify-center gap-1.5 bg-card hover:bg-muted/80 text-foreground font-bold px-3.5 py-2 rounded-lg border border-border transition-all shadow-xs disabled:opacity-50"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${loading ? "animate-spin text-emerald-500" : ""}`} />
          <span>Refresh Logs</span>
        </button>
      </div>

      {/* Control Panel: Filters & Search */}
      <div className="grid gap-3 md:flex md:items-center md:justify-between p-3.5 rounded-xl border border-border bg-card shadow-[0_8px_30px_rgb(0,0,0,0.01)]">
        
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
          <input 
            type="text" 
            placeholder="Search logs (user name, action details, ID)..." 
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-4 py-2 border border-border rounded-lg bg-background text-foreground outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all text-xs"
          />
        </div>

        {/* Filters */}
        <div className="flex flex-wrap items-center gap-3">
          
          <div className="flex items-center gap-1.5">
            <SlidersHorizontal className="h-3.5 w-3.5 text-muted-foreground" />
            <span className="font-semibold text-muted-foreground">Action:</span>
            <select 
              value={filterAction} 
              onChange={(e) => setFilterAction(e.target.value)}
              className="p-2 border border-border rounded-lg bg-background text-foreground focus:border-emerald-500 outline-hidden font-medium text-xs"
            >
              <option value="all">All Actions</option>
              <option value="create">Create</option>
              <option value="update">Update</option>
              <option value="delete">Delete</option>
              <option value="trigger">Trigger</option>
            </select>
          </div>

          <div className="flex items-center gap-1.5">
            <Tag className="h-3.5 w-3.5 text-muted-foreground" />
            <span className="font-semibold text-muted-foreground">Entity:</span>
            <select 
              value={filterEntity} 
              onChange={(e) => setFilterEntity(e.target.value)}
              className="p-2 border border-border rounded-lg bg-background text-foreground focus:border-emerald-500 outline-hidden font-medium text-xs"
            >
              <option value="all">All Entities</option>
              <option value="field">Field</option>
              <option value="zone">Zone</option>
              <option value="valve">Valve</option>
              <option value="schedule">Schedule</option>
              <option value="command">Command</option>
            </select>
          </div>

        </div>

      </div>

      {/* Logs Table Card */}
      <Card className="shadow-[0_8px_30px_rgb(0,0,0,0.01)] border border-border overflow-hidden">
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-border bg-muted/20 text-muted-foreground font-semibold">
                  <th className="p-3.5">User</th>
                  <th className="p-3.5">Action</th>
                  <th className="p-3.5">Target</th>
                  <th className="p-3.5">Description</th>
                  <th className="p-3.5">Time</th>
                </tr>
              </thead>
              <tbody>
                {filteredLogs.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="p-12 text-center text-muted-foreground">
                      <div className="flex flex-col items-center justify-center gap-2">
                        <AlertCircle className="h-8 w-8 text-amber-500 animate-pulse" />
                        <div>
                          <h4 className="font-bold text-foreground">No Logs Found</h4>
                          <p className="text-[10px] text-muted-foreground mt-0.5">Try clearing search parameters or filters.</p>
                        </div>
                      </div>
                    </td>
                  </tr>
                ) : (
                  filteredLogs.map((log) => (
                    <tr key={log.id} className="border-b border-border/60 hover:bg-muted/10 transition-colors">
                      
                      {/* User Info */}
                      <td className="p-3.5">
                        <div className="flex items-center gap-2">
                          <div className="flex h-7 w-7 items-center justify-center rounded-full bg-muted border border-border">
                            <User className="h-3.5 w-3.5 text-muted-foreground" />
                          </div>
                          <div>
                            <div className="font-bold text-foreground">{log.user?.name || "System"}</div>
                            <div className={`inline-block text-[9px] font-bold px-1.5 py-0.5 rounded-md mt-0.5 uppercase tracking-wider ${getRoleColor(log.user?.role)}`}>
                              {log.user?.role || "SYSTEM"}
                            </div>
                          </div>
                        </div>
                      </td>

                      {/* Action Badge */}
                      <td className="p-3.5">
                        <span className={`inline-block text-[9px] font-bold px-2 py-0.5 rounded-full border uppercase tracking-wider ${getActionColor(log.action)}`}>
                          {log.action}
                        </span>
                      </td>

                      {/* Target Info */}
                      <td className="p-3.5 font-semibold text-foreground">
                        <div className="capitalize">{log.entityType}</div>
                        <div className="text-[9px] text-muted-foreground font-mono mt-0.5">ID: {String(log.entityId)}</div>
                      </td>

                      {/* Details Description */}
                      <td className="p-3.5 text-foreground leading-relaxed">
                        {renderDetails(log)}
                      </td>

                      {/* Timestamp */}
                      <td className="p-3.5 font-mono text-muted-foreground">
                        <div className="flex items-center gap-1.5">
                          <Clock className="h-3.5 w-3.5 text-muted-foreground/60" />
                          <span>{formatTime(log.createdAt)}</span>
                        </div>
                      </td>

                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
      
    </div>
  )
}

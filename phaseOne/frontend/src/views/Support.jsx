import React, { useState } from "react"
import { 
  Wrench, 
  Plus, 
  X, 
  Search, 
  MessageSquare, 
  UserCheck, 
  CheckCircle, 
  AlertCircle, 
  Clock,
  ArrowRight,
  User,
  Activity
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

export default function Support({ db, setDb }) {
  const [selectedTicketId, setSelectedTicketId] = useState(1)
  const [statusFilter, setStatusFilter] = useState("all") // all, open, closed
  const [searchQuery, setSearchQuery] = useState("")
  
  // Local message thread input
  const [messageInput, setMessageInput] = useState("")
  const [comments, setComments] = useState([
    { id: 1, ticketId: 1, author: "Aditi Rao", text: "Checked physical Raspberry Pi connection. Signals fluctuate over local WiFi access point. Proposing routing check.", time: "2026-06-29 10:15 AM" },
    { id: 2, ticketId: 1, author: "Ramesh Kumar", text: "Yes please, the automation schedules fail to sync frequently.", time: "2026-06-29 11:00 AM" }
  ])

  // New ticket modal
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [newTicketForm, setNewTicketForm] = useState({
    farmerId: "1", title: "", description: "", priority: "Medium", category: "Hardware", assignedTechnician: "Aditi Rao"
  })

  const tickets = db?.tickets || []
  const selectedTicket = tickets.find(t => t.id === selectedTicketId)
  const selectedFarmer = db?.farmers?.find(f => f.id === selectedTicket?.farmerId)

  // Filter tickets
  const filteredTickets = tickets.filter(t => {
    const matchesStatus = statusFilter === "all" 
      ? true 
      : statusFilter === "closed" 
      ? t.status === "Closed" 
      : t.status !== "Closed"
    
    const matchesSearch = t.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.category.toLowerCase().includes(searchQuery.toLowerCase())

    return matchesStatus && matchesSearch
  })

  // Assign Technician
  const handleAssignTechnician = (techName) => {
    if (!selectedTicket) return
    const updatedTickets = db.tickets.map(t => t.id === selectedTicketId ? { ...t, assignedTechnician: techName, status: "In Progress" } : t)
    let updatedDb = { ...db, tickets: updatedTickets }
    updatedDb = addLog(updatedDb, "Super Admin", "Technician Assigned", `Assigned support ticket '${selectedTicket.title}' to ${techName}`)
    setDb(updatedDb)
  }

  // Update Ticket Status
  const handleUpdateStatus = (newStatus) => {
    if (!selectedTicket) return
    const updatedTickets = db.tickets.map(t => t.id === selectedTicketId ? { ...t, status: newStatus } : t)
    let updatedDb = { ...db, tickets: updatedTickets }
    updatedDb = addLog(updatedDb, "Super Admin", "Ticket Status Changed", `Set status of ticket '${selectedTicket.title}' to ${newStatus}`)
    setDb(updatedDb)
  }

  // Send message comment
  const handleSendMessage = (e) => {
    e.preventDefault()
    if (!messageInput.trim() || !selectedTicket) return

    const newComment = {
      id: Date.now(),
      ticketId: selectedTicketId,
      author: "Super Admin",
      text: messageInput,
      time: new Date().toISOString().replace('T', ' ').substring(0, 16)
    }

    setComments([...comments, newComment])
    setMessageInput("")
  }

  // Create Support Ticket
  const handleCreateTicket = (e) => {
    e.preventDefault()
    if (!newTicketForm.title.trim()) return

    const newTicket = {
      id: Date.now(),
      farmerId: parseInt(newTicketForm.farmerId),
      title: newTicketForm.title,
      description: newTicketForm.description,
      status: "Open",
      priority: newTicketForm.priority,
      category: newTicketForm.category,
      assignedTechnician: newTicketForm.assignedTechnician,
      createdAt: new Date().toISOString().split("T")[0]
    }

    const updatedTickets = [...db.tickets, newTicket]
    let updatedDb = { ...db, tickets: updatedTickets }
    updatedDb = addLog(updatedDb, "Super Admin", "Support Ticket Logged", `Logged new ticket: '${newTicket.title}'`)
    setDb(updatedDb)
    setIsModalOpen(false)
    setSelectedTicketId(newTicket.id)
  }

  // Technicians list
  const technicians = db?.users?.filter(u => u.role === "Technician" || u.role === "Super Admin") || []

  return (
    <div className="grid gap-6 md:grid-cols-3 font-sans text-xs">
      
      {/* 1. Tickets List Table Panel */}
      <div className="md:col-span-2 flex flex-col gap-4">
        
        {/* Filters Toolbar */}
        <div className="flex flex-col md:flex-row gap-4 items-center justify-between bg-muted/10 p-3 rounded-xl border border-border/40 font-bold">
          
          <div className="flex border border-border bg-background rounded-lg p-0.5 overflow-hidden">
            <button
              onClick={() => setStatusFilter("all")}
              className={`px-3 py-1.5 rounded text-[10px] font-bold uppercase tracking-wider transition-all duration-200 cursor-pointer ${
                statusFilter === "all" ? "bg-emerald-500 text-white shadow-xs" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              All Tickets
            </button>
            <button
              onClick={() => setStatusFilter("open")}
              className={`px-3 py-1.5 rounded text-[10px] font-bold uppercase tracking-wider transition-all duration-200 cursor-pointer ${
                statusFilter === "open" ? "bg-emerald-500 text-white shadow-xs" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              Open
            </button>
            <button
              onClick={() => setStatusFilter("closed")}
              className={`px-3 py-1.5 rounded text-[10px] font-bold uppercase tracking-wider transition-all duration-200 cursor-pointer ${
                statusFilter === "closed" ? "bg-emerald-500 text-white shadow-xs" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              Closed
            </button>
          </div>

          <div className="flex items-center gap-2 w-full md:w-auto">
            <div className="relative flex-1 md:w-64">
              <Search className="absolute left-3 top-2 h-3.5 w-3.5 text-muted-foreground" />
              <input
                type="text"
                placeholder="Search ticket logs..."
                className="pl-9 pr-3 py-1.5 w-full border border-border rounded-lg bg-background text-[11px] focus:outline-none"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <button
              onClick={() => setIsModalOpen(true)}
              className="flex items-center gap-1 bg-emerald-600 hover:bg-emerald-700 text-white font-bold px-3 py-1.5 rounded-lg text-xs cursor-pointer shadow-xs whitespace-nowrap"
            >
              <Plus size={14} />
              <span>Log Ticket</span>
            </button>
          </div>
        </div>

        {/* Tickets list */}
        <div className="bg-card rounded-xl border border-border overflow-hidden shadow-xs">
          <Table>
            <TableHeader className="bg-muted/10 border-b border-border/60">
              <TableRow>
                <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Ticket Title</TableHead>
                <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Category</TableHead>
                <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Priority</TableHead>
                <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Status</TableHead>
                <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider text-right pr-6">Open</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredTickets.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center py-8 text-muted-foreground italic text-xs">
                    No tickets found matching criteria.
                  </TableCell>
                </TableRow>
              ) : (
                filteredTickets.map(t => (
                  <TableRow 
                    key={t.id} 
                    onClick={() => setSelectedTicketId(t.id)}
                    className={`hover:bg-muted/10 font-semibold cursor-pointer ${
                      selectedTicketId === t.id ? "bg-emerald-500/5" : ""
                    }`}
                  >
                    <TableCell className="font-extrabold text-foreground py-3">
                      <div>
                        <div>{t.title}</div>
                        <div className="text-[9px] text-muted-foreground font-semibold mt-0.5">Date: {t.createdAt}</div>
                      </div>
                    </TableCell>
                    <TableCell className="text-muted-foreground">{t.category}</TableCell>
                    <TableCell>
                      <span className={`inline-flex items-center px-1.5 py-0.2 rounded text-[8px] font-bold border ${
                        t.priority === "High" ? "bg-red-500/10 text-red-500 border-red-500/15" : "bg-amber-500/10 text-amber-500 border-amber-500/15"
                      }`}>
                        {t.priority}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-[9px] font-extrabold border ${
                        t.status === "Open" 
                          ? "bg-red-500/10 text-red-500 border-red-500/15 animate-pulse" 
                          : t.status === "In Progress"
                          ? "bg-amber-500/10 text-amber-500 border-amber-500/15"
                          : "bg-green-500/10 text-green-500 border-green-500/15"
                      }`}>
                        {t.status}
                      </span>
                    </TableCell>
                    <TableCell className="text-right pr-6">
                      <ArrowRight size={12} className="inline text-muted-foreground" />
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      </div>

      {/* 2. Selected Ticket Details Card */}
      <div className="flex flex-col gap-6">
        {selectedTicket ? (
          <Card className="shadow-xs border border-border bg-card flex flex-col justify-between h-full">
            <CardHeader className="border-b border-border/40 pb-3">
              <div className="flex items-center justify-between">
                <span className={`text-[8px] font-extrabold px-1.5 py-0.2 rounded border uppercase tracking-wider font-mono ${
                  selectedTicket.status === "Open" ? "bg-red-100 text-red-700 border-red-500/15" : "bg-green-100 text-green-700 border-green-500/15"
                }`}>
                  {selectedTicket.status}
                </span>
                <span className="text-[10px] text-muted-foreground font-semibold">{selectedTicket.createdAt}</span>
              </div>
              <CardTitle className="text-sm font-extrabold text-foreground mt-2">{selectedTicket.title}</CardTitle>
              <CardDescription className="text-[10px] font-bold text-emerald-600">Farmer: {selectedFarmer?.name || "Unassigned"}</CardDescription>
            </CardHeader>

            <CardContent className="flex-1 flex flex-col gap-4 py-4 text-xs">
              
              {/* Description */}
              <div className="bg-muted/15 border border-border p-3 rounded-xl font-medium text-muted-foreground">
                {selectedTicket.description}
              </div>

              {/* Assignments dropdowns */}
              <div className="grid grid-cols-2 gap-3 border-b border-border/40 pb-3 font-bold text-[10px]">
                <div className="flex flex-col gap-1">
                  <span className="text-muted-foreground">Assigned Technician</span>
                  <select
                    value={selectedTicket.assignedTechnician}
                    onChange={(e) => handleAssignTechnician(e.target.value)}
                    className="p-1 border border-border bg-background rounded text-foreground outline-hidden font-bold cursor-pointer"
                  >
                    <option value="">Unassigned</option>
                    {technicians.map(t => (
                      <option key={t.id} value={t.name}>{t.name}</option>
                    ))}
                  </select>
                </div>
                
                <div className="flex flex-col gap-1">
                  <span className="text-muted-foreground">Change Status</span>
                  <select
                    value={selectedTicket.status}
                    onChange={(e) => handleUpdateStatus(e.target.value)}
                    className="p-1 border border-border bg-background rounded text-foreground outline-hidden font-bold cursor-pointer"
                  >
                    <option value="Open">Open</option>
                    <option value="In Progress">In Progress</option>
                    <option value="Closed">Closed</option>
                  </select>
                </div>
              </div>

              {/* Message loop timeline thread */}
              <div className="flex flex-col gap-2 flex-1">
                <span className="font-extrabold text-muted-foreground text-[10px] uppercase tracking-wider block">Communication Log Thread</span>
                
                <div className="h-44 overflow-y-auto border border-border/60 rounded-xl p-2.5 bg-muted/5 flex flex-col gap-3 max-h-48 leading-relaxed font-semibold">
                  {comments.filter(c => c.ticketId === selectedTicketId).map(comment => (
                    <div key={comment.id} className="text-[10px] bg-background border border-border/55 p-2 rounded-lg">
                      <div className="flex justify-between items-center text-[8.5px] text-muted-foreground mb-0.5 font-bold">
                        <span>{comment.author}</span>
                        <span>{comment.time.split(" ")[1]} {comment.time.split(" ")[2]}</span>
                      </div>
                      <div className="text-foreground font-medium">{comment.text}</div>
                    </div>
                  ))}
                </div>

                <form onSubmit={handleSendMessage} className="flex gap-1.5 mt-auto">
                  <input
                    type="text"
                    required
                    value={messageInput}
                    onChange={(e) => setMessageInput(e.target.value)}
                    className="flex-1 p-1.5 bg-background border border-border rounded-lg text-foreground text-[10px]"
                    placeholder="Write a message..."
                  />
                  <button type="submit" className="px-3 bg-emerald-600 text-white rounded-lg font-bold hover:bg-emerald-700 cursor-pointer">
                    Reply
                  </button>
                </form>
              </div>

            </CardContent>
          </Card>
        ) : (
          <div className="text-center py-12 border border-dashed border-border rounded-2xl bg-card">
            No ticket selected.
          </div>
        )}
      </div>

      {/* Log Ticket Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-card text-card-foreground w-full max-w-md rounded-xl shadow-lg border border-border flex flex-col animate-in zoom-in-95 duration-200 font-bold">
            <div className="flex items-center justify-between p-6 border-b border-border">
              <h3 className="text-lg font-bold text-foreground">Log Support Request</h3>
              <button onClick={() => setIsModalOpen(false)} className="text-muted-foreground hover:text-foreground p-1 rounded-md hover:bg-muted">
                <X className="h-5 w-5" />
              </button>
            </div>
            
            <form onSubmit={handleCreateTicket} className="p-6 flex flex-col gap-4 text-xs font-semibold">
              <div className="flex flex-col gap-1.5">
                <label className="text-muted-foreground">Associated Farmer</label>
                <select
                  value={newTicketForm.farmerId}
                  onChange={(e) => setNewTicketForm({ ...newTicketForm, farmerId: e.target.value })}
                  className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold cursor-pointer"
                >
                  {db?.farmers?.map(f => (
                    <option key={f.id} value={f.id}>{f.name}</option>
                  ))}
                </select>
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-muted-foreground">Ticket Title Summary</label>
                <input
                  type="text"
                  required
                  value={newTicketForm.title}
                  onChange={(e) => setNewTicketForm({ ...newTicketForm, title: e.target.value })}
                  className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold"
                  placeholder="E.g. Flow rate registry values erratic"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-muted-foreground">Description Details</label>
                <textarea
                  required
                  value={newTicketForm.description}
                  onChange={(e) => setNewTicketForm({ ...newTicketForm, description: e.target.value })}
                  className="flex h-20 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold resize-none"
                  placeholder="Describe the physical failure state in detail..."
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Category</label>
                  <select
                    value={newTicketForm.category}
                    onChange={(e) => setNewTicketForm({ ...newTicketForm, category: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold cursor-pointer"
                  >
                    <option value="Hardware">Hardware Failure</option>
                    <option value="Modbus">Modbus Serial Loop</option>
                    <option value="Sensor Calibration">Sensor Calibration</option>
                    <option value="Software Portal">Software Portal Bug</option>
                  </select>
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-muted-foreground">Priority</label>
                  <select
                    value={newTicketForm.priority}
                    onChange={(e) => setNewTicketForm({ ...newTicketForm, priority: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 font-bold cursor-pointer"
                  >
                    <option value="Low">Low</option>
                    <option value="Medium">Medium</option>
                    <option value="High">High (Immediate Action)</option>
                  </select>
                </div>
              </div>

              <div className="flex justify-end gap-3 mt-4">
                <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 rounded-lg border border-border bg-background hover:bg-accent text-foreground font-bold transition-all cursor-pointer">
                  Cancel
                </button>
                <button type="submit" className="px-4 py-2 rounded-lg bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white font-bold transition-all cursor-pointer shadow-md shadow-emerald-500/10">
                  Log Ticket
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  )
}

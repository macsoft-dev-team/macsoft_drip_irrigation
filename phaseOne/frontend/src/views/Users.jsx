import React, { useState } from "react"
import { Users as UsersIcon, Plus, Pencil, Trash2, X, AlertTriangle, ShieldCheck, Key } from "lucide-react"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import {
  Pagination,
  PaginationContent,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from "@/components/ui/pagination"

export default function Users({ db, setDb }) {
  const [activeTab, setActiveTab] = useState("users") // users, roles
  const users = db?.users || []

  // Pagination state
  const [currentPage, setCurrentPage] = useState(1)
  const ITEMS_PER_PAGE = 8
  
  const totalPages = Math.ceil(users.length / ITEMS_PER_PAGE)
  const startIndex = (currentPage - 1) * ITEMS_PER_PAGE
  const paginatedUsers = users.slice(startIndex, startIndex + ITEMS_PER_PAGE)
  
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [modalMode, setModalMode] = useState("create") // create, update, delete
  const [currentUser, setCurrentUser] = useState(null)

  // Form state
  const [formData, setFormData] = useState({ name: "", email: "", role: "Technician", status: "Active", mobile: "" })

  const openModal = (mode, user = null) => {
    setModalMode(mode)
    setCurrentUser(user)
    if (user && mode !== "delete") {
      setFormData({ name: user.name, email: user.email, role: user.role, status: user.status, mobile: user.mobile || "" })
    } else {
      setFormData({ name: "", email: "", role: "Technician", status: "Active", mobile: "" })
    }
    setIsModalOpen(true)
  }

  const closeModal = () => {
    setIsModalOpen(false)
    setCurrentUser(null)
  }

  const handleSubmit = (e) => {
    e.preventDefault()

    if (modalMode === "create") {
      const newUser = {
        id: Date.now(),
        ...formData,
        joinedAt: new Date().toISOString().split("T")[0]
      }
      const updatedUsers = [...users, newUser]
      setDb({ ...db, users: updatedUsers })
    } else if (modalMode === "update") {
      const updatedUsers = users.map(u => u.id === currentUser.id ? { ...u, ...formData } : u)
      setDb({ ...db, users: updatedUsers })
    }

    closeModal()
  }

  const handleDelete = () => {
    const updatedUsers = users.filter(u => u.id !== currentUser.id)
    setDb({ ...db, users: updatedUsers })
    closeModal()
  }

  // Roles permissions matrix mock
  const [permissions, setPermissions] = useState([
    { module: "Farmer Onboarding", superAdmin: true, support: true, technician: false },
    { module: "Hardware Registration", superAdmin: true, support: false, technician: true },
    { module: "Modbus Address Config", superAdmin: true, support: false, technician: true },
    { module: "Manual Irrigation Toggles", superAdmin: true, support: true, technician: true },
    { module: "Schedules Configuration", superAdmin: true, support: true, technician: true },
    { module: "Global MQTT Config", superAdmin: true, support: false, technician: false }
  ])

  const togglePermission = (idx, role) => {
    const updated = [...permissions]
    updated[idx][role] = !updated[idx][role]
    setPermissions(updated)
  }

  return (
    <div className="flex flex-col gap-6 font-sans">
      
      {/* Navigation tabs */}
      <div className="flex items-center justify-between border-b border-border/60 pb-3">
        <div className="flex border border-border bg-background rounded-lg p-0.5 overflow-hidden">
          <button
            onClick={() => setActiveTab("users")}
            className={`px-3 py-1 rounded text-xs font-bold uppercase tracking-wider transition-all duration-200 cursor-pointer ${
              activeTab === "users"
                ? "bg-emerald-500 text-white shadow-xs"
                : "text-muted-foreground hover:text-foreground"
            }`}
          >
            User Accounts
          </button>
          <button
            onClick={() => setActiveTab("roles")}
            className={`px-3 py-1 rounded text-xs font-bold uppercase tracking-wider transition-all duration-200 cursor-pointer ${
              activeTab === "roles"
                ? "bg-emerald-500 text-white shadow-xs"
                : "text-muted-foreground hover:text-foreground"
            }`}
          >
            Roles & Permissions
          </button>
        </div>

        {activeTab === "users" && (
          <button
            onClick={() => openModal("create")}
            className="inline-flex items-center justify-center rounded-lg text-xs font-bold transition-all bg-gradient-to-r from-emerald-600 to-teal-500 text-white hover:from-emerald-700 hover:to-teal-600 hover:-translate-y-0.5 active:translate-y-0 h-9 py-2 px-4 shadow-md shadow-emerald-500/10 cursor-pointer"
          >
            <Plus className="h-4 w-4 mr-1.5" />
            <span>Add User</span>
          </button>
        )}
      </div>

      {activeTab === "users" ? (
        // User Accounts List Table
        <div className="flex flex-col gap-4">
          <div className="rounded-xl border border-border bg-card text-card-foreground shadow-[0_8px_30px_rgb(0,0,0,0.02)] overflow-hidden">
            <Table>
              <TableHeader className="bg-muted/10 border-b border-border/60">
                <TableRow>
                  <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Name</TableHead>
                  <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Email Address</TableHead>
                  <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">System Role</TableHead>
                  <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Access Status</TableHead>
                  <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Mobile Number</TableHead>
                  <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider text-right pr-6">Manage</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan="6" className="h-24 text-center text-muted-foreground text-xs italic">
                      No system users configured.
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedUsers.map((user) => (
                    <TableRow key={user.id} className="hover:bg-emerald-500/5 dark:hover:bg-emerald-500/2 transition-colors font-medium text-xs">
                      <TableCell className="font-extrabold text-foreground py-3">{user.name}</TableCell>
                      <TableCell className="text-muted-foreground font-mono">{user.email}</TableCell>
                      <TableCell>
                        <span className={`inline-flex items-center rounded-md px-2 py-0.5 text-[9px] font-extrabold border ${
                          user.role === 'Super Admin' || user.role === 'Admin'
                            ? 'bg-purple-500/10 text-purple-600 dark:text-purple-400 border-purple-500/15' :
                          user.role === 'Technician' || user.role === 'Field Engineer'
                            ? 'bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/15' :
                            'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/15'
                        }`}>
                          {user.role}
                        </span>
                      </TableCell>
                      <TableCell>
                        <span className={`inline-flex items-center gap-1.5 font-bold ${user.status === 'Active' ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-500'}`}>
                          <span className={`h-1.5 w-1.5 rounded-full ${user.status === 'Active' ? 'bg-emerald-500 animate-pulse' : 'bg-slate-500'}`}></span>
                          {user.status}
                        </span>
                      </TableCell>
                      <TableCell className="text-muted-foreground font-mono">{user.mobile || "-"}</TableCell>
                      <TableCell className="text-right pr-6">
                        <div className="flex items-center justify-end gap-1.5">
                          <button
                            onClick={() => openModal("update", user)}
                            className="p-1 rounded-md border border-border hover:bg-emerald-500 hover:text-white text-emerald-600 transition-colors cursor-pointer"
                            title="Edit User"
                          >
                            <Pencil className="h-3.5 w-3.5" />
                          </button>
                          <button
                            onClick={() => openModal("delete", user)}
                            className="p-1 rounded-md border border-border hover:bg-red-500 hover:text-white text-red-500 transition-colors cursor-pointer"
                            title="Delete User"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>

          {/* Pagination Controls */}
          {totalPages > 1 && (
            <Pagination>
              <PaginationContent>
                <PaginationItem>
                  <PaginationPrevious 
                    href="#" 
                    onClick={(e) => {
                      e.preventDefault()
                      if (currentPage > 1) setCurrentPage(currentPage - 1)
                    }} 
                    className={currentPage === 1 ? "pointer-events-none opacity-50" : ""}
                  />
                </PaginationItem>
                {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
                  <PaginationItem key={page}>
                    <PaginationLink 
                      href="#" 
                      onClick={(e) => {
                        e.preventDefault()
                        setCurrentPage(page)
                      }}
                      isActive={currentPage === page}
                    >
                      {page}
                    </PaginationLink>
                  </PaginationItem>
                ))}
                <PaginationItem>
                  <PaginationNext 
                    href="#" 
                    onClick={(e) => {
                      e.preventDefault()
                      if (currentPage < totalPages) setCurrentPage(currentPage + 1)
                    }}
                    className={currentPage === totalPages ? "pointer-events-none opacity-50" : ""}
                  />
                </PaginationItem>
              </PaginationContent>
            </Pagination>
          )}
        </div>
      ) : (
        // Roles & Permissions Panel
        <Card className="shadow-[0_8px_30px_rgb(0,0,0,0.02)] border border-border bg-card">
          <CardHeader>
            <CardTitle className="text-sm font-extrabold uppercase tracking-wider text-foreground flex items-center gap-1.5">
              <ShieldCheck className="h-4.5 w-4.5 text-emerald-500" />
              <span>Permission Settings Matrix</span>
            </CardTitle>
            <CardDescription className="text-[10px] text-muted-foreground">Configure access settings for distinct SaaS operator levels</CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader className="bg-muted/10 border-b border-border/60">
                <TableRow>
                  <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Module Module / Capability</TableHead>
                  <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider text-center">Super Admin</TableHead>
                  <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider text-center">Support Staff</TableHead>
                  <TableHead className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider text-center">Field Technician</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {permissions.map((p, idx) => (
                  <TableRow key={idx} className="hover:bg-muted/5 font-medium text-xs">
                    <TableCell className="font-extrabold text-foreground py-3.5 flex items-center gap-2">
                      <Key className="h-3.5 w-3.5 text-emerald-500/60" />
                      <span>{p.module}</span>
                    </TableCell>
                    <TableCell className="text-center">
                      <input 
                        type="checkbox" 
                        checked={p.superAdmin} 
                        onChange={() => togglePermission(idx, "superAdmin")}
                        className="accent-emerald-600 rounded cursor-pointer"
                      />
                    </TableCell>
                    <TableCell className="text-center">
                      <input 
                        type="checkbox" 
                        checked={p.support} 
                        onChange={() => togglePermission(idx, "support")}
                        className="accent-emerald-600 rounded cursor-pointer"
                      />
                    </TableCell>
                    <TableCell className="text-center">
                      <input 
                        type="checkbox" 
                        checked={p.technician} 
                        onChange={() => togglePermission(idx, "technician")}
                        className="accent-emerald-600 rounded cursor-pointer"
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}

      {/* User Modals */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-card text-card-foreground w-full max-w-md rounded-xl shadow-lg border border-border flex flex-col animate-in zoom-in-95 duration-200">

            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-border">
              <h3 className="text-lg font-bold text-foreground flex items-center gap-2">
                {modalMode === "create" && "Create New User"}
                {modalMode === "update" && "Update User Profile"}
                {modalMode === "delete" && (
                  <>
                    <AlertTriangle className="h-5 w-5 text-red-500" />
                    <span>Confirm Revocation</span>
                  </>
                )}
              </h3>
              <button onClick={closeModal} className="text-muted-foreground hover:text-foreground transition-colors p-1 rounded-md hover:bg-muted">
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Body */}
            {modalMode === "delete" ? (
              <div className="p-6 text-xs">
                <p className="text-muted-foreground mb-6 font-semibold">
                  Are you sure you want to delete <strong className="text-foreground">{currentUser?.name}</strong>? This will revoke their platform credentials immediately.
                </p>
                <div className="flex justify-end gap-3">
                  <button onClick={closeModal} className="px-4 py-2 rounded-lg border border-border bg-background hover:bg-accent text-foreground font-bold transition-all cursor-pointer">
                    Cancel
                  </button>
                  <button onClick={handleDelete} className="px-4 py-2 rounded-lg bg-gradient-to-r from-red-600 to-rose-500 hover:from-red-700 hover:to-rose-600 text-white font-bold transition-all cursor-pointer shadow-md shadow-red-500/10">
                    Revoke User
                  </button>
                </div>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="p-6 flex flex-col gap-4 text-xs font-semibold">
                <div className="flex flex-col gap-1.5">
                  <label htmlFor="name" className="text-muted-foreground">Full Name</label>
                  <input
                    id="name"
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-muted-foreground/60 font-bold"
                    placeholder="E.g. Ramesh Patil"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label htmlFor="email" className="text-muted-foreground">Email Address</label>
                  <input
                    id="email"
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-muted-foreground/60 font-mono font-bold"
                    placeholder="E.g. technician@dripcontrol.com"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label htmlFor="mobile" className="text-muted-foreground">Mobile Contact</label>
                  <input
                    id="mobile"
                    type="tel"
                    value={formData.mobile}
                    onChange={(e) => setFormData({ ...formData, mobile: e.target.value })}
                    className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-muted-foreground/60 font-mono font-bold"
                    placeholder="E.g. +91 9876543210"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label htmlFor="role" className="text-muted-foreground">Role</label>
                    <select
                      id="role"
                      value={formData.role}
                      onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 transition-all font-bold cursor-pointer"
                    >
                      <option value="Super Admin">Super Admin</option>
                      <option value="Technician">Technician</option>
                      <option value="Support Staff">Support Staff</option>
                    </select>
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <label htmlFor="status" className="text-muted-foreground">Status</label>
                    <select
                      id="status"
                      value={formData.status}
                      onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                      className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 outline-hidden focus:border-emerald-500 transition-all font-bold cursor-pointer"
                    >
                      <option value="Active">Active</option>
                      <option value="Suspended">Suspended</option>
                    </select>
                  </div>
                </div>

                <div className="flex justify-end gap-3 mt-4">
                  <button type="button" onClick={closeModal} className="px-4 py-2 rounded-lg border border-border bg-background hover:bg-accent text-foreground font-bold transition-all cursor-pointer">
                    Cancel
                  </button>
                  <button type="submit" className="px-4 py-2 rounded-lg bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white font-bold transition-all cursor-pointer shadow-md shadow-emerald-500/10">
                    {modalMode === "create" ? "Add Operator" : "Save Changes"}
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

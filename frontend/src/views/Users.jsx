import React, { useState } from "react"
import { Users as UsersIcon, Plus, Pencil, Trash2, X, AlertTriangle } from "lucide-react"
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
  PaginationEllipsis,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from "@/components/ui/pagination"

// Initial mock users list
const initialUsers = [
    {
        id: 1,
        name: "Admin User",
        email: "admin@macsoft.com",
        role: "admin",
        status: "Active",
        mobile: "+1 555-0101",
    },
    {
        id: 2,
        name: "Field Engineer",
        email: "engineer@macsoft.com",
        role: "field_engineer",
        status: "Active",
        mobile: "+1 555-0102",
    },
    {
        id: 3,
        name: "Farmer John",
        email: "john@macsoft.com",
        role: "farmer",
        status: "Active",
        mobile: "+1 555-0103",
    },
    {
        id: 4,
        name: "Inactive User",
        email: "inactive@macsoft.com",
        role: "farmer",
        status: "Inactive",
        mobile: "+1 555-0104",
    }
]


export default function Users() {
    const [users, setUsers] = useState(initialUsers)

    // Pagination state
    const [currentPage, setCurrentPage] = useState(1)
    const ITEMS_PER_PAGE = 10
    
    const totalPages = Math.ceil(users.length / ITEMS_PER_PAGE)
    const startIndex = (currentPage - 1) * ITEMS_PER_PAGE
    const paginatedUsers = users.slice(startIndex, startIndex + ITEMS_PER_PAGE)
    const [isModalOpen, setIsModalOpen] = useState(false)
    const [modalMode, setModalMode] = useState("create")
    const [currentUser, setCurrentUser] = useState(null)

    // Form state
    const [formData, setFormData] = useState({ name: "", email: "", role: "Viewer", status: "Active", mobile: "" })

    const openModal = (mode, user = null) => {
        setModalMode(mode)
        setCurrentUser(user)
        if (user && mode !== "delete") {
            setFormData({ name: user.name, email: user.email, role: user.role, status: user.status, mobile: user.mobile || "" })
        } else {
            setFormData({ name: "", email: "", role: "Viewer", status: "Active", mobile: "" })
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
                id: Math.max(...users.map(u => u.id), 0) + 1,
                ...formData
            }
            setUsers([...users, newUser])
        } else if (modalMode === "update") {
            setUsers(users.map(u => u.id === currentUser.id ? { ...u, ...formData } : u))
        }

        closeModal()
    }

    const handleDelete = () => {
        setUsers(users.filter(u => u.id !== currentUser.id))
        closeModal()
    }

    return (
        <div className="flex flex-col gap-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-border/60">
                <div className="flex items-center gap-3">
                    <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 shadow-xs">
                        <UsersIcon className="h-6 w-6" />
                    </div>
                    <div>
                        <h2 className="text-xl font-bold tracking-tight text-foreground">
                            User Management
                        </h2>
                        <p className="text-xs text-muted-foreground mt-0.5">Manage system access, operator roles, and farmer accounts.</p>
                    </div>
                </div>
                <button
                    onClick={() => openModal("create")}
                    className="inline-flex items-center justify-center rounded-lg text-sm font-bold transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30 disabled:opacity-50 disabled:pointer-events-none bg-gradient-to-r from-emerald-600 to-teal-500 text-white hover:from-emerald-700 hover:to-teal-600 hover:-translate-y-0.5 active:translate-y-0 h-10 py-2 px-4 shadow-md shadow-emerald-500/10"
                >
                    <Plus className="h-4 w-4 mr-2" />
                    Add User
                </button>
            </div>

            {/* Users Table */}
            <div className="rounded-xl border border-border bg-card text-card-foreground shadow-sm">
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead>Name</TableHead>
                            <TableHead>Email</TableHead>
                            <TableHead>Role</TableHead>
                            <TableHead>Status</TableHead>
                            <TableHead>Mobile No</TableHead>
                            <TableHead className="text-right">Actions</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {users.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan="6" className="h-24 text-center text-muted-foreground">
                                    No users found.
                                </TableCell>
                            </TableRow>
                        ) : (
                            paginatedUsers.map((user) => (
                                <TableRow key={user.id} className="hover:bg-emerald-500/5 dark:hover:bg-emerald-500/2 transition-colors">
                                    <TableCell className="font-bold text-foreground">{user.name}</TableCell>
                                    <TableCell className="text-muted-foreground font-mono">{user.email}</TableCell>
                                    <TableCell>
                                        <span className={`inline-flex items-center rounded-md px-2 py-0.5 text-[10px] font-bold border ${
                                            user.role === 'Administrator' || user.role === 'admin' || user.role === 'Admin'
                                                ? 'bg-purple-500/10 text-purple-600 dark:text-purple-400 border-purple-500/15' :
                                            user.role === 'Operator' || user.role === 'field_engineer' || user.role === 'Field_Engineer' || user.role === 'Technician'
                                                ? 'bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/15' :
                                                'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/15'
                                            }`}>
                                            {user.role}
                                        </span>
                                    </TableCell>
                                    <TableCell>
                                        <span className={`inline-flex items-center gap-1.5 font-bold ${user.status === 'Active' ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-500'
                                            }`}>
                                            <span className={`h-1.5 w-1.5 rounded-full ${user.status === 'Active' ? 'bg-emerald-500' : 'bg-slate-500'}`}></span>
                                            {user.status}
                                        </span>
                                    </TableCell>
                                    <TableCell className="text-muted-foreground font-mono">{user.mobile || "-"}</TableCell>
                                    <TableCell className="text-right">
                                        <div className="flex items-center justify-end gap-1">
                                            <button
                                                onClick={() => openModal("update", user)}
                                                className="p-2 text-slate-500 hover:text-emerald-600 hover:bg-emerald-500/10 dark:hover:bg-emerald-500/20 rounded-lg transition-all"
                                                title="Edit User"
                                            >
                                                <Pencil className="h-4 w-4" />
                                            </button>
                                            <button
                                                onClick={() => openModal("delete", user)}
                                                className="p-2 text-slate-500 hover:text-red-600 hover:bg-red-500/10 dark:hover:bg-red-500/20 rounded-lg transition-all"
                                                title="Delete User"
                                            >
                                                <Trash2 className="h-4 w-4" />
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

            {/* Modal Backdrop & Content */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
                    <div className="bg-card text-card-foreground w-full max-w-md rounded-xl shadow-lg border border-border flex flex-col animate-in zoom-in-95 duration-200">

                        {/* Modal Header */}
                        <div className="flex items-center justify-between p-6 border-b border-border">
                            <h3 className="text-lg font-semibold flex items-center gap-2">
                                {modalMode === "create" && "Create New User"}
                                {modalMode === "update" && "Update User"}
                                {modalMode === "delete" && (
                                    <>
                                        <AlertTriangle className="h-5 w-5 text-red-500" />
                                        Delete User
                                    </>
                                )}
                            </h3>
                            <button
                                onClick={closeModal}
                                className="text-muted-foreground hover:text-foreground transition-colors p-1 rounded-md hover:bg-muted"
                            >
                                <X className="h-5 w-5" />
                            </button>
                        </div>

                        {/* Modal Body - Delete Confirmation */}
                        {modalMode === "delete" ? (
                            <div className="p-6">
                                <p className="text-muted-foreground mb-6">
                                    Are you sure you want to delete <strong className="text-foreground">{currentUser?.name}</strong>? This action cannot be undone and will immediately revoke their access to the system.
                                </p>
                                <div className="flex justify-end gap-3">
                                    <button
                                        onClick={closeModal}
                                        className="px-4 py-2 rounded-lg border border-border bg-background hover:bg-accent hover:text-accent-foreground text-sm font-semibold transition-all hover:-translate-y-0.5 active:translate-y-0"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        onClick={handleDelete}
                                        className="px-4 py-2 rounded-lg bg-gradient-to-r from-red-600 to-rose-500 hover:from-red-700 hover:to-rose-600 text-white text-sm font-bold transition-all shadow-md shadow-red-500/10 hover:-translate-y-0.5 active:translate-y-0"
                                    >
                                        Delete User
                                    </button>
                                </div>
                            </div>
                        ) : (
                            /* Modal Body - Create/Update Form */
                            <form onSubmit={handleSubmit} className="p-6 flex flex-col gap-4">
                                <div className="flex flex-col gap-2">
                                    <label htmlFor="name" className="text-sm font-semibold text-muted-foreground">Full Name</label>
                                    <input
                                        id="name"
                                        type="text"
                                        required
                                        value={formData.name}
                                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                        className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm outline-hidden focus-visible:ring-2 focus-visible:ring-emerald-500/20 focus-visible:border-emerald-500 transition-all placeholder:text-muted-foreground/60"
                                        placeholder="John Doe"
                                    />
                                </div>

                                <div className="flex flex-col gap-2">
                                    <label htmlFor="email" className="text-sm font-semibold text-muted-foreground">Email Address</label>
                                    <input
                                        id="email"
                                        type="email"
                                        required
                                        value={formData.email}
                                        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                        className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm outline-hidden focus-visible:ring-2 focus-visible:ring-emerald-500/20 focus-visible:border-emerald-500 transition-all placeholder:text-muted-foreground/60"
                                        placeholder="john@example.com"
                                    />
                                </div>

                                <div className="flex flex-col gap-2">
                                    <label htmlFor="mobile" className="text-sm font-semibold text-muted-foreground">Mobile Number</label>
                                    <input
                                        id="mobile"
                                        type="tel"
                                        value={formData.mobile}
                                        onChange={(e) => setFormData({ ...formData, mobile: e.target.value })}
                                        className="flex h-10 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm outline-hidden focus-visible:ring-2 focus-visible:ring-emerald-500/20 focus-visible:border-emerald-500 transition-all placeholder:text-muted-foreground/60"
                                        placeholder="+1 (555) 000-0000"
                                    />
                                </div>

                                <div className="flex flex-col sm:flex-row gap-4">
                                    <div className="flex flex-col gap-2 flex-1">
                                        <label htmlFor="role" className="text-sm font-semibold text-muted-foreground">Role</label>
                                        <select
                                            id="role"
                                            value={formData.role}
                                            onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                                            className="flex h-10 w-full items-center justify-between rounded-lg border border-border bg-background px-3 py-2 text-sm outline-hidden focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                                        >
                                            <option value="Admin">Admin</option>
                                            <option value="Technician">Technician</option>
                                            <option value="Customer_Service">Customer Service</option>
                                            <option value="Field_Engineer">Field Engineer</option>
                                            <option value="Distributor">Distributor</option>
                                            <option value="Farmer">Farmer</option>
                                        </select>
                                    </div>

                                    <div className="flex flex-col gap-2 flex-1">
                                        <label htmlFor="status" className="text-sm font-semibold text-muted-foreground">Status</label>
                                        <select
                                            id="status"
                                            value={formData.status}
                                            onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                                            className="flex h-10 w-full items-center justify-between rounded-lg border border-border bg-background px-3 py-2 text-sm outline-hidden focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                                        >
                                            <option value="Active">Active</option>
                                            <option value="Inactive">Inactive</option>
                                        </select>
                                    </div>
                                </div>

                                <div className="flex justify-end gap-3 mt-4">
                                    <button
                                        type="button"
                                        onClick={closeModal}
                                        className="px-4 py-2 rounded-lg border border-border bg-background hover:bg-accent hover:text-accent-foreground text-sm font-semibold transition-all hover:-translate-y-0.5 active:translate-y-0"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        type="submit"
                                        className="px-4 py-2 rounded-lg bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-700 hover:to-teal-600 text-white text-sm font-bold transition-all shadow-md shadow-emerald-500/10 hover:-translate-y-0.5 active:translate-y-0"
                                    >
                                        {modalMode === "create" ? "Create User" : "Save Changes"}
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

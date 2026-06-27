import React, { useState } from "react"
import { Users as UsersIcon, Plus, Pencil, Search, Ban, CheckCircle2, ShieldCheck, MapPin, Eye, X, Phone, Mail } from "lucide-react"
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

// Initial mock customers/farmers list
const initialCustomers = [
  {
    id: 1,
    name: "Ramesh Kumar",
    phone: "9876543210",
    email: "ramesh.kumar@gmail.com",
    state: "Maharashtra",
    district: "Pune",
    village: "Manchar",
    pincode: "410503",
    distributor: "Macro Drip Distributors",
    status: "Active",
    registeredAt: "2026-01-15",
    fieldsCount: 3,
    valvesCount: 12,
    servicePlan: "Premium Pro",
  },
  {
    id: 2,
    name: "Suresh Patil",
    phone: "8765432109",
    email: "suresh.patil@yahoo.com",
    state: "Karnataka",
    district: "Belagavi",
    village: "Nippani",
    pincode: "591237",
    distributor: "Agri Drip Retailers",
    status: "Active",
    registeredAt: "2026-02-10",
    fieldsCount: 2,
    valvesCount: 8,
    servicePlan: "Standard Growth",
  },
  {
    id: 3,
    name: "Anil Deshmukh",
    phone: "7654321098",
    email: "anil.deshmukh@rediffmail.com",
    state: "Maharashtra",
    district: "Nashik",
    village: "Pimpalgaon",
    pincode: "422209",
    distributor: "Macro Drip Distributors",
    status: "Suspended",
    registeredAt: "2025-11-20",
    fieldsCount: 4,
    valvesCount: 16,
    servicePlan: "None (Expired)",
  },
  {
    id: 4,
    name: "Vijay Singh",
    phone: "9988776655",
    email: "vijay.singh@outlook.com",
    state: "Rajasthan",
    district: "Jaipur",
    village: "Bagru",
    pincode: "303007",
    distributor: "Agri Drip Retailers",
    status: "Active",
    registeredAt: "2026-03-05",
    fieldsCount: 1,
    valvesCount: 4,
    servicePlan: "Starter",
  }
]

export default function Customers() {
  const [customers, setCustomers] = useState(initialCustomers)
  const [searchQuery, setSearchQuery] = useState("")
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [modalMode, setModalMode] = useState("create") // create, edit, view
  const [currentCustomer, setCurrentCustomer] = useState(null)

  // Form states
  const [formData, setFormData] = useState({
    name: "",
    phone: "",
    email: "",
    state: "",
    district: "",
    village: "",
    pincode: "",
    distributor: "Macro Drip Distributors",
    status: "Active",
    servicePlan: "Starter",
  })

  // Pagination states
  const [currentPage, setCurrentPage] = useState(1)
  const ITEMS_PER_PAGE = 8

  // Filter based on search query
  const filteredCustomers = customers.filter(c =>
    c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.phone.includes(searchQuery) ||
    c.district.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.state.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const totalPages = Math.ceil(filteredCustomers.length / ITEMS_PER_PAGE)
  const startIndex = (currentPage - 1) * ITEMS_PER_PAGE
  const paginatedCustomers = filteredCustomers.slice(startIndex, startIndex + ITEMS_PER_PAGE)

  const handleOpenModal = (mode, customer = null) => {
    setModalMode(mode)
    setCurrentCustomer(customer)
    if (customer) {
      setFormData({
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        state: customer.state,
        district: customer.district,
        village: customer.village || "",
        pincode: customer.pincode || "",
        distributor: customer.distributor,
        status: customer.status,
        servicePlan: customer.servicePlan,
      })
    } else {
      setFormData({
        name: "",
        phone: "",
        email: "",
        state: "Maharashtra",
        district: "",
        village: "",
        pincode: "",
        distributor: "Macro Drip Distributors",
        status: "Active",
        servicePlan: "Starter",
      })
    }
    setIsModalOpen(true)
  }

  const handleCloseModal = () => {
    setIsModalOpen(false)
    setCurrentCustomer(null)
  }

  const handleSave = (e) => {
    e.preventDefault()
    if (modalMode === "create") {
      const newCustomer = {
        id: Math.max(...customers.map(c => c.id), 0) + 1,
        ...formData,
        registeredAt: new Date().toISOString().split("T")[0],
        fieldsCount: 0,
        valvesCount: 0,
      }
      setCustomers([newCustomer, ...customers])
    } else if (modalMode === "edit") {
      setCustomers(customers.map(c => c.id === currentCustomer.id ? { ...c, ...formData } : c))
    }
    handleCloseModal()
  }

  const handleToggleStatus = (id) => {
    setCustomers(customers.map(c => {
      if (c.id === id) {
        return {
          ...c,
          status: c.status === "Active" ? "Suspended" : "Active"
        }
      }
      return c
    }))
  }

  return (
    <div className="p-6 space-y-6">
      {/* Upper Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm flex items-center space-x-4">
          <div className="p-3 bg-green-50 rounded-lg text-green-600">
            <UsersIcon size={24} />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500">Total Registered Farmers</p>
            <h3 className="text-2xl font-bold text-gray-900">{customers.length}</h3>
          </div>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm flex items-center space-x-4">
          <div className="p-3 bg-blue-50 rounded-lg text-blue-600">
            <ShieldCheck size={24} />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500">Active Service Subscriptions</p>
            <h3 className="text-2xl font-bold text-gray-900">
              {customers.filter(c => c.status === "Active" && c.servicePlan !== "None (Expired)").length}
            </h3>
          </div>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm flex items-center space-x-4">
          <div className="p-3 bg-red-50 rounded-lg text-red-600">
            <Ban size={24} />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500">Suspended / Inactive Accounts</p>
            <h3 className="text-2xl font-bold text-gray-900">
              {customers.filter(c => c.status === "Suspended").length}
            </h3>
          </div>
        </div>
      </div>

      {/* Main List Section */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        {/* Search and Action Bar */}
        <div className="p-4 border-b border-gray-200 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-2.5 h-4 width-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search by name, phone, district, state..."
              className="pl-10 pr-4 py-2 w-full border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent text-sm"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <button
            onClick={() => handleOpenModal("create")}
            className="flex items-center space-x-2 bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors"
          >
            <Plus size={16} />
            <span>Register Farmer</span>
          </button>
        </div>

        {/* Farmers Table */}
        <div className="overflow-x-auto">
          <Table>
            <TableHeader className="bg-gray-50">
              <TableRow>
                <TableHead className="font-semibold text-gray-700">Farmer Details</TableHead>
                <TableHead className="font-semibold text-gray-700">Contact</TableHead>
                <TableHead className="font-semibold text-gray-700">Region</TableHead>
                <TableHead className="font-semibold text-gray-700">Distributor</TableHead>
                <TableHead className="font-semibold text-gray-700">Fields / Valves</TableHead>
                <TableHead className="font-semibold text-gray-700">Service Plan</TableHead>
                <TableHead className="font-semibold text-gray-700">Status</TableHead>
                <TableHead className="font-semibold text-gray-700 text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {paginatedCustomers.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center py-8 text-gray-500">
                    No farmers found matching your search.
                  </TableCell>
                </TableRow>
              ) : (
                paginatedCustomers.map((c) => (
                  <TableRow key={c.id} className="hover:bg-gray-50/50">
                    <TableCell>
                      <div>
                        <div className="font-semibold text-gray-900">{c.name}</div>
                        <div className="text-xs text-gray-500">Reg: {c.registeredAt}</div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="text-sm">
                        <div className="flex items-center space-x-1.5 text-gray-700">
                          <Phone size={12} className="text-gray-400" />
                          <span>{c.phone}</span>
                        </div>
                        <div className="flex items-center space-x-1.5 text-gray-500 text-xs mt-0.5">
                          <Mail size={12} className="text-gray-400" />
                          <span>{c.email}</span>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="text-sm text-gray-700 flex items-center space-x-1">
                        <MapPin size={12} className="text-gray-400" />
                        <span>{c.district}, {c.state}</span>
                      </div>
                    </TableCell>
                    <TableCell className="text-sm text-gray-600">{c.distributor}</TableCell>
                    <TableCell>
                      <div className="text-sm">
                        <span className="font-medium text-gray-900">{c.fieldsCount}</span> Fields
                        <span className="text-gray-400 mx-1.5">|</span>
                        <span className="font-medium text-gray-900">{c.valvesCount}</span> Valves
                      </div>
                    </TableCell>
                    <TableCell>
                      <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-50 text-blue-700 border border-blue-100">
                        {c.servicePlan}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span
                        className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold ${
                          c.status === "Active"
                            ? "bg-green-50 text-green-700 border border-green-100"
                            : "bg-red-50 text-red-700 border border-red-100"
                        }`}
                      >
                        {c.status}
                      </span>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex items-center justify-end space-x-2">
                        <button
                          onClick={() => handleOpenModal("view", c)}
                          className="p-1 hover:bg-gray-100 rounded text-gray-500 hover:text-gray-700 transition-colors"
                          title="View Fields & Devices"
                        >
                          <Eye size={16} />
                        </button>
                        <button
                          onClick={() => handleOpenModal("edit", c)}
                          className="p-1 hover:bg-gray-100 rounded text-gray-500 hover:text-green-600 transition-colors"
                          title="Edit Profile"
                        >
                          <Pencil size={16} />
                        </button>
                        <button
                          onClick={() => handleToggleStatus(c.id)}
                          className={`p-1 hover:bg-gray-100 rounded transition-colors ${
                            c.status === "Active" ? "text-red-500 hover:text-red-700" : "text-green-500 hover:text-green-700"
                          }`}
                          title={c.status === "Active" ? "Suspend Account" : "Activate Account"}
                        >
                          {c.status === "Active" ? <Ban size={16} /> : <CheckCircle2 size={16} />}
                        </button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="p-4 border-t border-gray-200">
            <Pagination>
              <PaginationContent>
                <PaginationItem>
                  <PaginationPrevious
                    onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                    disabled={currentPage === 1}
                  />
                </PaginationItem>
                {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
                  <PaginationItem key={page}>
                    <PaginationLink
                      onClick={() => setCurrentPage(page)}
                      isActive={currentPage === page}
                    >
                      {page}
                    </PaginationLink>
                  </PaginationItem>
                ))}
                <PaginationItem>
                  <PaginationNext
                    onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                    disabled={currentPage === totalPages}
                  />
                </PaginationItem>
              </PaginationContent>
            </Pagination>
          </div>
        )}
      </div>

      {/* Modal - Create, Edit, and View */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="bg-white rounded-xl shadow-lg border border-gray-200 w-full max-w-lg overflow-hidden flex flex-col max-h-[90vh]">
            {/* Modal Header */}
            <div className="p-4 border-b border-gray-200 flex items-center justify-between">
              <h3 className="text-lg font-bold text-gray-900">
                {modalMode === "create" ? "Register New Farmer" : modalMode === "edit" ? "Edit Profile" : "Farmer Profile & Field Operations"}
              </h3>
              <button onClick={handleCloseModal} className="p-1 hover:bg-gray-100 rounded text-gray-400 hover:text-gray-600">
                <X size={20} />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto flex-1">
              {modalMode === "view" ? (
                <div className="space-y-6">
                  {/* Summary Card */}
                  <div className="bg-gray-50 p-4 rounded-lg border border-gray-200">
                    <h4 className="font-bold text-gray-900 text-base">{currentCustomer?.name}</h4>
                    <p className="text-sm text-gray-500 mt-1">Village: {currentCustomer?.village || "Main Village"}</p>
                    <div className="grid grid-cols-2 gap-4 mt-4">
                      <div>
                        <div className="text-xs text-gray-400 uppercase font-semibold">Phone</div>
                        <div className="text-sm font-medium text-gray-800">{currentCustomer?.phone}</div>
                      </div>
                      <div>
                        <div className="text-xs text-gray-400 uppercase font-semibold">Service Plan</div>
                        <div className="text-sm font-medium text-gray-800">{currentCustomer?.servicePlan}</div>
                      </div>
                    </div>
                  </div>

                  {/* Fields list */}
                  <div>
                    <h4 className="font-bold text-gray-800 text-sm mb-3">Linked Farm Fields</h4>
                    <div className="space-y-3">
                      <div className="border border-gray-200 rounded-lg p-3 flex justify-between items-center">
                        <div>
                          <div className="font-semibold text-gray-800 text-sm">North Farm Block</div>
                          <div className="text-xs text-gray-500">2.5 Acres · Sugarcane</div>
                        </div>
                        <span className="text-xs font-semibold px-2 py-0.5 bg-green-50 text-green-700 rounded border border-green-100">
                          Master Online
                        </span>
                      </div>
                      <div className="border border-gray-200 rounded-lg p-3 flex justify-between items-center">
                        <div>
                          <div className="font-semibold text-gray-800 text-sm">East Canal Drip</div>
                          <div className="text-xs text-gray-500">1.8 Acres · Tomatoes</div>
                        </div>
                        <span className="text-xs font-semibold px-2 py-0.5 bg-red-50 text-red-700 rounded border border-red-100">
                          Master Offline
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Distributor & Support Info */}
                  <div className="grid grid-cols-2 gap-4">
                    <div className="border border-gray-200 rounded-lg p-3">
                      <div className="text-xs text-gray-400 font-semibold uppercase">Assigned Distributor</div>
                      <div className="text-sm font-semibold text-gray-800 mt-1">{currentCustomer?.distributor}</div>
                    </div>
                    <div className="border border-gray-200 rounded-lg p-3">
                      <div className="text-xs text-gray-400 font-semibold uppercase">Open Support Tickets</div>
                      <div className="text-sm font-semibold text-red-600 mt-1">1 Pending Ticket</div>
                    </div>
                  </div>
                </div>
              ) : (
                <form onSubmit={handleSave} className="space-y-4">
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-1">Farmer Full Name</label>
                    <input
                      type="text"
                      required
                      className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-1">Phone Number</label>
                      <input
                        type="tel"
                        required
                        className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                        value={formData.phone}
                        onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-1">Email Address</label>
                      <input
                        type="email"
                        className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                        value={formData.email}
                        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      />
                    </div>
                  </div>
                  <div className="grid grid-cols-3 gap-4">
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-1">Village</label>
                      <input
                        type="text"
                        className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                        value={formData.village}
                        onChange={(e) => setFormData({ ...formData, village: e.target.value })}
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-1">District</label>
                      <input
                        type="text"
                        required
                        className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                        value={formData.district}
                        onChange={(e) => setFormData({ ...formData, district: e.target.value })}
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-1">State</label>
                      <input
                        type="text"
                        required
                        className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                        value={formData.state}
                        onChange={(e) => setFormData({ ...formData, state: e.target.value })}
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-1">Pincode</label>
                    <input
                      type="text"
                      className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                      value={formData.pincode}
                      onChange={(e) => setFormData({ ...formData, pincode: e.target.value })}
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-1">Service Plan</label>
                      <select
                        className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                        value={formData.servicePlan}
                        onChange={(e) => setFormData({ ...formData, servicePlan: e.target.value })}
                      >
                        <option value="Starter">Starter</option>
                        <option value="Standard Growth">Standard Growth</option>
                        <option value="Premium Pro">Premium Pro</option>
                        <option value="None (Expired)">None (Expired)</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-1">Retailer / Distributor</label>
                      <select
                        className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                        value={formData.distributor}
                        onChange={(e) => setFormData({ ...formData, distributor: e.target.value })}
                      >
                        <option value="Macro Drip Distributors">Macro Drip Distributors</option>
                        <option value="Agri Drip Retailers">Agri Drip Retailers</option>
                      </select>
                    </div>
                  </div>
                  
                  {/* Actions */}
                  <div className="flex justify-end space-x-3 pt-4 border-t border-gray-200 mt-6">
                    <button
                      type="button"
                      onClick={handleCloseModal}
                      className="px-4 py-2 border border-gray-200 rounded-lg text-sm text-gray-600 hover:bg-gray-50 transition-colors"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg text-sm font-medium transition-colors"
                    >
                      Save Changes
                    </button>
                  </div>
                </form>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

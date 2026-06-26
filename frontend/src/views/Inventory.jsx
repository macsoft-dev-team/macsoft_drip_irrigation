import React, { useState } from "react"
import { 
  Package, 
  Plus, 
  Pencil, 
  Trash2, 
  X, 
  AlertTriangle, 
  TrendingUp, 
  DollarSign, 
  Layers, 
  Minus, 
  Search,
  Warehouse
} from "lucide-react"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

// Initial high-fidelity agricultural irrigation stock list
const initialInventory = [
  {
    id: 1,
    name: "12V Solenoid Valve (1-inch)",
    category: "Valves & Piping",
    quantity: 28,
    threshold: 10,
    price: 24.99,
    location: "Aisle A, Shelf 2",
  },
  {
    id: 2,
    name: "Capacitive Soil Moisture Sensor v2",
    category: "Sensors & Electrical",
    quantity: 84,
    threshold: 15,
    price: 8.50,
    location: "Aisle B, Shelf 1",
  },
  {
    id: 3,
    name: "Digital Pulse Flow Meter (2-inch)",
    category: "Sensors & Electrical",
    quantity: 6,
    threshold: 5,
    price: 45.00,
    location: "Aisle A, Shelf 4",
  },
  {
    id: 4,
    name: "16mm PE Drip Irrigation Tubing (100m)",
    category: "Valves & Piping",
    quantity: 12,
    threshold: 5,
    price: 35.00,
    location: "Yard Section B",
  },
  {
    id: 5,
    name: "16mm T-Joint Fitting (Pack of 50)",
    category: "Fittings & Accessories",
    quantity: 40,
    threshold: 8,
    price: 12.00,
    location: "Aisle C, Shelf 3",
  },
  {
    id: 6,
    name: "Adjustable Pressure Regulator (25 PSI)",
    category: "Valves & Piping",
    quantity: 18,
    threshold: 10,
    price: 18.50,
    location: "Aisle A, Shelf 1",
  },
  {
    id: 7,
    name: "120 Mesh Disc Screen Filter (1.5-inch)",
    category: "Fittings & Accessories",
    quantity: 4,
    threshold: 5,
    price: 29.99,
    location: "Aisle D, Shelf 2",
  },
  {
    id: 8,
    name: "IP67 Weatherproof Junction Box",
    category: "Sensors & Electrical",
    quantity: 0,
    threshold: 10,
    price: 15.00,
    location: "Aisle B, Shelf 3",
  }
]

export default function Inventory() {
  const [items, setItems] = useState(initialInventory)
  const [searchQuery, setSearchQuery] = useState("")
  const [selectedCategory, setSelectedCategory] = useState("All")
  
  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [modalMode, setModalMode] = useState("create") // "create" | "update" | "delete"
  const [currentItem, setCurrentItem] = useState(null)
  
  // Form states
  const [formData, setFormData] = useState({
    name: "",
    category: "Valves & Piping",
    quantity: 0,
    threshold: 5,
    price: 0.0,
    location: ""
  })

  // Dynamic calculations for summary cards
  const totalUniqueItems = items.length
  const totalStockVolume = items.reduce((acc, item) => acc + item.quantity, 0)
  const lowStockCount = items.filter(item => item.quantity <= item.threshold).length
  const totalValuation = items.reduce((acc, item) => acc + (item.quantity * item.price), 0)

  // Handlers for quick stock adjustment
  const handleQuickAdjust = (id, amount) => {
    setItems(prevItems => 
      prevItems.map(item => {
        if (item.id === id) {
          const newQty = Math.max(0, item.quantity + amount)
          return { ...item, quantity: newQty }
        }
        return item
      })
    )
  }

  const openModal = (mode, item = null) => {
    setModalMode(mode)
    setCurrentItem(item)
    if (item && mode !== "delete") {
      setFormData({
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        threshold: item.threshold,
        price: item.price,
        location: item.location
      })
    } else {
      setFormData({
        name: "",
        category: "Valves & Piping",
        quantity: 0,
        threshold: 5,
        price: 0.0,
        location: ""
      })
    }
    setIsModalOpen(true)
  }

  const closeModal = () => {
    setIsModalOpen(false)
    setCurrentItem(null)
  }

  const handleSubmit = (e) => {
    e.preventDefault()

    if (modalMode === "create") {
      const newItem = {
        id: Math.max(...items.map(i => i.id), 0) + 1,
        name: formData.name,
        category: formData.category,
        quantity: Number(formData.quantity),
        threshold: Number(formData.threshold),
        price: Number(formData.price),
        location: formData.location || "Unassigned"
      }
      setItems([...items, newItem])
    } else if (modalMode === "update") {
      setItems(items.map(i => i.id === currentItem.id ? { 
        ...i, 
        name: formData.name,
        category: formData.category,
        quantity: Number(formData.quantity),
        threshold: Number(formData.threshold),
        price: Number(formData.price),
        location: formData.location || "Unassigned"
      } : i))
    }

    closeModal()
  }

  const handleDelete = () => {
    setItems(items.filter(i => i.id !== currentItem.id))
    closeModal()
  }

  // Categories list helper
  const categories = ["All", "Valves & Piping", "Sensors & Electrical", "Fittings & Accessories"]

  // Filter & Search computation
  const filteredItems = items.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
                          item.location.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesCategory = selectedCategory === "All" || item.category === selectedCategory
    return matchesSearch && matchesCategory
  })

  // Stock status styling helper
  const getStockStatusBadge = (qty, threshold) => {
    if (qty === 0) {
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-red-50 text-red-700 border border-red-200 dark:bg-red-950/20 dark:text-red-400 dark:border-red-900/30 animate-pulse">
          <span className="h-1.5 w-1.5 rounded-full bg-red-500"></span>
          Out of Stock
        </span>
      )
    }
    if (qty <= threshold) {
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-950/20 dark:text-amber-400 dark:border-amber-900/30">
          <span className="h-1.5 w-1.5 rounded-full bg-amber-500"></span>
          Low Stock
        </span>
      )
    }
    return (
      <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-950/20 dark:text-emerald-400 dark:border-emerald-900/30">
        <span className="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>
        Optimal
      </span>
    )
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-border/60">
        <div className="flex items-center gap-2.5">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 shadow-xs">
            <Package className="h-5 w-5" />
          </div>
          <div>
            <h2 className="text-lg font-bold tracking-tight text-foreground">
              Inventory & Stock Management
            </h2>
            <p className="text-xs text-muted-foreground mt-0">Track hardware stock levels, sensors, valves, and installation accessories.</p>
          </div>
        </div>
        <button
          onClick={() => openModal("create")}
          className="inline-flex items-center justify-center rounded-lg text-xs font-bold transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/30 disabled:opacity-50 disabled:pointer-events-none bg-gradient-to-r from-emerald-600 to-teal-500 text-white hover:from-emerald-700 hover:to-teal-600 hover:-translate-y-0.5 active:translate-y-0 h-8.5 py-1 px-3 shadow-sm shadow-emerald-500/5"
        >
          <Plus className="h-3.5 w-3.5 mr-1.5" />
          Add Stock Item
        </button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
        {/* Card 1: Unique Items */}
        <div className="flex items-center gap-3 rounded-lg border border-border bg-card p-3 text-card-foreground shadow-xs hover:-translate-y-0.5 hover:shadow-sm transition-all duration-300">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
            <Layers className="h-4.5 w-4.5" />
          </div>
          <div>
            <p className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">Unique Items</p>
            <p className="text-lg font-bold font-heading mt-0">{totalUniqueItems}</p>
          </div>
        </div>

        {/* Card 2: Total Volume */}
        <div className="flex items-center gap-3 rounded-lg border border-border bg-card p-3 text-card-foreground shadow-xs hover:-translate-y-0.5 hover:shadow-sm transition-all duration-300">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-teal-500/10 text-teal-600 dark:text-teal-400 border border-teal-500/20">
            <Warehouse className="h-4.5 w-4.5" />
          </div>
          <div>
            <p className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">Total Units</p>
            <p className="text-lg font-bold font-heading mt-0">{totalStockVolume}</p>
          </div>
        </div>

        {/* Card 3: Low Stock Alerts */}
        <div className={`flex items-center gap-3 rounded-lg border p-3 text-card-foreground shadow-xs hover:-translate-y-0.5 hover:shadow-sm transition-all duration-300 ${
          lowStockCount > 0 ? "border-amber-300 bg-amber-500/5 dark:border-amber-500/15" : "border-border bg-card"
        }`}>
          <div className={`flex h-9 w-9 items-center justify-center rounded-lg ${
            lowStockCount > 0 ? "bg-amber-500/20 text-amber-600 dark:text-amber-400 border border-amber-500/30" : "bg-emerald-500/10 text-emerald-600 border border-emerald-500/20"
          }`}>
            <AlertTriangle className="h-4.5 w-4.5" />
          </div>
          <div>
            <p className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">Low Stock Alerts</p>
            <p className="text-lg font-bold font-heading mt-0 text-foreground">{lowStockCount}</p>
          </div>
        </div>

        {/* Card 4: Total Value */}
        <div className="flex items-center gap-3 rounded-lg border border-border bg-card p-3 text-card-foreground shadow-xs hover:-translate-y-0.5 hover:shadow-sm transition-all duration-300">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
            <DollarSign className="h-4.5 w-4.5" />
          </div>
          <div>
            <p className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">Total Value</p>
            <p className="text-lg font-bold font-heading mt-0">${totalValuation.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
          </div>
        </div>
      </div>

      {/* Filters & Search Control Bar */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3 bg-card border border-border p-2.5 rounded-lg shadow-xs">
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-2 h-4 w-4 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search items by name or storage location..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-3 h-8.5 border border-border rounded-lg text-xs bg-background/50 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 transition-all font-sans"
          />
        </div>

        {/* Category Filter Buttons */}
        <div className="flex flex-wrap gap-1">
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`px-2.5 py-1 text-[11px] font-semibold rounded-md transition-all cursor-pointer ${
                selectedCategory === cat
                  ? "bg-emerald-600 text-white shadow-xs"
                  : "bg-muted/40 hover:bg-muted/80 text-muted-foreground"
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* Stock Items Table */}
      <div className="rounded-lg border border-border bg-card text-card-foreground shadow-xs">
        <Table>
          <TableHeader>
            <TableRow className="h-9 hover:bg-transparent">
              <TableHead className="h-9 py-1 px-3 text-xs">Item Name</TableHead>
              <TableHead className="h-9 py-1 px-3 text-xs">Category</TableHead>
              <TableHead className="h-9 py-1 px-3 text-xs">Storage Location</TableHead>
              <TableHead className="h-9 py-1 px-3 text-center text-xs">Stock Level</TableHead>
              <TableHead className="h-9 py-1 px-3 text-right text-xs">Unit Price</TableHead>
              <TableHead className="h-9 py-1 px-3 text-right text-xs">Total Value</TableHead>
              <TableHead className="h-9 py-1 px-3 text-center text-xs">Quick Adjust</TableHead>
              <TableHead className="h-9 py-1 px-3 text-right text-xs">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredItems.length === 0 ? (
              <TableRow>
                <TableCell colSpan={8} className="h-20 text-center text-xs text-muted-foreground">
                  No stock items match your search or filter criteria.
                </TableCell>
              </TableRow>
            ) : (
              filteredItems.map((item) => (
                <TableRow key={item.id} className="hover:bg-muted/20 transition-all">
                  <TableCell className="font-semibold text-foreground py-1.5 px-3 text-xs">{item.name}</TableCell>
                  <TableCell className="text-[11px] text-muted-foreground py-1.5 px-3">{item.category}</TableCell>
                  <TableCell className="text-[11px] py-1.5 px-3">{item.location}</TableCell>
                  <TableCell className="text-center py-1.5 px-3">
                    <div className="flex flex-col items-center gap-0.5">
                      <span className="font-bold font-heading text-xs text-foreground">
                        {item.quantity} <span className="text-[10px] font-normal text-muted-foreground">/ {item.threshold} safe</span>
                      </span>
                      {getStockStatusBadge(item.quantity, item.threshold)}
                    </div>
                  </TableCell>
                  <TableCell className="text-right font-medium py-1.5 px-3 text-xs">${item.price.toFixed(2)}</TableCell>
                  <TableCell className="text-right font-semibold text-foreground py-1.5 px-3 text-xs">
                    ${(item.quantity * item.price).toFixed(2)}
                  </TableCell>
                  <TableCell className="text-center py-1.5 px-3">
                    <div className="inline-flex rounded-md border border-border bg-background p-0.5 shadow-xs">
                      <button
                        onClick={() => handleQuickAdjust(item.id, -1)}
                        title="Reduce Stock"
                        className="p-0.5 text-muted-foreground hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/20 rounded-sm transition-all cursor-pointer"
                      >
                        <Minus className="h-3 w-3" />
                      </button>
                      <div className="w-px bg-border mx-0.5" />
                      <button
                        onClick={() => handleQuickAdjust(item.id, 1)}
                        title="Add Stock"
                        className="p-0.5 text-muted-foreground hover:text-emerald-600 hover:bg-emerald-50 dark:hover:bg-emerald-950/20 rounded-sm transition-all cursor-pointer"
                      >
                        <Plus className="h-3 w-3" />
                      </button>
                    </div>
                  </TableCell>
                  <TableCell className="text-right py-1.5 px-3">
                    <div className="inline-flex items-center justify-end gap-1">
                      <button
                        onClick={() => openModal("update", item)}
                        title="Edit Item"
                        className="inline-flex h-7 w-7 items-center justify-center rounded-lg border border-border text-muted-foreground hover:text-emerald-600 hover:bg-emerald-50 dark:hover:bg-emerald-950/20 transition-all cursor-pointer"
                      >
                        <Pencil className="h-3.5 w-3.5" />
                      </button>
                      <button
                        onClick={() => openModal("delete", item)}
                        title="Delete Item"
                        className="inline-flex h-7 w-7 items-center justify-center rounded-lg border border-border text-muted-foreground hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/20 transition-all cursor-pointer"
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

      {/* Create / Edit / Delete Modal Dialog */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-fade-in">
          <div className="w-full max-w-lg bg-card rounded-xl border border-border shadow-xl overflow-hidden flex flex-col max-h-[90vh]">
            
            {/* Modal Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-border/80">
              <h3 className="text-lg font-bold text-foreground">
                {modalMode === "create" && "Add New Inventory Item"}
                {modalMode === "update" && "Edit Inventory Item"}
                {modalMode === "delete" && "Confirm Item Deletion"}
              </h3>
              <button 
                onClick={closeModal} 
                className="text-muted-foreground hover:text-foreground transition-all rounded-md p-1 hover:bg-muted/40 cursor-pointer"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Modal Content */}
            {modalMode === "delete" ? (
              <div className="p-6 flex flex-col gap-4">
                <div className="flex items-start gap-4 p-4 rounded-lg bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-900/30">
                  <AlertTriangle className="h-5 w-5 text-red-600 dark:text-red-400 shrink-0 mt-0.5" />
                  <div>
                    <h4 className="font-semibold text-red-800 dark:text-red-400 text-sm">Delete "{currentItem?.name}"?</h4>
                    <p className="text-xs text-red-700 dark:text-red-400/80 mt-1 leading-relaxed">
                      Are you sure you want to remove this item from inventory? This action is permanent and cannot be undone.
                    </p>
                  </div>
                </div>
                <div className="flex justify-end gap-3 pt-2">
                  <button
                    onClick={closeModal}
                    className="px-4 py-2 border border-border text-muted-foreground hover:text-foreground hover:bg-muted/50 rounded-lg text-sm transition-all cursor-pointer font-semibold"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleDelete}
                    className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm transition-all cursor-pointer font-semibold shadow-md shadow-red-500/10"
                  >
                    Delete Item
                  </button>
                </div>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 flex flex-col gap-4">
                {/* Item Name */}
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-semibold text-foreground uppercase tracking-wider">Item Name</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. 12V Solenoid Valve (1-inch)"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="px-3 py-2 border border-border rounded-lg text-sm bg-background/50 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all font-sans"
                  />
                </div>

                {/* Category & Location grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs font-semibold text-foreground uppercase tracking-wider">Category</label>
                    <select
                      value={formData.category}
                      onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                      className="px-3 py-2 border border-border rounded-lg text-sm bg-background focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all"
                    >
                      <option value="Valves & Piping">Valves & Piping</option>
                      <option value="Sensors & Electrical">Sensors & Electrical</option>
                      <option value="Fittings & Accessories">Fittings & Accessories</option>
                    </select>
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs font-semibold text-foreground uppercase tracking-wider">Storage Location</label>
                    <input
                      type="text"
                      placeholder="e.g. Aisle A, Shelf 2"
                      value={formData.location}
                      onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                      className="px-3 py-2 border border-border rounded-lg text-sm bg-background/50 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all font-sans"
                    />
                  </div>
                </div>

                {/* Qty, Safety Threshold & Price */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs font-semibold text-foreground uppercase tracking-wider">Qty in Stock</label>
                    <input
                      type="number"
                      required
                      min="0"
                      value={formData.quantity}
                      onChange={(e) => setFormData({ ...formData, quantity: e.target.value })}
                      className="px-3 py-2 border border-border rounded-lg text-sm bg-background/50 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all font-sans"
                    />
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs font-semibold text-foreground uppercase tracking-wider">Safety Level</label>
                    <input
                      type="number"
                      required
                      min="1"
                      value={formData.threshold}
                      onChange={(e) => setFormData({ ...formData, threshold: e.target.value })}
                      className="px-3 py-2 border border-border rounded-lg text-sm bg-background/50 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all font-sans"
                    />
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs font-semibold text-foreground uppercase tracking-wider">Unit Price ($)</label>
                    <input
                      type="number"
                      required
                      step="0.01"
                      min="0.00"
                      value={formData.price}
                      onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                      className="px-3 py-2 border border-border rounded-lg text-sm bg-background/50 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all font-sans"
                    />
                  </div>
                </div>

                {/* Modal Footer */}
                <div className="flex justify-end gap-3 pt-4 border-t border-border mt-2">
                  <button
                    type="button"
                    onClick={closeModal}
                    className="px-4 py-2 border border-border text-muted-foreground hover:text-foreground hover:bg-muted/50 rounded-lg text-sm transition-all cursor-pointer font-semibold"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 bg-gradient-to-r from-emerald-600 to-teal-500 text-white hover:from-emerald-700 hover:to-teal-600 hover:-translate-y-0.5 active:translate-y-0 rounded-lg text-sm transition-all cursor-pointer font-semibold shadow-md shadow-emerald-500/10"
                  >
                    {modalMode === "create" ? "Add Stock" : "Save Changes"}
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

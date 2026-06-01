import React from 'react';
import { LayoutGrid, List, Upload, Server, Plus, Search, FileDown, Filter, Building2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useRole } from '../../hooks/useRole';

export default function DashboardHeader({ view, setView, search, onSearch, statusFilter, onStatusFilter, customerFilter, onCustomerFilter, customers = [], onExport }) {
    const { canManageDevices } = useRole();
    const navigate = useNavigate();

    return (
        <div className="flex flex-col lg:flex-row lg:items-center justify-between z-1000 gap-5 bg-white/70 backdrop-blur-xl p-4 md:p-5 rounded-2xl border border-slate-200/60 shadow-[0_4px_20px_rgb(0,0,0,0.03)]">
            {/* Logo/Title Section */}
            <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-linear-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-lg shadow-blue-500/20">
                    <Server className="w-6 h-6 text-white" />
                </div>
                <div>
                    <h1 className="text-xl font-bold text-slate-900 tracking-tight">DEVICES</h1>
                    <div className="flex items-center gap-2 mt-0.5">
                        <span className="flex h-2 w-2 relative">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                        </span>
                        <p className="text-xs font-semibold text-slate-500 tracking-wide uppercase">System Online</p>
                    </div>
                </div>
            </div>

            <div className="flex flex-wrap items-center gap-3">

                {/* --- Provision Button (admin+ only) --- */}
                {canManageDevices() && (
                    <button
                        type="button"
                        onClick={() => navigate('/devices/new')}
                        className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-bold bg-blue-600 hover:bg-blue-700 text-white transition-colors shadow-sm shadow-blue-200"
                    >
                        <Plus className="w-4 h-4" /> Provision Device
                    </button>
                )}

                {/* Search */}
                <div className="relative flex items-center">
                    <Search className="absolute left-3 w-3.5 h-3.5 text-slate-400 pointer-events-none" />
                    <input
                        type="text"
                        value={search}
                        onChange={(e) => onSearch(e.target.value)}
                        placeholder="Search IMEI or name…"
                        className="pl-8 pr-3 py-2.5 text-sm rounded-xl border border-slate-200/80 bg-white shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500/30 focus:border-blue-400 w-52 text-slate-700 placeholder:text-slate-400"
                    />
                </div>

                {/* Status Filter */}
                <div className="relative flex items-center">
                    <Filter className="absolute left-3 w-3.5 h-3.5 text-slate-400 pointer-events-none" />
                    <select
                        value={statusFilter}
                        onChange={(e) => onStatusFilter(e.target.value)}
                        className="pl-8 pr-7 py-2.5 text-sm rounded-xl border border-slate-200/80 bg-white shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500/30 focus:border-blue-400 text-slate-700 appearance-none cursor-pointer"
                    >
                        <option value="all">All Status</option>
                        <option value="active">Active</option>
                        <option value="inactive">Inactive</option>
                    </select>
                </div>

                {/* Customer Filter — Macsoft roles only, hidden when list is empty */}
                {customers.length > 0 && (
                    <div className="relative flex items-center">
                        <Building2 className="absolute left-3 w-3.5 h-3.5 text-slate-400 pointer-events-none" />
                        <select
                            value={customerFilter}
                            onChange={(e) => onCustomerFilter(e.target.value)}
                            className="pl-8 pr-7 py-2.5 text-sm rounded-xl border border-slate-200/80 bg-white shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500/30 focus:border-blue-400 text-slate-700 appearance-none cursor-pointer max-w-45"
                        >
                            <option value="all">All Customers</option>
                            <option value="unassigned">Unassigned</option>
                            {customers.map((c) => (
                                <option key={c.id} value={c.id}>{c.name}</option>
                            ))}
                        </select>
                    </div>
                )}

                {/* Export — visible to all */}
                <button onClick={onExport} className="bg-white text-emerald-700 px-4 py-2.5 rounded-xl text-sm font-bold border border-emerald-200 hover:bg-emerald-50 transition-colors flex items-center gap-2 shadow-sm">
                    <FileDown className="w-4 h-4" /> Export
                </button>

                {/* Import — admin+ only */}
          {/*       {canManageDevices() && (
                    <button onClick={onOpenUpload} className="bg-white text-slate-700 px-4 py-2.5 rounded-xl text-sm font-bold border border-slate-200/80 hover:bg-slate-50 hover:text-blue-600 transition-colors flex items-center gap-2 shadow-sm">
                        <Upload className="w-4 h-4" /> Import
                    </button>
                )} */}

                <div className="w-px h-8 bg-slate-200 mx-1 hidden sm:block"></div>

                {/* View Toggles */}
                <div className="flex bg-slate-100/80 p-1 rounded-xl border border-slate-200/60 ml-auto lg:ml-0 shadow-inner">
                    <button onClick={() => setView('table')} className={`px-3.5 py-2 rounded-lg flex items-center gap-2 text-xs font-bold transition-all ${view === 'table' ? 'bg-white shadow-sm text-blue-600' : 'text-slate-500 hover:text-slate-700'}`}>
                        <List className="w-4 h-4" />
                    </button>
                    <button onClick={() => setView('kanban')} className={`px-3.5 py-2 rounded-lg flex items-center gap-2 text-xs font-bold transition-all ${view === 'kanban' ? 'bg-white shadow-sm text-blue-600' : 'text-slate-500 hover:text-slate-700'}`}>
                        <LayoutGrid className="w-4 h-4" />
                    </button>
                </div>
            </div>
        </div>
    );
}
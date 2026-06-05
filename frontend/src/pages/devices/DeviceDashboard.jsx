// src/devices/DeviceDashboard.jsx
import React, { useState, useEffect, useMemo } from 'react';
import * as XLSX from 'xlsx';
import { motion, AnimatePresence } from 'motion/react';
import { Cpu, CheckCircle, X, Server, Wifi, Terminal, Settings, Sparkles, ArrowRight } from 'lucide-react';
import toast from 'react-hot-toast';
import { useNavigate } from 'react-router-dom';
import { DataTable } from '../../components';
import DashboardHeader from './DashboardHeader';
import KanbanView, { MqttModal } from './KanbanView';
import UploadModal from './UploadModal';
import DeviceTelemetryPanel from './DeviceTelemetryPanel';
import CommandModal from './CommandModal';
import DeviceConfigModal from './DeviceConfigModal';
import { useDevice } from '../../hooks/useDevice';
import { useAllDevicesSocket } from '../../hooks/useAllDevicesSocket';
import { useCustomers } from '../../hooks/useCustomers';
import { useRole } from '../../hooks/useRole';

export default function DeviceDashboard() {
    const navigate = useNavigate();
    const { devices, loading, error, loadDevices, createDevice, uploadDevice } = useDevice();
    const { isMacsoftRole } = useRole();
    const { customers } = useCustomers({ pageSize: 200 });
    const [uploadedImeis, setUploadedImeis] = useState([]);
    const [view, setView] = useState('table');
    const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
    const [selectedDevice, setSelectedDevice] = useState(null);
    const [mqttDevice, setMqttDevice] = useState(null);
    const [cmdDevice, setCmdDevice] = useState(null);
    const [configDevice, setConfigDevice] = useState(null);
    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState('all');
    const [customerFilter, setCustomerFilter] = useState('all');
    const [isAdBannerOpen, setIsAdBannerOpen] = useState(() => localStorage.getItem('macsoft_dashboard_ad_dismissed') !== 'true');

    const handleCloseAdBanner = () => {
        setIsAdBannerOpen(false);
        localStorage.setItem('macsoft_dashboard_ad_dismissed', 'true');
    };

    // Local copy of devices so live socket updates don't require a Redux round-trip
    const [liveDevices, setLiveDevices] = useState([]);

    const filteredDevices = useMemo(() => {
        const q = search.trim().toLowerCase();
        return liveDevices.filter((d) => {
            const matchSearch = !q ||
                (d.imeinumber || '').toLowerCase().includes(q) ||
                (d.name || '').toLowerCase().includes(q);
            const matchStatus =
                statusFilter === 'all' ||
                (statusFilter === 'active' && d.isActive) ||
                (statusFilter === 'inactive' && !d.isActive);
            const matchCustomer =
                customerFilter === 'all' ||
                (customerFilter === 'unassigned' ? !d.customerId : d.customerId === customerFilter);
            return matchSearch && matchStatus && matchCustomer;
        });
    }, [liveDevices, search, statusFilter, customerFilter]);

    const handleExport = () => {
        const rows = filteredDevices.map((d) => ({
            IMEI: d.imeinumber,
            Name: d.name || '',
            Status: d.isActive ? 'Active' : 'Inactive',
            Customer: d.user ? `${d.user.firstname} ${d.user.lastname}` : '',
            'Last Heartbeat': d.telemetry?.[0]?.timestamp
                ? new Date(d.telemetry[0].timestamp).toLocaleString('en-GB')
                : '',
        }));
        const ws = XLSX.utils.json_to_sheet(rows);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Devices');
        XLSX.writeFile(wb, `devices_${new Date().toISOString().slice(0, 10)}.xlsx`);
    };
    useEffect(() => { setLiveDevices(devices); }, [devices]);

    // Update heartbeat + active status for any device that sends telemetry
    useAllDevicesSocket((deviceId, row) => {
        setLiveDevices((prev) =>
            prev.map((d) =>
                d.id === deviceId
                    ? { ...d, brokerConnected: true, isActive: true, lastStatus: 'ONLINE', telemetry: [row] }
                    : d
            )
        );
    });

    useEffect(() => {
        const params = { skip: 0, take: 50 };
        loadDevices(params);

        const intervalId = window.setInterval(() => {
            loadDevices(params);
        }, 15000);

        return () => window.clearInterval(intervalId);
    }, [loadDevices]);

    // --- Actions ---
    const handleAddDevice = async (imeiInput) => {
        const result = await createDevice(imeiInput);
        if (result.error) {
            toast.error(result.payload || 'Failed to create device');
        } else {
            toast.success(`Device ${imeiInput} added successfully`);
        }
    };

    const handleUpload = (imeis, result) => {
        setUploadedImeis(imeis);
        loadDevices({ skip: 0, take: 50 });
        const data = result?.payload?.data;
        if (data) {
            toast.success(`${data.created} device(s) imported, ${data.skipped} skipped`);
        } else {
            toast.success(`${imeis.length} device(s) imported successfully`);
        }
    };

    const dismissUploadBanner = () => setUploadedImeis([]);

    // --- Table Configuration ---
    const tableColumns = [
        {
            header: 'IMEI Number',
            accessor: 'imeinumber',
            sortable: true,
            cell: (row) => (
                <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-slate-100 border border-slate-200 flex items-center justify-center">
                        <Cpu className="w-4 h-4 text-slate-500" />
                    </div>
                    <span className="font-mono text-slate-700 font-semibold">{row.imeinumber}</span>
                </div>
            )
        }, 
        ...(isMacsoftRole() ? [{
            header: 'Customer',
            accessor: 'customer',
            sortable: false,
            cell: (row) => (
                <span className="text-xs text-slate-500 font-medium">{row.customer?.name || <span className="text-slate-300">—</span>}</span>
            )
        }] : []),
        {
            header: 'Status',
            accessor: 'isActive',
            sortable: true,
            align: 'center',
            cell: (row) => {
                const isActive = row.isActive;
                return (
                    <div className="flex justify-center">
                        <span className={`flex items-center gap-2 px-2.5 py-1 rounded-md text-[11px] font-bold uppercase tracking-wider border transition-all duration-300 ${isActive
                                ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                                : 'bg-slate-50 text-slate-500 border-slate-200'
                            }`}>
                            <span className="relative flex h-2 w-2">
                                {isActive && <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>}
                                <span className={`relative inline-flex rounded-full h-2 w-2 ${isActive ? 'bg-emerald-500' : 'bg-slate-400'}`}></span>
                            </span>
                            {isActive ? 'Active' : 'Inactive'}
                        </span>
                    </div>
                )
            }
        },
        {
            header: 'Recent Heartbeat',
            accessor: 'telemetryLogs',
            sortable: false,
            align: 'right',
            cell: (row) => {
                const t = row.telemetry?.[0]?.timestamp;
                return (
                    <div className="text-right">
                        {t ? (
                            <>
                                <p className="text-slate-700 text-xs font-medium">{new Date(t).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}</p>
                                <p className="text-slate-400 text-[11px] font-mono">{new Date(t).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}</p>
                            </>
                        ) : (
                            <span className="text-slate-300 text-xs">No data yet</span>
                        )}
                    </div>
                );
            }
        },
        {
            header: 'Actions',
            accessor: 'actions',
            sortable: false,
            align: 'center',
            cell: (row) => (
                <div className="flex items-center justify-center gap-1" onClick={(e) => e.stopPropagation()}>
                    <button
                        title="MQTT Details"
                        onClick={() => setMqttDevice(row)}
                        className="p-1.5 rounded-lg text-blue-500 bg-blue-50 border border-blue-200 hover:bg-blue-100 hover:border-blue-300 transition-colors"
                    >
                        <Wifi className="w-3.5 h-3.5" />
                    </button>
                    <button
                        title="Command Console"
                        onClick={() => setCmdDevice(row)}
                        className="p-1.5 rounded-lg text-violet-500 bg-violet-50 border border-violet-200 hover:bg-violet-100 hover:border-violet-300 transition-colors"
                    >
                        <Terminal className="w-3.5 h-3.5" />
                    </button>
                    <button
                        title="Device Config"
                        onClick={() => setConfigDevice(row)}
                        className="p-1.5 rounded-lg text-emerald-500 bg-emerald-50 border border-emerald-200 hover:bg-emerald-100 hover:border-emerald-300 transition-colors"
                    >
                        <Settings className="w-3.5 h-3.5" />
                    </button>
                </div>
            )
        }
    ];

    return (
        <div className="min-h-screen bg-slate-50 text-slate-900 p-4 md:p-8 font-sans relative selection:bg-blue-100 selection:text-blue-900">
            <div className="absolute inset-0 z-0 bg-[radial-gradient(#e2e8f0_1px,transparent_1px)] bg-size-[16px_16px] opacity-40 pointer-events-none"></div>

            <div className="max-w-7xl mx-auto space-y-6 relative z-10">
                <DashboardHeader
                    view={view}
                    setView={setView}
                    search={search}
                    onSearch={setSearch}
                    statusFilter={statusFilter}
                    onStatusFilter={setStatusFilter}
                    customerFilter={customerFilter}
                    onCustomerFilter={setCustomerFilter}
                    customers={isMacsoftRole() ? customers : []}
                    onExport={handleExport}
                />

                <AnimatePresence>
                    {isAdBannerOpen && (
                        <motion.div
                            initial={{ opacity: 0, y: -20, height: 0 }}
                            animate={{ opacity: 1, y: 0, height: 'auto' }}
                            exit={{ opacity: 0, y: -20, height: 0 }}
                            transition={{ duration: 0.3, ease: 'easeInOut' }}
                            className="overflow-hidden"
                        >
                            <div className="relative overflow-hidden rounded-2xl border border-indigo-500/20 bg-linear-to-r from-indigo-950 via-slate-900 to-blue-950 p-5 md:p-6 text-white shadow-xl shadow-indigo-950/10 mb-6">
                                {/* Decorative glowing blobs */}
                                <div className="absolute -right-10 -top-10 w-40 h-40 bg-indigo-500/10 rounded-full blur-2xl pointer-events-none"></div>
                                <div className="absolute -left-10 -bottom-10 w-40 h-40 bg-blue-500/10 rounded-full blur-2xl pointer-events-none"></div>

                                <div className="relative flex flex-col md:flex-row gap-5 items-start md:items-center justify-between">
                                    <div className="flex gap-4 items-start">
                                        <div className="w-12 h-12 rounded-xl bg-linear-to-tr from-indigo-500 to-blue-500 flex items-center justify-center shadow-lg shadow-indigo-500/30 shrink-0 animate-pulse">
                                            <Sparkles className="w-6 h-6 text-white" />
                                        </div>
                                        <div className="space-y-1">
                                            <div className="flex flex-wrap items-center gap-2">
                                                <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase tracking-wider bg-indigo-500/20 border border-indigo-500/30 text-indigo-300">
                                                    Featured Product
                                                </span>
                                                <span className="text-xs text-indigo-200/80 font-medium">Store Special Offer</span>
                                            </div>
                                            <h3 className="text-lg font-bold text-white leading-snug tracking-tight">
                                                Soil Moisture Sensor Pro
                                            </h3>
                                            <p className="text-sm text-slate-300 max-w-2xl">
                                                Capacitive soil moisture sensor with corrosion-resistant probe for high-accuracy soil wetting profiles. Save up to 40% water with real-time moisture telemetry.
                                            </p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-3 w-full md:w-auto justify-end">
                                        <button 
                                            onClick={() => {
                                                toast.success('Promo Code MOIST20 Applied! 20% discount applied to Soil Moisture Sensor Pro.', {
                                                    icon: '🎉',
                                                    duration: 5000
                                                });
                                            }}
                                            className="w-full md:w-auto flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl text-sm font-bold bg-white text-indigo-950 hover:bg-slate-100 transition-all duration-300 shadow-md shadow-white/5 active:scale-95 group shrink-0 cursor-pointer"
                                        >
                                            Apply Discount
                                            <ArrowRight className="w-4 h-4 text-indigo-950 group-hover:translate-x-0.5 transition-transform" />
                                        </button>
                                        <button 
                                            onClick={handleCloseAdBanner}
                                            className="p-2 text-slate-400 hover:text-white hover:bg-white/10 rounded-xl transition-all duration-300 shrink-0 cursor-pointer"
                                            title="Dismiss Ad"
                                        >
                                            <X className="w-5 h-5" />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>

                <AnimatePresence>
                    {uploadedImeis.length > 0 && (
                        <motion.div
                            initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }}
                            className="overflow-hidden"
                        >
                            <div className="relative flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between border border-blue-200 bg-linear-to-r from-blue-50 to-indigo-50/50 rounded-xl p-4 shadow-sm">
                                <div>
                                    <div className="flex items-center gap-2 font-bold text-blue-800 mb-2 text-xs uppercase tracking-wider">
                                        <CheckCircle className="w-4 h-4" /> {/* Replaced SVG */}
                                        Successfully Uploaded {uploadedImeis.length} Devices
                                    </div>
                                    <div className="flex flex-wrap gap-2">
                                        {uploadedImeis.map((imei, i) => (
                                            <span key={i} className="font-mono text-[11px] font-medium bg-white/80 backdrop-blur-sm border border-blue-200/60 rounded-md px-2.5 py-1 text-blue-700 shadow-sm">
                                                {imei}
                                            </span>
                                        ))}
                                    </div>
                                </div>
                                <button onClick={dismissUploadBanner} className="p-2 text-blue-400 hover:text-blue-600 hover:bg-blue-100/50 rounded-lg transition-colors shrink-0">
                                    <X className="w-5 h-5" /> {/* Replaced SVG */}
                                </button>
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>

                <div className="min-h-100">
                    <AnimatePresence mode="wait">
                        {devices.length === 0 ? (
                            <EmptyState key="empty" setIsUploadModalOpen={setIsUploadModalOpen} />
                        ) : view === 'table' ? (
                            <motion.div key="table" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
                                <DataTable columns={tableColumns} data={filteredDevices} itemsPerPage={8} onRowClick={(row) => navigate(`/devices/${row.id}`)} />
                            </motion.div>
                        ) : (
                            <motion.div key="kanban" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
                                <KanbanView devices={filteredDevices} />
                            </motion.div>
                        )}
                    </AnimatePresence>
                </div>
            </div>

            <UploadModal
                isOpen={isUploadModalOpen}
                onClose={() => setIsUploadModalOpen(false)}
                onUpload={handleUpload}
            />

            {/* Telemetry panel backdrop */}
            <AnimatePresence>
                {selectedDevice && (
                    <>
                        <motion.div
                            key="backdrop"
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            exit={{ opacity: 0 }}
                            className="fixed inset-0 z-40 bg-slate-950/30 backdrop-blur-[2px]"
                            onClick={() => setSelectedDevice(null)}
                        />
                        <DeviceTelemetryPanel
                            key={selectedDevice.id}
                            device={selectedDevice}
                            onClose={() => setSelectedDevice(null)}
                        />
                    </>
                )}
            </AnimatePresence>

            <AnimatePresence>
                {mqttDevice && (
                    <MqttModal device={mqttDevice} onClose={() => setMqttDevice(null)} />
                )}
            </AnimatePresence>
            <AnimatePresence>
                {cmdDevice && (
                    <CommandModal device={cmdDevice} onClose={() => setCmdDevice(null)} />
                )}
            </AnimatePresence>
            <AnimatePresence>
                {configDevice && (
                    <DeviceConfigModal device={configDevice} onClose={() => setConfigDevice(null)} />
                )}
            </AnimatePresence>
        </div>
    );
}

// --- Components ---
const EmptyState = ({ setIsUploadModalOpen }) => (
    <motion.div
        initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}
        className="flex flex-col items-center justify-center p-12 mt-8 bg-white border border-slate-200 border-dashed rounded-2xl shadow-sm"
    >
        <div className="w-16 h-16 bg-blue-50 text-blue-500 rounded-full flex items-center justify-center mb-4">
            <Server className="w-8 h-8" /> {/* Replaced SVG */}
        </div>
        <h3 className="text-lg font-bold text-slate-900 mb-2">No devices found</h3>
        <p className="text-slate-500 text-sm max-w-sm text-center mb-6">
            You haven't added any devices yet. Add a single device via IMEI or upload a batch CSV to get started.
        </p>
        <div className="flex gap-3">
            <button onClick={() => document.getElementById('add-device-input')?.focus()} className="px-4 py-2 bg-slate-900 text-white text-sm font-medium rounded-lg hover:bg-slate-800 transition-colors">
                Add Device manually
            </button>
            <button onClick={() => setIsUploadModalOpen(true)} className="px-4 py-2 bg-white border border-slate-200 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors">
                Upload Batch
            </button>
        </div>
    </motion.div>
);

// src/components/KanbanView.jsx
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { AnimatePresence, motion } from 'motion/react';
import { ArrowLeft, ArrowRight, Cpu, Wifi, WifiOff, Copy, Check, Terminal, Settings, ExternalLink } from 'lucide-react';
import { useDeviceSocket } from '../../hooks/useDeviceSocket';
import CommandModal, { getFaults } from './CommandModal';
import DeviceConfigModal from './DeviceConfigModal';
import RightDrawer from '../../components/RightDrawer';

// --- MQTT Details Modal ---
export const MqttModal = ({ device, onClose }) => {
    const [copied, setCopied] = useState(null);

    const copyToClipboard = (key, value) => {
        navigator.clipboard.writeText(value);
        setCopied(key);
        setTimeout(() => setCopied(null), 2000);
    };

    const fields = [
        { label: 'Client ID',       key: 'mqttClientId',       value: device.mqttClientId },
        { label: 'Username',        key: 'mqttUsername',        value: device.mqttUsername },
        { label: 'Password',        key: 'mqttPassword',        value: device.mqttPassword, secret: true },
        { label: 'Data Topic',      key: 'mqttTelemetryTopic',  value: device.mqttTelemetryTopic },
        { label: 'Command Topic',   key: 'mqttCommandTopic',    value: device.mqttCommandTopic },
        { label: 'Response Topic',  key: 'mqttAckTopic',        value: device.mqttAckTopic },
    ];

    return (
        <RightDrawer
            onClose={onClose}
            title="MQTT Details"
            subtitle={device.imeinumber}
            icon={<Cpu className="w-4 h-4 text-blue-600" />}
            footer={
                <button
                    onClick={onClose}
                    className="w-full py-2 rounded-xl text-sm font-semibold text-slate-600 border border-slate-200 hover:bg-slate-100 transition-colors"
                >
                    Close
                </button>
            }
        >
            <div className="flex-1 overflow-y-auto p-5 space-y-2">
                {fields.map(({ label, key, value, secret }) => (
                    <div key={key} className="flex items-center justify-between gap-3 p-3 bg-slate-50 rounded-xl border border-slate-100 group">
                        <div className="min-w-0">
                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-0.5">{label}</p>
                            <p className={`text-xs font-mono font-semibold text-slate-700 truncate ${secret ? 'blur-sm group-hover:blur-none transition-all' : ''}`}>
                                {value || '—'}
                            </p>
                        </div>
                        {value && (
                            <button
                                onClick={() => copyToClipboard(key, value)}
                                className="shrink-0 p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                title="Copy"
                            >
                                {copied === key ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
                            </button>
                        )}
                    </div>
                ))}
            </div>
        </RightDrawer>
    );
};

const FAULT_COLOR = { red: 'bg-red-50 border-red-200 text-red-600', orange: 'bg-orange-50 border-orange-200 text-orange-600', amber: 'bg-amber-50 border-amber-200 text-amber-600', yellow: 'bg-yellow-50 border-yellow-200 text-yellow-600' };

// Sub-component for individual cards
const DeviceCard = ({ device }) => {
    const navigate = useNavigate();
    const [showMqtt, setShowMqtt] = useState(false);
    const [showCmd, setShowCmd] = useState(false);
    const [showConfig, setShowConfig] = useState(false);
    const isActive = device.isActive;

    // Seed latest telemetry from what was loaded with the device list,
    // then keep it live via WebSocket.
    const [latest, setLatest] = useState(device.telemetryLogs?.[0] ?? null);
    useDeviceSocket(device.id, (row) => setLatest(row));

    const createdAt = device.createdAt
        ? new Date(device.createdAt).toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
        : '—';

    return (
        <>
            <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm hover:border-blue-200 transition-all flex flex-col gap-3">
                <div className="flex justify-between items-start">
                    <div className="flex gap-1.5">
                        <button
                            onClick={() => setShowMqtt(true)}
                            className="p-2 bg-slate-100 rounded-lg hover:bg-blue-100 hover:text-blue-600 transition-colors"
                            title="View MQTT details"
                        >
                            <Cpu className="w-4 h-4 text-slate-500" />
                        </button>
                        <button
                            onClick={() => setShowCmd(true)}
                            className="p-2 bg-slate-100 rounded-lg hover:bg-violet-100 hover:text-violet-600 transition-colors"
                            title="Send command"
                        >
                            <Terminal className="w-4 h-4 text-slate-500" />
                        </button>
                        <button
                            onClick={() => setShowConfig(true)}
                            className="p-2 bg-slate-100 rounded-lg hover:bg-emerald-100 hover:text-emerald-600 transition-colors"
                            title="Device configuration"
                        >
                            <Settings className="w-4 h-4 text-slate-500" />
                        </button>
                        <button
                            onClick={() => navigate(`/devices/${device.id}`)}
                            className="p-2 bg-slate-100 rounded-lg hover:bg-indigo-100 hover:text-indigo-600 transition-colors"
                            title="Open device dashboard"
                        >
                            <ExternalLink className="w-4 h-4 text-slate-500" />
                        </button>
                    </div>
                    <span className={`flex items-center gap-1.5 px-2 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider border ${isActive
                            ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                            : 'bg-slate-50 text-slate-400 border-slate-200'
                        }`}>
                        {isActive ? <Wifi className="w-3 h-3" /> : <WifiOff className="w-3 h-3" />}
                        {isActive ? 'Connected' : 'Offline'}
                    </span>
                </div>

                <div>
                    <div className="flex items-center justify-between mb-1">
                        <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">IMEI</p>
                        {device.config?.rmd != null && (
                            <span className={`px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider border ${
                                device.config.rmd === 1
                                    ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                                    : 'bg-amber-50 text-amber-700 border-amber-200'
                            }`}>
                                {device.config.rmd === 1 ? 'Auto' : 'Manual'}
                            </span>
                        )}
                    </div>
                    <h3 className="font-mono font-bold text-slate-800 text-sm break-all">{device.imeinumber}</h3>
                </div>

                {device.name && (
                    <p className="text-xs text-slate-500 font-medium truncate">{device.name}</p>
                )}

                {/* Latest Telemetry */}
                {latest ? (
                    <div className="pt-2 border-t border-slate-100 space-y-1.5">
                        {/* Fault badges */}
                        {getFaults(latest.flt).length > 0 && (
                            <div className="flex flex-wrap gap-1">
                                {getFaults(latest.flt).map(({ bit, label, color }) => (
                                    <span key={bit} className={`px-2 py-0.5 rounded-full text-[9px] font-bold uppercase border tracking-wide ${FAULT_COLOR[color]}`}>
                                        ⚠ {label}
                                    </span>
                                ))}
                            </div>
                        )}
                        {/* Phase voltages IV1-IV3 and motor currents IC1-IC5 */}
                        <div className="grid grid-cols-2 gap-1.5 pt-0.5">
                            <div>
                                <p className="text-[9px] font-bold text-blue-400 uppercase tracking-widest mb-1">Voltage</p>
                                <div className="space-y-1">
                                    {[1, 2, 3].map((n) => {
                                        const value = latest[`iv${n}`];
                                        return (
                                            <TeleStat
                                                key={`iv${n}`}
                                                label={`IV${n}`}
                                                value={value != null ? `${Number(value).toFixed(1)} V` : '—'}
                                                color="blue"
                                            />
                                        );
                                    })}
                                </div>
                            </div>
                            <div>
                                <p className="text-[9px] font-bold text-amber-400 uppercase tracking-widest mb-1">Current</p>
                                <div className="space-y-1 max-h-28 overflow-y-auto pr-0.5">
                                    {[1, 2, 3, 4, 5].map((n) => {
                                        const value = latest[`ic${n}`];
                                        return (
                                            <TeleStat
                                                key={`ic${n}`}
                                                label={`IC${n}`}
                                                value={value != null ? `${Number(value).toFixed(2)} A` : '—'}
                                                color="amber"
                                            />
                                        );
                                    })}
                                </div>
                            </div>
                        </div>
                    </div>
                ) : (
                    <div className="pt-2 border-t border-slate-100">
                        <p className="text-[10px] text-slate-300 text-center font-medium">No telemetry yet</p>
                    </div>
                )}

                <div className="pt-2 border-t border-slate-100 mt-auto flex items-center justify-between">
                    <p className="text-[10px] text-slate-400 font-medium">Added {createdAt}</p>
                    {latest && (
                        <p className="text-[10px] text-slate-300 font-mono">
                            {new Date(latest.time).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })}
                        </p>
                    )}
                </div>
            </div>

            <AnimatePresence>
                {showMqtt && <MqttModal device={device} onClose={() => setShowMqtt(false)} />}
                {showCmd && <CommandModal device={device} onClose={() => setShowCmd(false)} />}
                {showConfig && <DeviceConfigModal device={device} onClose={() => setShowConfig(false)} />}
            </AnimatePresence>
        </>
    );
};

const COLOR_MAP = {
    blue: 'bg-blue-50 border-blue-100 text-blue-700',
    amber: 'bg-amber-50 border-amber-100 text-amber-700',
    slate: 'bg-slate-50 border-slate-100 text-slate-700',
};

const TeleStat = ({ label, value, color = 'slate' }) => (
    <div className={`rounded-lg px-2 py-1.5 text-center border ${COLOR_MAP[color] ?? COLOR_MAP.slate}`}>
        <p className="text-[9px] font-bold opacity-60 uppercase tracking-wide">{label}</p>
        <p className="text-[11px] font-bold font-mono mt-0.5">{value}</p>
    </div>
);

export default function KanbanView({ devices }) {
    const [currentPage, setCurrentPage] = useState(1);
    const itemsPerPage = 8;
    const totalPages = Math.max(1, Math.ceil(devices.length / itemsPerPage));
    const currentData = devices.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

    return (
        <>
            <motion.div key="kanban" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {currentData.map((device) => (
                    <DeviceCard key={device.id} device={device} />
                ))}
            </motion.div>

            {totalPages > 1 && (
                <div className="flex items-center justify-between pt-2">
                    <p className="text-xs text-slate-500 font-medium">Page {currentPage} of {totalPages}</p>
                    <div className="flex gap-1">
                        <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1} className="p-2 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 disabled:opacity-30 transition-all"><ArrowLeft className="w-4 h-4" /></button>
                        <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages} className="p-2 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 disabled:opacity-30 transition-all"><ArrowRight className="w-4 h-4" /></button>
                    </div>
                </div>
            )}
        </>
    );
}

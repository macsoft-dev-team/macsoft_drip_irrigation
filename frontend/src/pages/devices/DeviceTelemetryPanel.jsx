// src/pages/devices/DeviceTelemetryPanel.jsx
import React, { useState, useEffect, useRef, useCallback } from 'react';
import { motion as _motion } from 'motion/react';
const MotionPanel = _motion.div;
import { X, Download, RefreshCw, Activity, Wifi, WifiOff, Radio } from 'lucide-react';
import * as XLSX from 'xlsx';
import { useDevice } from '../../hooks/useDevice';
import { useDeviceSocket } from '../../hooks/useDeviceSocket';
import { useSocket } from '../../hooks/useSocket';

const PAGE_SIZE = 50;

const TELEMETRY_COLUMNS = [
    { key: 'timestamp', label: 'Timestamp',           format: (v) => v ? new Date(v).toLocaleString('en-GB') : '—' },
    { key: 'prs',       label: 'Pressure (bar)',       format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'vfr',       label: 'VFD Freq (Hz)',        format: (v) => v != null ? String(v) : '—' },
    { key: 'iv1',       label: 'Phase Voltage 1 (V)', format: (v) => v != null ? Number(v).toFixed(1) : '—' },
    { key: 'iv2',       label: 'Phase Voltage 2 (V)', format: (v) => v != null ? Number(v).toFixed(1) : '—' },
    { key: 'iv3',       label: 'Phase Voltage 3 (V)', format: (v) => v != null ? Number(v).toFixed(1) : '—' },
    { key: 'ic1',       label: 'Motor Current 1 (A)', format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'ic2',       label: 'Motor Current 2 (A)', format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'ic3',       label: 'Motor Current 3 (A)', format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'ic4',       label: 'Motor Current 4 (A)', format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'ic5',       label: 'Motor Current 5 (A)', format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'flt',       label: 'Fault Code',           format: (v) => v != null ? String(v) : '—' },
    { key: 'p1s',       label: 'P1 Status',            format: (v) => v != null ? ['VFD','DOL','Stop','Service'][v] ?? v : '—' },
    { key: 'p2s',       label: 'P2 Status',            format: (v) => v != null ? ['VFD','DOL','Stop','Service'][v] ?? v : '—' },
    { key: 'p3s',       label: 'P3 Status',            format: (v) => v != null ? ['VFD','DOL','Stop','Service'][v] ?? v : '—' },
    { key: 'p4s',       label: 'P4 Status',            format: (v) => v != null ? ['VFD','DOL','Stop','Service'][v] ?? v : '—' },
    { key: 'p5s',       label: 'P5 Status',            format: (v) => v != null ? ['VFD','DOL','Stop','Service'][v] ?? v : '—' },
    { key: 'p1r',       label: 'P1 Run Mins',          format: (v) => v != null ? String(v) : '—' },
    { key: 'p2r',       label: 'P2 Run Mins',          format: (v) => v != null ? String(v) : '—' },
    { key: 'p3r',       label: 'P3 Run Mins',          format: (v) => v != null ? String(v) : '—' },
    { key: 'p4r',       label: 'P4 Run Mins',          format: (v) => v != null ? String(v) : '—' },
    { key: 'p5r',       label: 'P5 Run Mins',          format: (v) => v != null ? String(v) : '—' },
    { key: 's1h',       label: 'P1 Starts/hr',         format: (v) => v != null ? String(v) : '—' },
    { key: 's2h',       label: 'P2 Starts/hr',         format: (v) => v != null ? String(v) : '—' },
    { key: 's3h',       label: 'P3 Starts/hr',         format: (v) => v != null ? String(v) : '—' },
    { key: 's4h',       label: 'P4 Starts/hr',         format: (v) => v != null ? String(v) : '—' },
    { key: 's5h',       label: 'P5 Starts/hr',         format: (v) => v != null ? String(v) : '—' },
];

// ---- sub-components ----
const LiveBadge = ({ live }) => (
    <span className={`flex items-center gap-1 px-2 py-0.5 rounded-full text-[9px] font-bold uppercase border transition-all ${
        live ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : 'bg-slate-50 text-slate-400 border-slate-200'
    }`}>
        <span className={`w-1.5 h-1.5 rounded-full ${live ? 'bg-emerald-500 animate-ping' : 'bg-slate-400'}`} />
        {live ? 'Live' : 'Offline'}
    </span>
);

const TelemetryRow = ({ row, flash }) => (
    <tr className={`transition-colors ${flash ? 'bg-blue-50/60' : 'hover:bg-slate-50/40'}`}>
        {TELEMETRY_COLUMNS.map(({ key, format }) => (
            <td key={key} className="px-3 py-2 font-mono text-slate-600 text-xs whitespace-nowrap">
                {format(row[key])}
            </td>
        ))}
    </tr>
);

export default function DeviceTelemetryPanel({ device, onClose }) {
    const { connected } = useSocket() ?? {};

    // --- history state (lazy-loaded) ---
    const { telemetryLoading, loadTelemetry } = useDevice();
    const [rows, setRows] = useState([]);
    const [page, setPage] = useState(0);
    const [hasMore, setHasMore] = useState(true);
    const loaderRef = useRef(null);

    const todayStr = new Date().toISOString().split('T')[0];
    const defaultFrom = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const [from, setFrom] = useState(defaultFrom);
    const [to, setTo] = useState(todayStr);

    // --- live state ---
    const [liveRows, setLiveRows] = useState([]);
    const [flashId, setFlashId] = useState(null);

    // subscribe to socket
    useDeviceSocket(device?.id, useCallback((row) => {
        setLiveRows((prev) => {
            // keep max 200 live rows
            const next = [row, ...prev].slice(0, 200);
            return next;
        });
        setFlashId(row.timestamp);
        setTimeout(() => setFlashId(null), 800);
    }, []));

    // load initial page on mount / date change
    const fetchPage = useCallback(async (pageNum, reset = false) => {
        const result = await loadTelemetry({
            deviceId: device.id,
            from: `${from}T00:00:00`,
            to: `${to}T23:59:59`,
            skip: pageNum * PAGE_SIZE,
            take: PAGE_SIZE,
        });
        const fetched = result?.payload ?? [];
        if (reset) {
            setRows(fetched);
        } else {
            setRows((prev) => [...prev, ...fetched]);
        }
        if (fetched.length < PAGE_SIZE) setHasMore(false);
        else setHasMore(true);
    }, [device.id, from, to, loadTelemetry]);

    // initial load
    useEffect(() => {
        setPage(0);
        setRows([]);
        setHasMore(true);
        fetchPage(0, true);
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [device.id]);

    // infinite scroll via IntersectionObserver
    useEffect(() => {
        if (!hasMore || telemetryLoading) return;
        const el = loaderRef.current;
        if (!el) return;
        const obs = new IntersectionObserver(
            ([entry]) => {
                if (entry.isIntersecting) {
                    const nextPage = page + 1;
                    setPage(nextPage);
                    fetchPage(nextPage);
                }
            },
            { threshold: 0.1 }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, [hasMore, telemetryLoading, page, fetchPage]);

    const handleLoad = () => {
        setPage(0);
        setRows([]);
        setHasMore(true);
        fetchPage(0, true);
    };

    const handleExcel = () => {
        const all = [...liveRows, ...rows];
        if (!all.length) return;
        const data = all.map((row) => {
            const out = {};
            TELEMETRY_COLUMNS.forEach(({ key, label }) => {
                out[label] = key === 'time'
                    ? (row[key] ? new Date(row[key]).toLocaleString('en-GB') : '')
                    : (row[key] != null ? row[key] : '');
            });
            return out;
        });
        const ws = XLSX.utils.json_to_sheet(data);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Telemetry');
        XLSX.writeFile(wb, `telemetry_${device.imeinumber}_${from}_${to}.xlsx`);
    };

    const allRows = [...liveRows, ...rows];

    return (
        <MotionPanel
            initial={{ x: '100%', opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: '100%', opacity: 0 }}
            transition={{ type: 'spring', stiffness: 320, damping: 32 }}
            className="fixed top-0 right-0 h-full w-full max-w-2xl z-50 flex flex-col bg-white border-l border-slate-200 shadow-2xl"
        >
            {/* Header */}
            <div className="px-5 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/60 shrink-0">
                <div className="flex items-center gap-3">
                    <div className="p-2 bg-white rounded-xl shadow-sm border border-slate-100">
                        <Activity className="w-4 h-4 text-blue-600" />
                    </div>
                    <div>
                        <div className="flex items-center gap-2">
                            <p className="text-sm font-bold text-slate-800">Device Logs</p>
                            <LiveBadge live={connected} />
                        </div>
                        <div className="flex items-center gap-2 flex-wrap mt-0.5">
                            <p className="text-[11px] text-slate-400 font-mono">{device.imeinumber}</p>
                            {device.name && <span className="text-[11px] text-slate-400">· {device.name}</span>}
                            <span className={`flex items-center gap-1 px-1.5 py-0.5 rounded-full text-[9px] font-bold uppercase border ${
                                device.isActive
                                    ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                                    : 'bg-slate-50 text-slate-400 border-slate-200'
                            }`}>
                                {device.isActive ? <Wifi className="w-2.5 h-2.5" /> : <WifiOff className="w-2.5 h-2.5" />}
                                {device.isActive ? 'Active' : 'Inactive'}
                            </span>
                            {liveRows.length > 0 && (
                                <span className="flex items-center gap-1 px-1.5 py-0.5 rounded-full text-[9px] font-bold uppercase border bg-blue-50 text-blue-700 border-blue-200">
                                    <Radio className="w-2.5 h-2.5" />
                                    {liveRows.length} live
                                </span>
                            )}
                        </div>
                    </div>
                </div>
                <button onClick={onClose} className="p-1.5 text-slate-400 hover:text-slate-700 hover:bg-slate-200/50 rounded-lg transition-colors">
                    <X className="w-4 h-4" />
                </button>
            </div>

            {/* Date Range + Actions */}
            <div className="px-5 py-3 border-b border-slate-100 flex flex-wrap items-center gap-3 shrink-0 bg-white">
                <div className="flex items-center gap-2">
                    <label className="text-[11px] font-bold text-slate-500 uppercase tracking-wide">From</label>
                    <input type="date" value={from} onChange={(e) => setFrom(e.target.value)}
                        className="text-xs border border-slate-200 rounded-lg px-2.5 py-1.5 text-slate-700 focus:outline-none focus:ring-1 focus:ring-blue-400 bg-slate-50" />
                </div>
                <div className="flex items-center gap-2">
                    <label className="text-[11px] font-bold text-slate-500 uppercase tracking-wide">To</label>
                    <input type="date" value={to} onChange={(e) => setTo(e.target.value)}
                        className="text-xs border border-slate-200 rounded-lg px-2.5 py-1.5 text-slate-700 focus:outline-none focus:ring-1 focus:ring-blue-400 bg-slate-50" />
                </div>
                <button onClick={handleLoad} disabled={telemetryLoading}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-900 text-white text-xs font-semibold rounded-lg hover:bg-slate-700 disabled:opacity-40 transition-colors">
                    <RefreshCw className={`w-3.5 h-3.5 ${telemetryLoading ? 'animate-spin' : ''}`} />
                    Load
                </button>
                <button onClick={handleExcel} disabled={!allRows.length || telemetryLoading}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 text-white text-xs font-semibold rounded-lg hover:bg-emerald-500 disabled:opacity-40 transition-colors ml-auto">
                    <Download className="w-3.5 h-3.5" />
                    Excel
                </button>
            </div>

            {/* Telemetry Table */}
            <div className="flex-1 overflow-auto">
                {allRows.length === 0 && !telemetryLoading ? (
                    <div className="flex flex-col items-center justify-center h-full min-h-40 text-slate-400 gap-2">
                        <Activity className="w-8 h-8 opacity-30" />
                        <p className="text-sm">No telemetry data for this range</p>
                        <p className="text-xs text-slate-300">Select a date range and click Load</p>
                    </div>
                ) : (
                    <>
                        <div className="overflow-x-auto">
                            <table className="w-full text-left whitespace-nowrap">
                                <thead className="sticky top-0 bg-slate-50 border-b border-slate-200 text-[10px] uppercase tracking-wider text-slate-500 z-10">
                                    <tr>
                                        {TELEMETRY_COLUMNS.map(({ label }) => (
                                            <th key={label} className="px-3 py-2.5 font-bold">{label}</th>
                                        ))}
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {allRows.map((row, i) => (
                                        <TelemetryRow
                                            key={`${row.timestamp}-${i}`}
                                            row={row}
                                            flash={row.timestamp === flashId}
                                        />
                                    ))}
                                </tbody>
                            </table>
                        </div>

                        {/* Lazy-load sentinel */}
                        {hasMore && (
                            <div ref={loaderRef} className="flex items-center justify-center py-4 text-slate-400">
                                <RefreshCw className="w-4 h-4 animate-spin mr-2" />
                                <span className="text-xs">Loading more…</span>
                            </div>
                        )}

                        <div className="px-4 py-2 border-t border-slate-100 text-[11px] text-slate-400 flex gap-3">
                            <span>{allRows.length} row{allRows.length !== 1 ? 's' : ''}</span>
                            {liveRows.length > 0 && (
                                <span className="text-blue-500">{liveRows.length} live</span>
                            )}
                        </div>
                    </>
                )}

                {telemetryLoading && rows.length === 0 && (
                    <div className="flex items-center justify-center h-40 text-slate-400">
                        <RefreshCw className="w-5 h-5 animate-spin mr-2" />
                        <span className="text-sm">Loading telemetry…</span>
                    </div>
                )}
            </div>
        </MotionPanel>
    );
}


  
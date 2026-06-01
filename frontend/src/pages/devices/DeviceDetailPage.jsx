import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { motion, AnimatePresence } from 'motion/react';
import * as XLSX from 'xlsx';
import {
    ArrowLeft, Activity, WifiOff, Radio, Cpu,
    Terminal, Settings, Download, RefreshCw, Signal,
    AlertTriangle, CheckCircle2, XCircle, Gauge, ChevronDown,
    ChevronUp, Send, RotateCcw, Maximize2, Minimize2, Zap,
} from 'lucide-react';
import toast from 'react-hot-toast';
import {
    LineChart, Line, AreaChart, Area, ResponsiveContainer,
    CartesianGrid, XAxis, YAxis, Tooltip, ReferenceLine,
} from 'recharts';
import { fetchDeviceById } from '../../reducers/deviceSlice';
import { useDevice } from '../../hooks/useDevice';
import { useDeviceSocket } from '../../hooks/useDeviceSocket';
import { useSocket } from '../../hooks/useSocket';
import CommandModal from './CommandModal';
import DeviceConfigModal from './DeviceConfigModal';
import { Tank, Pump, Pipe, PipeJoint } from '../../components/scada';

// ─── Constants ────────────────────────────────────────────────────────────────

/** Indexed by fault code 0-35 (from dataFormat.txt address 40067) */
const FAULT_DESCRIPTIONS = [
    'No Fault',                       // 0
    'Voltage Low',                    // 1
    'High Voltage',                   // 2
    'VFD Trip',                       // 3
    'Low Pressure Cutoff',            // 4
    'High Pressure Alarm',            // 5
    'Pump Max Hour Reached',          // 6
    'Water Sump Level Low',           // 7
    'PT Fault',                       // 8
    'Emergency Stop',                 // 9
    'Phase Reversal Fault',           // 10
    'Pump 1 \u2013 VFD Dry Run',      // 11
    'Pump 1 \u2013 VFD Overload',     // 12
    'Pump 1 \u2013 Max Starts Reached', // 13
    'Pump 1 \u2013 DOL Overload',     // 14
    'Pump 1 \u2013 DOL Dry Run',      // 15
    'Pump 2 \u2013 VFD Dry Run',      // 16
    'Pump 2 \u2013 VFD Overload',     // 17
    'Pump 2 \u2013 Max Starts Reached', // 18
    'Pump 2 \u2013 DOL Overload',     // 19
    'Pump 2 \u2013 DOL Dry Run',      // 20
    'Pump 3 \u2013 VFD Dry Run',      // 21
    'Pump 3 \u2013 VFD Overload',     // 22
    'Pump 3 \u2013 Max Starts Reached', // 23
    'Pump 3 \u2013 DOL Overload',     // 24
    'Pump 3 \u2013 DOL Dry Run',      // 25
    'Pump 4 \u2013 VFD Dry Run',      // 26
    'Pump 4 \u2013 VFD Overload',     // 27
    'Pump 4 \u2013 Max Starts Reached', // 28
    'Pump 4 \u2013 DOL Overload',     // 29
    'Pump 4 \u2013 DOL Dry Run',      // 30
    'Pump 5 \u2013 VFD Dry Run',      // 31
    'Pump 5 \u2013 VFD Overload',     // 32
    'Pump 5 \u2013 Max Starts Reached', // 33
    'Pump 5 \u2013 DOL Overload',     // 34
    'Pump 5 \u2013 DOL Dry Run',      // 35
];

/** Pump status codes 0=VFD, 1=DOL, 2=STOP, 3=SERVICE */
const PUMP_STATUS = {
    0: { label: 'VFD', color: 'text-cyan-600', bg: 'bg-cyan-50 border-cyan-200', dot: 'bg-cyan-500' },
    1: { label: 'DOL', color: 'text-green-600', bg: 'bg-green-50 border-green-200', dot: 'bg-green-500' },
    2: { label: 'Stop', color: 'text-slate-500', bg: 'bg-slate-50 border-slate-200', dot: 'bg-slate-400' },
    3: { label: 'Service', color: 'text-amber-600', bg: 'bg-amber-50 border-amber-200', dot: 'bg-amber-500' },
};

/** Config field definitions (commandcodes.csv / addresses 40101-40123) */
const CONFIG_FIELDS = [
    { key: 'mxp', label: 'Max Pressure', unit: 'bar', code: 'MXP' },
    { key: 'mnp', label: 'Min Pressure', unit: 'bar', code: 'MNP' },
    { key: 'tfs', label: 'Transducer Full Scale', unit: 'bar', code: 'TFS' },
    { key: 'stp', label: 'Set Pressure', unit: 'bar', code: 'STP' },
    { key: 'dfp', label: 'Differential Pressure', unit: 'bar', code: 'DFP' },
    { key: 'wut', label: 'Warm Up Time', unit: 'hrs', code: 'WUT' },
    { key: 'lpc', label: 'Low Pressure Cutoff Delay', unit: 'mins', code: 'LPC' },
    { key: 'msh', label: 'Max Starts / hr', unit: '', code: 'MSH' },
    { key: 'hvg', label: 'High Voltage', unit: 'V', code: 'HVG' },
    { key: 'lvg', label: 'Low Voltage', unit: 'V', code: 'LVG' },
    { key: 'vcd', label: 'Voltage Cutoff Delay', unit: 'secs', code: 'VCD' },
    { key: 'olc', label: 'Overload Current', unit: 'A', code: 'OLC' },
    { key: 'ocd', label: 'Overload Cutoff Delay', unit: 'secs', code: 'OCD' },
    { key: 'drc', label: 'Dry Run Current', unit: 'A', code: 'DRC' },
    { key: 'drd', label: 'Dry Run Delay', unit: 'secs', code: 'DRD' },
    { key: 'swf', label: 'Switching Frequency', unit: 'Hz', code: 'SWF' },
    { key: 'swt', label: 'Switching Time', unit: 'secs', code: 'SWT' },
    { key: 'slf', label: 'Sleep Frequency', unit: 'Hz', code: 'SLF' },
    { key: 'slt', label: 'Sleep Time', unit: 'secs', code: 'SLT' },
    { key: 'pof', label: 'PID Overwrite Frequency', unit: 'Hz', code: 'POF' },
    { key: 'pgn', label: 'Proportional Gain', unit: '', code: 'PGN' },
    { key: 'ign', label: 'Integral Gain', unit: '', code: 'IGN' },
    { key: 'dgn', label: 'Derivative Gain', unit: '', code: 'DGN' },
    { key: 'stm', label: 'Scan Time', unit: 'ms', code: 'STM' },
];

const TELEMETRY_COLUMNS = [
    { key: 'timestamp', label: 'Timestamp', format: (v) => v ? new Date(v).toLocaleString('en-GB') : '—' },
    { key: 'prs', label: 'Pressure (bar)', format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'vfr', label: 'VFD (Hz)', format: (v) => v != null ? v : '—' },
    { key: 'iv1', label: 'Phase Voltage 1 (V)', format: (v) => v != null ? Number(v).toFixed(1) : '—' },
    { key: 'iv2', label: 'Phase Voltage 2 (V)', format: (v) => v != null ? Number(v).toFixed(1) : '—' },
    { key: 'iv3', label: 'Phase Voltage 3 (V)', format: (v) => v != null ? Number(v).toFixed(1) : '—' },
    { key: 'ic1', label: 'Motor Current 1 (A)', format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'ic2', label: 'Motor Current 2 (A)', format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'ic3', label: 'Motor Current 3 (A)', format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'ic4', label: 'Motor Current 4 (A)', format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'ic5', label: 'Motor Current 5 (A)', format: (v) => v != null ? Number(v).toFixed(2) : '—' },
    { key: 'flt', label: 'Fault', format: (v) => v != null ? `${v} – ${FAULT_DESCRIPTIONS[v] ?? 'Unknown'}` : '—' },
    { key: 'p1s', label: 'P1 Status', format: (v) => v != null ? ['VFD', 'DOL', 'Stop', 'Service'][v] ?? v : '—' },
    { key: 'p2s', label: 'P2 Status', format: (v) => v != null ? ['VFD', 'DOL', 'Stop', 'Service'][v] ?? v : '—' },
    { key: 'p3s', label: 'P3 Status', format: (v) => v != null ? ['VFD', 'DOL', 'Stop', 'Service'][v] ?? v : '—' },
    { key: 'p4s', label: 'P4 Status', format: (v) => v != null ? ['VFD', 'DOL', 'Stop', 'Service'][v] ?? v : '—' },
    { key: 'p5s', label: 'P5 Status', format: (v) => v != null ? ['VFD', 'DOL', 'Stop', 'Service'][v] ?? v : '—' },
    { key: 'p1r', label: 'P1 Run Mins', format: (v) => v != null ? v : '—' },
    { key: 'p2r', label: 'P2 Run Mins', format: (v) => v != null ? v : '—' },
    { key: 'p3r', label: 'P3 Run Mins', format: (v) => v != null ? v : '—' },
    { key: 'p4r', label: 'P4 Run Mins', format: (v) => v != null ? v : '—' },
    { key: 'p5r', label: 'P5 Run Mins', format: (v) => v != null ? v : '—' },
    { key: 's1h', label: 'P1 Starts/hr', format: (v) => v != null ? v : '—' },
    { key: 's2h', label: 'P2 Starts/hr', format: (v) => v != null ? v : '—' },
    { key: 's3h', label: 'P3 Starts/hr', format: (v) => v != null ? v : '—' },
    { key: 's4h', label: 'P4 Starts/hr', format: (v) => v != null ? v : '—' },
    { key: 's5h', label: 'P5 Starts/hr', format: (v) => v != null ? v : '—' },
];

const PAGE_SIZE = 50;
const MAX_LIVE_PTS = 60;

const getPumpCount = (pumpModel) => {
    const m = pumpModel?.match(/MODEL_(\d+)P(\d+)/);
    if (!m) return 1;
    return parseInt(m[1]) + parseInt(m[2]);
};

const fmtTime = (ts) =>
    ts ? new Date(ts).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' }) : '';

// ─── InputPowerPanel ──────────────────────────────────────────────────────────

function InputPowerPanel({ t }) {
    const faultCode = t?.flt ?? 0;
    const hasFault = faultCode > 0;
    const faultDesc = FAULT_DESCRIPTIONS[faultCode] ?? 'Unknown';

    const voltages = [1, 2, 3].map((n) => ({
        label: `IV${n}`,
        value: t?.[`iv${n}`],
        unit: 'V',
    }));
    const currents = [1, 2, 3, 4, 5].map((n) => ({
        label: `IC${n}`,
        value: t?.[`ic${n}`],
        unit: 'A',
    }));

    const ValueRow = ({ label, value, unit, accent }) => (
        <div className="flex items-center justify-between gap-2 px-3 py-2 rounded-xl bg-slate-50 border border-slate-200">
            <div className="flex items-center gap-2">
                <div className={`w-3 h-3 rounded-full ${accent} animate-pulse shrink-0`} />
                <span className="text-sm font-bold text-slate-600">{label}</span>
            </div>
            <p className="text-xs font-mono font-semibold text-slate-700">
                {value != null ? `${Number(value).toFixed(unit === 'A' ? 2 : 1)} ${unit}` : '—'}
            </p>
        </div>
    );

    return (
        <div className="rounded-2xl p-5 shadow-sm border border-slate-200 bg-white h-full flex flex-col gap-4">
            <p className="text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Input Power</p>

            <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
                <div className="space-y-2">
                    <p className="text-[9px] font-extrabold uppercase tracking-widest text-blue-400">Phase Voltage</p>
                    {voltages.map((item) => (
                        <ValueRow key={item.label} {...item} accent="bg-sky-500 shadow-[0_0_8px_rgba(14,165,233,0.8)]" />
                    ))}
                </div>
                <div className="space-y-2">
                    <p className="text-[9px] font-extrabold uppercase tracking-widest text-amber-400">Motor Current</p>
                    {currents.map((item) => (
                        <ValueRow key={item.label} {...item} accent="bg-amber-400 shadow-[0_0_8px_rgba(251,191,36,0.8)]" />
                    ))}
                </div>
            </div>

            <div className="flex items-center justify-between px-3 py-3 rounded-xl bg-sky-50 border border-sky-200">
                <div className="flex items-center gap-2">
                    <Zap className="w-4 h-4 text-cyan-400" />
                    <span className="text-xs font-bold text-slate-500 uppercase tracking-wide">VFD Freq</span>
                </div>
                <span className="text-lg font-mono font-bold text-cyan-500">
                    {t?.vfr != null ? `${t.vfr} Hz` : '—'}
                </span>
            </div>

            <div className="rounded-xl border px-3 py-3 flex flex-col gap-1 transition-colors"
                style={{ borderColor: hasFault ? '#fca5a5' : '#d1fae5', background: hasFault ? '#fff1f2' : '#f0fdf4' }}>
                <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-slate-500 uppercase tracking-wide">Fault</span>
                    <div className="flex items-center gap-1.5">
                        <div className={`w-2.5 h-2.5 rounded-full animate-pulse ${hasFault ? 'bg-red-500' : 'bg-emerald-500'}`} />
                        <span className={`text-xs font-bold ${hasFault ? 'text-red-600' : 'text-emerald-600'}`}>
                            {hasFault ? 'FAULT' : 'NORMAL'}
                        </span>
                    </div>
                </div>
                <p className="text-[11px] font-semibold text-slate-600">{faultDesc}</p>
                <p className="text-[10px] text-slate-400 font-mono">Code: {String(faultCode).padStart(3, '0')}</p>
            </div>
        </div>
    );
}

// ─── LivePressureChart ────────────────────────────────────────────────────────

function LivePressureChart({ data }) {
    return (
        <div className="rounded-2xl p-5 shadow-sm border border-slate-200 bg-white">
            <div className="flex items-center justify-between mb-3">
                <p className="text-[11px] font-extrabold uppercase tracking-widest text-slate-400">Running Pressure (Live)</p>
                {data.length > 0 && (
                    <span className="flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-50 text-blue-600 border border-blue-200">
                        <Radio className="w-2.5 h-2.5" /> {data.length} pts
                    </span>
                )}
            </div>
            {data.length === 0 ? (
                <div className="flex items-center justify-center h-32 text-slate-300">
                    <Activity className="w-6 h-6 animate-pulse mr-2" />
                    <span className="text-sm">Waiting for live data…</span>
                </div>
            ) : (
                <ResponsiveContainer width="100%" height={140}>
                    <LineChart data={data}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                        <XAxis dataKey="time" stroke="#94a3b8" tick={{ fontSize: 10 }} interval="preserveStartEnd" />
                        <YAxis stroke="#94a3b8" tick={{ fontSize: 10 }} width={36} />
                        <Tooltip
                            contentStyle={{ backgroundColor: '#fff', border: '1px solid #e2e8f0', borderRadius: '8px', fontSize: 11 }}
                            formatter={(v) => [`${v} bar`, 'Pressure']}
                        />
                        <Line type="monotone" dataKey="prs" stroke="#06b6d4" strokeWidth={2} dot={false} />
                    </LineChart>
                </ResponsiveContainer>
            )}
        </div>
    );
}

// ─── PressureHistoryChart ─────────────────────────────────────────────────────

function PressureHistoryChart({ device }) {
    const { loadTelemetry, telemetryLoading } = useDevice();
    const [data, setData] = useState([]);
    const setPoint = device?.config?.stp ?? null;
    const maxPressure = device?.config?.mxp ?? null;

    useEffect(() => {
        let cancelled = false;
        loadTelemetry({
            deviceId: device.id,
            from: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
            to: new Date().toISOString(),
            skip: 0, take: 200,
        }).then((result) => {
            if (cancelled) return;
            const rows = result?.payload ?? [];
            // Pressure is system-wide — map every row directly, no per-pump filtering
            setData(rows.map((r) => ({ time: fmtTime(r.timestamp), prs: r.prs ?? 0 })));
        });
        return () => { cancelled = true; };
    }, [device.id, loadTelemetry]);

    const yMax = maxPressure ? maxPressure * 1.1 : undefined;

    return (
        <div className="rounded-2xl p-5 shadow-sm border border-slate-200 bg-white">
            <div className="flex items-center justify-between mb-3">
                <p className="text-[11px] font-extrabold uppercase tracking-widest text-slate-400">System Pressure History (24h)</p>
                <div className="flex items-center gap-3 text-[10px]">
                    <span className="flex items-center gap-1">
                        <span className="inline-block w-3 h-0.5 bg-cyan-400 rounded" />
                        <span className="text-slate-400">Pressure</span>
                    </span>
                    {setPoint != null && (
                        <span className="flex items-center gap-1">
                            <span className="inline-block w-3 h-0.5 bg-orange-400 rounded" style={{ borderTop: '2px dashed #f97316' }} />
                            <span className="text-orange-500 font-bold">SP {setPoint} bar</span>
                        </span>
                    )}
                </div>
            </div>
            {data.length === 0 && !telemetryLoading ? (
                <div className="flex items-center justify-center h-40 text-slate-300">
                    <Activity className="w-5 h-5 mr-2" />
                    <span className="text-sm">No pressure data</span>
                </div>
            ) : (
                <ResponsiveContainer width="100%" height={180}>
                    <AreaChart data={data}>
                        <defs>
                            <linearGradient id="pGrad" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#06b6d4" stopOpacity={0.25} />
                                <stop offset="95%" stopColor="#06b6d4" stopOpacity={0} />
                            </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                        <XAxis dataKey="time" stroke="#94a3b8" tick={{ fontSize: 10 }} interval="preserveStartEnd" />
                        <YAxis stroke="#94a3b8" tick={{ fontSize: 10 }} width={36} domain={[0, yMax ?? 'auto']} />
                        <Tooltip
                            contentStyle={{ backgroundColor: '#fff', border: '1px solid #e2e8f0', borderRadius: '8px', fontSize: 11 }}
                            formatter={(v) => [`${v} bar`, 'Pressure']}
                        />
                        {setPoint != null && (
                            <ReferenceLine y={setPoint} stroke="#f97316" strokeDasharray="4 3" strokeWidth={1.5}
                                label={{ value: `SP ${setPoint}`, position: 'insideTopRight', fill: '#f97316', fontSize: 9, fontWeight: 'bold' }} />
                        )}
                        <Area type="monotone" dataKey="prs" stroke="#06b6d4" strokeWidth={2} fill="url(#pGrad)" dot={false} />
                    </AreaChart>
                </ResponsiveContainer>
            )}
            {telemetryLoading && <div className="text-center mt-2"><RefreshCw className="w-4 h-4 animate-spin inline text-slate-300" /></div>}
        </div>
    );
}

// ─── Command Presets ─────────────────────────────────────────────────────────
// All values are plain decimal integers — sent as-is to MQTT publish.
// Packed-register bit layout: MOD bit0=Auto, bit1=Manual, bit2-6=P1-P5 VFD, bit7-11=P1-P5 DOL
//                              PRR bit0-4=P1-P5 reset, PSM bit0-4=P1-P5 service, PML bit0-3=model
const CMD_PRESETS = [
    { group: 'Mode (MOD)', items: [
        { label: 'AUTO',         payload: { MOD: 1  }, desc: 'decimal 1  — bit0 Auto ON' },
        { label: 'MANUAL',       payload: { MOD: 2  }, desc: 'decimal 2  — bit1 Manual ON' },
    ]}, 
    { group: 'Fault (FLT)', items: [
        { label: 'Clear Fault',  payload: { FLT: 0  }, desc: 'decimal 0  — clear active fault' },
    ]},
    { group: 'Service Mode (PSM)', items: [
        { label: 'P1 Svc ON',    payload: { PSM: 1  }, desc: 'decimal 1  — bit0 pump 1' },
        { label: 'P2 Svc ON',    payload: { PSM: 2  }, desc: 'decimal 2  — bit1 pump 2' },
        { label: 'P3 Svc ON',    payload: { PSM: 4  }, desc: 'decimal 4  — bit2 pump 3' },
        { label: 'P4 Svc ON',    payload: { PSM: 8  }, desc: 'decimal 8  — bit3 pump 4' },
        { label: 'P5 Svc ON',    payload: { PSM: 16 }, desc: 'decimal 16 — bit4 pump 5' },
        { label: 'PSM OFF',      payload: { PSM: 0  }, desc: 'decimal 0  — all service OFF' },
    ]},
    { group: 'Run Mins Reset (PRR)', items: [
        { label: 'P1 Reset',     payload: { PRR: 1  }, desc: 'decimal 1  — bit0 pump 1' },
        { label: 'P2 Reset',     payload: { PRR: 2  }, desc: 'decimal 2  — bit1 pump 2' },
        { label: 'P3 Reset',     payload: { PRR: 4  }, desc: 'decimal 4  — bit2 pump 3' },
        { label: 'P4 Reset',     payload: { PRR: 8  }, desc: 'decimal 8  — bit3 pump 4' },
        { label: 'P5 Reset',     payload: { PRR: 16 }, desc: 'decimal 16 — bit4 pump 5' },
    ]},
];

// ─── CommandEditorPanel ───────────────────────────────────────────────────────

function CommandEditorPanel({ device }) {
    const { sendCommand, commandSending, loadCommands, commandsLoading } = useDevice();
    const [jsonInput, setJsonInput] = useState('{\n  "MOD": 1\n}');
    const [jsonError, setJsonError] = useState(null);
    const [showPresets, setShowPresets] = useState(false);
    const logEndRef = useRef(null);
    const [logs, setLogs] = useState([`> Device: ${device?.code || device?.imeinumber}`]);

    // Fetch command history on mount — API returns newest-first, so reverse for bottom=newest display
    useEffect(() => {
        if (!device?.id) return;
        loadCommands({ deviceId: device.id, take: 30, skip: 0 }).then((action) => {
            const history = action?.payload;
            if (!Array.isArray(history) || history.length === 0) {
                setLogs([`> Device: ${device?.code || device?.imeinumber}`, '> No history. Ready.']);
                return;
            }
            const historyLines = [...history].reverse().map((c) => {
                const ts = new Date(c.sentAt || c.createdAt).toLocaleTimeString('en-GB');
                const statusIcon = c.status === 'SENT' ? '✓' : c.status === 'FAILED' ? '✗' : '…';
                return `[${ts}] ${statusIcon} ${c.commandCode}: ${c.value}  (${c.status})`;
            });
            setLogs([`> Device: ${device?.code || device?.imeinumber}`, ...historyLines, '> Ready.']);
        });
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [device?.id]);

    // Append newest at bottom (standard terminal direction)
    const addLog = (msg) =>
        setLogs((p) => [...p.slice(-49), `[${new Date().toLocaleTimeString('en-GB')}] ${msg}`]);

    // Auto-scroll log to latest entry
    useEffect(() => { logEndRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [logs]);

    const handleJsonInput = (val) => {
        setJsonInput(val);
        try { JSON.parse(val); setJsonError(null); } catch { setJsonError('Invalid JSON'); }
    };

    const handleSend = async () => {
        let payload;
        try {
            payload = JSON.parse(jsonInput);
            setJsonError(null);
        } catch {
            setJsonError('Invalid JSON');
            toast.error('Invalid JSON');
            return;
        }
        addLog(`\u2192 ${JSON.stringify(payload)}`);
        const result = await sendCommand({ deviceId: device.id, payload });
        if (result.error) { addLog('\u2717 Failed'); toast.error('Command failed'); }
        else { addLog('\u2713 Sent OK'); toast.success('Command sent'); setJsonInput('{\n  \n}'); }
    };

    const quickCmds = [
        { label: 'AUTO',    payload: { MOD: 1 }, cls: 'bg-cyan-500/10 border-cyan-300 text-cyan-600' },
        { label: 'MANUAL',  payload: { MOD: 2 }, cls: 'bg-amber-500/10 border-amber-300 text-amber-600' },
        { label: 'FLT CLR', payload: { FLT: 0 }, cls: 'bg-red-500/10 border-red-300 text-red-600' },
    ];

    return (
        <div className="rounded-2xl shadow-sm border border-slate-200 bg-white overflow-hidden">
            <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between">
                <div className="flex items-center gap-2">
                    <Terminal className="w-4 h-4 text-slate-400" />
                    <p className="text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Command Editor</p>
                </div>
                <button
                    onClick={() => setShowPresets(v => !v)}
                    className={`text-[10px] font-bold px-2.5 py-1 rounded-lg border transition-colors ${showPresets ? 'bg-violet-100 border-violet-300 text-violet-600' : 'border-slate-200 text-slate-400 hover:text-slate-600'}`}>
                    Presets
                </button>
            </div>

            {/* Presets panel — clicking a preset populates the textarea for review before sending */}
            {showPresets && (
                <div className="px-4 py-3 border-b border-slate-100 bg-slate-50 space-y-3 max-h-65 overflow-y-auto">
                    {CMD_PRESETS.map(({ group, items }) => (
                        <div key={group}>
                            <p className="text-[9px] font-extrabold uppercase tracking-widest text-slate-400 mb-1.5">{group}</p>
                            <div className="flex flex-wrap gap-1.5">
                                {items.map(({ label, payload, desc }) => (
                                    <button
                                        key={label}
                                        title={desc}
                                        onClick={() => {
                                            setJsonInput(JSON.stringify(payload, null, 2));
                                            setJsonError(null);
                                        }}
                                        className="px-2.5 py-1 text-[10px] font-bold rounded-lg border border-violet-200 bg-white text-violet-600 hover:bg-violet-50 transition-colors">
                                        {label}
                                        <span className="ml-1 font-mono text-slate-400">{Object.values(payload)[0]}</span>
                                    </button>
                                ))}
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Quick-send buttons */}
            <div className="px-4 pt-3 pb-2 flex flex-wrap gap-1.5">
                {quickCmds.map(({ label, payload, cls }) => (
                    <button key={label} onClick={() =>
                        sendCommand({ deviceId: device.id, payload }).then((r) =>
                            addLog(`\u2192 ${label} (${JSON.stringify(payload)}): ${r.error ? '\u2717 failed' : '\u2713 sent'}`)
                        )}
                        className={`px-2.5 py-1 text-xs font-bold rounded-lg border transition-all ${cls}`}>
                        {label}
                    </button>
                ))}
            </div>

            {/* Log history — fixed height, newest at bottom, auto-scrolls */}
            <div className="mx-4 mb-2 rounded-xl bg-sky-50 border border-sky-300 p-3 font-mono text-[10px] text-slate-500 space-y-0.5 h-35 overflow-y-auto">
                {commandsLoading
                    ? <div className="flex items-center gap-1.5 text-slate-400"><RefreshCw className="w-3 h-3 animate-spin" /> Loading history…</div>
                    : logs.map((l, i) => <div key={i}>{l}</div>)
                }
                <div ref={logEndRef} />
            </div>

            <div className="px-4 pb-4 space-y-2">
                <textarea
                    rows={3}
                    value={jsonInput}
                    onChange={(e) => handleJsonInput(e.target.value)}
                    spellCheck={false}
                    placeholder={'{\n  "MOD": 1\n}'}
                    className={`w-full font-mono text-xs text-slate-900 rounded-xl px-3 py-2.5 outline-none border-2 resize-none bg-slate-50 ${jsonError ? 'border-red-400' : 'border border-gray-200 focus:border-cyan-400'}`}
                />
                {jsonError && <p className="text-[10px] text-red-500 font-mono">{jsonError}</p>}
                <button onClick={handleSend} disabled={commandSending || !!jsonError}
                    className="w-full py-2 rounded-xl bg-cyan-500 hover:bg-cyan-600 disabled:opacity-50 text-white text-sm font-semibold flex items-center justify-center gap-2 transition-colors">
                    {commandSending ? <RefreshCw className="w-3.5 h-3.5 animate-spin" /> : <Send className="w-3.5 h-3.5" />}
                    {commandSending ? 'Sending\u2026' : 'Send Command'}
                </button>
            </div>
        </div>
    );
}

// ─── PressureArcGauge ────────────────────────────────────────────────────────

function PressureArcGauge({ pressure = 2.8, maxPressure = 8, setPoint = 4 }) {
    // Increased SIZE and viewBox to give the outer tick labels room to breathe
    const SIZE = 120;
    const CX = SIZE / 2;
    const CY = SIZE / 2;
    const R = 42;
    const STROKE_WIDTH = 10;

    // Arc calculations
    const GAP_DEG = 90; // 90 degree gap at the bottom
    const ARC_DEG = 360 - GAP_DEG; // 270 degree arc
    const START_ROT = 90 + GAP_DEG / 2; // 135 degrees (starts at bottom left)

    const circ = 2 * Math.PI * R;
    const arcLen = circ * (ARC_DEG / 360);

    const pct = Math.min(Math.max(pressure / maxPressure, 0), 1);
    const fillLen = arcLen * pct;

    // Colors matching your image
    const color = pct >= 0.85 ? '#ef4444' : pct >= 0.65 ? '#f59e0b' : '#0ea5e9';
    const trackColor = '#e2e8f0';
    const spColor = '#f97316';

    // Set-point Tick Math
    let spTick = null;
    if (setPoint != null && maxPressure > 0) {
        const spPct = Math.min(Math.max(setPoint / maxPressure, 0), 1);
        const spAngle = START_ROT + spPct * ARC_DEG;

        // Removed the `- 90` bug here. SVG 0 degrees is exactly 3 o'clock.
        const rad = spAngle * (Math.PI / 180);

        // Tick goes from inner edge of the stroke to slightly outside
        const inner = R - STROKE_WIDTH / 2;
        const outer = R + STROKE_WIDTH / 2 + 4; // Sticks out by 4px

        const x1 = CX + inner * Math.cos(rad);
        const y1 = CY + inner * Math.sin(rad);
        const x2 = CX + outer * Math.cos(rad);
        const y2 = CY + outer * Math.sin(rad);

        // Label position slightly further out from the tick
        const lblR = outer + 6;
        const lx = CX + lblR * Math.cos(rad);
        const ly = CY + lblR * Math.sin(rad);

        // If the tick is on the left half of the circle, anchor text to the 'end' so it doesn't overlap
        const isLeft = Math.cos(rad) < 0;

        spTick = {
            x1, y1, x2, y2, lx, ly,
            anchor: isLeft ? 'end' : 'start',
            label: setPoint % 1 === 0 ? String(setPoint) : setPoint.toFixed(1)
        };
    }

    return (
        <svg
            width="100%"
            height="100%"
            viewBox={`0 0 ${SIZE} ${SIZE}`}
            className="shrink-0 overflow-visible"
        >
            {/* Background Track */}
            <circle
                cx={CX} cy={CY} r={R}
                fill="none" stroke={trackColor} strokeWidth={STROKE_WIDTH}
                strokeDasharray={`${arcLen} ${circ}`}
                strokeLinecap="round"
                transform={`rotate(${START_ROT} ${CX} ${CY})`}
            />

            {/* Dynamic Value Fill */}
            <circle
                cx={CX} cy={CY} r={R}
                fill="none" stroke={color} strokeWidth={STROKE_WIDTH}
                strokeDasharray={`${fillLen} ${circ}`}
                strokeLinecap="round"
                transform={`rotate(${START_ROT} ${CX} ${CY})`}
                style={{ transition: 'stroke-dasharray 0.6s ease-out, stroke 0.3s ease' }}
            />

            {/* Set-point Tick Marker */}
            {spTick && (
                <g>
                    <line
                        x1={spTick.x1} y1={spTick.y1}
                        x2={spTick.x2} y2={spTick.y2}
                        stroke={spColor} strokeWidth={3} strokeLinecap="round"
                    />
                    <text
                        x={spTick.lx} y={spTick.ly}
                        textAnchor={spTick.anchor}
                        dominantBaseline="central"
                        fill={spColor}
                        fontSize="11"
                        fontWeight="800"
                    >
                        {spTick.label}
                    </text>
                </g>
            )}

            {/* Center Text block */}
            <text x={CX} y={CY - 2} textAnchor="middle" fill={color} fontSize="22" fontWeight="800">
                {pressure.toFixed(1)}
            </text>

            <text x={CX} y={CY + 14} textAnchor="middle" fill="#94a3b8" fontSize="11" fontWeight="600">
                bar
            </text>

            {setPoint != null && (
                <text x={CX} y={CY + 28} textAnchor="middle" fill={spColor} fontSize="9" fontWeight="800">
                    SP {setPoint % 1 === 0 ? setPoint : Number(setPoint).toFixed(1)}
                </text>
            )}
        </svg>
    );
}

// ─── SCADASection ─────────────────────────────────────────────────────────────

export function SCADASection({ device, liveRow }) {
    const t = liveRow ?? device?.telemetry?.[0];
    const { sendCommand } = useDevice();
    const pumpCount = getPumpCount(device?.pumpModel);
    const maxPressure = device?.config?.mxp ?? 8;
    const setPoint = device?.config?.stp ?? null;
    const isFault = (t?.flt ?? 0) > 0;
    const [expanded, setExpanded] = useState(false);
    const [mode, setMode] = useState('auto');
    const [modeSending, setModeSending] = useState(false);
    // Optimistic stop: instantly show all pumps off after manual-stop commands sent.
    // Cleared automatically once live telemetry confirms current is already 0.
    const [stoppedOverride, setStoppedOverride] = useState(false);

    // Clear override once real telemetry confirms all pumps are off
    useEffect(() => {
        if (!stoppedOverride) return;
        const allOff = Array.from({ length: pumpCount }, (_, i) => (t?.[`p${i + 1}s`] ?? 2) === 2).every(Boolean);
        if (allOff) setStoppedOverride(false);
    }, [t, pumpCount, stoppedOverride]);

    // Send each register as a separate MQTT message (device processes one write per message)
    const handleModeChange = useCallback(async (m) => {
        if (m === mode || modeSending) return;
        setMode(m);
        setModeSending(true);
        try {
            if (m === 'manual') {
                // Optimistically zero all pumps in the UI immediately
                setStoppedOverride(true);
                // MOD is one packed register. Manual mode with all pump bits OFF stops VFD/DOL manual channels.
                await sendCommand({ deviceId: device.id, payload: { MOD: 2 } });
            } else {
                // Resume auto mode (MOD bit0 = 1)
                setStoppedOverride(false);
                await sendCommand({ deviceId: device.id, payload: { MOD: 1 } });
            }
        } finally {
            setModeSending(false);
        }
    }, [mode, modeSending, sendCommand, device.id]);

    const pressure = stoppedOverride ? 0 : (t?.prs ?? 0);
    const vfd = stoppedOverride ? 0 : (t?.vfr ?? 0);
    const pumps = Array.from({ length: pumpCount }, (_, i) => {
        const n = i + 1;
        return {
            n,
            label: `Pump ${String(n).padStart(2, '0')}`,
            isRunning: !stoppedOverride && (t?.[`p${n}s`] ?? 2) < 2,
            isFault,
            activeCurrent: stoppedOverride ? 0 : (t?.[`ic${n}`] ?? 0),
            activeFrequency: vfd,
            speed: vfd ? (vfd / 50) * 100 : 0,
            status: stoppedOverride ? 2 : t?.[`p${n}s`], // 2 = Stop
        };
    });

    const runningCount = stoppedOverride ? 0 : Array.from({ length: pumpCount }, (_, i) => t?.[`p${i + 1}s`] ?? 2).filter(s => s < 2).length;

    // Canvas width grows with pump count so pipes never overflow
    const canvasMinWidth = Math.max(1100, 320 + pumpCount * 220);

    return (
        <div className="rounded-2xl shadow-sm border border-slate-200 bg-white overflow-hidden flex flex-col isolate">

            {/* ── Header Toolbar ── */}
            <div className="px-5 py-3.5 border-b border-slate-100 flex items-center justify-between flex-wrap gap-3 shrink-0">
                <div className="flex items-center gap-3">
                    <Radio className="w-4 h-4 text-cyan-500 animate-pulse" />
                    <p className="text-[11px] font-extrabold uppercase tracking-widest text-slate-400">Live System</p>
                    <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${isFault ? 'bg-red-50 text-red-600 border-red-200' : 'bg-emerald-50 text-emerald-600 border-emerald-200'
                        }`}>
                        {isFault ? `FAULT ${t?.flt} \u2013 ${FAULT_DESCRIPTIONS[t?.flt] ?? 'System Error'}` : 'NORMAL'}
                    </span>
                    <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-500 border border-slate-200">
                        {runningCount}/{pumpCount} Running
                    </span>
                </div>
                <div className="flex items-center gap-2">
                    <div className="flex items-center bg-slate-100 rounded-lg p-0.5 gap-0.5 text-[11px] font-bold">
                        {['auto', 'manual'].map((m) => (
                            <button key={m} onClick={() => handleModeChange(m)}
                                disabled={modeSending}
                                className={`px-3 py-1 rounded-md transition-all capitalize flex items-center gap-1.5 disabled:opacity-60 ${mode === m
                                        ? m === 'auto' ? 'bg-white text-slate-700 shadow-sm' : 'bg-amber-500 text-white shadow-sm'
                                        : 'text-slate-500 hover:text-slate-700'
                                    }`}>
                                {modeSending && mode !== m && <RefreshCw className="w-2.5 h-2.5 animate-spin" />}
                                {m}
                            </button>
                        ))}
                    </div>
                    <button onClick={() => setExpanded(v => !v)}
                        className="p-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-500 transition-colors">
                        {expanded ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
                    </button>
                </div>
            </div>

            {/* ── Live Metrics Strip ── */}
            <div className="px-5 py-2.5 border-b border-slate-100 bg-linear-to-r from-slate-50 to-white flex items-center gap-5 flex-wrap shrink-0">
                {/* Mini arc gauge */}
                <div className='h-20 w-20'>
                    <PressureArcGauge pressure={pressure} maxPressure={maxPressure} setPoint={setPoint} />
                </div>

                {/* Readouts */}
                <div className="flex flex-wrap gap-6">
                    {[
                        {
                            label: 'Actual Pressure', unit: 'bar',
                            value: pressure.toFixed(2),
                            color: pressure >= maxPressure * 0.85 ? 'text-red-600' : pressure >= maxPressure * 0.65 ? 'text-amber-600' : 'text-cyan-600',
                        },
                        { label: 'VFD Freq', unit: 'Hz', value: vfd > 0 ? vfd.toFixed(1) : '—', color: 'text-blue-600' },
                        { label: 'Set Pressure', unit: 'bar', value: setPoint != null ? String(setPoint) : '—', color: 'text-orange-500' },
                        { label: 'Max Pressure', unit: 'bar', value: String(maxPressure), color: 'text-slate-600' },
                    ].map(({ label, unit, value, color }) => (
                        <div key={label} className="flex flex-col justify-center">
                            <span className="text-[9px] font-bold uppercase tracking-widest text-slate-400 leading-none mb-0.5">{label}</span>
                            <span className={`text-base font-mono font-bold leading-none ${color}`}>{value}
                                <span className="text-[10px] font-normal text-slate-400 ml-0.5">{unit}</span>
                            </span>
                        </div>
                    ))}
                </div>

                {/* Pump status dots */}
                <div className="ml-auto flex items-center gap-3 shrink-0">
                    <span className="text-[9px] font-bold uppercase tracking-widest text-slate-400">Pumps</span>
                    <div className="flex items-center gap-2">
                        {Array.from({ length: 5 }, (_, i) => {
                            const n = i + 1;
                            const active = n <= pumpCount;
                            const status = t?.[`p${n}s`];
                            const cfg = active && status != null && PUMP_STATUS[status] ? PUMP_STATUS[status] : null;
                            return (
                                <div key={n} className="flex flex-col items-center gap-0.5">
                                    <div className={`w-4 h-4 rounded-full border-2 transition-all duration-300 ${!active ? 'bg-slate-100 border-slate-200 opacity-30'
                                            : cfg ? `${cfg.dot} border-white shadow-sm`
                                                : 'bg-slate-300 border-slate-200'
                                        }`} />
                                    <span className="text-[8px] text-slate-400 font-mono">P{n}</span>
                                </div>
                            );
                        })}
                    </div>
                </div>
            </div>

            {/* ── SCADA Canvas ── */}
            <div className={`p-4 overflow-x-auto transition-all duration-300 ease-in-out ${expanded ? 'h-160' : 'h-150'}`}>
                <div
                    className="relative h-full rounded-xl border border-slate-200/80 overflow-hidden bg-linear-to-br from-slate-50 via-white to-sky-50/30 shadow-[inset_0_2px_14px_rgba(0,0,0,0.03)]"
                    style={{ minWidth: `${canvasMinWidth}px` }}
                >
                    {/* Engineering grid */}
                    <div className="absolute inset-0 z-0 pointer-events-none opacity-[0.18] bg-[linear-gradient(to_right,#94a3b8_1px,transparent_1px),linear-gradient(to_bottom,#94a3b8_1px,transparent_1px)] bg-size-[2rem_2rem]" />

                    {/* Canvas watermark */}
                    <span className="absolute bottom-3 left-4 z-0 pointer-events-none text-[9px] font-mono font-bold text-slate-200 uppercase tracking-widest select-none">
                        I Series Booster Panel
                    </span>

                    {/* System health chip — top-right */}
                    <div className={`absolute top-3 right-3 z-40 flex items-center gap-1.5 px-2.5 py-1 rounded-full border text-[10px] font-bold shadow-sm ${isFault ? 'bg-red-50 border-red-200 text-red-600'
                            : runningCount > 0 ? 'bg-emerald-50 border-emerald-200 text-emerald-600'
                                : 'bg-slate-50 border-slate-200 text-slate-400'
                        }`}>
                        <div className={`w-2 h-2 rounded-full animate-pulse ${isFault ? 'bg-red-500' : runningCount > 0 ? 'bg-emerald-500' : 'bg-slate-300'
                            }`} />
                        {isFault ? 'FAULT' : runningCount > 0 ? 'FLOWING' : 'STANDBY'}
                    </div>

                    {/* Mode chip — top-right (left of health chip) */}
                    <div className={`absolute top-3 right-28 z-40 flex items-center gap-1 px-2.5 py-1 rounded-full border text-[10px] font-bold shadow-sm ${mode === 'auto'
                            ? 'bg-cyan-50 border-cyan-200 text-cyan-700'
                            : 'bg-amber-50 border-amber-200 text-amber-700'
                        }`}>
                        {mode === 'auto' ? 'AUTO' : 'MANUAL'}
                    </div>

                    {/* ─ Pressure Vessel ─ */}
                    <div className="absolute z-30 flex flex-col items-center w-60" style={{ left: 24, top: 36 }}>
                        {/*  <p className="text-[9px] font-bold text-slate-400 uppercase tracking-widest mb-3 text-center">
                            Pressure Vessel
                        </p> */}
                        <Tank
                            pressure={pressure}
                            maxPressure={maxPressure}
                            setPoint={setPoint}
                            label=""
                            isFault={isFault}
                        />
                    </div>

                    {/* ─ Stub pipe: vessel → manifold ─ 
                    <div className="absolute z-10" style={{ left: 128, top: 185 }}>
                        <Pipe length={62} active={runningCount > 0} />
                    </div>

                    {/* ─ Tank → manifold T-junction ─ 
                    <PipeJoint active={runningCount > 0} style={{ left: 190, top: 185 }} />

                    {/* ─ Main vertical manifold ─  
                    <div className="absolute z-10" style={{ left: 190, top: 185 }}>
                        <Pipe vertical length={Math.max(0, (pumps.length - 1) * 80)} active={runningCount > 0} />
                    </div>

                    {/* ─ Pumps ─ */}
                    {pumps.map((pump, idx) => {
                        const isFlowing = pump.isRunning && !pump.isFault;
                        const pumpLeft = 310 + idx * 220;
                        const pipeLeft = pumpLeft + 60;
                        const branchTop = 185 + idx * 80;
                        const horizLen = pipeLeft - 190;
                        const vertLen = branchTop - 166 + 24;

                        return (
                            <React.Fragment key={pump.n}>
                                {/* Branch T-junction on manifold (skip first — shares tank junction)  
                                {idx > 0 && <PipeJoint active={runningCount > 0} style={{ left: 190, top: branchTop }} />}

                                {/* Horizontal branch pipe
                                <div className="absolute z-10" style={{ left: 190, top: branchTop }}>
                                    <Pipe length={horizLen} active={isFlowing} />
                                </div>

                                {/* Elbow junction turning up  
                                <PipeJoint active={isFlowing} style={{ left: pipeLeft, top: branchTop }} />

                                {/* Vertical riser into pump 
                                <div className="absolute z-10" style={{ left: pipeLeft, top: 166 }}>
                                    <Pipe vertical length={vertLen} active={isFlowing} />
                                </div>

                                {/* Pump card */}
                                <div className="absolute z-30" style={{ left: pumpLeft, top: 36 }}>
                                    <Pump
                                        idx={pump.n}
                                        label={idx !== pumps.length - 1 ? `Working pump` : `Assist pump`}
                                        isRunning={pump.isRunning}
                                        isFault={pump.isFault}
                                        speed={pump.speed}
                                        activeCurrent={pump.activeCurrent}
                                        activeFrequency={pump.activeFrequency}
                                        operationalMode={mode}
                                        togglePump={() => sendCommand({
                                            deviceId: device.id,
                                            payload: { [`P${pump.n}V`]: pump.isRunning ? 0 : 1 },
                                        })}
                                    />
                                    {pump.status != null && PUMP_STATUS[pump.status] && (
                                        <div className={`mt-2 mx-auto min-w-36 w-fit px-2 py-0.5 rounded-md text-[11px] sfont-bold uppercase tracking-wider border shadow-sm ${PUMP_STATUS[pump.status].bg} ${PUMP_STATUS[pump.status].color}`}>
                                            <span className="text-[11px] stext-slate-400 px-2">Pump model</span> {/*  {PUMP_STATUS[pump.status].label} */} <span className="text-[11px] stext-slate-400 px-2">MVS 3/19</span>
                                        </div>
                                    )}
                                    {/* power rating */}
                                    <div className={`mt-1 mx-auto min-w-36 w-fit px-2 py-0.5 rounded-md text-[11px] sfont-bold text-slate-600 border border-slate-200`}>
                                        <span className="text-[11px] stext-slate-400 px-2 uppercase">Power rating</span><span className="text-[11px] stext-slate-400 px-2">1.5<span className='normal-case px-2'>kW</span></span>
                                    </div>
                                </div>
                            </React.Fragment>
                        );
                    })}
                </div>
            </div>

            {/* ── Bottom Legend Bar ── */}
            <div className="px-5 py-2 border-t border-slate-100 bg-slate-50/60 flex items-center flex-wrap gap-5 shrink-0">
                {/* Status legend */}
                <div className="flex items-center gap-4">
                    <span className="text-[9px] font-bold uppercase tracking-widest text-slate-400 mr-1">Pump</span>
                    {Object.entries(PUMP_STATUS).map(([key, cfg]) => (
                        <div key={key} className="flex items-center gap-1.5">
                            <div className={`w-2.5 h-2.5 rounded-full ${cfg.dot}`} />
                            <span className={`text-[10px] font-bold ${cfg.color}`}>{cfg.label}</span>
                        </div>
                    ))}
                </div>

                {/* Pipe legend */}
                <div className="flex items-center gap-3">
                    <span className="text-[9px] font-bold uppercase tracking-widest text-slate-400 mr-1">Pipe</span>
                    <div className="flex items-center gap-1.5">
                        <div className="w-8 h-3.5 rounded-sm bg-cyan-50 border border-cyan-200 overflow-hidden relative">
                            <div className="absolute inset-0 bg-cyan-400/25" />
                        </div>
                        <span className="text-[10px] text-slate-500">Active</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                        <div className="w-8 h-3.5 rounded-sm bg-slate-100 border border-slate-300" />
                        <span className="text-[10px] text-slate-400">No Flow</span>
                    </div>
                </div>

                {/* Last update */}
                {t?.timestamp && (
                    <div className="ml-auto text-[9px] text-slate-400 font-mono">
                        Updated: {new Date(t.timestamp).toLocaleTimeString('en-GB')}
                    </div>
                )}
            </div>
        </div>
    );
}
// ─── ISeriesPanel ─────────────────────────────────────────────────────────────

function ToggleSwitch({ active, onToggle, color = 'bg-cyan-500' }) {
    return (
        <button onClick={onToggle}
            className={`relative inline-flex h-5 w-9 shrink-0 items-center rounded-full transition-colors ${active ? color : 'bg-slate-200'}`}>
            <span className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow transition-transform ${active ? 'translate-x-5' : 'translate-x-0.5'}`} />
        </button>
    );
}

function VFDToggleRow({ n, pumpCount, mod, onModChange }) {
    const enabled = n <= pumpCount;
    const on = !!(mod & (1 << (2 + n - 1))); // bit 2+(n-1)
    return (
        <div className={`flex items-center justify-between px-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50 ${!enabled ? 'opacity-40' : ''}`}>
            <span className="text-sm text-slate-600">Pump {n} VFD Manual</span>
            <ToggleSwitch active={on} color="bg-cyan-500"
                onToggle={enabled ? () => onModChange(n, 'vfd', !on) : undefined} />
        </div>
    );
}

function DOLToggleRow({ n, pumpCount, mod, onModChange }) {
    const enabled = n <= pumpCount;
    const on = !!(mod & (1 << (7 + n - 1))); // bit 7+(n-1)
    return (
        <div className={`flex items-center justify-between px-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50 ${!enabled ? 'opacity-40' : ''}`}>
            <span className="text-sm text-slate-600">Pump {n} DOL Manual</span>
            <ToggleSwitch active={on} color="bg-green-500"
                onToggle={enabled ? () => onModChange(n, 'dol', !on) : undefined} />
        </div>
    );
}

function ServiceToggleRow({ n, pumpCount, psm, onPsmChange }) {
    const enabled = n <= pumpCount;
    const on = !!(psm & (1 << (n - 1))); // bit n-1
    return (
        <div className={`flex items-center justify-between px-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50 ${!enabled ? 'opacity-40' : ''}`}>
            <span className="text-sm text-slate-600">Pump {n} Service Mode</span>
            <ToggleSwitch active={on} color="bg-amber-500"
                onToggle={enabled ? () => onPsmChange(n, !on) : undefined} />
        </div>
    );
}

function AmoMmoRow({ label, bitIndex, mod, onModChange, color }) {
    const on = !!(mod & (1 << bitIndex));
    return (
        <div className="flex items-center justify-between px-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50">
            <span className="text-sm text-slate-600">{label}</span>
            <ToggleSwitch active={on} color={color}
                onToggle={() => onModChange(null, bitIndex === 0 ? 'amo' : 'mmo', !on)} />
        </div>
    );
}

function ISeriesPanel({ device, t, onOpenConfig }) {
    const { sendCommand, saveDeviceConfig } = useDevice();
    const [activeTab, setActiveTab] = useState('status');
    const [resetFlash, setResetFlash] = useState({});
    const [cfgDraft, setCfgDraft] = useState(() => {
        const d = {};
        CONFIG_FIELDS.forEach(({ key }) => { d[key] = device?.config?.[key] ?? ''; });
        return d;
    });
    const [savingCfg, setSavingCfg] = useState(false);
    const pumpCount = getPumpCount(device?.pumpModel);

    // Packed register state for bit controls
    const [mod, setMod] = useState(device?.state?.mod ?? 1); // bit0=AMO default
    const [psm, setPsm] = useState(device?.state?.psm ?? 0);
    const [pml, setPml] = useState(device?.state?.pml ?? 0);
    const setBitFn = (val, bit, on) => on ? (val | (1 << bit)) : (val & ~(1 << bit));

    const handleModChange = async (n, type, on) => {
        let bitIdx;
        if (type === 'amo') bitIdx = 0;
        else if (type === 'mmo') bitIdx = 1;
        else if (type === 'vfd') bitIdx = 2 + (n - 1);
        else if (type === 'dol') bitIdx = 7 + (n - 1);

        let next = setBitFn(mod, bitIdx, on);
        // AMO/MMO mutually exclusive
        if (type === 'amo' && on) next = setBitFn(next, 1, false);
        if (type === 'mmo' && on) next = setBitFn(next, 0, false);
        setMod(next);
        sendCommand({ deviceId: device.id, payload: { MOD: next } });
        toast.success(`MOD → ${next}`);
    };

    const handlePsmChange = async (n, on) => {
        const next = setBitFn(psm, n - 1, on);
        setPsm(next);
        sendCommand({ deviceId: device.id, payload: { PSM: next } });
        toast.success(`PSM → ${next}`);
    };

    const handlePmlChange = async (value) => {
        setPml(value);
        await sendCommand({ deviceId: device.id, payload: { PML: value } });
        toast.success(`PML → ${value}`);
    };

    const triggerReset = (n) => {
        const prrVal = 1 << (n - 1);
        sendCommand({ deviceId: device.id, payload: { PRR: prrVal } });
        setResetFlash(p => ({ ...p, [n]: true }));
        setTimeout(() => {
            sendCommand({ deviceId: device.id, payload: { PRR: 0 } });
            setResetFlash(p => ({ ...p, [n]: false }));
        }, 1200);
    };

    const handleApplyConfig = async () => {
        setSavingCfg(true);
        const cfg = {};
        CONFIG_FIELDS.forEach(({ key }) => {
            const v = cfgDraft[key];
            if (v !== '' && v != null) cfg[key] = Number(v);
        });
        const result = await saveDeviceConfig({ deviceId: device.id, cfg });
        setSavingCfg(false);
        if (result.error) toast.error('Failed to save config');
        else toast.success('Config saved');
    };

    const tabs = [
        { id: 'status', label: 'Pump Status' },
        { id: 'controls', label: 'Bit Controls' },
        { id: 'settings', label: 'Settings' },
    ];

    return (
        <div className="rounded-2xl shadow-sm border border-slate-200 bg-white overflow-hidden">
            <div className="flex items-center gap-0.5 px-5 pt-4 border-b border-slate-100">
                <div className="flex items-center gap-2 mr-4">
                    <Gauge className="w-4 h-4 text-slate-400" />
                    <p className="text-[10px] font-extrabold uppercase tracking-widest text-slate-400">I Series Control</p>
                </div>
                {tabs.map(({ id, label }) => (
                    <button key={id} onClick={() => setActiveTab(id)}
                        className={`px-4 py-2 text-xs font-bold rounded-t-lg border-b-2 transition-colors -mb-px ${activeTab === id ? 'border-cyan-500 text-cyan-600 bg-cyan-50' : 'border-transparent text-slate-400 hover:text-slate-600'}`}>
                        {label}
                    </button>
                ))}
            </div>

            <div className="p-5">

                {/* ── PUMP STATUS ── */}
                {activeTab === 'status' && (
                    <div className="space-y-5">
                        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
                            {Array.from({ length: 5 }, (_, i) => {
                                const n = i + 1;
                                const status = t?.[`p${n}s`] ?? 2;
                                const cfg = PUMP_STATUS[status] ?? PUMP_STATUS[2];
                                const active = n <= pumpCount;
                                return (
                                    <div key={n} className={`rounded-2xl p-4 border transition-all ${active ? cfg.bg : 'bg-slate-50 border-slate-200 opacity-40'}`}>
                                        <div className="flex items-center justify-between mb-2">
                                            <span className="text-xs font-mono text-slate-400 uppercase">Pump {n}</span>
                                            <div className={`w-2.5 h-2.5 rounded-full animate-pulse ${active ? cfg.dot : 'bg-slate-300'}`} />
                                        </div>
                                        <div className={`text-base font-bold font-mono ${active ? cfg.color : 'text-slate-400'}`}>{cfg.label}</div>
                                        <div className="mt-3 pt-3 border-t border-black/5 space-y-1">
                                            <div className="flex justify-between text-[10px]">
                                                <span className="text-slate-400">Run Mins</span>
                                                <span className="font-mono font-semibold text-slate-700">{(t?.[`p${n}r`] ?? 0).toLocaleString()}</span>
                                            </div>
                                            <div className="flex justify-between text-[10px]">
                                                <span className="text-slate-400">Starts/hr</span>
                                                <span className="font-mono font-semibold text-slate-700">{t?.[`s${n}h`] ?? 0}</span>
                                            </div>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                        {(t?.flt ?? 0) > 0 && (
                            <div className="flex items-center gap-3 px-4 py-3 rounded-xl bg-red-50 border border-red-200">
                                <AlertTriangle className="w-5 h-5 text-red-500 shrink-0" />
                                <div>
                                    <p className="text-xs font-bold text-red-600">Active Fault \u2014 Code {t.flt}</p>
                                    <p className="text-xs text-red-500">{FAULT_DESCRIPTIONS[t.flt] ?? 'Unknown fault'}</p>
                                </div>
                            </div>
                        )}
                    </div>
                )}

                {/* ── BIT CONTROLS ── */}
                {activeTab === 'controls' && (
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        <div>
                            <p className="text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-3">Operating Mode</p>
                            <div className="space-y-2">
                                <AmoMmoRow label="Auto Mode ON/OFF" bitIndex={0} mod={mod} onModChange={handleModChange} color="bg-cyan-500" />
                                <AmoMmoRow label="Manual Mode ON/OFF" bitIndex={1} mod={mod} onModChange={handleModChange} color="bg-blue-500" />
                            </div>
                        </div>

                        <div>
                            <p className="text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-3">VFD Manual Mode</p>
                            <div className="space-y-2">
                                {[1, 2, 3, 4, 5].map(n => <VFDToggleRow key={n} n={n} pumpCount={pumpCount} mod={mod} onModChange={handleModChange} />)}
                            </div>
                        </div>

                        <div>
                            <p className="text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-3">DOL Manual Mode</p>
                            <div className="space-y-2">
                                {[1, 2, 3, 4, 5].map(n => <DOLToggleRow key={n} n={n} pumpCount={pumpCount} mod={mod} onModChange={handleModChange} />)}
                            </div>
                        </div>

                        <div>
                            <p className="text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-3">Service Mode</p>
                            <div className="space-y-2">
                                {[1, 2, 3, 4, 5].map(n => <ServiceToggleRow key={n} n={n} pumpCount={pumpCount} psm={psm} onPsmChange={handlePsmChange} />)}
                            </div>
                        </div>

                        <div className="lg:col-span-2">
                            <p className="text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-3">Pump Model Register (PML)</p>
                            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                                {[
                                    { label: '1+1 / 2 Pump', value: 1 },
                                    { label: '2+1 / 3 Pump', value: 2 },
                                    { label: '3+1 / 4 Pump', value: 4 },
                                    { label: '4+1 / 5 Pump', value: 8 },
                                ].map(({ label, value }) => (
                                    <button
                                        key={value}
                                        onClick={() => handlePmlChange(value)}
                                        className={`py-2 rounded-xl border text-xs font-bold transition-all ${pml === value ? 'bg-violet-500 text-white border-violet-500' : 'bg-violet-50 border-violet-200 text-violet-600 hover:bg-violet-100'}`}
                                    >
                                        {label}
                                    </button>
                                ))}
                            </div>
                        </div>

                        <div className="lg:col-span-2">
                            <p className="text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-3">Run Minutes Reset</p>
                            <div className="grid grid-cols-2 sm:grid-cols-5 gap-2">
                                {[1, 2, 3, 4, 5].map(n => {
                                    const enabled = n <= pumpCount;
                                    const flashing = resetFlash[n];
                                    return (
                                        <button key={n} onClick={enabled ? () => triggerReset(n) : undefined}
                                            className={`py-2 rounded-xl border text-xs font-bold transition-all ${!enabled ? 'opacity-40 cursor-default border-slate-200 text-slate-400' : flashing ? 'bg-red-500 text-white border-red-500 scale-95' : 'bg-red-50 border-red-200 text-red-600 hover:bg-red-500 hover:text-white'}`}>
                                            <RotateCcw className="w-3 h-3 inline mr-1" />
                                            {flashing ? 'RESET!' : `P${n} Reset`}
                                        </button>
                                    );
                                })}
                            </div>
                        </div>
                    </div>
                )}

                {/* ── SETTINGS ── */}
                {activeTab === 'settings' && (
                    <div>
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                            {CONFIG_FIELDS.map(({ key, label, unit, code }) => (
                                <div key={key} className="rounded-xl border border-slate-200 bg-slate-50 p-3">
                                    <label className="text-[10px] text-slate-400 uppercase tracking-widest mb-1 block">
                                        {label}
                                        <span className="ml-1 text-slate-300 font-mono">({code})</span>
                                    </label>
                                    <div className="flex items-center gap-1.5">
                                        <input type="number" value={cfgDraft[key] ?? ''}
                                            onChange={(e) => setCfgDraft(p => ({ ...p, [key]: e.target.value }))}
                                            className="flex-1 min-w-0 bg-white border border-slate-200 rounded-lg px-2.5 py-1.5 text-sm font-mono focus:outline-none focus:ring-1 focus:ring-cyan-400" />
                                        {unit && <span className="text-[10px] text-slate-400 whitespace-nowrap">{unit}</span>}
                                    </div>
                                </div>
                            ))}
                        </div>
                        <div className="mt-4 flex items-center gap-3 justify-end">
                            <button onClick={onOpenConfig}
                                className="px-4 py-2 text-xs font-semibold text-slate-600 border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors">
                                Open Full Config
                            </button>
                            <button onClick={handleApplyConfig} disabled={savingCfg}
                                className="px-5 py-2 rounded-xl bg-cyan-500 hover:bg-cyan-600 disabled:opacity-50 text-white text-sm font-semibold flex items-center gap-2 transition-colors">
                                {savingCfg ? <RefreshCw className="w-3.5 h-3.5 animate-spin" /> : <CheckCircle2 className="w-3.5 h-3.5" />}
                                {savingCfg ? 'Saving…' : 'Apply Settings'}
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}

// ─── TelemetrySection ─────────────────────────────────────────────────────────

function TelemetrySection({ device }) {
    const { loadTelemetry, telemetryLoading } = useDevice();
    const [open, setOpen] = useState(false);
    const [rows, setRows] = useState([]);
    const [liveRows, setLiveRows] = useState([]);
    const [hasMore, setHasMore] = useState(true);
    const loaderRef = useRef(null);
    const pageRef = useRef(0);      // mutable — avoids observer re-creation
    const fetchingRef = useRef(false);  // guard against concurrent requests
    const [from, setFrom] = useState(() => new Date(Date.now() - 86400000).toISOString().split('T')[0]);
    const [to, setTo] = useState(() => new Date().toISOString().split('T')[0]);

    useDeviceSocket(device?.id, useCallback((row) => {
        setLiveRows(prev => [row, ...prev].slice(0, 200));
    }, []));

    const fetchPage = useCallback(async (pageNum, reset = false) => {
        if (fetchingRef.current) return;
        fetchingRef.current = true;
        try {
            const result = await loadTelemetry({
                deviceId: device.id,
                from: `${from}T00:00:00`, to: `${to}T23:59:59`,
                skip: pageNum * PAGE_SIZE, take: PAGE_SIZE,
            });
            const fetched = result?.payload ?? [];
            if (reset) setRows(fetched); else setRows(p => [...p, ...fetched]);
            setHasMore(fetched.length >= PAGE_SIZE);
        } finally {
            fetchingRef.current = false;
        }
    }, [device.id, from, to, loadTelemetry]);

    // Always expose the latest fetchPage to the observer without re-creating it
    const fetchPageRef = useRef(fetchPage);
    useEffect(() => { fetchPageRef.current = fetchPage; }, [fetchPage]);

    // Infinite scroll — only recreated when open/hasMore changes, never on every fetch
    useEffect(() => {
        if (!open || !hasMore) return;
        const el = loaderRef.current;
        if (!el) return;
        const obs = new IntersectionObserver(([entry]) => {
            if (entry.isIntersecting && !fetchingRef.current) {
                const next = pageRef.current + 1;
                pageRef.current = next;
                fetchPageRef.current(next);
            }
        }, { threshold: 0.1 });
        obs.observe(el);
        return () => obs.disconnect();
    }, [open, hasMore]);

    const allRows = [...liveRows, ...rows];

    const handleExcel = () => {
        if (!allRows.length) return;
        const data = allRows.map(row => {
            const out = {};
            TELEMETRY_COLUMNS.forEach(({ key, label, format }) => { out[label] = format(row[key]); });
            return out;
        });
        const ws = XLSX.utils.json_to_sheet(data);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Telemetry');
        XLSX.writeFile(wb, `telemetry_${device.imeinumber}_${from}_${to}.xlsx`);
    };

    return (
        <div className="rounded-2xl shadow-sm border border-slate-200 bg-white overflow-hidden">
            <button onClick={() => {
                setOpen(v => !v);
                if (!open && rows.length === 0) { pageRef.current = 0; fetchPage(0, true); }
            }} className="w-full px-5 py-4 flex items-center justify-between hover:bg-slate-50 transition-colors">
                <div className="flex items-center gap-2">
                    <Activity className="w-4 h-4 text-slate-400" />
                    <p className="text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Telemetry Log</p>
                    {liveRows.length > 0 && (
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-50 text-blue-600 border border-blue-200">
                            {liveRows.length} live
                        </span>
                    )}
                </div>
                {open ? <ChevronUp className="w-4 h-4 text-slate-400" /> : <ChevronDown className="w-4 h-4 text-slate-400" />}
            </button>

            <AnimatePresence>
                {open && (
                    <motion.div initial={{ height: 0 }} animate={{ height: 'auto' }} exit={{ height: 0 }} className="overflow-hidden">
                        <div className="px-5 pb-3 flex flex-wrap items-center gap-3 border-t border-slate-100 pt-3">
                            <div className="flex items-center gap-2">
                                <label className="text-[10px] font-bold uppercase text-slate-400">From</label>
                                <input type="date" value={from} onChange={e => setFrom(e.target.value)}
                                    className="text-xs border rounded-lg px-2 py-1.5 bg-slate-50 text-slate-700 focus:outline-none" />
                            </div>
                            <div className="flex items-center gap-2">
                                <label className="text-[10px] font-bold uppercase text-slate-400">To</label>
                                <input type="date" value={to} onChange={e => setTo(e.target.value)}
                                    className="text-xs border rounded-lg px-2 py-1.5 bg-slate-50 text-slate-700 focus:outline-none" />
                            </div>
                            <button onClick={() => { pageRef.current = 0; setRows([]); setHasMore(true); fetchPage(0, true); }}
                                disabled={telemetryLoading}
                                className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-900 text-white text-xs font-semibold rounded-lg disabled:opacity-40">
                                <RefreshCw className={`w-3 h-3 ${telemetryLoading ? 'animate-spin' : ''}`} /> Load
                            </button>
                            <button onClick={handleExcel} disabled={!allRows.length}
                                className="ml-auto flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 text-white text-xs font-semibold rounded-lg disabled:opacity-40">
                                <Download className="w-3 h-3" /> Excel
                            </button>
                        </div>

                        <div className="overflow-x-auto max-h-100 overflow-y-auto">
                            {allRows.length === 0 && !telemetryLoading ? (
                                <div className="flex flex-col items-center py-10 text-slate-300 gap-2">
                                    <Activity className="w-6 h-6 opacity-40" />
                                    <p className="text-sm">No data for this range</p>
                                </div>
                            ) : (
                                <table className="w-full text-left whitespace-nowrap">
                                    <thead className="bg-slate-50 border-y border-slate-200 text-[9px] uppercase tracking-wider text-slate-400 sticky top-0">
                                        <tr>{TELEMETRY_COLUMNS.map(({ label }) => <th key={label} className="px-3 py-2 font-bold">{label}</th>)}</tr>
                                    </thead>
                                    <tbody className="divide-y divide-slate-100">
                                        {allRows.map((row, i) => (
                                            <tr key={`${row.timestamp}-${i}`} className="hover:bg-slate-50 transition-colors">
                                                {TELEMETRY_COLUMNS.map(({ key, format }) => (
                                                    <td key={key} className="px-3 py-1.5 font-mono text-slate-600 text-xs">{format(row[key])}</td>
                                                ))}
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            )}
                            {hasMore && (
                                <div ref={loaderRef} className="flex justify-center py-3">
                                    {telemetryLoading && <RefreshCw className="w-4 h-4 animate-spin text-slate-300" />}
                                </div>
                            )}
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function DeviceDetailPage() {
    const { id } = useParams();
    const navigate = useNavigate();
    const dispatch = useDispatch();
    const { device, loading } = useSelector(s => s.devices);
    const socketCtx = useSocket();
    const connected = socketCtx?.connected;
    const [liveRow, setLiveRow] = useState(null);
    const [showCmd, setShowCmd] = useState(false);
    const [showConfig, setShowConfig] = useState(false);
    const [livePressure, setLivePressure] = useState([]);

    useEffect(() => { dispatch(fetchDeviceById(id)); }, [id, dispatch]);

    useDeviceSocket(id, useCallback((row) => {
        setLiveRow(row);
        if (row?.prs != null) {
            setLivePressure(prev => [
                ...prev.slice(-(MAX_LIVE_PTS - 1)),
                { time: fmtTime(row.timestamp), prs: Number(Number(row.prs).toFixed(2)) },
            ]);
        }
    }, []));

    const t = liveRow ?? device?.telemetry?.[0];
    const isOnline = device?.lastStatus === 'ONLINE' || !!liveRow;
    const hasFault = (t?.flt ?? 0) > 0;

    if (loading && !device) {
        return (
            <div className="flex items-center justify-center min-h-[60vh] text-slate-400">
                <Activity className="w-6 h-6 animate-spin mr-2" /> Loading device…
            </div>
        );
    }

    if (!device) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh] text-slate-400 gap-3">
                <Cpu className="w-10 h-10 opacity-30" />
                <p className="font-medium">Device not found</p>
                <button onClick={() => navigate('/devices')} className="text-sm text-blue-600 hover:underline">
                    Back to devices
                </button>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-slate-50">

            {/* Sticky top bar */}
            <motion.div initial={{ y: -80 }} animate={{ y: 0 }}
                className="sticky top-0 z-50 backdrop-blur-xl bg-white/95 border-b border-slate-200 shadow-sm">
                <div className="px-4 md:px-8 py-3 flex items-center justify-between gap-4 flex-wrap">
                    <div className="flex items-center gap-3">
                        <button onClick={() => navigate('/devices')}
                            className="p-2 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-500 transition-colors">
                            <ArrowLeft className="w-4 h-4" />
                        </button>
                        <div>
                            <h1 className="text-base font-bold text-slate-800">{device.name || device.code || device.imeinumber}</h1>
                            <p className="text-[11px] text-slate-400 font-mono font-medium">
                                IMEI : {device.imeinumber}
                                {/* {device.customer?.name ? ` \u00b7 ${device.customer.name} \u00b7 Fludyn Advanced Technology centre` : ''} */}
                            </p>
                            <p className="text-[11px] text-slate-400 font-mono font-medium">
                                GPS Location : {`Fludyn Advanced Technology centre (Unit of CRI Pumps)`}
                            </p>
                        </div>
                    </div>

                    <div className="flex items-center gap-2 flex-wrap">
                        <span className={`flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold border ${isOnline ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : 'bg-slate-50 text-slate-500 border-slate-200'}`}>
                            {isOnline ? (
                                <><span className="relative flex h-2 w-2"><span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" /><span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500" /></span>Online</>
                            ) : (
                                <><WifiOff className="w-3 h-3" />Offline</>
                            )}
                        </span>

                        {connected && (
                            <span className="flex items-center gap-1 px-2 py-1 rounded-full text-[10px] font-bold bg-blue-50 text-blue-700 border border-blue-200">
                                <Radio className="w-2.5 h-2.5" /> Live
                            </span>
                        )}

                        <motion.span animate={hasFault ? { scale: [1, 1.05, 1] } : {}} transition={{ repeat: Infinity, duration: 2 }}
                            className={`flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold border ${hasFault ? 'bg-red-50 text-red-600 border-red-200' : 'bg-slate-50 text-slate-400 border-slate-200'}`}>
                            {hasFault ? <AlertTriangle className="w-3 h-3" /> : <CheckCircle2 className="w-3 h-3" />}
                            {hasFault ? `FAULT ${t?.flt}` : 'No Fault'}
                        </motion.span>

                        <button onClick={() => setShowCmd(true)}
                            className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-violet-600 hover:bg-violet-700 text-white transition-colors">
                            <Terminal className="w-3.5 h-3.5" /> Commands
                        </button>
                        <button onClick={() => setShowConfig(true)}
                            className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-emerald-600 hover:bg-emerald-700 text-white transition-colors">
                            <Settings className="w-3.5 h-3.5" /> Config
                        </button>
                    </div>
                </div>
            </motion.div>

            {/* Page body */}
            <div className="px-4 md:px-8 py-6 space-y-5 max-w-400 mx-auto">

                {/* Fault banner */}
                <AnimatePresence>
                    {hasFault && (
                        <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}
                            className="flex items-center gap-3 px-5 py-3 rounded-2xl bg-red-50 border border-red-200">
                            <AlertTriangle className="w-5 h-5 text-red-500 shrink-0" />
                            <div>
                                <p className="text-sm font-bold text-red-700">Fault Active \u2014 Code {t?.flt}</p>
                                <p className="text-xs text-red-500">{FAULT_DESCRIPTIONS[t?.flt] ?? 'Unknown fault'}</p>
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>

                {/* SCADA */}
                <SCADASection device={device} liveRow={liveRow} />

                {/* 4-col metrics */}
                <div className="grid grid-cols-1 lg:grid-cols-4 gap-5">
                    <div className="lg:col-span-1">
                        <InputPowerPanel t={t} />
                    </div>
                    <div className="lg:col-span-2 flex flex-col gap-5">
                        <LivePressureChart data={livePressure} />
                        <PressureHistoryChart device={device} />
                    </div>
                    <div className="lg:col-span-1">
                        <CommandEditorPanel device={device} />
                    </div>
                </div>

                {/* I Series control — key=device.id forces remount when device loads */}
                <ISeriesPanel key={device.id} device={device} t={t} onOpenConfig={() => setShowConfig(true)} />

                {/* Telemetry log */}
                <TelemetrySection device={device} />
            </div>

            {/* Modals */}
            <AnimatePresence>
                {showCmd && <CommandModal device={device} onClose={() => setShowCmd(false)} />}
                {showConfig && <DeviceConfigModal device={device} onClose={() => setShowConfig(false)} />}
            </AnimatePresence>
        </div>
    );
}

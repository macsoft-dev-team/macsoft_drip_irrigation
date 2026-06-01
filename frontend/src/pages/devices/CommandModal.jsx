// src/pages/devices/CommandModal.jsx
import React, { useState, useEffect } from 'react';
import { Terminal, Send, RefreshCw, CheckCircle, XCircle, Clock, Loader } from 'lucide-react';
import toast from 'react-hot-toast';
import { useDevice } from '../../hooks/useDevice';
import RightDrawer from '../../components/RightDrawer';

// ---- STS Fault code map (bitmask) ----
export const STS_FAULTS = [
    { bit: 0, label: 'Phase Fault', color: 'red' },
    { bit: 1, label: 'Overcurrent', color: 'orange' },
    { bit: 2, label: 'Overvoltage', color: 'amber' },
    { bit: 3, label: 'Undervoltage', color: 'yellow' },
];

export function getFaults(sts) {
    if (!sts || sts === 0) return [];
    return STS_FAULTS.filter(({ bit }) => (sts >> bit) & 1);
}

// ---- Pre-built command templates (unused — single textarea mode) ----
const STATUS_UI = {
    PENDING: { icon: Clock, color: 'text-slate-400', bg: 'bg-slate-50 border-slate-200', label: 'Pending' },
    SENT: { icon: Loader, color: 'text-blue-500', bg: 'bg-blue-50 border-blue-200', label: 'Sent' },
    ACK: { icon: CheckCircle, color: 'text-emerald-600', bg: 'bg-emerald-50 border-emerald-200', label: 'ACK' },
    FAILED: { icon: XCircle, color: 'text-red-500', bg: 'bg-red-50 border-red-200', label: 'Failed' },
};

const COMMAND_EXAMPLES = [
    { label: 'AUTO', payload: { MOD: 1 }, hint: 'MOD bit0' },
    { label: 'MANUAL', payload: { MOD: 2 }, hint: 'MOD bit1' },
    { label: 'P1 Reset', payload: { PRR: 1 }, hint: 'PRR bit0 pulse' },
    { label: 'P1 Service', payload: { PSM: 1 }, hint: 'PSM bit0' }, 
    { label: 'High Volt', payload: { HVG: 440 }, hint: 'normal decimal' },
];

const validateCommandPayload = (payload) => {
    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
        return 'Payload must be a JSON object';
    }
    const keys = Object.keys(payload);
    if (keys.length !== 1) {
        return 'Send only one command per payload';
    }
    return null;
};

function StatusBadge({ status }) {
    const ui = STATUS_UI[status] ?? STATUS_UI.PENDING;
    const Icon = ui.icon;
    return (
        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold uppercase border ${ui.bg} ${ui.color}`}>
            <Icon className={`w-3 h-3 ${status === 'SENT' ? 'animate-spin' : ''}`} />
            {ui.label}
        </span>
    );
}

export default function CommandModal({ device, onClose }) {
    const { commands, commandsLoading, commandSending, loadCommands, sendCommand } = useDevice();

    const [jsonInput, setJsonInput] = useState('{\n  "MOD": 1\n}');
    const [jsonError, setJsonError] = useState(null);

    useEffect(() => {
        if (device?.id) loadCommands({ deviceId: device.id });
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [device?.id]);

    const handleJsonInput = (val) => {
        setJsonInput(val);
        try {
            const parsed = JSON.parse(val);
            setJsonError(validateCommandPayload(parsed));
        } catch { setJsonError('Invalid JSON'); }
    };

    const handleSend = async () => {
        let payload;
        try {
            payload = JSON.parse(jsonInput);
            const validationError = validateCommandPayload(payload);
            if (validationError) {
                setJsonError(validationError);
                return;
            }
            setJsonError(null);
        } catch {
            setJsonError('Invalid JSON');
            return;
        }
        const result = await sendCommand({ deviceId: device.id, payload });
        if (result.error) {
            toast.error(result.payload || 'Failed to send command');
        } else {
            toast.success('Command sent');
            loadCommands({ deviceId: device.id });
        }
    };

    return (
        <RightDrawer
            onClose={onClose}
            title="Command Console"
            subtitle={`${device.imeinumber}${device.name ? ` · ${device.name}` : ''}`}
            icon={<Terminal className="w-4 h-4 text-emerald-600" />}
            zClass="z-[200]"
        >
            {/* Command composer */}
            <div className="p-5 space-y-4 shrink-0 border-b border-slate-100">
                {/* JSON payload editor */}
                <div>
                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5">
                        Payload (JSON){jsonError && <span className="ml-2 text-red-500 normal-case">{jsonError}</span>}
                    </p>
                    <textarea
                        rows={6}
                        value={jsonInput}
                        onChange={(e) => handleJsonInput(e.target.value)}
                        spellCheck={false}
                        placeholder={'{\n  "MOD": 1\n}'}
                        className={`w-full font-mono text-xs text-slate-900 rounded-xl px-4 py-3 outline-none border-2 resize-none bg-slate-50 ${jsonError ? 'border-red-500' : 'border-transparent focus:border-emerald-500'}`}
                    />
                </div>

                <div>
                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5">
                        Quick examples
                    </p>
                    <div className="grid grid-cols-2 gap-2">
                        {COMMAND_EXAMPLES.map(({ label, payload, hint }) => (
                            <button
                                key={label}
                                type="button"
                                onClick={() => {
                                    setJsonInput(JSON.stringify(payload, null, 2));
                                    setJsonError(null);
                                }}
                                className="text-left px-3 py-2 rounded-xl border border-slate-200 bg-white hover:border-emerald-300 hover:bg-emerald-50 transition-colors"
                            >
                                <span className="block text-[11px] font-bold text-slate-700">{label}</span>
                                <span className="block text-[9px] font-mono text-slate-400">{hint}</span>
                            </button>
                        ))}
                    </div>
                    <p className="mt-2 text-[10px] text-slate-400">
                        MOD, PRR, PSM and PML are packed bit registers. Other commands are normal decimal values.
                    </p>
                </div>

                {/* Send button */}
                <button
                    onClick={handleSend}
                    disabled={commandSending || !!jsonError}
                    className="w-full flex items-center justify-center gap-2 py-2.5 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 text-white text-sm font-bold rounded-xl transition-colors"
                >
                    {commandSending
                        ? <><RefreshCw className="w-4 h-4 animate-spin" /> Sending…</>
                        : <><Send className="w-4 h-4" /> Send Command</>
                    }
                </button>
            </div>

            {/* Command history */}
            <div className="flex-1 overflow-auto">
                <div className="px-5 py-3 flex items-center justify-between border-b border-slate-50">
                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">History</p>
                    <button onClick={() => loadCommands({ deviceId: device.id })} className="text-slate-400 hover:text-slate-600 transition-colors">
                        <RefreshCw className={`w-3.5 h-3.5 ${commandsLoading ? 'animate-spin' : ''}`} />
                    </button>
                </div>

                {commandsLoading && commands.length === 0 ? (
                    <div className="flex items-center justify-center py-8 text-slate-400 text-xs gap-2">
                        <RefreshCw className="w-4 h-4 animate-spin" /> Loading…
                    </div>
                ) : commands.length === 0 ? (
                    <p className="text-center text-slate-300 text-xs py-8">No commands sent yet</p>
                ) : (
                    <ul className="divide-y divide-slate-50">
                        {commands.map((cmd) => (
                            <li key={cmd.id} className="px-5 py-3 flex items-start justify-between gap-3 hover:bg-slate-50/40 transition-colors">
                                <div className="min-w-0">
                                    <pre className="text-[11px] font-mono text-slate-600 truncate max-w-[260px]">
                                        {cmd.commandCode}{cmd.value != null ? ` : ${cmd.value}` : ''}
                                    </pre>
                                    <p className="text-[10px] text-slate-400 mt-0.5">
                                        {new Date(cmd.createdAt).toLocaleString('en-GB')}
                                    </p>
                                </div>
                                <StatusBadge status={cmd.status} />
                            </li>
                        ))}
                    </ul>
                )}
            </div>
        </RightDrawer>
    );
}

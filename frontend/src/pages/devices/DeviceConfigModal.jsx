// src/pages/devices/DeviceConfigModal.jsx
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react'; // eslint-disable-line no-unused-vars
import { Settings, Lock, User, Tag, Loader, Check, Send, Zap, ShieldAlert, Activity, Gauge, SlidersHorizontal, Cpu, Power, RotateCcw } from 'lucide-react';
import toast from 'react-hot-toast';
import axios from 'axios';
import { useDevice } from '../../hooks/useDevice';
import { useRole } from '../../hooks/useRole';
import { API_URL } from '../../configs/services';
import RightDrawer from '../../components/RightDrawer';

// ─────────────────────────────────────────────────────────
// I-Series Booster Panel config defaults (uppercase keys = MQTT register codes)
// ─────────────────────────────────────────────────────────
const DEFAULT_CONFIG = {
    // Pressure
    MXP: 8,   MNP: 2,   TFS: 10,  STP: 6,   DFP: 1,
    // Timing / Starts
    WUT: 30,  LPC: 5,   MSH: 6,
    // Electrical protection
    HVG: 260, LVG: 180, VCD: 10,
    OLC: 15,  OCD: 5,   DRC: 2,   DRD: 10,
    // VFD / Switching
    SWF: 50,  SWT: 30,  SLF: 25,  SLT: 60,  POF: 40,
    // PID gains
    PGN: 10,  IGN: 5,   DGN: 0,
    // Advanced
    STM: 100,
};

// ─────────────────────────────────────────────────────────
// Shared primitives
// ─────────────────────────────────────────────────────────
const SectionTitle = ({ icon: Icon, title, color }) => (
    <div className="flex items-center gap-2 mb-3">
        {Icon && <Icon className={`w-3.5 h-3.5 ${color}`} />}
        <p className={`text-[10px] font-extrabold uppercase tracking-widest ${color}`}>{title}</p>
        <div className="flex-1 h-px bg-slate-100" />
    </div>
);

const FieldLabel = ({ label, unit }) => (
    <p className="text-[9px] font-bold text-slate-400 uppercase tracking-widest mb-1">
        {label}{unit ? <span className="normal-case font-normal ml-1 text-slate-300">({unit})</span> : null}
    </p>
);

const NumField = ({ label, unit, fieldKey, value, onChange, step = 1, min, max }) => (
    <div>
        <FieldLabel label={label} unit={unit} />
        <input
            type="number"
            value={value ?? ''}
            step={step}
            min={min}
            max={max}
            onChange={(e) => onChange(fieldKey, e.target.value === '' ? '' : Number(e.target.value))}
            className="w-full px-2.5 py-2 text-sm font-mono font-semibold text-slate-700 bg-white border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-300 focus:border-emerald-400 transition-all"
        />
    </div>
);

// ─────────────────────────────────────────────────────────
// Tab: Device Info
// ─────────────────────────────────────────────────────────
function DeviceInfoPanel({ device, onClose, onSaved }) {
    const { updateDevice } = useDevice();
    const { isMacsoftRole } = useRole();

    const [name, setName] = useState(device.name ?? '');
    const [customerId, setCustomerId] = useState(device.customerId ?? '');
    const [customers, setCustomers] = useState([]);
    const [customersLoading, setCustomersLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        if (!isMacsoftRole()) {
            setCustomersLoading(false);
            return;
        }
        const fetchCustomers = async () => {
            try {
                const token = sessionStorage.getItem('token');
                const res = await axios.get(`${API_URL}/customers`, {
                    params: { take: 200 },
                    headers: { Authorization: `Bearer ${token}` },
                });
                setCustomers(res.data.customers ?? []);
            } catch {
                toast.error('Failed to load customers');
            } finally {
                setCustomersLoading(false);
            }
        };
        fetchCustomers();
    }, []); // eslint-disable-line react-hooks/exhaustive-deps

    const handleSave = async () => {
        setSaving(true);
        const result = await updateDevice({ deviceId: device.id, data: { name: name.trim() || null, customerId: customerId || null } });
        setSaving(false);

        if (result.error) {
            toast.error(result.payload || 'Failed to update device');
        } else {
            toast.success('Device updated');
            onSaved?.(result.payload);
            onClose();
        }
    };

    return (
        <div className="flex flex-col flex-1 overflow-hidden">
            <div className="flex-1 overflow-y-auto p-5 space-y-4">
                {/* IMEI — read-only */}
                <div>
                    <label className="flex items-center gap-1.5 text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5">
                        <Lock className="w-3 h-3" /> IMEI Number
                    </label>
                    <div className="flex items-center gap-2 px-3 py-2.5 bg-slate-100 rounded-xl border border-slate-200">
                        <p className="font-mono text-sm font-semibold text-slate-500 select-all flex-1">{device.imeinumber}</p>
                        <Lock className="w-3.5 h-3.5 text-slate-300 shrink-0" />
                    </div>
                    <p className="text-[10px] text-slate-300 mt-1">IMEI cannot be changed.</p>
                </div>

                {/* Device Name */}
                <div>
                    <label className="flex items-center gap-1.5 text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5">
                        <Tag className="w-3 h-3" /> Device Name
                    </label>
                    <input
                        type="text"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        placeholder="Enter device name…"
                        className="w-full px-3 py-2.5 text-sm font-medium text-slate-800 bg-white border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-300 focus:border-emerald-400 transition-all placeholder:text-slate-300"
                    />
                </div>

                {/* Customer Mapping — macsoft roles only */}
                {isMacsoftRole() && (
                    <div>
                        <label className="flex items-center gap-1.5 text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5">
                            <User className="w-3 h-3" /> Assigned Customer
                        </label>
                        {customersLoading ? (
                            <div className="flex items-center gap-2 px-3 py-2.5 bg-slate-50 rounded-xl border border-slate-200">
                                <Loader className="w-4 h-4 animate-spin text-slate-300" />
                                <span className="text-sm text-slate-300">Loading customers…</span>
                            </div>
                        ) : (
                            <select
                                value={customerId}
                                onChange={(e) => setCustomerId(e.target.value)}
                                className="w-full px-3 py-2.5 text-sm font-medium text-slate-800 bg-white border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-300 focus:border-emerald-400 transition-all appearance-none cursor-pointer"
                            >
                                <option value="">— Unassigned —</option>
                                {customers.map((c) => (
                                    <option key={c.id} value={c.id}>
                                        {c.name || c.email}
                                    </option>
                                ))}
                            </select>
                        )}
                    </div>
                )}
            </div>

            <div className="px-5 py-4 border-t border-slate-100 flex items-center justify-end gap-2 bg-slate-50/40">
                <button
                    onClick={onClose}
                    disabled={saving}
                    className="px-4 py-2 text-sm font-semibold text-slate-600 hover:text-slate-800 hover:bg-slate-100 rounded-xl transition-colors disabled:opacity-40"
                >
                    Cancel
                </button>
                <button
                    onClick={handleSave}
                    disabled={saving}
                    className="flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl transition-colors disabled:opacity-50 shadow-sm"
                >
                    {saving ? <Loader className="w-3.5 h-3.5 animate-spin" /> : <Check className="w-3.5 h-3.5" />}
                    {saving ? 'Saving…' : 'Save Changes'}
                </button>
            </div>
        </div>
    );
}

// ─────────────────────────────────────────────────────────
// Map DB DeviceConfig fields (lowercase) → MQTT payload keys (uppercase)
// ─────────────────────────────────────────────────────────
const dbToCfg = (db) => ({
    MXP: db.mxp ?? DEFAULT_CONFIG.MXP,
    MNP: db.mnp ?? DEFAULT_CONFIG.MNP,
    TFS: db.tfs ?? DEFAULT_CONFIG.TFS,
    STP: db.stp ?? DEFAULT_CONFIG.STP,
    DFP: db.dfp ?? DEFAULT_CONFIG.DFP,
    WUT: db.wut ?? DEFAULT_CONFIG.WUT,
    LPC: db.lpc ?? DEFAULT_CONFIG.LPC,
    MSH: db.msh ?? DEFAULT_CONFIG.MSH,
    HVG: db.hvg ?? DEFAULT_CONFIG.HVG,
    LVG: db.lvg ?? DEFAULT_CONFIG.LVG,
    VCD: db.vcd ?? DEFAULT_CONFIG.VCD,
    OLC: db.olc ?? DEFAULT_CONFIG.OLC,
    OCD: db.ocd ?? DEFAULT_CONFIG.OCD,
    DRC: db.drc ?? DEFAULT_CONFIG.DRC,
    DRD: db.drd ?? DEFAULT_CONFIG.DRD,
    SWF: db.swf ?? DEFAULT_CONFIG.SWF,
    SWT: db.swt ?? DEFAULT_CONFIG.SWT,
    SLF: db.slf ?? DEFAULT_CONFIG.SLF,
    SLT: db.slt ?? DEFAULT_CONFIG.SLT,
    POF: db.pof ?? DEFAULT_CONFIG.POF,
    PGN: db.pgn ?? DEFAULT_CONFIG.PGN,
    IGN: db.ign ?? DEFAULT_CONFIG.IGN,
    DGN: db.dgn ?? DEFAULT_CONFIG.DGN,
    STM: db.stm ?? DEFAULT_CONFIG.STM,
});

// ─────────────────────────────────────────────────────────
// Tab: I-Series Config
// ─────────────────────────────────────────────────────────
function ISeriesConfigPanel({ device, onClose }) {
    const { sendCommand, commandSending, saveDeviceConfig } = useDevice();
    const [cfg, setCfg] = useState(() =>
        device.config ? dbToCfg(device.config) : { ...DEFAULT_CONFIG }
    );
    const [saving, setSaving] = useState(false);
    const set = (key, val) => setCfg((prev) => ({ ...prev, [key]: val }));

    const handleSave = async () => {
        setSaving(true);
        const result = await saveDeviceConfig({ deviceId: device.id, cfg });
        setSaving(false);
        if (result.error) {
            toast.error(result.payload || 'Failed to save config');
        } else {
            toast.success('Config saved to database');
        }
    };

    // Send each register individually — device processes one register write per MQTT message
    const handleSendToDevice = async () => {
        const entries = Object.entries(cfg).filter(([, v]) => v !== '' && v != null);
        for (const [code, value] of entries) {
            const result = await sendCommand({ deviceId: device.id, payload: { [code]: Number(value) } });
            if (result.error) { toast.error(`Failed to send ${code}`); return; }
        }
        toast.success('All config registers sent to device');
    };

    const isBusy = saving || commandSending;

    return (
        <div className="flex flex-col flex-1 overflow-hidden">
            <div className="flex-1 overflow-y-auto p-5 space-y-5">

                {/* Pressure Settings */}
                <div>
                    <SectionTitle icon={Gauge} title="Pressure Settings" color="text-cyan-500" />
                    <div className="grid grid-cols-2 gap-3">
                        <NumField label="Max Pressure"          unit="bar"  fieldKey="MXP" value={cfg.MXP} onChange={set} step={0.5} min={0} />
                        <NumField label="Min Pressure"          unit="bar"  fieldKey="MNP" value={cfg.MNP} onChange={set} step={0.5} min={0} />
                        <NumField label="Set Pressure"          unit="bar"  fieldKey="STP" value={cfg.STP} onChange={set} step={0.5} min={0} />
                        <NumField label="Differential Press."  unit="bar"  fieldKey="DFP" value={cfg.DFP} onChange={set} step={0.5} min={0} />
                        <NumField label="Transducer Full Scale" unit="bar"  fieldKey="TFS" value={cfg.TFS} onChange={set} step={1}   min={0} />
                    </div>
                </div>

                {/* Timing & Starts */}
                <div>
                    <SectionTitle icon={Activity} title="Timing &amp; Starts" color="text-emerald-500" />
                    <div className="grid grid-cols-2 gap-3">
                        <NumField label="Warm Up Time"              unit="hrs"  fieldKey="WUT" value={cfg.WUT} onChange={set} step={1} min={0} />
                        <NumField label="Low Press. Cutoff Delay"   unit="mins" fieldKey="LPC" value={cfg.LPC} onChange={set} step={1} min={0} />
                        <NumField label="Max Starts / hr"           unit=""     fieldKey="MSH" value={cfg.MSH} onChange={set} step={1} min={0} />
                    </div>
                </div>

                {/* Electrical Protection */}
                <div>
                    <SectionTitle icon={ShieldAlert} title="Electrical Protection" color="text-blue-500" />
                    <div className="grid grid-cols-2 gap-3">
                        <NumField label="High Voltage"           unit="V"    fieldKey="HVG" value={cfg.HVG} onChange={set} step={1}   min={100} max={300} />
                        <NumField label="Low Voltage"            unit="V"    fieldKey="LVG" value={cfg.LVG} onChange={set} step={1}   min={100} max={300} />
                        <NumField label="Voltage Cutoff Delay"   unit="secs" fieldKey="VCD" value={cfg.VCD} onChange={set} step={1}   min={0} />
                        <NumField label="Overload Current"       unit="A"    fieldKey="OLC" value={cfg.OLC} onChange={set} step={0.5} min={0} />
                        <NumField label="Overload Cutoff Delay"  unit="secs" fieldKey="OCD" value={cfg.OCD} onChange={set} step={1}   min={0} />
                        <NumField label="Dry Run Current"        unit="A"    fieldKey="DRC" value={cfg.DRC} onChange={set} step={0.5} min={0} />
                        <NumField label="Dry Run Delay"          unit="secs" fieldKey="DRD" value={cfg.DRD} onChange={set} step={1}   min={0} />
                    </div>
                </div>

                {/* VFD / Switching */}
                <div>
                    <SectionTitle icon={Zap} title="VFD / Switching" color="text-amber-500" />
                    <div className="grid grid-cols-2 gap-3">
                        <NumField label="Switching Frequency" unit="Hz"   fieldKey="SWF" value={cfg.SWF} onChange={set} step={1} min={0} max={60} />
                        <NumField label="Switching Time"      unit="secs" fieldKey="SWT" value={cfg.SWT} onChange={set} step={1} min={0} />
                        <NumField label="Sleep Frequency"     unit="Hz"   fieldKey="SLF" value={cfg.SLF} onChange={set} step={1} min={0} max={60} />
                        <NumField label="Sleep Time"          unit="secs" fieldKey="SLT" value={cfg.SLT} onChange={set} step={1} min={0} />
                        <NumField label="PID Overwrite Freq." unit="Hz"   fieldKey="POF" value={cfg.POF} onChange={set} step={1} min={0} max={60} />
                    </div>
                </div>

                {/* PID Gains */}
                <div>
                    <SectionTitle icon={SlidersHorizontal} title="PID Gains" color="text-indigo-500" />
                    <div className="grid grid-cols-3 gap-3">
                        <NumField label="Proportional" fieldKey="PGN" value={cfg.PGN} onChange={set} step={1} min={0} />
                        <NumField label="Integral"     fieldKey="IGN" value={cfg.IGN} onChange={set} step={1} min={0} />
                        <NumField label="Derivative"   fieldKey="DGN" value={cfg.DGN} onChange={set} step={1} min={0} />
                    </div>
                </div>

                <div>
                    <SectionTitle icon={SlidersHorizontal} title="Advanced" color="text-slate-400" />
                    <div className="grid grid-cols-2 gap-3">
                        <NumField label="Scan Time" unit="ms" fieldKey="STM" value={cfg.STM} onChange={set} step={10} min={100} max={60000} />
                    </div>
                </div>

                {/* Hardware info */}
                <div>
                    <SectionTitle icon={Cpu} title="Hardware" color="text-slate-400" />
                    <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 space-y-2">
                        {[
                            { label: 'IMEI',           value: device.imeinumber },
                            { label: 'Pump Model',     value: device.pumpModel ?? '—' },
                            { label: 'Command Topic',  value: device.mqttCommandTopic || `device/${device.imeinumber}/cmd` },
                        ].map(({ label, value }) => (
                            <div key={label} className="flex items-start justify-between gap-2 text-[11px]">
                                <span className="font-bold text-slate-400 uppercase tracking-wider text-[9px] shrink-0">{label}</span>
                                <span className="font-mono text-slate-600 text-right break-all">{value}</span>
                            </div>
                        ))}
                    </div>
                </div>

            </div>

            {/* Footer */}
            <div className="px-5 py-4 border-t border-slate-100 flex items-center justify-between gap-3 bg-slate-50/40">
                <p className="text-[10px] text-slate-300 font-mono truncate">{device.mqttCommandTopic || `device/${device.imeinumber}/cmd`}</p>
                <div className="flex items-center gap-2 shrink-0">
                    <button
                        onClick={onClose}
                        disabled={isBusy}
                        className="px-4 py-2 text-sm font-semibold text-slate-600 hover:text-slate-800 hover:bg-slate-100 rounded-xl transition-colors disabled:opacity-40"
                    >
                        Close
                    </button>
                    <button
                        onClick={handleSave}
                        disabled={isBusy}
                        className="flex items-center gap-2 px-4 py-2 text-sm font-semibold text-slate-700 bg-white border border-slate-200 hover:bg-slate-50 rounded-xl transition-colors disabled:opacity-50 shadow-sm"
                    >
                        {saving ? <Loader className="w-3.5 h-3.5 animate-spin" /> : <Check className="w-3.5 h-3.5" />}
                        {saving ? 'Saving…' : 'Save'}
                    </button>
                    <button
                        onClick={handleSendToDevice}
                        disabled={isBusy}
                        className="flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl transition-colors disabled:opacity-50 shadow-sm"
                    >
                        {commandSending ? <Loader className="w-3.5 h-3.5 animate-spin" /> : <Send className="w-3.5 h-3.5" />}
                        {commandSending ? 'Sending…' : 'Send to Device'}
                    </button>
                </div>
            </div>
        </div>
    );
}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────
function getPumpCount(model) {
    const m = model?.match(/MODEL_(\d+)P(\d+)/);
    if (!m) return 2;
    return parseInt(m[1]) + parseInt(m[2]);
}

const PML_OPTIONS = [
    { label: '1+1 Pump / 2 Pump', value: 1 },
    { label: '2+1 Pump / 3 Pump', value: 2 },
    { label: '3+1 Pump / 4 Pump', value: 4 },
    { label: '4+1 Pump / 5 Pump', value: 8 },
];

// ─────────────────────────────────────────────────────────
// Tab: Bit Controls
// ─────────────────────────────────────────────────────────
function BitControlsPanel({ device, onClose }) {
    const { sendCommand } = useDevice();
    const pumpCount = getPumpCount(device.pumpModel);
    const pumps = Array.from({ length: pumpCount }, (_, i) => i + 1);

    // Packed register local state
    // MOD: bit0=amo, bit1=mmo, bit2-6=p1v-p5v (VFD manual), bit7-11=p1d-p5d (DOL manual)
    // PSM: bit0-4=s1m-s5m (service mode)
    const [mod, setMod] = useState(device?.state?.mod ?? 1); // bit0 (AMO) set by default
    const [psm, setPsm] = useState(device?.state?.psm ?? 0);
    const [pml, setPml] = useState(device?.state?.pml ?? 0);
    const [sending, setSending] = useState({});
    const [resetting, setResetting] = useState({});

    const setBit = (val, bit, on) => on ? (val | (1 << bit)) : (val & ~(1 << bit));

    const fireMod = async (nextMod) => {
        setSending((p) => ({ ...p, MOD: true }));
        await sendCommand({ deviceId: device.id, payload: { MOD: nextMod } });
        setSending((p) => ({ ...p, MOD: false }));
    };
    const firePsm = async (nextPsm) => {
        setSending((p) => ({ ...p, PSM: true }));
        await sendCommand({ deviceId: device.id, payload: { PSM: nextPsm } });
        setSending((p) => ({ ...p, PSM: false }));
    };
    const firePml = async (nextPml) => {
        setSending((p) => ({ ...p, PML: true }));
        await sendCommand({ deviceId: device.id, payload: { PML: nextPml } });
        setSending((p) => ({ ...p, PML: false }));
    };

    // AMO / MMO are mutually exclusive — bit0 XOR bit1
    const handleMode = async (code) => {
        const next = code === 'AMO'
            ? setBit(setBit(mod, 1, false), 0, true)
            : setBit(setBit(mod, 0, false), 1, true);
        setMod(next);
        await fireMod(next);
    };

    const handleVfd = async (n, on) => {
        const next = setBit(mod, 2 + (n - 1), on); // p1v=bit2…p5v=bit6
        setMod(next);
        await fireMod(next);
    };
    const handleDol = async (n, on) => {
        const next = setBit(mod, 7 + (n - 1), on); // p1d=bit7…p5d=bit11
        setMod(next);
        await fireMod(next);
    };
    const handleService = async (n, on) => {
        const next = setBit(psm, n - 1, on); // s1m=bit0…s5m=bit4
        setPsm(next);
        await firePsm(next);
    };
    const handlePumpModel = async (value) => {
        setPml(value);
        await firePml(value);
    };

    // PRR: momentary pulse — set bit(n-1), then clear after 600 ms
    const handleReset = async (n) => {
        setResetting((p) => ({ ...p, [n]: true }));
        const prrVal = 1 << (n - 1);
        await sendCommand({ deviceId: device.id, payload: { PRR: prrVal } });
        setTimeout(async () => {
            await sendCommand({ deviceId: device.id, payload: { PRR: 0 } });
            setResetting((p) => ({ ...p, [n]: false }));
        }, 600);
    };

    const BitToggle = ({ on, onToggle, disabled }) => (
        <button
            onClick={onToggle}
            disabled={disabled}
            className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none disabled:opacity-50 ${
                on ? 'bg-emerald-500' : 'bg-slate-200'
            }`}
        >
            <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${on ? 'translate-x-6' : 'translate-x-1'}`} />
        </button>
    );

    const isAmo = !!(mod & 1);
    const isMmo = !!(mod & 2);

    return (
        <div className="flex flex-col flex-1 overflow-hidden">
            <div className="flex-1 overflow-y-auto p-5 space-y-5">

                {/* System Mode */}
                <div>
                    <SectionTitle icon={Power} title="System Mode" color="text-violet-500" />
                    <div className="flex gap-3">
                        {[{ code: 'AMO', label: 'AUTO', color: 'emerald', active: isAmo }, { code: 'MMO', label: 'MANUAL', color: 'amber', active: isMmo }].map(({ code, label, color, active }) => (
                            <button
                                key={code}
                                onClick={() => handleMode(code)}
                                disabled={!!sending.MOD}
                                className={`flex-1 py-3 rounded-xl font-bold text-sm transition-all border-2 ${
                                    active
                                        ? color === 'emerald'
                                            ? 'bg-emerald-500 border-emerald-500 text-white shadow-md'
                                            : 'bg-amber-500 border-amber-500 text-white shadow-md'
                                        : 'bg-white border-slate-200 text-slate-400 hover:border-slate-300'
                                }`}
                            >
                                {sending.MOD ? '…' : label}
                            </button>
                        ))}
                    </div>
                </div>

                {/* Pump Model Register */}
                <div>
                    <SectionTitle icon={Cpu} title="Pump Model Register (PML)" color="text-violet-500" />
                    <div className="grid grid-cols-2 gap-2">
                        {PML_OPTIONS.map(({ label, value }) => (
                            <button
                                key={value}
                                onClick={() => handlePumpModel(value)}
                                disabled={!!sending.PML}
                                className={`py-2.5 rounded-xl font-bold text-xs transition-all border-2 disabled:opacity-50 ${
                                    pml === value
                                        ? 'bg-violet-500 border-violet-500 text-white shadow-md'
                                        : 'bg-white border-slate-200 text-slate-400 hover:border-violet-300 hover:text-violet-600'
                                }`}
                            >
                                {sending.PML ? '…' : label}
                            </button>
                        ))}
                    </div>
                </div>

                {/* Per-Pump Controls */}
                <div>
                    <SectionTitle icon={Activity} title="Per-Pump Controls" color="text-emerald-500" />
                    <div className="rounded-xl border border-slate-200 overflow-hidden">
                        <div className="grid grid-cols-[3rem_1fr_1fr_1fr_auto] gap-0 bg-slate-50 border-b border-slate-200 text-[10px] font-bold uppercase tracking-wider text-slate-400">
                            <div className="px-3 py-2 text-center">#</div>
                            <div className="px-3 py-2 text-center">VFD Manual</div>
                            <div className="px-3 py-2 text-center">DOL Manual</div>
                            <div className="px-3 py-2 text-center">Service</div>
                            <div className="px-3 py-2 text-center">Reset Mins</div>
                        </div>
                        {pumps.map((n) => {
                            const vOn  = !!(mod & (1 << (2 + n - 1)));
                            const dOn  = !!(mod & (1 << (7 + n - 1)));
                            const sOn  = !!(psm & (1 << (n - 1)));
                            return (
                                <div
                                    key={n}
                                    className={`grid grid-cols-[3rem_1fr_1fr_1fr_auto] gap-0 items-center border-b border-slate-100 last:border-0 ${n % 2 === 0 ? 'bg-slate-50/40' : 'bg-white'}`}
                                >
                                    <div className="px-3 py-3 text-center text-xs font-bold text-slate-500">P{n}</div>
                                    <div className="px-3 py-3 flex justify-center">
                                        <BitToggle on={vOn} onToggle={() => handleVfd(n, !vOn)} disabled={!!sending.MOD} />
                                    </div>
                                    <div className="px-3 py-3 flex justify-center">
                                        <BitToggle on={dOn} onToggle={() => handleDol(n, !dOn)} disabled={!!sending.MOD} />
                                    </div>
                                    <div className="px-3 py-3 flex justify-center">
                                        <BitToggle on={sOn} onToggle={() => handleService(n, !sOn)} disabled={!!sending.PSM} />
                                    </div>
                                    <div className="px-3 py-3 flex justify-center">
                                        <button
                                            onClick={() => handleReset(n)}
                                            disabled={!!resetting[n]}
                                            className="flex items-center gap-1.5 px-3 py-1.5 text-[11px] font-semibold text-orange-600 bg-orange-50 border border-orange-200 rounded-lg hover:bg-orange-100 transition-colors disabled:opacity-50"
                                        >
                                            <RotateCcw className={`w-3 h-3 ${resetting[n] ? 'animate-spin' : ''}`} />
                                            {resetting[n] ? '…' : 'Reset'}
                                        </button>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                    <p className="mt-2 text-[10px] text-slate-400">VFD / DOL toggles write MOD register. Pump model writes PML register. Service toggles write PSM register. Reset sends a momentary PRR pulse.</p>
                </div>

            </div>

            {/* Footer */}
            <div className="px-5 py-4 border-t border-slate-100 flex items-center justify-end bg-slate-50/40">
                <button
                    onClick={onClose}
                    className="px-4 py-2 text-sm font-semibold text-slate-600 hover:text-slate-800 hover:bg-slate-100 rounded-xl transition-colors"
                >
                    Close
                </button>
            </div>
        </div>
    );
}

// ─────────────────────────────────────────────────────────
// Root modal — tab shell
// ─────────────────────────────────────────────────────────
const TABS = [
    { id: 'info',   label: 'Device Info' },
    { id: 'config', label: 'I-Series Config' },
    { id: 'bits',   label: 'Bit Controls' },
];

export default function DeviceConfigModal({ device, onClose, onSaved }) {
    const [activeTab, setActiveTab] = useState('info');

    return (
        <RightDrawer
            onClose={onClose}
            title="Device Configuration"
            subtitle={device.imeinumber}
            icon={<Settings className="w-4 h-4 text-emerald-600" />}
            zClass="z-[200]"
        >
                {/* Tab bar */}
                <div className="flex gap-1 px-5 pt-3 pb-0 border-b border-slate-100 bg-white shrink-0">
                    {TABS.map(({ id, label }) => (
                        <button
                            key={id}
                            onClick={() => setActiveTab(id)}
                            className={`px-4 py-2 text-xs font-bold rounded-t-xl border-b-2 transition-all ${
                                activeTab === id
                                    ? 'text-emerald-600 border-emerald-500 bg-emerald-50/50'
                                    : 'text-slate-400 border-transparent hover:text-slate-600 hover:bg-slate-50'
                            }`}
                        >
                            {label}
                        </button>
                    ))}
                </div>

                {/* Panel */}
                <div className="flex-1 overflow-hidden flex flex-col">
                    <AnimatePresence mode="wait">
                        <motion.div
                            key={activeTab}
                            initial={{ opacity: 0, y: 6 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -6 }}
                            transition={{ duration: 0.15 }}
                            className="flex flex-col h-full"
                        >
                            {activeTab === 'info'
                                ? <DeviceInfoPanel device={device} onClose={onClose} onSaved={onSaved} />
                                : activeTab === 'config'
                                    ? <ISeriesConfigPanel device={device} onClose={onClose} />
                                    : <BitControlsPanel device={device} onClose={onClose} />
                            }
                        </motion.div>
                    </AnimatePresence>
                </div>
        </RightDrawer>
    );
}

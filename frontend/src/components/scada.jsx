import { motion } from "motion/react"; // eslint-disable-line no-unused-vars
import { cn } from "../utils/cn";
import { Activity, Fan, AlertTriangle, Zap, Gauge, Target } from "lucide-react";
// Precomputed bubble configs — avoids Math.random() calls during render
const BUBBLES = Array.from({ length: 6 }, () => ({
    width:    2 + Math.random() * 3,
    height:   2 + Math.random() * 3,
    left:     `${12 + Math.random() * 76}%`,
    duration: 3.5 + Math.random() * 3,
    delay:    Math.random() * 4,
}));

// ─── Tank ────────────────────────────────────────────────────────────────────

export function Tank({ label = " ", isFault, pressure = 0, maxPressure = 8, setPoint = null }) {
    const pressurePercentage = Math.min(Math.max((pressure / maxPressure) * 100, 0), 100);

    const getPressureStatus = () => {
        if (isFault) return "fault";
        if (pressurePercentage < 40) return "low";
        if (pressurePercentage <= 75) return "correct";
        return "high";
    };

    const pressureStatus = getPressureStatus();

    const fillColor = isFault ? "rgba(220, 50, 50, 0.7)" : "rgba(30, 120, 200, 0.75)";
    const fillColorTop = isFault ? "rgba(240, 90, 90, 0.5)" : "rgba(60, 155, 225, 0.5)";
    const borderColor = isFault ? "border-red-400/60" : "border-sky-400/50";
    const glow = isFault ? "shadow-[0_0_20px_rgba(239,68,68,0.35)]" : "shadow-[0_0_16px_rgba(60,150,220,0.25)]";
    const levelLineColor = isFault ? "rgba(239,68,68,0.9)" : "rgba(20,100,180,0.85)";
    const waveAmplitude = isFault ? 6 : pressureStatus === "high" ? 5 : 3;
    const waveDuration = isFault ? 1 : pressureStatus === "high" ? 1.6 : 2.4;
    const waveColor1 = isFault ? "rgba(239,68,68,0.55)" : "rgba(40,130,210,0.65)";
    const waveColor2 = isFault ? "rgba(239,68,68,0.35)" : "rgba(70,160,230,0.45)";
    const waveColor3 = isFault ? "rgba(239,68,68,0.2)" : "rgba(100,180,240,0.3)";

    return (
        <div className="relative flex flex-col items-center">
            {/* Top Cap  
            <div className={cn(
                "w-28 h-7 rounded-t-full border-2 border-b-0 relative overflow-hidden",
                "bg-linear-to-b from-white to-slate-100",
                borderColor
            )}>
                <div className="absolute inset-0 bg-linear-to-r from-transparent via-white/60 to-transparent" />
            </div>

            {/* Cylinder Body  
            <div className={cn(
                "w-28 h-56 relative overflow-hidden border",
                "bg-linear-to-b from-white via-slate-50 to-slate-100",
                "border-x-2",
                borderColor,
                glow,
            )}>
                {/* Glass highlight  
                <div className="absolute inset-y-0 left-1 w-3 bg-linear-to-b from-white/50 via-white/20 to-transparent rounded-full z-30 pointer-events-none" />

                {/* Scale markings  
                <div className="absolute inset-0 z-20 flex flex-col justify-between py-3 px-1 pointer-events-none">
                    {[100, 75, 50, 25, 0].map((mark) => (
                        <div key={mark} className="w-full flex items-center justify-between">
                            <div className="h-px w-2 bg-slate-300/60" />
                            <span className="text-[8px] text-slate-400 font-mono">
                                {(maxPressure * mark / 100).toFixed(1)}
                            </span>
                            <div className="h-px w-2 bg-slate-300/60" />
                        </div>
                    ))}
                </div>

                {/* Water Fill 
                <div className="absolute bottom-0 left-0 right-0 h-full w-full z-10 flex items-end">
                    <motion.div
                        initial={{ height: "0%" }}
                        animate={{ height: `${pressurePercentage}%` }}
                        transition={{ type: "spring", damping: 22, stiffness: 100 }}
                        className="w-full relative"
                        style={{ background: `linear-gradient(to top, ${fillColor}, ${fillColorTop})` }}
                    >
                        <div className="absolute inset-0 bg-linear-to-t from-transparent to-white/10" />

                        {/* Level Indicator Line  
                        {pressurePercentage > 2 && (
                            <div className="absolute top-0 left-0 right-0 z-40 pointer-events-none">
                                <div className="w-full h-0.5" style={{ backgroundColor: levelLineColor }} />
                                <div className="w-full h-1 opacity-60" style={{ background: `linear-gradient(to bottom, ${levelLineColor}, transparent)` }} />
                                <div className="absolute -top-5 right-0.5 z-50">
                                    <span
                                        className="text-[9px] font-mono font-bold px-1 py-px rounded shadow-sm"
                                        style={{ backgroundColor: isFault ? 'rgba(239,68,68,0.9)' : 'rgba(20,100,180,0.9)', color: 'white' }}
                                    >
                                        {pressurePercentage.toFixed(0)}%
                                    </span>
                                </div>
                            </div>
                        )}

                        {/* Wave Tides  
                        {pressurePercentage > 4 && (
                            <div className="absolute -top-4 left-0 right-0 h-8 overflow-visible pointer-events-none">
                                {[
                                    { color: waveColor1, amp: waveAmplitude,        dur: waveDuration,        delay: 0   },
                                    { color: waveColor2, amp: waveAmplitude * 0.7,  dur: waveDuration * 1.3,  delay: 0.4 },
                                    { color: waveColor3, amp: waveAmplitude * 0.45, dur: waveDuration * 1.7,  delay: 0.8 },
                                ].map((w, i) => (
                                    <svg key={i} className="absolute bottom-0 left-0 w-full" style={{ height: 20 }} viewBox="0 0 120 20" preserveAspectRatio="none">
                                        <motion.path
                                            fill={w.color}
                                            animate={{
                                                d: [
                                                    `M0 ${10 + w.amp} C20 ${10 - w.amp} 40 ${10 + w.amp} 60 ${10 - w.amp * 0.5} C80 ${10 + w.amp} 100 ${10 - w.amp} 120 ${10 + w.amp * 0.5} V20 H0Z`,
                                                    `M0 ${10 - w.amp * 0.5} C20 ${10 + w.amp} 40 ${10 - w.amp} 60 ${10 + w.amp * 0.5} C80 ${10 - w.amp} 100 ${10 + w.amp} 120 ${10 - w.amp * 0.5} V20 H0Z`,
                                                    `M0 ${10 + w.amp} C20 ${10 - w.amp} 40 ${10 + w.amp} 60 ${10 - w.amp * 0.5} C80 ${10 + w.amp} 100 ${10 - w.amp} 120 ${10 + w.amp * 0.5} V20 H0Z`,
                                                ],
                                            }}
                                            transition={{ repeat: Infinity, duration: w.dur, delay: w.delay, ease: "easeInOut" }}
                                        />
                                    </svg>
                                ))}
                            </div>
                        )}

                        {/* Bubbles  
                        {pressurePercentage > 8 && (
                            <div className="absolute inset-0 overflow-hidden">
                                {BUBBLES.map((b, i) => (
                                    <motion.div
                                        key={i}
                                        className="absolute rounded-full bg-white/30"
                                        style={{ width: b.width, height: b.height, left: b.left }}
                                        initial={{ bottom: -4, opacity: 0.6 }}
                                        animate={{ bottom: "105%", opacity: 0 }}
                                        transition={{ repeat: Infinity, duration: b.duration, delay: b.delay, ease: "linear" }}
                                    />
                                ))}
                            </div>
                        )}
                    </motion.div>
                </div>
            </div>

            {/* Bottom Cap 
            <div className={cn(
                "w-28 h-7 rounded-b-full border-2 border-t-0 relative overflow-hidden",
                "bg-linear-to-t from-white to-slate-100",
                borderColor
            )}>
                <div className="absolute inset-0 bg-linear-to-r from-transparent via-white/60 to-transparent" />
            </div>

            {/* Label 
            <div className="mt-3 text-center">
                <div className="font-semibold text-slate-600 uppercase tracking-wider text-xs">{label}</div>
                <div className="flex items-center justify-center gap-1.5 mt-1">
                    <div className={cn(
                        "w-1.5 h-1.5 rounded-full",
                        isFault ? "bg-red-500 animate-pulse" : pressurePercentage > 5 ? "bg-sky-400 animate-pulse" : "bg-slate-400"
                    )} />
                    <span className="font-mono text-[10px] text-slate-500">
                        {pressurePercentage.toFixed(0)}%
                    </span>
                </div>
            </div>

            {/* Pressure Readout */}


            <div className="mt-4 w-full space-y-3">
                {/* ACTUAL PRESSURE */}
                <motion.div
                    animate={isFault ? { scale: [1, 1.08, 1] } : {}}
                    transition={{ repeat: Infinity, duration: 1.5 }}
                    className={cn(
                        "bg-white/95 border rounded-xl px-5 py-4 shadow-md flex items-center gap-4",
                        isFault ? "border-red-400" : "border-sky-200"
                    )}
                >
                    {/* Animated Icon */}
                    <motion.div
                        animate={
                            isFault
                                ? { rotate: [0, -10, 10, -10, 0] }
                                : { scale: [1, 1.1, 1] }
                        }
                        transition={{ repeat: Infinity, duration: 1.2 }}
                        className={cn(
                            "p-2 rounded-lg",
                            isFault ? "bg-red-100" : "bg-sky-100"
                        )}
                    >
                        <Gauge
                            className={cn(
                                "w-6 h-6",
                                isFault ? "text-red-500" : "text-sky-600"
                            )}
                        />
                    </motion.div>

                    {/* Text Content */}
                    <div className="flex-1">
                        <div className="text-xs text-slate-400 uppercase tracking-wider mb-1">
                            Actual Pressure
                        </div>

                        <motion.div
                            key={pressure}
                            initial={{ opacity: 0, y: 5 }}
                            animate={{ opacity: 1, y: 0 }}
                            className={cn(
                                "text-3xl font-mono font-bold",
                                isFault ? "text-red-500" : "text-sky-600"
                            )}
                        >
                            {pressure.toFixed(2)}
                        </motion.div>

                        <div className="text-xs text-slate-400">bar</div>
                    </div>
                </motion.div>

                {/* SET PRESSURE */}
                {setPoint != null && (
                    <motion.div
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="bg-orange-50/80 border border-orange-200 rounded-xl px-5 py-3 shadow-md flex items-center gap-4"
                    >
                        {/* Animated Icon */}
                        <motion.div
                            animate={{ scale: [1, 1.15, 1] }}
                            transition={{ repeat: Infinity, duration: 1.6 }}
                            className="p-2 rounded-lg bg-orange-100"
                        >
                            <Target className="w-6 h-6 text-orange-500" />
                        </motion.div>

                        {/* Text */}
                        <div className="flex-1">
                            <div className="text-xs text-orange-400 uppercase tracking-wider mb-1">
                                Set Pressure
                            </div>

                            <div className="text-2xl font-mono font-bold text-orange-500">
                                {Number(setPoint).toFixed(1)}
                            </div>

                            <div className="text-xs text-orange-300">bar</div>
                        </div>
                    </motion.div>
                )}
            </div>
        </div>
    );
}

// ─── Pump ────────────────────────────────────────────────────────────────────

export function Pump({
    isRunning = true,
    isFault,
    speed = 100,
    label = "Pump 01",
    activeCurrent = 0,
    activeFrequency = 0,
    operationalMode = "auto",
    togglePump = () => {},
    idx,
}) {
    return (
        <div className={cn(
            "flex flex-col items-center bg-white p-2 rounded-2xl rounded-tl-none rounded-br-none py-4 w-50",
            isRunning
                ? "border-emerald-500/25 border text-slate-900 hover:bg-slate-100/50"
                : "border-gray-500/25 border bg-white text-slate-700 hover:bg-slate-200",
            isFault && "border-red-500/25 text-slate-900 hover:bg-slate-100/50",
        )}>
            {operationalMode === "manual" && (
                <div className="pb-2 w-full flex justify-center">
                    <motion.button
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => !isFault && togglePump(idx)}
                        disabled={isFault}
                        className={cn(
                            "px-5 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wider transition-all duration-200 shadow-md w-full",
                            isFault ? "bg-red-500 text-white cursor-not-allowed"
                                : isRunning ? "bg-red-500 text-white hover:bg-red-600"
                                    : "bg-emerald-500 text-white hover:bg-emerald-600"
                        )}
                    >
                        {isFault ? "FAULT" : isRunning ? "STOP" : "START"}
                    </motion.button>
                </div>
            )}

            {/* Wheel */}
            <div className={cn(
                "w-20 h-20 rounded-full border-4 flex items-center justify-center relative bg-slate-200 shadow-xl transition-all duration-300",
                isFault ? "border-red-500 shadow-[0_0_20px_rgba(239,68,68,0.4)]"
                    : isRunning ? "border-emerald-500 shadow-[0_0_20px_rgba(16,185,129,0.3)]"
                        : "border-slate-500",
            )}>
                {/* Status dot */}
                <div className={cn(
                    "absolute top-0 right-0 w-4 h-4 rounded-full border-2 border-white z-10 transition-all duration-300",
                    isFault ? "bg-red-500 animate-pulse"
                        : isRunning ? "bg-emerald-500"
                            : "bg-slate-100",
                )} />

                <motion.div
                    animate={{ rotate: isRunning && !isFault ? 360 : 0 }}
                    transition={{ repeat: Infinity, duration: isRunning && !isFault ? 60 / (speed || 60) : 0, ease: "linear" }}
                >
                    <Fan className={cn(
                        "w-10 h-10",
                        isFault ? "text-red-500" : isRunning ? "text-emerald-500" : "text-slate-600",
                    )} />
                </motion.div>
            </div>

            {/* Label + stats — always same layout regardless of state */}
            <div className="mt-2 text-center px-2 py-1 rounded w-full">
                <div className="font-bold text-slate-700 uppercase text-xs tracking-wider mb-2">{label}</div>

                {/* Status badge row */}
                {isFault ? (
                    <div className="flex items-center justify-center gap-1.5 mb-2 px-3 py-1 rounded-xl bg-red-50 border border-red-200">
                        <AlertTriangle className="w-3 h-3 text-red-500" />
                        <span className="font-bold text-[10px] text-red-600 uppercase">Fault</span>
                    </div>
                ) : isRunning ? (
                    <div className="flex items-center justify-center gap-1.5 mb-2 px-3 py-1 rounded-xl bg-emerald-50 border border-emerald-200">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                        <span className="font-bold text-[10px] text-emerald-600 uppercase">Running</span>
                    </div>
                ) : (
                    <div className="flex items-center justify-center gap-1.5 mb-2 px-3 py-1 rounded-xl bg-slate-50 border border-slate-200">
                        <span className="font-bold text-[10px] text-slate-400 uppercase">Offline</span>
                    </div>
                )}

                {/* Current metric — always rendered */}
                <motion.div
                    animate={isRunning && !isFault ? { opacity: [1, 0.8, 1] } : {}}
                    transition={{ repeat: Infinity, duration: 2 }}
                    className={cn(
                        "px-3 py-2 rounded-xl border mb-2",
                        isFault ? "bg-red-50 border-red-200"
                            : isRunning ? "bg-emerald-500/10 border-emerald-500/30"
                                : "bg-slate-50 border-slate-200"
                    )}
                >
                    <div className={cn(
                        "flex items-center gap-2",
                        isFault ? "text-red-400" : isRunning ? "text-emerald-600" : "text-slate-400"
                    )}>
                        <Zap className="w-4 h-4" />
                        <span className="text-xs uppercase tracking-wide">Current</span>
                    </div>
                    <span className={cn(
                        "text-lg font-bold font-mono",
                        isFault ? "text-red-400" : isRunning ? "text-emerald-600" : "text-slate-400"
                    )}>
                        {isRunning && !isFault ? `${Number(activeCurrent).toFixed(2)} A` : '— A'}
                    </span>
                </motion.div>

                {/* Frequency metric — always rendered */}
                <motion.div
                    animate={isRunning && !isFault ? { opacity: [1, 0.85, 1] } : {}}
                    transition={{ repeat: Infinity, duration: 2, delay: 0.5 }}
                    className={cn(
                        "px-3 py-2 rounded-xl border",
                        isFault ? "bg-red-50 border-red-200"
                            : isRunning ? "bg-cyan-500/10 border-cyan-500/30"
                                : "bg-slate-50 border-slate-200"
                    )}
                >
                    <div className={cn(
                        "flex items-center gap-2",
                        isFault ? "text-red-400" : isRunning ? "text-cyan-600" : "text-slate-400"
                    )}>
                        <Activity className="w-4 h-4" />
                        <span className="text-xs uppercase tracking-wide">Frequency</span>
                    </div>
                    <span className={cn(
                        "text-lg font-bold font-mono",
                        isFault ? "text-red-400" : isRunning ? "text-cyan-600" : "text-slate-400"
                    )}>
                        {isRunning && !isFault ? `${Number(activeFrequency).toFixed(1)} Hz` : '— Hz'}
                    </span>
                </motion.div>
            </div>
        </div>
    );
}

// ─── Enhanced Pipe (Light Theme) ─────────────────────────────────────────────

export function Pipe({ active, vertical = false, length = 100 }) {
    const baseStyle = vertical
        ? { width: '24px', height: `${length}px` }
        : { height: '24px', width: `${length}px` };

    return (
        <div
            style={baseStyle}
            className={`relative rounded-sm border shadow-[inset_0_1px_3px_rgba(0,0,0,0.05)] overflow-hidden transition-colors duration-500 ${active ? 'bg-cyan-50 border-cyan-200' : 'bg-slate-100 border-slate-300'
                }`}
        >
            {/* Pipe Glass/Glare Reflection */}
            <div className={cn(
                "absolute bg-linear-to-b from-white/80 to-transparent pointer-events-none z-20",
                vertical ? "inset-y-0 left-1 w-1.5" : "inset-x-0 top-1 h-1.5"
            )} />

            {active && (
                <>
                    {/* Base fluid glow for light mode */}
                    <div className="absolute inset-0 bg-cyan-400/10 z-0" />

                    {/* Framer Motion Animated Flow Lines */}
                    <motion.div
                        className="absolute inset-0 opacity-70 z-10"
                        style={{
                            backgroundImage: vertical
                                ? 'linear-gradient(to bottom, transparent 40%, rgba(6, 182, 212, 0.5) 40%, rgba(6, 182, 212, 0.5) 60%, transparent 60%)'
                                : 'linear-gradient(to right, transparent 40%, rgba(6, 182, 212, 0.5) 40%, rgba(6, 182, 212, 0.5) 60%, transparent 60%)',
                            backgroundSize: vertical ? '100% 24px' : '24px 100%',
                        }}
                        animate={{
                            backgroundPosition: vertical ? ['0px 0px', '0px 24px'] : ['0px 0px', '24px 0px']
                        }}
                        transition={{ repeat: Infinity, duration: 0.6, ease: "linear" }}
                    />
                </>
            )}
        </div>
    );
}

// ─── Pipe Joint (Light Theme) ────────────────────────────────────────────────

export function PipeJoint({ active, style }) {
    return (
        <div
            className={`absolute z-20 w-8 h-8 -ml-1 -mt-1 rounded border shadow-sm flex items-center justify-center transition-colors duration-500 ${active ? 'bg-cyan-50 border-cyan-300' : 'bg-slate-100 border-slate-300'
                }`}
            style={style}
        >
            {/* Inner mechanical bolt/dot */}
            <div className={`w-3 h-3 rounded-full transition-all duration-500 shadow-inner ${active
                    ? 'bg-cyan-500 shadow-[0_0_8px_rgba(6,182,212,0.4)]'
                    : 'bg-slate-300'
                }`} />
        </div>
    );
}
// ─── StatusBadge ─────────────────────────────────────────────────────────────

export function StatusBadge({ status }) {
    const styles = {
        ONLINE:      "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
        OFFLINE:     "bg-slate-500/10 text-slate-400 border-slate-500/20",
        FAULT:       "bg-red-500/10 text-red-400 border-red-500/20 animate-pulse",
        MAINTENANCE: "bg-amber-500/10 text-amber-400 border-amber-500/20",
    };
    return (
        <span className={cn("px-2 py-0.5 rounded text-[10px] font-bold border tracking-wider uppercase", styles[status] ?? styles.OFFLINE)}>
            {status}
        </span>
    );
}

// ─── MetricCard ──────────────────────────────────────────────────────────────

export function MetricCard({ label, value, unit, icon: Icon, trend }) { // eslint-disable-line no-unused-vars
    return (
        <div className="bg-white border border-slate-200 p-4 rounded-lg relative overflow-hidden group shadow-sm">
            <div className="absolute top-0 right-0 p-2 opacity-10 group-hover:opacity-20 transition-opacity">
                <Icon className="w-12 h-12" />
            </div>
            <div className="flex items-center gap-3">
                <div className="p-2 rounded bg-slate-100 border border-slate-200">
                    <Icon className="w-5 h-5 text-cyan-600" />
                </div>
                <div>
                    <p className="text-xs text-slate-500 uppercase tracking-wider">{label}</p>
                    <div className="flex items-baseline gap-1">
                        <span className="text-2xl font-mono font-bold text-slate-800">{value}</span>
                        <span className="text-xs text-slate-500">{unit}</span>
                    </div>
                </div>
            </div>
            {trend != null && (
                <div className={cn("text-xs mt-2 font-mono flex items-center gap-1", trend > 0 ? "text-emerald-600" : "text-red-600")}>
                    {trend > 0 ? "+" : ""}{trend}% <span className="text-slate-500">vs last hr</span>
                </div>
            )}
        </div>
    );
}

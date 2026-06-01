// src/components/RightDrawer.jsx
import React from 'react';
import { motion as Motion } from 'framer-motion';
import { X } from 'lucide-react';

/**
 * Shared right-side overlay drawer shell.
 *
 * Props:
 *  - onClose       : () => void  — called when backdrop or X is clicked
 *  - title         : string
 *  - subtitle      : string | ReactNode
 *  - icon          : ReactNode   — icon element shown in the header badge
 *  - footer        : ReactNode   — pinned footer area (buttons etc.)
 *  - children      : ReactNode   — scrollable body content
 *  - zClass        : string      — Tailwind z-index class (default 'z-50')
 *  - maxWidth      : string      — Tailwind max-w class (default 'max-w-md')
 */
export default function RightDrawer({
    onClose,
    title,
    subtitle,
    icon,
    footer,
    children,
    zClass = 'z-50',
    maxWidth = 'max-w-md',
}) {
    return (
        <div
            className={`fixed inset-0 ${zClass} flex items-stretch justify-end bg-slate-950/40 backdrop-blur-sm`}
            onClick={onClose}
        >
            <Motion.div
                initial={{ x: '100%' }}
                animate={{ x: 0 }}
                exit={{ x: '100%' }}
                transition={{ type: 'spring', stiffness: 320, damping: 32 }}
                className={`relative flex flex-col w-full ${maxWidth} h-full bg-white border-l border-slate-200 shadow-2xl`}
                onClick={(e) => e.stopPropagation()}
            >
                {/* ── Header ── */}
                <div className="px-5 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/60 shrink-0">
                    <div className="flex items-center gap-3">
                        {icon && (
                            <div className="p-2 bg-white rounded-xl shadow-sm border border-slate-100">
                                {icon}
                            </div>
                        )}
                        <div>
                            {title && <p className="text-sm font-bold text-slate-800">{title}</p>}
                            {subtitle && <p className="text-[11px] text-slate-400 font-mono">{subtitle}</p>}
                        </div>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-1.5 text-slate-400 hover:text-slate-700 hover:bg-slate-200/50 rounded-lg transition-colors"
                        aria-label="Close"
                    >
                        <X className="w-4 h-4" />
                    </button>
                </div>

                {/* ── Body ── */}
                <div className="flex-1 overflow-hidden flex flex-col min-h-0">
                    {children}
                </div>

                {/* ── Footer ── */}
                {footer && (
                    <div className="px-5 py-3 border-t border-slate-100 bg-slate-50/60 shrink-0">
                        {footer}
                    </div>
                )}
            </Motion.div>
        </div>
    );
}

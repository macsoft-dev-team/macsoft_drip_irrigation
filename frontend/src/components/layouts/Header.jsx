import React from 'react';
import { Menu, LogOut, ShieldCheck, Shield, User } from 'lucide-react';
import { useLocation } from 'react-router-dom';
import { ROLES } from '../../hooks/useRole';

const PAGE_TITLES = {
    '/devices': { breadcrumb: 'Master', title: 'Devices Overview' },
    '/users': { breadcrumb: 'Master', title: 'User Management' },
};

const ROLE_META = {
    [ROLES.MACSOFT_ADMIN]: { label: 'Super Admin', color: 'bg-rose-50 text-rose-600 border-rose-200', Icon: ShieldCheck },
    [ROLES.MACSOFT_USER]: { label: 'Super User', color: 'bg-orange-50 text-orange-600 border-orange-200', Icon: Shield },
    [ROLES.CUSTOMER_ADMIN]: { label: 'Admin', color: 'bg-violet-50 text-violet-600 border-violet-200', Icon: Shield },
    [ROLES.CUSTOMER_USER]: { label: 'User', color: 'bg-slate-50 text-slate-500 border-slate-200', Icon: User },
    [ROLES.END_USER]: { label: 'End User', color: 'bg-slate-50 text-slate-500 border-slate-200', Icon: User },
};

export default function Header({ setIsMobileOpen, onLogout, user }) {
    const location = useLocation();
    const page = PAGE_TITLES[location.pathname] || { breadcrumb: 'Master', title: 'Dashboard' };
    const roleMeta = ROLE_META[user?.role] || ROLE_META[ROLES.END_USER];
    const RoleIcon = roleMeta.Icon;

    return (
        <header className="h-16 bg-white/80 backdrop-blur-md border-b border-slate-200 flex items-center justify-between px-4 md:px-8 z-10 shrink-0 shadow-[0_2px_10px_rgb(0,0,0,0.02)]">
            {/* Left side: Mobile Menu Toggle & Breadcrumbs */}
            <div className="flex items-center gap-3">
                <button
                    onClick={() => setIsMobileOpen(true)}
                    className="md:hidden p-2 text-slate-500 hover:bg-slate-100 hover:text-slate-700 rounded-xl transition-colors border border-transparent hover:border-slate-200"
                >
                    <Menu className="w-5 h-5" />
                </button>

                {/* Page Breadcrumb / Title for Desktop */}
                <div className="hidden md:flex items-center gap-2 text-sm font-medium text-slate-500">
                    <span className="hover:text-slate-800 cursor-pointer transition-colors">{page.breadcrumb}</span>
                    <span className="text-slate-300">/</span>
                    <span className="text-slate-800 font-bold tracking-tight">{page.title}</span>
                </div>
            </div>

            {/* Right side: Role badge + Logout */}
            <div className="flex items-center gap-3 md:gap-4">
                {/* Role badge */}
                <span className={`hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-[11px] font-bold uppercase tracking-wider border ${roleMeta.color}`}>
                    <RoleIcon className="w-3.5 h-3.5" />
                    {roleMeta.label}
                </span>

                <div className="h-8 w-px bg-slate-200 hidden sm:block"></div>

                <button
                    onClick={onLogout}
                    className="flex items-center gap-2 text-sm font-bold text-slate-600 hover:text-rose-600 hover:bg-rose-50 px-4 py-2.5 rounded-xl transition-all border border-transparent hover:border-rose-100"
                >
                    <LogOut className="w-4 h-4" />
                    <span className="hidden sm:inline">Logout</span>
                </button>
            </div>
        </header>
    );
}
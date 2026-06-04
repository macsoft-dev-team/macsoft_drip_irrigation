import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Users, Building2, X, ShieldCheck, Shield, User, Grid } from 'lucide-react';
import { useRole, ROLES } from '../../hooks/useRole';

const ROLE_BADGE = {
    [ROLES.MACSOFT_ADMIN]: { label: 'Super Admin', color: 'text-indigo-700', bg: 'bg-indigo-50', Icon: ShieldCheck },
    [ROLES.ADMIN]: { label: 'Admin', color: 'text-blue-700', bg: 'bg-blue-50', Icon: Shield },
    [ROLES.USER]: { label: 'User', color: 'text-slate-600', bg: 'bg-slate-100', Icon: User },
};

const SidebarHeader = ({ onClose }) => (
    <div className="h-16 flex items-center justify-between px-5 border-b border-slate-200 shrink-0">
        <div className="flex items-center gap-3">
            <div className="w-8 h-8 flex items-center justify-center">
                <img src="/macsoft-logo.png" alt="HNS" className="w-7 h-7 drop-shadow-2xl"  />
            </div>
            <span className="text-[1.15rem] font-bold text-slate-900 tracking-tight">
               HNS<span className="font-semibold text-blue-600 ml-1">Portal</span>
            </span>
        </div>
        <button onClick={onClose} className="md:hidden p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-900 rounded transition-colors">
            <X className="w-5 h-5" />
        </button>
    </div>
);

const SidebarNavItem = ({ icon: Icon, label, path, isActive, onClick, rightElement }) => (
    <Link
        to={path}
        onClick={onClick}
        className={`w-full flex items-center justify-between px-4 py-2.5 text-sm transition-all duration-200 group border-l-[3px] ${
            isActive
                ? 'bg-blue-50/50 border-blue-600 text-blue-700 font-medium'
                : 'border-transparent text-slate-600 hover:bg-slate-50 hover:text-slate-900'
        }`}
    >
        <div className="flex items-center gap-3">
            <Icon className={`w-4 h-4 transition-colors ${isActive ? 'text-blue-600' : 'text-slate-400 group-hover:text-slate-500'}`} />
            <span>{label}</span>
        </div>
        {rightElement && rightElement}
    </Link>
);

const SidebarProfile = ({ user }) => {
    const roleMeta = ROLE_BADGE[user?.role] || ROLE_BADGE[ROLES.USER];
    const RoleIcon = roleMeta.Icon;
    const name = user?.name || 'User';
    const initials = name.split(' ').map((n) => n[0]).join('').slice(0, 2).toUpperCase();

    return (
        <div className="p-4 border-t border-slate-200 bg-slate-50/80 shrink-0">
            <div className="flex items-center gap-3 p-1.5 rounded-lg hover:bg-white hover:shadow-sm hover:ring-1 hover:ring-slate-200 transition-all cursor-pointer">
                <div className="w-9 h-9 rounded bg-blue-100 flex items-center justify-center text-blue-700 font-bold text-xs shrink-0">
                    {initials}
                </div>
                <div className="flex-1 overflow-hidden">
                    <p className="text-sm font-semibold text-slate-900 truncate leading-tight">{name}</p>
                    <div className="mt-0.5">
                        <span className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-bold tracking-wide uppercase ${roleMeta.bg} ${roleMeta.color}`}>
                            <RoleIcon className="w-3 h-3" />
                            {roleMeta.label}
                        </span>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default function Sidebar({ isMobileOpen, setIsMobileOpen, user }) {
    const location = useLocation();
    const { canManageUsers, isMacsoftAdmin } = useRole();

    const navItems = [
        {
            groupLabel: 'Main Menu',
            items: [
                {
                    id: 'devices',
                    label: 'Device Registry',
                    path: '/devices',
                    icon: LayoutDashboard,                 
                },
                {
                    id: 'irrigation',
                    label: 'Irrigation Layout',
                    path: '/irrigation',
                    icon: Grid,
                },
                ...(canManageUsers()
                    ? [{
                        id: 'users',
                        label: 'Access Control',
                        path: '/users',
                        icon: Users,
                    }]
                    : []),
                ...(isMacsoftAdmin()
                    ? [{
                        id: 'customers',
                        label: 'Customers',
                        path: '/customers',
                        icon: Building2,
                    }]
                    : []),
            ],
        },
    ];

    return (
        <aside
            className={`fixed inset-y-0 left-0 z-50 w-64 bg-white border-r border-slate-200 flex flex-col transform transition-transform duration-300 ease-in-out md:relative md:translate-x-0 ${
                isMobileOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full'
            }`}
        >
            <SidebarHeader onClose={() => setIsMobileOpen(false)} />

            <nav className="flex-1 py-4 overflow-y-auto">
                {navItems.map((group, groupIndex) => (
                    <div key={groupIndex} className={groupIndex > 0 ? 'mt-6' : ''}>
                        <p className="px-5 text-xs font-semibold text-slate-400 mb-2">
                            {group.groupLabel}
                        </p>
                        <div className="space-y-0.5">
                            {group.items.map((item) => (
                                <SidebarNavItem
                                    key={item.id}
                                    icon={item.icon}
                                    label={item.label}
                                    path={item.path}
                                    isActive={location.pathname.startsWith(item.path)}
                                    onClick={() => setIsMobileOpen(false)}
                                    rightElement={item.rightElement}
                                />
                            ))}
                        </div>
                    </div>
                ))}
            </nav>

            <SidebarProfile user={user} />
        </aside>
    );
}
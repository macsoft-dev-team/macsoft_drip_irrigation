import React from 'react';
import { Navigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { useRole } from '../hooks/useRole';
import { ShieldOff } from 'lucide-react';

/**
 * Wraps a route and enforces role-based access.
 *
 * Props:
 *  - allowedRoles: string[]  – roles that may access this route
 *  - redirectTo: string      – where to send unauthenticated users (default /login)
 *  - children: ReactNode
 */
export default function ProtectedRoute({ allowedRoles = [], redirectTo = '/login', children }) {
    const { isAuthenticated } = useSelector((state) => state.auth);
    const { role } = useRole();

    if (!isAuthenticated) {
        return <Navigate to={redirectTo} replace />;
    }

    if (allowedRoles.length > 0 && !allowedRoles.includes(role)) {
        return (
            <div className="flex flex-col items-center justify-center flex-1 h-full gap-4 text-slate-400 py-32">
                <ShieldOff className="w-12 h-12 text-slate-300" />
                <p className="text-lg font-bold text-slate-600">Access Denied</p>
                <p className="text-sm font-medium">
                    You don&apos;t have permission to view this page.
                </p>
            </div>
        );
    }

    return children;
}

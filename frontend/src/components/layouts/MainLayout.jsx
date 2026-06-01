import { useState } from 'react';
import Sidebar from './Sidebar';
import Header from './Header';

export default function MainLayout({ children, onLogout, user }) {
    const [isMobileOpen, setIsMobileOpen] = useState(false);

    return (
        <div
            className="min-h-screen bg-[#f8fafc] flex antialiased overflow-hidden relative selection:bg-blue-200 selection:text-blue-900"
            style={{ fontFamily: "'Plus Jakarta Sans', sans-serif" }}
        >
            {/* Mobile Backdrop Overlay with Blur */}
            {isMobileOpen && (
                <div
                    className="fixed inset-0 bg-slate-950/60 backdrop-blur-sm z-40 md:hidden transition-opacity"
                    onClick={() => setIsMobileOpen(false)}
                />
            )}

            <Sidebar
                isMobileOpen={isMobileOpen}
                setIsMobileOpen={setIsMobileOpen}
                user={user}
            />

            {/* Main Content Area */}
            <div className="flex-1 flex flex-col min-w-0 h-screen overflow-hidden">
                <Header
                    setIsMobileOpen={setIsMobileOpen}
                    onLogout={onLogout}
                    user={user}
                />

                {/* Page Content */}
                <main className="flex-1 overflow-y-auto pb-10">
                    {children}
                </main>
            </div>
        </div>
    );
}
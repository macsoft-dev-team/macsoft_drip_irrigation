import { useEffect } from 'react';
import './App.css';
import { Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { useSelector, useDispatch } from 'react-redux';
import { setStoreForInterceptor } from './configs/api';
import store from './store';

import { DeviceDashboard, LoginPage, UsersPage, AddDevice, DeviceDetailPage, CustomersPage } from './pages';
import { MainLayout, ProtectedRoute } from './components';
import { SocketProvider } from './contexts/SocketContext';
import { logout } from './reducers/authSlice';
import { ROLES } from './hooks/useRole';

const ADMIN_ROLES = [ROLES.MACSOFT_ADMIN, ROLES.CUSTOMER_ADMIN];
const ALL_ROLES = [ROLES.MACSOFT_ADMIN, ROLES.MACSOFT_USER, ROLES.CUSTOMER_ADMIN, ROLES.CUSTOMER_USER, ROLES.END_USER];

function AppRoutes() {
    const dispatch = useDispatch();
    const { isAuthenticated, user } = useSelector((s) => s.auth);
    const navigate = useNavigate();

    const handleLogout = () => {
        dispatch(logout());
        navigate('/login', { replace: true });
    };

    if (!isAuthenticated) {
        return (
            <Routes>
                <Route path="/login" element={<LoginPage />} />
                <Route path="*" element={<Navigate to="/login" replace />} />
            </Routes>
        );
    }

    return (
        <SocketProvider>
            <MainLayout onLogout={handleLogout} user={user}>
                <Routes>
                    <Route
                        path="/devices/new"
                        element={
                            <ProtectedRoute allowedRoles={ADMIN_ROLES}>
                                <AddDevice />
                            </ProtectedRoute>
                        }
                    />
                    <Route
                        path="/devices/:id"
                        element={
                            <ProtectedRoute allowedRoles={ALL_ROLES}>
                                <DeviceDetailPage />
                            </ProtectedRoute>
                        }
                    />
                    <Route
                        path="/devices"
                        element={
                            <ProtectedRoute allowedRoles={ALL_ROLES}>
                                <DeviceDashboard />
                            </ProtectedRoute>
                        }
                    />
                    <Route
                        path="/users"
                        element={
                            <ProtectedRoute allowedRoles={ADMIN_ROLES}>
                                <UsersPage />
                            </ProtectedRoute>
                        }
                    />
                    <Route
                        path="/customers"
                        element={
                            <ProtectedRoute allowedRoles={[ROLES.MACSOFT_ADMIN]}>
                                <CustomersPage />
                            </ProtectedRoute>
                        }
                    />
                    <Route path="*" element={<Navigate to="/devices" replace />} />
                </Routes>
            </MainLayout>
        </SocketProvider>
    );
}

function App() {
    useEffect(() => {
        setStoreForInterceptor(store);
    }, []);

    return (
        <>
            <AppRoutes />
            <Toaster
                position="top-right"
                toastOptions={{
                    duration: 4000,
                    style: { fontSize: '13px', fontWeight: 600 },
                    success: { iconTheme: { primary: '#10b981', secondary: '#fff' } },
                    error: { iconTheme: { primary: '#ef4444', secondary: '#fff' } },
                }}
            />
        </>
    );
}

export default App;
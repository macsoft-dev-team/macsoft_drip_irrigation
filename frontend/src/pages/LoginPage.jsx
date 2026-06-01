import React, { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
// Swapped 'Mail' for 'User' to better represent a generic login identifier
import { Server, User, Lock, Loader2, AlertCircle, ShieldCheck } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { useNavigate } from 'react-router-dom';

import { useAuth } from '../hooks';

// --- 1. Define Regex Patterns for Validation ---
const emailRegExp = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
// Matches basic international and domestic phone formats
const phoneRegExp = /^\+?[0-9\s\-()]{7,15}$/;

// --- 2. Update Yup Validation Schema ---
const loginSchema = yup.object().shape({
    identifier: yup.string()
        .required('Email or phone number is required.')
        .test('is-email-or-phone', 'Please enter a valid email or phone number.', (value) => {
            if (!value) return false;
            return emailRegExp.test(value) || phoneRegExp.test(value);
        }),
    password: yup.string()
        .min(8, 'Password must be at least 8 characters.')
        .required('Password is required.'),
    rememberMe: yup.boolean()
});

export default function LoginPage() {
    const navigate = useNavigate();
    const { login, loading, error, isAuthenticated } = useAuth();

    // --- 3. Initialize React Hook Form ---
    const {
        register,
        handleSubmit,
        formState: { errors }
    } = useForm({
        resolver: yupResolver(loginSchema),
        defaultValues: { identifier: '', password: '', rememberMe: false }
    });

    useEffect(() => {
        if (isAuthenticated) {
            navigate('/devices', { replace: true });
        }
    }, [isAuthenticated, navigate]);

    // --- 4. Handle Form Submission ---
    const onSubmit = (data) => {
        // Map 'identifier' to 'any' as expected by the backend API
        login({ any: data.identifier, password: data.password });
    };

    return (
        <div className="min-h-screen w-full flex bg-white font-sans antialiased text-slate-900" style={{ fontFamily: "'Plus Jakarta Sans', sans-serif" }}>

            {/* Left Side - Enterprise Branding */}
            <div className="hidden lg:flex w-1/2 bg-slate-950 relative overflow-hidden flex-col justify-between p-12 lg:p-20 border-r border-slate-800">
                <div className="absolute top-0 left-0 w-full h-full overflow-hidden z-0 opacity-20 pointer-events-none">
                    <div className="absolute -top-[20%] -left-[10%] w-[70%] h-[70%] rounded-full bg-blue-600 blur-[120px]" />
                    <div className="absolute bottom-[10%] right-[10%] w-[50%] h-[50%] rounded-full bg-emerald-600 blur-[120px]" />
                    <div className="absolute inset-0 bg-[linear-gradient(to_right,#1e293b_1px,transparent_1px),linear-gradient(to_bottom,#1e293b_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_50%,#000_70%,transparent_100%)]" />
                </div>

                <div className="relative z-10 flex items-center gap-3">
                    <div className="p-2.5  rounded-xl shadow-[0_0_20px_rgba(37,99,235,0.4)]">
                        <img src="/macsoft-logo.png" alt="HNS Logo" className="w-8 h-8" />
                    </div>
                    <span className="text-2xl font-extrabold text-white tracking-tight">HNS<span className="text-blue-400 font-semibold"></span></span>
                </div>

                <div className="relative z-10 max-w-lg">
                    <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }}>
                        <h2 className="text-4xl font-extrabold text-white leading-tight tracking-tight mb-6">
                            Real-time <br />
                            <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-emerald-400">
                                operations.
                            </span>
                        </h2>
                        <p className="text-slate-400 text-lg leading-relaxed mb-8 font-medium">
                            Monitor machine health, track power consumption, and control remote assets with millisecond latency and military-grade encryption.
                        </p>
                    </motion.div>
                </div>

                <div className="relative z-10 flex items-center gap-4 text-sm text-slate-500 font-bold tracking-wide">
                    <span>© {new Date().getFullYear()} Macsoft Automations</span>
                </div>
            </div>

            {/* Right Side - Login Form */}
            <div className="w-full lg:w-1/2 flex items-center justify-center p-6 sm:p-12 relative">
                <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.5, ease: "easeOut" }} className="w-full max-w-[420px]">
                    <div className="mb-10">
                        <h1 className="text-3xl font-extrabold text-slate-900 tracking-tight mb-2">Welcome back</h1>
                        <p className="text-slate-500 font-semibold">Please enter your credentials to access the secure dashboard.</p>
                    </div>

                    <AnimatePresence>
                        {error && (
                            <motion.div initial={{ opacity: 0, height: 0, mb: 0 }} animate={{ opacity: 1, height: 'auto', mb: 24 }} exit={{ opacity: 0, height: 0, mb: 0 }} className="p-4 bg-rose-50 border border-rose-100 rounded-xl flex items-start gap-3 text-rose-700 text-sm font-bold shadow-sm overflow-hidden">
                                <AlertCircle className="w-5 h-5 shrink-0 mt-0.5 text-rose-600" />
                                <p>{error}</p>
                            </motion.div>
                        )}
                    </AnimatePresence>

                    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">

                        {/* --- Updated Identifier Field --- */}
                        <div className="space-y-2">
                            <label className="text-sm font-extrabold text-slate-700 tracking-wide">Email or Phone</label>
                            <div className="relative group">
                                <div className={`absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none transition-colors ${errors.identifier ? 'text-rose-500' : 'group-focus-within:text-blue-600 text-slate-400'}`}>
                                    <User className="h-5 w-5" />
                                </div>
                                <input
                                    type="text"
                                    {...register('identifier')}
                                    className={`block w-full pl-11 pr-4 py-3 border rounded-xl bg-slate-50 text-slate-900 placeholder-slate-400 font-semibold focus:outline-none focus:ring-2 focus:bg-white transition-all sm:text-sm ${errors.identifier ? 'border-rose-500 focus:ring-rose-500/20' : 'border-slate-200 focus:ring-blue-600/20 focus:border-blue-600'
                                        }`}
                                    placeholder="admin@macsoft.com or 9876543210"
                                />
                            </div>
                            <AnimatePresence>
                                {errors.identifier && (
                                    <motion.p initial={{ opacity: 0, y: -5 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -5 }} className="text-sm font-bold text-rose-500 mt-1">
                                        {errors.identifier.message}
                                    </motion.p>
                                )}
                            </AnimatePresence>
                        </div>

                        {/* Password Field */}
                        <div className="space-y-2">
                            <div className="flex items-center justify-between">
                                <label className="text-sm font-extrabold text-slate-700 tracking-wide">Password</label>
                                <a href="#" className="text-sm font-bold text-blue-600 hover:text-blue-700 transition-colors">Forgot password?</a>
                            </div>
                            <div className="relative group">
                                <div className={`absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none transition-colors ${errors.password ? 'text-rose-500' : 'group-focus-within:text-blue-600 text-slate-400'}`}>
                                    <Lock className="h-5 w-5" />
                                </div>
                                <input
                                    type="password"
                                    {...register('password')}
                                    className={`block w-full pl-11 pr-4 py-3 border rounded-xl bg-slate-50 text-slate-900 placeholder-slate-400 font-semibold focus:outline-none focus:ring-2 focus:bg-white transition-all sm:text-sm ${errors.password ? 'border-rose-500 focus:ring-rose-500/20' : 'border-slate-200 focus:ring-blue-600/20 focus:border-blue-600'
                                        }`}
                                    placeholder="••••••••"
                                />
                            </div>
                            <AnimatePresence>
                                {errors.password && (
                                    <motion.p initial={{ opacity: 0, y: -5 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -5 }} className="text-sm font-bold text-rose-500 mt-1">
                                        {errors.password.message}
                                    </motion.p>
                                )}
                            </AnimatePresence>
                        </div>

                        {/* Remember Me Toggle */}
                        <div className="flex items-center pt-2">
                            <input
                                id="rememberMe"
                                type="checkbox"
                                {...register('rememberMe')}
                                className="h-4 w-4 text-blue-600 focus:ring-blue-600 border-slate-300 rounded cursor-pointer"
                            />
                            <label htmlFor="rememberMe" className="ml-2.5 block text-sm font-bold text-slate-600 cursor-pointer select-none">
                                Keep me logged in
                            </label>
                        </div>

                        {/* Submit Button */}
                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full flex justify-center items-center gap-2 py-3.5 px-4 border border-transparent rounded-xl shadow-[0_4px_14px_0_rgba(37,99,235,0.2)] hover:shadow-[0_6px_20px_rgba(37,99,235,0.23)] text-sm font-extrabold text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-600 disabled:opacity-70 disabled:cursor-not-allowed transition-all"
                        >
                            {loading ? (
                                <><Loader2 className="w-5 h-5 animate-spin" /> Authenticating...</>
                            ) : (
                                <><ShieldCheck className="w-5 h-5" /> Secure Sign In</>
                            )}
                        </button>
                    </form>
                </motion.div>
            </div>
        </div>
    );
}
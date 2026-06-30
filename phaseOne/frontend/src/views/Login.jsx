import React, { useState } from 'react';
import { Leaf, ArrowLeft, KeyRound, MailCheck } from 'lucide-react';
import plant from '../../src/assets/drip_img.jpg';

export default function Login({ onLogin }) {
    const [mode, setMode] = useState("login"); // login, forgot, reset
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [username, setUsername] = useState("");
    const [message, setMessage] = useState("");

    const handleSubmit = (e) => {
        e.preventDefault();
        if (mode === "login") {
            if (onLogin) {
                onLogin(username, password);
            }
        } else if (mode === "forgot") {
            setMessage("A reset link has been sent to your email address.");
            setTimeout(() => {
                setMode("reset");
                setMessage("");
            }, 2000);
        } else if (mode === "reset") {
            setMessage("Password reset successfully. Redirecting to login...");
            setTimeout(() => {
                setMode("login");
                setMessage("");
            }, 2000);
        }
    };

    return (
        <div className="h-screen w-full bg-[#f4f7f4] flex items-center justify-center p-4 md:p-8 font-sans overflow-hidden">

            {/* Main Container */}
            <div className="w-full max-w-5xl h-[95vh] md:h-full max-h-[750px] flex flex-col md:flex-row shadow-2xl rounded-3xl overflow-hidden bg-white">

                {/* Left Side - Green Banner */}
                <div className="w-full md:w-1/2 h-2/5 md:h-full bg-[#5d8a4d] p-6 md:p-8 relative flex flex-col items-center justify-center overflow-hidden">

                    {/* Decorative Dot Pattern (Top Left) */}
                    <div className="hidden md:grid absolute top-12 left-12 grid-cols-4 gap-2 opacity-50">
                        {[...Array(16)].map((_, i) => (
                            <div key={i} className="w-1.5 h-1.5 bg-white rounded-full"></div>
                        ))}
                    </div>

                    {/* Decorative Curved Lines (Bottom Right) */}
                    <svg className="hidden md:block absolute -bottom-16 -right-16 w-64 h-64 text-white opacity-10" viewBox="0 0 100 100" fill="none">
                        <circle cx="50" cy="50" r="40" stroke="currentColor" strokeWidth="8" />
                        <circle cx="50" cy="50" r="60" stroke="currentColor" strokeWidth="8" />
                    </svg>

                    <div className="z-10 text-center mb-6 md:mb-10 w-full mt-2 md:mt-8">
                        <h1 className="text-white text-2xl md:text-3xl font-bold tracking-wide mb-2 md:mb-3">
                            Smart Drip Admin
                        </h1>
                        <p className="text-[#cde0c5] text-xs md:text-sm tracking-wider">
                            Advanced Drip Irrigation & IoT Commissioning
                        </p>
                    </div>

                    {/* Plant Image Circle */}
                    <div className="relative w-32 h-32 md:w-72 md:h-72 rounded-full bg-white flex items-center justify-center shadow-xl z-10 border-4 md:border-8 border-transparent flex-shrink-0">
                        <img
                            src={plant}
                            alt="Potted Plant"
                            className="w-full h-full object-cover rounded-full"
                        />
                    </div>
                </div>

                {/* Right Side - Login Form */}
                <div className="w-full md:w-1/2 h-3/5 md:h-full bg-[#eef3eb] p-6 md:p-16 flex flex-col justify-center overflow-hidden">
                    <div className="w-full max-w-sm mx-auto">

                        {/* Logo Section */}
                        <div className="flex items-center gap-2 mb-6 md:mb-8 text-[#5d8a4d]">
                            <Leaf className="h-6 w-6 fill-current" />
                            <span className="font-bold text-xl tracking-tight">Smart Drip SaaS</span>
                        </div>

                        {mode === "login" && (
                            <>
                                <h2 className="text-2xl md:text-3xl font-bold text-gray-900 mb-6 md:mb-8 leading-tight">
                                    Sign in to<br />the Admin Panel
                                </h2>

                                <form className="space-y-4 md:space-y-5 w-full" onSubmit={handleSubmit}>
                                    <div className="space-y-1">
                                        <label className="block text-xs font-medium text-gray-500 ml-1">
                                            User Name / Email
                                        </label>
                                        <input
                                            type="text"
                                            required
                                            value={username}
                                            onChange={(e) => setUsername(e.target.value)}
                                            placeholder="admin@dripirrigation.com"
                                            className="w-full px-4 py-3 bg-white rounded-xl border border-transparent focus:border-[#628f52] focus:ring-2 focus:ring-[#cde0c5] text-sm text-gray-800 placeholder:text-gray-400 outline-none shadow-sm font-medium transition-all"
                                        />
                                    </div>

                                    <div className="space-y-1">
                                        <label className="block text-xs font-medium text-gray-500 ml-1">
                                            Password
                                        </label>
                                        <input
                                            type="password"
                                            required
                                            value={password}
                                            onChange={(e) => setPassword(e.target.value)}
                                            placeholder="••••••••"
                                            className="w-full px-4 py-3 bg-white rounded-xl border border-transparent focus:border-[#628f52] focus:ring-2 focus:ring-[#cde0c5] text-sm text-gray-800 placeholder:text-gray-400 outline-none shadow-sm font-medium tracking-widest transition-all"
                                        />
                                    </div>

                                    <div className="flex justify-end">
                                        <button 
                                            type="button" 
                                            onClick={() => setMode("forgot")}
                                            className="text-xs text-[#5d8a4d] hover:underline font-semibold"
                                        >
                                            Forgot Password?
                                        </button>
                                    </div>

                                    <button
                                        type="submit"
                                        className="w-full bg-[#628f52] hover:bg-[#4f7342] rounded-xl text-white font-semibold py-3 transition-colors shadow-md active:scale-[0.98]"
                                    >
                                        Login
                                    </button>
                                </form>
                            </>
                        )}

                        {mode === "forgot" && (
                            <>
                                <button 
                                    onClick={() => setMode("login")}
                                    className="flex items-center gap-1 text-xs text-gray-500 hover:text-gray-800 font-semibold mb-4"
                                >
                                    <ArrowLeft className="h-3.5 w-3.5" />
                                    Back to Login
                                </button>
                                
                                <h2 className="text-2xl font-bold text-gray-900 mb-2 leading-tight">
                                    Forgot Password
                                </h2>
                                <p className="text-xs text-gray-500 mb-6">
                                    Enter your registered email address and we'll send you a password reset link.
                                </p>

                                <form className="space-y-4 w-full" onSubmit={handleSubmit}>
                                    <div className="space-y-1">
                                        <label className="block text-xs font-medium text-gray-500 ml-1">
                                            Email Address
                                        </label>
                                        <input
                                            type="email"
                                            required
                                            value={email}
                                            onChange={(e) => setEmail(e.target.value)}
                                            placeholder="admin@dripirrigation.com"
                                            className="w-full px-4 py-3 bg-white rounded-xl border border-transparent focus:border-[#628f52] focus:ring-2 focus:ring-[#cde0c5] text-sm text-gray-800 placeholder:text-gray-400 outline-none shadow-sm font-medium transition-all"
                                        />
                                    </div>

                                    {message && (
                                        <div className="bg-emerald-50 text-emerald-800 border border-emerald-100 p-3 rounded-xl flex items-center gap-2 text-xs font-semibold">
                                            <MailCheck className="h-4 w-4 text-emerald-600" />
                                            <span>{message}</span>
                                        </div>
                                    )}

                                    <button
                                        type="submit"
                                        className="w-full bg-[#628f52] hover:bg-[#4f7342] rounded-xl text-white font-semibold py-3 transition-colors shadow-md"
                                    >
                                        Send Reset Link
                                    </button>
                                </form>
                            </>
                        )}

                        {mode === "reset" && (
                            <>
                                <h2 className="text-2xl font-bold text-gray-900 mb-2 leading-tight">
                                    Reset Password
                                </h2>
                                <p className="text-xs text-gray-500 mb-6">
                                    Choose a strong new password for your admin account.
                                </p>

                                <form className="space-y-4 w-full" onSubmit={handleSubmit}>
                                    <div className="space-y-1">
                                        <label className="block text-xs font-medium text-gray-500 ml-1">
                                            New Password
                                        </label>
                                        <input
                                            type="password"
                                            required
                                            placeholder="••••••••"
                                            className="w-full px-4 py-3 bg-white rounded-xl border border-transparent focus:border-[#628f52] focus:ring-2 focus:ring-[#cde0c5] text-sm text-gray-800 outline-none shadow-sm"
                                        />
                                    </div>
                                    <div className="space-y-1">
                                        <label className="block text-xs font-medium text-gray-500 ml-1">
                                            Confirm Password
                                        </label>
                                        <input
                                            type="password"
                                            required
                                            placeholder="••••••••"
                                            className="w-full px-4 py-3 bg-white rounded-xl border border-transparent focus:border-[#628f52] focus:ring-2 focus:ring-[#cde0c5] text-sm text-gray-800 outline-none shadow-sm"
                                        />
                                    </div>

                                    {message && (
                                        <div className="bg-emerald-50 text-emerald-800 border border-emerald-100 p-3 rounded-xl flex items-center gap-2 text-xs font-semibold">
                                            <KeyRound className="h-4 w-4 text-emerald-600" />
                                            <span>{message}</span>
                                        </div>
                                    )}

                                    <button
                                        type="submit"
                                        className="w-full bg-[#628f52] hover:bg-[#4f7342] rounded-xl text-white font-semibold py-3 transition-colors shadow-md"
                                    >
                                        Update Password
                                    </button>
                                </form>
                            </>
                        )}

                    </div>
                </div>
            </div>
        </div>
    );
}
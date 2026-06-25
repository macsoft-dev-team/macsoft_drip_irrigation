import React from 'react';
import { Leaf } from 'lucide-react';
import plant from '../../src/assets/drip_img.jpg';
export default function Login({ onLogin }) {
    const handleSubmit = (e) => {
        e.preventDefault();
        if (onLogin) {
            onLogin();
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
                            Welcome to Smart Drip
                        </h1>
                        <p className="text-[#cde0c5] text-xs md:text-sm tracking-wider">
                            One stop for all the variety of plants
                        </p>
                    </div>

                    {/* Plant Image Circle */}
                    <div className="relative w-32 h-32 md:w-72 md:h-72 rounded-full bg-white flex items-center justify-center shadow-xl z-10 border-4 md:border-8 border-transparent flex-shrink-0">
                        {/* Using an Unsplash plant image as a placeholder */}
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
                        <div className="flex items-center gap-2 mb-8 md:mb-12 text-[#5d8a4d]">
                            <Leaf className="h-6 w-6 fill-current" />
                            <span className="font-bold text-xl tracking-tight">Smart Drip</span>
                        </div>

                        <h2 className="text-2xl md:text-3xl font-bold text-gray-900 mb-8 md:mb-10 leading-tight">
                            Login in to<br />your Smart Drip Account
                        </h2>

                        <form className="space-y-5 md:space-y-6 w-full" onSubmit={handleSubmit}>

                            {/* User Name Input */}
                            <div className="space-y-2">
                                <label className="block text-xs font-medium text-gray-500 ml-1">
                                    User Name
                                </label>
                                <input
                                    type="text"
                                    placeholder="Username"
                                    className="w-full px-5 py-3.5 bg-white rounded-xl border border-transparent focus:border-[#628f52] focus:ring-2 focus:ring-[#cde0c5] text-gray-800 placeholder:text-gray-400 outline-none shadow-sm font-medium transition-all [&:-webkit-autofill]:[box-shadow:0_0_0px_1000px_white_inset] [&:-webkit-autofill]:[-webkit-text-fill-color:#1f2937]"
                                />
                            </div>

                            {/* Password Input */}
                            <div className="space-y-2">
                                <label className="block text-xs font-medium text-gray-500 ml-1">
                                    Password
                                </label>
                                <input
                                    type="password"
                                    placeholder="••••••••"
                                    className="w-full px-5 py-3.5 bg-white rounded-xl border border-transparent focus:border-[#628f52] focus:ring-2 focus:ring-[#cde0c5] text-gray-800 placeholder:text-gray-400 outline-none shadow-sm font-medium tracking-widest transition-all [&:-webkit-autofill]:[box-shadow:0_0_0px_1000px_white_inset] [&:-webkit-autofill]:[-webkit-text-fill-color:#1f2937]"
                                />
                            </div>

                            {/* Forgot Password Link */}
                            <div className="flex justify-end">
                                <a href="#" className="text-xs text-gray-500 hover:text-[#5d8a4d] transition-colors font-medium">
                                    Forgot Password ?
                                </a>
                            </div>

                            {/* Submit Button */}
                            <button
                                type="submit"
                                className="w-full bg-[#628f52] hover:bg-[#4f7342] rounded-xl text-white font-semibold py-3.5 mt-2 transition-colors shadow-md active:scale-[0.98]"
                            >
                                Login
                            </button>

                        </form>

                        {/* Footer Link */}
                        <div className="mt-6 md:mt-8 text-center w-full">
                            <p className="text-xs text-gray-500 font-medium">
                                Don't have account ?{' '}
                                <a href="#" className="text-[#628f52] hover:underline">
                                    Signup
                                </a>
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
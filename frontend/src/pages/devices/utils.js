// src/utils.js

export const getLevelColor = (value, type) => {
    if (type === 'high' && value >= 90) return 'text-rose-600 font-bold';
    if (type === 'low' && value <= 15) return 'text-amber-600 font-bold';
    return type === 'high' ? 'text-blue-600' : 'text-slate-600';
};

export const generateMockData = (count = 12) => {
    return Array.from({ length: count }).map((_, i) => ({
        id: i + 1,
        imei: `86${Math.floor(Math.random() * 10000000000000)}`,
        tankHigh: Math.floor(Math.random() * 40) + 55,
        tankLow: Math.floor(Math.random() * 30) + 5,
        motorStatus: Math.random() > 0.4 ? 'Running' : 'Stopped',
        timestamp: new Date(Date.now() - Math.random() * 10000000).toLocaleString('en-GB', { hour12: true }),
    }));
};
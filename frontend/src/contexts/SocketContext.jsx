// src/contexts/SocketContext.jsx
import React, { createContext, useEffect, useRef, useState } from 'react';
import { io } from 'socket.io-client';

const WS_URL = import.meta.env.VITE_WEBSOCKET_URL || 'ws://localhost:4051';

// eslint-disable-next-line react-refresh/only-export-components
export const SocketContext = createContext(null);

export function SocketProvider({ children }) {
    // Keep socket in a ref (no re-renders on creation).
    // Expose `connected` as state — consumers depend on it to know when to subscribe.
    const socketRef = useRef(null);
    const [connected, setConnected] = useState(false);

    useEffect(() => {
        const s = io(WS_URL, {
            path: '/ws',
            transports: ['websocket'],
            autoConnect: true,
            reconnectionDelay: 2000,
            reconnectionAttempts: 10,
        });

        socketRef.current = s;

        s.on('connect', () => setConnected(true));
        s.on('disconnect', () => setConnected(false));

        return () => {
            s.disconnect();
        };
    }, []);

    return (
        <SocketContext.Provider value={{ socketRef, connected }}>
            {children}
        </SocketContext.Provider>
    );
}

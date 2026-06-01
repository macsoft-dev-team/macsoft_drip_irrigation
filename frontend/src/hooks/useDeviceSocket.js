// src/hooks/useDeviceSocket.js
// Subscribes to a device room and streams incoming telemetry rows.
import { useEffect, useRef } from 'react';
import { useSocket } from './useSocket';

/**
 * @param {string|null} deviceId  - UUID of the device to watch (null = no-op)
 * @param {(row: object) => void} onRow - called with each incoming telemetry row
 */
export function useDeviceSocket(deviceId, onRow) {
    // `connected` is the reactive trigger: false → no sub, true → subscribe.
    // When it flips true (connect/reconnect), this effect re-runs and re-subscribes.
    const { socketRef, connected } = useSocket() ?? {};
    const onRowRef = useRef(onRow);

    // Keep callback ref current without triggering re-subscription
    useEffect(() => { onRowRef.current = onRow; });

    useEffect(() => {
        const socket = socketRef?.current;
        if (!socket || !connected || !deviceId) return;

        socket.emit('subscribe:device', deviceId);

        const handler = (row) => onRowRef.current(row);
        socket.on('telemetry', handler);

        return () => {
            socket.off('telemetry', handler);
            socket.emit('unsubscribe:device', deviceId);
        };
    }, [deviceId, connected, socketRef]);
}

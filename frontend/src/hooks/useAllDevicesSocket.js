// src/hooks/useAllDevicesSocket.js
// Subscribes to the all-devices global room and fires onRow for any incoming telemetry.
import { useEffect, useRef } from 'react';
import { useSocket } from './useSocket';

/**
 * @param {(deviceId: string, row: object) => void} onRow
 */
export function useAllDevicesSocket(onRow) {
    const { socketRef, connected } = useSocket() ?? {};
    const onRowRef = useRef(onRow);

    useEffect(() => { onRowRef.current = onRow; });

    useEffect(() => {
        const socket = socketRef?.current;
        if (!socket || !connected) return;

        socket.emit('subscribe:all-devices');

        const handler = ({ deviceId, row }) => onRowRef.current(deviceId, row);
        socket.on('device:telemetry', handler);

        return () => {
            socket.off('device:telemetry', handler);
            socket.emit('unsubscribe:all-devices');
        };
    }, [connected, socketRef]);
}

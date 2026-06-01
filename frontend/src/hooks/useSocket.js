// src/hooks/useSocket.js
import { useContext } from 'react';
import { SocketContext } from '../contexts/SocketContext';

export function useSocket() {
    return useContext(SocketContext);
}

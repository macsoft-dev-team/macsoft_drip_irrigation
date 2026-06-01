import { useCallback } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { fetchDevices, fetchDeviceById, uploadDevices, createDevice, fetchDeviceTelemetry, sendCommand, fetchCommands, updateDevice, saveDeviceConfig } from '../reducers/deviceSlice';

export const useDevice = () => {
    const dispatch = useDispatch();

    // Select state from the store
    const { devices, device, loading, error, telemetry, telemetryLoading, commands, commandsLoading, commandSending } = useSelector((state) => state.devices);

    // dispatch from react-redux is stable — all callbacks below are stable across renders
    const loadDevices             = useCallback((params) => dispatch(fetchDevices(params)), [dispatch]);
    const loadDeviceById          = useCallback((id) => dispatch(fetchDeviceById(id)), [dispatch]);
    const handleUploadDevice      = useCallback((imeis) => dispatch(uploadDevices(imeis)), [dispatch]);
    const handleCreateDevice      = useCallback((imei) => dispatch(createDevice(imei)), [dispatch]);
    const loadTelemetry           = useCallback((params) => dispatch(fetchDeviceTelemetry(params)), [dispatch]);
    const dispatchSendCommand     = useCallback((params) => dispatch(sendCommand(params)), [dispatch]);
    const loadCommands            = useCallback((params) => dispatch(fetchCommands(params)), [dispatch]);
    const dispatchUpdateDevice    = useCallback((params) => dispatch(updateDevice(params)), [dispatch]);
    const dispatchSaveDeviceConfig = useCallback((params) => dispatch(saveDeviceConfig(params)), [dispatch]);

    return {
        devices,
        device,
        loading,
        error,
        telemetry,
        telemetryLoading,
        commands,
        commandsLoading,
        commandSending,
        loadDevices,
        loadDeviceById,
        uploadDevice: handleUploadDevice,
        createDevice: handleCreateDevice,
        loadTelemetry,
        sendCommand: dispatchSendCommand,
        loadCommands,
        updateDevice: dispatchUpdateDevice,
        saveDeviceConfig: dispatchSaveDeviceConfig,
    };
};
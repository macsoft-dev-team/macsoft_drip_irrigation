import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { API_URL } from '../configs/services';
import axios from 'axios';


export const fetchDevices = createAsyncThunk(
    'devices/fetchDevices',
    async ({ skip = 0, take = 10, filter = '' }, { rejectWithValue }) => {
        try {
            const token = sessionStorage.getItem('token');
            const response = await axios.get(`${API_URL}/devices`, {
                params: { skip, take, filter },
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
            });

            return response.data.data; // { devices, totalCount }
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to fetch devices');
        }
    }
);

export const uploadDevices = createAsyncThunk(
    'devices/uploadDevices',
    async (imeis, { rejectWithValue }) => {
        try {
            const token = sessionStorage.getItem('token');
            const response = await axios.post(`${API_URL}/devices/upload`,
                { imeis: JSON.stringify(imeis) },
                {
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json',
                    },
                }
            );

            return response.data; // { success, data: { totalInput, unique, created, skipped } }
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to upload devices');
        }
    }
);

export const createDevice = createAsyncThunk(
    'devices/createDevice',
    async (deviceData, { rejectWithValue }) => {
        try {
            const token = sessionStorage.getItem('token');
            const response = await axios.post(`${API_URL}/devices`, deviceData, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json',
                },
            });

            return response.data.data; // the created device
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to create device');
        }
    }
);

export const fetchDeviceById = createAsyncThunk(
    'devices/fetchDeviceById',
    async (id, { rejectWithValue }) => {
        try {
            const token = sessionStorage.getItem('token');
            const response = await axios.get(`${API_URL}/devices/${id}`, {
                headers: { Authorization: `Bearer ${token}` },
            });
            return response.data.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to fetch device');
        }
    }
);

export const fetchDeviceTelemetry = createAsyncThunk(
    'devices/fetchDeviceTelemetry',
    async ({ deviceId, from, to, skip = 0, take = 50 }, { rejectWithValue }) => {
        try {
            const token = sessionStorage.getItem('token');
            const response = await axios.get(`${API_URL}/devices/${deviceId}/telemetry`, {
                params: { from, to, take, skip },
                headers: { Authorization: `Bearer ${token}` },
            });
            return response.data.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to fetch telemetry');
        }
    }
);

export const sendCommand = createAsyncThunk(
    'devices/sendCommand',
    async ({ deviceId, payload }, { rejectWithValue }) => {
        try {
            const token = sessionStorage.getItem('token');
            const response = await axios.post(`${API_URL}/devices/${deviceId}/commands`, payload, {
                headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
            });
            return response.data.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to send command');
        }
    }
);

export const fetchCommands = createAsyncThunk(
    'devices/fetchCommands',
    async ({ deviceId, take = 20, skip = 0 }, { rejectWithValue }) => {
        try {
            const token = sessionStorage.getItem('token');
            const response = await axios.get(`${API_URL}/devices/${deviceId}/commands`, {
                params: { take, skip },
                headers: { Authorization: `Bearer ${token}` },
            });
            return response.data.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to fetch commands');
        }
    }
);

export const updateDevice = createAsyncThunk(
    'devices/updateDevice',
    async ({ deviceId, data }, { rejectWithValue }) => {
        try {
            const token = sessionStorage.getItem('token');
            const response = await axios.put(`${API_URL}/devices/${deviceId}`, data, {
                headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
            });
            return response.data.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to update device');
        }
    }
);

export const saveDeviceConfig = createAsyncThunk(
    'devices/saveDeviceConfig',
    async ({ deviceId, cfg }, { rejectWithValue }) => {
        try {
            const token = sessionStorage.getItem('token');
            const response = await axios.put(`${API_URL}/devices/${deviceId}/config`, cfg, {
                headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
            });
            // Return both so the reducer knows which device to patch
            return { deviceId, config: response.data.data };
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to save config');
        }
    }
);

const initialState = {
    devices: [],
    device: null,
    telemetry: [],
    telemetryLoading: false,
    commands: [],
    commandsLoading: false,
    commandSending: false,
    loading: false,
    error: null,
};

const deviceSlice = createSlice({
    name: 'devices',
    initialState,
    reducers: {
        setDevices: (state, action) => {
            state.devices = action.payload;
        },
        setDevice: (state, action) => {
            state.device = action.payload;
        }
    },
    extraReducers: (builder) => {
        builder
            .addCase(fetchDevices.pending, (state) => {
                state.loading = true;
                state.error = null;
            })
            .addCase(fetchDevices.fulfilled, (state, action) => {
                state.loading = false;
                state.devices = action.payload.devices;
            })
            .addCase(fetchDevices.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload || 'Failed to fetch devices';
            })
            .addCase(uploadDevices.pending, (state) => {
                state.loading = true;
                state.error = null;
            })
            .addCase(uploadDevices.fulfilled, (state) => {
                state.loading = false;
            })
            .addCase(uploadDevices.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload || 'Failed to upload devices';
            })
            .addCase(createDevice.pending, (state) => {
                state.loading = true;
                state.error = null;
            })
            .addCase(createDevice.fulfilled, (state, action) => {
                state.loading = false;
                state.devices = [action.payload, ...state.devices];
            })
            .addCase(createDevice.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload || 'Failed to create device';
            })
            .addCase(fetchDeviceTelemetry.pending, (state) => {
                state.telemetryLoading = true;
            })
            .addCase(fetchDeviceTelemetry.fulfilled, (state, action) => {
                state.telemetryLoading = false;
                state.telemetry = action.payload;
            })
            .addCase(fetchDeviceTelemetry.rejected, (state) => {
                state.telemetryLoading = false;
                state.telemetry = [];
            })
            .addCase(sendCommand.pending, (state) => { state.commandSending = true; })
            .addCase(sendCommand.fulfilled, (state, action) => {
                state.commandSending = false;
                state.commands = [action.payload, ...state.commands];
            })
            .addCase(sendCommand.rejected, (state) => { state.commandSending = false; })
            .addCase(fetchCommands.pending, (state) => { state.commandsLoading = true; })
            .addCase(fetchCommands.fulfilled, (state, action) => {
                state.commandsLoading = false;
                state.commands = action.payload;
            })
            .addCase(fetchCommands.rejected, (state) => { state.commandsLoading = false; })
            .addCase(updateDevice.pending, (state) => { state.loading = true; })
            .addCase(updateDevice.fulfilled, (state, action) => {
                state.loading = false;
                const idx = state.devices.findIndex(d => d.id === action.payload.id);
                if (idx !== -1) state.devices[idx] = { ...state.devices[idx], ...action.payload };
                if (state.device?.id === action.payload.id) state.device = { ...state.device, ...action.payload };
            })
            .addCase(updateDevice.rejected, (state) => { state.loading = false; })
            .addCase(saveDeviceConfig.pending, (state) => { state.loading = true; })
            .addCase(saveDeviceConfig.fulfilled, (state, action) => {
                state.loading = false;
                const { deviceId, config } = action.payload;
                const idx = state.devices.findIndex(d => d.id === deviceId);
                if (idx !== -1) state.devices[idx] = { ...state.devices[idx], config };
            })
            .addCase(saveDeviceConfig.rejected, (state) => { state.loading = false; })
            .addCase(fetchDeviceById.pending, (state) => { state.loading = true; state.device = null; })
            .addCase(fetchDeviceById.fulfilled, (state, action) => { state.loading = false; state.device = action.payload; })
            .addCase(fetchDeviceById.rejected, (state) => { state.loading = false; });
    },
});

export default deviceSlice.reducer;
export const { setDevices, setDevice } = deviceSlice.actions;
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { API_URL } from '../configs/services';
import axios from 'axios';

const authHeader = () => ({
    Authorization: `Bearer ${sessionStorage.getItem('token')}`,
});

export const fetchFields = createAsyncThunk(
    'irrigation/fetchFields',
    async ({ customerId } = {}, { rejectWithValue }) => {
        try {
            const response = await axios.get(`${API_URL}/fields`, {
                params: customerId ? { customerId } : {},
                headers: authHeader(),
            });
            return response.data.fields;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to fetch fields');
        }
    }
);

export const createField = createAsyncThunk(
    'irrigation/createField',
    async (data, { rejectWithValue }) => {
        try {
            const response = await axios.post(`${API_URL}/fields`, data, {
                headers: { ...authHeader(), 'Content-Type': 'application/json' },
            });
            return response.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to create field');
        }
    }
);

export const updateField = createAsyncThunk(
    'irrigation/updateField',
    async ({ id, data }, { rejectWithValue }) => {
        try {
            const response = await axios.put(`${API_URL}/fields/${id}`, data, {
                headers: { ...authHeader(), 'Content-Type': 'application/json' },
            });
            return response.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to update field');
        }
    }
);

export const deleteField = createAsyncThunk(
    'irrigation/deleteField',
    async (id, { rejectWithValue }) => {
        try {
            await axios.delete(`${API_URL}/fields/${id}`, { headers: authHeader() });
            return id;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to delete field');
        }
    }
);

export const createZone = createAsyncThunk(
    'irrigation/createZone',
    async (data, { rejectWithValue }) => {
        try {
            const response = await axios.post(`${API_URL}/zones`, data, {
                headers: { ...authHeader(), 'Content-Type': 'application/json' },
            });
            return response.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to create zone');
        }
    }
);

export const updateZone = createAsyncThunk(
    'irrigation/updateZone',
    async ({ id, data }, { rejectWithValue }) => {
        try {
            const response = await axios.put(`${API_URL}/zones/${id}`, data, {
                headers: { ...authHeader(), 'Content-Type': 'application/json' },
            });
            return response.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to update zone');
        }
    }
);

export const deleteZone = createAsyncThunk(
    'irrigation/deleteZone',
    async ({ id, fieldId }, { rejectWithValue }) => {
        try {
            await axios.delete(`${API_URL}/zones/${id}`, { headers: authHeader() });
            return { id, fieldId };
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to delete zone');
        }
    }
);

export const createValve = createAsyncThunk(
    'irrigation/createValve',
    async ({ data, fieldId }, { rejectWithValue }) => {
        try {
            const response = await axios.post(`${API_URL}/valves`, data, {
                headers: { ...authHeader(), 'Content-Type': 'application/json' },
            });
            return { valve: response.data, fieldId };
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to create valve');
        }
    }
);

export const updateValve = createAsyncThunk(
    'irrigation/updateValve',
    async ({ id, data, fieldId, zoneId }, { rejectWithValue }) => {
        try {
            const response = await axios.put(`${API_URL}/valves/${id}`, data, {
                headers: { ...authHeader(), 'Content-Type': 'application/json' },
            });
            return { valve: response.data, fieldId, zoneId };
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to update valve');
        }
    }
);

export const deleteValve = createAsyncThunk(
    'irrigation/deleteValve',
    async ({ id, fieldId, zoneId }, { rejectWithValue }) => {
        try {
            await axios.delete(`${API_URL}/valves/${id}`, { headers: authHeader() });
            return { id, fieldId, zoneId };
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to delete valve');
        }
    }
);

const irrigationSlice = createSlice({
    name: 'irrigation',
    initialState: {
        fields: [],
        loading: false,
        error: null,
    },
    reducers: {},
    extraReducers: (builder) => {
        builder
            .addCase(fetchFields.pending, (state) => { state.loading = true; state.error = null; })
            .addCase(fetchFields.fulfilled, (state, action) => {
                state.loading = false;
                state.fields = action.payload;
            })
            .addCase(fetchFields.rejected, (state, action) => { state.loading = false; state.error = action.payload; })

            .addCase(createField.fulfilled, (state, action) => {
                state.fields.push(action.payload);
            })
            .addCase(updateField.fulfilled, (state, action) => {
                const idx = state.fields.findIndex(f => f.id === action.payload.id);
                if (idx !== -1) {
                    state.fields[idx] = action.payload;
                }
            })
            .addCase(deleteField.fulfilled, (state, action) => {
                state.fields = state.fields.filter(f => f.id !== action.payload);
            })

            .addCase(createZone.fulfilled, (state, action) => {
                const fieldIdx = state.fields.findIndex(f => f.id === action.payload.fieldId);
                if (fieldIdx !== -1) {
                    if (!state.fields[fieldIdx].zones) state.fields[fieldIdx].zones = [];
                    state.fields[fieldIdx].zones.push(action.payload);
                }
            })
            .addCase(updateZone.fulfilled, (state, action) => {
                const fieldIdx = state.fields.findIndex(f => f.id === action.payload.fieldId);
                if (fieldIdx !== -1 && state.fields[fieldIdx].zones) {
                    const zoneIdx = state.fields[fieldIdx].zones.findIndex(z => z.id === action.payload.id);
                    if (zoneIdx !== -1) {
                        state.fields[fieldIdx].zones[zoneIdx] = action.payload;
                    }
                }
            })
            .addCase(deleteZone.fulfilled, (state, action) => {
                const fieldIdx = state.fields.findIndex(f => f.id === action.payload.fieldId);
                if (fieldIdx !== -1 && state.fields[fieldIdx].zones) {
                    state.fields[fieldIdx].zones = state.fields[fieldIdx].zones.filter(z => z.id !== action.payload.id);
                }
            })

            .addCase(createValve.fulfilled, (state, action) => {
                const { valve, fieldId } = action.payload;
                const fieldIdx = state.fields.findIndex(f => f.id === fieldId);
                if (fieldIdx !== -1 && state.fields[fieldIdx].zones) {
                    const zoneIdx = state.fields[fieldIdx].zones.findIndex(z => z.id === valve.zoneId);
                    if (zoneIdx !== -1) {
                        if (!state.fields[fieldIdx].zones[zoneIdx].valves) state.fields[fieldIdx].zones[zoneIdx].valves = [];
                        state.fields[fieldIdx].zones[zoneIdx].valves.push(valve);
                    }
                }
            })
            .addCase(updateValve.fulfilled, (state, action) => {
                const { valve, fieldId, zoneId } = action.payload;
                const fieldIdx = state.fields.findIndex(f => f.id === fieldId);
                if (fieldIdx !== -1 && state.fields[fieldIdx].zones) {
                    const zoneIdx = state.fields[fieldIdx].zones.findIndex(z => z.id === zoneId);
                    if (zoneIdx !== -1 && state.fields[fieldIdx].zones[zoneIdx].valves) {
                        const valveIdx = state.fields[fieldIdx].zones[zoneIdx].valves.findIndex(v => v.id === valve.id);
                        if (valveIdx !== -1) {
                            state.fields[fieldIdx].zones[zoneIdx].valves[valveIdx] = valve;
                        }
                    }
                }
            })
            .addCase(deleteValve.fulfilled, (state, action) => {
                const { id, fieldId, zoneId } = action.payload;
                const fieldIdx = state.fields.findIndex(f => f.id === fieldId);
                if (fieldIdx !== -1 && state.fields[fieldIdx].zones) {
                    const zoneIdx = state.fields[fieldIdx].zones.findIndex(z => z.id === zoneId);
                    if (zoneIdx !== -1 && state.fields[fieldIdx].zones[zoneIdx].valves) {
                        state.fields[fieldIdx].zones[zoneIdx].valves = state.fields[fieldIdx].zones[zoneIdx].valves.filter(v => v.id !== id);
                    }
                }
            });
    },
});

export default irrigationSlice.reducer;

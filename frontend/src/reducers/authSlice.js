import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { API_URL } from '../configs/services';
import axios from 'axios';

// Decode JWT payload without a library (payload is public base64url)
const decodeToken = (token) => {
    try {
        const base64 = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
        return JSON.parse(atob(base64));
    } catch {
        return null;
    }
};

// Restore user from token already in sessionStorage (page refresh)
const restoreUser = () => {
    const token = sessionStorage.getItem('token');
    if (!token) return null;
    const decoded = decodeToken(token);
    if (!decoded || decoded.exp * 1000 < Date.now()) {
        sessionStorage.removeItem('token');
        return null;
    }
    return { id: decoded.id, role: decoded.role, name: decoded.name, customerId: decoded.customerId ?? null };
};

// 1. Define the Async Thunk
export const loginUser = createAsyncThunk(
    'auth/loginUser',
    async (credentials, { rejectWithValue }) => {
        try {
            const response = await axios.post(`${API_URL}/auth/login`, credentials, {
                headers: { 'Content-Type': 'application/json' },
            });

            const { token } = response.data;
            sessionStorage.setItem('token', token);

            const decoded = decodeToken(token);
            return { token, user: { id: decoded.id, role: decoded.role, name: decoded.name, customerId: decoded.customerId ?? null } };
        } catch (err) {
            return rejectWithValue(
                err.response?.data?.message || 'Server connection error'
            );
        }
    }
);

const restoredUser = restoreUser();

const initialState = {
    user: restoredUser,
    token: restoredUser ? sessionStorage.getItem('token') : null,
    isAuthenticated: !!restoredUser,
    loading: false,
    error: null,
};

// 2. The Slice
const authSlice = createSlice({
    name: 'auth',
    initialState,
    reducers: {
        logout: (state) => {
            state.user = null;
            state.token = null;
            state.isAuthenticated = false;
            sessionStorage.removeItem('token');
        },
    },
    extraReducers: (builder) => {
        builder
            .addCase(loginUser.pending, (state) => {
                state.loading = true;
                state.error = null;
            })
            .addCase(loginUser.fulfilled, (state, action) => {
                state.loading = false;
                state.isAuthenticated = true;
                state.user = action.payload.user;
                state.token = action.payload.token;
            })
            .addCase(loginUser.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            });
    },
});

export const { logout } = authSlice.actions;
export default authSlice.reducer;
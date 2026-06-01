import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { API_URL } from '../configs/services';
import axios from 'axios';

const authHeader = () => ({
    Authorization: `Bearer ${sessionStorage.getItem('token')}`,
});

export const fetchUsers = createAsyncThunk(
    'users/fetchUsers',
    async ({ skip = 1, take = 10, filter = '', role = '', customerId = '' } = {}, { rejectWithValue }) => {
        try {
            const response = await axios.get(`${API_URL}/users`, {
                params: { skip, take, filter, role: role || undefined, customerId: customerId || undefined },
                headers: authHeader(),
            });
            return response.data; // { users, totalPages, currentPage }
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to fetch users');
        }
    }
);

export const fetchUserById = createAsyncThunk(
    'users/fetchUserById',
    async (id, { rejectWithValue }) => {
        try {
            const response = await axios.get(`${API_URL}/users/${id}`, {
                headers: authHeader(),
            });
            return response.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to fetch user');
        }
    }
);

export const createUser = createAsyncThunk(
    'users/createUser',
    async (data, { rejectWithValue }) => {
        try {
            const response = await axios.post(`${API_URL}/users`, data, {
                headers: { ...authHeader(), 'Content-Type': 'application/json' },
            });
            return response.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to create user');
        }
    }
);

export const updateUser = createAsyncThunk(
    'users/updateUser',
    async ({ id, data }, { rejectWithValue }) => {
        try {
            const response = await axios.put(`${API_URL}/users/${id}`, data, {
                headers: { ...authHeader(), 'Content-Type': 'application/json' },
            });
            return response.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to update user');
        }
    }
);

export const deleteUser = createAsyncThunk(
    'users/deleteUser',
    async (id, { rejectWithValue }) => {
        try {
            await axios.delete(`${API_URL}/users/${id}`, { headers: authHeader() });
            return id;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to delete user');
        }
    }
);

const usersSlice = createSlice({
    name: 'users',
    initialState: {
        users: [],
        totalPages: 1,
        currentPage: 1,
        loading: false,
        error: null,
    },
    reducers: {},
    extraReducers: (builder) => {
        builder
            // fetchUsers
            .addCase(fetchUsers.pending, (state) => { state.loading = true; state.error = null; })
            .addCase(fetchUsers.fulfilled, (state, action) => {
                state.loading = false;
                state.users = action.payload.users;
                state.totalPages = action.payload.totalPages;
                state.currentPage = action.payload.currentPage;
            })
            .addCase(fetchUsers.rejected, (state, action) => { state.loading = false; state.error = action.payload; })

            // createUser
            .addCase(createUser.fulfilled, (state, action) => {
                state.users.unshift(action.payload);
            })

            // updateUser
            .addCase(updateUser.fulfilled, (state, action) => {
                const idx = state.users.findIndex((u) => u.id === action.payload.id);
                if (idx !== -1) state.users[idx] = action.payload;
            })

            // deleteUser
            .addCase(deleteUser.fulfilled, (state, action) => {
                state.users = state.users.filter((u) => u.id !== action.payload);
            });
    },
});

export default usersSlice.reducer;

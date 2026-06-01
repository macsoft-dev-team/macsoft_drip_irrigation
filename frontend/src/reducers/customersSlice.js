import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { API_URL } from '../configs/services';
import axios from 'axios';

const authHeader = () => ({
    Authorization: `Bearer ${sessionStorage.getItem('token')}`,
});

export const fetchCustomers = createAsyncThunk(
    'customers/fetchCustomers',
    async ({ skip = 1, take = 10, filter = '' } = {}, { rejectWithValue }) => {
        try {
            const response = await axios.get(`${API_URL}/customers`, {
                params: { skip, take, filter },
                headers: authHeader(),
            });
            return response.data; // { customers, totalPages, currentPage }
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to fetch customers');
        }
    }
);

export const fetchCustomerById = createAsyncThunk(
    'customers/fetchCustomerById',
    async (id, { rejectWithValue }) => {
        try {
            const response = await axios.get(`${API_URL}/customers/${id}`, {
                headers: authHeader(),
            });
            return response.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to fetch customer');
        }
    }
);

export const createCustomer = createAsyncThunk(
    'customers/createCustomer',
    async (data, { rejectWithValue }) => {
        try {
            const response = await axios.post(`${API_URL}/customers`, data, {
                headers: { ...authHeader(), 'Content-Type': 'application/json' },
            });
            return response.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to create customer');
        }
    }
);

export const updateCustomer = createAsyncThunk(
    'customers/updateCustomer',
    async ({ id, data }, { rejectWithValue }) => {
        try {
            const response = await axios.put(`${API_URL}/customers/${id}`, data, {
                headers: { ...authHeader(), 'Content-Type': 'application/json' },
            });
            return response.data;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to update customer');
        }
    }
);

export const deleteCustomer = createAsyncThunk(
    'customers/deleteCustomer',
    async (id, { rejectWithValue }) => {
        try {
            await axios.delete(`${API_URL}/customers/${id}`, { headers: authHeader() });
            return id;
        } catch (err) {
            return rejectWithValue(err.response?.data?.error || 'Failed to delete customer');
        }
    }
);

const customersSlice = createSlice({
    name: 'customers',
    initialState: {
        customers: [],
        totalPages: 1,
        currentPage: 1,
        loading: false,
        error: null,
    },
    reducers: {},
    extraReducers: (builder) => {
        builder
            // fetchCustomers
            .addCase(fetchCustomers.pending, (state) => { state.loading = true; state.error = null; })
            .addCase(fetchCustomers.fulfilled, (state, action) => {
                state.loading = false;
                state.customers = action.payload.customers;
                state.totalPages = action.payload.totalPages;
                state.currentPage = action.payload.currentPage;
            })
            .addCase(fetchCustomers.rejected, (state, action) => { state.loading = false; state.error = action.payload; })

            // createCustomer
            .addCase(createCustomer.fulfilled, (state, action) => {
                state.customers.unshift(action.payload);
            })

            // updateCustomer
            .addCase(updateCustomer.fulfilled, (state, action) => {
                const idx = state.customers.findIndex((c) => c.id === action.payload.id);
                if (idx !== -1) state.customers[idx] = action.payload;
            })

            // deleteCustomer
            .addCase(deleteCustomer.fulfilled, (state, action) => {
                state.customers = state.customers.filter((c) => c.id !== action.payload);
            });
    },
});

export default customersSlice.reducer;

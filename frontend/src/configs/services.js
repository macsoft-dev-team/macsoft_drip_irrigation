import axios from './api'

export const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4051/api';

export const WEBSOCKET_URL = import.meta.env.VITE_WEBSOCKET_URL || 'ws://localhost:4051';

export const getToken = () => {
    return locaSltorage.getItem('token');
};

export const apiGet = async (endpoint, params) => {
    try {
        const response = await axios.get(`${API_URL}${endpoint}`, { params });
        return response.data;
    } catch (error) {
        throw error.response ? error.response.data : new Error('Network error');
    }
};

export const apiPost = async (endpoint, data) => {
    try {
        const response = await axios.post(`${API_URL}${endpoint}`, data);
        return response.data;
    } catch (error) {
        throw error.response ? error.response.data : new Error('Network error');
    }
};

export const apiPut = async (endpoint, data) => {
    try {
        const response = await axios.put(`${API_URL}${endpoint}`, data);
        return response.data;
    } catch (error) {
        throw error.response ? error.response.data : new Error('Network error');
    }
};

export const apiDelete = async (endpoint) => {
    try {
        const response = await axios.delete(`${API_URL}${endpoint}`);
        return response.data;
    } catch (error) {
        throw error.response ? error.response.data : new Error('Network error');
    }
};

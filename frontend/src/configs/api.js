import axios from 'axios';
import { logout } from '../reducers/authSlice';

let store;

// This function will be called to set the store reference
export const setStoreForInterceptor = (storeInstance) => {
  store = storeInstance;
};

// Request interceptor to add token to requests
axios.interceptors.request.use(
  (config) => {
    const token = sessionStorage.getItem('token');
    
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
     } else {
      console.warn('❌ No token found in sessionStorage');
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle expired tokens
axios.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    // Only logout on authentication-related 401 errors, not authorization (403) errors
    if (error.response?.status === 401) {
      // Check if it's a token-related authentication error
      const authErrorMessages = [
        'token expired',
        'invalid token',
        'no token provided',
        'unauthorized',
        'access denied'
      ];
      
      const errorMessage = (error.response?.data?.message || '').toLowerCase();
      const isAuthError = authErrorMessages.some(msg => errorMessage.includes(msg));
      
      // Also logout if the error is from auth endpoints
      const isAuthEndpoint = error.config?.url?.includes('/auth/') || 
                            error.config?.url?.includes('/user/me');
      
      if (isAuthError || isAuthEndpoint) {
        console.warn('🔒 Authentication failed - clearing session');
        // Token is expired or invalid
        if (store) {
          store.dispatch(logout());
        }
        // Clear storage
        sessionStorage.removeItem('user');
        sessionStorage.removeItem('token');
        
        // Redirect to login if not already there
        if (window.location.pathname !== '/login') {
          window.location.href = '/login';
        }
      }
    }
    return Promise.reject(error);
  }
);

export default axios;
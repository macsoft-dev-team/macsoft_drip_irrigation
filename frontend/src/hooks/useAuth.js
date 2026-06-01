import { useSelector, useDispatch } from 'react-redux';
import { loginUser, logout } from '../reducers/authSlice';

export const useAuth = () => {
    const dispatch = useDispatch();

    // Select state from the store
    const { user, isAuthenticated, loading, error } = useSelector((state) => state.auth);

    const login = (credentials) => {
        // We dispatch the thunk directly
        dispatch(loginUser(credentials));
    };

    const handleLogout = () => {
        dispatch(logout());
    };

    return {
        user,
        isAuthenticated,
        loading,
        error,
        login,
        logout: handleLogout,
    };
};
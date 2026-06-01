import { useSelector } from 'react-redux';

export const ROLES = {
    MACSOFT_ADMIN: 'MACSOFT_ADMIN',
    MACSOFT_USER: 'MACSOFT_USER',
    CUSTOMER_ADMIN: 'CUSTOMER_ADMIN',
    CUSTOMER_USER: 'CUSTOMER_USER',
    END_USER: 'END_USER',
};

/**
 * Returns the current user's role and helper predicates.
 *
 * hasRole(roles)       – true when user's role is in the provided array
 * isMacsoftAdmin()     – true for MACSOFT_ADMIN only
 * isAdminLevel()       – true for MACSOFT_ADMIN or CUSTOMER_ADMIN
 * canManageUsers()     – true for MACSOFT_ADMIN or CUSTOMER_ADMIN
 * canDeleteUsers()     – true for MACSOFT_ADMIN only
 * canManageDevices()   – true for MACSOFT_ADMIN, MACSOFT_USER, CUSTOMER_ADMIN
 */
export const useRole = () => {
    const user = useSelector((state) => state.auth.user);
    const role = user?.role ?? null;

    const hasRole = (roles = []) => roles.includes(role);

    return {
        role,
        hasRole,
        isMacsoftAdmin: () => role === ROLES.MACSOFT_ADMIN,
        isMacsoftRole: () => role === ROLES.MACSOFT_ADMIN || role === ROLES.MACSOFT_USER,
        isAdminLevel: () => role === ROLES.MACSOFT_ADMIN || role === ROLES.CUSTOMER_ADMIN,
        canManageUsers: () => role === ROLES.MACSOFT_ADMIN || role === ROLES.CUSTOMER_ADMIN,
        canDeleteUsers: () => role === ROLES.MACSOFT_ADMIN,
        canManageDevices: () =>
            role === ROLES.MACSOFT_ADMIN ||
            role === ROLES.MACSOFT_USER ||
            role === ROLES.CUSTOMER_ADMIN,
    };
};

import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { motion, AnimatePresence } from 'framer-motion';
import {
    Users, Plus, Trash2, Pencil, Search, Shield, ShieldCheck,
    User, X, AlertCircle, Loader2, ChevronLeft, ChevronRight, Eye, EyeOff,
} from 'lucide-react';
import toast from 'react-hot-toast';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';

import { fetchUsers, createUser, updateUser, deleteUser } from '../../reducers/usersSlice';
import { fetchCustomers } from '../../reducers/customersSlice';
import { useRole, ROLES } from '../../hooks/useRole';

const ROLE_META = {
    [ROLES.MACSOFT_ADMIN]: { label: 'Macsoft Admin', color: 'bg-rose-50 text-rose-700 border-rose-200', icon: ShieldCheck },
    [ROLES.MACSOFT_USER]: { label: 'Macsoft User', color: 'bg-orange-50 text-orange-700 border-orange-200', icon: Shield },
    [ROLES.CUSTOMER_ADMIN]: { label: 'Customer Admin', color: 'bg-violet-50 text-violet-700 border-violet-200', icon: Shield },
    [ROLES.CUSTOMER_USER]: { label: 'Customer User', color: 'bg-blue-50 text-blue-700 border-blue-200', icon: User },
    [ROLES.END_USER]: { label: 'End User', color: 'bg-slate-50 text-slate-600 border-slate-200', icon: User },
};

const RoleBadge = ({ role }) => {
    const meta = ROLE_META[role] || ROLE_META[ROLES.END_USER];
    const Icon = meta.icon;
    return (
        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-bold uppercase tracking-wider border ${meta.color}`}>
            <Icon className="w-3 h-3" />
            {meta.label}
        </span>
    );
};

// ---------- Form Schema ----------
const ALL_ROLES = [ROLES.MACSOFT_ADMIN, ROLES.MACSOFT_USER, ROLES.CUSTOMER_ADMIN, ROLES.CUSTOMER_USER, ROLES.END_USER];

const makeSchema = (isEdit) =>
    yup.object().shape({
        name: yup.string().required('Name is required'),
        email: yup.string().email('Invalid email').required('Email is required'),
        phone: yup.string().nullable(),
        role: yup.string().oneOf(ALL_ROLES).required('Role is required'),
        customerId: yup.string().nullable(),
        password: isEdit
            ? yup.string().min(8, 'Min 8 characters').nullable().transform((v) => v || undefined)
            : yup.string().min(8, 'Min 8 characters').required('Password is required'),
    });

// ---------- User Form Modal ----------
function UserFormModal({ user, onClose, onSaved, isMacsoftAdmin, isMacsoftRole, customers }) {
    const dispatch = useDispatch();
    const isEdit = !!user;
    const [showPw, setShowPw] = useState(false);

    const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm({
        resolver: yupResolver(makeSchema(isEdit)),
        defaultValues: {
            name: user?.name || '',
            email: user?.email || '',
            phone: user?.phone || '',
            role: user?.role || ROLES.END_USER,
            customerId: user?.customerId || '',
            password: '',
        },
    });

    const onSubmit = async (data) => {
        // Strip empty password on edit
        if (isEdit && !data.password) delete data.password;

        const result = isEdit
            ? await dispatch(updateUser({ id: user.id, data }))
            : await dispatch(createUser(data));

        if (result.error) {
            toast.error(result.payload || 'Operation failed');
        } else {
            toast.success(isEdit ? 'User updated' : 'User created');
            onSaved?.();
            onClose();
        }
    };

    const Field = ({ label, name, type = 'text', children }) => (
        <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-600 uppercase tracking-wide">{label}</label>
            {children || (
                <input
                    type={type}
                    {...register(name)}
                    className={`w-full px-3.5 py-2.5 text-sm font-medium rounded-xl border bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/30 transition-shadow ${errors[name] ? 'border-rose-400' : 'border-slate-200'}`}
                />
            )}
            {errors[name] && (
                <p className="text-[11px] font-bold text-rose-500 flex items-center gap-1">
                    <AlertCircle className="w-3 h-3" /> {errors[name].message}
                </p>
            )}
        </div>
    );

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/50 backdrop-blur-sm p-4">
            <motion.div
                initial={{ opacity: 0, scale: 0.96 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.96 }}
                className="bg-white rounded-2xl shadow-2xl w-full max-w-md"
            >
                <div className="flex items-center justify-between p-6 border-b border-slate-100">
                    <h2 className="text-lg font-extrabold text-slate-800">
                        {isEdit ? 'Edit User' : 'Create User'}
                    </h2>
                    <button onClick={onClose} className="p-2 rounded-lg text-slate-400 hover:bg-slate-100 transition-colors">
                        <X className="w-4 h-4" />
                    </button>
                </div>

                <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-4">
                    <Field label="Full Name" name="name" />
                    <Field label="Email" name="email" type="email" />
                    <Field label="Phone (optional)" name="phone" />

                    {/* Role Select */}
                    <div className="space-y-1.5">
                        <label className="text-xs font-bold text-slate-600 uppercase tracking-wide">Role</label>
                        <select
                            {...register('role')}
                            className={`w-full px-3.5 py-2.5 text-sm font-medium rounded-xl border bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/30 transition-shadow ${errors.role ? 'border-rose-400' : 'border-slate-200'}`}
                        >
                            {isMacsoftRole ? (
                                <>
                                    {isMacsoftAdmin && (
                                        <>
                                            <option value={ROLES.MACSOFT_ADMIN}>Macsoft Admin</option>
                                            <option value={ROLES.MACSOFT_USER}>Macsoft User</option>
                                        </>
                                    )}
                                    <option value={ROLES.CUSTOMER_ADMIN}>Customer Admin</option>
                                    <option value={ROLES.CUSTOMER_USER}>Customer User</option>
                                    <option value={ROLES.END_USER}>End User</option>
                                </>
                            ) : (
                                <>
                                    <option value={ROLES.CUSTOMER_ADMIN}>Admin</option>
                                    <option value={ROLES.CUSTOMER_USER}>User</option>
                                    <option value={ROLES.END_USER}>End User</option>
                                </>
                            )}
                        </select>
                        {errors.role && (
                            <p className="text-[11px] font-bold text-rose-500 flex items-center gap-1">
                                <AlertCircle className="w-3 h-3" /> {errors.role.message}
                            </p>
                        )}
                    </div>

                    {/* Customer Select — macsoft roles only */}
                    {isMacsoftRole && (
                        <div className="space-y-1.5">
                            <label className="text-xs font-bold text-slate-600 uppercase tracking-wide">Customer</label>
                            <select
                                {...register('customerId')}
                                className="w-full px-3.5 py-2.5 text-sm font-medium rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/30 transition-shadow"
                            >
                                <option value="">— No customer (internal) —</option>
                                {customers.map((c) => (
                                    <option key={c.id} value={c.id}>{c.name || c.email}</option>
                                ))}
                            </select>
                        </div>
                    )}

                    {/* Password */}
                    <div className="space-y-1.5">
                        <label className="text-xs font-bold text-slate-600 uppercase tracking-wide">
                            {isEdit ? 'New Password (leave blank to keep)' : 'Password'}
                        </label>
                        <div className="relative">
                            <input
                                type={showPw ? 'text' : 'password'}
                                {...register('password')}
                                className={`w-full px-3.5 py-2.5 pr-10 text-sm font-medium rounded-xl border bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/30 transition-shadow ${errors.password ? 'border-rose-400' : 'border-slate-200'}`}
                            />
                            <button type="button" onClick={() => setShowPw(!showPw)} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                                {showPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                            </button>
                        </div>
                        {errors.password && (
                            <p className="text-[11px] font-bold text-rose-500 flex items-center gap-1">
                                <AlertCircle className="w-3 h-3" /> {errors.password.message}
                            </p>
                        )}
                    </div>

                    <div className="flex gap-3 pt-2">
                        <button type="button" onClick={onClose} className="flex-1 py-2.5 rounded-xl border border-slate-200 text-sm font-bold text-slate-600 hover:bg-slate-50 transition-colors">
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={isSubmitting}
                            className="flex-1 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-sm font-bold transition-colors flex items-center justify-center gap-2 disabled:opacity-60"
                        >
                            {isSubmitting && <Loader2 className="w-4 h-4 animate-spin" />}
                            {isEdit ? 'Save Changes' : 'Create User'}
                        </button>
                    </div>
                </form>
            </motion.div>
        </div>
    );
}

// ---------- Main Page ----------
export default function UsersPage() {
    const dispatch = useDispatch();
    const { users, totalPages, currentPage, loading } = useSelector((s) => s.users);
    const { customers } = useSelector((s) => s.customers);
    const { isMacsoftAdmin, isMacsoftRole, canDeleteUsers } = useRole();

    const [page, setPage] = useState(1);
    const [search, setSearch] = useState('');
    const [roleFilter, setRoleFilter] = useState('');
    const [customerFilter, setCustomerFilter] = useState('');
    const [formTarget, setFormTarget] = useState(null); // null = closed, false = new, user = edit
    const [deleteTarget, setDeleteTarget] = useState(null);

    const load = (p = page, q = search, r = roleFilter, c = customerFilter) =>
        dispatch(fetchUsers({ skip: p, take: 10, filter: q, role: r, customerId: c }));

    useEffect(() => {
        load(1, '', '', '');
        dispatch(fetchCustomers({ skip: 1, take: 100 }));
    }, []);

    const handleSearch = (e) => {
        const q = e.target.value;
        setSearch(q);
        setPage(1);
        load(1, q, roleFilter, customerFilter);
    };

    const handleRoleFilter = (e) => {
        const r = e.target.value;
        setRoleFilter(r);
        setPage(1);
        load(1, search, r, customerFilter);
    };

    const handleCustomerFilter = (e) => {
        const c = e.target.value;
        setCustomerFilter(c);
        setPage(1);
        load(1, search, roleFilter, c);
    };

    const handleDelete = async () => {
        const result = await dispatch(deleteUser(deleteTarget.id));
        if (result.error) {
            toast.error(result.payload || 'Delete failed');
        } else {
            toast.success('User deleted');
            load(page, search, roleFilter, customerFilter);
        }
        setDeleteTarget(null);
    };

    const handlePage = (p) => {
        setPage(p);
        load(p, search, roleFilter, customerFilter);
    };

    return (
        <div className="min-h-screen bg-slate-50 p-4 md:p-8 font-sans">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
                <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center shadow-lg shadow-violet-500/20">
                        <Users className="w-6 h-6 text-white" />
                    </div>
                    <div>
                        <h1 className="text-xl font-extrabold text-slate-900 tracking-tight">USERS</h1>
                        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Role-based user management</p>
                    </div>
                </div>
                <button
                    onClick={() => setFormTarget(false)}
                    className="inline-flex items-center gap-2 bg-slate-900 hover:bg-slate-800 text-white text-sm font-bold px-4 py-2.5 rounded-xl transition-colors shadow-sm"
                >
                    <Plus className="w-4 h-4" /> Add User
                </button>
            </div>

            {/* Filters */}
            <div className="flex flex-wrap gap-3 mb-5">
                <div className="relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none" />
                    <input
                        type="text"
                        value={search}
                        onChange={handleSearch}
                        placeholder="Search name, email, phone…"
                        className="pl-9 pr-4 py-2.5 text-sm font-medium border border-slate-200 rounded-xl bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/30 w-64"
                    />
                </div>

                <select
                    value={roleFilter}
                    onChange={handleRoleFilter}
                    className="py-2.5 px-3.5 text-sm font-medium border border-slate-200 rounded-xl bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/30 text-slate-600"
                >
                    <option value="">All Roles</option>
                    {isMacsoftRole() && (
                        <>
                            <option value={ROLES.MACSOFT_ADMIN}>Macsoft Admin</option>
                            <option value={ROLES.MACSOFT_USER}>Macsoft User</option>
                        </>
                    )}
                    <option value={ROLES.CUSTOMER_ADMIN}>{isMacsoftRole() ? 'Customer Admin' : 'Admin'}</option>
                    <option value={ROLES.CUSTOMER_USER}>{isMacsoftRole() ? 'Customer User' : 'User'}</option>
                    <option value={ROLES.END_USER}>End User</option>
                </select>

                {isMacsoftRole() && (
                    <select
                        value={customerFilter}
                        onChange={handleCustomerFilter}
                        className="py-2.5 px-3.5 text-sm font-medium border border-slate-200 rounded-xl bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/30 text-slate-600"
                    >
                        <option value="">All Customers</option>
                        {customers.map((c) => (
                            <option key={c.id} value={c.id}>{c.name || c.email}</option>
                        ))}
                    </select>
                )}
            </div>

            {/* Table */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                {loading ? (
                    <div className="flex items-center justify-center py-20 text-slate-400">
                        <Loader2 className="w-6 h-6 animate-spin mr-2" /> Loading…
                    </div>
                ) : users.length === 0 ? (
                    <div className="flex flex-col items-center py-20 gap-3 text-slate-400">
                        <Users className="w-10 h-10 text-slate-200" />
                        <p className="font-semibold">No users found</p>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead className="bg-slate-50 border-b border-slate-200">
                                <tr>
                                    {['Name', 'Email', 'Phone', 'Role', ...(isMacsoftRole() ? ['Customer'] : []), 'Actions'].map((h) => (
                                        <th key={h} className="px-5 py-3.5 text-left text-[11px] font-extrabold text-slate-500 uppercase tracking-wider">
                                            {h}
                                        </th>
                                    ))}
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {users.map((u) => (
                                    <tr key={u.id} className="hover:bg-slate-50/50 transition-colors">
                                        <td className="px-5 py-4 font-semibold text-slate-800">{u.name}</td>
                                        <td className="px-5 py-4 text-slate-600">{u.email}</td>
                                        <td className="px-5 py-4 text-slate-500">{u.phone || '—'}</td>
                                        <td className="px-5 py-4"><RoleBadge role={u.role} /></td>
                                        {isMacsoftRole() && (
                                            <td className="px-5 py-4 text-slate-500 text-xs">
                                                {u.customer?.name || '—'}
                                            </td>
                                        )}
                                        <td className="px-5 py-4">
                                            <div className="flex items-center gap-1.5">
                                                <button
                                                    onClick={() => setFormTarget(u)}
                                                    className="p-1.5 rounded-lg text-blue-500 bg-blue-50 border border-blue-200 hover:bg-blue-100 transition-colors"
                                                    title="Edit"
                                                >
                                                    <Pencil className="w-3.5 h-3.5" />
                                                </button>
                                                {canDeleteUsers() && (
                                                    <button
                                                        onClick={() => setDeleteTarget(u)}
                                                        className="p-1.5 rounded-lg text-rose-500 bg-rose-50 border border-rose-200 hover:bg-rose-100 transition-colors"
                                                        title="Delete"
                                                    >
                                                        <Trash2 className="w-3.5 h-3.5" />
                                                    </button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}

                {/* Pagination */}
                {totalPages > 1 && (
                    <div className="flex items-center justify-between px-5 py-4 border-t border-slate-100 bg-slate-50/50">
                        <p className="text-xs font-semibold text-slate-500">Page {page} of {totalPages}</p>
                        <div className="flex items-center gap-1.5">
                            <button
                                onClick={() => handlePage(page - 1)}
                                disabled={page <= 1}
                                className="p-1.5 rounded-lg border border-slate-200 text-slate-500 disabled:opacity-40 hover:bg-slate-100 transition-colors"
                            >
                                <ChevronLeft className="w-4 h-4" />
                            </button>
                            <button
                                onClick={() => handlePage(page + 1)}
                                disabled={page >= totalPages}
                                className="p-1.5 rounded-lg border border-slate-200 text-slate-500 disabled:opacity-40 hover:bg-slate-100 transition-colors"
                            >
                                <ChevronRight className="w-4 h-4" />
                            </button>
                        </div>
                    </div>
                )}
            </div>

            {/* Create/Edit Modal */}
            <AnimatePresence>
                {formTarget !== null && (
                    <UserFormModal
                        user={formTarget || null}
                        onClose={() => setFormTarget(null)}
                        onSaved={() => load(page, search, roleFilter, customerFilter)}
                        isMacsoftAdmin={isMacsoftAdmin()}
                        isMacsoftRole={isMacsoftRole()}
                        customers={customers}
                    />
                )}
            </AnimatePresence>

            {/* Delete Confirm */}
            <AnimatePresence>
                {deleteTarget && (
                    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/50 backdrop-blur-sm p-4">
                        <motion.div
                            initial={{ opacity: 0, scale: 0.96 }}
                            animate={{ opacity: 1, scale: 1 }}
                            exit={{ opacity: 0, scale: 0.96 }}
                            className="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6 space-y-4"
                        >
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-xl bg-rose-50 border border-rose-200 flex items-center justify-center">
                                    <Trash2 className="w-5 h-5 text-rose-500" />
                                </div>
                                <div>
                                    <p className="font-extrabold text-slate-800">Delete User</p>
                                    <p className="text-sm text-slate-500">This action cannot be undone.</p>
                                </div>
                            </div>
                            <p className="text-sm text-slate-600 font-medium">
                                Are you sure you want to delete <span className="font-bold text-slate-800">{deleteTarget.name}</span>?
                            </p>
                            <div className="flex gap-3 pt-1">
                                <button onClick={() => setDeleteTarget(null)} className="flex-1 py-2.5 rounded-xl border border-slate-200 text-sm font-bold text-slate-600 hover:bg-slate-50 transition-colors">
                                    Cancel
                                </button>
                                <button onClick={handleDelete} className="flex-1 py-2.5 rounded-xl bg-rose-500 hover:bg-rose-600 text-white text-sm font-bold transition-colors">
                                    Delete
                                </button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
}

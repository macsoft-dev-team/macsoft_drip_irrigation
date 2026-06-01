import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import { motion, AnimatePresence } from 'framer-motion';
import {
    Building2, Plus, Trash2, Pencil, Search,
    X, AlertCircle, Loader2, ChevronLeft, ChevronRight,
} from 'lucide-react';
import toast from 'react-hot-toast';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';

import { createCustomer, updateCustomer, deleteCustomer } from '../../reducers/customersSlice';
import { useCustomers } from '../../hooks/useCustomers';
import { useRole } from '../../hooks/useRole';

// ---------- Form Schema ----------
const schema = yup.object().shape({
    name: yup.string().required('Name is required'),
    email: yup.string().email('Invalid email').required('Email is required'),
});

// ---------- Customer Form Modal ----------
function CustomerFormModal({ customer, onClose, onSaved }) {
    const dispatch = useDispatch();
    const isEdit = !!customer;

    const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm({
        resolver: yupResolver(schema),
        defaultValues: {
            name: customer?.name || '',
            email: customer?.email || '',
        },
    });

    const onSubmit = async (data) => {
        const result = isEdit
            ? await dispatch(updateCustomer({ id: customer.id, data }))
            : await dispatch(createCustomer(data));

        if (result.error) {
            toast.error(result.payload || 'Operation failed');
        } else {
            toast.success(isEdit ? 'Customer updated' : 'Customer created');
            onSaved?.();
            onClose();
        }
    };

    const Field = ({ label, name, type = 'text' }) => (
        <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-600 uppercase tracking-wide">{label}</label>
            <input
                type={type}
                {...register(name)}
                className={`w-full px-3.5 py-2.5 text-sm font-medium rounded-xl border bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/30 transition-shadow ${errors[name] ? 'border-rose-400' : 'border-slate-200'}`}
            />
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
                        {isEdit ? 'Edit Customer' : 'Create Customer'}
                    </h2>
                    <button onClick={onClose} className="p-2 rounded-lg text-slate-400 hover:bg-slate-100 transition-colors">
                        <X className="w-4 h-4" />
                    </button>
                </div>

                <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-4">
                    <Field label="Company Name" name="name" />
                    <Field label="Email" name="email" type="email" />

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
                            {isEdit ? 'Save Changes' : 'Create Customer'}
                        </button>
                    </div>
                </form>
            </motion.div>
        </div>
    );
}

// ---------- Main Page ----------
export default function CustomersPage() {
    const { customers, totalPages, loading, page, search, handleSearch, handlePage, reload } = useCustomers();
    const { isMacsoftAdmin } = useRole();

    const [formTarget, setFormTarget] = useState(null); // null = closed, false = new, customer = edit
    const [deleteTarget, setDeleteTarget] = useState(null);
    const dispatch = useDispatch();

    const handleDelete = async () => {
        const result = await dispatch(deleteCustomer(deleteTarget.id));
        if (result.error) {
            toast.error(result.payload || 'Delete failed');
        } else {
            toast.success('Customer deleted');
            reload();
        }
        setDeleteTarget(null);
    };

    return (
        <div className="min-h-screen bg-slate-50 p-4 md:p-8 font-sans">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
                <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center shadow-lg shadow-emerald-500/20">
                        <Building2 className="w-6 h-6 text-white" />
                    </div>
                    <div>
                        <h1 className="text-xl font-extrabold text-slate-900 tracking-tight">CUSTOMERS</h1>
                        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Tenant / organisation management</p>
                    </div>
                </div>
                {isMacsoftAdmin() && (
                    <button
                        onClick={() => setFormTarget(false)}
                        className="inline-flex items-center gap-2 bg-slate-900 hover:bg-slate-800 text-white text-sm font-bold px-4 py-2.5 rounded-xl transition-colors shadow-sm"
                    >
                        <Plus className="w-4 h-4" /> Add Customer
                    </button>
                )}
            </div>

            {/* Search */}
            <div className="relative mb-5 max-w-sm">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none" />
                <input
                    type="text"
                    value={search}
                    onChange={(e) => handleSearch(e.target.value)}
                    placeholder="Search name or email…"
                    className="w-full pl-9 pr-4 py-2.5 text-sm font-medium border border-slate-200 rounded-xl bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/30"
                />
            </div>

            {/* Table */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                {loading ? (
                    <div className="flex items-center justify-center py-20 text-slate-400">
                        <Loader2 className="w-6 h-6 animate-spin mr-2" /> Loading…
                    </div>
                ) : customers.length === 0 ? (
                    <div className="flex flex-col items-center py-20 gap-3 text-slate-400">
                        <Building2 className="w-10 h-10 text-slate-200" />
                        <p className="font-semibold">No customers found</p>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead className="bg-slate-50 border-b border-slate-200">
                                <tr>
                                    {['Company Name', 'Email', 'Created', 'Actions'].map((h) => (
                                        <th key={h} className="px-5 py-3.5 text-left text-[11px] font-extrabold text-slate-500 uppercase tracking-wider">
                                            {h}
                                        </th>
                                    ))}
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {customers.map((c) => (
                                    <tr key={c.id} className="hover:bg-slate-50/50 transition-colors">
                                        <td className="px-5 py-4 font-semibold text-slate-800">{c.name || '—'}</td>
                                        <td className="px-5 py-4 text-slate-600">{c.email}</td>
                                        <td className="px-5 py-4 text-slate-500 text-xs">
                                            {new Date(c.createdAt).toLocaleDateString()}
                                        </td>
                                        <td className="px-5 py-4">
                                            <div className="flex items-center gap-1.5">
                                                {isMacsoftAdmin() && (
                                                    <>
                                                        <button
                                                            onClick={() => setFormTarget(c)}
                                                            className="p-1.5 rounded-lg text-blue-500 bg-blue-50 border border-blue-200 hover:bg-blue-100 transition-colors"
                                                            title="Edit"
                                                        >
                                                            <Pencil className="w-3.5 h-3.5" />
                                                        </button>
                                                        <button
                                                            onClick={() => setDeleteTarget(c)}
                                                            className="p-1.5 rounded-lg text-rose-500 bg-rose-50 border border-rose-200 hover:bg-rose-100 transition-colors"
                                                            title="Delete"
                                                        >
                                                            <Trash2 className="w-3.5 h-3.5" />
                                                        </button>
                                                    </>
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
                    <CustomerFormModal
                        customer={formTarget || null}
                        onClose={() => setFormTarget(null)}
                        onSaved={reload}
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
                                    <p className="font-extrabold text-slate-800">Delete Customer</p>
                                    <p className="text-sm text-slate-500">This action cannot be undone.</p>
                                </div>
                            </div>
                            <p className="text-sm text-slate-600 font-medium">
                                Are you sure you want to delete <span className="font-bold text-slate-800">{deleteTarget.name || deleteTarget.email}</span>?
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

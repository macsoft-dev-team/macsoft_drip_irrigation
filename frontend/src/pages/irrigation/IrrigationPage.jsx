import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { motion, AnimatePresence } from 'framer-motion';
import {
    ChevronDown, ChevronRight, Plus, Pencil, Trash2,
    Grid, Trees, Droplet, Loader2, X, AlertCircle
} from 'lucide-react';
import toast from 'react-hot-toast';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';

import {
    fetchFields, createField, updateField, deleteField,
    createZone, updateZone, deleteZone,
    createValve, updateValve, deleteValve
} from '../../reducers/irrigationSlice';
import { fetchCustomers } from '../../reducers/customersSlice';
import { useRole } from '../../hooks/useRole';

// ---------- Form Schema ----------
const schema = yup.object().shape({
    name: yup.string().required('Name is required'),
    customerId: yup.string().optional(),
});

function IrrigationFormModal({ target, onClose, onSaved }) {
    const dispatch = useDispatch();
    const { isMacsoftAdmin } = useRole();
    const { customers } = useSelector((s) => s.customers);
    
    const isEdit = target.action === 'edit';
    const typeLabel = target.type.charAt(0).toUpperCase() + target.type.slice(1);

    const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm({
        resolver: yupResolver(schema),
        defaultValues: {
            name: isEdit ? target.data.name : '',
            customerId: target.type === 'field' ? (target.data?.customerId || '') : '',
        },
    });

    useEffect(() => {
        if (target.type === 'field' && isMacsoftAdmin()) {
            dispatch(fetchCustomers({ take: 200 }));
        }
    }, [dispatch, target.type, isMacsoftAdmin]);

    const onSubmit = async (formData) => {
        let result;
        if (target.type === 'field') {
            if (isEdit) {
                result = await dispatch(updateField({ id: target.data.id, data: { name: formData.name } }));
            } else {
                result = await dispatch(createField({
                    name: formData.name,
                    customerId: isMacsoftAdmin() ? formData.customerId : undefined
                }));
            }
        } else if (target.type === 'zone') {
            if (isEdit) {
                result = await dispatch(updateZone({ id: target.data.id, data: { name: formData.name } }));
            } else {
                result = await dispatch(createZone({ name: formData.name, fieldId: target.parent.id }));
            }
        } else if (target.type === 'valve') {
            if (isEdit) {
                result = await dispatch(updateValve({
                    id: target.data.id,
                    data: { name: formData.name },
                    fieldId: target.parent.fieldId,
                    zoneId: target.parent.id
                }));
            } else {
                result = await dispatch(createValve({
                    data: { name: formData.name, zoneId: target.parent.id },
                    fieldId: target.parent.fieldId
                }));
            }
        }

        if (result.error) {
            toast.error(result.payload || 'Operation failed');
        } else {
            toast.success(isEdit ? `${typeLabel} updated` : `${typeLabel} created`);
            onSaved?.();
            onClose();
        }
    };

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
                        {isEdit ? `Edit ${typeLabel}` : `Create ${typeLabel}`}
                    </h2>
                    <button onClick={onClose} className="p-2 rounded-lg text-slate-400 hover:bg-slate-100 transition-colors">
                        <X className="w-4 h-4" />
                    </button>
                </div>

                <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-4">
                    <div className="space-y-1.5">
                        <label className="text-xs font-bold text-slate-600 uppercase tracking-wide">Name</label>
                        <input
                            type="text"
                            {...register('name')}
                            placeholder={`Enter ${target.type} name...`}
                            className={`w-full px-3.5 py-2.5 text-sm font-medium rounded-xl border bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/30 transition-shadow ${errors.name ? 'border-rose-400' : 'border-slate-200'}`}
                        />
                        {errors.name && (
                            <p className="text-[11px] font-bold text-rose-500 flex items-center gap-1">
                                <AlertCircle className="w-3 h-3" /> {errors.name.message}
                            </p>
                        )}
                    </div>

                    {target.type === 'field' && isMacsoftAdmin() && !isEdit && (
                        <div className="space-y-1.5">
                            <label className="text-xs font-bold text-slate-600 uppercase tracking-wide">Assign Customer</label>
                            <select
                                {...register('customerId')}
                                className="w-full px-3.5 py-2.5 text-sm font-medium rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-blue-500/30 transition-shadow"
                            >
                                <option value="">Select a customer...</option>
                                {customers.map((c) => (
                                    <option key={c.id} value={c.id}>{c.name || c.email}</option>
                                ))}
                            </select>
                        </div>
                    )}

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
                            {isEdit ? 'Save Changes' : `Create ${typeLabel}`}
                        </button>
                    </div>
                </form>
            </motion.div>
        </div>
    );
}

export default function IrrigationPage() {
    const dispatch = useDispatch();
    const { fields, loading, error } = useSelector((s) => s.irrigation);
    const { user } = useSelector((s) => s.auth);
    const { isMacsoftAdmin } = useRole();

    const [expandedFields, setExpandedFields] = useState({});
    const [expandedZones, setExpandedZones] = useState({});
    
    const [formTarget, setFormTarget] = useState(null); // null or { type, action, parent, data }
    const [deleteTarget, setDeleteTarget] = useState(null); // null or { type, id, parent, name }

    useEffect(() => {
        dispatch(fetchFields());
    }, [dispatch]);

    const toggleField = (id) => {
        setExpandedFields((prev) => ({ ...prev, [id]: !prev[id] }));
    };

    const toggleZone = (id) => {
        setExpandedZones((prev) => ({ ...prev, [id]: !prev[id] }));
    };

    const handleDelete = async () => {
        let result;
        if (deleteTarget.type === 'field') {
            result = await dispatch(deleteField(deleteTarget.id));
        } else if (deleteTarget.type === 'zone') {
            result = await dispatch(deleteZone({ id: deleteTarget.id, fieldId: deleteTarget.parent.id }));
        } else if (deleteTarget.type === 'valve') {
            result = await dispatch(deleteValve({
                id: deleteTarget.id,
                fieldId: deleteTarget.parent.fieldId,
                zoneId: deleteTarget.parent.id
            }));
        }

        if (result.error) {
            toast.error(result.payload || 'Delete failed');
        } else {
            toast.success(`${deleteTarget.type.charAt(0).toUpperCase() + deleteTarget.type.slice(1)} deleted`);
        }
        setDeleteTarget(null);
    };

    return (
        <div className="min-h-screen bg-slate-50 p-4 md:p-8 font-sans">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
                <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-lg shadow-blue-500/20">
                        <Grid className="w-6 h-6 text-white" />
                    </div>
                    <div>
                        <h1 className="text-xl font-extrabold text-slate-900 tracking-tight">IRRIGATION FIELDS</h1>
                        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Fields, Zones & Valves Layout</p>
                    </div>
                </div>
                <button
                    onClick={() => setFormTarget({ type: 'field', action: 'create', parent: null, data: null })}
                    className="inline-flex items-center gap-2 bg-slate-900 hover:bg-slate-800 text-white text-sm font-bold px-4 py-2.5 rounded-xl transition-colors shadow-sm"
                >
                    <Plus className="w-4 h-4" /> Add Field
                </button>
            </div>

            {/* Tree */}
            <div className="space-y-4 max-w-4xl">
                {loading && fields.length === 0 ? (
                    <div className="flex items-center justify-center py-20 text-slate-400">
                        <Loader2 className="w-6 h-6 animate-spin mr-2" /> Loading Irrigation Layout…
                    </div>
                ) : error ? (
                    <div className="p-4 bg-rose-50 border border-rose-200 text-rose-700 text-sm font-bold rounded-xl flex items-center gap-2">
                        <AlertCircle className="w-4 h-4" /> {error}
                    </div>
                ) : fields.length === 0 ? (
                    <div className="flex flex-col items-center py-20 gap-3 text-slate-400 bg-white rounded-2xl border border-slate-200 shadow-sm">
                        <Grid className="w-10 h-10 text-slate-200" />
                        <p className="font-semibold">No fields found</p>
                        <button
                            onClick={() => setFormTarget({ type: 'field', action: 'create', parent: null, data: null })}
                            className="text-sm font-bold text-blue-600 hover:text-blue-700"
                        >
                            Create one now
                        </button>
                    </div>
                ) : (
                    fields.map((field) => {
                        const isFieldExpanded = !!expandedFields[field.id];
                        return (
                            <div key={field.id} className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden transition-all">
                                {/* Field Header */}
                                <div className="flex items-center justify-between p-4 hover:bg-slate-50/50 cursor-pointer" onClick={() => toggleField(field.id)}>
                                    <div className="flex items-center gap-3">
                                        <div className="w-9 h-9 rounded-xl bg-blue-50 border border-blue-200 flex items-center justify-center">
                                            <Trees className="w-5 h-5 text-blue-600" />
                                        </div>
                                        <div>
                                            <p className="font-bold text-slate-800">{field.name}</p>
                                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Field</p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
                                        <button
                                            onClick={() => setFormTarget({ type: 'field', action: 'edit', parent: null, data: field })}
                                            className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors"
                                            title="Edit Field"
                                        >
                                            <Pencil className="w-4 h-4" />
                                        </button>
                                        <button
                                            onClick={() => setDeleteTarget({ type: 'field', id: field.id, parent: null, name: field.name })}
                                            className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 hover:text-rose-600 transition-colors"
                                            title="Delete Field"
                                        >
                                            <Trash2 className="w-4 h-4" />
                                        </button>
                                        <button className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors" onClick={() => toggleField(field.id)}>
                                            {isFieldExpanded ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
                                        </button>
                                    </div>
                                </div>

                                {/* Expanded Zones */}
                                <AnimatePresence initial={false}>
                                    {isFieldExpanded && (
                                        <motion.div
                                            initial={{ height: 0 }}
                                            animate={{ height: 'auto' }}
                                            exit={{ height: 0 }}
                                            className="overflow-hidden bg-slate-50/50 border-t border-slate-100"
                                        >
                                            <div className="p-4 pl-8 space-y-3">
                                                {field.zones?.length === 0 ? (
                                                    <p className="text-xs font-semibold text-slate-400 italic">No zones created in this field.</p>
                                                ) : (
                                                    field.zones?.map((zone) => {
                                                        const isZoneExpanded = !!expandedZones[zone.id];
                                                        return (
                                                            <div key={zone.id} className="bg-white border border-slate-100 rounded-xl overflow-hidden shadow-sm">
                                                                {/* Zone Header */}
                                                                <div className="flex items-center justify-between p-3 cursor-pointer hover:bg-slate-50/50" onClick={() => toggleZone(zone.id)}>
                                                                    <div className="flex items-center gap-2.5">
                                                                        <Grid className="w-4.5 h-4.5 text-emerald-600" />
                                                                        <div>
                                                                            <p className="text-sm font-bold text-slate-700">{zone.name}</p>
                                                                            <p className="text-[9px] font-bold text-slate-400 uppercase tracking-wider">Zone</p>
                                                                        </div>
                                                                    </div>
                                                                    <div className="flex items-center gap-1.5" onClick={(e) => e.stopPropagation()}>
                                                                        <button
                                                                            onClick={() => setFormTarget({ type: 'zone', action: 'edit', parent: field, data: zone })}
                                                                            className="p-1 rounded-md text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors"
                                                                            title="Edit Zone"
                                                                        >
                                                                            <Pencil className="w-3.5 h-3.5" />
                                                                        </button>
                                                                        <button
                                                                            onClick={() => setDeleteTarget({ type: 'zone', id: zone.id, parent: field, name: zone.name })}
                                                                            className="p-1 rounded-md text-slate-400 hover:bg-slate-100 hover:text-rose-600 transition-colors"
                                                                            title="Delete Zone"
                                                                        >
                                                                            <Trash2 className="w-3.5 h-3.5" />
                                                                        </button>
                                                                        <button className="p-1 rounded-md text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors" onClick={() => toggleZone(zone.id)}>
                                                                            {isZoneExpanded ? <ChevronDown className="w-3.5 h-3.5" /> : <ChevronRight className="w-3.5 h-3.5" />}
                                                                        </button>
                                                                    </div>
                                                                </div>

                                                                {/* Expanded Valves */}
                                                                <AnimatePresence initial={false}>
                                                                    {isZoneExpanded && (
                                                                        <motion.div
                                                                            initial={{ height: 0 }}
                                                                            animate={{ height: 'auto' }}
                                                                            exit={{ height: 0 }}
                                                                            className="overflow-hidden bg-slate-50/20 border-t border-slate-100"
                                                                        >
                                                                            <div className="p-3 pl-8 space-y-2">
                                                                                {zone.valves?.length === 0 ? (
                                                                                    <p className="text-xs font-semibold text-slate-400 italic">No valves created in this zone.</p>
                                                                                ) : (
                                                                                    zone.valves?.map((valve) => (
                                                                                        <div key={valve.id} className="flex items-center justify-between p-2 hover:bg-slate-50 rounded-lg">
                                                                                            <div className="flex items-center gap-2">
                                                                                                <Droplet className="w-4 h-4 text-blue-500" />
                                                                                                <span className="text-xs font-bold text-slate-600">{valve.name}</span>
                                                                                            </div>
                                                                                            <div className="flex items-center gap-1">
                                                                                                <button
                                                                                                    onClick={() => setFormTarget({ type: 'valve', action: 'edit', parent: zone, data: valve })}
                                                                                                    className="p-1 rounded text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors"
                                                                                                    title="Edit Valve"
                                                                                                >
                                                                                                    <Pencil className="w-3 h-3" />
                                                                                                </button>
                                                                                                <button
                                                                                                    onClick={() => setDeleteTarget({ type: 'valve', id: valve.id, parent: zone, name: valve.name })}
                                                                                                    className="p-1 rounded text-slate-400 hover:bg-slate-100 hover:text-rose-600 transition-colors"
                                                                                                    title="Delete Valve"
                                                                                                >
                                                                                                    <Trash2 className="w-3 h-3" />
                                                                                                </button>
                                                                                            </div>
                                                                                        </div>
                                                                                    ))
                                                                                )}
                                                                                <button
                                                                                    onClick={() => setFormTarget({ type: 'valve', action: 'create', parent: zone, data: null })}
                                                                                    className="mt-2 text-xs font-bold text-blue-600 hover:text-blue-700 flex items-center gap-1"
                                                                                >
                                                                                    <Plus className="w-3.5 h-3.5" /> Add Valve
                                                                                </button>
                                                                            </div>
                                                                        </motion.div>
                                                                    )}
                                                                </AnimatePresence>
                                                            </div>
                                                        );
                                                    })
                                                )}
                                                <button
                                                    onClick={() => setFormTarget({ type: 'zone', action: 'create', parent: field, data: null })}
                                                    className="mt-3 text-xs font-bold text-blue-600 hover:text-blue-700 flex items-center gap-1"
                                                >
                                                    <Plus className="w-3.5 h-3.5" /> Add Zone
                                                </button>
                                            </div>
                                        </motion.div>
                                    )}
                                </AnimatePresence>
                            </div>
                        );
                    })
                )}
            </div>

            {/* Form Modals */}
            <AnimatePresence>
                {formTarget !== null && (
                    <IrrigationFormModal
                        target={formTarget}
                        onClose={() => setFormTarget(null)}
                        onSaved={() => dispatch(fetchFields())}
                    />
                )}
            </AnimatePresence>

            {/* Delete Modal */}
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
                                    <p className="font-extrabold text-slate-800">Delete {deleteTarget.type.charAt(0).toUpperCase() + deleteTarget.type.slice(1)}</p>
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

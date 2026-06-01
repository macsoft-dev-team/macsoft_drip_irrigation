import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { createDevice } from '../../reducers/deviceSlice';
import toast from 'react-hot-toast';
import { Eye, EyeOff } from 'lucide-react';

const MODELS = [
    { label: '1+1 Pump', sublabel: '2 Pump', pumpCount: 2, value: 'MODEL_1P1' },
    { label: '2+1 Pump', sublabel: '3 Pump', pumpCount: 3, value: 'MODEL_2P1' },
    { label: '3+1 Pump', sublabel: '4 Pump', pumpCount: 4, value: 'MODEL_3P1' },
    { label: '4+1 Pump', sublabel: '5 Pump', pumpCount: 5, value: 'MODEL_4P1' },
];

const MOCK_DEVICE = {
    code: '356938035643809',
    imeinumber: '356938035643809',
    latitude: '3.1390',
    longitude: '101.6869',
    mqttClientId: 'client_356938035643809',
    mqttUsername: 'mqtt_356938035643809',
    mqttPassword: '356938035643809',
    mqttTelemetryTopic: 'device/356938035643809/data',
    mqttCommandTopic: 'device/356938035643809/cmd',
    mqttAckTopic: 'device/356938035643809/cmd/res',
};

function Field({ label, error, children }) {
    return (
        <div className="flex flex-col gap-1">
            <label className="text-xs font-semibold text-slate-500 uppercase tracking-wide">{label}</label>
            {children}
            {error && <span className="text-[11px] text-rose-500 font-semibold">{error}</span>}
        </div>
    );
}

function TextInput({ registration, error, type = 'text', placeholder }) {
    return (
        <input
            type={type}
            placeholder={placeholder}
            {...registration}
            className={`w-full px-3 py-2.5 text-sm rounded-xl border bg-white focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-400 transition-colors ${
                error ? 'border-rose-400' : 'border-slate-200'
            } text-slate-800 placeholder:text-slate-400`}
        />
    );
}

function PasswordInput({ registration, error, placeholder }) {
    const [show, setShow] = useState(false);
    return (
        <div className={`flex items-center w-full rounded-xl border bg-white focus-within:ring-2 focus-within:ring-blue-400/40 focus-within:border-blue-400 transition-colors ${
            error ? 'border-rose-400' : 'border-slate-200'
        }`}>
            <input
                type={show ? 'text' : 'password'}
                placeholder={placeholder}
                {...registration}
                className="flex-1 px-3 py-2.5 text-sm bg-transparent focus:outline-none text-slate-800 placeholder:text-slate-400"
            />
            <button
                type="button"
                onClick={() => setShow((v) => !v)}
                className="pr-3 text-slate-400 hover:text-slate-600 transition-colors"
                tabIndex={-1}
            >
                {show ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
            </button>
        </div>
    );
}

export default function AddDevice() {
    const {
        register,
        handleSubmit,
        reset,
        setValue,
        getValues,
        formState: { errors },
    } = useForm();
    const dispatch = useDispatch();
    const navigate = useNavigate();
    const loading = useSelector((s) => s.devices.loading);
    const [selectedModel, setSelectedModel] = useState(null);

    const generateMqttFields = (imei) => {
        if (!String(getValues('code') || '').trim()) {
            setValue('code', imei);
        }
        setValue('mqttClientId',       `client_${imei}`);
        setValue('mqttUsername',        `mqtt_${imei}`);
        setValue('mqttPassword',        imei);
        setValue('mqttTelemetryTopic',  `device/${imei}/data`);
        setValue('mqttCommandTopic',    `device/${imei}/cmd`);
        setValue('mqttAckTopic',        `device/${imei}/cmd/res`);
    };

    const handleModelSelect = (model) => {
        setSelectedModel(model.value);
        setValue('pumpModel', model.value);
    };

    const onSubmit = async (data) => {
        if (!selectedModel) {
            toast.error('Please select a pump model.');
            return;
        }
        const payload = Object.fromEntries(
            Object.entries(data).map(([key, value]) => [
                key,
                typeof value === 'string' ? value.trim() : value,
            ])
        );
        const result = await dispatch(createDevice(payload));
        if (createDevice.fulfilled.match(result)) {
            toast.success('Device created successfully.');
            navigate('/devices');
        } else {
            toast.error(result.payload || 'Failed to create device.');
        }
    };

    const fillMock = () => {
        reset(MOCK_DEVICE);
        setSelectedModel('MODEL_1P1');
        setValue('pumpModel', 'MODEL_1P1');
    };

    return (
        <div className="p-6 max-w-6xl mx-auto">
            <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6 space-y-8">
                {/* Header */}
                <div className="flex items-center justify-between">
                    <div>
                        <h2 className="text-xl font-bold text-slate-800 tracking-tight">Provision New Device</h2>
                        <p className="text-xs text-slate-400 mt-0.5">Fill in device details to register it in the system.</p>
                    </div>
                    <button
                        type="button"
                        onClick={fillMock}
                        className="text-xs font-semibold px-4 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 text-slate-600 transition-colors"
                    >
                        Fill Mock Data
                    </button>
                </div>

                <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
                    {/* Hidden field */}
                    <input type="hidden" {...register('pumpModel', { required: true })} />

                    {/* BASIC INFORMATION */}
                    <section>
                        <h3 className="text-xs font-bold uppercase tracking-widest text-slate-400 mb-4 border-b border-slate-100 pb-2">
                            Basic Information
                        </h3>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                            <Field label="Device Code" error={errors.code?.message}>
                                <TextInput
                                    registration={register('code')}
                                    error={errors.code}
                                    placeholder="Defaults to IMEI"
                                />
                            </Field>
                            <Field label="IMEI Number" error={errors.imeinumber?.message}>
                                <TextInput
                                    registration={register('imeinumber', {
                                        required: 'IMEI is required',
                                        pattern: { value: /^\d{15}$/, message: 'Must be exactly 15 digits' },
                                        onChange: (e) => {
                                            const v = e.target.value.trim();
                                            if (/^\d{15}$/.test(v)) generateMqttFields(v);
                                        },
                                    })}
                                    error={errors.imeinumber}
                                    placeholder="15-digit IMEI"
                                />
                            </Field>
                            <Field label="Latitude">
                                <TextInput
                                    registration={register('latitude')}
                                    placeholder="3.1390"
                                />
                            </Field>
                            <Field label="Longitude">
                                <TextInput
                                    registration={register('longitude')}
                                    placeholder="101.6869"
                                />
                            </Field>
                        </div>
                    </section>

                    {/* MODEL SELECTION */}
                    <section>
                        <h3 className="text-xs font-bold uppercase tracking-widest text-slate-400 mb-1 border-b border-slate-100 pb-2">
                            Model Selection
                        </h3>
                        <p className="text-xs text-slate-400 mb-4">
                            Select the pump configuration. This determines the number of active pumps.
                        </p>
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                            {MODELS.map((model) => {
                                const active = selectedModel === model.value;
                                return (
                                    <button
                                        key={model.value}
                                        type="button"
                                        onClick={() => handleModelSelect(model)}
                                        className={`relative flex flex-col items-start gap-1 rounded-xl border-2 px-5 py-4 text-left transition-all focus:outline-none ${
                                            active
                                                ? 'border-cyan-500 bg-cyan-50 shadow-sm'
                                                : 'border-slate-200 hover:border-cyan-400/50 bg-white'
                                        }`}
                                    >
                                        <span
                                            className={`mb-1 flex items-center justify-center w-4 h-4 rounded-full border-2 transition-colors ${
                                                active ? 'border-cyan-500 bg-cyan-500' : 'border-slate-400'
                                            }`}
                                        >
                                            {active && <span className="w-1.5 h-1.5 rounded-full bg-white" />}
                                        </span>
                                        <span className={`text-sm font-semibold ${active ? 'text-cyan-600' : 'text-slate-700'}`}>
                                            {model.label}
                                        </span>
                                        <span className="text-xs text-slate-500">{model.sublabel}</span>
                                        <span
                                            className={`mt-2 text-xs font-mono px-2 py-0.5 rounded-full ${
                                                active
                                                    ? 'bg-cyan-500/20 text-cyan-600'
                                                    : 'bg-slate-100 text-slate-500'
                                            }`}
                                        >
                                            {model.pumpCount} pumps
                                        </span>
                                    </button>
                                );
                            })}
                        </div>
                        {!selectedModel && (
                            <p className="mt-2 text-xs text-amber-500 font-semibold">Please select a model.</p>
                        )}
                    </section>

                    {/* MQTT CONFIG */}
                    <section>
                        <h3 className="text-xs font-bold uppercase tracking-widest text-slate-400 mb-4 border-b border-slate-100 pb-2">
                            MQTT Configuration
                        </h3>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                            <Field label="Client ID">
                                <TextInput registration={register('mqttClientId')} placeholder="client-dev001" />
                            </Field>
                            <Field label="Username">
                                <TextInput registration={register('mqttUsername')} placeholder="mqtt_user" />
                            </Field>
                            <Field label="Password">
                                <PasswordInput registration={register('mqttPassword')} placeholder="••••••••" />
                            </Field>
                            <Field label="Telemetry Topic">
                                <TextInput registration={register('mqttTelemetryTopic')} placeholder="device/IMEI/data" />
                            </Field>
                            <Field label="Command Topic">
                                <TextInput registration={register('mqttCommandTopic')} placeholder="device/IMEI/cmd" />
                            </Field>
                            <Field label="Ack Topic">
                                <TextInput registration={register('mqttAckTopic')} placeholder="device/IMEI/cmd/res" />
                            </Field>
                        </div>
                    </section>

                    {/* ACTIONS */}
                    <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
                        <button
                            type="button"
                            onClick={() => reset()}
                            disabled={loading}
                            className="px-5 py-2.5 rounded-xl text-sm font-semibold border border-slate-200 hover:bg-slate-50 text-slate-600 transition-colors disabled:opacity-50"
                        >
                            Reset
                        </button>
                        <button
                            type="button"
                            onClick={() => navigate('/devices')}
                            disabled={loading}
                            className="px-5 py-2.5 rounded-xl text-sm font-semibold bg-rose-50 border border-rose-200 text-rose-600 hover:bg-rose-100 transition-colors disabled:opacity-50"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={loading}
                            className="px-6 py-2.5 rounded-xl text-sm font-bold bg-blue-600 hover:bg-blue-700 text-white transition-colors disabled:opacity-50 shadow-sm shadow-blue-200"
                        >
                            {loading ? 'Creating…' : 'Create Device'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}

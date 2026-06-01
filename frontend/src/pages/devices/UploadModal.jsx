import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { X, FileUp, FileText, Loader2, CheckCircle2, AlertCircle, Upload, Download } from 'lucide-react';
import * as XLSX from 'xlsx';
import toast from 'react-hot-toast';
import { useDevice } from '../../hooks/useDevice';

export default function UploadModal({ isOpen, onClose, onUpload }) {
    const [selectedFile, setSelectedFile] = useState(null);
    const [isUploading, setIsUploading] = useState(false);

    // Validation States
    const [isProcessing, setIsProcessing] = useState(false);
    const [validationResults, setValidationResults] = useState(null);
    const [validImeis, setValidImeis] = useState([]);

    const { uploadDevice } = useDevice();

    const resetState = () => {
        setSelectedFile(null);
        setValidationResults(null);
        setIsProcessing(false);
        setIsUploading(false);
        setValidImeis([]);
    };

    const handleClose = () => {
        resetState();
        onClose();
    };

    // --- Generate & Download Sample Template ---
    const downloadSampleTemplate = () => {
        // 1. Define the 5 sample rows (mock IMEIs commented out for now)
        const sampleData = [
            // { imeinumber: "861234567890123" },
            // { imeinumber: "869876543210987" },
            // { imeinumber: "861112223334445" },
            // { imeinumber: "865556667778889" },
            // { imeinumber: "860009998887776" },
            { imeinumber: "" },
        ];

        // 2. Convert to an Excel Worksheet
        const worksheet = XLSX.utils.json_to_sheet(sampleData);

        // Auto-size the column to make it look neat
        worksheet['!cols'] = [{ wch: 20 }];

        // 3. Create a new Workbook and append the sheet
        const workbook = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbook, worksheet, "Sample_Devices");

        // 4. Trigger the download automatically
        XLSX.writeFile(workbook, "Device_Import_Template.xlsx");
    };

    // --- Core File Reading & Validation Logic ---
    const processFile = (file) => {
        setIsProcessing(true);
        const reader = new FileReader();

        reader.onload = (e) => {
            try {
                const data = new Uint8Array(e.target.result);
                const workbook = XLSX.read(data, { type: 'array' });

                const worksheetName = workbook.SheetNames[0];
                const worksheet = workbook.Sheets[worksheetName];
                const jsonData = XLSX.utils.sheet_to_json(worksheet);

                let parsedImeis = [];
                let errors = [];

                jsonData.forEach((row, index) => {
                    const imeiKey = Object.keys(row).find(key => key.toLowerCase().trim() === 'imeinumber');
                    const imeiValue = imeiKey ? String(row[imeiKey]).trim() : '';
                    const rowNumber = index + 2;

                    if (!imeiValue) {
                        errors.push({ row: rowNumber, message: 'Missing imeinumber value' });
                    } else if (!/^\d{15}$/.test(imeiValue)) {
                        errors.push({ row: rowNumber, value: imeiValue, message: 'Must be exactly 15 digits' });
                    } else {
                        parsedImeis.push(imeiValue);
                    }
                });

                setValidImeis(parsedImeis);
                setValidationResults({
                    total: jsonData.length,
                    valid: parsedImeis.length,
                    errors: errors
                });

            } catch (error) {
                console.error("Error parsing file:", error);
                setValidationResults({ total: 0, valid: 0, errors: [{ row: '-', message: 'Failed to parse file. Ensure it is a valid Excel/CSV.' }] });
            } finally {
                setIsProcessing(false);
            }
        };

        reader.readAsArrayBuffer(file);
    };

    const handleFileChange = (e) => {
        if (e.target.files && e.target.files.length > 0) {
            const file = e.target.files[0];
            setSelectedFile(file);
            processFile(file);
        }
    };

    const handleFileUpload = async () => {
        if (!selectedFile || validationResults?.errors.length > 0) return;
        setIsUploading(true);

        try {
            const res = await uploadDevice(validImeis);

            if (res.error) {
                toast.error(res.payload || 'Upload failed');
                setIsUploading(false);
                return;
            }

            onUpload?.(validImeis, res);
            handleClose();
        } catch (err) {
            console.error('Upload failed', err);
            toast.error('Upload failed — please try again');
            setIsUploading(false);
        }
    };

    return (
        <AnimatePresence>
            {isOpen && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm">
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, y: 10 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95, y: 10 }}
                        transition={{ duration: 0.2 }}
                        className="bg-white rounded-[24px] shadow-2xl w-full max-w-lg overflow-hidden flex flex-col border border-slate-100"
                    >
                        {/* Modal Header */}
                        <div className="px-6 py-5 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-white rounded-xl shadow-sm border border-slate-100">
                                    <FileUp className="w-5 h-5 text-blue-600" />
                                </div>
                                <div>
                                    <h3 className="text-lg font-bold text-slate-800 tracking-tight">Import Devices</h3>
                                    <p className="text-xs text-slate-500 font-medium">Upload an Excel or CSV file</p>
                                </div>
                            </div>
                            <button onClick={handleClose} className="p-2 text-slate-400 hover:text-slate-700 hover:bg-slate-200/50 rounded-full transition-colors">
                                <X className="w-5 h-5" />
                            </button>
                        </div>

                        {/* Modal Body */}
                        <div className="p-6 bg-white">
                            {!selectedFile ? (
                                <div className="space-y-4">
                                    <div className="relative group">
                                        <input type="file" accept=".csv, .xlsx, .xls" onChange={handleFileChange} className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10" />
                                        <div className="border-2 border-dashed border-slate-200/80 rounded-2xl bg-slate-50/50 group-hover:bg-blue-50/30 group-hover:border-blue-300 transition-colors duration-300 p-10 flex flex-col items-center justify-center text-center gap-4">
                                            <div className="p-4 bg-white rounded-full shadow-sm border border-slate-100 group-hover:scale-110 transition-transform duration-300">
                                                <Upload className="w-6 h-6 text-blue-500" />
                                            </div>
                                            <div>
                                                <p className="text-sm font-bold text-slate-700 mb-1">Click to upload or drag and drop</p>
                                                <p className="text-xs text-slate-500 font-medium">Excel or CSV (Must contain 'IMEI' column)</p>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Download Template Button */}
                                    <div className="flex justify-center">
                                        <button
                                            onClick={downloadSampleTemplate}
                                            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-bold text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-colors"
                                        >
                                            <Download className="w-4 h-4" />
                                            Download sample template
                                        </button>
                                    </div>
                                </div>
                            ) : (
                                <div className="space-y-4">
                                    {/* File Info */}
                                    <div className="p-4 border border-blue-100 bg-blue-50/50 rounded-2xl flex items-center justify-between">
                                        <div className="flex items-center gap-4">
                                            <div className="p-3 bg-white rounded-xl text-blue-600 shadow-sm border border-blue-100/50">
                                                {isProcessing ? <Loader2 className="w-6 h-6 animate-spin" /> : <FileText className="w-6 h-6" />}
                                            </div>
                                            <div>
                                                <p className="text-sm font-bold text-slate-800 line-clamp-1 mb-0.5">{selectedFile.name}</p>
                                                <p className="text-xs text-slate-500 font-semibold">{(selectedFile.size / 1024).toFixed(1)} KB</p>
                                            </div>
                                        </div>
                                        <button onClick={resetState} className="text-slate-400 hover:text-rose-500 hover:bg-rose-50 p-2 rounded-lg transition-colors" disabled={isUploading || isProcessing}>
                                            <X className="w-4 h-4" />
                                        </button>
                                    </div>

                                    {/* Validation Results */}
                                    {validationResults && !isProcessing && (
                                        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="pt-2">
                                            {validationResults.errors.length === 0 ? (
                                                <div className="space-y-3">
                                                    <div className="flex items-center gap-3 p-4 bg-emerald-50 border border-emerald-100 rounded-xl text-emerald-700">
                                                        <CheckCircle2 className="w-5 h-5 shrink-0" />
                                                        <div>
                                                            <p className="text-sm font-bold">Validation Successful</p>
                                                            <p className="text-xs font-medium opacity-80">{validationResults.valid} valid devices found ready for import.</p>
                                                        </div>
                                                    </div>
                                                    {/* Uploaded IMEI list */}
                                                    <div className="border border-slate-100 rounded-xl overflow-hidden">
                                                        <div className="px-4 py-2.5 bg-slate-50 border-b border-slate-100">
                                                            <p className="text-xs font-bold text-slate-500 uppercase tracking-wider">IMEI Numbers ({validImeis.length})</p>
                                                        </div>
                                                        <ul className="max-h-36 overflow-y-auto divide-y divide-slate-50 bg-white">
                                                            {validImeis.map((imei, i) => (
                                                                <li key={i} className="flex items-center gap-3 px-4 py-2">
                                                                    <span className="text-xs font-semibold text-slate-400 w-5 text-right shrink-0">{i + 1}</span>
                                                                    <span className="font-mono text-xs text-slate-700 font-medium">{imei}</span>
                                                                </li>
                                                            ))}
                                                        </ul>
                                                    </div>
                                                </div>
                                            ) : (
                                                <div className="border border-rose-100 rounded-xl overflow-hidden">
                                                    <div className="flex items-center gap-3 p-4 bg-rose-50 text-rose-700 border-b border-rose-100">
                                                        <AlertCircle className="w-5 h-5 shrink-0" />
                                                        <div>
                                                            <p className="text-sm font-bold">Validation Failed</p>
                                                            <p className="text-xs font-medium opacity-80">Found {validationResults.errors.length} errors in your file. Please fix them and re-upload.</p>
                                                        </div>
                                                    </div>
                                                    <div className="max-h-32 overflow-y-auto bg-white p-2">
                                                        <table className="w-full text-left text-xs">
                                                            <thead className="text-slate-400 font-semibold sticky top-0 bg-white">
                                                                <tr>
                                                                    <th className="px-3 py-2">Row</th>
                                                                    <th className="px-3 py-2">Value</th>
                                                                    <th className="px-3 py-2">Error</th>
                                                                </tr>
                                                            </thead>
                                                            <tbody className="divide-y divide-slate-50">
                                                                {validationResults.errors.map((err, i) => (
                                                                    <tr key={i} className="text-slate-600">
                                                                        <td className="px-3 py-2 font-medium text-slate-900">{err.row}</td>
                                                                        <td className="px-3 py-2 font-mono text-[10px]">{err.value || 'N/A'}</td>
                                                                        <td className="px-3 py-2 text-rose-600 font-medium">{err.message}</td>
                                                                    </tr>
                                                                ))}
                                                            </tbody>
                                                        </table>
                                                    </div>
                                                </div>
                                            )}
                                        </motion.div>
                                    )}
                                </div>
                            )}
                        </div>

                        {/* Modal Footer */}
                        <div className="px-6 py-5 border-t border-slate-100 flex items-center justify-between gap-3 bg-slate-50/50">
                            <span className="text-xs font-semibold text-slate-400">Excel must have an 'imeinumber' column header</span>
                            <div className="flex gap-2">
                                <button onClick={handleClose} className="px-5 py-2.5 text-sm font-bold text-slate-600 hover:bg-slate-200/50 rounded-xl transition-colors" disabled={isUploading}>
                                    Cancel
                                </button>
                                <button
                                    onClick={handleFileUpload}
                                    disabled={!selectedFile || isProcessing || isUploading || validationResults?.errors.length > 0}
                                    className="px-5 py-2.5 text-sm truncate font-bold text-white bg-blue-600 hover:bg-blue-700 disabled:bg-slate-300 disabled:text-slate-500 disabled:cursor-not-allowed rounded-xl transition-colors flex items-center gap-2 shadow-[0_4px_14px_0_rgba(37,99,235,0.2)]"
                                >
                                    {isUploading ? <><Loader2 className="w-4 h-4 animate-spin" /> Processing...</> : "Confirm Import"}
                                </button>
                            </div>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>
    );
}
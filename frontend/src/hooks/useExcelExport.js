// src/hooks/useExcelExport.js
import { useCallback } from 'react';
import * as XLSX from 'xlsx';

export const useExcelExport = () => {
    const exportToExcel = useCallback((data, columns, filename) => {
        if (!data || data.length === 0) return;

        const formattedData = data.map(row => {
            const out = {};
            columns.forEach(({ key, label, format }) => {
                out[label] = format ? format(row[key]) : row[key];
            });
            return out;
        });

        const ws = XLSX.utils.json_to_sheet(formattedData);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Data');
        XLSX.writeFile(wb, `${filename}.xlsx`);
    }, []);

    return { exportToExcel };
};
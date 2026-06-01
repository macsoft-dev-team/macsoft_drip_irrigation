import React, { useState, useMemo, useEffect } from "react";
import {
  ChevronUp,
  ChevronDown,
  ChevronsUpDown,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";

// --- 1. REUSABLE DATA TABLE COMPONENT ---
export const DataTable = ({ columns, data, itemsPerPage = 5, onRowClick }) => {
  const [sortConfig, setSortConfig] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [jumpInputValue, setJumpInputValue] = useState(1); // State for the "Go to" box

  // Sorting Logic
  const handleSort = (key) => {
    let direction = "asc";
    if (sortConfig && sortConfig.key === key && sortConfig.direction === "asc") {
      direction = "desc";
    }
    setSortConfig({ key, direction });
  };

  const sortedData = useMemo(() => {
    let sortableItems = [...data];
    if (sortConfig !== null) {
      sortableItems.sort((a, b) => {
        if (a[sortConfig.key] < b[sortConfig.key]) {
          return sortConfig.direction === "asc" ? -1 : 1;
        }
        if (a[sortConfig.key] > b[sortConfig.key]) {
          return sortConfig.direction === "asc" ? 1 : -1;
        }
        return 0;
      });
    }
    return sortableItems;
  }, [data, sortConfig]);

  // Pagination Logic
  const totalPages = Math.max(1, Math.ceil(sortedData.length / itemsPerPage));
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedData = sortedData.slice(startIndex, startIndex + itemsPerPage);

  const handleNextPage = () => setCurrentPage((prev) => Math.min(prev + 1, totalPages));
  const handlePrevPage = () => setCurrentPage((prev) => Math.max(prev - 1, 1));

  // Sync the "Go to" input box when currentPage changes via other buttons
  useEffect(() => {
    setJumpInputValue(currentPage);
  }, [currentPage]);

  // Generate numbered pagination with ellipses (e.g., 1 ... 4 5 6 ... 10)
  const paginationRange = useMemo(() => {
    const delta = 1; // Number of sibling pages to show beside the current page
    const range = [];
    const rangeWithDots = [];
    let l;

    for (let i = 1; i <= totalPages; i++) {
      if (i === 1 || i === totalPages || (i >= currentPage - delta && i <= currentPage + delta)) {
        range.push(i);
      }
    }

    for (let i of range) {
      if (l) {
        if (i - l === 2) {
          rangeWithDots.push(l + 1); // Fill the gap if it's only 1 number
        } else if (i - l !== 1) {
          rangeWithDots.push("..."); // Insert dots for larger gaps
        }
      }
      rangeWithDots.push(i);
      l = i;
    }

    return rangeWithDots;
  }, [currentPage, totalPages]);

  // Handle the "Go to" Input Box Submit/Change
  const handleJumpSubmit = (e) => {
    if (e.key === "Enter" || e.type === "blur") {
      let page = parseInt(jumpInputValue, 10);
      if (isNaN(page)) page = currentPage;

      // Keep it within bounds
      page = Math.max(1, Math.min(page, totalPages));

      setCurrentPage(page);
      setJumpInputValue(page); // Reset input to actual bounded value
    }
  };

  return (
    <div className="flex flex-col w-full bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
      {/* Table Area */}
      <div className="overflow-x-auto">
        <table className="w-full text-left text-sm whitespace-nowrap">
          <thead className="bg-slate-50 text-slate-500 text-[11px] uppercase tracking-wider border-b border-slate-200">
            <tr>
              {columns.map((col, index) => (
                <th
                  key={index}
                  className={`px-6 py-4 font-bold ${col.sortable ? "cursor-pointer hover:bg-slate-100 select-none transition-colors" : ""}`}
                  onClick={() => col.sortable && handleSort(col.accessor)}
                >
                  <div className={`flex items-center gap-1 ${col.align === "right" ? "justify-end" : col.align === "center" ? "justify-center" : ""}`}>
                    {col.header}
                    {col.sortable && (
                      <span className="text-slate-400">
                        {sortConfig?.key === col.accessor ? (
                          sortConfig.direction === "asc" ? (
                            <ChevronUp size={14} className="text-slate-800" />
                          ) : (
                            <ChevronDown size={14} className="text-slate-800" />
                          )
                        ) : (
                          <ChevronsUpDown size={14} />
                        )}
                      </span>
                    )}
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {paginatedData.length > 0 ? (
              paginatedData.map((row, rowIndex) => (
                <tr
                  key={rowIndex}
                  onClick={() => onRowClick?.(row)}
                  className={`hover:bg-slate-50/50 transition-colors group ${onRowClick ? 'cursor-pointer' : ''}`}
                >
                  {columns.map((col, colIndex) => (
                    <td key={colIndex} className="px-6 py-4 text-slate-600">
                      {col.cell ? col.cell(row) : row[col.accessor]}
                    </td>
                  ))}
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={columns.length} className="px-6 py-8 text-center text-slate-500">
                  No data available.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination Footer */}
      {totalPages > 1 && (
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 px-6 py-4 bg-white border-t border-slate-200">

          {/* Left Side: Results Info */}
          <span className="text-sm text-slate-500">
            Showing <span className="font-medium text-slate-900">{startIndex + 1}</span> to{" "}
            <span className="font-medium text-slate-900">{Math.min(startIndex + itemsPerPage, sortedData.length)}</span> of{" "}
            <span className="font-medium text-slate-900">{sortedData.length}</span> results
          </span>

          {/* Right Side: Controls */}
          <div className="flex items-center flex-wrap justify-center gap-2 sm:gap-4">

            {/* Numbered Pagination */}
            <div className="flex items-center gap-1">
              <button
                onClick={handlePrevPage}
                disabled={currentPage === 1}
                className="p-1.5 rounded-md border border-slate-200 text-slate-500 hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors mr-1"
              >
                <ChevronLeft size={16} />
              </button>

              {paginationRange.map((item, index) =>
                item === "..." ? (
                  <span key={index} className="px-2 text-slate-400 font-medium select-none">
                    ...
                  </span>
                ) : (
                  <button
                    key={index}
                    onClick={() => setCurrentPage(item)}
                    className={`w-8 h-8 flex items-center justify-center rounded-md text-sm font-semibold transition-colors ${currentPage === item
                        ? "bg-blue-600 text-white shadow-sm"
                        : "text-slate-600 hover:bg-slate-100"
                      }`}
                  >
                    {item}
                  </button>
                )
              )}

              <button
                onClick={handleNextPage}
                disabled={currentPage === totalPages}
                className="p-1.5 rounded-md border border-slate-200 text-slate-500 hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors ml-1"
              >
                <ChevronRight size={16} />
              </button>
            </div>

            {/* Jump to Page Selection Box */}
            <div className="flex items-center gap-2 pl-4 sm:border-l border-slate-200">
              <span className="text-sm text-slate-500 font-medium whitespace-nowrap">Go to:</span>
              <input
                type="number"
                min={1}
                max={totalPages}
                value={jumpInputValue}
                onChange={(e) => setJumpInputValue(e.target.value)}
                onKeyDown={handleJumpSubmit}
                onBlur={handleJumpSubmit}
                className="w-14 px-2 py-1.5 text-center text-sm border border-slate-200 rounded-md bg-slate-50 text-slate-700 focus:outline-none focus:ring-2 focus:ring-blue-600/20 focus:border-blue-600 focus:bg-white transition-all appearance-none hide-spin-button"
              />
            </div>

          </div>
        </div>
      )}

      {/* Small inline style block to hide the messy up/down arrows in the number input */}
      <style dangerouslySetInnerHTML={{
        __html: `
        .hide-spin-button::-webkit-inner-spin-button,
        .hide-spin-button::-webkit-outer-spin-button { -webkit-appearance: none; margin: 0; }
        .hide-spin-button { -moz-appearance: textfield; }
      `}} />
    </div>
  );
};
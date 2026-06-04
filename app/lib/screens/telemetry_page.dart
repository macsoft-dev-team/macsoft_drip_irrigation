import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle;
import 'package:provider/provider.dart';
import '../models/api_device.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../services/socket_service.dart';

class TelemetryPage extends StatefulWidget {
  final ApiDevice device;
  const TelemetryPage({super.key, required this.device});

  @override
  State<TelemetryPage> createState() => _TelemetryPageState();
}

class _TelemetryPageState extends State<TelemetryPage> {
  static final _dtFmt = DateFormat('yyyy-MM-dd');
  static final _timeFmt = DateFormat('HH:mm:ss');
  static final _dtDisplay = DateFormat('dd MMM yyyy');

  DateTime _from = DateTime.now().subtract(const Duration(hours: 24));
  DateTime _to = DateTime.now();

  List<TelemetryRow> _rows = [];
  bool _loading = false;
  String? _error;
  int _skip = 0;
  final int _take = 50;
  bool _hasMore = true;

  final _liveRows = <TelemetryRow>[];

  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    SocketService.instance.subscribeDevice(widget.device.id);
    SocketService.instance.addListener(_onLive);
    _loadTelemetry(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    SocketService.instance.unsubscribeDevice(widget.device.id);
    SocketService.instance.removeListener(_onLive);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onLive(String deviceId, TelemetryRow row) {
    if (deviceId == widget.device.id && mounted) {
      setState(() => _liveRows.insert(0, row));
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loading && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadTelemetry({bool reset = false}) async {
    final token = context.read<AppState>().token;
    if (token == null) return;
    if (reset) {
      setState(() { _rows = []; _liveRows.clear(); _skip = 0; _hasMore = true; _error = null; _loading = true; });
    }
    try {
      final api = ApiService(token: token);
      final result = await api.getTelemetry(
        deviceId: widget.device.id,
        from: _dtFmt.format(_from),
        to: _dtFmt.format(_to.add(const Duration(days: 1))),
        skip: _skip,
        take: _take,
      );
      if (!mounted) return;
      setState(() {
        _rows = reset ? result : [..._rows, ...result];
        _hasMore = result.length == _take;
        _skip = _rows.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    await _loadTelemetry();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      setState(() { if (isFrom) _from = picked; else _to = picked; });
      _loadTelemetry(reset: true);
    }
  }

  Future<void> _export() async {
    if (_rows.isEmpty && _liveRows.isEmpty) return;
    final all = [..._liveRows, ..._rows];
    final excel = Excel.createExcel();
    final sheet = excel['Telemetry'];
    sheet.appendRow([
      TextCellValue('Time'), TextCellValue('IV1'), TextCellValue('IV2'), TextCellValue('IV3'),
      TextCellValue('IC1'), TextCellValue('IC2'), TextCellValue('IC3'),
      TextCellValue('FLC'), TextCellValue('STS'), TextCellValue('AMM'), TextCellValue('PHM'),
      TextCellValue('OHR'), TextCellValue('SHR'), TextCellValue('CHR'), TextCellValue('RSI'),
    ]);
    for (final r in all) {
      sheet.appendRow([
        TextCellValue(r.time != null ? _timeFmt.format(r.time!) : ''),
        if (r.iv1 != null) DoubleCellValue(r.iv1!) else TextCellValue(''),
        if (r.iv2 != null) DoubleCellValue(r.iv2!) else TextCellValue(''),
        if (r.iv3 != null) DoubleCellValue(r.iv3!) else TextCellValue(''),
        if (r.ic1 != null) DoubleCellValue(r.ic1!) else TextCellValue(''),
        if (r.ic2 != null) DoubleCellValue(r.ic2!) else TextCellValue(''),
        if (r.ic3 != null) DoubleCellValue(r.ic3!) else TextCellValue(''),
        TextCellValue(r.flc?.toString() ?? ''),
        TextCellValue(r.sts?.toString() ?? ''),
        TextCellValue(r.amm?.toString() ?? ''),
        TextCellValue(r.phm?.toString() ?? ''),
        TextCellValue(r.ohr?.toString() ?? ''),
        TextCellValue(r.shr?.toString() ?? ''),
        TextCellValue(r.chr?.toString() ?? ''),
        if (r.rsi != null) DoubleCellValue(r.rsi!) else TextCellValue(''),
      ]);
    }
    final bytes = excel.save();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/telemetry_${widget.device.imeinumber}.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    await Share.shareXFiles([XFile(file.path)], subject: 'Telemetry Export');
  }

  @override
  Widget build(BuildContext context) {
    final allRows = [..._liveRows, ..._rows];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1F36)), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.device.name ?? widget.device.imeinumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
          Text('Telemetry', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded, color: Color(0xFF2D7A3A)), tooltip: 'Export Excel', onPressed: _export),
        ],
      ),
      body: Column(children: [
        // ── Date range bar ──────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(children: [
            _DateBtn(label: 'From', date: _dtDisplay.format(_from), onTap: () => _pickDate(true)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('→', style: TextStyle(color: Color(0xFF9CA3AF)))),
            _DateBtn(label: 'To', date: _dtDisplay.format(_to), onTap: () => _pickDate(false)),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2D7A3A)),
              onPressed: () => _loadTelemetry(reset: true),
            ),
          ]),
        ),
        if (_liveRows.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFFECFDF5),
            child: Row(children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('${_liveRows.length} live reading${_liveRows.length > 1 ? 's' : ''} received', style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
            ]),
          ),
        // ── Table ────────────────────────────────────────────
        Expanded(
          child: _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  TextButton(onPressed: () => _loadTelemetry(reset: true), child: const Text('Retry')),
                ]))
              : allRows.isEmpty && !_loading
                  ? const Center(child: Text('No telemetry found for this range', style: TextStyle(color: Color(0xFF9CA3AF))))
                  : SingleChildScrollView(
                      controller: _scrollCtrl,
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          columnSpacing: 16,
                          headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                          dataTextStyle: const TextStyle(fontSize: 11, color: Color(0xFF374151), fontFamily: 'monospace'),
                          columns: const [
                            DataColumn(label: Text('Time')),
                            DataColumn(label: Text('IV1'), numeric: true),
                            DataColumn(label: Text('IV2'), numeric: true),
                            DataColumn(label: Text('IV3'), numeric: true),
                            DataColumn(label: Text('IC1'), numeric: true),
                            DataColumn(label: Text('IC2'), numeric: true),
                            DataColumn(label: Text('IC3'), numeric: true),
                            DataColumn(label: Text('FLC')),
                            DataColumn(label: Text('STS')),
                            DataColumn(label: Text('AMM')),
                            DataColumn(label: Text('PHM')),
                            DataColumn(label: Text('OHR')),
                            DataColumn(label: Text('SHR')),
                            DataColumn(label: Text('CHR')),
                            DataColumn(label: Text('RSI'), numeric: true),
                          ],
                          rows: [
                            ...allRows.map((r) => _buildRow(r, _liveRows.contains(r))),
                            if (_loading)
                              const DataRow(cells: [
                                DataCell(SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                                DataCell(Text('')), DataCell(Text('')), DataCell(Text('')),
                                DataCell(Text('')), DataCell(Text('')), DataCell(Text('')),
                                DataCell(Text('')), DataCell(Text('')), DataCell(Text('')),
                                DataCell(Text('')), DataCell(Text('')), DataCell(Text('')),
                                DataCell(Text('')), DataCell(Text('')),
                              ]),
                          ],
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }

  DataRow _buildRow(TelemetryRow r, bool isLive) {
    final bg = isLive ? const Color(0xFFF0FDF4) : null;
    String fmtD(double? v) => v != null ? v.toStringAsFixed(1) : '—';
    String fmtA(dynamic v) => v?.toString() ?? '—';
    return DataRow(
      color: bg != null ? WidgetStateProperty.all(bg) : null,
      cells: [
        DataCell(Text(r.time != null ? _timeFmt.format(r.time!) : '—')),
        DataCell(Text(fmtD(r.iv1))),
        DataCell(Text(fmtD(r.iv2))),
        DataCell(Text(fmtD(r.iv3))),
        DataCell(Text(fmtD(r.ic1))),
        DataCell(Text(fmtD(r.ic2))),
        DataCell(Text(fmtD(r.ic3))),
        DataCell(Text(fmtA(r.flc))),
        DataCell(Text(fmtA(r.sts))),
        DataCell(Text(fmtA(r.amm))),
        DataCell(Text(fmtA(r.phm))),
        DataCell(Text(fmtA(r.ohr))),
        DataCell(Text(fmtA(r.shr))),
        DataCell(Text(fmtA(r.chr))),
        DataCell(Text(fmtD(r.rsi))),
      ],
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;
  const _DateBtn({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
              Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
            ])),
          ]),
        ),
      ),
    );
  }
}

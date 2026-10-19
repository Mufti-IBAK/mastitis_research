import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/export_print_service.dart';
import '../constants/enums.dart';
import '../models/study_models.dart';
import 'home_screen.dart';
import 'cow_visit_screen.dart';
import 'quarter_grid_screen.dart';

class DatasetSpreadsheetScreen extends StatefulWidget {
  const DatasetSpreadsheetScreen({super.key});

  @override
  State<DatasetSpreadsheetScreen> createState() => _DatasetSpreadsheetScreenState();
}

class _DatasetSpreadsheetScreenState extends State<DatasetSpreadsheetScreen> {
  final _storage = LocalStorageService.instance;
  final _exportService = ExportPrintService.instance;

  List<Map<String, dynamic>> _allRows = [];
  List<Map<String, dynamic>> _filteredRows = [];

  bool _isLoading = true;
  bool _isExporting = false;
  String _searchQuery = '';
  String _selectedState = 'All';
  String _selectedFilter = 'All'; // All, CMT+, Clinical, Lab, Tx
  bool _isTableViewOnMobile = false; // Mobile defaults to Card View, toggleable to Table
  int _selectedRowIndex = -1;

  final ScrollController _tableHScroll = ScrollController();
  final ScrollController _tableVScroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tableHScroll.dispose();
    _tableVScroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final rows = await _storage.fetchCompleteSpreadsheetRows(limit: 2000);
    setState(() {
      _allRows = rows;
      _applyFilters();
      _isLoading = false;
      if (_selectedRowIndex >= _filteredRows.length) {
        _selectedRowIndex = -1;
      }
    });
  }

  void _applyFilters() {
    var list = List<Map<String, dynamic>>.from(_allRows);

    // State filter
    if (_selectedState != 'All') {
      list = list.where((r) => (r['state'] ?? '').toString().toLowerCase() == _selectedState.toLowerCase()).toList();
    }

    // Category Quick Filters
    if (_selectedFilter == 'CMT+') {
      list = list.where((r) => (r['cmt_positive_derived'] ?? '').toString() == 'Yes').toList();
    } else if (_selectedFilter == 'Clinical') {
      list = list.where((r) => (r['quarter_clinical_mastitis'] ?? '').toString() == 'Yes').toList();
    } else if (_selectedFilter == 'Lab') {
      list = list.where((r) {
        final sampleId = (r['lab_sample_id'] ?? '').toString();
        return sampleId.isNotEmpty;
      }).toList();
    } else if (_selectedFilter == 'Tx') {
      list = list.where((r) => (r['tx_current_treatment'] ?? '').toString() == 'Yes').toList();
    }

    // Text Search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((r) {
        final cowId = (r['cow_id'] ?? '').toString().toLowerCase();
        final farmId = (r['farm_id'] ?? '').toString().toLowerCase();
        final obsId = (r['observer_id'] ?? '').toString().toLowerCase();
        final lga = (r['lga'] ?? '').toString().toLowerCase();
        final recordKey = (r['record_key_derived'] ?? '').toString().toLowerCase();
        return cowId.contains(q) || farmId.contains(q) || obsId.contains(q) || lga.contains(q) || recordKey.contains(q);
      }).toList();
    }

    _filteredRows = list;
  }

  Future<void> _exportToExcel() async {
    if (_filteredRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data rows to export!')),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final bytes = await _exportService.generateExcelBytesFromRawRows(rows: _filteredRows);
      await _exportService.shareOrDownloadExcelBytes(
        bytes: bytes,
        fileName: 'UDDER_HEALTH_STUDY_DATA_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Color _getCmtChipColor(String score) {
    switch (score) {
      case 'N':
        return const Color(0xFF10B981);
      case 'T':
        return const Color(0xFFF59E0B);
      case '1':
        return const Color(0xFFF97316);
      case '2':
        return const Color(0xFFE11D48);
      case '3':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _openEditorForRow(Map<String, dynamic> row, {bool editQuarterOnly = false}) async {
    final farmId = row['farm_id']?.toString() ?? '';
    final cowId = row['cow_id']?.toString() ?? '';
    final qtr = row['quarter']?.toString() ?? 'LF';
    final visitId = row['visit_id']?.toString() ?? '';

    // Search for visit in local storage
    final visits = await _storage.getLocalVisits();
    VisitRecord? matchedVisit;
    CowRecord? matchedCow;

    for (final v in visits) {
      if (visitId.isNotEmpty && v.visitId == visitId) {
        matchedVisit = v;
        break;
      }
      if (v.farmId == farmId) {
        matchedVisit = v;
        break;
      }
    }

    if (matchedVisit != null) {
      for (final c in matchedVisit.cows) {
        if (c.cowId == cowId) {
          matchedCow = c;
          break;
        }
      }
    }

    if (matchedVisit == null || matchedCow == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot find editable local record for Cow "$cowId". Please sync cloud feed first.'),
          backgroundColor: Colors.amber.shade900,
        ),
      );
      return;
    }

    if (editQuarterOnly) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuarterGridScreen(
            visit: matchedVisit!,
            cow: matchedCow!,
            initialQuarter: qtr,
          ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CowVisitScreen(
            visit: matchedVisit!,
            cow: matchedCow!,
            isNew: false,
          ),
        ),
      );
    }

    // Refresh table upon return
    await _loadData();
  }

  void _showRowInspector(Map<String, dynamic> row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Cow: ${row['cow_id'] ?? '—'}  •  Qtr: ${row['quarter'] ?? '—'}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getCmtChipColor(row['cmt_score']?.toString() ?? 'N').withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('CMT: ${row['cmt_score'] ?? "N"}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _getCmtChipColor(row['cmt_score']?.toString() ?? 'N'))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Record Key: ${row['record_key_derived'] ?? '—'}  •  Farm: ${row['farm_id'] ?? '—'}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // Action Edit Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                          side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                          minimumSize: const Size(0, 38),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Cow Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openEditorForRow(row, editQuarterOnly: false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 38),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.healing_outlined, size: 16),
                        label: Text('Edit Udder (${row['quarter'] ?? "Qtr"})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openEditorForRow(row, editQuarterOnly: true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 99 Column List View
                Expanded(
                  child: ListView.separated(
                    itemCount: ExportPrintService.excelHeaders.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, idx) {
                      final header = ExportPrintService.excelHeaders[idx];
                      final key = ExportPrintService.dbKeys[idx];
                      final val = row[key];
                      final valStr = val == null ? '—' : val.toString();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text('${idx + 1}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(header,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            ),
                            Expanded(
                              flex: 5,
                              child: SelectableText(
                                valStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: (key == 'cmt_score' || key == 'quarter_clinical_mastitis')
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: key == 'cmt_score' ? _getCmtChipColor(valStr) : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close Inspector', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  double _getColumnWidth(int colIndex) {
    final key = ExportPrintService.dbKeys[colIndex];
    switch (key) {
      case 'record_key_derived':
        return 175.0;
      case 'state':
        return 95.0;
      case 'lga':
        return 110.0;
      case 'farm_id':
      case 'visit_id':
      case 'observer_id':
        return 100.0;
      case 'visit_date':
      case 'scheduled_visit_date':
      case 'calving_date':
      case 'cow_birth_date':
      case 'tx_start_date':
      case 'tx_stop_date':
      case 'tx_milk_withdrawal_end_date':
        return 105.0;
      case 'cow_id':
      case 'local_tag_id':
      case 'lactation_id':
        return 95.0;
      case 'breed_genetic_group':
      case 'farm_production_system':
      case 'farm_housing_type':
        return 150.0;
      case 'parity':
      case 'dim_derived':
      case 'cow_age_years':
      case 'cow_milking_frequency':
      case 'cow_bcs_value':
      case 'cow_locomotion_score':
      case 'cow_udder_hygiene_score':
      case 'cow_rectal_temperature_c':
        return 85.0;
      case 'quarter':
        return 65.0;
      case 'quarter_functional_status':
        return 115.0;
      case 'quarter_clinical_mastitis':
      case 'quarter_clinical_grade':
        return 105.0;
      case 'cmt_score':
        return 80.0;
      case 'cmt_positive_derived':
        return 95.0;
      case 'lab_sample_id':
      case 'lab_culture_result_category':
      case 'lab_organism_primary':
      case 'tx_product_trade_name':
      case 'tx_active_ingredient':
        return 140.0;
      default:
        return 120.0;
    }
  }

  Widget _buildExcelFormulaBar() {
    final hasSelection = _selectedRowIndex >= 0 && _selectedRowIndex < _filteredRows.length;
    final r = hasSelection ? _filteredRows[_selectedRowIndex] : null;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
      ),
      child: Row(
        children: [
          // fx icon box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('fx',
                style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF475569))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              hasSelection ? 'Row ${_selectedRowIndex + 1}' : 'Ready',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasSelection
                  ? 'Cow: ${r!['cow_id'] ?? '—'}  •  Qtr: ${r['quarter'] ?? '—'}  •  Farm: ${r['farm_id'] ?? '—'}  •  Date: ${r['visit_date'] ?? '—'}  •  CMT: ${r['cmt_score'] ?? '—'}'
                  : 'Click any row or cell in the spreadsheet to inspect or edit details',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: hasSelection ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (hasSelection) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 26,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.edit_outlined, size: 12),
                label: const Text('Edit Row', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                onPressed: () => _openEditorForRow(r!),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 26,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => _showRowInspector(r!),
                child: const Text('Full 99 Cols', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExcelHeaderRow() {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFF107C41), // Authentic Microsoft Excel Green
        border: Border(
          bottom: BorderSide(color: Color(0xFF0E6B37), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // Row index column header
          Container(
            width: 46,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF0E6B37),
              border: Border(
                right: BorderSide(color: Color(0xFF15803D), width: 1),
              ),
            ),
            child: const Text('#', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          ...List.generate(ExportPrintService.excelHeaders.length, (i) {
            final w = _getColumnWidth(i);
            final title = ExportPrintService.excelHeaders[i];
            return Container(
              width: w,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0x33FFFFFF), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExcelDataRow(int idx) {
    final r = _filteredRows[idx];
    final isEven = idx % 2 == 0;
    final isSelected = _selectedRowIndex == idx;

    final rowBgColor = isSelected
        ? const Color(0xFFE8F5E9) // Excel selection green tint
        : (isEven ? Colors.white : const Color(0xFFFBFDFA));

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRowIndex = idx;
        });
      },
      onDoubleTap: () => _showRowInspector(r),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: rowBgColor,
          border: isSelected ? Border.all(color: const Color(0xFF107C41), width: 1.2) : null,
        ),
        child: Row(
          children: [
            // Row number column
            Container(
              width: 46,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFC8E6C9) : const Color(0xFFF1F5F9),
                border: const Border(
                  right: BorderSide(color: Color(0xFFD1D5DB), width: 1),
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Text(
                '${idx + 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF64748B),
                ),
              ),
            ),
            // 99 Data Columns
            ...List.generate(ExportPrintService.dbKeys.length, (i) {
              final w = _getColumnWidth(i);
              final key = ExportPrintService.dbKeys[i];
              final val = r[key];
              final valStr = val == null ? '—' : val.toString();

              Widget cellContent;
              if (key == 'cmt_score' && valStr != '—') {
                final color = _getCmtChipColor(valStr);
                cellContent = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    border: Border.all(color: color.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(valStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                );
              } else if (key == 'quarter_clinical_mastitis' && valStr == 'Yes') {
                cellContent = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Clinical',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                );
              } else if (key == 'cmt_positive_derived' && valStr == 'Yes') {
                cellContent = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Positive',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                );
              } else if (key == 'cow_id') {
                cellContent = Text(
                  valStr,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                );
              } else if (key == 'quarter') {
                cellContent = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(valStr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                );
              } else {
                cellContent = Text(
                  valStr,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                );
              }

              return Container(
                width: w,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: cellContent,
              );
            }),
          ],
        ),
      ),
    );
  }

  /// WIDESCREEN & MOBILE EXCEL SPREADSHEET TABLE
  Widget _buildSpreadsheetTable() {
    final double totalWidth = 46.0 +
        List.generate(
          ExportPrintService.dbKeys.length,
          (i) => _getColumnWidth(i),
        ).fold<double>(0.0, (sum, w) => sum + w);

    return Column(
      children: [
        // 1. EXCEL FORMULA / ACTIVE ROW BAR
        _buildExcelFormulaBar(),

        // 2. UNIFIED EXCEL SPREADSHEET 2D GRID
        Expanded(
          child: Container(
            color: Colors.white,
            child: Scrollbar(
              controller: _tableHScroll,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _tableHScroll,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: totalWidth,
                  child: Column(
                    children: [
                      // Excel Column Headers (Frozen at top)
                      _buildExcelHeaderRow(),

                      // Excel Data Rows
                      Expanded(
                        child: Scrollbar(
                          controller: _tableVScroll,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: ListView.builder(
                            controller: _tableVScroll,
                            itemCount: _filteredRows.length,
                            itemExtent: 38.0,
                            physics: const ClampingScrollPhysics(),
                            itemBuilder: (context, idx) {
                              return _buildExcelDataRow(idx);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// MOBILE CARDS VIEW: Alternate view for mobile phone screens
  Widget _buildMobileCardsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredRows.length,
      itemBuilder: (context, idx) {
        final r = _filteredRows[idx];
        final cmtScore = (r['cmt_score'] ?? 'N').toString();
        final cmtColor = _getCmtChipColor(cmtScore);
        final isClinical = (r['quarter_clinical_mastitis'] ?? '').toString() == 'Yes';
        final isPositive = (r['cmt_positive_derived'] ?? '').toString() == 'Yes';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showRowInspector(r),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              'Cow: ${r['cow_id'] ?? '—'}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F766E)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              'Qtr: ${r['quarter'] ?? '—'}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cmtColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: cmtColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              'CMT: $cmtScore',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: cmtColor),
                            ),
                          ),
                          if (isClinical) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Clinical',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Color(0xFFDC2626))),
                            ),
                          ],
                          if (isPositive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Positive',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Color(0xFFB45309))),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Farm: ${r['farm_id'] ?? '—'}  •  Date: ${r['visit_date'] ?? '—'}  •  ${r['state'] ?? '—'}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Obs: ${r['observer_id'] ?? '—'}  •  Parity: ${r['parity'] ?? '—'}  •  BCS: ${r['cow_bcs_value'] ?? '—'}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _openEditorForRow(r),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 12, color: Color(0xFF0F766E)),
                                  SizedBox(width: 2),
                                  Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Row(
                            children: [
                              Text('99 cols', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF64748B)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search Cow ID, Farm ID, LGA, Observer...',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedState,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          items: ['All', ...Enums.states].map((s) => DropdownMenuItem(value: s, child: Text('State: $s'))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedState = val;
                _applyFilters();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 6,
      children: [
        _filterChip('All', 'All'),
        _filterChip('CMT (+)', 'CMT+'),
        _filterChip('Clinical', 'Clinical'),
        _filterChip('Lab Sample', 'Lab'),
        _filterChip('Treatment', 'Tx'),
      ],
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _selectedState != 'All' || _selectedFilter != 'All';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.filter_list_off_rounded : Icons.table_chart_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters ? 'No records match your filters' : 'No dataset records found yet',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            if (hasFilters)
              TextButton(
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedState = 'All';
                    _selectedFilter = 'All';
                    _applyFilters();
                  });
                },
                child: const Text('Reset All Filters', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600)),
              )
            else
              TextButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh from Cloud Database', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _viewToggleItem({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String code) {
    final isSelected = _selectedFilter == code;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        setState(() {
          _selectedFilter = code;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final totalRows = _filteredRows.length;
    final totalCows = _filteredRows.map((r) => r['cow_id']).where((id) => id != null).toSet().length;
    final cmtPositives = _filteredRows.where((r) => r['cmt_positive_derived'] == 'Yes').length;
    final clinicalCases = _filteredRows.where((r) => r['quarter_clinical_mastitis'] == 'Yes').length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leadingWidth: isDesktop ? 160 : 56,
          leading: isDesktop
              ? Padding(
                  padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: _handleBack,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                  tooltip: 'Back to Dashboard',
                  onPressed: _handleBack,
                ),
          title: isDesktop
              ? const Row(
                  children: [
                    Text('99-Column Study Dataset',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    SizedBox(width: 8),
                    Text('•  Longitudinal Udder Health Surveillance',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                )
              : const Text('Study Dataset',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          actions: [
            if (isDesktop) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F766E),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _loadData,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Color(0xFF0F766E), strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isExporting ? null : _exportToExcel,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.table_view_outlined, size: 16),
                  label: const Text('Export Excel (.xlsx)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ] else ...[
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF0F172A)),
                onPressed: _isLoading ? null : _loadData,
              ),
              IconButton(
                tooltip: 'Export Excel (.xlsx)',
                icon: const Icon(Icons.file_download_outlined, size: 22, color: Color(0xFF0F766E)),
                onPressed: _isExporting ? null : _exportToExcel,
              ),
            ],
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFE2E8F0), height: 1),
          ),
        ),
        body: Column(
          children: [
            // Sub-Header Navigation Bar with explicit Back link
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  if (!isDesktop) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _handleBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: Color(0xFF0F766E)),
                            SizedBox(width: 4),
                            Text('Dashboard',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '$totalRows records found',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const Spacer(),

                  // Mobile View Toggle Switch: Cards vs Table
                  if (!isDesktop)
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _viewToggleItem(
                            label: 'Cards',
                            icon: Icons.view_agenda_outlined,
                            isSelected: !_isTableViewOnMobile,
                            onTap: () => setState(() => _isTableViewOnMobile = false),
                          ),
                          _viewToggleItem(
                            label: 'Table',
                            icon: Icons.table_chart_outlined,
                            isSelected: _isTableViewOnMobile,
                            onTap: () => setState(() => _isTableViewOnMobile = true),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Stats Ribbon & Filter Controls
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Ribbon
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statPill('Dataset Rows', '$totalRows', const Color(0xFF0F766E)),
                        const SizedBox(width: 6),
                        _statPill('Cows Monitored', '$totalCows', const Color(0xFF0284C7)),
                        const SizedBox(width: 6),
                        _statPill('CMT Positives', '$cmtPositives', const Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        _statPill('Clinical Cases', '$clinicalCases', const Color(0xFFDC2626)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Responsive Search and Filters
                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(flex: 3, child: _buildSearchField()),
                        const SizedBox(width: 10),
                        _buildStateDropdown(),
                        const SizedBox(width: 10),
                        _buildFilterChips(),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchField(),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStateDropdown(),
                              const SizedBox(width: 8),
                              _buildFilterChips(),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Main Content View (Desktop: Table | Mobile: Cards or Table)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
                  : _filteredRows.isEmpty
                      ? _buildEmptyState()
                      : (isDesktop || _isTableViewOnMobile)
                          ? _buildSpreadsheetTable()
                          : _buildMobileCardsList(),
            ),
          ],
        ),
        bottomNavigationBar: isDesktop
            ? null
            : BottomAppBar(
                elevation: 4,
                color: Colors.white,
                surfaceTintColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 64,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Showing $totalRows of ${_allRows.length} rows',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          const SizedBox(height: 2),
                          const Text('99-Column Excel Ready', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isExporting ? null : _exportToExcel,
                        icon: _isExporting
                            ? const SizedBox(
                                width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('Export Excel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

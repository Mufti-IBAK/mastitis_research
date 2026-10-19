import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/export_print_service.dart';
import '../constants/enums.dart';
import 'home_screen.dart';

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
  bool _isTableViewOnMobile = false; // Mobile defaults to Card View

  final ScrollController _headerHScroll = ScrollController();
  final ScrollController _dataHScroll = ScrollController();
  final ScrollController _dataVScroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Synchronize horizontal scrolling between header and body on desktop/table view
    _dataHScroll.addListener(() {
      if (_headerHScroll.hasClients && _headerHScroll.offset != _dataHScroll.offset) {
        _headerHScroll.jumpTo(_dataHScroll.offset);
      }
    });
    _headerHScroll.addListener(() {
      if (_dataHScroll.hasClients && _dataHScroll.offset != _headerHScroll.offset) {
        _dataHScroll.jumpTo(_headerHScroll.offset);
      }
    });

    _loadData();
  }

  @override
  void dispose() {
    _headerHScroll.dispose();
    _dataHScroll.dispose();
    _dataVScroll.dispose();
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
        fileName: 'UDDER_HEALTH_DATA_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        subject: 'Longitudinal Udder Health Study Dataset (${_filteredRows.length} rows)',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F766E),
            content: Text('Exported ${_filteredRows.length} rows to 99-column Excel workbook!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Export error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Color _getCmtChipColor(String? score) {
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

  void _showRowInspector(Map<String, dynamic> row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
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
                          Text(
                            'Cow: ${row['cow_id'] ?? '—'}  •  Quarter: ${row['quarter'] ?? '—'}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
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
                const Divider(height: 20),
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
                              width: 30,
                              child: Text('${idx + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(header, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            ),
                            Expanded(
                              flex: 5,
                              child: SelectableText(
                                valStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: (key == 'cmt_score' || key == 'quarter_clinical_mastitis') ? FontWeight.w700 : FontWeight.w400,
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
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final totalRows = _filteredRows.length;
    final totalCows = _filteredRows.map((r) => r['cow_id']).where((id) => id != null).toSet().length;
    final cmtPositives = _filteredRows.where((r) => r['cmt_positive_derived'] == 'Yes').length;
    final clinicalCases = _filteredRows.where((r) => r['quarter_clinical_mastitis'] == 'Yes').length;

    // Fixed lead columns that stay pinned on the left
    final List<Map<String, String>> pinnedCols = [
      {'key': 'record_key_derived', 'label': 'Col 1: Record Key', 'width': '140'},
      {'key': 'farm_id', 'label': 'Col 4: Farm ID', 'width': '105'},
      {'key': 'cow_id', 'label': 'Col 23: Cow ID', 'width': '95'},
      {'key': 'quarter', 'label': 'Col 51: Qtr', 'width': '70'},
    ];

    // Scrollable columns (the other 95 columns)
    final List<int> scrollableIndices = [];
    for (int i = 0; i < ExportPrintService.excelHeaders.length; i++) {
      final k = ExportPrintService.dbKeys[i];
      if (k != 'record_key_derived' && k != 'farm_id' && k != 'cow_id' && k != 'quarter') {
        scrollableIndices.add(i);
      }
    }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          tooltip: 'Back to Dashboard',
          onPressed: _handleBack,
        ),
        title: isDesktop
            ? const Row(
                children: [
                  Text('99-Column Study Dataset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  SizedBox(width: 8),
                  Text('•  Longitudinal Udder Health Surveillance', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              )
            : const Text('Study Dataset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        actions: [
          IconButton(
            tooltip: 'Query Latest Cloud Data',
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _isLoading ? null : _loadData,
          ),
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: SizedBox(
                height: 38,
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
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Export Excel (.xlsx)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Export Excel (.xlsx)',
              icon: const Icon(Icons.file_download_outlined, size: 22, color: Color(0xFF0F766E)),
              onPressed: _isExporting ? null : _exportToExcel,
            ),
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
                        Text('Dashboard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
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
                Text(
                  '$totalRows records',
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
                        ? _buildSpreadsheetTable(pinnedCols, scrollableIndices)
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
                        Text('Showing $totalRows of ${_allRows.length} rows', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
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
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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

  /// MOBILE CARDS VIEW: Optimized for mobile phone screens
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
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
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Cow: ${r['cow_id'] ?? '—'}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F766E)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Qtr: ${r['quarter'] ?? '—'}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cmtColor.withValues(alpha: 0.12),
                              border: Border.all(color: cmtColor.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(6),
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
                              child: const Text('Clinical', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Color(0xFFDC2626))),
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
                              child: const Text('Positive', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Color(0xFFB45309))),
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
                      const Row(
                        children: [
                          Text('99 cols', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0F766E))),
                          Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF0F766E)),
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

  /// WIDESCREEN SPREADSHEET TABLE: Optimized for Laptop / Desktop and Table mode
  Widget _buildSpreadsheetTable(List<Map<String, String>> pinnedCols, List<int> scrollableIndices) {
    return Row(
      children: [
        // 1. PINNED LEFT COLUMNS (Record_Key, Farm, Cow, Quarter)
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
          ),
          child: Column(
            children: [
              // Pinned Header
              Container(
                height: 40,
                color: const Color(0xFF0F766E),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: const Text('#', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    ...pinnedCols.map((col) {
                      final w = double.parse(col['width']!);
                      return Container(
                        width: w,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        child: Text(col['label']!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      );
                    }),
                  ],
                ),
              ),

              // Pinned Body Rows
              Expanded(
                child: ListView.builder(
                  controller: _dataVScroll,
                  itemCount: _filteredRows.length,
                  itemExtent: 36,
                  itemBuilder: (context, idx) {
                    final r = _filteredRows[idx];
                    final isEven = idx % 2 == 0;
                    return InkWell(
                      onTap: () => _showRowInspector(r),
                      child: Container(
                        color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text('${idx + 1}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            ),
                            ...pinnedCols.map((col) {
                              final w = double.parse(col['width']!);
                              final key = col['key']!;
                              final val = r[key]?.toString() ?? '—';
                              return Container(
                                width: w,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  val,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: key == 'cow_id' ? FontWeight.w700 : FontWeight.w500,
                                    color: key == 'cow_id' ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // 2. HORIZONTALLY SCROLLABLE REMAINING 95 COLUMNS
        Expanded(
          child: Column(
            children: [
              // Scrollable Header Row
              Container(
                height: 40,
                color: const Color(0xFF115E59),
                child: SingleChildScrollView(
                  controller: _headerHScroll,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: scrollableIndices.map((i) {
                      final header = ExportPrintService.excelHeaders[i];
                      return Container(
                        width: 140,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        decoration: const BoxDecoration(
                          border: Border(right: BorderSide(color: Color(0x33FFFFFF))),
                        ),
                        child: Text(
                          'Col ${i + 1}: $header',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Scrollable Body Rows
              Expanded(
                child: SingleChildScrollView(
                  controller: _dataHScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: scrollableIndices.length * 140.0,
                    child: ListView.builder(
                      itemCount: _filteredRows.length,
                      itemExtent: 36,
                      itemBuilder: (context, idx) {
                        final r = _filteredRows[idx];
                        final isEven = idx % 2 == 0;
                        return InkWell(
                          onTap: () => _showRowInspector(r),
                          child: Container(
                            color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                            child: Row(
                              children: scrollableIndices.map((i) {
                                final key = ExportPrintService.dbKeys[i];
                                final val = r[key];
                                final valStr = val == null ? '—' : val.toString();

                                Widget cellContent;
                                if (key == 'cmt_score' && valStr != '—') {
                                  final color = _getCmtChipColor(valStr);
                                  cellContent = Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      border: Border.all(color: color.withValues(alpha: 0.4)),
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
                                    child: const Text('Clinical', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                                  );
                                } else if (key == 'cmt_positive_derived' && valStr == 'Yes') {
                                  cellContent = Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Positive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                                  );
                                } else {
                                  cellContent = Text(
                                    valStr,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                  );
                                }

                                return Container(
                                  width: 140,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  decoration: const BoxDecoration(
                                    border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
                                  ),
                                  child: cellContent,
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
}

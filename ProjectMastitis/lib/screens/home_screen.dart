import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/study_models.dart';
import '../services/local_storage_service.dart';
import '../services/ota_update_service.dart';
import '../services/export_print_service.dart';
import '../widgets/udder_logo_widget.dart';
import 'farm_visit_screen.dart';
import 'cow_list_screen.dart';
import 'all_visits_screen.dart';
import 'dataset_spreadsheet_screen.dart';
import 'observer_profile_screen.dart';
import '../constants/enums.dart';
import '../widgets/responsive_wrapper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = LocalStorageService.instance;
  List<VisitRecord> _visits = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _observerId = 'OBS-01';
  String _observerName = 'Dr. Muhammad Jimoh';
  String? _observerImagePath;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    // Check for OTA updates silently in the background
    final release = await OtaUpdateService().checkForUpdate();
    if (release != null && mounted) {
      OtaUpdateService.promptUpdateDialog(context, release);
    }
  }

  Future<void> _manualCheckForUpdates() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking cloud for app updates...')),
    );
    final release = await OtaUpdateService().checkForUpdate();
    if (!mounted) return;
    if (release != null) {
      OtaUpdateService.promptUpdateDialog(context, release);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF006D5B),
          content: Text('Your app is up to date! You are running the latest version.'),
        ),
      );
    }
  }

  Future<void> _loadData() async {
    final obs = await _storage.getObserverId();
    final name = await _storage.getObserverName();
    final img = await _storage.getObserverImagePath();
    final list = await _storage.getLocalVisits();
    if (mounted) {
      setState(() {
        _observerId = obs;
        _observerName = name;
        _observerImagePath = img;
        _visits = list;
        _isLoading = false;
      });
    }

    // Background pull down of latest cloud visits from Supabase
    // Guarantees all devices see the identical data immediately
    _storage.fetchAndMergeCloudVisits().then((mergedCount) async {
      if (mergedCount > 0 && mounted) {
        final updatedList = await _storage.getLocalVisits();
        setState(() {
          _visits = updatedList;
        });
      }
    });
  }

  Future<void> _syncAllPending() async {
    setState(() => _isSyncing = true);
    // 1. Push any unsynced local visits
    final res = await _storage.syncAllPendingVisits();
    // 2. Pull all cloud visits to ensure complete two-way sync
    final pulledCount = await _storage.fetchAndMergeCloudVisits();

    final updatedList = await _storage.getLocalVisits();
    if (mounted) {
      setState(() {
        _visits = updatedList;
        _isSyncing = false;
      });
    }

    if (!mounted) return;
    final total = res['total'] as int;
    final synced = res['synced'] as int;
    final failed = res['failed'] as int;

    String msg;
    if (failed > 0) {
      msg = 'Synced $synced. Failed $failed: ${res['lastError']}';
    } else if (synced > 0 || pulledCount > 0) {
      msg = 'Synced: $synced uploaded to cloud, $pulledCount downloaded to device.';
    } else {
      msg = 'Database is in sync! All research records are up to date.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: failed > 0 ? Colors.red.shade800 : const Color(0xFF006D5B),
        content: Text(msg),
      ),
    );
  }

  void _showObserverSettingsDialog() {
    final controller = TextEditingController(text: _observerId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.badge_outlined, color: Color(0xFF006D5B)),
            ),
            const SizedBox(width: 12),
            const Text('Observer Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Observer ID will be tagged on all visit sheets, cow records, and CMT scores.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Observer Code / Name',
                hintText: 'e.g. OBS-01 or JIMOH-M',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.system_update_rounded, color: Color(0xFF006D5B)),
              ),
              title: const Text('Check for OTA Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Verifies latest release on cloud', style: TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () async {
                Navigator.pop(ctx);
                _manualCheckForUpdates();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newId = controller.text.trim();
              if (newId.isNotEmpty) {
                await _storage.setObserverId(newId);
                setState(() => _observerId = newId);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Observer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVisit(VisitRecord visit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Farm Visit?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete the entire visit for Farm "${visit.farmId}" (${visit.cows.length} cows)?\n\nThis cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Visit'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.deleteVisit(visit.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visit ${visit.visitId} deleted.')),
        );
      }
    }
  }

  void _showVisitExportOptions(VisitRecord visit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Farm ${visit.farmId} - Export & Print', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Visit Date: ${visit.visitDate} | ${visit.cows.length} Cows', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.print_rounded, color: Color(0xFF006D5B)),
              title: const Text('Print / Preview Visit PDF'),
              subtitle: const Text('Complete herd summary with 4-quarter CMT scores'),
              onTap: () async {
                Navigator.pop(ctx);
                await ExportPrintService.instance.printOrSharePdf(visit: visit, isDirectPrint: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
              title: const Text('Share Visit PDF'),
              subtitle: const Text('Send clinical report via WhatsApp or Email'),
              onTap: () async {
                Navigator.pop(ctx);
                await ExportPrintService.instance.printOrSharePdf(visit: visit, isDirectPrint: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_view_rounded, color: Colors.green),
              title: const Text('Export to Excel (.xlsx)'),
              subtitle: const Text('Generates the exact 99-column workbook rows'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await ExportPrintService.instance.exportToExcel(
                  visits: [visit],
                  filenamePrefix: 'Mastitis_${visit.farmId}_${visit.visitDate}',
                );
                await ExportPrintService.instance.shareExcelFile(file, subject: 'Farm ${visit.farmId} Data Export');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportAllVisitsToExcel() async {
    if (_visits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No visits recorded to export.')),
      );
      return;
    }

    final file = await ExportPrintService.instance.exportToExcel(
      visits: _visits,
      filenamePrefix: 'Mastitis_All_Surveillance_Data',
    );
    await ExportPrintService.instance.shareExcelFile(file, subject: 'Complete Mastitis Surveillance Dataset (99 Columns)');
  }

  void _showNewVisitDialog() {
    final farmIdCtrl = TextEditingController();
    final lgaCtrl = TextEditingController();
    String selectedState = 'Kaduna';
    String selectedProductionSystem = 'Semi-intensive';
    String selectedMilkingMethod = 'Hand';
    String selectedHousingType = 'Loose housing';
    DateTime visitDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) => Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 18,
                right: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const UdderLogoWidget(size: 28),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start New Farm Visit',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            Text('Observer: $_observerId', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    TextField(
                      controller: farmIdCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Farm ID *',
                        hintText: 'e.g. FARM-KAD-01',
                        prefixIcon: Icon(Icons.business_outlined, size: 18, color: Color(0xFF64748B)),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: selectedState,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        prefixIcon: Icon(Icons.map_outlined, size: 18, color: Color(0xFF64748B)),
                      ),
                      items: Enums.states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))))).toList(),
                      onChanged: (val) => setSheetState(() => selectedState = val ?? selectedState),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: lgaCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'LGA',
                        hintText: 'Local Government Area',
                        prefixIcon: Icon(Icons.location_city_outlined, size: 18, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: selectedProductionSystem,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(
                        labelText: 'Production System',
                        prefixIcon: Icon(Icons.agriculture_outlined, size: 18, color: Color(0xFF64748B)),
                      ),
                      items: Enums.productionSystems.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))))).toList(),
                      onChanged: (val) => setSheetState(() => selectedProductionSystem = val ?? selectedProductionSystem),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: selectedMilkingMethod,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(
                        labelText: 'Milking Method',
                        prefixIcon: Icon(Icons.water_drop_outlined, size: 18, color: Color(0xFF64748B)),
                      ),
                      items: Enums.milkingMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))))).toList(),
                      onChanged: (val) => setSheetState(() => selectedMilkingMethod = val ?? selectedMilkingMethod),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: selectedHousingType,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(
                        labelText: 'Housing Type',
                        prefixIcon: Icon(Icons.roofing_outlined, size: 18, color: Color(0xFF64748B)),
                      ),
                      items: Enums.housingTypes.map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))))).toList(),
                      onChanged: (val) => setSheetState(() => selectedHousingType = val ?? selectedHousingType),
                    ),
                    const SizedBox(height: 10),

                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: visitDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setSheetState(() => visitDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF0F766E)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Visit Date', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  Text(DateFormat('yyyy-MM-dd').format(visitDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final farmId = farmIdCtrl.text.trim();
                        if (farmId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a Farm ID.')),
                          );
                          return;
                        }

                        final dateStr = DateFormat('yyyy-MM-dd').format(visitDate);
                        final visitId = '${farmId}_${dateStr.replaceAll('-', '')}';

                        final newVisit = VisitRecord(
                          id: visitId,
                          visitId: visitId,
                          farmId: farmId,
                          visitDate: dateStr,
                          scheduledVisitDate: dateStr,
                          observerId: _observerId,
                          state: selectedState,
                          lga: lgaCtrl.text.trim(),
                          farmProductionSystem: selectedProductionSystem,
                          farmMilkingMethod: selectedMilkingMethod,
                          farmHousingType: selectedHousingType,
                          cows: [],
                        );

                        await _storage.saveVisit(newVisit);
                        if (ctx.mounted) Navigator.pop(ctx);

                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FarmVisitScreen(visit: newVisit)),
                        ).then((_) => _loadData());
                      },
                      child: const Text('Proceed to Farm Header →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _visits.where((v) => !v.isSynced && v.cows.isNotEmpty).length;
    final totalCowsExamined = _visits.fold<int>(0, (sum, v) => sum + v.cows.length);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            const UdderLogoWidget(size: 26, showBadgeBorder: true),
            const SizedBox(width: 8),
            Text('mastitis_research', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isDesktop ? 16 : 15, color: const Color(0xFF0F172A))),
            if (isDesktop) ...[
              const SizedBox(width: 8),
              Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
              const SizedBox(width: 8),
              Text('Longitudinal Udder Health Study', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
        actions: [
          if (isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.table_chart_rounded, size: 20, color: Color(0xFF0F766E)),
              tooltip: '99-Column Dataset Spreadsheet',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DatasetSpreadsheetScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.table_view_outlined, size: 20),
              tooltip: 'Export to Excel (.xlsx)',
              onPressed: _visits.isEmpty ? null : _exportAllVisitsToExcel,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.sync_rounded, size: 20),
            tooltip: 'Sync Cloud Data',
            onPressed: _isSyncing ? null : _syncAllPending,
          ),
          IconButton(
            tooltip: 'Observer Profile & Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ObserverProfileScreen()),
              ).then((_) => _loadData());
            },
            icon: _observerImagePath != null && File(_observerImagePath!).existsSync()
                ? Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0F766E), width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.file(File(_observerImagePath!), width: 28, height: 28, fit: BoxFit.cover),
                    ),
                  )
                : const Icon(Icons.account_circle_outlined, size: 22),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E), strokeWidth: 2.5))
          : RefreshIndicator(
              color: const Color(0xFF0F766E),
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ResponsiveWrapper(
                  maxWidth: 720,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Modern Compact Hero Banner
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ObserverProfileScreen()),
                                    ).then((_) => _loadData());
                                  },
                                  child: _observerImagePath != null && File(_observerImagePath!).existsSync()
                                      ? Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: ClipOval(
                                            child: Image.file(
                                              File(_observerImagePath!),
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : const UdderLogoWidget(size: 44, showBadgeBorder: true),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Observer: $_observerId',
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _observerName,
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Quick Metric Strip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMetricCol('${_visits.length}', 'Visits'),
                                  Container(width: 1, height: 18, color: Colors.white24),
                                  _buildMetricCol('$totalCowsExamined', 'Cows'),
                                  Container(width: 1, height: 18, color: Colors.white24),
                                  _buildMetricCol('${totalCowsExamined * 4}', 'Quarters'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _showNewVisitDialog,
                              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                              label: const Text('New Farm Visit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F766E),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AllVisitsScreen()));
                              },
                              icon: const Icon(Icons.cloud_done_outlined, size: 18, color: Color(0xFF0F766E)),
                              label: const Text('Cloud Feed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Grand Researcher 99-Column Study Dataset Button
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DatasetSpreadsheetScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                            border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.25)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.table_chart_rounded, color: Color(0xFF0F766E), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Open 99-Column Dataset Spreadsheet',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F766E), size: 15),
                            ],
                          ),
                        ),
                      ),

                      // Pending Sync Banner
                      if (pendingCount > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_upload_outlined, color: Color(0xFFD97706), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '$pendingCount visit(s) ready to sync',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFB45309)),
                                ),
                              ),
                              InkWell(
                                onTap: _isSyncing ? null : _syncAllPending,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: _isSyncing
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Sync Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recorded Visits', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                            child: Text('${_visits.length} saved', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (_visits.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              const UdderLogoWidget(size: 40),
                              const SizedBox(height: 12),
                              const Text('No local visits on this device yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              const Text('Tap "New Farm Visit" to start recording field data.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12), textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      else
                        ..._visits.map((visit) {
                          final hasCows = visit.cows.isNotEmpty;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CowListScreen(visit: visit)),
                                ).then((_) => _loadData());
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFCCFBF1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.villa_outlined, color: Color(0xFF0F766E), size: 18),
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(visit.farmId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                                Text('ID: ${visit.visitId}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: visit.isSynced ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: visit.isSynced ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                visit.isSynced ? Icons.cloud_done_outlined : Icons.cloud_queue_outlined,
                                                size: 12,
                                                color: visit.isSynced ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                visit.isSynced ? 'Synced' : 'Local Draft',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: visit.isSynced ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Date: ${visit.visitDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                          Text('State: ${visit.state}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                          Text(
                                            '${visit.cows.length} Cows',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: hasCows ? const Color(0xFF0F766E) : const Color(0xFFDC2626)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.share_outlined, size: 18, color: Color(0xFF0F766E)),
                                              tooltip: 'Export/Print',
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(6),
                                              onPressed: () => _showVisitExportOptions(visit),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                              tooltip: 'Delete',
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(6),
                                              onPressed: () => _confirmDeleteVisit(visit),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                minimumSize: const Size(0, 32),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => FarmVisitScreen(visit: visit)),
                                                ).then((_) => _loadData());
                                              },
                                              child: const Text('Header', style: TextStyle(fontSize: 12)),
                                            ),
                                            const SizedBox(width: 6),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF0F766E),
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size(0, 32),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => CowListScreen(visit: visit)),
                                                ).then((_) => _loadData());
                                              },
                                              child: const Text('Cows', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                        }),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: _showNewVisitDialog,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('New Visit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMetricCol(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF99F6E4))),
      ],
    );
  }
}


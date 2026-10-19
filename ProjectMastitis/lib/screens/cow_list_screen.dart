import 'package:flutter/material.dart';
import '../models/study_models.dart';
import '../services/local_storage_service.dart';
import '../services/export_print_service.dart';
import '../widgets/responsive_wrapper.dart';
import 'cow_visit_screen.dart';
import 'quarter_grid_screen.dart';
import 'visit_summary_screen.dart';

class CowListScreen extends StatefulWidget {
  final VisitRecord visit;
  const CowListScreen({super.key, required this.visit});

  @override
  State<CowListScreen> createState() => _CowListScreenState();
}

class _CowListScreenState extends State<CowListScreen> {
  final _exportService = ExportPrintService.instance;

  Color _getCmtColor(String score) {
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

  Widget _buildQuarterPill(CowRecord cow, String qName, QuarterData q) {
    final c = _getCmtColor(q.cmtScore);
    final isBlind = q.functionalStatus != 'Functional';
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuarterGridScreen(
              visit: widget.visit,
              cow: cow,
              initialQuarter: qName,
            ),
          ),
        ).then((_) {
          setState(() {});
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isBlind ? const Color(0xFFF1F5F9) : c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isBlind ? const Color(0xFFCBD5E1) : c.withValues(alpha: 0.7), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBlind ? '$qName: Blind' : '$qName [${q.cmtScore}]',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isBlind ? const Color(0xFF64748B) : c,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 10, color: isBlind ? const Color(0xFF94A3B8) : c),
          ],
        ),
      ),
    );
  }

  void _addCow() {
    final nextNum = widget.visit.cows.length + 1;
    final cowId = 'C${nextNum.toString().padLeft(3, '0')}';
    final newCow = CowRecord(cowId: cowId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CowVisitScreen(
          visit: widget.visit,
          cow: newCow,
          isNew: true,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _editCow(CowRecord cow) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CowVisitScreen(
          visit: widget.visit,
          cow: cow,
          isNew: false,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _deleteCow(int index) async {
    final cow = widget.visit.cows[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Cow Record?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Remove cow "${cow.cowId}" and its quarter examinations?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        widget.visit.cows.removeAt(index);
      });
      await LocalStorageService.instance.saveVisit(widget.visit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cow ${cow.cowId} removed.', style: const TextStyle(fontSize: 13))),
        );
      }
    }
  }

  void _showCowExportMenu(CowRecord cow) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cow ${cow.cowId} Options', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Farm ${widget.visit.farmId} • ${widget.visit.visitDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const Divider(height: 20),
                ListTile(
                  leading: const Icon(Icons.print_outlined, size: 20, color: Color(0xFF0F766E)),
                  title: const Text('Print / Preview Cow PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Clinical examination & CMT summary sheet', style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _exportService.printOrSharePdf(visit: widget.visit, singleCow: cow, isDirectPrint: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: Color(0xFFDC2626)),
                  title: const Text('Share Cow PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Send PDF via WhatsApp or Email', style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _exportService.printOrSharePdf(visit: widget.visit, singleCow: cow, isDirectPrint: false);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFarmVisitExportMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export Visit: ${widget.visit.farmId}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${widget.visit.cows.length} Cows Recorded • ${widget.visit.visitDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const Divider(height: 20),
                ListTile(
                  leading: const Icon(Icons.print_outlined, size: 20, color: Color(0xFF0F766E)),
                  title: const Text('Print Herd Summary PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _exportService.printOrSharePdf(visit: widget.visit, isDirectPrint: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.table_view_outlined, size: 20, color: Color(0xFF16A34A)),
                  title: const Text('Export Visit to Excel (.xlsx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final file = await _exportService.exportToExcel(
                      visits: [widget.visit],
                      filenamePrefix: 'Mastitis_Farm_${widget.visit.farmId}',
                    );
                    await _exportService.shareExcelFile(file, subject: 'Farm ${widget.visit.farmId} Data');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Farm ${v.farmId}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            Text('${v.cows.length} Cows Examined • ${v.visitDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, size: 20),
            tooltip: 'Export Farm Data',
            onPressed: v.cows.isEmpty ? null : _showFarmVisitExportMenu,
          ),
        ],
      ),
      body: v.cows.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pets_outlined, size: 40, color: Color(0xFF0F766E)),
                    const SizedBox(height: 12),
                    const Text('No cows recorded for this visit yet.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    const Text('Tap "+ Add Cow" to examine your first cow and record CMT scores.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: _addCow,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add First Cow', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
              child: ResponsiveWrapper(
                maxWidth: 720,
                child: Column(
                  children: List.generate(v.cows.length, (index) {
                    final cow = v.cows[index];
                    final hasMastitis = cow.quarters.values.any((q) => q.clinicalMastitis == 'Yes');
                    final hasTx = cow.treatment.txCurrentTreatment == 'Yes';

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
                        onTap: () => _editCow(cow),
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
                                        decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.pets, color: Color(0xFF0F766E), size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(cow.cowId, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                      if (cow.localTagId != null && cow.localTagId!.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text('(${cow.localTagId})', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      ],
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.share_outlined, size: 17, color: Color(0xFF0F766E)),
                                        tooltip: 'Export',
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        onPressed: () => _showCowExportMenu(cow),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF64748B)),
                                        tooltip: 'Edit',
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        onPressed: () => _editCow(cow),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFDC2626)),
                                        tooltip: 'Delete',
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        onPressed: () => _deleteCow(index),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Parity: ${cow.parity} • BCS: ${cow.cowBcsValue ?? "-"} • Yield: ${cow.cowMilkYieldValue ?? "-"} ${cow.cowMilkYieldUnit}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              const SizedBox(height: 8),

                              // 4 Quarters Pill Grid
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildQuarterPill(cow, 'LF', cow.quarters['LF'] ?? QuarterData(quarter: 'LF')),
                                  _buildQuarterPill(cow, 'RF', cow.quarters['RF'] ?? QuarterData(quarter: 'RF')),
                                  _buildQuarterPill(cow, 'LR', cow.quarters['LR'] ?? QuarterData(quarter: 'LR')),
                                  _buildQuarterPill(cow, 'RR', cow.quarters['RR'] ?? QuarterData(quarter: 'RR')),
                                ],
                              ),

                              if (hasMastitis || hasTx) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (hasMastitis)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                                        child: const Text('⚠️ Clinical Mastitis', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                                      ),
                                    if (hasTx) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(4)),
                                        child: const Text('💊 Treatment Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: _addCow,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add Cow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      bottomNavigationBar: v.cows.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: ResponsiveWrapper(
                  maxWidth: 720,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VisitSummaryScreen(visit: v)),
                      );
                    },
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: Text('Finish & Review (${v.cows.length} Cows)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
    );
  }
}

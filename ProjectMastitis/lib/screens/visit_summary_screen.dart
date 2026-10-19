import 'package:flutter/material.dart';
import '../models/study_models.dart';
import '../services/local_storage_service.dart';
import '../widgets/responsive_wrapper.dart';

class VisitSummaryScreen extends StatefulWidget {
  final VisitRecord visit;
  const VisitSummaryScreen({super.key, required this.visit});

  @override
  State<VisitSummaryScreen> createState() => _VisitSummaryScreenState();
}

class _VisitSummaryScreenState extends State<VisitSummaryScreen> {
  bool _isSyncing = false;

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

  Future<void> _syncToCloud() async {
    setState(() => _isSyncing = true);
    final error = await LocalStorageService.instance.syncVisitToSupabase(widget.visit);
    setState(() => _isSyncing = false);

    if (!mounted) return;
    if (error == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF0F766E), size: 40),
          title: const Text('Successfully Synced', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          content: Text(
            'All ${widget.visit.cows.length} cows (${widget.visit.cows.length * 4} quarter records) uploaded to the udder_health_data cloud table.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            SizedBox(
              height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Return to Home', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 40),
          title: const Text('Sync Offline / Pending', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          content: Text(
            'Could not upload to cloud: $error\n\nYour data is safely stored locally on this device. You can sync again anytime from the dashboard.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F766E))),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    final totalQuarters = v.cows.length * 4;
    final cmtPositiveCount = v.cows
        .expand((c) => c.quarters.values)
        .where((q) => q.cmtPositiveDerived == 'Yes')
        .length;
    final clinicalMastitisCount = v.cows
        .expand((c) => c.quarters.values)
        .where((q) => q.clinicalMastitis == 'Yes')
        .length;
    final samplesCollected = v.cows
        .expand((c) => c.quarters.values)
        .where((q) => q.labSampleId != null && q.labSampleId!.isNotEmpty)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Visit Review & Cloud Upload', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: ResponsiveWrapper(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Header Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
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
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.agriculture_rounded, color: Color(0xFF0F766E), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Farm: ${v.farmId}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: v.isSynced ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                          border: Border.all(color: v.isSynced ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          v.isSynced ? 'Synced (Cloud)' : 'Pending Sync',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: v.isSynced ? const Color(0xFF047857) : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Visit ID: ${v.visitId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                  const SizedBox(height: 2),
                  Text(
                    'Date: ${v.visitDate}  •  ${v.state}, ${v.lga}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  Text('Observer: ${v.observerId}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Study Metrics Grid
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Observations Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _metricBox('Cows', '${v.cows.length}', const Color(0xFF0F766E))),
                      const SizedBox(width: 8),
                      Expanded(child: _metricBox('Quarters', '$totalQuarters', const Color(0xFF475569))),
                      const SizedBox(width: 8),
                      Expanded(child: _metricBox('CMT (+)', '$cmtPositiveCount', const Color(0xFFF59E0B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _metricBox('Clinical', '$clinicalMastitisCount', const Color(0xFFDC2626))),
                      const SizedBox(width: 8),
                      Expanded(child: _metricBox('Samples', '$samplesCollected', const Color(0xFF6366F1))),
                      const SizedBox(width: 8),
                      Expanded(child: _metricBox('Herd Size', '${v.farmTotalCattle ?? '-'}', const Color(0xFF0D9488))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cows Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cows & Quarters', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                Text('${v.cows.length} cows recorded', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 8),

            if (v.cows.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: const Text('No cows entered. Please return and add cows before syncing.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              )
            else
              ...v.cows.map((cow) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Cow: ${cow.cowId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          Text('Parity: ${cow.parity}  •  BCS: ${cow.cowBcsValue}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['LF', 'RF', 'LR', 'RR'].map((qKey) {
                          final q = cow.quarters[qKey] ?? QuarterData(quarter: qKey);
                          final color = _getCmtColor(q.cmtScore);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$qKey: ${q.cmtScore}',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: color),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Big Sync Button
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (_isSyncing || v.cows.isEmpty) ? null : _syncToCloud,
                icon: _isSyncing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined, size: 20),
                label: Text(
                  _isSyncing ? 'Uploading to Supabase...' : 'Sync Visit to Supabase (${v.cows.length * 4} rows)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 40,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Dashboard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

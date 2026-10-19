import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../widgets/responsive_wrapper.dart';

class AllVisitsScreen extends StatefulWidget {
  const AllVisitsScreen({super.key});

  @override
  State<AllVisitsScreen> createState() => _AllVisitsScreenState();
}

class _AllVisitsScreenState extends State<AllVisitsScreen> {
  final _storage = LocalStorageService.instance;
  List<Map<String, dynamic>> _cloudRows = [];
  bool _isLoading = true;
  String _filter = 'All'; // All, Positive, Clinical

  @override
  void initState() {
    super.initState();
    _fetchCloudData();
  }

  Future<void> _fetchCloudData() async {
    setState(() => _isLoading = true);
    final data = await _storage.fetchAllCloudEntries(limit: 100);
    setState(() {
      _cloudRows = data;
      _isLoading = false;
    });
  }

  Color _getCmtColor(String? score) {
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

  @override
  Widget build(BuildContext context) {
    var filtered = _cloudRows;
    if (_filter == 'Positive') {
      filtered = filtered.where((r) => r['cmt_positive_derived'] == 'Yes').toList();
    } else if (_filter == 'Clinical') {
      filtered = filtered.where((r) => r['quarter_clinical_mastitis'] == 'Yes').toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cloud Surveillance Feed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            Text('Multi-device research database records', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh',
            onPressed: _fetchCloudData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(width: 6),
                ...['All', 'Positive', 'Clinical'].map((f) {
                  final isSel = _filter == f;
                  final label = f == 'All' ? 'All Rows' : (f == 'Positive' ? 'CMT (+)' : 'Clinical');
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isSel ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E), strokeWidth: 2.5))
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_outlined, size: 40, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              const Text('No cloud records found yet.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              const Text(
                                'Visits synced by any researcher on any device will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F766E),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                ),
                                onPressed: _fetchCloudData,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: ResponsiveWrapper(
                          maxWidth: 720,
                          child: Column(
                            children: List.generate(filtered.length, (index) {
                              final row = filtered[index];
                              final farmId = row['farm_id'] ?? 'Unknown';
                              final cowId = row['cow_id'] ?? 'Unknown';
                              final quarter = row['quarter'] ?? '';
                              final cmt = row['cmt_score'] ?? 'N';
                              final date = row['visit_date'] ?? '';
                              final obs = row['observer_id'] ?? '';
                              final isPos = row['cmt_positive_derived'] == 'Yes';
                              final isClin = row['quarter_clinical_mastitis'] == 'Yes';
                              final color = _getCmtColor(cmt);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        quarter,
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: color),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text('Cow $cowId', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text('CMT: $cmt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text('Farm: $farmId • $date • Obs: $obs', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          if (isClin)
                                            const Text('⚠️ Clinical Mastitis', style: TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isPos ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: isPos ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0)),
                                      ),
                                      child: Text(
                                        isPos ? 'CMT (+)' : 'CMT (-)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isPos ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

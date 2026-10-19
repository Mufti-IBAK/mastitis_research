import 'package:flutter/material.dart';
import '../models/study_models.dart';
import '../constants/enums.dart';
import '../services/local_storage_service.dart';
import '../widgets/reference_keys_sheet.dart';
import '../widgets/cmt_score_selector.dart';
import '../widgets/responsive_wrapper.dart';
import 'treatment_screen.dart';

class QuarterGridScreen extends StatefulWidget {
  final VisitRecord visit;
  final CowRecord cow;

  const QuarterGridScreen({
    super.key,
    required this.visit,
    required this.cow,
  });

  @override
  State<QuarterGridScreen> createState() => _QuarterGridScreenState();
}

class _QuarterGridScreenState extends State<QuarterGridScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _quarters = ['LF', 'RF', 'LR', 'RR'];

  // Global lot / reader for this cow
  late TextEditingController _reagentLotCtrl;
  late TextEditingController _reagentExpiryCtrl;
  late TextEditingController _readerIdCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final firstQ = widget.cow.quarters['LF']!;
    _reagentLotCtrl = TextEditingController(text: firstQ.cmtReagentLot ?? 'LOT-2026-A');
    _reagentExpiryCtrl = TextEditingController(text: firstQ.cmtReagentExpiry ?? '2027-12-31');
    _readerIdCtrl = TextEditingController(text: firstQ.cmtReaderId ?? widget.visit.observerId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reagentLotCtrl.dispose();
    _reagentExpiryCtrl.dispose();
    _readerIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAllQuarters() async {
    final lot = _reagentLotCtrl.text.trim();
    final exp = _reagentExpiryCtrl.text.trim();
    final reader = _readerIdCtrl.text.trim();

    for (final q in widget.cow.quarters.values) {
      q.cmtReagentLot = lot;
      q.cmtReagentExpiry = exp;
      q.cmtReaderId = reader;
    }

    await LocalStorageService.instance.saveVisit(widget.visit);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        content: Text('Saved examination for Cow ${widget.cow.cowId}', style: const TextStyle(fontSize: 13)),
        duration: const Duration(seconds: 1),
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildQuarterForm(QuarterData q) {
    final isFunctional = q.functionalStatus == 'Functional';
    final hasMastitis = q.clinicalMastitis == 'Yes';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: ResponsiveWrapper(
        maxWidth: 680,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${q.quarter} Functional Status', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Col 52', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['Functional', 'Blind/nonfunctional', 'Absent'].map((status) {
                      final isSelected = q.functionalStatus == status;
                      final label = status == 'Blind/nonfunctional' ? 'Blind' : status;

                      return InkWell(
                        borderRadius: BorderRadius.circular(7),
                        onTap: () {
                          setState(() {
                            q.functionalStatus = status;
                            if (status != 'Functional') {
                              q.missingReason = status == 'Absent' ? 'Absent' : 'Blind quarter';
                              q.cmtScore = 'Not done';
                            } else {
                              q.missingReason = 'Not missing';
                              q.cmtScore = 'N';
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (!isFunctional) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: q.missingReason ?? 'Blind quarter',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(labelText: 'Reason', isDense: true),
                      items: Enums.missingReasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))))).toList(),
                      onChanged: (val) => setState(() => q.missingReason = val),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (isFunctional) ...[
              // CMT Score Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CMT Score',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: q.cmtPositiveDerived == 'Yes' ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Positive: ${q.cmtPositiveDerived}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: q.cmtPositiveDerived == 'Yes' ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CmtScoreSelector(
                      value: q.cmtScore,
                      onChanged: (val) => setState(() => q.cmtScore = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Clinical Signs Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Clinical Mastitis & Physical Exam', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Clinical Mastitis?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                        Row(
                          children: ['Yes', 'No'].map((opt) {
                            final isSel = (q.clinicalMastitis ?? 'No') == opt;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () {
                                  setState(() {
                                    q.clinicalMastitis = opt;
                                    if (opt == 'Yes' && (q.clinicalGrade == null || q.clinicalGrade == '0 None')) {
                                      q.clinicalGrade = '1 Mild';
                                      q.milkAbnormality = 'Yes';
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isSel ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    opt,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                      color: isSel ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    if (hasMastitis) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: q.clinicalGrade ?? '1 Mild',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                        decoration: const InputDecoration(labelText: 'Clinical Grade', isDense: true),
                        items: Enums.clinicalGrades.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))))).toList(),
                        onChanged: (val) => setState(() => q.clinicalGrade = val),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Milk Abnormality:', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          Row(
                            children: ['Yes', 'No'].map((opt) {
                              final isSel = (q.milkAbnormality ?? 'Yes') == opt;
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => setState(() => q.milkAbnormality = opt),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSel ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isSel ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      opt,
                                      style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? Colors.white : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Swelling / Heat / Pain:', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          Row(
                            children: ['Yes', 'No'].map((opt) {
                              final isSel = (q.swellingHeatPain ?? 'No') == opt;
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => setState(() => q.swellingHeatPain = opt),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSel ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isSel ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      opt,
                                      style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? Colors.white : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 16),

                    // Teat End Score
                    const Text('Teat-End Hyperkeratosis (Col 57):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        {'val': 1, 'lbl': '1 None'},
                        {'val': 2, 'lbl': '2 Smooth'},
                        {'val': 3, 'lbl': '3 Rough'},
                        {'val': 4, 'lbl': '4 Very R'},
                      ].map((item) {
                        final val = item['val'] as int;
                        final lbl = item['lbl'] as String;
                        final isSel = (q.teatEndScore ?? 1) == val;
                        return InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => setState(() => q.teatEndScore = val),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSel ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              lbl,
                              style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? Colors.white : const Color(0xFF64748B)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Teat Lesion Present?', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                        Row(
                          children: ['Yes', 'No'].map((opt) {
                            final isSel = (q.teatLesion ?? 'No') == opt;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => setState(() => q.teatLesion = opt),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isSel ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    opt,
                                    style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? Colors.white : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Lab Sample & Documentation Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Laboratory & Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: q.labSampleId,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Lab Sample ID (Col 65)',
                        hintText: 'e.g. S-KAD-001-LF',
                        isDense: true,
                      ),
                      onChanged: (val) => q.labSampleId = val.trim(),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: q.notes,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Notes (Col 99)',
                        hintText: 'Observations...',
                        isDense: true,
                      ),
                      onChanged: (val) => q.notes = val.trim(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cow = widget.cow;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cow ${cow.cowId}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            Text('Visit: ${widget.visit.visitId}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            tooltip: 'CMT Grading Guide',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ReferenceKeysSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.medication_outlined, size: 20),
            tooltip: 'Treatment Log',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TreatmentScreen(
                    visit: widget.visit,
                    cow: cow,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0F766E),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF0F766E),
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              tabs: _quarters.map((qKey) {
                final q = cow.quarters[qKey] ?? QuarterData(quarter: qKey);
                final score = q.functionalStatus != 'Functional' ? 'X' : q.cmtScore;
                return Tab(text: '$qKey [$score]');
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _quarters.map((qKey) {
          final q = cow.quarters[qKey] ?? QuarterData(quarter: qKey);
          return _buildQuarterForm(q);
        }).toList(),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.medical_services_outlined, size: 16, color: Color(0xFF0F766E)),
                  label: const Text('Add Treatment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F766E))),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TreatmentScreen(
                          visit: widget.visit,
                          cow: cow,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text('Save & Done', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onPressed: _saveAllQuarters,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

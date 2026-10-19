import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/study_models.dart';
import '../constants/enums.dart';
import '../services/local_storage_service.dart';
import '../widgets/responsive_wrapper.dart';
import 'quarter_grid_screen.dart';

class CowVisitScreen extends StatefulWidget {
  final VisitRecord visit;
  final CowRecord cow;
  final bool isNew;

  const CowVisitScreen({
    super.key,
    required this.visit,
    required this.cow,
    this.isNew = false,
  });

  @override
  State<CowVisitScreen> createState() => _CowVisitScreenState();
}

class _CowVisitScreenState extends State<CowVisitScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cowIdCtrl;
  late TextEditingController _localTagCtrl;
  late TextEditingController _lactationIdCtrl;
  late TextEditingController _breedCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _parityCtrl;
  late TextEditingController _calvingDateCtrl;
  late TextEditingController _yieldCtrl;
  late TextEditingController _tempCtrl;
  late TextEditingController _diseaseCtrl;

  late String _cowSource;
  late String _pregnancyStatus;
  late String _prevClinMastitis;
  late String _prevHighScc;
  late String _dryCowTherapy;
  late String _teatSealant;

  late String _yieldUnit;
  late String _yieldPeriod;
  late double _bcsValue;
  late int _locomotionScore;
  late int _udderHygieneScore;

  late String _antimicrobial14d;
  late String _mastitisTxSinceLast;
  late String _incompleteMilking;

  @override
  void initState() {
    super.initState();
    final c = widget.cow;
    _cowIdCtrl = TextEditingController(text: c.cowId);
    _localTagCtrl = TextEditingController(text: c.localTagId ?? '');
    _lactationIdCtrl = TextEditingController(text: c.lactationId ?? 'L1');
    _breedCtrl = TextEditingController(text: c.breedGeneticGroup ?? 'Bunaji (White Fulani)');
    _ageCtrl = TextEditingController(text: c.cowAgeYears?.toString() ?? '');
    _parityCtrl = TextEditingController(text: c.parity.toString());
    _calvingDateCtrl = TextEditingController(text: c.calvingDate ?? '');
    _yieldCtrl = TextEditingController(text: c.cowMilkYieldValue?.toString() ?? '');
    _tempCtrl = TextEditingController(text: c.cowRectalTemperatureC?.toString() ?? '38.5');
    _diseaseCtrl = TextEditingController(text: c.cowConcurrentDiseaseSigns ?? '');

    _cowSource = c.cowSource;
    _pregnancyStatus = c.pregnancyStatus;
    _prevClinMastitis = c.previousClinicalMastitis;
    _prevHighScc = c.previousHighSccCmt;
    _dryCowTherapy = c.dryCowTherapyPrevious;
    _teatSealant = c.teatSealantPrevious;

    _yieldUnit = c.cowMilkYieldUnit;
    _yieldPeriod = c.cowYieldPeriod;
    _bcsValue = c.cowBcsValue;
    _locomotionScore = c.cowLocomotionScore;
    _udderHygieneScore = c.cowUdderHygieneScore;

    _antimicrobial14d = c.cowAntimicrobialPrevious14d;
    _mastitisTxSinceLast = c.cowMastitisTreatmentSinceLast;
    _incompleteMilking = c.cowIncompleteMilkingOrSuckling;
  }

  @override
  void dispose() {
    _cowIdCtrl.dispose();
    _localTagCtrl.dispose();
    _lactationIdCtrl.dispose();
    _breedCtrl.dispose();
    _ageCtrl.dispose();
    _parityCtrl.dispose();
    _calvingDateCtrl.dispose();
    _yieldCtrl.dispose();
    _tempCtrl.dispose();
    _diseaseCtrl.dispose();
    super.dispose();
  }

  int? _calcLiveDim() {
    final cDateStr = _calvingDateCtrl.text.trim();
    if (cDateStr.isEmpty) return null;
    try {
      final cDate = DateTime.parse(cDateStr);
      final vDate = DateTime.parse(widget.visit.visitDate);
      return vDate.difference(cDate).inDays;
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectCalvingDate() async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 60));
    try {
      if (_calvingDateCtrl.text.isNotEmpty) {
        initial = DateTime.parse(_calvingDateCtrl.text);
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _calvingDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveAndNext() async {
    if (!_formKey.currentState!.validate()) return;

    final c = widget.cow;
    c.cowId = _cowIdCtrl.text.trim();
    c.localTagId = _localTagCtrl.text.trim().isEmpty ? null : _localTagCtrl.text.trim();
    c.lactationId = _lactationIdCtrl.text.trim().isEmpty ? 'L1' : _lactationIdCtrl.text.trim();
    c.breedGeneticGroup = _breedCtrl.text.trim();
    c.cowAgeYears = double.tryParse(_ageCtrl.text);
    c.parity = int.tryParse(_parityCtrl.text) ?? 1;
    c.calvingDate = _calvingDateCtrl.text.trim().isEmpty ? null : _calvingDateCtrl.text.trim();

    c.cowSource = _cowSource;
    c.pregnancyStatus = _pregnancyStatus;
    c.previousClinicalMastitis = _prevClinMastitis;
    c.previousHighSccCmt = _prevHighScc;
    c.dryCowTherapyPrevious = _dryCowTherapy;
    c.teatSealantPrevious = _teatSealant;

    c.cowMilkYieldValue = double.tryParse(_yieldCtrl.text);
    c.cowMilkYieldUnit = _yieldUnit;
    c.cowYieldPeriod = _yieldPeriod;
    c.cowBcsValue = _bcsValue;
    c.cowLocomotionScore = _locomotionScore;
    c.cowUdderHygieneScore = _udderHygieneScore;
    c.cowRectalTemperatureC = double.tryParse(_tempCtrl.text);
    c.cowConcurrentDiseaseSigns = _diseaseCtrl.text.trim();

    c.cowAntimicrobialPrevious14d = _antimicrobial14d;
    c.cowMastitisTreatmentSinceLast = _mastitisTxSinceLast;
    c.cowIncompleteMilkingOrSuckling = _incompleteMilking;

    if (widget.isNew && !widget.visit.cows.any((existing) => existing.cowId == c.cowId)) {
      widget.visit.cows.add(c);
    }

    await LocalStorageService.instance.saveVisit(widget.visit);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuarterGridScreen(
          visit: widget.visit,
          cow: c,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : options.first,
        style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))))).toList(),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  Widget _buildYesNoToggle(String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
          Row(
            children: ['Yes', 'No', 'Unknown'].map((opt) {
              final isSel = value == opt;
              final shortLabel = opt == 'Unknown' ? 'Unk' : opt;
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => onChanged(opt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isSel ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      shortLabel,
                      style: TextStyle(
                        fontSize: 11,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveDim = _calcLiveDim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.isNew ? 'New Cow Exam' : 'Edit Cow: ${widget.cow.cowId}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            Text('Farm ${widget.visit.farmId} • Section B', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: ResponsiveWrapper(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. COW IDENTITY & LACTATION
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
                      const Text('1. Identity & Lactation (Cols 23-37)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cowIdCtrl,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(labelText: 'Cow ID (Col 23) *', isDense: true),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _localTagCtrl,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(labelText: 'Local Tag ID (Col 24)', isDense: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lactationIdCtrl,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(labelText: 'Lactation ID (Col 25)', isDense: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _parityCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(labelText: 'Parity (Col 30) *', isDense: true),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _breedCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(labelText: 'Breed / Genetic Group (Col 26)', isDense: true),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(labelText: 'Age in Years (Col 28)', isDense: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdown('Source (Col 29)', _cowSource, Enums.cowSource, (v) => setState(() => _cowSource = v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Calving date & Live DIM
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _calvingDateCtrl,
                              readOnly: true,
                              onTap: _selectCalvingDate,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'Calving Date (Col 31)',
                                hintText: 'YYYY-MM-DD',
                                isDense: true,
                                suffixIcon: Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                const Text('DIM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                                Text(
                                  liveDim != null ? '$liveDim d' : 'Auto',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildDropdown('Pregnancy Status (Col 33)', _pregnancyStatus, Enums.pregnancyStatus, (v) => setState(() => _pregnancyStatus = v)),
                      _buildYesNoToggle('Prev Clinical Mastitis? (Col 34)', _prevClinMastitis, (v) => setState(() => _prevClinMastitis = v)),
                      _buildYesNoToggle('Prev High SCC / CMT? (Col 35)', _prevHighScc, (v) => setState(() => _prevHighScc = v)),
                      _buildDropdown('Dry Cow Therapy Prev (Col 36)', _dryCowTherapy, Enums.dryCowTherapy, (v) => setState(() => _dryCowTherapy = v)),
                      _buildDropdown('Teat Sealant Prev (Col 37)', _teatSealant, Enums.teatSealant, (v) => setState(() => _teatSealant = v)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 2. TIME-VARYING MEASUREMENTS
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
                      const Text('2. Production & Measurements (Cols 38-50)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _yieldCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(labelText: 'Milk Yield (Col 38)', isDense: true),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 1,
                            child: _buildDropdown('Unit', _yieldUnit, Enums.milkYieldUnits, (v) => setState(() => _yieldUnit = v)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 2,
                            child: _buildDropdown('Period', _yieldPeriod, Enums.yieldPeriods, (v) => setState(() => _yieldPeriod = v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // BCS Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Body Condition (BCS Col 42):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          Text(_bcsValue.toStringAsFixed(2), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF0F766E),
                          thumbColor: const Color(0xFF0F766E),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        ),
                        child: Slider(
                          value: _bcsValue,
                          min: 1.0,
                          max: 5.0,
                          divisions: 16,
                          label: _bcsValue.toStringAsFixed(2),
                          onChanged: (v) => setState(() => _bcsValue = v),
                        ),
                      ),

                      // Locomotion Score (1-5)
                      const Text('Locomotion Score (Col 44):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [1, 2, 3, 4, 5].map((score) {
                          final isSel = _locomotionScore == score;
                          return InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => setState(() => _locomotionScore = score),
                            child: Container(
                              width: 34,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSel ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                score.toString(),
                                style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? Colors.white : const Color(0xFF64748B)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Udder Hygiene Score (1-4)
                      const Text('Udder Hygiene Score (Col 45: 1=Clean, 4=Dirty):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          {'val': 1, 'lbl': '1 Clean'},
                          {'val': 2, 'lbl': '2 Slight'},
                          {'val': 3, 'lbl': '3 Mod'},
                          {'val': 4, 'lbl': '4 Severe'},
                        ].map((item) {
                          final val = item['val'] as int;
                          final lbl = item['lbl'] as String;
                          final isSel = _udderHygieneScore == val;
                          return InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => setState(() => _udderHygieneScore = val),
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
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _tempCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Rectal Temp °C (Col 46)',
                          suffixText: '°C (Norm: 38-39.3)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _diseaseCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(labelText: 'Concurrent Disease Signs (Col 47)', isDense: true),
                      ),
                      const Divider(height: 16),
                      _buildYesNoToggle('Antimicrobial in Last 14 Days? (Col 48)', _antimicrobial14d, (v) => setState(() => _antimicrobial14d = v)),
                      _buildYesNoToggle('Mastitis Treatment Since Last Visit? (Col 49)', _mastitisTxSinceLast, (v) => setState(() => _mastitisTxSinceLast = v)),
                      _buildYesNoToggle('Incomplete Milking / Calf Suckling? (Col 50)', _incompleteMilking, (v) => setState(() => _incompleteMilking = v)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saveAndNext,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Save Cow & Record Quarters (CMT) →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

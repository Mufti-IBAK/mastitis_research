import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/study_models.dart';
import '../constants/enums.dart';
import '../services/local_storage_service.dart';
import '../widgets/responsive_wrapper.dart';

class TreatmentScreen extends StatefulWidget {
  final VisitRecord visit;
  final CowRecord cow;

  const TreatmentScreen({
    super.key,
    required this.visit,
    required this.cow,
  });

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _txEventIdCtrl;
  late TextEditingController _productNameCtrl;
  late TextEditingController _activeIngredientCtrl;
  late TextEditingController _doseCtrl;
  late TextEditingController _startDateCtrl;
  late TextEditingController _stopDateCtrl;
  late TextEditingController _withholdDateCtrl;

  late String _currentTx;
  late String _doseUnit;
  late String _route;
  late String _outcome;

  @override
  void initState() {
    super.initState();
    final tx = widget.cow.treatment;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _txEventIdCtrl = TextEditingController(text: tx.txEventId ?? 'TX-${widget.cow.cowId}-01');
    _productNameCtrl = TextEditingController(text: tx.txProductTradeName ?? '');
    _activeIngredientCtrl = TextEditingController(text: tx.txActiveIngredient ?? '');
    _doseCtrl = TextEditingController(text: tx.txDose?.toString() ?? '');
    _startDateCtrl = TextEditingController(text: tx.txStartDate ?? today);
    _stopDateCtrl = TextEditingController(text: tx.txStopDate ?? today);
    _withholdDateCtrl = TextEditingController(text: tx.txMilkWithdrawalEndDate ?? '');

    _currentTx = tx.txCurrentTreatment;
    _doseUnit = tx.txDoseUnit ?? 'tube';
    _route = tx.txRoute ?? 'Intramammary';
    _outcome = tx.txOutcomeNextVisit ?? 'Pending';
  }

  @override
  void dispose() {
    _txEventIdCtrl.dispose();
    _productNameCtrl.dispose();
    _activeIngredientCtrl.dispose();
    _doseCtrl.dispose();
    _startDateCtrl.dispose();
    _stopDateCtrl.dispose();
    _withholdDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(ctrl.text) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveTreatment() async {
    if (!_formKey.currentState!.validate()) return;

    final tx = widget.cow.treatment;
    tx.txEventId = _txEventIdCtrl.text.trim();
    tx.txCurrentTreatment = _currentTx;
    tx.txProductTradeName = _productNameCtrl.text.trim();
    tx.txActiveIngredient = _activeIngredientCtrl.text.trim();
    tx.txDose = double.tryParse(_doseCtrl.text);
    tx.txDoseUnit = _doseUnit;
    tx.txRoute = _route;
    tx.txStartDate = _startDateCtrl.text.trim().isEmpty ? null : _startDateCtrl.text.trim();
    tx.txStopDate = _stopDateCtrl.text.trim().isEmpty ? null : _stopDateCtrl.text.trim();
    tx.txMilkWithdrawalEndDate = _withholdDateCtrl.text.trim().isEmpty ? null : _withholdDateCtrl.text.trim();
    tx.txOutcomeNextVisit = _outcome;

    await LocalStorageService.instance.saveVisit(widget.visit);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0F766E),
        content: Text('Treatment record saved.', style: TextStyle(fontSize: 13)),
        duration: Duration(seconds: 1),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Treatment: Cow ${widget.cow.cowId}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const Text('Clinical Mastitis Treatment Event (Cols 77-87)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: ResponsiveWrapper(
            maxWidth: 680,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
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
                          const Text('Currently Under Treatment?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          Row(
                            children: ['Yes', 'No'].map((opt) {
                              final isSel = _currentTx == opt;
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => setState(() => _currentTx = opt),
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
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _txEventIdCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(labelText: 'Tx Event ID (Col 77)', isDense: true),
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _productNameCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Product Trade Name (Col 79)',
                          hintText: 'e.g. Ubrolexin, Terramycin',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _activeIngredientCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Active Ingredient (Col 80)',
                          hintText: 'e.g. Cefalexin + Kanamycin',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _doseCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(labelText: 'Dose (Col 81)', isDense: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: Enums.txDoseUnits.contains(_doseUnit) ? _doseUnit : Enums.txDoseUnits.first,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                              decoration: const InputDecoration(labelText: 'Unit (Col 82)', isDense: true),
                              items: Enums.txDoseUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _doseUnit = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: Enums.txRoutes.contains(_route) ? _route : Enums.txRoutes.first,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                        decoration: const InputDecoration(labelText: 'Route of Administration (Col 83)', isDense: true),
                        items: Enums.txRoutes.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _route = v);
                        },
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startDateCtrl,
                              readOnly: true,
                              onTap: () => _selectDate(_startDateCtrl),
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'Start Date (84)',
                                isDense: true,
                                suffixIcon: Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _stopDateCtrl,
                              readOnly: true,
                              onTap: () => _selectDate(_stopDateCtrl),
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'Stop Date (85)',
                                isDense: true,
                                suffixIcon: Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _withholdDateCtrl,
                        readOnly: true,
                        onTap: () => _selectDate(_withholdDateCtrl),
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Milk Withdrawal End Date (Col 86)',
                          hintText: 'YYYY-MM-DD',
                          isDense: true,
                          suffixIcon: Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: Enums.txOutcomes.contains(_outcome) ? _outcome : Enums.txOutcomes.first,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                        decoration: const InputDecoration(labelText: 'Outcome at Next Visit (Col 87)', isDense: true),
                        items: Enums.txOutcomes.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _outcome = v);
                        },
                      ),
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
                  onPressed: _saveTreatment,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save Treatment Record', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

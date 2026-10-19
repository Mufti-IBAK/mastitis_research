import 'package:flutter/material.dart';
import '../models/study_models.dart';
import '../constants/enums.dart';
import '../services/local_storage_service.dart';
import '../widgets/responsive_wrapper.dart';
import 'cow_list_screen.dart';

class FarmVisitScreen extends StatefulWidget {
  final VisitRecord visit;
  const FarmVisitScreen({super.key, required this.visit});

  @override
  State<FarmVisitScreen> createState() => _FarmVisitScreenState();
}

class _FarmVisitScreenState extends State<FarmVisitScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _visitIdCtrl;
  late TextEditingController _totalCattleCtrl;
  late TextEditingController _lactatingCowsCtrl;
  late TextEditingController _milkingFreqCtrl;
  late TextEditingController _mainForageCtrl;
  late TextEditingController _lgaCtrl;

  late String _state;
  late String _productionSystem;
  late String _milkingMethod;
  late String _housingType;
  late String _floorWetness;
  late String _beddingCondition;
  late String _manureAccumulation;
  late String _flyAbundance;
  late String _waterAvailable;
  late String _feedChange;
  late String _milkingRoutineChange;
  late String _diseaseOutbreak;

  late String _concentrateOffered;
  late String _mineralSupplement;
  late String _waterSource;
  late String _forestripping;
  late String _premilkingTeatCleaning;
  late String _dryingMaterial;
  late String _glovesUsed;
  late String _postmilkingTeatDisinfection;

  @override
  void initState() {
    super.initState();
    final v = widget.visit;
    _visitIdCtrl = TextEditingController(text: v.visitId);
    _totalCattleCtrl = TextEditingController(text: v.farmTotalCattle?.toString() ?? '');
    _lactatingCowsCtrl = TextEditingController(text: v.farmLactatingCows?.toString() ?? '');
    _milkingFreqCtrl = TextEditingController(text: v.farmMilkingFrequencyDay.toString());
    _mainForageCtrl = TextEditingController(text: v.farmMainForage ?? 'Hay / Crop residue');
    _lgaCtrl = TextEditingController(text: v.lga);

    _state = v.state;
    _productionSystem = v.farmProductionSystem;
    _milkingMethod = v.farmMilkingMethod;
    _housingType = v.farmHousingType;
    _floorWetness = v.farmFloorWetness;
    _beddingCondition = v.farmBeddingCondition;
    _manureAccumulation = v.farmManureAccumulation;
    _flyAbundance = v.farmFlyAbundance;
    _waterAvailable = v.farmWaterAvailable;
    _feedChange = v.farmFeedChange;
    _milkingRoutineChange = v.farmMilkingRoutineChange;
    _diseaseOutbreak = v.farmDiseaseOutbreak;

    _concentrateOffered = v.farmConcentrateOffered;
    _mineralSupplement = v.farmMineralSupplement;
    _waterSource = v.farmWaterSource;
    _forestripping = v.farmForestripping;
    _premilkingTeatCleaning = v.farmPremilkingTeatCleaning;
    _dryingMaterial = v.farmDryingMaterial;
    _glovesUsed = v.farmGlovesUsed;
    _postmilkingTeatDisinfection = v.farmPostmilkingTeatDisinfection;
  }

  @override
  void dispose() {
    _visitIdCtrl.dispose();
    _totalCattleCtrl.dispose();
    _lactatingCowsCtrl.dispose();
    _milkingFreqCtrl.dispose();
    _mainForageCtrl.dispose();
    _lgaCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final v = widget.visit;
    v.visitId = _visitIdCtrl.text.trim();
    v.state = _state;
    v.lga = _lgaCtrl.text.trim();
    v.farmTotalCattle = int.tryParse(_totalCattleCtrl.text);
    v.farmLactatingCows = int.tryParse(_lactatingCowsCtrl.text);
    v.farmMilkingFrequencyDay = int.tryParse(_milkingFreqCtrl.text) ?? 2;
    v.farmProductionSystem = _productionSystem;
    v.farmMilkingMethod = _milkingMethod;
    v.farmHousingType = _housingType;
    v.farmFloorWetness = _floorWetness;
    v.farmBeddingCondition = _beddingCondition;
    v.farmManureAccumulation = _manureAccumulation;
    v.farmFlyAbundance = _flyAbundance;
    v.farmWaterAvailable = _waterAvailable;
    v.farmFeedChange = _feedChange;
    v.farmMilkingRoutineChange = _milkingRoutineChange;
    v.farmDiseaseOutbreak = _diseaseOutbreak;

    v.farmMainForage = _mainForageCtrl.text.trim();
    v.farmConcentrateOffered = _concentrateOffered;
    v.farmMineralSupplement = _mineralSupplement;
    v.farmWaterSource = _waterSource;
    v.farmForestripping = _forestripping;
    v.farmPremilkingTeatCleaning = _premilkingTeatCleaning;
    v.farmDryingMaterial = _dryingMaterial;
    v.farmGlovesUsed = _glovesUsed;
    v.farmPostmilkingTeatDisinfection = _postmilkingTeatDisinfection;

    await LocalStorageService.instance.saveVisit(v);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CowListScreen(visit: v)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Farm Header: ${widget.visit.farmId}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const Text('Section A • Farm Environment & Husbandry', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                // 1. IDENTIFIERS
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
                      const Text('1. Visit Identifiers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _visitIdCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(labelText: 'Visit ID (Col 5) *', isDense: true),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: widget.visit.farmId,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(labelText: 'Farm ID (Col 4)', isDense: true),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: widget.visit.visitDate,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(labelText: 'Visit Date (Col 6)', isDense: true),
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _state,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                              decoration: const InputDecoration(labelText: 'State (Col 2)', isDense: true),
                              items: Enums.states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))))).toList(),
                              onChanged: (val) => setState(() => _state = val ?? _state),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _lgaCtrl,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(labelText: 'LGA (Col 3)', isDense: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 2. FARM CONDITIONS
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
                      const Text('2. Farm Conditions (Cols 9-22)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                      const SizedBox(height: 10),
                      _buildDropdown('Production System (Col 9)', _productionSystem, Enums.productionSystems, (v) => setState(() => _productionSystem = v)),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _totalCattleCtrl,
                              style: const TextStyle(fontSize: 12),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Total Cattle (Col 10)', isDense: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _lactatingCowsCtrl,
                              style: const TextStyle(fontSize: 12),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Lactating Cows (Col 11)', isDense: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildDropdown('Milking Method (Col 12)', _milkingMethod, Enums.milkingMethods, (v) => setState(() => _milkingMethod = v)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                controller: _milkingFreqCtrl,
                                style: const TextStyle(fontSize: 12),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Freq/Day (Col 13)', isDense: true),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildDropdown('Housing Type (Col 14)', _housingType, Enums.housingTypes, (v) => setState(() => _housingType = v)),
                      _buildDropdown('Floor Wetness (Col 15)', _floorWetness, Enums.floorWetness, (v) => setState(() => _floorWetness = v)),
                      _buildDropdown('Bedding Condition (Col 16)', _beddingCondition, Enums.beddingCondition, (v) => setState(() => _beddingCondition = v)),
                      _buildDropdown('Manure Accumulation (Col 17)', _manureAccumulation, Enums.manureAccumulation, (v) => setState(() => _manureAccumulation = v)),
                      _buildDropdown('Fly Abundance (Col 18)', _flyAbundance, Enums.flyAbundance, (v) => setState(() => _flyAbundance = v)),
                      const Divider(height: 14),
                      _buildYesNoToggle('Water Available 24/7? (Col 19)', _waterAvailable, (v) => setState(() => _waterAvailable = v)),
                      _buildYesNoToggle('Feed Change Recent? (Col 20)', _feedChange, (v) => setState(() => _feedChange = v)),
                      _buildYesNoToggle('Milking Routine Change? (Col 21)', _milkingRoutineChange, (v) => setState(() => _milkingRoutineChange = v)),
                      _buildYesNoToggle('Disease Outbreak in Herd? (Col 22)', _diseaseOutbreak, (v) => setState(() => _diseaseOutbreak = v)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3. MANAGEMENT / HUSBANDRY
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
                      const Text('3. Milking Hygiene & Husbandry (Cols 88-96)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _mainForageCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(labelText: 'Main Forage Type (Col 88)', isDense: true),
                      ),
                      const SizedBox(height: 10),
                      _buildYesNoToggle('Concentrate Offered? (Col 89)', _concentrateOffered, (v) => setState(() => _concentrateOffered = v)),
                      _buildYesNoToggle('Mineral Supplement? (Col 90)', _mineralSupplement, (v) => setState(() => _mineralSupplement = v)),
                      _buildDropdown('Water Source (Col 91)', _waterSource, Enums.waterSources, (v) => setState(() => _waterSource = v)),
                      _buildDropdown('Forestripping Done? (Col 92)', _forestripping, Enums.forestripping, (v) => setState(() => _forestripping = v)),
                      _buildDropdown('Premilking Teat Cleaning (Col 93)', _premilkingTeatCleaning, Enums.premilkingTeatCleaning, (v) => setState(() => _premilkingTeatCleaning = v)),
                      _buildDropdown('Teat Drying Material (Col 94)', _dryingMaterial, Enums.dryingMaterial, (v) => setState(() => _dryingMaterial = v)),
                      _buildDropdown('Milker Gloves Used? (Col 95)', _glovesUsed, Enums.glovesUsed, (v) => setState(() => _glovesUsed = v)),
                      _buildDropdown('Postmilking Disinfection (Col 96)', _postmilkingTeatDisinfection, Enums.postmilkingTeatDisinfection, (v) => setState(() => _postmilkingTeatDisinfection = v)),
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
                  onPressed: _saveForm,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Save Header & Proceed to Cows →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

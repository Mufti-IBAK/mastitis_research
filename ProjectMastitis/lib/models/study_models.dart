import 'dart:math';

class QuarterData {
  String quarter; // LF, RF, LR, RR
  String functionalStatus; // Functional, Blind/nonfunctional, Absent, Unknown
  String? clinicalMastitis; // Yes, No, Unknown
  String? clinicalGrade; // 0 None, 1 Mild, 2 Moderate, 3 Severe, Not assessed
  String? milkAbnormality; // Yes, No, Unknown
  String? swellingHeatPain; // Yes, No, Unknown
  int? teatEndScore; // 1-4
  String? teatLesion; // Yes, No, Unknown
  String? udderFinding;
  String cmtScore; // N, T, 1, 2, 3, Not done
  String? cmtReaderId;
  String? cmtReagentLot;
  String? cmtReagentExpiry;

  // Lab
  String? labSampleId;
  String? labSampleType; // Quarter, Composite cow
  String? labCollectedBeforeTreatment; // Yes, No, Unknown
  int? labSccCellsMl;
  String? labSccResultFlag;
  String? labCultureResultCategory;
  String? labOrganismPrimary;
  String? labIsolateId;
  String? labMixedContaminated;
  String? labAstMethodStandard;
  String? labAstSummary;

  // Missing / notes
  String? missingReason;
  String? protocolDeviation;
  String? notes;

  QuarterData({
    required this.quarter,
    this.functionalStatus = 'Functional',
    this.clinicalMastitis = 'No',
    this.clinicalGrade,
    this.milkAbnormality = 'No',
    this.swellingHeatPain = 'No',
    this.teatEndScore = 1,
    this.teatLesion = 'No',
    this.udderFinding,
    this.cmtScore = 'N',
    this.cmtReaderId,
    this.cmtReagentLot,
    this.cmtReagentExpiry,
    this.labSampleId,
    this.labSampleType,
    this.labCollectedBeforeTreatment,
    this.labSccCellsMl,
    this.labSccResultFlag,
    this.labCultureResultCategory,
    this.labOrganismPrimary,
    this.labIsolateId,
    this.labMixedContaminated,
    this.labAstMethodStandard,
    this.labAstSummary,
    this.missingReason = 'Not missing',
    this.protocolDeviation,
    this.notes,
  });

  String get cmtPositiveDerived {
    if (cmtScore == '1' || cmtScore == '2' || cmtScore == '3') return 'Yes';
    if (cmtScore == 'N' || cmtScore == 'T') return 'No';
    return 'Not assessable';
  }

  double? get scsDerived {
    if (labSccCellsMl == null || labSccCellsMl! <= 0) return null;
    return (log(labSccCellsMl! / 100000.0) / ln2) + 3.0;
  }

  Map<String, dynamic> toJson() => {
        'quarter': quarter,
        'functionalStatus': functionalStatus,
        'clinicalMastitis': clinicalMastitis,
        'clinicalGrade': clinicalGrade,
        'milkAbnormality': milkAbnormality,
        'swellingHeatPain': swellingHeatPain,
        'teatEndScore': teatEndScore,
        'teatLesion': teatLesion,
        'udderFinding': udderFinding,
        'cmtScore': cmtScore,
        'cmtReaderId': cmtReaderId,
        'cmtReagentLot': cmtReagentLot,
        'cmtReagentExpiry': cmtReagentExpiry,
        'labSampleId': labSampleId,
        'labSampleType': labSampleType,
        'labCollectedBeforeTreatment': labCollectedBeforeTreatment,
        'labSccCellsMl': labSccCellsMl,
        'labSccResultFlag': labSccResultFlag,
        'labCultureResultCategory': labCultureResultCategory,
        'labOrganismPrimary': labOrganismPrimary,
        'labIsolateId': labIsolateId,
        'labMixedContaminated': labMixedContaminated,
        'labAstMethodStandard': labAstMethodStandard,
        'labAstSummary': labAstSummary,
        'missingReason': missingReason,
        'protocolDeviation': protocolDeviation,
        'notes': notes,
      };

  factory QuarterData.fromJson(Map<String, dynamic> json) => QuarterData(
        quarter: json['quarter'] ?? 'LF',
        functionalStatus: json['functionalStatus'] ?? 'Functional',
        clinicalMastitis: json['clinicalMastitis'],
        clinicalGrade: json['clinicalGrade'],
        milkAbnormality: json['milkAbnormality'],
        swellingHeatPain: json['swellingHeatPain'],
        teatEndScore: json['teatEndScore'],
        teatLesion: json['teatLesion'],
        udderFinding: json['udderFinding'],
        cmtScore: json['cmtScore'] ?? 'N',
        cmtReaderId: json['cmtReaderId'],
        cmtReagentLot: json['cmtReagentLot'],
        cmtReagentExpiry: json['cmtReagentExpiry'],
        labSampleId: json['labSampleId'],
        labSampleType: json['labSampleType'],
        labCollectedBeforeTreatment: json['labCollectedBeforeTreatment'],
        labSccCellsMl: json['labSccCellsMl'],
        labSccResultFlag: json['labSccResultFlag'],
        labCultureResultCategory: json['labCultureResultCategory'],
        labOrganismPrimary: json['labOrganismPrimary'],
        labIsolateId: json['labIsolateId'],
        labMixedContaminated: json['labMixedContaminated'],
        labAstMethodStandard: json['labAstMethodStandard'],
        labAstSummary: json['labAstSummary'],
        missingReason: json['missingReason'],
        protocolDeviation: json['protocolDeviation'],
        notes: json['notes'],
      );
}

class TreatmentData {
  String? txEventId;
  String txCurrentTreatment; // Yes, No, Unknown
  String? txProductTradeName;
  String? txActiveIngredient;
  double? txDose;
  String? txDoseUnit;
  String? txRoute;
  String? txStartDate;
  String? txStopDate;
  String? txMilkWithdrawalEndDate;
  String? txOutcomeNextVisit;

  TreatmentData({
    this.txEventId,
    this.txCurrentTreatment = 'No',
    this.txProductTradeName,
    this.txActiveIngredient,
    this.txDose,
    this.txDoseUnit,
    this.txRoute,
    this.txStartDate,
    this.txStopDate,
    this.txMilkWithdrawalEndDate,
    this.txOutcomeNextVisit,
  });

  Map<String, dynamic> toJson() => {
        'txEventId': txEventId,
        'txCurrentTreatment': txCurrentTreatment,
        'txProductTradeName': txProductTradeName,
        'txActiveIngredient': txActiveIngredient,
        'txDose': txDose,
        'txDoseUnit': txDoseUnit,
        'txRoute': txRoute,
        'txStartDate': txStartDate,
        'txStopDate': txStopDate,
        'txMilkWithdrawalEndDate': txMilkWithdrawalEndDate,
        'txOutcomeNextVisit': txOutcomeNextVisit,
      };

  factory TreatmentData.fromJson(Map<String, dynamic> json) => TreatmentData(
        txEventId: json['txEventId'],
        txCurrentTreatment: json['txCurrentTreatment'] ?? 'No',
        txProductTradeName: json['txProductTradeName'],
        txActiveIngredient: json['txActiveIngredient'],
        txDose: (json['txDose'] as num?)?.toDouble(),
        txDoseUnit: json['txDoseUnit'],
        txRoute: json['txRoute'],
        txStartDate: json['txStartDate'],
        txStopDate: json['txStopDate'],
        txMilkWithdrawalEndDate: json['txMilkWithdrawalEndDate'],
        txOutcomeNextVisit: json['txOutcomeNextVisit'],
      );
}

class CowRecord {
  String cowId; // Col 23
  String? localTagId; // Col 24
  String? lactationId; // Col 25
  String? breedGeneticGroup; // Col 26
  String? cowBirthDate; // Col 27
  double? cowAgeYears; // Col 28
  String cowSource; // Col 29
  int parity; // Col 30
  String? calvingDate; // Col 31 (YYYY-MM-DD)
  String pregnancyStatus; // Col 33
  String previousClinicalMastitis; // Col 34
  String previousHighSccCmt; // Col 35
  String dryCowTherapyPrevious; // Col 36
  String teatSealantPrevious; // Col 37
  double? cowMilkYieldValue; // Col 38
  String cowMilkYieldUnit; // Col 39 (kg, L)
  String cowYieldPeriod; // Col 40
  int? cowMilkingFrequency; // Col 41
  double cowBcsValue; // Col 42 (1.0 - 5.0)
  String cowBcsScale; // Col 43 ("1-5")
  int cowLocomotionScore; // Col 44 (1 - 5)
  int cowUdderHygieneScore; // Col 45 (1 - 4)
  double? cowRectalTemperatureC; // Col 46
  String? cowConcurrentDiseaseSigns; // Col 47
  String cowAntimicrobialPrevious14d; // Col 48
  String cowMastitisTreatmentSinceLast; // Col 49
  String cowIncompleteMilkingOrSuckling; // Col 50

  Map<String, QuarterData> quarters; // 'LF', 'RF', 'LR', 'RR'
  TreatmentData treatment;

  CowRecord({
    required this.cowId,
    this.localTagId,
    this.lactationId,
    this.breedGeneticGroup,
    this.cowBirthDate,
    this.cowAgeYears,
    this.cowSource = 'Homebred',
    this.parity = 1,
    this.calvingDate,
    this.pregnancyStatus = 'Unknown',
    this.previousClinicalMastitis = 'No',
    this.previousHighSccCmt = 'No',
    this.dryCowTherapyPrevious = 'Unknown',
    this.teatSealantPrevious = 'Unknown',
    this.cowMilkYieldValue,
    this.cowMilkYieldUnit = 'L',
    this.cowYieldPeriod = 'Morning',
    this.cowMilkingFrequency = 2,
    this.cowBcsValue = 3.0,
    this.cowBcsScale = '1-5',
    this.cowLocomotionScore = 1,
    this.cowUdderHygieneScore = 1,
    this.cowRectalTemperatureC,
    this.cowConcurrentDiseaseSigns,
    this.cowAntimicrobialPrevious14d = 'No',
    this.cowMastitisTreatmentSinceLast = 'No',
    this.cowIncompleteMilkingOrSuckling = 'No',
    Map<String, QuarterData>? quarters,
    TreatmentData? treatment,
  })  : quarters = quarters ??
            {
              'LF': QuarterData(quarter: 'LF'),
              'RF': QuarterData(quarter: 'RF'),
              'LR': QuarterData(quarter: 'LR'),
              'RR': QuarterData(quarter: 'RR'),
            },
        treatment = treatment ?? TreatmentData();

  int? computeDim(String? visitDateStr) {
    if (calvingDate == null || visitDateStr == null) return null;
    try {
      final cDate = DateTime.parse(calvingDate!);
      final vDate = DateTime.parse(visitDateStr);
      return vDate.difference(cDate).inDays;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'cowId': cowId,
        'localTagId': localTagId,
        'lactationId': lactationId,
        'breedGeneticGroup': breedGeneticGroup,
        'cowBirthDate': cowBirthDate,
        'cowAgeYears': cowAgeYears,
        'cowSource': cowSource,
        'parity': parity,
        'calvingDate': calvingDate,
        'pregnancyStatus': pregnancyStatus,
        'previousClinicalMastitis': previousClinicalMastitis,
        'previousHighSccCmt': previousHighSccCmt,
        'dryCowTherapyPrevious': dryCowTherapyPrevious,
        'teatSealantPrevious': teatSealantPrevious,
        'cowMilkYieldValue': cowMilkYieldValue,
        'cowMilkYieldUnit': cowMilkYieldUnit,
        'cowYieldPeriod': cowYieldPeriod,
        'cowMilkingFrequency': cowMilkingFrequency,
        'cowBcsValue': cowBcsValue,
        'cowBcsScale': cowBcsScale,
        'cowLocomotionScore': cowLocomotionScore,
        'cowUdderHygieneScore': cowUdderHygieneScore,
        'cowRectalTemperatureC': cowRectalTemperatureC,
        'cowConcurrentDiseaseSigns': cowConcurrentDiseaseSigns,
        'cowAntimicrobialPrevious14d': cowAntimicrobialPrevious14d,
        'cowMastitisTreatmentSinceLast': cowMastitisTreatmentSinceLast,
        'cowIncompleteMilkingOrSuckling': cowIncompleteMilkingOrSuckling,
        'quarters': quarters.map((k, v) => MapEntry(k, v.toJson())),
        'treatment': treatment.toJson(),
      };

  factory CowRecord.fromJson(Map<String, dynamic> json) {
    final qMap = <String, QuarterData>{};
    if (json['quarters'] != null) {
      (json['quarters'] as Map<String, dynamic>).forEach((k, v) {
        qMap[k] = QuarterData.fromJson(v);
      });
    }
    return CowRecord(
      cowId: json['cowId'] ?? '',
      localTagId: json['localTagId'],
      lactationId: json['lactationId'],
      breedGeneticGroup: json['breedGeneticGroup'],
      cowBirthDate: json['cowBirthDate'],
      cowAgeYears: (json['cowAgeYears'] as num?)?.toDouble(),
      cowSource: json['cowSource'] ?? 'Homebred',
      parity: json['parity'] ?? 1,
      calvingDate: json['calvingDate'],
      pregnancyStatus: json['pregnancyStatus'] ?? 'Unknown',
      previousClinicalMastitis: json['previousClinicalMastitis'] ?? 'No',
      previousHighSccCmt: json['previousHighSccCmt'] ?? 'No',
      dryCowTherapyPrevious: json['dryCowTherapyPrevious'] ?? 'Unknown',
      teatSealantPrevious: json['teatSealantPrevious'] ?? 'Unknown',
      cowMilkYieldValue: (json['cowMilkYieldValue'] as num?)?.toDouble(),
      cowMilkYieldUnit: json['cowMilkYieldUnit'] ?? 'L',
      cowYieldPeriod: json['cowYieldPeriod'] ?? 'Morning',
      cowMilkingFrequency: json['cowMilkingFrequency'],
      cowBcsValue: (json['cowBcsValue'] as num?)?.toDouble() ?? 3.0,
      cowBcsScale: json['cowBcsScale'] ?? '1-5',
      cowLocomotionScore: json['cowLocomotionScore'] ?? 1,
      cowUdderHygieneScore: json['cowUdderHygieneScore'] ?? 1,
      cowRectalTemperatureC: (json['cowRectalTemperatureC'] as num?)?.toDouble(),
      cowConcurrentDiseaseSigns: json['cowConcurrentDiseaseSigns'],
      cowAntimicrobialPrevious14d: json['cowAntimicrobialPrevious14d'] ?? 'No',
      cowMastitisTreatmentSinceLast: json['cowMastitisTreatmentSinceLast'] ?? 'No',
      cowIncompleteMilkingOrSuckling: json['cowIncompleteMilkingOrSuckling'] ?? 'No',
      quarters: qMap.isNotEmpty ? qMap : null,
      treatment: json['treatment'] != null ? TreatmentData.fromJson(json['treatment']) : null,
    );
  }
}

class VisitRecord {
  String id;
  String farmId;
  String visitId;
  String visitDate; // YYYY-MM-DD
  String? scheduledVisitDate;
  String observerId;

  // Farm Location
  String state;
  String lga;

  // Farm Conditions (cols 9-22)
  String farmProductionSystem;
  int? farmTotalCattle;
  int? farmLactatingCows;
  String farmMilkingMethod;
  int farmMilkingFrequencyDay;
  String farmHousingType;
  String farmFloorWetness;
  String farmBeddingCondition;
  String farmManureAccumulation;
  String farmFlyAbundance;
  String farmWaterAvailable;
  String farmFeedChange;
  String farmMilkingRoutineChange;
  String farmDiseaseOutbreak;

  // Farm Management / Husbandry (cols 88-96)
  String? farmMainForage;
  String farmConcentrateOffered;
  String farmMineralSupplement;
  String farmWaterSource;
  String farmForestripping;
  String farmPremilkingTeatCleaning;
  String farmDryingMaterial;
  String farmGlovesUsed;
  String farmPostmilkingTeatDisinfection;

  List<CowRecord> cows;
  bool isSynced;
  DateTime updatedAt;

  VisitRecord({
    required this.id,
    required this.farmId,
    required this.visitId,
    required this.visitDate,
    this.scheduledVisitDate,
    required this.observerId,
    this.state = 'Sokoto',
    this.lga = '',
    this.farmProductionSystem = 'Semi-intensive',
    this.farmTotalCattle,
    this.farmLactatingCows,
    this.farmMilkingMethod = 'Hand',
    this.farmMilkingFrequencyDay = 2,
    this.farmHousingType = 'Open yard',
    this.farmFloorWetness = 'Dry',
    this.farmBeddingCondition = 'Dry',
    this.farmManureAccumulation = 'Low',
    this.farmFlyAbundance = 'Low',
    this.farmWaterAvailable = 'Yes',
    this.farmFeedChange = 'No',
    this.farmMilkingRoutineChange = 'No',
    this.farmDiseaseOutbreak = 'No',
    this.farmMainForage = 'Hay / Crop residue',
    this.farmConcentrateOffered = 'Yes',
    this.farmMineralSupplement = 'Yes',
    this.farmWaterSource = 'Borehole',
    this.farmForestripping = 'Always',
    this.farmPremilkingTeatCleaning = 'Water only',
    this.farmDryingMaterial = 'Individual towel',
    this.farmGlovesUsed = 'Sometimes',
    this.farmPostmilkingTeatDisinfection = 'Never',
    List<CowRecord>? cows,
    this.isSynced = false,
    DateTime? updatedAt,
  })  : cows = cows ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  /// Converts this Visit into the exact 99-column rows expected by UDDER_HEALTH_DATA.
  /// Generates exactly 4 rows per cow (LF, RF, LR, RR).
  List<Map<String, dynamic>> toSingleSheetRows() {
    final rows = <Map<String, dynamic>>[];

    for (final cow in cows) {
      final dim = cow.computeDim(visitDate);

      for (final qKey in ['LF', 'RF', 'LR', 'RR']) {
        final q = cow.quarters[qKey] ?? QuarterData(quarter: qKey);
        final tx = cow.treatment;

        // Record key derivation: Visit_ID | Cow_ID | Quarter
        final recordKey = '$visitId|${cow.cowId}|$qKey';

        final row = <String, dynamic>{
          // Col 1-8: Identifiers and Visit
          'record_key_derived': recordKey,
          'state': state,
          'lga': lga,
          'farm_id': farmId,
          'visit_id': visitId,
          'visit_date': visitDate,
          'scheduled_visit_date': scheduledVisitDate ?? visitDate,
          'observer_id': observerId,

          // Col 9-22: Farm Conditions
          'farm_production_system': farmProductionSystem,
          'farm_total_cattle': farmTotalCattle,
          'farm_lactating_cows': farmLactatingCows,
          'farm_milking_method': farmMilkingMethod,
          'farm_milking_frequency_day': farmMilkingFrequencyDay,
          'farm_housing_type': farmHousingType,
          'farm_floor_wetness': farmFloorWetness,
          'farm_bedding_condition': farmBeddingCondition,
          'farm_manure_accumulation': farmManureAccumulation,
          'farm_fly_abundance': farmFlyAbundance,
          'farm_water_available': farmWaterAvailable,
          'farm_feed_change': farmFeedChange,
          'farm_milking_routine_change': farmMilkingRoutineChange,
          'farm_disease_outbreak': farmDiseaseOutbreak,

          // Col 23-37: Cow & Lactation
          'cow_id': cow.cowId,
          'local_tag_id': cow.localTagId,
          'lactation_id': cow.lactationId ?? 'L1',
          'breed_genetic_group': cow.breedGeneticGroup,
          'cow_birth_date': cow.cowBirthDate,
          'cow_age_years': cow.cowAgeYears,
          'cow_source': cow.cowSource,
          'parity': cow.parity,
          'calving_date': cow.calvingDate,
          'dim_derived': dim,
          'pregnancy_status': cow.pregnancyStatus,
          'previous_clinical_mastitis': cow.previousClinicalMastitis,
          'previous_high_scc_cmt': cow.previousHighSccCmt,
          'dry_cow_therapy_previous': cow.dryCowTherapyPrevious,
          'teat_sealant_previous': cow.teatSealantPrevious,

          // Col 38-50: Time-Varying Cow Measurements
          'cow_milk_yield_value': cow.cowMilkYieldValue,
          'cow_milk_yield_unit': cow.cowMilkYieldUnit,
          'cow_yield_period': cow.cowYieldPeriod,
          'cow_milking_frequency': cow.cowMilkingFrequency,
          'cow_bcs_value': cow.cowBcsValue,
          'cow_bcs_scale': cow.cowBcsScale,
          'cow_locomotion_score': cow.cowLocomotionScore,
          'cow_udder_hygiene_score': cow.cowUdderHygieneScore,
          'cow_rectal_temperature_c': cow.cowRectalTemperatureC,
          'cow_concurrent_disease_signs': cow.cowConcurrentDiseaseSigns,
          'cow_antimicrobial_previous_14d': cow.cowAntimicrobialPrevious14d,
          'cow_mastitis_treatment_since_last': cow.cowMastitisTreatmentSinceLast,
          'cow_incomplete_milking_or_suckling': cow.cowIncompleteMilkingOrSuckling,

          // Col 51-64: Quarter Examination & CMT
          'quarter': q.quarter,
          'quarter_functional_status': q.functionalStatus,
          'quarter_clinical_mastitis': q.clinicalMastitis,
          'quarter_clinical_grade': q.clinicalGrade,
          'quarter_milk_abnormality': q.milkAbnormality,
          'quarter_swelling_heat_pain': q.swellingHeatPain,
          'quarter_teat_end_score': q.teatEndScore,
          'quarter_teat_lesion': q.teatLesion,
          'quarter_udder_finding': q.udderFinding,
          'cmt_score': q.cmtScore,
          'cmt_positive_derived': q.cmtPositiveDerived,
          'cmt_reader_id': q.cmtReaderId ?? observerId,
          'cmt_reagent_lot': q.cmtReagentLot,
          'cmt_reagent_expiry': q.cmtReagentExpiry,

          // Col 65-76: Laboratory (if composite, usually recorded on LF)
          'lab_sample_id': q.labSampleId,
          'lab_sample_type': q.labSampleType,
          'lab_collected_before_treatment': q.labCollectedBeforeTreatment,
          'lab_scc_cells_ml': q.labSccCellsMl,
          'lab_scc_result_flag': q.labSccResultFlag,
          'scs_derived': q.scsDerived,
          'lab_culture_result_category': q.labCultureResultCategory,
          'lab_organism_primary': q.labOrganismPrimary,
          'lab_isolate_id': q.labIsolateId,
          'lab_mixed_contaminated': q.labMixedContaminated,
          'lab_ast_method_standard': q.labAstMethodStandard,
          'lab_ast_summary': q.labAstSummary,

          // Col 77-87: Treatment
          'tx_event_id': tx.txEventId,
          'tx_current_treatment': tx.txCurrentTreatment,
          'tx_product_trade_name': tx.txProductTradeName,
          'tx_active_ingredient': tx.txActiveIngredient,
          'tx_dose': tx.txDose,
          'tx_dose_unit': tx.txDoseUnit,
          'tx_route': tx.txRoute,
          'tx_start_date': tx.txStartDate,
          'tx_stop_date': tx.txStopDate,
          'tx_milk_withdrawal_end_date': tx.txMilkWithdrawalEndDate,
          'tx_outcome_next_visit': tx.txOutcomeNextVisit,

          // Col 88-96: Farm Management/Husbandry
          'farm_main_forage': farmMainForage,
          'farm_concentrate_offered': farmConcentrateOffered,
          'farm_mineral_supplement': farmMineralSupplement,
          'farm_water_source': farmWaterSource,
          'farm_forestripping': farmForestripping,
          'farm_premilking_teat_cleaning': farmPremilkingTeatCleaning,
          'farm_drying_material': farmDryingMaterial,
          'farm_gloves_used': farmGlovesUsed,
          'farm_postmilking_teat_disinfection': farmPostmilkingTeatDisinfection,

          // Col 97-99: Documentation
          'missing_reason': q.missingReason,
          'protocol_deviation': q.protocolDeviation,
          'notes': q.notes,
        };

        rows.add(row);
      }
    }

    return rows;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmId': farmId,
        'visitId': visitId,
        'visitDate': visitDate,
        'scheduledVisitDate': scheduledVisitDate,
        'observerId': observerId,
        'state': state,
        'lga': lga,
        'farmProductionSystem': farmProductionSystem,
        'farmTotalCattle': farmTotalCattle,
        'farmLactatingCows': farmLactatingCows,
        'farmMilkingMethod': farmMilkingMethod,
        'farmMilkingFrequencyDay': farmMilkingFrequencyDay,
        'farmHousingType': farmHousingType,
        'farmFloorWetness': farmFloorWetness,
        'farmBeddingCondition': farmBeddingCondition,
        'farmManureAccumulation': farmManureAccumulation,
        'farmFlyAbundance': farmFlyAbundance,
        'farmWaterAvailable': farmWaterAvailable,
        'farmFeedChange': farmFeedChange,
        'farmMilkingRoutineChange': farmMilkingRoutineChange,
        'farmDiseaseOutbreak': farmDiseaseOutbreak,
        'farmMainForage': farmMainForage,
        'farmConcentrateOffered': farmConcentrateOffered,
        'farmMineralSupplement': farmMineralSupplement,
        'farmWaterSource': farmWaterSource,
        'farmForestripping': farmForestripping,
        'farmPremilkingTeatCleaning': farmPremilkingTeatCleaning,
        'farmDryingMaterial': farmDryingMaterial,
        'farmGlovesUsed': farmGlovesUsed,
        'farmPostmilkingTeatDisinfection': farmPostmilkingTeatDisinfection,
        'cows': cows.map((c) => c.toJson()).toList(),
        'isSynced': isSynced,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VisitRecord.fromJson(Map<String, dynamic> json) => VisitRecord(
        id: json['id'] ?? '',
        farmId: json['farmId'] ?? '',
        visitId: json['visitId'] ?? '',
        visitDate: json['visitDate'] ?? '',
        scheduledVisitDate: json['scheduledVisitDate'],
        observerId: json['observerId'] ?? '',
        state: json['state'] ?? 'Sokoto',
        lga: json['lga'] ?? '',
        farmProductionSystem: json['farmProductionSystem'] ?? 'Semi-intensive',
        farmTotalCattle: json['farmTotalCattle'],
        farmLactatingCows: json['farmLactatingCows'],
        farmMilkingMethod: json['farmMilkingMethod'] ?? 'Hand',
        farmMilkingFrequencyDay: json['farmMilkingFrequencyDay'] ?? 2,
        farmHousingType: json['farmHousingType'] ?? 'Open yard',
        farmFloorWetness: json['farmFloorWetness'] ?? 'Dry',
        farmBeddingCondition: json['farmBeddingCondition'] ?? 'Dry',
        farmManureAccumulation: json['farmManureAccumulation'] ?? 'Low',
        farmFlyAbundance: json['farmFlyAbundance'] ?? 'Low',
        farmWaterAvailable: json['farmWaterAvailable'] ?? 'Yes',
        farmFeedChange: json['farmFeedChange'] ?? 'No',
        farmMilkingRoutineChange: json['farmMilkingRoutineChange'] ?? 'No',
        farmDiseaseOutbreak: json['farmDiseaseOutbreak'] ?? 'No',
        farmMainForage: json['farmMainForage'],
        farmConcentrateOffered: json['farmConcentrateOffered'] ?? 'Yes',
        farmMineralSupplement: json['farmMineralSupplement'] ?? 'Yes',
        farmWaterSource: json['farmWaterSource'] ?? 'Borehole',
        farmForestripping: json['farmForestripping'] ?? 'Always',
        farmPremilkingTeatCleaning: json['farmPremilkingTeatCleaning'] ?? 'Water only',
        farmDryingMaterial: json['farmDryingMaterial'] ?? 'Individual towel',
        farmGlovesUsed: json['farmGlovesUsed'] ?? 'Sometimes',
        farmPostmilkingTeatDisinfection: json['farmPostmilkingTeatDisinfection'] ?? 'Never',
        cows: json['cows'] != null
            ? (json['cows'] as List<dynamic>).map((c) => CowRecord.fromJson(c)).toList()
            : [],
        isSynced: json['isSynced'] ?? false,
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      );
}

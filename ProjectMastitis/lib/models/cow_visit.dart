class CowVisit {
  final String id;
  final String farmVisitId;
  final String cowId;
  final String? localTagId;
  final String? lactationId;
  final String? breedGeneticGroup;
  final DateTime? cowBirthDate;
  final double? cowAgeYears;
  final String? cowSource;
  final int? parity;
  final DateTime? calvingDate;

  // Pregnancy/history
  final String? pregnancyStatus;
  final String? previousClinicalMastitis;
  final String? previousHighSccCmt;
  final String? dryCowTherapyPrevious;
  final String? teatSealantPrevious;

  // Time-varying
  final double? milkYieldValue;
  final String? milkYieldUnit;
  final String? yieldPeriod;
  final int? milkingFrequency;
  final double? bcsValue;
  final String? bcsScale;
  final String? locomotionScore;
  final String? udderHygieneScore;
  final double? rectalTemperatureC;
  final String? concurrentDiseaseSigns;
  final String? antimicrobialPrevious14d;
  final String? mastitisTreatmentSinceLast;
  final String? incompleteMilkingOrSuckling;

  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CowVisit({
    required this.id,
    required this.farmVisitId,
    required this.cowId,
    this.localTagId,
    this.lactationId,
    this.breedGeneticGroup,
    this.cowBirthDate,
    this.cowAgeYears,
    this.cowSource,
    this.parity,
    this.calvingDate,
    this.pregnancyStatus,
    this.previousClinicalMastitis,
    this.previousHighSccCmt,
    this.dryCowTherapyPrevious,
    this.teatSealantPrevious,
    this.milkYieldValue,
    this.milkYieldUnit,
    this.yieldPeriod,
    this.milkingFrequency,
    this.bcsValue,
    this.bcsScale,
    this.locomotionScore,
    this.udderHygieneScore,
    this.rectalTemperatureC,
    this.concurrentDiseaseSigns,
    this.antimicrobialPrevious14d,
    this.mastitisTreatmentSinceLast,
    this.incompleteMilkingOrSuckling,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  int? get dim {
    if (calvingDate == null || createdAt == null) return null;
    return createdAt!.difference(calvingDate!).inDays;
  }

  factory CowVisit.fromJson(Map<String, dynamic> json) {
    return CowVisit(
      id: json['id'] as String,
      farmVisitId: json['farm_visit_id'] as String,
      cowId: json['cow_id'] as String,
      localTagId: json['local_tag_id'] as String?,
      lactationId: json['lactation_id'] as String?,
      breedGeneticGroup: json['breed_genetic_group'] as String?,
      cowBirthDate: json['cow_birth_date'] != null ? DateTime.parse(json['cow_birth_date'] as String) : null,
      cowAgeYears: (json['cow_age_years'] as num?)?.toDouble(),
      cowSource: json['cow_source'] as String?,
      parity: json['parity'] as int?,
      calvingDate: json['calving_date'] != null ? DateTime.parse(json['calving_date'] as String) : null,
      pregnancyStatus: json['pregnancy_status'] as String?,
      previousClinicalMastitis: json['previous_clinical_mastitis'] as String?,
      previousHighSccCmt: json['previous_high_scc_cmt'] as String?,
      dryCowTherapyPrevious: json['dry_cow_therapy_previous'] as String?,
      teatSealantPrevious: json['teat_sealant_previous'] as String?,
      milkYieldValue: (json['milk_yield_value'] as num?)?.toDouble(),
      milkYieldUnit: json['milk_yield_unit'] as String?,
      yieldPeriod: json['yield_period'] as String?,
      milkingFrequency: json['milking_frequency'] as int?,
      bcsValue: (json['bcs_value'] as num?)?.toDouble(),
      bcsScale: json['bcs_scale'] as String?,
      locomotionScore: json['locomotion_score'] as String?,
      udderHygieneScore: json['udder_hygiene_score'] as String?,
      rectalTemperatureC: (json['rectal_temperature_c'] as num?)?.toDouble(),
      concurrentDiseaseSigns: json['concurrent_disease_signs'] as String?,
      antimicrobialPrevious14d: json['antimicrobial_previous_14d'] as String?,
      mastitisTreatmentSinceLast: json['mastitis_treatment_since_last'] as String?,
      incompleteMilkingOrSuckling: json['incomplete_milking_or_suckling'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'farm_visit_id': farmVisitId,
      'cow_id': cowId,
      'local_tag_id': localTagId,
      'lactation_id': lactationId,
      'breed_genetic_group': breedGeneticGroup,
      'cow_birth_date': cowBirthDate?.toIso8601String(),
      'cow_age_years': cowAgeYears,
      'cow_source': cowSource,
      'parity': parity,
      'calving_date': calvingDate?.toIso8601String(),
      'pregnancy_status': pregnancyStatus,
      'previous_clinical_mastitis': previousClinicalMastitis,
      'previous_high_scc_cmt': previousHighSccCmt,
      'dry_cow_therapy_previous': dryCowTherapyPrevious,
      'teat_sealant_previous': teatSealantPrevious,
      'milk_yield_value': milkYieldValue,
      'milk_yield_unit': milkYieldUnit,
      'yield_period': yieldPeriod,
      'milking_frequency': milkingFrequency,
      'bcs_value': bcsValue,
      'bcs_scale': bcsScale,
      'locomotion_score': locomotionScore,
      'udder_hygiene_score': udderHygieneScore,
      'rectal_temperature_c': rectalTemperatureC,
      'concurrent_disease_signs': concurrentDiseaseSigns,
      'antimicrobial_previous_14d': antimicrobialPrevious14d,
      'mastitis_treatment_since_last': mastitisTreatmentSinceLast,
      'incomplete_milking_or_suckling': incompleteMilkingOrSuckling,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class FarmVisit {
  final String id;
  final String farmId;
  final String visitId;
  final DateTime? visitDate;
  final DateTime? scheduledVisitDate;
  final String? observerId;

  // Farm conditions
  final String? productionSystem;
  final int? totalCattle;
  final int? lactatingCows;
  final String? milkingMethod;
  final int? milkingFrequencyDay;
  final String? housingType;
  final String? floorWetness;
  final String? beddingCondition;
  final String? manureAccumulation;
  final String? flyAbundance;
  final String? waterAvailable;
  final String? feedChange;
  final String? milkingRoutineChange;
  final String? diseaseOutbreak;

  // Management/husbandry
  final String? mainForage;
  final String? concentrateOffered;
  final String? mineralSupplement;
  final String? waterSource;
  final String? forestripping;
  final String? premilkingTeatCleaning;
  final String? dryingMaterial;
  final String? glovesUsed;
  final String? postmilkingTeatDisinfection;

  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FarmVisit({
    required this.id,
    required this.farmId,
    required this.visitId,
    this.visitDate,
    this.scheduledVisitDate,
    this.observerId,
    this.productionSystem,
    this.totalCattle,
    this.lactatingCows,
    this.milkingMethod,
    this.milkingFrequencyDay,
    this.housingType,
    this.floorWetness,
    this.beddingCondition,
    this.manureAccumulation,
    this.flyAbundance,
    this.waterAvailable,
    this.feedChange,
    this.milkingRoutineChange,
    this.diseaseOutbreak,
    this.mainForage,
    this.concentrateOffered,
    this.mineralSupplement,
    this.waterSource,
    this.forestripping,
    this.premilkingTeatCleaning,
    this.dryingMaterial,
    this.glovesUsed,
    this.postmilkingTeatDisinfection,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory FarmVisit.fromJson(Map<String, dynamic> json) {
    return FarmVisit(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      visitId: json['visit_id'] as String,
      visitDate: json['visit_date'] != null ? DateTime.parse(json['visit_date'] as String) : null,
      scheduledVisitDate: json['scheduled_visit_date'] != null ? DateTime.parse(json['scheduled_visit_date'] as String) : null,
      observerId: json['observer_id'] as String?,
      productionSystem: json['production_system'] as String?,
      totalCattle: json['total_cattle'] as int?,
      lactatingCows: json['lactating_cows'] as int?,
      milkingMethod: json['milking_method'] as String?,
      milkingFrequencyDay: json['milking_frequency_day'] as int?,
      housingType: json['housing_type'] as String?,
      floorWetness: json['floor_wetness'] as String?,
      beddingCondition: json['bedding_condition'] as String?,
      manureAccumulation: json['manure_accumulation'] as String?,
      flyAbundance: json['fly_abundance'] as String?,
      waterAvailable: json['water_available'] as String?,
      feedChange: json['feed_change'] as String?,
      milkingRoutineChange: json['milking_routine_change'] as String?,
      diseaseOutbreak: json['disease_outbreak'] as String?,
      mainForage: json['main_forage'] as String?,
      concentrateOffered: json['concentrate_offered'] as String?,
      mineralSupplement: json['mineral_supplement'] as String?,
      waterSource: json['water_source'] as String?,
      forestripping: json['forestripping'] as String?,
      premilkingTeatCleaning: json['premilking_teat_cleaning'] as String?,
      dryingMaterial: json['drying_material'] as String?,
      glovesUsed: json['gloves_used'] as String?,
      postmilkingTeatDisinfection: json['postmilking_teat_disinfection'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'farm_id': farmId,
      'visit_id': visitId,
      'visit_date': visitDate?.toIso8601String(),
      'scheduled_visit_date': scheduledVisitDate?.toIso8601String(),
      'observer_id': observerId,
      'production_system': productionSystem,
      'total_cattle': totalCattle,
      'lactating_cows': lactatingCows,
      'milking_method': milkingMethod,
      'milking_frequency_day': milkingFrequencyDay,
      'housing_type': housingType,
      'floor_wetness': floorWetness,
      'bedding_condition': beddingCondition,
      'manure_accumulation': manureAccumulation,
      'fly_abundance': flyAbundance,
      'water_available': waterAvailable,
      'feed_change': feedChange,
      'milking_routine_change': milkingRoutineChange,
      'disease_outbreak': diseaseOutbreak,
      'main_forage': mainForage,
      'concentrate_offered': concentrateOffered,
      'mineral_supplement': mineralSupplement,
      'water_source': waterSource,
      'forestripping': forestripping,
      'premilking_teat_cleaning': premilkingTeatCleaning,
      'drying_material': dryingMaterial,
      'gloves_used': glovesUsed,
      'postmilking_teat_disinfection': postmilkingTeatDisinfection,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

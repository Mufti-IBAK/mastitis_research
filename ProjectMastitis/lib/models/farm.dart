class Farm {
  final String id;
  final String farmId; // External facing ID
  final String? state;
  final String? lga;
  final String? productionSystem;
  final String? housingType;
  final String? waterSource;

  Farm({
    required this.id,
    required this.farmId,
    this.state,
    this.lga,
    this.productionSystem,
    this.housingType,
    this.waterSource,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      state: json['state'] as String?,
      lga: json['lga'] as String?,
      productionSystem: json['production_system'] as String?,
      housingType: json['housing_type'] as String?,
      waterSource: json['water_source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'farm_id': farmId,
      'state': state,
      'lga': lga,
      'production_system': productionSystem,
      'housing_type': housingType,
      'water_source': waterSource,
    };
  }
}

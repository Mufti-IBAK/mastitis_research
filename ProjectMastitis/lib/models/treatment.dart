class Treatment {
  final String id;
  final String cowVisitId;
  final String? txEventId;
  final String? txCurrentTreatment;
  final String? txProductTradeName;
  final String? txActiveIngredient;
  final double? txDose;
  final String? txDoseUnit;
  final String? txRoute;
  final DateTime? txStartDate;
  final DateTime? txStopDate;
  final DateTime? txMilkWithdrawalEndDate;
  final String? txOutcomeNextVisit;
  final List<String>? quarters;

  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Treatment({
    required this.id,
    required this.cowVisitId,
    this.txEventId,
    this.txCurrentTreatment,
    this.txProductTradeName,
    this.txActiveIngredient,
    this.txDose,
    this.txDoseUnit,
    this.txRoute,
    this.txStartDate,
    this.txStopDate,
    this.txMilkWithdrawalEndDate,
    this.txOutcomeNextVisit,
    this.quarters,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
      id: json['id'] as String,
      cowVisitId: json['cow_visit_id'] as String,
      txEventId: json['tx_event_id'] as String?,
      txCurrentTreatment: json['tx_current_treatment'] as String?,
      txProductTradeName: json['tx_product_trade_name'] as String?,
      txActiveIngredient: json['tx_active_ingredient'] as String?,
      txDose: (json['tx_dose'] as num?)?.toDouble(),
      txDoseUnit: json['tx_dose_unit'] as String?,
      txRoute: json['tx_route'] as String?,
      txStartDate: json['tx_start_date'] != null ? DateTime.parse(json['tx_start_date'] as String) : null,
      txStopDate: json['tx_stop_date'] != null ? DateTime.parse(json['tx_stop_date'] as String) : null,
      txMilkWithdrawalEndDate: json['tx_milk_withdrawal_end_date'] != null ? DateTime.parse(json['tx_milk_withdrawal_end_date'] as String) : null,
      txOutcomeNextVisit: json['tx_outcome_next_visit'] as String?,
      quarters: (json['quarters'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'cow_visit_id': cowVisitId,
      'tx_event_id': txEventId,
      'tx_current_treatment': txCurrentTreatment,
      'tx_product_trade_name': txProductTradeName,
      'tx_active_ingredient': txActiveIngredient,
      'tx_dose': txDose,
      'tx_dose_unit': txDoseUnit,
      'tx_route': txRoute,
      'tx_start_date': txStartDate?.toIso8601String(),
      'tx_stop_date': txStopDate?.toIso8601String(),
      'tx_milk_withdrawal_end_date': txMilkWithdrawalEndDate?.toIso8601String(),
      'tx_outcome_next_visit': txOutcomeNextVisit,
      'quarters': quarters,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

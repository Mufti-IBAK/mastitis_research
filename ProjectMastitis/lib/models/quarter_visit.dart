class QuarterVisit {
  final String id;
  final String cowVisitId;
  final String quarter; // LF/RF/LR/RR

  final String? functionalStatus;
  final String? clinicalMastitis;
  final String? clinicalGrade;
  final String? milkAbnormality;
  final String? swellingHeatPain;
  final String? teatEndScore;
  final String? teatLesion;
  final String? udderFinding;

  final String? cmtScore;
  final String? cmtReaderId;
  final String? cmtReagentLot;
  final DateTime? cmtReagentExpiry;

  final String? missingReason;
  final String? protocolDeviation;
  final String? notes;

  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  QuarterVisit({
    required this.id,
    required this.cowVisitId,
    required this.quarter,
    this.functionalStatus,
    this.clinicalMastitis,
    this.clinicalGrade,
    this.milkAbnormality,
    this.swellingHeatPain,
    this.teatEndScore,
    this.teatLesion,
    this.udderFinding,
    this.cmtScore,
    this.cmtReaderId,
    this.cmtReagentLot,
    this.cmtReagentExpiry,
    this.missingReason,
    this.protocolDeviation,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  bool get cmtPositive {
    if (cmtScore == null) return false;
    return cmtScore == '1' || cmtScore == '2' || cmtScore == '3';
  }

  factory QuarterVisit.fromJson(Map<String, dynamic> json) {
    return QuarterVisit(
      id: json['id'] as String,
      cowVisitId: json['cow_visit_id'] as String,
      quarter: json['quarter'] as String,
      functionalStatus: json['functional_status'] as String?,
      clinicalMastitis: json['clinical_mastitis'] as String?,
      clinicalGrade: json['clinical_grade'] as String?,
      milkAbnormality: json['milk_abnormality'] as String?,
      swellingHeatPain: json['swelling_heat_pain'] as String?,
      teatEndScore: json['teat_end_score'] as String?,
      teatLesion: json['teat_lesion'] as String?,
      udderFinding: json['udder_finding'] as String?,
      cmtScore: json['cmt_score'] as String?,
      cmtReaderId: json['cmt_reader_id'] as String?,
      cmtReagentLot: json['cmt_reagent_lot'] as String?,
      cmtReagentExpiry: json['cmt_reagent_expiry'] != null ? DateTime.parse(json['cmt_reagent_expiry'] as String) : null,
      missingReason: json['missing_reason'] as String?,
      protocolDeviation: json['protocol_deviation'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'cow_visit_id': cowVisitId,
      'quarter': quarter,
      'functional_status': functionalStatus,
      'clinical_mastitis': clinicalMastitis,
      'clinical_grade': clinicalGrade,
      'milk_abnormality': milkAbnormality,
      'swelling_heat_pain': swellingHeatPain,
      'teat_end_score': teatEndScore,
      'teat_lesion': teatLesion,
      'udder_finding': udderFinding,
      'cmt_score': cmtScore,
      'cmt_reader_id': cmtReaderId,
      'cmt_reagent_lot': cmtReagentLot,
      'cmt_reagent_expiry': cmtReagentExpiry?.toIso8601String(),
      'missing_reason': missingReason,
      'protocol_deviation': protocolDeviation,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

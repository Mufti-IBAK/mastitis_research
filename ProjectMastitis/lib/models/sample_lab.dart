import 'dart:math';

class SampleLab {
  final String id;
  final String quarterVisitId;
  final String? labSampleId;
  final String? labSampleType;
  final String? labCollectedBeforeTreatment;
  
  final int? labSccCellsMl;
  final String? labSccResultFlag;
  final String? labCultureResultCategory;
  final String? labOrganismPrimary;
  final String? labIsolateId;
  final String? labMixedContaminated;
  final String? labAstMethodStandard;
  final String? labAstSummary;

  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SampleLab({
    required this.id,
    required this.quarterVisitId,
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
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  double? get scs {
    if (labSccCellsMl == null || labSccCellsMl! <= 0) return null;
    return log(labSccCellsMl! / 100000) / ln2 + 3;
  }

  factory SampleLab.fromJson(Map<String, dynamic> json) {
    return SampleLab(
      id: json['id'] as String,
      quarterVisitId: json['quarter_visit_id'] as String,
      labSampleId: json['lab_sample_id'] as String?,
      labSampleType: json['lab_sample_type'] as String?,
      labCollectedBeforeTreatment: json['lab_collected_before_treatment'] as String?,
      labSccCellsMl: json['lab_scc_cells_ml'] as int?,
      labSccResultFlag: json['lab_scc_result_flag'] as String?,
      labCultureResultCategory: json['lab_culture_result_category'] as String?,
      labOrganismPrimary: json['lab_organism_primary'] as String?,
      labIsolateId: json['lab_isolate_id'] as String?,
      labMixedContaminated: json['lab_mixed_contaminated'] as String?,
      labAstMethodStandard: json['lab_ast_method_standard'] as String?,
      labAstSummary: json['lab_ast_summary'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'quarter_visit_id': quarterVisitId,
      'lab_sample_id': labSampleId,
      'lab_sample_type': labSampleType,
      'lab_collected_before_treatment': labCollectedBeforeTreatment,
      'lab_scc_cells_ml': labSccCellsMl,
      'lab_scc_result_flag': labSccResultFlag,
      'lab_culture_result_category': labCultureResultCategory,
      'lab_organism_primary': labOrganismPrimary,
      'lab_isolate_id': labIsolateId,
      'lab_mixed_contaminated': labMixedContaminated,
      'lab_ast_method_standard': labAstMethodStandard,
      'lab_ast_summary': labAstSummary,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

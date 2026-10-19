import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/study_models.dart';

class ExportPrintService {
  static final ExportPrintService instance = ExportPrintService._internal();
  factory ExportPrintService() => instance;
  ExportPrintService._internal();

  /// 99 exact columns list matching Excel schema
  static const List<String> excelHeaders = [
    'Record_Key_DERIVED', 'State', 'LGA', 'Farm_ID', 'Visit_ID', 'Visit_Date', 'Scheduled_Visit_Date', 'Observer_ID',
    'Farm_Production_System', 'Farm_Total_Cattle', 'Farm_Lactating_Cows', 'Farm_Milking_Method', 'Farm_Milking_Frequency_Day',
    'Farm_Housing_Type', 'Farm_Floor_Wetness', 'Farm_Bedding_Condition', 'Farm_Manure_Accumulation', 'Farm_Fly_Abundance',
    'Farm_Water_Available', 'Farm_Feed_Change', 'Farm_Milking_Routine_Change', 'Farm_Disease_Outbreak',
    'Cow_ID', 'Local_Tag_ID', 'Lactation_ID', 'Breed_Genetic_Group', 'Cow_Birth_Date', 'Cow_Age_Years', 'Cow_Source',
    'Parity', 'Calving_Date', 'DIM_DERIVED', 'Pregnancy_Status', 'Previous_Clinical_Mastitis', 'Previous_High_SCC_CMT',
    'Dry_Cow_Therapy_Previous', 'Teat_Sealant_Previous',
    'Cow_Milk_Yield_Value', 'Cow_Milk_Yield_Unit', 'Cow_Yield_Period', 'Cow_Milking_Frequency', 'Cow_BCS_Value',
    'Cow_BCS_Scale', 'Cow_Locomotion_Score', 'Cow_Udder_Hygiene_Score', 'Cow_Rectal_Temperature_C', 'Cow_Concurrent_Disease_Signs',
    'Cow_Antimicrobial_Previous_14d', 'Cow_Mastitis_Treatment_Since_Last', 'Cow_Incomplete_Milking_or_Suckling',
    'Quarter', 'Quarter_Functional_Status', 'Quarter_Clinical_Mastitis', 'Quarter_Clinical_Grade', 'Quarter_Milk_Abnormality',
    'Quarter_Swelling_Heat_Pain', 'Quarter_Teat_End_Score', 'Quarter_Teat_Lesion', 'Quarter_Udder_Finding',
    'CMT_Score', 'CMT_Positive_DERIVED', 'CMT_Reader_ID', 'CMT_Reagent_Lot', 'CMT_Reagent_Expiry',
    'Lab_Sample_ID', 'Lab_Sample_Type', 'Lab_Collected_Before_Treatment', 'Lab_SCC_cells_mL', 'Lab_SCC_Result_Flag',
    'SCS_DERIVED', 'Lab_Culture_Result_Category', 'Lab_Organism_Primary', 'Lab_Isolate_ID', 'Lab_Mixed_Contaminated',
    'Lab_AST_Method_Standard', 'Lab_AST_Summary',
    'Tx_Event_ID', 'Tx_Current_Treatment', 'Tx_Product_Trade_Name', 'Tx_Active_Ingredient', 'Tx_Dose', 'Tx_Dose_Unit',
    'Tx_Route', 'Tx_Start_Date', 'Tx_Stop_Date', 'Tx_Milk_Withdrawal_End_Date', 'Tx_Outcome_Next_Visit',
    'Farm_Main_Forage', 'Farm_Concentrate_Offered', 'Farm_Mineral_Supplement', 'Farm_Water_Source', 'Farm_Forestripping',
    'Farm_Premilking_Teat_Cleaning', 'Farm_Drying_Material', 'Farm_Gloves_Used', 'Farm_Postmilking_Teat_Disinfection',
    'Missing_Reason', 'Protocol_Deviation', 'Notes'
  ];

  static const List<String> dbKeys = [
    'record_key_derived', 'state', 'lga', 'farm_id', 'visit_id', 'visit_date', 'scheduled_visit_date', 'observer_id',
    'farm_production_system', 'farm_total_cattle', 'farm_lactating_cows', 'farm_milking_method', 'farm_milking_frequency_day',
    'farm_housing_type', 'farm_floor_wetness', 'farm_bedding_condition', 'farm_manure_accumulation', 'farm_fly_abundance',
    'farm_water_available', 'farm_feed_change', 'farm_milking_routine_change', 'farm_disease_outbreak',
    'cow_id', 'local_tag_id', 'lactation_id', 'breed_genetic_group', 'cow_birth_date', 'cow_age_years', 'cow_source',
    'parity', 'calving_date', 'dim_derived', 'pregnancy_status', 'previous_clinical_mastitis', 'previous_high_scc_cmt',
    'dry_cow_therapy_previous', 'teat_sealant_previous',
    'cow_milk_yield_value', 'cow_milk_yield_unit', 'cow_yield_period', 'cow_milking_frequency', 'cow_bcs_value',
    'cow_bcs_scale', 'cow_locomotion_score', 'cow_udder_hygiene_score', 'cow_rectal_temperature_c', 'cow_concurrent_disease_signs',
    'cow_antimicrobial_previous_14d', 'cow_mastitis_treatment_since_last', 'cow_incomplete_milking_or_suckling',
    'quarter', 'quarter_functional_status', 'quarter_clinical_mastitis', 'quarter_clinical_grade', 'quarter_milk_abnormality',
    'quarter_swelling_heat_pain', 'quarter_teat_end_score', 'quarter_teat_lesion', 'quarter_udder_finding',
    'cmt_score', 'cmt_positive_derived', 'cmt_reader_id', 'cmt_reagent_lot', 'cmt_reagent_expiry',
    'lab_sample_id', 'lab_sample_type', 'lab_collected_before_treatment', 'lab_scc_cells_ml', 'lab_scc_result_flag',
    'scs_derived', 'lab_culture_result_category', 'lab_organism_primary', 'lab_isolate_id', 'lab_mixed_contaminated',
    'lab_ast_method_standard', 'lab_ast_summary',
    'tx_event_id', 'tx_current_treatment', 'tx_product_trade_name', 'tx_active_ingredient', 'tx_dose', 'tx_dose_unit',
    'tx_route', 'tx_start_date', 'tx_stop_date', 'tx_milk_withdrawal_end_date', 'tx_outcome_next_visit',
    'farm_main_forage', 'farm_concentrate_offered', 'farm_mineral_supplement', 'farm_water_source', 'farm_forestripping',
    'farm_premilking_teat_cleaning', 'farm_drying_material', 'farm_gloves_used', 'farm_postmilking_teat_disinfection',
    'missing_reason', 'protocol_deviation', 'notes'
  ];

  /// Export 99-column Excel workbook from a list of VisitRecords or single cow
  Future<File> exportToExcel({
    required List<VisitRecord> visits,
    String? singleCowId,
    String filenamePrefix = 'Mastitis_Research_Data',
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['UDDER_HEALTH_DATA'];
    excel.delete('Sheet1');

    // 1. Header row
    sheet.appendRow(excelHeaders.map((h) => TextCellValue(h)).toList());

    // 2. Data rows
    for (final visit in visits) {
      final rows = visit.toSingleSheetRows();
      for (final row in rows) {
        if (singleCowId != null && row['cow_id'] != singleCowId) {
          continue;
        }

        final cellValues = <CellValue?>[];
        for (final k in dbKeys) {
          final val = row[k];
          if (val == null) {
            cellValues.add(null);
          } else if (val is int) {
            cellValues.add(IntCellValue(val));
          } else if (val is double) {
            cellValues.add(DoubleCellValue(val));
          } else if (val is bool) {
            cellValues.add(TextCellValue(val ? 'Yes' : 'No'));
          } else {
            cellValues.add(TextCellValue(val.toString()));
          }
        }
        sheet.appendRow(cellValues);
      }
    }

    final bytes = excel.save();
    final dir = await getTemporaryDirectory();
    final timeStr = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${filenamePrefix}_$timeStr.xlsx');
    await file.writeAsBytes(bytes!);
    return file;
  }

  /// Generate 99-column Excel bytes from raw database rows (works across Web, Desktop & Mobile)
  Future<Uint8List> generateExcelBytesFromRawRows({
    required List<Map<String, dynamic>> rows,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['UDDER_HEALTH_DATA'];
    excel.delete('Sheet1');

    // 1. Header row
    sheet.appendRow(excelHeaders.map((h) => TextCellValue(h)).toList());

    // 2. Data rows
    for (final row in rows) {
      final cellValues = <CellValue?>[];
      for (final k in dbKeys) {
        final val = row[k];
        if (val == null) {
          cellValues.add(null);
        } else if (val is int) {
          cellValues.add(IntCellValue(val));
        } else if (val is double) {
          cellValues.add(DoubleCellValue(val));
        } else if (val is bool) {
          cellValues.add(TextCellValue(val ? 'Yes' : 'No'));
        } else {
          cellValues.add(TextCellValue(val.toString()));
        }
      }
      sheet.appendRow(cellValues);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Share or download Excel file (works on Web, Windows, Android)
  Future<void> shareOrDownloadExcelBytes({
    required Uint8List bytes,
    String fileName = 'UDDER_HEALTH_DATA.xlsx',
    String subject = 'Mastitis Research Data Export (99 Columns)',
  }) async {
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          name: fileName,
        ),
      ],
      subject: subject,
      text: 'Exported Longitudinal Udder Health Research Data (99 Columns Excel)',
    );
  }

  /// Share exported Excel file
  Future<void> shareExcelFile(File file, {String subject = 'Mastitis Research Data Export'}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
      text: 'Exported Longitudinal Udder Health Research Data (99 Columns Excel)',
    );
  }

  /// Generate Printable PDF Document for Visit or Single Cow
  Future<Uint8List> generatePdfDocument({
    required VisitRecord visit,
    CowRecord? singleCow,
  }) async {
    final pdf = pw.Document();
    final cowsToInclude = singleCow != null ? [singleCow] : visit.cows;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(visit, singleCow),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          _buildFarmInfoSection(visit),
          pw.SizedBox(height: 14),
          pw.Text(
            singleCow != null ? 'INDIVIDUAL COW CLINICAL & CMT EXAMINATION' : 'COW SURVEILLANCE & CMT QUARTER EXAMINATIONS (${cowsToInclude.length} COWS)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
          ),
          pw.SizedBox(height: 8),
          ...cowsToInclude.map((cow) => _buildCowPdfCard(visit, cow)),
        ],
      ),
    );

    return pdf.save();
  }

  /// Print or Share PDF
  Future<void> printOrSharePdf({
    required VisitRecord visit,
    CowRecord? singleCow,
    bool isDirectPrint = true,
  }) async {
    final pdfBytes = await generatePdfDocument(visit: visit, singleCow: singleCow);
    final title = singleCow != null
        ? 'Udder_Health_Cow_${singleCow.cowId}_${visit.visitDate}.pdf'
        : 'Udder_Health_Visit_${visit.farmId}_${visit.visitDate}.pdf';

    if (isDirectPrint) {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: title,
      );
    } else {
      await Printing.sharePdf(bytes: pdfBytes, filename: title);
    }
  }

  pw.Widget _buildPdfHeader(VisitRecord visit, CowRecord? singleCow) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('MASTITIS RESEARCH & UDDER HEALTH STUDY',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
              pw.Text('Clinical Surveillance & CMT Long-Format Protocol (99 Columns)',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Farm: ${visit.farmId}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('Visit: ${visit.visitDate} | Obs: ${visit.observerId}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount} - mastitis_research',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _buildFarmInfoSection(VisitRecord visit) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.teal200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('SECTION A: FARM HEADER & HUSBANDRY CONDITIONS',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(child: _buildPdfTextRow('State / LGA', '${visit.state} / ${visit.lga.isEmpty ? "N/A" : visit.lga}')),
              pw.Expanded(child: _buildPdfTextRow('System', visit.farmProductionSystem)),
              pw.Expanded(child: _buildPdfTextRow('Milking Method', visit.farmMilkingMethod)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _buildPdfTextRow('Housing', visit.farmHousingType)),
              pw.Expanded(child: _buildPdfTextRow('Floor Wetness', visit.farmFloorWetness)),
              pw.Expanded(child: _buildPdfTextRow('Bedding / Manure', '${visit.farmBeddingCondition} / ${visit.farmManureAccumulation}')),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _buildPdfTextRow('Total / Lactating', '${visit.farmTotalCattle ?? "N/A"} / ${visit.farmLactatingCows ?? "N/A"}')),
              pw.Expanded(child: _buildPdfTextRow('Water Source', visit.farmWaterSource)),
              pw.Expanded(child: _buildPdfTextRow('Pre-cleaning / Towel', '${visit.farmPremilkingTeatCleaning} / ${visit.farmDryingMaterial}')),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCowPdfCard(VisitRecord visit, CowRecord cow) {
    final dim = cow.computeDim(visit.visitDate);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cow ID: ${cow.cowId}  (Tag: ${(cow.localTagId != null && cow.localTagId!.isNotEmpty) ? cow.localTagId : "None"})',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
              pw.Text('Breed: ${cow.breedGeneticGroup} | Parity: ${cow.parity} | DIM: ${dim ?? "N/A"}d',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('Yield: ${cow.cowMilkYieldValue ?? "N/A"} ${cow.cowMilkYieldUnit} | BCS: ${cow.cowBcsValue ?? "N/A"} | Temp: ${cow.cowRectalTemperatureC ?? "N/A"}°C | Hygiene: ${cow.cowUdderHygieneScore}',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),

          // 4-Quarter CMT Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableCell('Quarter', isHeader: true),
                  _tableCell('Status', isHeader: true),
                  _tableCell('CMT Score', isHeader: true),
                  _tableCell('CMT Positive', isHeader: true),
                  _tableCell('Clinical Mastitis', isHeader: true),
                  _tableCell('Teat End', isHeader: true),
                  _tableCell('Sample ID', isHeader: true),
                ],
              ),
              ...['LF', 'RF', 'LR', 'RR'].map((qKey) {
                final q = cow.quarters[qKey] ?? QuarterData(quarter: qKey);
                final sampleId = (q.labSampleId != null && q.labSampleId!.isNotEmpty) ? q.labSampleId! : '-';
                return pw.TableRow(
                  children: [
                    _tableCell(qKey, isBold: true),
                    _tableCell(q.functionalStatus),
                    _tableCell(q.cmtScore, isBold: true, color: _cmtPdfColor(q.cmtScore)),
                    _tableCell(q.cmtPositiveDerived),
                    _tableCell(q.clinicalMastitis == 'Yes' ? 'YES (G${q.clinicalGrade})' : 'No'),
                    _tableCell('${q.teatEndScore}'),
                    _tableCell(sampleId),
                  ],
                );
              }),
            ],
          ),

          if (cow.treatment.txCurrentTreatment == 'Yes') ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              color: PdfColors.amber50,
              child: pw.Text(
                'Treatment: ${cow.treatment.txProductTradeName} (${cow.treatment.txActiveIngredient}) | Dose: ${cow.treatment.txDose ?? ""} ${cow.treatment.txDoseUnit} | Route: ${cow.treatment.txRoute} | Withdrawal End: ${cow.treatment.txMilkWithdrawalEndDate ?? "N/A"}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.brown800),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false, bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  static PdfColor _cmtPdfColor(String score) {
    switch (score) {
      case 'N':
        return PdfColors.green800;
      case 'T':
        return PdfColors.amber800;
      case '1':
      case '2':
        return PdfColors.orange800;
      case '3':
        return PdfColors.red800;
      default:
        return PdfColors.grey700;
    }
  }

  static pw.Widget _buildPdfTextRow(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/study_models.dart';

class LocalStorageService {
  static const String _keyVisits = 'local_udder_health_visits_v1';
  static const String _keyObserverId = 'saved_observer_id';
  static const String _keyDefaultState = 'saved_default_state';
  static const String _keyDefaultLga = 'saved_default_lga';

  // Singleton
  static final LocalStorageService instance = LocalStorageService._internal();
  LocalStorageService._internal();

  /// Gets the saved default observer ID (e.g. Dr Jimoh or OBS01)
  Future<String> getObserverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyObserverId) ?? 'OBS-01';
  }

  Future<void> setObserverId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyObserverId, id.trim());
  }

  static const String _keyObserverName = 'saved_observer_name';
  static const String _keyObserverEmail = 'saved_observer_email';
  static const String _keyObserverInstitution = 'saved_observer_institution';
  static const String _keyObserverImagePath = 'saved_observer_image_path';

  Future<String> getObserverName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyObserverName) ?? 'Dr. Muhammad Jimoh';
  }

  Future<void> setObserverName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyObserverName, name.trim());
  }

  Future<String> getObserverEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyObserverEmail) ?? 'researcher@udderhealth.org';
  }

  Future<void> setObserverEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyObserverEmail, email.trim());
  }

  Future<String> getObserverInstitution() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyObserverInstitution) ?? 'Faculty of Veterinary Medicine';
  }

  Future<void> setObserverInstitution(String inst) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyObserverInstitution, inst.trim());
  }

  Future<String?> getObserverImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyObserverImagePath);
  }

  Future<void> setObserverImagePath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_keyObserverImagePath);
    } else {
      await prefs.setString(_keyObserverImagePath, path);
    }
  }

  static const String _keyUserRole = 'saved_user_role';

  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole) ?? 'observer';
  }

  Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRole, role.trim());
  }

  Future<bool> isGrandObserver() async {
    final r = await getUserRole();
    return r == 'grand_observer' || r == 'admin';
  }

  Future<String> getDefaultState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultState) ?? 'Sokoto';
  }

  Future<void> setDefaultState(String state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultState, state);
  }

  Future<String> getDefaultLga() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultLga) ?? '';
  }

  Future<void> setDefaultLga(String lga) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultLga, lga.trim());
  }

  /// Load all visits stored locally
  Future<List<VisitRecord>> getLocalVisits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyVisits);
      if (jsonStr == null || jsonStr.isEmpty) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      final visits = list.map((item) => VisitRecord.fromJson(item)).toList();
      // Sort most recent first
      visits.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return visits;
    } catch (e) {
      return [];
    }
  }

  /// Save or update a visit locally
  Future<void> saveVisit(VisitRecord visit) async {
    final visits = await getLocalVisits();
    final index = visits.indexWhere((v) => v.id == visit.id);
    visit.updatedAt = DateTime.now();

    if (index >= 0) {
      visits[index] = visit;
    } else {
      visits.insert(0, visit);
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(visits.map((v) => v.toJson()).toList());
    await prefs.setString(_keyVisits, jsonStr);
  }

  /// Get a single visit by ID
  Future<VisitRecord?> getVisitById(String id) async {
    final visits = await getLocalVisits();
    try {
      return visits.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Delete a local visit
  Future<void> deleteVisit(String id) async {
    final visits = await getLocalVisits();
    visits.removeWhere((v) => v.id == id);
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(visits.map((v) => v.toJson()).toList());
    await prefs.setString(_keyVisits, jsonStr);
  }

  /// Uploads a visit to Supabase. Returns null if success, or error string if failed.
  Future<String?> syncVisitToSupabase(VisitRecord visit) async {
    if (visit.cows.isEmpty) {
      return 'No cows recorded in this visit yet. Please add at least one cow.';
    }

    try {
      final client = Supabase.instance.client;
      final rows = visit.toSingleSheetRows();

      // 1. Upload to the 99-column master table udder_health_data
      await client
          .from('udder_health_data')
          .upsert(rows, onConflict: 'record_key_derived');

      // 2. Also populate the relational tables for multi-level indexing
      try {
        // Farm visit header
        await client.from('farm_visits').upsert({
          'id': visit.id,
          'farm_id': visit.farmId,
          'visit_id': visit.visitId,
          'visit_date': visit.visitDate,
          'scheduled_visit_date': visit.scheduledVisitDate ?? visit.visitDate,
          'observer_id': visit.observerId,
          'production_system': visit.farmProductionSystem,
          'total_cattle': visit.farmTotalCattle,
          'lactating_cows': visit.farmLactatingCows,
          'milking_method': visit.farmMilkingMethod,
          'milking_frequency_day': visit.farmMilkingFrequencyDay,
          'housing_type': visit.farmHousingType,
          'floor_wetness': visit.farmFloorWetness,
          'bedding_condition': visit.farmBeddingCondition,
          'manure_accumulation': visit.farmManureAccumulation,
          'fly_abundance': visit.farmFlyAbundance,
          'water_available': visit.farmWaterAvailable,
          'feed_change': visit.farmFeedChange,
          'milking_routine_change': visit.farmMilkingRoutineChange,
          'disease_outbreak': visit.farmDiseaseOutbreak,
          'main_forage': visit.farmMainForage,
          'concentrate_offered': visit.farmConcentrateOffered,
          'mineral_supplement': visit.farmMineralSupplement,
          'water_source': visit.farmWaterSource,
          'forestripping': visit.farmForestripping,
          'premilking_teat_cleaning': visit.farmPremilkingTeatCleaning,
          'drying_material': visit.farmDryingMaterial,
          'gloves_used': visit.farmGlovesUsed,
          'postmilking_teat_disinfection': visit.farmPostmilkingTeatDisinfection,
        }, onConflict: 'visit_id');
      } catch (_) {
        // Relational table sync is secondary; ignore if table differs
      }

      // Mark locally as synced
      visit.isSynced = true;
      await saveVisit(visit);
      return null; // Success
    } catch (e) {
      return 'Sync error: $e';
    }
  }

  /// Syncs all visits that are currently marked isSynced = false
  Future<Map<String, dynamic>> syncAllPendingVisits() async {
    final visits = await getLocalVisits();
    final pending = visits.where((v) => !v.isSynced).toList();

    int successCount = 0;
    int failCount = 0;
    String lastError = '';

    for (final v in pending) {
      final err = await syncVisitToSupabase(v);
      if (err == null) {
        successCount++;
      } else {
        failCount++;
        lastError = err;
      }
    }

    return {
      'total': pending.length,
      'synced': successCount,
      'failed': failCount,
      'lastError': lastError,
    };
  }

  /// Fetch recent rows from cloud (cross-researcher view)
  Future<List<Map<String, dynamic>>> fetchAllCloudEntries({int limit = 50}) async {
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('udder_health_data')
          .select('visit_id, farm_id, visit_date, observer_id, cow_id, quarter, cmt_score, cmt_positive_derived, quarter_clinical_mastitis, created_at')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  /// Fetch all 99-column complete rows from cloud for Grand Researcher Spreadsheet Viewer
  Future<List<Map<String, dynamic>>> fetchCompleteSpreadsheetRows({int limit = 2000}) async {
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('udder_health_data')
          .select('*')
          .order('visit_date', ascending: false)
          .limit(limit);
      if (data.isNotEmpty) {
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      // Fallback below
    }

    // Fallback: If offline or query empty, generate rows from local visits
    final localVisits = await getLocalVisits();
    final List<Map<String, dynamic>> localRows = [];
    for (final v in localVisits) {
      localRows.addAll(v.toSingleSheetRows());
    }
    return localRows;
  }

  /// Downloads all visits from Supabase and merges them into local storage.
  /// This ensures any phone/device installing the app immediately sees the
  /// complete research records created across all team members.
  Future<int> fetchAndMergeCloudVisits() async {
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('udder_health_data')
          .select('*')
          .order('visit_date', ascending: false)
          .limit(2000);

      if (data.isEmpty) return 0;

      // Group rows by visit_id
      final Map<String, List<Map<String, dynamic>>> visitGroups = {};
      for (final row in data) {
        final vId = (row['visit_id'] ?? '').toString();
        if (vId.isEmpty) continue;
        visitGroups.putIfAbsent(vId, () => []).add(row);
      }

      final List<VisitRecord> cloudVisits = [];

      for (final entry in visitGroups.entries) {
        final rows = entry.value;
        final firstRow = rows.first;

        // Group by cow_id
        final Map<String, List<Map<String, dynamic>>> cowGroups = {};
        for (final r in rows) {
          final cId = (r['cow_id'] ?? '').toString();
          if (cId.isEmpty) continue;
          cowGroups.putIfAbsent(cId, () => []).add(r);
        }

        final List<CowRecord> cows = [];
        for (final cowEntry in cowGroups.entries) {
          final cowRows = cowEntry.value;
          final cFirst = cowRows.first;

          // Build quarter map
          final Map<String, QuarterData> quarters = {};
          for (final qRow in cowRows) {
            final qKey = (qRow['quarter'] ?? '').toString();
            if (qKey.isNotEmpty) {
              quarters[qKey] = QuarterData(
                quarter: qKey,
                functionalStatus: qRow['quarter_functional_status'] ?? 'Functional',
                clinicalMastitis: qRow['quarter_clinical_mastitis'] ?? 'No',
                clinicalGrade: qRow['quarter_clinical_grade'],
                milkAbnormality: qRow['quarter_milk_abnormality'] ?? 'No',
                swellingHeatPain: qRow['quarter_swelling_heat_pain'] ?? 'No',
                teatEndScore: (qRow['quarter_teat_end_score'] as num?)?.toInt() ?? 1,
                teatLesion: qRow['quarter_teat_lesion'] ?? 'No',
                udderFinding: qRow['quarter_udder_finding'],
                cmtScore: qRow['cmt_score'] ?? 'N',
                cmtReaderId: qRow['cmt_reader_id'],
                cmtReagentLot: qRow['cmt_reagent_lot'],
                cmtReagentExpiry: qRow['cmt_reagent_expiry'],
                labSampleId: qRow['lab_sample_id'],
                labSampleType: qRow['lab_sample_type'],
                labCollectedBeforeTreatment: qRow['lab_collected_before_treatment'],
                labSccCellsMl: (qRow['lab_scc_cells_ml'] as num?)?.toInt(),
                labSccResultFlag: qRow['lab_scc_result_flag'],
                labCultureResultCategory: qRow['lab_culture_result_category'],
                labOrganismPrimary: qRow['lab_organism_primary'],
                labIsolateId: qRow['lab_isolate_id'],
                labMixedContaminated: qRow['lab_mixed_contaminated'],
                labAstMethodStandard: qRow['lab_ast_method_standard'],
                labAstSummary: qRow['lab_ast_summary'],
                missingReason: qRow['missing_reason'] ?? 'Not missing',
                protocolDeviation: qRow['protocol_deviation'],
                notes: qRow['notes'],
              );
            }
          }

          // Build Treatment
          final txData = TreatmentData(
            txEventId: cFirst['tx_event_id'],
            txCurrentTreatment: cFirst['tx_current_treatment'] ?? 'No',
            txProductTradeName: cFirst['tx_product_trade_name'],
            txActiveIngredient: cFirst['tx_active_ingredient'],
            txDose: (cFirst['tx_dose'] as num?)?.toDouble(),
            txDoseUnit: cFirst['tx_dose_unit'] ?? 'mL',
            txRoute: cFirst['tx_route'] ?? 'Intramammary',
            txStartDate: cFirst['tx_start_date'],
            txStopDate: cFirst['tx_stop_date'],
            txMilkWithdrawalEndDate: cFirst['tx_milk_withdrawal_end_date'],
            txOutcomeNextVisit: cFirst['tx_outcome_next_visit'],
          );

          cows.add(CowRecord(
            cowId: cowEntry.key,
            localTagId: cFirst['local_tag_id'],
            lactationId: cFirst['lactation_id'],
            breedGeneticGroup: cFirst['breed_genetic_group'],
            cowBirthDate: cFirst['cow_birth_date'],
            cowAgeYears: (cFirst['cow_age_years'] as num?)?.toDouble(),
            cowSource: cFirst['cow_source'] ?? 'Homebred',
            parity: (cFirst['parity'] as num?)?.toInt() ?? 1,
            calvingDate: cFirst['calving_date'],
            pregnancyStatus: cFirst['pregnancy_status'] ?? 'Unknown',
            previousClinicalMastitis: cFirst['previous_clinical_mastitis'] ?? 'No',
            previousHighSccCmt: cFirst['previous_high_scc_cmt'] ?? 'No',
            dryCowTherapyPrevious: cFirst['dry_cow_therapy_previous'] ?? 'Unknown',
            teatSealantPrevious: cFirst['teat_sealant_previous'] ?? 'Unknown',
            cowMilkYieldValue: (cFirst['cow_milk_yield_value'] as num?)?.toDouble(),
            cowMilkYieldUnit: cFirst['cow_milk_yield_unit'] ?? 'L',
            cowYieldPeriod: cFirst['cow_yield_period'] ?? 'Morning',
            cowMilkingFrequency: (cFirst['cow_milking_frequency'] as num?)?.toInt(),
            cowBcsValue: (cFirst['cow_bcs_value'] as num?)?.toDouble() ?? 3.0,
            cowBcsScale: cFirst['cow_bcs_scale'] ?? '1-5',
            cowLocomotionScore: (cFirst['cow_locomotion_score'] as num?)?.toInt() ?? 1,
            cowUdderHygieneScore: (cFirst['cow_udder_hygiene_score'] as num?)?.toInt() ?? 1,
            cowRectalTemperatureC: (cFirst['cow_rectal_temperature_c'] as num?)?.toDouble(),
            cowConcurrentDiseaseSigns: cFirst['cow_concurrent_disease_signs'],
            cowAntimicrobialPrevious14d: cFirst['cow_antimicrobial_previous_14d'] ?? 'No',
            cowMastitisTreatmentSinceLast: cFirst['cow_mastitis_treatment_since_last'] ?? 'No',
            cowIncompleteMilkingOrSuckling: cFirst['cow_incomplete_milking_or_suckling'] ?? 'No',
            quarters: quarters,
            treatment: txData,
          ));
        }

        final visitRecord = VisitRecord(
          id: (firstRow['id'] ?? entry.key).toString(),
          farmId: (firstRow['farm_id'] ?? '').toString(),
          visitId: entry.key,
          visitDate: (firstRow['visit_date'] ?? '').toString(),
          scheduledVisitDate: firstRow['scheduled_visit_date']?.toString(),
          observerId: (firstRow['observer_id'] ?? '').toString(),
          state: (firstRow['state'] ?? 'Sokoto').toString(),
          lga: (firstRow['lga'] ?? '').toString(),
          farmProductionSystem: (firstRow['farm_production_system'] ?? 'Semi-intensive').toString(),
          farmTotalCattle: (firstRow['farm_total_cattle'] as num?)?.toInt(),
          farmLactatingCows: (firstRow['farm_lactating_cows'] as num?)?.toInt(),
          farmMilkingMethod: (firstRow['farm_milking_method'] ?? 'Hand').toString(),
          farmMilkingFrequencyDay: (firstRow['farm_milking_frequency_day'] as num?)?.toInt() ?? 2,
          farmHousingType: (firstRow['farm_housing_type'] ?? 'Open yard').toString(),
          farmFloorWetness: (firstRow['farm_floor_wetness'] ?? 'Dry').toString(),
          farmBeddingCondition: (firstRow['farm_bedding_condition'] ?? 'Dry').toString(),
          farmManureAccumulation: (firstRow['farm_manure_accumulation'] ?? 'Low').toString(),
          farmFlyAbundance: (firstRow['farm_fly_abundance'] ?? 'Low').toString(),
          farmWaterAvailable: (firstRow['farm_water_available'] ?? 'Yes').toString(),
          farmFeedChange: (firstRow['farm_feed_change'] ?? 'No').toString(),
          farmMilkingRoutineChange: (firstRow['farm_milking_routine_change'] ?? 'No').toString(),
          farmDiseaseOutbreak: (firstRow['farm_disease_outbreak'] ?? 'No').toString(),
          farmMainForage: firstRow['farm_main_forage']?.toString(),
          farmConcentrateOffered: (firstRow['farm_concentrate_offered'] ?? 'Yes').toString(),
          farmMineralSupplement: (firstRow['farm_mineral_supplement'] ?? 'Yes').toString(),
          farmWaterSource: (firstRow['farm_water_source'] ?? 'Borehole').toString(),
          farmForestripping: (firstRow['farm_forestripping'] ?? 'Always').toString(),
          farmPremilkingTeatCleaning: (firstRow['farm_premilking_teat_cleaning'] ?? 'Water only').toString(),
          farmDryingMaterial: (firstRow['farm_drying_material'] ?? 'Individual towel').toString(),
          farmGlovesUsed: (firstRow['farm_gloves_used'] ?? 'Sometimes').toString(),
          farmPostmilkingTeatDisinfection: (firstRow['farm_postmilking_teat_disinfection'] ?? 'Never').toString(),
          cows: cows,
          isSynced: true,
          updatedAt: firstRow['updated_at'] != null ? DateTime.tryParse(firstRow['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
        );

        cloudVisits.add(visitRecord);
      }

      // Merge with local storage
      final localVisits = await getLocalVisits();
      int newOrUpdated = 0;

      for (final cv in cloudVisits) {
        final existingIdx = localVisits.indexWhere((lv) => lv.visitId == cv.visitId || lv.id == cv.id);
        if (existingIdx < 0) {
          // Brand new visit downloaded from cloud
          localVisits.add(cv);
          newOrUpdated++;
        } else {
          // If local visit is already synced, update it with cloud version
          if (localVisits[existingIdx].isSynced) {
            localVisits[existingIdx] = cv;
            newOrUpdated++;
          }
        }
      }

      localVisits.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Save back to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(localVisits.map((v) => v.toJson()).toList());
      await prefs.setString(_keyVisits, jsonStr);

      return newOrUpdated;
    } catch (e) {
      // Offline or network error - return 0 silently
      return 0;
    }
  }
}

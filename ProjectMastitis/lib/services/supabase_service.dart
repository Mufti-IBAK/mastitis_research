import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/farm.dart';
import '../models/farm_visit.dart';
import '../models/cow_visit.dart';
import '../models/quarter_visit.dart';
import '../models/sample_lab.dart';
import '../models/treatment.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Authentication
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  /// Native Google Sign-In on Android linking to Supabase Auth
  Future<AuthResponse> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: SupabaseConfig.googleWebClientId,
      clientId: SupabaseConfig.googleAndroidClientId,
      scopes: ['email', 'profile'],
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google Sign-In was cancelled by user.');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('No ID Token received from Google Sign-In.');
    }

    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // Farms
  Future<List<Farm>> getFarms() async {
    final data = await _client.from('farms').select();
    return data.map((json) => Farm.fromJson(json)).toList();
  }

  Future<Farm> addFarm(Farm farm) async {
    final data = await _client.from('farms').insert(farm.toJson()).select().single();
    return Farm.fromJson(data);
  }

  // Farm Visits
  Future<List<FarmVisit>> getFarmVisits() async {
    final data = await _client.from('farm_visits').select();
    return data.map((json) => FarmVisit.fromJson(json)).toList();
  }

  Future<List<FarmVisit>> getFarmVisitsByFarm(String farmId) async {
    final data = await _client.from('farm_visits').select().eq('farm_id', farmId);
    return data.map((json) => FarmVisit.fromJson(json)).toList();
  }

  Future<FarmVisit> addFarmVisit(FarmVisit farmVisit) async {
    final data = await _client.from('farm_visits').insert(farmVisit.toJson()).select().single();
    return FarmVisit.fromJson(data);
  }

  Future<FarmVisit> updateFarmVisit(FarmVisit farmVisit) async {
    final data = await _client.from('farm_visits').update(farmVisit.toJson()).eq('id', farmVisit.id).select().single();
    return FarmVisit.fromJson(data);
  }

  // Cow Visits
  Future<List<CowVisit>> getCowVisitsByFarmVisit(String farmVisitId) async {
    final data = await _client.from('cow_visits').select().eq('farm_visit_id', farmVisitId);
    return data.map((json) => CowVisit.fromJson(json)).toList();
  }

  Future<CowVisit> addCowVisit(CowVisit cowVisit) async {
    final data = await _client.from('cow_visits').insert(cowVisit.toJson()).select().single();
    return CowVisit.fromJson(data);
  }

  Future<CowVisit> updateCowVisit(CowVisit cowVisit) async {
    final data = await _client.from('cow_visits').update(cowVisit.toJson()).eq('id', cowVisit.id).select().single();
    return CowVisit.fromJson(data);
  }

  // Quarter Visits
  Future<List<QuarterVisit>> getQuarterVisitsByCowVisit(String cowVisitId) async {
    final data = await _client.from('quarter_visits').select().eq('cow_visit_id', cowVisitId);
    return data.map((json) => QuarterVisit.fromJson(json)).toList();
  }

  Future<QuarterVisit> addQuarterVisit(QuarterVisit quarterVisit) async {
    final data = await _client.from('quarter_visits').insert(quarterVisit.toJson()).select().single();
    return QuarterVisit.fromJson(data);
  }
  
  Future<List<QuarterVisit>> addQuarterVisits(List<QuarterVisit> quarterVisits) async {
    final data = await _client.from('quarter_visits').insert(quarterVisits.map((q) => q.toJson()).toList()).select();
    return (data as List).map((json) => QuarterVisit.fromJson(json)).toList();
  }

  Future<QuarterVisit> updateQuarterVisit(QuarterVisit quarterVisit) async {
    final data = await _client.from('quarter_visits').update(quarterVisit.toJson()).eq('id', quarterVisit.id).select().single();
    return QuarterVisit.fromJson(data);
  }

  // Sample Lab
  Future<SampleLab> addSampleLab(SampleLab sampleLab) async {
    final data = await _client.from('sample_labs').insert(sampleLab.toJson()).select().single();
    return SampleLab.fromJson(data);
  }

  Future<List<SampleLab>> getSampleLabByQuarterVisit(String quarterVisitId) async {
    final data = await _client.from('sample_labs').select().eq('quarter_visit_id', quarterVisitId);
    return data.map((json) => SampleLab.fromJson(json)).toList();
  }

  // Treatments
  Future<Treatment> addTreatment(Treatment treatment) async {
    final data = await _client.from('treatments').insert(treatment.toJson()).select().single();
    return Treatment.fromJson(data);
  }

  Future<List<Treatment>> getTreatmentsByCowVisit(String cowVisitId) async {
    final data = await _client.from('treatments').select().eq('cow_visit_id', cowVisitId);
    return data.map((json) => Treatment.fromJson(json)).toList();
  }

  // All Visits
  Future<List<dynamic>> getAllVisits() async {
    final data = await _client.from('farm_visits').select('*, cow_visits(*, quarter_visits(*, sample_labs(*)))');
    return data;
  }
}

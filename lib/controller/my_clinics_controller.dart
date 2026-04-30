import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/doctor_clinic_model.dart';
import '../service/doctor_clinics_service.dart';
import '../utilities/sharedpreference_constants.dart';

/// Holds the doctor's clinics list + the currently-picked clinic.
/// `selectedClinicId == null` means "All my clinics" (caller should send
/// clinic_ids of every clinic in the list, see appointment_controller).
class MyClinicsController extends GetxController {
  final RxList<DoctorClinicModel> clinics = <DoctorClinicModel>[].obs;
  final RxnInt selectedClinicId = RxnInt();
  final RxBool isLoading = false.obs;
  final RxBool isError = false.obs;

  /// CSV of every clinic the doctor belongs to. Useful for the "All" filter
  /// to send clinic_ids to the backend (so non-doctor's appointments are
  /// excluded even when the user picks "All").
  String get allClinicIdsCsv =>
      clinics.map((c) => c.clinicId).whereType<int>().join(',');

  Future<void> loadForUser(String userId) async {
    isLoading(true);
    isError(false);
    try {
      final list =
          await DoctorClinicsService.getMyClinics(userId: userId);
      if (list != null) {
        clinics.value = list;
        await _restoreSelection();
      } else {
        clinics.clear();
      }
    } catch (_) {
      isError(true);
    } finally {
      isLoading(false);
    }
  }

  Future<void> _restoreSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(SharedPreferencesConstants.clinicId) ?? '';
    if (stored.isEmpty || stored == 'all') {
      // If only one clinic, pick it; otherwise leave as "All".
      selectedClinicId.value = clinics.length == 1
          ? clinics.first.clinicId
          : null;
      return;
    }
    final parsed = int.tryParse(stored);
    if (parsed != null && clinics.any((c) => c.clinicId == parsed)) {
      selectedClinicId.value = parsed;
    } else if (clinics.length == 1) {
      selectedClinicId.value = clinics.first.clinicId;
    } else {
      selectedClinicId.value = null;
    }
  }

  Future<void> setSelection(int? clinicId) async {
    selectedClinicId.value = clinicId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      SharedPreferencesConstants.clinicId,
      clinicId == null ? 'all' : clinicId.toString(),
    );
  }
}

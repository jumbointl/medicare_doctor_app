import '../helper/get_req_helper.dart';
import '../model/doctor_clinic_model.dart';
import '../utilities/api_content.dart';

/// Pulls the list of clinics where the logged-in doctor is registered.
///
/// Backend: GET /api/v1/get_doctor?user_id={uid}&active=1
/// → returns one v_doctors row per (doctor, clinic) pair.
class DoctorClinicsService {
  static Future<List<DoctorClinicModel>?> getMyClinics({
    required String userId,
  }) async {
    if (userId.isEmpty || userId == '-1' || userId == 'null') return null;
    final body = <String, String>{
      'user_id': userId,
      'active': '1',
    };
    final res = await GetService.getReqWithBody(
      ApiContents.getDoctorsUrl,
      body,
    );
    if (res == null) return null;
    return List<DoctorClinicModel>.from(
      (res as List).map((item) => DoctorClinicModel.fromJson(item)),
    );
  }
}

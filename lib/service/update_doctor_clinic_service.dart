import '../helper/post_req_helper.dart';
import '../utilities/api_content.dart';

/// POST /api/v1/update_doctor_clinic_status
///
/// Updates the per-clinic row in `user_clinics` for the (doctor, clinic) pair.
/// All fields except [doctorId] and [clinicId] are optional — only the keys
/// that are non-null are sent, so the backend only touches those columns.
class UpdateDoctorClinicService {
  static Future<bool> update({
    required int doctorId,
    required int clinicId,
    int? active,
    int? stopBooking,
    int? opdClinic,
    int? videoClinic,
    int? emergencyClinic,
    num? opdFee,
    num? videoCFee,
    num? emergencyFee,
    String? noAvailableDateStart,
    String? noAvailableDateEnd,
    int? autoRescheduledAllowed,
    int? autoRescheduledAllowedBeforeMinutes,
    int? videoAutoRescheduledAllowed,
    int? videoAutoRescheduledAllowedBeforeMinutes,
    bool clearNoAvailableDateStart = false,
    bool clearNoAvailableDateEnd = false,
  }) async {
    final body = <String, dynamic>{
      'doctor_id': doctorId,
      'clinic_id': clinicId,
    };

    void putIf(String key, Object? value) {
      if (value != null) body[key] = value;
    }

    putIf('active', active);
    putIf('stop_booking', stopBooking);
    putIf('opd_clinic', opdClinic);
    putIf('video_clinic', videoClinic);
    putIf('emergency_clinic', emergencyClinic);
    putIf('opd_fee', opdFee);
    putIf('video_c_fee', videoCFee);
    putIf('emergency_fee', emergencyFee);
    putIf('auto_rescheduled_allowed', autoRescheduledAllowed);
    putIf(
      'auto_rescheduled_allowed_before_minutes',
      autoRescheduledAllowedBeforeMinutes,
    );
    putIf('video_auto_rescheduled_allowed', videoAutoRescheduledAllowed);
    putIf(
      'video_auto_rescheduled_allowed_before_minutes',
      videoAutoRescheduledAllowedBeforeMinutes,
    );

    // Date range — empty string clears the column on the backend.
    if (clearNoAvailableDateStart) {
      body['no_available_date_start'] = '';
    } else if (noAvailableDateStart != null) {
      body['no_available_date_start'] = noAvailableDateStart;
    }
    if (clearNoAvailableDateEnd) {
      body['no_available_date_end'] = '';
    } else if (noAvailableDateEnd != null) {
      body['no_available_date_end'] = noAvailableDateEnd;
    }

    final res = await PostService.postReq(
      ApiContents.updateDoctorClinicStatusUrl,
      body,
    );

    if (res == null) return false;
    if (res is Map) {
      final status = res['status'];
      if (status == true) return true;
      final response = res['response'];
      if (response == 200) return true;
    }
    return false;
  }
}

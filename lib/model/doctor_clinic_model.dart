/// One row of v_doctors viewed from the doctor-app perspective: the clinic
/// where the logged-in doctor user is registered. Multiple instances per
/// doctor when they belong to several clinics.
class DoctorClinicModel {
  final int? clinicId;
  final String? clinicTitle;
  final int? isActive;
  final int? isDefault;
  final int? active;
  final int? stopBooking;

  // Per-clinic appointment-type flags (from user_clinics).
  final int? opdClinic;
  final int? videoClinic;
  final int? emergencyClinic;

  // Per-clinic fees (from user_clinics).
  final num? opdFee;
  final num? videoCFee;
  final num? emergencyFee;

  // Doctor identity (for forms that need to send doctor_id back).
  final int? doctorId;

  // No-availability date range (string yyyy-MM-dd from backend, may be null).
  final String? noAvailableDateStart;
  final String? noAvailableDateEnd;

  // Auto-reschedule policy per clinic.
  final int? autoRescheduledAllowed;
  final int? autoRescheduledAllowedBeforeMinutes;
  final int? videoAutoRescheduledAllowed;
  final int? videoAutoRescheduledAllowedBeforeMinutes;

  DoctorClinicModel({
    this.clinicId,
    this.clinicTitle,
    this.isActive,
    this.isDefault,
    this.active,
    this.stopBooking,
    this.opdClinic,
    this.videoClinic,
    this.emergencyClinic,
    this.opdFee,
    this.videoCFee,
    this.emergencyFee,
    this.doctorId,
    this.noAvailableDateStart,
    this.noAvailableDateEnd,
    this.autoRescheduledAllowed,
    this.autoRescheduledAllowedBeforeMinutes,
    this.videoAutoRescheduledAllowed,
    this.videoAutoRescheduledAllowedBeforeMinutes,
  });

  factory DoctorClinicModel.fromJson(Map<String, dynamic> json) =>
      DoctorClinicModel(
        clinicId: _readInt(json['clinic_id']),
        clinicTitle: json['clinic_title']?.toString(),
        isActive: _readInt(json['is_active']),
        isDefault: _readInt(json['is_default']),
        active: _readInt(json['active']),
        stopBooking: _readInt(json['stop_booking']),
        opdClinic: _readInt(json['opd_clinic']),
        videoClinic: _readInt(json['video_clinic']),
        emergencyClinic: _readInt(json['emergency_clinic']),
        opdFee: _readNum(json['opd_fee']),
        videoCFee: _readNum(json['video_c_fee'] ?? json['video_fee']),
        emergencyFee: _readNum(json['emergency_fee'] ?? json['emg_fee']),
        doctorId: _readInt(json['doctor_id']),
        noAvailableDateStart: json['no_available_date_start']?.toString(),
        noAvailableDateEnd: json['no_available_date_end']?.toString(),
        autoRescheduledAllowed: _readInt(json['auto_rescheduled_allowed']),
        autoRescheduledAllowedBeforeMinutes:
            _readInt(json['auto_rescheduled_allowed_before_minutes']),
        videoAutoRescheduledAllowed:
            _readInt(json['video_auto_rescheduled_allowed']),
        videoAutoRescheduledAllowedBeforeMinutes: _readInt(
            json['video_auto_rescheduled_allowed_before_minutes']),
      );

  static int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static num? _readNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }
}

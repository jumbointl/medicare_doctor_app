class DoctorsModel{
  int? id;
  String? fName;
  String? lName;
  int? exYear;
  String? specialization;
  String? image;
  String? desc;
  int? clinicAppointment;
  int? videoAppointment;
  int? emergencyAppointment;
  double? averageRating;
  int? numberOfReview;
  int? totalAppointmentDone;
  double? opdFee;
  double? videoFee;
  double? emgFee;
  int? autoRescheduledAllowed;
  int? videoAutoRescheduledAllowed;
  int? autoRescheduledAllowedBeforeMinutes;
  int? videoAutoRescheduledAllowedBeforeMinutes;
  DoctorsModel({
    this.id,
    this.fName,
    this.exYear,
    this.lName,
    this.specialization,
    this.image,
    this.desc,
    this.clinicAppointment,
    this.emergencyAppointment,
    this.videoAppointment,
    this.averageRating,
    this.numberOfReview,
    this.totalAppointmentDone,
    this.emgFee,
    this.opdFee,
    this.videoFee,
    this.autoRescheduledAllowed,
    this.videoAutoRescheduledAllowed,
    this.autoRescheduledAllowedBeforeMinutes,
    this.videoAutoRescheduledAllowedBeforeMinutes,
  });

  factory DoctorsModel.fromJson(Map<String,dynamic> json){
    return DoctorsModel(
      fName: json['f_name'],
      id: json['user_id'],
      exYear: json['ex_year'],
      lName: json['l_name'],
      specialization: json['specialization'],
      image: json['image'],
      desc: json['description'],
      clinicAppointment: json['clinic_appointment'],
      emergencyAppointment: json['emergency_appointment'],
      videoAppointment: json['video_appointment'],
        averageRating:  json['average_rating']!=null?double.parse(json['average_rating'].toString()):null,
      numberOfReview:json['number_of_reviews'],
        totalAppointmentDone:json['total_appointment_done'],
      emgFee:json['emg_fee']!=null?double.parse(json['emg_fee'].toString()):null,
      opdFee: json['opd_fee']!=null?double.parse(json['opd_fee'].toString()):null,
      videoFee: json['video_fee']!=null?double.parse(json['video_fee'].toString()):null,
      autoRescheduledAllowed: json['auto_rescheduled_allowed'] is int
          ? json['auto_rescheduled_allowed']
          : (json['auto_rescheduled_allowed'] != null ? int.tryParse(json['auto_rescheduled_allowed'].toString()) : null),
      videoAutoRescheduledAllowed: json['video_auto_rescheduled_allowed'] is int
          ? json['video_auto_rescheduled_allowed']
          : (json['video_auto_rescheduled_allowed'] != null ? int.tryParse(json['video_auto_rescheduled_allowed'].toString()) : null),
      // Accept both the correct key and the legacy typo "befor_minutes" that
      // the v_doctors view currently aliases.
      autoRescheduledAllowedBeforeMinutes: _readInt(
        json['auto_rescheduled_allowed_before_minutes']
            ?? json['auto_rescheduled_allowed_befor_minutes'],
      ),
      videoAutoRescheduledAllowedBeforeMinutes: _readInt(
        json['video_auto_rescheduled_allowed_before_minutes']
            ?? json['video_auto_rescheduled_allowed_befor_minutes'],
      ),
    );
  }

  static int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
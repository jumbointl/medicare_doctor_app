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
    this.videoFee
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
      videoFee: json['video_fee']!=null?double.parse(json['video_fee'].toString()):null
    );
  }

}
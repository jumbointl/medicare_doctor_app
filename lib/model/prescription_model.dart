class PrescriptionModel{
  int? id;
   int? appointmentId;
   int? patientId;
  String? patientFName;
  String? patientLName;
   String? test;
   String? advice;
   String? problemDesc;
   String? foodAllergies;
   String? tendencyBleed;
   String? heartDisease;
   String? bloodPressure;
   String? diabetic;
   String? surgery;
   String? accident;
   String? others;
   String? medicalHistory;
   String? currentMedication;
   String? femalePregnancy;
   String? breastFeeding;
   String? pulseRate;
   String? temperature;
   String? nextVisit;
  String? createdAt;
  String? notes;
  List? items;
  String? pdfFile;
  String? jsonData;
  PrescriptionModel({
    this.id,
    this.patientId,
    this.appointmentId,
    this.accident,
    this.advice,
    this.bloodPressure,
    this.breastFeeding,
    this.currentMedication,
    this.diabetic,
    this.femalePregnancy,
    this.foodAllergies,
    this.heartDisease,
    this.medicalHistory,
    this.nextVisit,
    this.others,
    this.problemDesc,
    this.pulseRate,
    this.surgery,
    this.temperature,
    this.tendencyBleed,
    this.test,
    this.createdAt,
    this.items,
    this.notes,
    this.patientFName,
    this.patientLName,
    this.pdfFile,
    this.jsonData
  });

  factory PrescriptionModel.fromJson(Map<String,dynamic> json){
    return PrescriptionModel(
      id: json['id'],
      appointmentId: json['appointment_id'],
      accident: json['accident'],
      advice: json['advice'],
      bloodPressure: json['blood_pressure'],
      breastFeeding: json['breast_feeding'],
      currentMedication: json['current_medication'],
      diabetic: json['diabetic'],
      femalePregnancy: json['female_pregnancy'],
      foodAllergies: json['food_allergies'],
      heartDisease: json['heart_disease'],
      medicalHistory: json['medical_history'],
      nextVisit: json['next_visit'],
      others: json['others'],
      patientId: json['patient_id'],
      problemDesc: json['problem_desc'],
      pulseRate: json['pulse_rate'],
      surgery: json['surgery'],
      temperature: json['temperature'],
      tendencyBleed: json['tendency_bleed'],
      test: json['test'],
      createdAt: json['created_at'],
      items: json['items'],
      notes: json['notes'],
      patientFName: json['patient_f_name'],
      patientLName: json['patient_l_name'],
      pdfFile: json['pdf_file'],
      jsonData: json['json_data']
    );
  }

}
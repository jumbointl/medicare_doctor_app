class NotificationModel{
  int? id;
  String? title;
  String? body;
  int? appointmentId;
  int? fileId;
  int? prescriptionId;
  String? createdAt;
  String? image;

  NotificationModel({
    this.id,
    this.body,
    this.title,
    this.createdAt,
    this.image,
    this.appointmentId,
    this.prescriptionId,
    this.fileId,


  });

  factory NotificationModel.fromJson(Map<String,dynamic> json){
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body:  json['body'],
      createdAt: json['created_at'],
      image: json['image'],
      appointmentId:  json['appointment_id'],
      fileId:  json['file_id'],
      prescriptionId:  json['prescription_id'],

    );
  }

}
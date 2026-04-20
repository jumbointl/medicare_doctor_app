
class MedicineModel{

  String title;
  String notes;
  MedicineModel({
    this.notes ="",
    this.title =""
  });

  factory MedicineModel.fromJson(Map<String,dynamic> json){
    return MedicineModel(

        title: json['title']??"",
        notes: json['notes']??""
    );
  }

}
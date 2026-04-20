class LanguageModel{
  String? title;
  String? code;
  String? direction;
  int? isDefault;
  int? id;


  LanguageModel({
    this.title,
    this.code,
    this.direction,
    this.isDefault, required int id,

  });

  factory LanguageModel.fromJson(Map<String,dynamic> json){
    return LanguageModel(
      title: json['title'],
      code: json['code'],
      direction: json['direction'],
      isDefault:  json['is_default'],
      id: json['id']

    );
  }
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "code": code,
      "direction": direction,
      "is_default":isDefault ?? 0,
      "id":id

    };
  }

}
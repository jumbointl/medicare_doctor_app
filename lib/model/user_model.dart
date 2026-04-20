class UserModel{
  int? id;
  List? roles;
  String? token;
  String? fName;
  String? lName;
  String? imageUrl;
  String? createdAt;
  UserModel({
    this.id,
    this.roles,
    this.token,
    this.imageUrl,
    this.lName,
    this.fName,
    this.createdAt
  });

  factory UserModel.fromJson(Map<String,dynamic> json){
    return UserModel(
      id: json['id'],
      roles: json['role'],
      token: json['token'],
     fName: json['f_name'],
      imageUrl: json['image'],
      lName: json['l_name'],
      createdAt: json['created_at'],
    );
  }

}
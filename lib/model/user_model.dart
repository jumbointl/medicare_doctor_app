class UserModel {
  int? id;
  List? roles;
  String? token;
  String? fName;
  String? lName;
  String? imageUrl;
  String? createdAt;

  // Contact / address fields used by the doctor profile form.
  String? email;
  String? phone;
  String? isdCode;
  String? gender;
  String? dob;
  String? address;
  String? city;
  String? state;
  String? postalCode;

  UserModel({
    this.id,
    this.roles,
    this.token,
    this.imageUrl,
    this.lName,
    this.fName,
    this.createdAt,
    this.email,
    this.phone,
    this.isdCode,
    this.gender,
    this.dob,
    this.address,
    this.city,
    this.state,
    this.postalCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      roles: json['role'],
      token: json['token'],
      fName: json['f_name'],
      imageUrl: json['image'],
      lName: json['l_name'],
      createdAt: json['created_at'],
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      isdCode: json['isd_code']?.toString(),
      gender: json['gender']?.toString(),
      dob: json['dob']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postal_code']?.toString(),
    );
  }
}

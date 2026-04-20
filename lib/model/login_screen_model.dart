class LoginScreenMode{
  String? image;

  LoginScreenMode({
    this.image,
  });

  factory LoginScreenMode.fromJson(Map<String,dynamic> json){
    return LoginScreenMode(
      image: json['image'],
    );
  }

}
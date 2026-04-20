import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../helper/route_helper.dart';
import '../service/login_screen_service.dart';
import '../service/login_service.dart';
import '../utilities/api_content.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/toast_message.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../helper/theme_helper.dart';
import '../service/user_service.dart';
import '../utilities/app_constans.dart';
import '../utilities/colors_constant.dart';
import '../utilities/image_constants.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/button_widget.dart';
import '../widget/input_label_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final List _images=[];
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  bool obscureText=true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void initState() {
   // _emailController.text="doctor@gmail.com";
   // _passwordController.text="12345678";
    super.initState();
    _initGoogleSignIn();
    getAndSetData();

  }
  Future<void> _initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
    } catch (e) {
      debugPrint("Doctor GoogleSignIn initialize error: $e");
    }
  }
  Future<void> _handleGoogleLogin() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint("Doctor Google login error: idToken is null or empty");
        IToastMsg.showMessage("something_went_wrong".tr);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);


      final user = userCredential.user;
      if (user == null) {
        debugPrint("Doctor Google login error: Firebase user is null");
        IToastMsg.showMessage("something_went_wrong".tr);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final String email = (user.email ?? '').trim().toLowerCase();
      debugPrint("Doctor Google login email: $email");
      if (email.isEmpty) {
        debugPrint("Doctor Google login error: email is empty");
        IToastMsg.showMessage("something_went_wrong".tr);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final resLogin = await LoginService.loginWithGoogle(
        idToken: idToken,
        email: email,
      );

      debugPrint("Doctor Google login response: $resLogin");

      if (resLogin == null) {
        IToastMsg.showMessage("something_went_wrong".tr);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      if (resLogin['status'] != true) {
        IToastMsg.showMessage(
          resLogin['message']?.toString() ?? "google_login_failed".tr,
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final List roles = resLogin['data']?['role'] ?? [];
      final bool hasDoctorRole = roles.any((e) => e['name'] == "Doctor");

      if (!hasDoctorRole) {
        IToastMsg.showMessage("this_account_is_not_doctor".tr);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final assignClinicId = resLogin['data']?['assign_clinic_id'];
      if (assignClinicId == null) {
        IToastMsg.showMessage("doctor_has_no_clinic_assigned".tr);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final SharedPreferences preferences =
      await SharedPreferences.getInstance();

      await preferences.setString(
        SharedPreferencesConstants.email,
        user.email?.trim() ?? '',
      );

      await preferences.setString(
        SharedPreferencesConstants.password,
        '',
      );
      debugPrint("Doctor Google login token: ${resLogin['token']}");
      await preferences.setString(
        SharedPreferencesConstants.token,
        resLogin['token']?.toString() ?? '',
      );

      await preferences.setString(
        SharedPreferencesConstants.uid,
        (resLogin['data']?['id'] ?? '').toString(),
      );

      await preferences.setString(
        SharedPreferencesConstants.clinicId,
        assignClinicId.toString(),
      );

      await preferences.setBool(
        SharedPreferencesConstants.login,
        true,
      );

      await preferences.setString(
        SharedPreferencesConstants.loginProvider,
        'google',
      );

      await preferences.setString(
        SharedPreferencesConstants.googleLoginAt,
        DateTime.now().toIso8601String(),
      );

      Get.offAllNamed(RouteHelper.getHomePageRoute());
    } catch (e) {
      debugPrint("Doctor Google login error: $e");
      IToastMsg.showMessage("something_went_wrong".tr);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:   _buildSlidingBody()
    );
  }
  Stack _buildSlidingBody(){
  return  Stack(
    children: [
      _images.isEmpty? Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: ColorResources.bgColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(ImageConstants.logoImage,
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 20),
              const Text(
                  '${AppConstants.appName} ',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 25
                  )),
            ],
          ),
        ),

      ) :  CarouselSlider.builder(
          itemCount:_images.length,
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height,
            viewportFraction: 1,
            autoPlay: _images.length==1?false:true,
            enlargeCenterPage: false,
            onPageChanged: _callbackFunction,
          ),
          itemBuilder: (ctx, index, realIdx) {
            return
              CachedNetworkImage(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.fill,
                imageUrl: _images[index],
                placeholder: (context, url) => const Center(child: Icon(Icons.image)),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              );
          },
        ),
      Positioned(
        bottom: 50,
      left: 20,
      right: 20,
      child:
      SizedBox(
        height: 50,
        child:_isLoading?const ILoadingIndicatorWidget(): SmallButtonsWidget(
            title: "login".tr,
            onPressed: () {
              _openBottomSheetLogin();
              }),
      ))
    ],
  );
  }
  void _callbackFunction(int index, CarouselPageChangedReason reason) {
    // setState(() {
    //   _currentIndex = index;
    // });
  }



  void getAndSetData() async {
    setState(() {
      _isLoading = true;
    });
    final resImage=await LoginScreenService.getData();
    if(resImage!=null){
      for(int i=0;i<resImage.length;i++){
        _images.add("${ApiContents.imageUrl}/${resImage[i].image??""}");
      }
    }
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final loggedIn = preferences.getBool(SharedPreferencesConstants.login) ?? false;
    final email = preferences.getString(SharedPreferencesConstants.email) ?? "";
    final password = preferences.getString(SharedPreferencesConstants.password) ?? "";
    if (loggedIn) {
      _handleSubmit(email,password);

    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<dynamic> _openBottomSheetLogin(){
    return
      showModalBottomSheet(
        backgroundColor:  ColorResources.bgColor,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0),
            topLeft: Radius.circular(20.0),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, setState) {
                return Padding(
                  padding: MediaQuery
                      .of(context)
                      .viewInsets,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SingleChildScrollView(
                      child:
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [




                            const SizedBox(height: 20),
                            SizedBox(
                              width:double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLogo(),
                                  const SizedBox(height: 20),
                                  const Text(
                                    '${AppConstants.appName} ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 25
                                    )),
                                  const SizedBox(height: 10),
                                     Text('credentials_to_login'.tr,
                                      style:  TextStyle(
                                        color: ColorResources.secondaryFontColor,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorResources.btnColor,
                                    shape:
                                    RoundedRectangleBorder(borderRadius:
                                    BorderRadius.circular(5.0)),
                                  ),
                                  onPressed: _isLoading ? null : _handleGoogleLogin,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text("continue_with_google".tr, style:  TextStyle(fontSize: 14,
                                        color: Colors.white)),
                                  )),
                            ),
                            const SizedBox(height: 20),
                            Text("or"),
                            const SizedBox(height: 20),
                            InputLabel.buildLabelBox("email".tr),
                            const SizedBox(height: 10),
                            Container(
                              decoration: ThemeHelper().inputBoxDecorationShaddow(),
                              child: TextFormField(
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if(val!.isEmpty){
                                    return "enter_email_address".tr;
                                  }
                                  else if((val.isNotEmpty) && !RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$").hasMatch(val)){
                                    return "valid_email_address".tr;
                                  }
                                 else {return null;}
                                },
                                controller: _emailController,
                                decoration: ThemeHelper().textInputDecoration('email'.tr),
                              ),
                            ),
                            const SizedBox(height: 10),
                            InputLabel.buildLabelBox("password".tr),
                            const SizedBox(height: 10),
                            Container(
                              decoration: ThemeHelper().inputBoxDecorationShaddow(),
                              child: TextFormField(
                                obscureText: obscureText,
                                keyboardType: TextInputType.text,
                                validator: (val){
                                  if(val!.isEmpty){
                                    return "enter_password".tr;
                                  }
                                  else {return null;}
                                },
                                controller: _passwordController,
                                decoration: ThemeHelper().textInputDecorationWithSuffix('password'.tr,
                                    IconButton(onPressed: (){
                                      setState((){
                                        obscureText=!obscureText;
                                      });
                                    },
                                        icon: const Icon(Icons.remove_red_eye,
                                        size: 20,))),
                              ),
                            ),
                            const SizedBox(height: 20),

                            SmallButtonsWidget(title: "submit".tr, onPressed:
                                (){
                              if(_formKey.currentState!.validate()){
                                Get.back();
                              _handleSubmit(_emailController.text,_passwordController.text);


                              }

                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
          );
        },

      ).whenComplete(() {

      });
  }
  SizedBox _buildLogo() {
    return SizedBox(
      height: 130,
      child: Image.asset(ImageConstants.logoImage),
    );
  }

  void _handleSubmit(String email, String password) async{
    setState(() {
      _isLoading=true;
    });
    final resLogin=await LoginService.login(email: email,
        password: password);
    if(resLogin!=null){
      String? token=resLogin['token'];
      String? uid=resLogin['data']['id']?.toString();
      List? role=resLogin['data']['role'];
      bool assignedRole=false;
      if(role!=null){
        for(var e in role){
          if(e['name']=="Doctor"){
            assignedRole=true;
            break;
          }
        }
      }else{
        _handleErrorRes("not_been_assigned_role".tr);
        return;
      }
      if(!assignedRole){
        _handleErrorRes("not_been_assigned_role".tr);
        return;
      }
      String name="${resLogin['data']['f_name']} ${resLogin['data']['l_name']}";
      String clinicId="${resLogin['data']['assign_clinic_id']}";
      if(token==null||token==""||uid==null||uid==""||clinicId==""){
        _handleErrorRes("something_went_wrong".tr);
        return;
      }

      debugPrint("Doctor login token: $token");
      SharedPreferences preferences=await SharedPreferences.getInstance();
      await  preferences.setString(SharedPreferencesConstants.email,email);
      await  preferences.setString(SharedPreferencesConstants.password,password);
      await  preferences.setString(SharedPreferencesConstants.token,token);
      await  preferences.setString(SharedPreferencesConstants.uid,uid);
      await  preferences.setString(SharedPreferencesConstants.name,name);
      await  preferences.setBool(SharedPreferencesConstants.login,true);
      await  preferences.setString(SharedPreferencesConstants.clinicId,clinicId);
      await preferences.setString(
        SharedPreferencesConstants.loginProvider,
        'email',
      );

      await preferences.remove(SharedPreferencesConstants.googleLoginAt);

      UserService.updateFCM();
      Get.offAllNamed(RouteHelper.getHomePageRoute());

    }else{
      _openBottomSheetLogin();
    }
    setState(() {
      _isLoading=false;
    });
  }
  void _handleErrorRes(String msg){
    _openBottomSheetLogin();
    IToastMsg.showMessage(msg);
    setState(() {
      _isLoading=false;
    });
  }
}

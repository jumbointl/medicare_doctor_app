import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/dashboard_controller.dart';
import '../helper/currency_formatter_helper.dart';
import '../helper/logout_helper.dart';
import '../helper/route_helper.dart';
import '../model/currency_model.dart';
import '../model/dashboard_model.dart';
import '../model/doctors_model.dart';
import '../model/user_model.dart';
import '../service/configuration_service.dart';
import '../service/doctor_service.dart';
import '../service/user_service.dart';
import '../utilities/api_content.dart';
import '../utilities/image_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../controller/appointment_controller.dart';
import '../controller/notification_dot_controller.dart';
import '../model/appointment_model.dart';
import '../service/notification_seen_service.dart';
import '../utilities/colors_constant.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/drawer_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import 'package:star_rating/star_rating.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading=false;
  AppointmentController appointmentController=Get.put(AppointmentController());
  DashboardController dashboardController=Get.put(DashboardController());
  final ScrollController _scrollController=ScrollController();
  RefreshController refreshController=RefreshController();
  UserModel? userModel;
  DoctorsModel? doctorsModel;
  final NotificationDotController _notificationDotController=Get.find(tag: "notification_dot");

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkLoginAndLoad();
    });
  }

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final bool loggedIn =
        prefs.getBool(SharedPreferencesConstants.login) ?? false;
    final String token =
        prefs.getString(SharedPreferencesConstants.token) ?? '';
    final String uid =
        prefs.getString(SharedPreferencesConstants.uid) ?? '';

    return loggedIn && token.isNotEmpty && uid.isNotEmpty;
  }

  Future<void> _checkLoginAndLoad() async {
    final bool loggedIn = await _isLoggedIn();

    if (!loggedIn) {
      Get.offAllNamed(RouteHelper.getLoginPageRoute());
      return;
    }

    final bool googleExpired = await _isGoogleLoginExpired();
    if (googleExpired) {
      await forceLogoutDoctorApp();
      return;
    }

    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    getAdnSetData();
    appointmentController.getData();
    dashboardController.getData();
  }


  void _onRefresh() async{
    refreshController.refreshCompleted();
    appointmentController.getData();
    dashboardController.getData();
  }
  Future<bool> _isGoogleLoginExpired() async {
    final prefs = await SharedPreferences.getInstance();

    final provider =
        prefs.getString(SharedPreferencesConstants.loginProvider) ?? '';

    if (provider != 'google') {
      return false;
    }

    final loginAtRaw =
        prefs.getString(SharedPreferencesConstants.googleLoginAt) ?? '';

    if (loginAtRaw.isEmpty) {
      return true;
    }

    try {
      final loginAt = DateTime.parse(loginAtRaw);
      final now = DateTime.now();
      final difference = now.difference(loginAt);

      return difference.inDays >= 6;
    } catch (_) {
      return true;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: IDrawerWidget().buildDrawerWidget(userModel,_notificationDotController),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the drawer icon color to white
        ),
        centerTitle: true,
        backgroundColor: ColorResources.appBarColor,
        title:  Text("doctor".tr,
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 16
          ),
        ),
        actions: [IconButton(onPressed: (){}, icon:
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications,
                color: Colors.white,), onPressed: () {
              Get.toNamed(RouteHelper.getNotificationPageRoute());
            },
            ),
            Obx((){
              return _notificationDotController.isShow.value? const Positioned(
                top:10,
                right: 10,
                child: Icon(Icons.circle,
                  color: Colors.red,
                  size: 12,
                ),
              ):Container();
            })
          ],
        )

        )],
      ),
      backgroundColor: ColorResources.bgColor,
      body: _isLoading?const ILoadingIndicatorWidget():SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        header: null,
        footer: null,
        controller: refreshController,
        onRefresh: _onRefresh,
        onLoading: null,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          children:  [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
              ),
              color: ColorResources.cardBgColor,
              child:  Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("hello!".tr,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: (){
                                Get.toNamed(RouteHelper.getNotificationPageRoute());
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 18,
                                    child: Icon(Icons.notifications_none,
                                      size: 25,),
                                  ),
                                  Obx((){
                                    return _notificationDotController.isShow.value? const Positioned(
                                      top:5,
                                      right: 7,
                                      child: Icon(Icons.circle,
                                        color: Colors.red,
                                        size: 12,
                                      ),
                                    ):Container();
                                  })


                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(userModel?.fName??"",
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500
                          ),),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            StarRating(
                              mainAxisAlignment: MainAxisAlignment.center,
                              length: 5,
                              color:  doctorsModel?.averageRating==0?Colors.grey:Colors.amber,
                              rating: doctorsModel?.averageRating??0,
                              between: 5,
                              starSize: 15,
                              onRaitingTap: (rating) {
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'rating_review_text'.trParams({
                            'rating': '${doctorsModel?.averageRating ?? "--"}',
                            'count': '${doctorsModel?.numberOfReview ?? 0}',
                          }),
                          style:const TextStyle(
                              color: ColorResources.secondaryFontColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12
                          ),)
                      ],
                    ),
                    SizedBox(
                      height: 70,
                      width: 70,
                      child: ClipOval(
                          child:
                          userModel?.imageUrl==null||userModel?.imageUrl==""?
                          const Icon(Icons.person,
                            size: 50,):
                          ImageBoxFillWidget(imageUrl:"${ApiContents.imageUrl}/${userModel?.imageUrl}") ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeeCard("OPD".tr,doctorsModel?.opdFee.toString()??"0",doctorsModel?.clinicAppointment??0),
                _buildFeeCard("Video".tr,doctorsModel?.videoFee.toString()??"0",doctorsModel?.videoAppointment??0),
                _buildFeeCard("Emergency".tr,doctorsModel?.emgFee.toString()??"0",doctorsModel?.emergencyAppointment??0),
              ],
            ),
            Obx(() {
              if (!dashboardController.isError.value) { // if no any error
                if (dashboardController.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: ILoadingIndicatorWidget(),
                  );
                } else {
                  DashboardModel dashboardModel=dashboardController.dataModel.value;
                  return Column(
                    children: [
                      Row(
                        children: [
                          buildCard("appointment".tr,dashboardModel.totalAppointments?.toString()??"0",ImageConstants.totalAppointmentImage,Colors.green),
                          buildCard("today".tr,dashboardModel.totalTodayAppointment?.toString()??"0",ImageConstants.todayImage,Colors.orange),
                        ],
                      ),
                      Row(
                        children: [
                          buildCard("pending".tr,dashboardModel.totalPendingAppointment?.toString()??"0",ImageConstants.pendingImage,Colors.yellow),
                          buildCard("cancelled".tr,dashboardModel.totalCancelledAppointment?.toString()??"0",ImageConstants.cancelledImage,Colors.redAccent),
                        ],

                      ),
                      Row(
                        children: [
                          buildCard("confirmed".tr,dashboardModel.totalConfirmedAppointment?.toString()??"0",ImageConstants.confirmedImage,Colors.green),
                          buildCard("rejected".tr,dashboardModel.totalRejectedAppointment?.toString()??"0",ImageConstants.rejectedImage,Colors.redAccent),
                        ],

                      ),
                    ],
                  );
                }


              }else {
                return  Container();
              } //Error svg
            }
            ),


            Card(
              color: ColorResources.cardBgColor,
              elevation: .1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)
              ),
              child: ListTile(
                trailing: TextButton(
                    onPressed: (){
                      Get.toNamed(RouteHelper.getAppointmentPageRoute());
                    },
                    child:  Text("view_all_btn".tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                title:  Text("last_20_appointments".tr,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500
                  ),),
              ),
            ),
            Obx(() {
              if (!appointmentController.isError.value) { // if no any error
                if (appointmentController.isLoading.value) {
                  return const IVerticalListLongLoadingWidget();
                } else if (appointmentController.dataList.isEmpty) {
                  return  Text("no_appointment_found".tr,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14
                    ),
                  );
                }
                else {
                  return
                    buildAppointmentList(appointmentController.dataList);

                }
              }else {
                return   Container();
              } //Error svg
            })
          ],
        ),
      ),
    );
  }

  Expanded buildCard(String titleFirst,String numbers,String imageAsset,Color dotIconColor) {
    return Expanded(
      child:  SizedBox(
        height: 100,
        child: Card(
          elevation: 1,
          color: ColorResources.cardBgColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5)
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child:
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(titleFirst,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.circle,
                            size: 10,
                            color: dotIconColor),
                        const SizedBox(width: 10),
                        Text(numbers,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: ColorResources.btnColor,
                  child: Image.asset(imageAsset,
                    height: 25,
                    width: 25,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  ListView buildAppointmentList(dataList){
    return  ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: dataList.length,
        itemBuilder: (BuildContext ctxt, int index) {
          return _card( dataList[index]);
        });

  }

  Widget _card(AppointmentModel appointmentModel) {
    return Padding(
      padding: const EdgeInsets.only(top:3.0),
      child: GestureDetector(
        onTap: () async{
          Get.toNamed(RouteHelper.getAppointmentDetailsPageRoute(appId:appointmentModel.id.toString() ));
        },
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Card(
            color:ColorResources.cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: .1,
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  _appointmentDate(appointmentModel.date),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children:  [
                              Text("name:".tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  )),
                              Text(
                                  "${appointmentModel.pFName??""} ${appointmentModel.pLName??""} #${appointmentModel.id}" ,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  )),
                            ],
                          ),
                          Row(
                            children:  [
                              Text("time:".tr,
                                  style: TextStyle(
                                    fontFamily: 'OpenSans-Regular',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  )),
                              Text(appointmentModel.timeSlot??"",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  )),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                  child: Container(
                                      height: 1, color: Colors.grey[300])),
                              Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: appointmentModel.status ==
                                      "Pending"
                                      ? _statusIndicator(Colors.yellowAccent)
                                      : appointmentModel.status ==
                                      "Rescheduled"
                                      ? _statusIndicator(Colors.orangeAccent)
                                      : appointmentModel.status ==
                                      "Rejected"
                                      ? _statusIndicator(Colors.red)
                                      : appointmentModel.status ==
                                      "Confirmed"
                                      ? _statusIndicator(Colors.green)
                                      : appointmentModel.status ==
                                      "Completed"
                                      ? _statusIndicator(Colors.green)
                                      : null),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                                child: Text(
                                 ( appointmentModel.status??"--").tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:  [
                                    Text(
                                        (appointmentModel.type??"--").tr,
                                        style: const TextStyle(
                                          color: ColorResources.secondaryFontColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        )),
                                    Text("doctor_value".trParams({"value":"${appointmentModel.doctFName??"--"} ${appointmentModel.doctLName??"--"}"}) ,
                                        style: const TextStyle(
                                          color: ColorResources.secondaryFontColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        )),
                                    Text(
                                        appointmentModel.departmentTitle??"--",
                                        style: const TextStyle(
                                          color: ColorResources.secondaryFontColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        )),
                                  ],
                                ),
                              ),
                              // appointmentDetails[index].appointmentStatus=="Visited"?

                              //:Container(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _appointmentDate(date) {
    //  print(date);
    var appointmentDate = date.split("-");
    String appointmentMonth="";
    switch (int.parse(appointmentDate[1])) {
      case 1:
        appointmentMonth = "month_jan";
        break;
      case 2:
        appointmentMonth = "month_feb";
        break;
      case 3:
        appointmentMonth = "month_mar";
        break;
      case 4:
        appointmentMonth = "month_apr";
        break;
      case 5:
        appointmentMonth = "month_may";
        break;
      case 6:
        appointmentMonth = "month_jun";
        break;
      case 7:
        appointmentMonth = "month_jul";
        break;
      case 8:
        appointmentMonth = "month_aug";
        break;
      case 9:
        appointmentMonth = "month_sep";
        break;
      case 10:
        appointmentMonth = "month_oct";
        break;
      case 11:
        appointmentMonth = "month_nov";
        break;
      case 12:
        appointmentMonth = "month_dec";
        break;
    }

    return Column(
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text(appointmentMonth.tr,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            )),
        Text(appointmentDate[2],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: ColorResources.primaryColor,
              fontSize: 35,
            )),
        Text(appointmentDate[0],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            )),
      ],
    );
  }
  Widget _statusIndicator(color) {
    return CircleAvatar(radius: 4, backgroundColor: color);
  }

  void getAdnSetData() async{
    setState(() {
      _isLoading=true;
    });
    /*SharedPreferences sharedPreferences=await SharedPreferences.getInstance();
    final lgCode= sharedPreferences.getString(SharedPreferencesConstants.languageCode)??"en";
    if (kDebugMode) {
      print('SELECTED LANGUAGE CODE = $lgCode');
    }
    Get.updateLocale( Locale(lgCode));*/
    final res =await UserService.getData();
    userModel=res;
    final resD =await DoctorsService.getDataById();
    doctorsModel=resD;
    final resN=await NotificationSeenService.getDataById();
    if(resN!=null){
      if(resN.dotStatus==true){
        _notificationDotController.setDotStatus(true);
      }
    }
    final configRes=await ConfigurationService.getData();
    if(configRes!=null) {
      for (var e in configRes) {
        // 💰 Currency settings (platform independent)
        if (e.idName == "currency_symbol") {
          Currency.currencySymbol = e.value??"₹";
        }
        if (e.idName == "currency_position") {
          Currency.currencyPosition = e.value??"Right"; // left / right
        }
        if (e.idName == "number_of_decimal") {
          Currency. currencyDecimal = int.parse(e.value??"2");
        }
        if (e.idName == "decimal_separator") {
          Currency.currencyDecimalSeparator = e.value??".";
        }
        if (e.idName == "thousand_separator") {
          Currency.currencyThousandSeparator = e.value??",";
        }
      }
    }
    setState(() {
      _isLoading=false;
    });
    _requestNotificationPermission();
  }

  Expanded _buildFeeCard(String titleFirst,String fee, int enable) {
    return Expanded(
      child: Card(
        elevation: 1,
        color: ColorResources.cardBgColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5)
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(titleFirst,
                textAlign:  TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500
                ),
              ),
              const  SizedBox(height: 3),
              Text("fee_value".trParams({"value":CurrencyFormatterHelper.format(double.parse(fee))}),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500
                ),
              ),
              const   SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle,
                      size: 10,
                      color: enable==1?Colors.green:Colors.redAccent),
                  const SizedBox(width: 5),
                  Text(enable==1?"enable".tr:"disable".tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _requestNotificationPermission() {
    //HandleLocalNotification.showWithOutImageNotification("ssss","slsls");
    if (Platform.isAndroid) {
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      // HandleLocalNotification.showWithOutImageNotification("hii", "ddd",);
    } else if (Platform.isIOS) {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

}


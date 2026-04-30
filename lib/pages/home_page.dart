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
import '../controller/my_clinics_controller.dart';
import '../controller/notification_dot_controller.dart';
import '../model/appointment_model.dart';
import '../service/notification_seen_service.dart';
import '../utilities/colors_constant.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/drawer_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/appointment_tab_view.dart';
import '../widget/doctor_profile_per_clinic_form.dart';
import '../widget/doctor_profile_personal_form.dart';
import '../widget/loading_Indicator_widget.dart';
import 'package:star_rating/star_rating.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading=false;
  String _userId = '';
  AppointmentController appointmentController=Get.put(AppointmentController());
  DashboardController dashboardController=Get.put(DashboardController());
  final MyClinicsController myClinicsController = Get.put(MyClinicsController());
  Worker? _clinicSelectionWorker;
  Worker? _dashboardClinicWorker;

  /// Active range filter on the Dashboard tab.
  _DashRange _dashRange = _DashRange.today;
  DateTime? _dashCustomFrom;
  DateTime? _dashCustomTo;
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

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(SharedPreferencesConstants.uid) ?? '-1';
    if (mounted) {
      setState(() {
        _userId = uid;
      });
    } else {
      _userId = uid;
    }
    await myClinicsController.loadForUser(uid);

    // Refetch appointments whenever the user picks a different clinic.
    _clinicSelectionWorker?.dispose();
    _clinicSelectionWorker = ever(
      myClinicsController.selectedClinicId,
      (_) => _refetchAppointments(),
    );

    // Refetch dashboard whenever the clinic selection changes.
    _dashboardClinicWorker?.dispose();
    _dashboardClinicWorker = ever(
      myClinicsController.selectedClinicId,
      (_) => _refetchDashboard(),
    );

    _refetchAppointments();
    _refetchDashboard();
  }

  void _refetchDashboard() {
    final selected = myClinicsController.selectedClinicId.value;
    final range = _resolveDashRange();
    dashboardController.getData(
      clinicId: selected,
      from: range.fromIso,
      to: range.toIso,
    );
  }

  _DashRangeResolved _resolveDashRange() {
    final now = DateTime.now();
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    switch (_dashRange) {
      case _DashRange.today:
        final today = fmt(now);
        return _DashRangeResolved(today, today);
      case _DashRange.week:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return _DashRangeResolved(fmt(monday), fmt(sunday));
      case _DashRange.month:
        final firstDay = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        return _DashRangeResolved(fmt(firstDay), fmt(lastDay));
      case _DashRange.custom:
        final from = _dashCustomFrom == null ? null : fmt(_dashCustomFrom!);
        final to = _dashCustomTo == null ? null : fmt(_dashCustomTo!);
        return _DashRangeResolved(from, to);
      case _DashRange.all:
        return const _DashRangeResolved(null, null);
    }
  }

  Widget _buildDashboardRangeFilter() {
    Widget chip(_DashRange r, String label) {
      final selected = _dashRange == r;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: selected,
          // Match the rest of the app: solid brand colour + white text when
          // selected, light grey background otherwise.
          backgroundColor: Colors.grey.shade200,
          selectedColor: ColorResources.appBarColor,
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected
                  ? ColorResources.appBarColor
                  : Colors.grey.shade300,
            ),
          ),
          onSelected: (_) async {
            if (r == _DashRange.custom) {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDateRange: _dashCustomFrom != null && _dashCustomTo != null
                    ? DateTimeRange(
                        start: _dashCustomFrom!,
                        end: _dashCustomTo!,
                      )
                    : null,
              );
              if (picked == null) return;
              setState(() {
                _dashCustomFrom = picked.start;
                _dashCustomTo = picked.end;
                _dashRange = _DashRange.custom;
              });
            } else {
              setState(() => _dashRange = r);
            }
            _refetchDashboard();
          },
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(_DashRange.today, "tab_today".tr),
          chip(_DashRange.week, "this_week".tr),
          chip(_DashRange.month, "this_month".tr),
          chip(_DashRange.custom, "custom".tr),
          chip(_DashRange.all, "all".tr),
        ],
      ),
    );
  }

  void _refetchAppointments() {
    final selected = myClinicsController.selectedClinicId.value;
    final allCsv = myClinicsController.allClinicIdsCsv;
    appointmentController.getData(
      0,
      20,
      selected?.toString(),
      selected == null && allCsv.isNotEmpty ? allCsv : null,
    );
  }


  void _onRefresh() async{
    refreshController.refreshCompleted();
    _refetchAppointments();
    _refetchDashboard();
  }

  /// Async variant used by the new tabs (AppointmentTabView). Awaits the
  /// fetches so the SmartRefresher inside each tab can complete its spinner.
  Future<void> _onRefreshAsync() async {
    _refetchAppointments();
    _refetchDashboard();
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
    return DefaultTabController(
      length: 5,
      initialIndex: 0,
      child: Scaffold(
      drawer: IDrawerWidget().buildDrawerWidget(userModel,_notificationDotController),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the drawer icon color to white
        ),
        centerTitle: true,
        backgroundColor: ColorResources.appBarColor,
        title:  Text(
          "${"doctor".tr} ${userModel?.lName ?? ''}".trim(),
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
        bottom: TabBar(
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: const Icon(Icons.today), text: "tab_today".tr),
            Tab(icon: const Icon(Icons.history), text: "tab_past".tr),
            Tab(icon: const Icon(Icons.schedule), text: "tab_future".tr),
            Tab(icon: const Icon(Icons.person), text: "tab_profile".tr),
            Tab(icon: const Icon(Icons.dashboard), text: "tab_dashboard".tr),
          ],
        ),
      ),
      backgroundColor: ColorResources.bgColor,
      bottomNavigationBar: Obx(() {
        final clinics = myClinicsController.clinics;
        if (clinics.isEmpty) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_hospital,
                  color: ColorResources.appBarColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "${"clinic".tr}:",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      isExpanded: true,
                      value: myClinicsController.selectedClinicId.value,
                      items: [
                        if (clinics.length > 1)
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text("all_clinics".tr),
                          ),
                        ...clinics.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.clinicId,
                            child: Text(
                              c.clinicTitle ?? '#${c.clinicId}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        myClinicsController.setSelection(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      body: _isLoading
          ? const ILoadingIndicatorWidget()
          : TabBarView(
              children: [
                AppointmentTabView(
                  controller: appointmentController,
                  mode: AppointmentMode.today,
                  cardBuilder: _card,
                  onRefresh: _onRefreshAsync,
                ),
                AppointmentTabView(
                  controller: appointmentController,
                  mode: AppointmentMode.past,
                  cardBuilder: _card,
                  onRefresh: _onRefreshAsync,
                ),
                AppointmentTabView(
                  controller: appointmentController,
                  mode: AppointmentMode.future,
                  cardBuilder: _card,
                  onRefresh: _onRefreshAsync,
                ),
                _buildProfileTab(),
                _buildDashboardTab(),
              ],
            ),
    ));
  }

  Widget _buildProfileTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              labelColor: ColorResources.appBarColor,
              unselectedLabelColor: Colors.black54,
              indicatorColor: ColorResources.appBarColor,
              tabs: [
                Tab(text: "tab_personal".tr),
                Tab(text: "tab_per_clinic".tr),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                DoctorProfilePersonalForm(
                  userModel: userModel,
                  doctorsModel: doctorsModel,
                  onChanged: () {
                    getAdnSetData();
                  },
                ),
                DoctorProfilePerClinicForm(
                  doctorId: doctorsModel?.id ?? 0,
                  userId: _userId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SmartRefresher(
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
          const SizedBox(height: 8),
          _buildDashboardRangeFilter(),
          const SizedBox(height: 8),
          Obx(() {
            if (!dashboardController.isError.value) {
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
            } else {
              return Container();
            }
          }),
        ],
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
  @override
  void dispose() {
    _clinicSelectionWorker?.dispose();
    _dashboardClinicWorker?.dispose();
    super.dispose();
  }

  Widget _buildClinicSelector() {
    return Obx(() {
      if (myClinicsController.isLoading.value) {
        return const SizedBox.shrink();
      }
      final clinics = myClinicsController.clinics;
      if (clinics.isEmpty) return const SizedBox.shrink();
      // No combo when only one clinic — just show its name read-only.
      if (clinics.length == 1) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.local_hospital, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  clinics.first.clinicTitle ?? '-',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }
      final selected = myClinicsController.selectedClinicId.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.local_hospital, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<int?>(
                isExpanded: true,
                value: selected,
                items: <DropdownMenuItem<int?>>[
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text("All clinics".tr),
                  ),
                  for (final c in clinics)
                    DropdownMenuItem<int?>(
                      value: c.clinicId,
                      child: Text(
                        c.clinicTitle ?? '-',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) async {
                  await myClinicsController.setSelection(v);
                },
              ),
            ),
          ],
        ),
      );
    });
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

enum _DashRange { today, week, month, custom, all }

class _DashRangeResolved {
  final String? fromIso;
  final String? toIso;
  const _DashRangeResolved(this.fromIso, this.toIso);
}


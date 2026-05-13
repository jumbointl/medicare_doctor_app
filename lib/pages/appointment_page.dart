import '../controller/appoitnment_controller_serach.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/route_helper.dart';
import '../model/appointment_model.dart';
import '../service/patient_calls_service.dart';
import '../utilities/colors_constant.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/error_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/no_data_widgets.dart';
import '../widget/toast_message.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {

  String  serviceName ="Offline";
  AppointmentSearchController appointmentSearchController=Get.put(AppointmentSearchController());
 final TextEditingController _textEditingController=TextEditingController();
  final ScrollController _scrollController=ScrollController();
  RefreshController refreshController=RefreshController();
  int start=0;
  int end=20;
  bool _callingNext = false;

  @override
  void initState() {
    appointmentSearchController.getData();
    super.initState();
  }

  /// Panel TV (Fase 2): llama al próximo paciente con check-in de la clínica
  /// activa (`SharedPreferencesConstants.clinicId`). El backend pickea el
  /// menor token de hoy aún no llamado; si no hay, devuelve bizErr.
  Future<void> _llamarProximo() async {
    if (_callingNext) return;
    final prefs = await SharedPreferences.getInstance();
    final clinicRaw = prefs.getString(SharedPreferencesConstants.clinicId) ?? '';
    final clinicId = int.tryParse(clinicRaw);
    if (clinicId == null || clinicId <= 0) {
      IToastMsg.showMessage("no_active_clinic".tr);
      return;
    }
    if (mounted) setState(() => _callingNext = true);
    try {
      final res = await PatientCallsService.callNext(clinicId);
      if (res == null) {
        IToastMsg.showMessage("network_error".tr);
        return;
      }
      if (res['status'] == true) {
        final token = (res['data']?['token'] ?? '').toString();
        IToastMsg.showMessage("calling_token".trParams({'token': token}));
      } else {
        IToastMsg.showMessage(
            res['message']?.toString() ?? "no_pending_calls".tr);
      }
    } finally {
      if (mounted) setState(() => _callingNext = false);
    }
  }
  void _onRefresh() async{
    refreshController.refreshCompleted();

  }
  void _onLoading() async{
    if(mounted) {
      setState(() {
      });
    }
    refreshController.loadComplete();
    end+=20;
    appointmentSearchController.getMoreDataData(0, end, _textEditingController.text);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor:ColorResources.bgColor,
        appBar: AppBar(
          centerTitle: true,
          iconTheme: const IconThemeData(
            color: Colors.white, //change your color here
          ),
          elevation: 0,
          backgroundColor:ColorResources.appBarColor ,
          title:  Column(
            children: [
              Text("appointment".tr,
                style:const  TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400
                ),),
            ],
          ),
          actions: [
            // Panel TV — llamar próximo paciente. Toma clinic_id del local.
            IconButton(
              onPressed: _callingNext ? null : _llamarProximo,
              tooltip: "call_next_patient".tr,
              icon: _callingNext
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.phone_forwarded, color: Colors.white),
            ),
          ],
        ),
        body:
        Stack(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height,
              width: MediaQuery.sizeOf(context).width,
            ),
            Positioned(
              top: 10,
              left:0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onSubmitted: (value){
                              appointmentSearchController.getData(0,20,_textEditingController.text);
                            },
                            controller: _textEditingController,
                            decoration: InputDecoration(
                              hintText: 'search...'.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(left:8.0,right: 8),
                          child: GestureDetector(
                            onTap: (){
                              _textEditingController.clear();
                              appointmentSearchController.getData(0,20,_textEditingController.text);
                            },
                            child: const Icon(Icons.clear,
                              color: ColorResources.greyBtnColor,
                              size: 20,),
                          ),
                        )

                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider()
                ],
              ),
            ),

            Positioned(
              top: 90,
              bottom: 0,
              left:0,
              right: 0,
              child: SmartRefresher(
                scrollController:_scrollController,
                enablePullDown: false,
                enablePullUp: true,
                header: null,
                footer: null,
                controller: refreshController,
                onRefresh: _onRefresh,
                onLoading: _onLoading,
                child: Obx(() {
                  if (!appointmentSearchController.isError.value) { // if no any error
                    if (appointmentSearchController.isLoading.value) {
                      return const IVerticalListLongLoadingWidget();
                    } else if (appointmentSearchController.dataList.isEmpty) {
                      return const NoDataWidget();
                    }
                    else {
                      return   _upcomingAppointmentList(appointmentSearchController.dataList);
                    }
                  }else {
                    return  const IErrorWidget();
                  } //Error svg
                }
                ),
              ),
            ),

          ],
        )



    );
  }

  ListView _upcomingAppointmentList(List dataList) {
    return ListView.builder(
      controller: _scrollController,
        shrinkWrap: true,
        itemCount: dataList.length,
        itemBuilder: (BuildContext ctxt, int index) {
          return _card( dataList[index]);
        });
  }

  Widget _card(AppointmentModel appointmentModel) {
    return Padding(
      padding: const EdgeInsets.only(top:8.0),
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
                                  (appointmentModel.status??"--").tr,
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

}

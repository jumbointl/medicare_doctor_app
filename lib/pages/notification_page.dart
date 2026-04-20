import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/notification_controller.dart';
import '../controller/notification_dot_controller.dart';
import '../helper/date_time_helper.dart';
import '../helper/route_helper.dart';
import '../model/notification_model.dart';
import '../service/prescription_service.dart';
import '../service/user_service.dart';
import '../utilities/api_content.dart';
import '../widget/app_bar_widget.dart';
import '../widget/image_box_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/no_data_widgets.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading=false;
  late NotificationController notificationController;
  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: IAppBar.commonAppBar(title: "notification".tr),
          body: _isLoading?const ILoadingIndicatorWidget():_buildBody()
      ),
    );
  }
  Obx _buildBody(){
    return        Obx(() {
      if (!notificationController.isError.value) { // if no any error
        if (notificationController.isLoading.value) {
          return const ILoadingIndicatorWidget();
        } else if (notificationController.dataList.isEmpty) {
          return const NoDataWidget();
        } else {
          return
            _buildDataList(notificationController.dataList);
        }
      }else {
        return Container();
      } //Error svg
    }
    );
  }

  void getAndSetData() async{
    setState(() {
      _isLoading=true;
    });
    notificationController=Get.put(NotificationController());
    await UserService.updateNotificationLastSeen();
    setState(() {
      _isLoading=false;
    });
    final NotificationDotController notificationDotController=Get.find(tag: "notification_dot");
    notificationDotController.setDotStatus(false);

  }

  ListView _buildDataList(RxList dataList) {
    return ListView.builder(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        itemCount:dataList.length ,
        itemBuilder: (context,index){
          NotificationModel notificationModel=dataList[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 0,
            child: ListTile(
              onTap:(){
                if(notificationModel.prescriptionId!=null) {
                  getAndOpenPre(notificationModel.prescriptionId.toString());
                }
                else  if(notificationModel.appointmentId!=null) {
                  Get.toNamed(RouteHelper.getAppointmentDetailsPageRoute(appId: notificationModel.appointmentId.toString()));
                }
              },
              isThreeLine: true,
              leading:  notificationModel.image==null|| notificationModel.image==""?
              null:
              SizedBox(
                width: 50,
                child: ImageBoxFillWidget(
                  imageUrl:
                  "${ApiContents.imageUrl}/${notificationModel.image}",
                  boxFit: BoxFit.contain,),
              ),
              title: Text("${notificationModel.id}${notificationModel.title}",
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15
                ),),
              subtitle:  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(notificationModel.body??"",
                    style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14
                    ),),
                  Text(DateTimeHelper.getDataFormat(notificationModel.createdAt),
                      style:  const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14
                      ))
                ],
              ),
            ),
          );
        });
  }
  void getAndOpenPre(String? pId) async{
    setState(() {
      _isLoading=true;
    });
    final prescription=await PrescriptionService.getDataByPrescriptionId(prescriptionId:pId??"");

    Get.toNamed(RouteHelper.getPrescriptionPageRoute());

    if(prescription!=null){
      if(prescription.pdfFile!=null&&prescription.pdfFile!=""){
        await launchUrl(Uri.parse("${ApiContents.imageUrl}/${prescription.pdfFile}"));
      }else{
       await  launchUrl(Uri.parse("${ApiContents.prescriptionUrl}/${prescription.id}"));
      }
    }

    setState(() {
      _isLoading=false;
    });
  }
}

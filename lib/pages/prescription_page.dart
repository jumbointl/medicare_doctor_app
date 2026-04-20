import 'package:url_launcher/url_launcher.dart';
import '../controller/prescription_controller.dart';
import '../helper/date_time_helper.dart';
import '../helper/route_helper.dart';
import '../model/prescription_model.dart';
import '../utilities/api_content.dart';
import '../widget/app_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/prescription_service.dart';
import '../utilities/colors_constant.dart';
import '../widget/error_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/no_data_widgets.dart';
import '../widget/toast_message.dart';

class PrescriptionPage extends StatefulWidget {
  const PrescriptionPage({super.key});

  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  PrescriptionController prescriptionController=Get.put(PrescriptionController());
  final TextEditingController _textEditingController=TextEditingController();
  final ScrollController _scrollController=ScrollController();
bool _isLoading=false;
  @override
  void initState() {
    // TODO: implement initState
    prescriptionController.getDataByDoctorId("");
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IAppBar.commonAppBar(title: "prescription".tr),
      body: _isLoading?const ILoadingIndicatorWidget(): ListView(
        controller: _scrollController,

        children: [   const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onSubmitted: (value){
                      prescriptionController.getDataByDoctorId(_textEditingController.text);
                      // appointmentSearchController.getData(0,20,_textEditingController.text);
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
                      prescriptionController.getDataByDoctorId("");
                      //    appointmentSearchController.getData(0,20,_textEditingController.text);
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
          Obx(() {
            if (!prescriptionController.isError.value) { // if no any error
              if (prescriptionController.isLoading.value) {
                return const IVerticalListLongLoadingWidget();
              } else if (prescriptionController.dataList.isEmpty) {
                return const NoDataWidget();
              }
              else {
                return   dataList(prescriptionController.dataList);
              }
            }else {
              return  const IErrorWidget();
            } //Error svg
          }
          ),
        ],
      )
    );
  }

  Widget dataList(RxList<PrescriptionModel> dataList) {
    return ListView.builder(
       controller: _scrollController,
      shrinkWrap: true,
        itemCount: dataList.length,
        itemBuilder: (context,index){
        PrescriptionModel prescriptionModel =dataList[index];
      return Card(
        color:ColorResources.cardBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: .1,
        child: ListTile(

          title: Text("${prescriptionModel.patientFName} ${prescriptionModel.patientLName}",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500
          ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              Text("prescription_id".trParams({"id":"${prescriptionModel.id}"}),
                style:const  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400
                ),
              ),
              const SizedBox(height: 3),
          Text("appointment_id".trParams({"id":"${prescriptionModel.appointmentId}"}),

                style:const  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400
                ),
              ),
              const SizedBox(height: 3),
              Text(DateTimeHelper.getDataFormat(prescriptionModel.createdAt),
                style:const  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400
                ),
              ),
              Row(
                children: [
                  IconButton(onPressed: ()async{
                    if(prescriptionModel.pdfFile!=null&&prescriptionModel.pdfFile!=""){
                      await  launchUrl(Uri.parse("${ApiContents.imageUrl}/${prescriptionModel.pdfFile}"),
                      mode: LaunchMode.externalApplication
                      );
                    }else{
                      await  launchUrl(Uri.parse("${ApiContents.prescriptionUrl}/${prescriptionModel.id}",
                      ),
                          mode: LaunchMode.externalApplication);
                    }
                  }, icon: const Icon(Icons.download,
                    color: Colors.green,
                    size: 20,
                  )),
                  prescriptionModel.pdfFile!=null?Container():   IconButton(onPressed: (){
                    Get.toNamed(RouteHelper.getAddPrescriptionPageRoute(appId: prescriptionModel.appointmentId.toString(), prescriptionId: prescriptionModel.id.toString()));
                  }, icon: const Icon(Icons.edit,
                    color: Colors.grey,
                    size: 20,
                  )),

                  IconButton(onPressed: (){
                    _openDialogDeletePrescriptionBox(prescriptionModel.id.toString());
                  }, icon: const Icon(Icons.delete,
                    color: Colors.redAccent,
                    size: 20,
                  )),

                ],
              ),
            ],
          ),
        ),
      );
    });
  }
  Future<dynamic> _openDialogDeletePrescriptionBox(String id) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title:   Text(
            "delete".tr,
            textAlign:  TextAlign.center,
            style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content:  Column(
            mainAxisSize: MainAxisSize.min,
            children:  [
              Text("delete_prescription_box_value".trParams({"id": id}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14)),
              const  SizedBox(height: 10),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.btnColorRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Change this value to adjust the border radius
                  ),
                ),
                child:  Text("no".tr,
                    style:
                    TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400, fontSize: 12)),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.btnColorGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Change this value to adjust the border radius
                  ),
                ),
                child:  Text(
                  "yes".tr,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400, fontSize: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleDeletePrescription(id);

                }),
            // usually buttons at the bottom of the dialog
          ],
        );
      },
    );
  }
  void _handleDeletePrescription(String id) async{
    setState(() {
      _isLoading=true;
    });
    final res=await  PrescriptionService.deleteData(
        id: id
    );
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      prescriptionController.getDataByDoctorId("");
    }
    setState(() {
      _isLoading=false;
    });
  }
}

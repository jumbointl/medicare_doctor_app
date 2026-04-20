import '../controller/patient_file_controller.dart';
import '../model/patient_file_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helper/date_time_helper.dart';
import '../utilities/api_content.dart';
import '../widget/app_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utilities/colors_constant.dart';
import '../widget/error_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/no_data_widgets.dart';


class PatientFilePage extends StatefulWidget {
  final String? patientId;

  const PatientFilePage({super.key,this.patientId});

  @override
  State<PatientFilePage> createState() => _PatientFilePageState();
}

class _PatientFilePageState extends State<PatientFilePage> {
  PatientFileController patientFileController=Get.put(PatientFileController());
  final TextEditingController _textEditingController=TextEditingController();
  final ScrollController _scrollController=ScrollController();
  bool isLoading = false;
  @override
  void initState() {
    // TODO: implement initState
    patientFileController.getData(widget.patientId??"","");
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: IAppBar.commonAppBar(title: "Patient Files"),
        body: isLoading?const ILoadingIndicatorWidget(): ListView(
          controller: _scrollController,

          children: [   const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onSubmitted: (value){
                        patientFileController.getData(widget.patientId??"",_textEditingController.text);
                        // appointmentSearchController.getData(0,20,_textEditingController.text);
                      },
                      controller: _textEditingController,
                      decoration: InputDecoration(
                        hintText: 'Search...',
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
                        patientFileController.getData(widget.patientId??"","");
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
              if (!patientFileController.isError.value) { // if no any error
                if (patientFileController.isLoading.value) {
                  return const IVerticalListLongLoadingWidget();
                } else if (patientFileController.dataList.isEmpty) {
                  return const NoDataWidget();
                }
                else {
                  return   _buildList(patientFileController.dataList);
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

  Widget _buildList(RxList dataList) {
    return ListView.builder(
        padding: EdgeInsets.zero,
        controller: _scrollController,
        shrinkWrap: true,
        itemCount:dataList.length ,
        itemBuilder: (context,index){
          PatientFileModel patientFileModel=dataList[index];
          //   print(testimonialModel.image);
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 0,
            child: ListTile(
                onTap: ()async {
                  if(patientFileModel.fileUrl!=null&&patientFileModel.fileUrl!=""){
                    final fileUrl="${ApiContents.imageUrl}/${patientFileModel.fileUrl}";
                    await launchUrl(Uri.parse(fileUrl));
                  }

                },
                trailing: const Icon(Icons.download,
                  size: 20,
                  color: ColorResources.iconColor,
                ),
                subtitle:   Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3),
                    Text("${patientFileModel.pFName} ${patientFileModel.pLName}",
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14
                      ),),
                    const SizedBox(height: 3),
                    Text(DateTimeHelper.getDataFormat(patientFileModel.createdAt??""),
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14
                      ),),
                  ],
                ),
                title:     Text(patientFileModel.fileName??"",
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14
                  ),)
            ),
          );
        });
  }

}

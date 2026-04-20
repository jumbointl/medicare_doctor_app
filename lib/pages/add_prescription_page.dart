import 'dart:io';
import '../utilities/sharedpreference_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/prescription_controller.dart';
import '../model/appointment_model.dart';
import '../model/medication.dart';
import '../model/medicine_model.dart';
import '../model/prescription_model.dart';
import '../service/appointment_Service.dart';
import '../service/medication_service.dart';
import '../service/prescription_service.dart';
import '../widget/app_bar_widget.dart';
import '../widget/bottom_button.dart';
import '../widget/input_label_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/toast_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import '../helper/theme_helper.dart';
import '../utilities/colors_constant.dart';
import '../widget/button_widget.dart';

class AddPrescriptionPage extends StatefulWidget {
   final String? appId;
   final String? prescriptionId;
    const AddPrescriptionPage({super.key,required this.appId,this.prescriptionId});

  @override
  State<AddPrescriptionPage> createState() => _AddPrescriptionPageState();
}

class _AddPrescriptionPageState extends State<AddPrescriptionPage> {
  PrescriptionController prescriptionController=Get.find<PrescriptionController>();
  final TextEditingController _testController = TextEditingController();
  final TextEditingController _adviceController = TextEditingController();
  final TextEditingController _problemDescController =TextEditingController();
  final TextEditingController _foodAllergiesController = TextEditingController();
  final TextEditingController _tendencyBleedController = TextEditingController();
  final TextEditingController _heartDiseaseController =TextEditingController();
  final TextEditingController _bloodPressureController = TextEditingController();
  final TextEditingController _diabeticController = TextEditingController();
  final TextEditingController _surgeryController =TextEditingController();
  final TextEditingController _accidentController = TextEditingController();
  final TextEditingController _othersController = TextEditingController();
  final TextEditingController _medicalHistoryController =TextEditingController();
  final TextEditingController _currentMedicationController =TextEditingController();
  final TextEditingController _femalePregnancyController = TextEditingController();
  final TextEditingController _breastFeedingController = TextEditingController();
  final TextEditingController _pulseRateController = TextEditingController();
  final TextEditingController _temperatureController =TextEditingController();
  final TextEditingController _nextVisitController =TextEditingController();
  final TextEditingController _medicineNameController =TextEditingController();
  final TextEditingController _notesController =TextEditingController();
  String selectedDosage="1";
  String selectedDuration="For 3 days";
  String selectedTime="After Meal";
  String selectedDoseInterval="Once a day";
  bool _isLoading=false;
  List <Medication> medicationList=[];
   List<MedicineModel> _suggestions = [];
   AppointmentModel? appointmentModel;
  PrescriptionModel? prescriptionModel;
@override
  void initState() {
    // TODO: implement initState
  getAndSetData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: IBottomNavBarWidget(
        title: "save".tr,
        onPressed: medicationList.isEmpty||_isLoading?null:(){
          if(widget.prescriptionId!=""&&widget.prescriptionId!=null){
            _handleUpdateData();
          }else{
            _handleAddData();
          }

        },
      ),
      floatingActionButton:
     FloatingActionButton(
        backgroundColor: ColorResources.btnColor,
        onPressed: _isLoading?null:() {
        _openBottomSheetAddMedicine();
        },
        shape:  const CircleBorder(),
        child:  const Icon(Icons.add,
          color: Colors.white,),
      ),
      appBar: IAppBar.commonAppBar(title: widget.prescriptionId!=""&&widget.prescriptionId!=null?"update_prescription".tr:"Add Prescription".tr),
      body: _buildBody(),
    );
  }
  StatelessWidget _buildBody() {
    return _isLoading?const ILoadingIndicatorWidget():ListView(
      padding:const EdgeInsets.all(8),
      children: [
        ListView.builder(
            shrinkWrap: true,
            itemCount: medicationList.length,
            itemBuilder: (context,index){
              Medication medication=medicationList[index];
          return buildMedicineList(medication,index);
        }),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("problem".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            maxLines: 5,
            keyboardType: TextInputType.name,
            validator: null,
            controller: _problemDescController,
            decoration: ThemeHelper().textInputDecoration('problem'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("test".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            maxLines: 5,
            keyboardType: TextInputType.name,
            validator: null,
            controller: _testController,
            decoration: ThemeHelper().textInputDecoration('test'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("advice".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            maxLines: 5,
            keyboardType: TextInputType.name,
            validator: null,
            controller: _adviceController,
            decoration: ThemeHelper().textInputDecoration('advice'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("next_visit".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            keyboardType:Platform.isIOS? const TextInputType.numberWithOptions(decimal: true, signed: true)
                : TextInputType.number,
            validator: null,
            controller:_nextVisitController ,
            decoration: ThemeHelper().textInputDecoration('next_visit_in_day'.tr),
          ),
        ),
        const SizedBox(height: 10),
       InputLabel.buildLabelBox("food_allergies".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _foodAllergiesController,
            decoration: ThemeHelper().textInputDecoration('food_allergies'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("tendency_to_bleed".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _tendencyBleedController,
            decoration: ThemeHelper().textInputDecoration('tendency_to_bleed'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("heart_disease".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _heartDiseaseController,
            decoration: ThemeHelper().textInputDecoration('heart_disease'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("blood_pressure".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _bloodPressureController,
            decoration: ThemeHelper().textInputDecoration('blood_pressure'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("diabetic".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _diabeticController,
            decoration: ThemeHelper().textInputDecoration('diabetic'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("surgery".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _surgeryController,
            decoration: ThemeHelper().textInputDecoration('surgery'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("accident".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _accidentController,
            decoration: ThemeHelper().textInputDecoration('accident'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("others".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _othersController,
            decoration: ThemeHelper().textInputDecoration('others'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("medical_history".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _medicalHistoryController,
            decoration: ThemeHelper().textInputDecoration('medical_history'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("current_medication".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _currentMedicationController,
            decoration: ThemeHelper().textInputDecoration('current_medication'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("female_pregnancy".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _femalePregnancyController,
            decoration: ThemeHelper().textInputDecoration('female_pregnancy'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("breast_feeding".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _breastFeedingController,
            decoration: ThemeHelper().textInputDecoration('breast_feeding'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("pulse_rate".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _pulseRateController,
            decoration: ThemeHelper().textInputDecoration('pulse_rate'.tr),
          ),
        ),
        const SizedBox(height: 10),
        InputLabel.buildLabelBox("temperature".tr),
        const SizedBox(height: 10),
        Container(
          decoration: ThemeHelper().inputBoxDecorationShaddow(),
          child: TextFormField(
            keyboardType: TextInputType.name,
            validator: null,
            controller: _temperatureController,
            decoration: ThemeHelper().textInputDecoration('temperature'.tr),
          ),
        ),

      ],
    );
  }

  // Function to get suggestions based on the query
  Future<List<MedicineModel>> _getSuggestions(String query) async {
    // Filter medicines based on title and notes
    final List<MedicineModel> matches = _suggestions.where((medicine) {
      return medicine.title.toLowerCase().contains(query.toLowerCase());
    }).toList();
    return matches;
  }
  Future<dynamic> _openBottomSheetAddMedicine(){
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Text('add_medicine'.tr,
                              style: const  TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                              )),
                          const SizedBox(height: 20),
                          TypeAheadField<MedicineModel>(
                            controller: _medicineNameController,
                            suggestionsCallback:_getSuggestions,
                            builder: (context, controller, focusNode) {
                              return  Container(
                                decoration: ThemeHelper().inputBoxDecorationShaddow(),
                                child: TextFormField(
                                  keyboardType:Platform.isIOS? const TextInputType.numberWithOptions(decimal: true, signed: true)
                                      : TextInputType.name,
                                  validator: null,
                                  controller:controller ,
                                  focusNode: focusNode,
                                  decoration: ThemeHelper().textInputDecoration('medicine'.tr),
                                ),
                              );
                            },
                            itemBuilder: (context, medicineModel) {
                              return ListTile(
                                title: Text(medicineModel.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14
                                  ),
                                ),
                                subtitle:  Text(medicineModel.notes,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13
                                  ),
                                ),
                              );
                            },
                            onSelected: (text) {
                              _medicineNameController.text=text.title;
                              setState(() {
                      
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          InputLabel.buildLabelBox("dosage".tr),
                          const SizedBox(height: 10),
                          InputDecorator(
                            decoration:  ThemeHelper().textInputDecoration('dosage*'.tr),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                padding: EdgeInsets.zero,
                                value: selectedDosage,
                                hint:  Text('dosage'.tr,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500
                                    )),
                                items: <String>['1', '2', '3','4','5','6']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedDosage = newValue??"";
                                  });
                                },
                                isExpanded: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InputLabel.buildLabelBox("duration".tr),
                          const SizedBox(height: 10),
                          InputDecorator(
                            decoration:  ThemeHelper().textInputDecoration('duration*'.tr),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                padding: EdgeInsets.zero,
                                value: selectedDuration,
                                hint:  Text('duration'.tr,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500
                                    )),
                                items: <String>['For 1 day', 'For 2 days', 'For 3 days','For 7 days','For 15 days','For 1 month']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value.tr),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedDuration = newValue??"";
                                  });
                                },
                                isExpanded: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InputLabel.buildLabelBox("time".tr),
                          const SizedBox(height: 10),
                          InputDecorator(
                            decoration:  ThemeHelper().textInputDecoration('time*'.tr),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                padding: EdgeInsets.zero,
                                value: selectedTime,
                                hint:  Text('time'.tr,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500
                                    )),
                                items: <String>['After Meal','Before Meal']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value.tr),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedTime = newValue??"";
                                  });
                                },
                                isExpanded: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InputLabel.buildLabelBox("dose_interval".tr),
                          const SizedBox(height: 10),
                          InputDecorator(
                            decoration:  ThemeHelper().textInputDecoration('dose_interval*'.tr),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                padding: EdgeInsets.zero,
                                value: selectedDoseInterval,
                                hint:  Text('dose_interval'.tr,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500
                                    )),
                                items: <String>['Once a day','Every Morning & Evening','3 Times a day','4 Times a day']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value.tr),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedDoseInterval = newValue??"";
                                  });
                                },
                                isExpanded: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InputLabel.buildLabelBox("notes".tr),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ThemeHelper().inputBoxDecorationShaddow(),
                            child: TextFormField(
                              keyboardType: TextInputType.name,
                              validator: null,
                              controller: _notesController,
                              decoration: ThemeHelper().textInputDecoration('notes'.tr),
                            ),
                          ),
                          const SizedBox(height: 20),
                      
                          SmallButtonsWidget(title: "add".tr, onPressed:
                              (){
                            if(_medicineNameController.text.isEmpty){
                              IToastMsg.showMessage("select_medicine".tr);
                              return;
                            }
                            bool isNeedToAdd=true;
                            Medication medication=Medication(medicineName: _medicineNameController.text,
                                dosage: selectedDosage,
                                duration: selectedDuration,
                                time: selectedTime,
                                doseInterval: selectedDoseInterval,
                                notes: _notesController.text);
                            for(var e in medicationList){
                              if(e.medicineName==medication.medicineName){
                                isNeedToAdd=false;
                                IToastMsg.showMessage("medicine_name_already_exists".tr);
                                break;
                              }
                            }
                            if(isNeedToAdd==false){return;}
                                medicationList.add(medication);
                                Get.back();
                             clearData();

                              }),
                        ],
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

  Card buildMedicineList(Medication medication,int index) {
    return Card(
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: ColorResources.cardBgColor,
      child: ListTile(
        trailing: IconButton(onPressed: (){
          _openDialogBox(medication.medicineName,index);
        }, icon: const Icon(Icons.delete,
        color: Colors.redAccent,
        )),
        title: Text("${index+1} - ${medication.medicineName}",
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("dosage_value".trParams({"value":medication.dosage}),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400
                )),
            const SizedBox(height: 5),
            Text("duration_value".trParams({"value":medication.duration}),
                style:  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400
                )),
            const SizedBox(height: 5),
             Text("time_value".trParams({"value":medication.time}),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400
                )),
            const SizedBox(height: 5),
           Text("dose_interval_value".trParams({"value":medication.doseInterval}),
              style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400
              )),
            medication.notes==""?Container():  Padding(
              padding: const EdgeInsets.only(top:5.0),
              child: Row(
                children: [
                   Text("notes_value".trParams({"value":medication.notes}),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400
                      )),
                  Flexible(
                    child: Text(medication.notes,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  Future<dynamic> _openDialogBox(String medicineName,index) {
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
              Text("are_you_sure_want_to_delete".trParams({"value":medicineName}),
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
                  medicationList.removeAt(index);
                  setState(() {

                  });
                }),
            // usually buttons at the bottom of the dialog
          ],
        );
      },
    );
  }
  void getAndSetData()async {
  setState(() {
    _isLoading=true;
  });
  SharedPreferences preferences=await SharedPreferences.getInstance();
  String clinicId=preferences.getString(SharedPreferencesConstants.clinicId)??"";
final res=await MedicationService.getData(clinicId);
    if(res!=null){
      _suggestions=res;
    }

  final resApp=await AppointmentService.getDataById(appId: widget.appId);
  if(resApp!=null){
    appointmentModel=resApp;
  }
  if(widget.prescriptionId!=""&&widget.prescriptionId!=null){

    final resPresc=await PrescriptionService.getDataByPrescriptionId(prescriptionId: widget.prescriptionId??"");
    if(resPresc!=null){
      prescriptionModel=resPresc;
       _testController.text = prescriptionModel?.test??"";
      _adviceController.text =prescriptionModel?.advice??"";
     _problemDescController.text =prescriptionModel?.problemDesc??"";
      _foodAllergiesController.text =prescriptionModel?.foodAllergies??"";
      _tendencyBleedController.text = prescriptionModel?.tendencyBleed??"";
      _heartDiseaseController.text =prescriptionModel?.heartDisease??"";
       _bloodPressureController.text = prescriptionModel?.bloodPressure??"";
       _diabeticController.text = prescriptionModel?.diabetic??"";
      _surgeryController.text =prescriptionModel?.surgery??"";
      _accidentController.text = prescriptionModel?.accident??"";
       _othersController.text =prescriptionModel?.others??"";
       _medicalHistoryController.text =prescriptionModel?.medicalHistory??"";
     _currentMedicationController.text =prescriptionModel?.currentMedication??"";
       _femalePregnancyController.text = prescriptionModel?.femalePregnancy??"";
      _breastFeedingController.text = prescriptionModel?.breastFeeding??"";
       _pulseRateController.text = prescriptionModel?.pulseRate??"";
      _temperatureController.text =prescriptionModel?.temperature??"";
       _nextVisitController.text =prescriptionModel?.nextVisit??"";
       _notesController.text =prescriptionModel?.notes??"";
       if(prescriptionModel?.items!=null){
         final List dataList=prescriptionModel!.items!;
         medicationList.clear();
         for( var e in dataList){

           medicationList.add(
               Medication(
                   medicineName: e['medicine_name'],
                   dosage: e['dosage']??"",
                   duration: e['duration']??"",
                   time: e['time']??"",
                   doseInterval:e['dose_interval']??"",
                   notes: e['notes']??"",));
         }
       }
    }  
  }
  setState(() {
    _isLoading=false;
  });
  }
  void clearData() {
    selectedDosage="1";
    selectedDuration="For 3 days";
    selectedTime="After Meal";
    selectedDoseInterval="Once a day";
    _medicineNameController.text="";
    _notesController.text="";
    setState(() {

    });
  }
  void _handleAddData() async{
    setState(() {
      _isLoading=true;
    });
    final res=await  PrescriptionService.addData(
         patientId: appointmentModel?.patientId.toString()??"",
        test: _testController.text,
        advice: _adviceController.text,
        problemDesc: _problemDescController.text,
        foodAllergies: _foodAllergiesController.text,
        tendencyBleed: _tendencyBleedController.text,
        heartDisease: _heartDiseaseController.text,
        bloodPressure: _bloodPressureController.text,
        diabetic: _diabeticController.text,
        surgery: _surgeryController.text,
        accident: _accidentController.text,
        others: _othersController.text,
        medicalHistory: _medicalHistoryController.text,
        currentMedication: _currentMedicationController.text,
        femalePregnancy: _femalePregnancyController.text,
        breastFeeding: _breastFeedingController.text,
        pulseRate: _pulseRateController.text,
        temperature: _temperatureController.text,
        nextVisit: _nextVisitController.text,
      appointmentId: widget.appId??"",
      medicationList: medicationList
    );
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      prescriptionController.getData(appointmentId: widget.appId??"");
      Get.back();
    }
    setState(() {
      _isLoading=false;
    });
  }
  void _handleUpdateData() async{
    setState(() {
      _isLoading=true;
    });
    final res=await  PrescriptionService.updateData(
       id: widget.prescriptionId??"",
        test: _testController.text,
        advice: _adviceController.text,
        problemDesc: _problemDescController.text,
        foodAllergies: _foodAllergiesController.text,
        tendencyBleed: _tendencyBleedController.text,
        heartDisease: _heartDiseaseController.text,
        bloodPressure: _bloodPressureController.text,
        diabetic: _diabeticController.text,
        surgery: _surgeryController.text,
        accident: _accidentController.text,
        others: _othersController.text,
        medicalHistory: _medicalHistoryController.text,
        currentMedication: _currentMedicationController.text,
        femalePregnancy: _femalePregnancyController.text,
        breastFeeding: _breastFeedingController.text,
        pulseRate: _pulseRateController.text,
        temperature: _temperatureController.text,
        nextVisit: _nextVisitController.text,
        medicationList: medicationList
    );
    if (res != null) {
      IToastMsg.showMessage("success".tr);
    }
    setState(() {
      _isLoading=false;
    });
  }

}


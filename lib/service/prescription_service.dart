import '../model/medication.dart';
import '../model/prescription_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/get_req_helper.dart';
import '../helper/post_req_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class PrescriptionService{

   static const  addPrescriptionUrl=   ApiContents.addPrescriptionUrl;

   static const  deletePrescriptionUrl=   ApiContents.deletePrescriptionUrl;
   static const  updatePrescriptionUrl=   ApiContents.updatePrescriptionUrl;
   static const  getPrescriptionUrl=   ApiContents.getPrescriptionUrl;
   static const  prescriptionUrl=   ApiContents.prescriptionSearchUrl;


   static Future deleteData(
       {
         required String id
       }
       )async{

     final res=await PostService.postReq(deletePrescriptionUrl, {"id":id});
     return res;
   }
   static Future addData(
       {
         required String appointmentId,
         required List<Medication> medicationList,
         required String patientId,
         required String test,
         required String advice,
         required String problemDesc,
         required String foodAllergies,
         required String tendencyBleed,
         required String heartDisease,
         required String bloodPressure,
         required String diabetic,
         required String surgery,
         required String accident,
         required String others,
         required String medicalHistory,
         required String currentMedication,
         required String femalePregnancy,
         required String breastFeeding,
         required String pulseRate,
         required String temperature,
         required String nextVisit,
       }
       )async{
     // Convert the List<Medication> to a List<Map<String, dynamic>> format
     List<Map<String, dynamic>> medicines = medicationList.map((med) {
       return {
         "medicine_name": med.medicineName,
         "dosage": med.dosage, // Assuming Medication class has a dosage field
         "duration": med.duration,
         "time": med.time,
         "dose_interval": med.doseInterval, // Adjust field names as necessary
         "notes": med.notes,
       };
     }).toList();
     Map body={
       "appointment_id": appointmentId,
       "patient_id": patientId,
       "test": test,
       "advice": advice,
       "problem_desc": problemDesc,
       "food_allergies": foodAllergies,
       "tendency_bleed": tendencyBleed,
       "heart_disease": heartDisease,
       "blood_pressure": bloodPressure,
       "diabetic": diabetic,
       "surgery": surgery,
       "accident": accident,
       "others": others,
       "medical_history": medicalHistory,
       "current_medication": currentMedication,
       "female_pregnancy": femalePregnancy,
       "breast_feeding": breastFeeding,
       "pulse_rate": pulseRate,
       "temperature": temperature,
       "next_visit": nextVisit,
       "medicines": medicines,
     };
     final res=await PostService.postReq(addPrescriptionUrl, body);
     return res;
   }
   static Future updateData(
       {
         required String id,
         required List<Medication> medicationList,
         required String test,
         required String advice,
         required String problemDesc,
         required String foodAllergies,
         required String tendencyBleed,
         required String heartDisease,
         required String bloodPressure,
         required String diabetic,
         required String surgery,
         required String accident,
         required String others,
         required String medicalHistory,
         required String currentMedication,
         required String femalePregnancy,
         required String breastFeeding,
         required String pulseRate,
         required String temperature,
         required String nextVisit,
       }
       )async{
     // Convert the List<Medication> to a List<Map<String, dynamic>> format
     List<Map<String, dynamic>> medicines = medicationList.map((med) {
       return {
         "medicine_name": med.medicineName,
         "dosage": med.dosage, // Assuming Medication class has a dosage field
         "duration": med.duration,
         "time": med.time,
         "dose_interval": med.doseInterval, // Adjust field names as necessary
         "notes": med.notes,
       };
     }).toList();
     Map body={
       "id": id,
       "test": test,
       "advice": advice,
       "problem_desc": problemDesc,
       "food_allergies": foodAllergies,
       "tendency_bleed": tendencyBleed,
       "heart_disease": heartDisease,
       "blood_pressure": bloodPressure,
       "diabetic": diabetic,
       "surgery": surgery,
       "accident": accident,
       "others": others,
       "medical_history": medicalHistory,
       "current_medication": currentMedication,
       "female_pregnancy": femalePregnancy,
       "breast_feeding": breastFeeding,
       "pulse_rate": pulseRate,
       "temperature": temperature,
       "next_visit": nextVisit,
       "medicines": medicines,
     };
     final res=await PostService.postReq(updatePrescriptionUrl, body);
     return res;
   }
   static List<PrescriptionModel> dataFromJson (jsonDecodedData){

     return List<PrescriptionModel>.from(jsonDecodedData.map((item)=>PrescriptionModel.fromJson(item)));
   }

   static Future <List<PrescriptionModel>?> getData({required String appointmentId})async {
     final body={
       "appointment_id":appointmentId
     };


     // fetch data
     final res=await GetService.getReqWithBody(getPrescriptionUrl,body);

     if(res==null) {
       return null; //check if any null value
     } else {
       List<PrescriptionModel> dataModelList = dataFromJson(res); // convert all list to model
       return dataModelList;  // return converted data list model
     }
   }
   static Future <List<PrescriptionModel>?> getDataByDoctorId()async {
     SharedPreferences preferences=await SharedPreferences.getInstance();
     final uid=preferences.getString(SharedPreferencesConstants.uid)??-1;
     final body={
       "doctor_id":uid
     };
     // fetch data
     final res=await GetService.getReqWithBody(getPrescriptionUrl,body);

     if(res==null) {
       return null; //check if any null value
     } else {
       List<PrescriptionModel> dataModelList = dataFromJson(res); // convert all list to model
       return dataModelList;  // return converted data list model
     }
   }



   static Future <PrescriptionModel?> getDataByPrescriptionId({required String prescriptionId})async {

     final res=await GetService.getReq("$getPrescriptionUrl/$prescriptionId");
     if(res==null) {
       return null;
     } else {
       PrescriptionModel dataModel = PrescriptionModel.fromJson(res);
       return dataModel;
     }
   }
   static Future <List<PrescriptionModel>?> getDataSearch({required String search})async {
     SharedPreferences preferences=await SharedPreferences.getInstance();
     final uid=preferences.getString(SharedPreferencesConstants.uid)??-1;
     final body={
       "doctor_id":uid,
       "search":search,
     };
     // fetch data
     final res=await GetService.getReqWithBody(prescriptionUrl,body);

     if(res==null) {
       return null; //check if any null value
     } else {
       List<PrescriptionModel> dataModelList = dataFromJson(res); // convert all list to model
       return dataModelList;  // return converted data list model
     }
   }

}
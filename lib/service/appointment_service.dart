import 'package:shared_preferences/shared_preferences.dart';
import '../helper/get_req_helper.dart';
import '../helper/post_req_helper.dart';
import '../model/appointment_model.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class AppointmentService{

   static const  getAppointmentUrl=   ApiContents.getAppointmentUrl;
   static const  getAppByIDUrl=   ApiContents.getAppByIDUrl;
   static const  appointmentRejectUrl=   ApiContents.appointmentRejectUrl;
   static const  appointmentCancelUrl=   ApiContents.appointmentCancelUrl;
   static const  updateAppointmentStatusUrl=   ApiContents.updateAppointmentStatusUrl;
   static const  updateAppointmentStatusToReschUrl=   ApiContents.updateAppointmentStatusToReschUrl;
  static List<AppointmentModel> dataFromJson (jsonDecodedData){
    return List<AppointmentModel>.from(jsonDecodedData.map((item)=>AppointmentModel.fromJson(item)));
  }

  static Future <List<AppointmentModel>?> getData({required int start,
  required int end,
    String search="",
    String? clinicId,
    String? clinicIds,
  })async {
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";
   final body=<String, dynamic>{
      "start":start.toString(),
       "end":end.toString(),
       "doctor_id":uid,
     "search":search
    };
    // clinic_ids takes precedence over clinic_id (matches backend logic).
    if (clinicIds != null && clinicIds.isNotEmpty) {
      body['clinic_ids'] = clinicIds;
    } else if (clinicId != null && clinicId.isNotEmpty) {
      body['clinic_id'] = clinicId;
    }
    final res=await GetService.getReqWithBody(getAppointmentUrl,body);
    if(res==null) {
      return null;
    } else {
      List<AppointmentModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }
   static Future <AppointmentModel?> getDataById({required String? appId})async {
     final res=await GetService.getReq("$getAppByIDUrl/${appId??""}");
     if(res==null) {
       return null;
     } else {
       AppointmentModel dataModel = AppointmentModel.fromJson(res);
       return dataModel;
     }
   }

   static Future updateStatus(
       {
         required String appointmentId,
         required String status,
       }
       )async{

     Map body={
       'status': status,
       'id':appointmentId
     };
     final res=await PostService.postReq(updateAppointmentStatusUrl, body);
     return res;
   }
   static Future updateStatusToReject(
       {
         required String appointmentId
       }
       )async{

     Map body={
       'appointment_id':appointmentId
     };
     final res=await PostService.postReq(appointmentRejectUrl, body);
     return res;
   }
   static Future updateStatusToCancel(
       {
         required String appointmentId
       }
       )async{

     Map body={
       'appointment_id':appointmentId,
       "status":"Approved"
     };
     final res=await PostService.postReq(appointmentCancelUrl, body);
     return res;
   }
   static Future updateStatusToResch(
       {
         required String appointmentId,
         required String date,
         required String timeSlots,
       }
       )async{

     Map body={
       'date': date,
       'id':appointmentId,
       "time_slots":timeSlots
     };
     final res=await PostService.postReq(updateAppointmentStatusToReschUrl, body);
     return res;
   }

}
import '../helper/get_req_helper.dart';
import '../model/appointment_cancellation_model.dart';
import '../utilities/api_content.dart';

class AppointmentCancellationService{
  static const  getByAppIdUrl=   ApiContents.getAppointmentCancellationUrlByAppId;

  static List<AppointmentCancellationRedModel> dataFromJson (jsonDecodedData){
    return List<AppointmentCancellationRedModel>.from(jsonDecodedData.map((item)=>AppointmentCancellationRedModel.fromJson(item)));
  }

  static Future <List<AppointmentCancellationRedModel>?> getData({required String appointmentId})async {
    final res=await GetService.getReq("$getByAppIdUrl/$appointmentId");
    if(res==null) {
      return null;
    } else {
      List<AppointmentCancellationRedModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }

}
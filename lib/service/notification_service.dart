import '../utilities/sharedpreference_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/get_req_helper.dart';
import '../model/notification_model.dart';
import '../utilities/api_content.dart';

class NotificationService{

  static const  getUserNotificationUrl=   ApiContents.getUserNotificationUrl;


  static List<NotificationModel> dataFromJson (jsonDecodedData){
    return List<NotificationModel>.from(jsonDecodedData.map((item)=>NotificationModel.fromJson(item)));
  }

  static List<NotificationModel> dataFromJsonSpecific (jsonDecodedData){
    return List<NotificationModel>.from(jsonDecodedData.map((item)=>NotificationModel.fromJson(item)));
  }

  static Future <List<NotificationModel>?> getData()async {
    SharedPreferences preferences =await SharedPreferences.getInstance();
    final uid=preferences.getString(SharedPreferencesConstants.uid)??"-1";
    final res=await GetService.getReq("$getUserNotificationUrl/$uid");
    if(res==null) {
      return null;
    } else {
      List<NotificationModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }
  static NotificationModel dataFromJsonById(data) {
    return NotificationModel.fromJson(data);
  }
  static Future <NotificationModel?> getDataById({required String? nId})async {
    final res=await GetService.getReq("$getUserNotificationUrl/${nId??""}");
    if(res==null) {
      return null;
    } else {
      NotificationModel dataModel = dataFromJsonById(res);
      return dataModel;
    }
  }

}
import '../model/dashboard_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/get_req_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class DashboardService{

  static const  getUrl=   ApiContents.getDashBoardCountUrl;

  static List<DashboardModel> dataFromJson (jsonDecodedData){

    return List<DashboardModel>.from(jsonDecodedData.map((item)=>DashboardModel.fromJson(item)));
  }
  static Future <DashboardModel?> getData()async {
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";
    final res=await GetService.getReq("$getUrl/$uid");
    if(res==null) {
      return null;
    } else {
      DashboardModel dataModel = DashboardModel.fromJson(res);
      return dataModel;
    }
  }


}
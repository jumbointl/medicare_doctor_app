import 'package:shared_preferences/shared_preferences.dart';
import '../helper/get_req_helper.dart';
import '../model/doctors_model.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class DoctorsService{

  static const  getUrl=   ApiContents.getDoctorsUrl;

  static List<DoctorsModel> dataFromJson (jsonDecodedData){

    return List<DoctorsModel>.from(jsonDecodedData.map((item)=>DoctorsModel.fromJson(item)));
  }


  static Future <DoctorsModel?> getDataById()async {
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";
    final res=await GetService.getReq("$getUrl/$uid");
    if(res==null) {
      return null;
    } else {
      DoctorsModel dataModel = DoctorsModel.fromJson(res);
      return dataModel;
    }
  }
}
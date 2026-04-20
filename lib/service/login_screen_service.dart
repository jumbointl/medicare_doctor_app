import '../model/login_screen_model.dart';
import '../helper/get_req_helper.dart';
import '../utilities/api_content.dart';

class LoginScreenService{

  static const  getUrl=   ApiContents.getLoginImageUrl;

  static List<LoginScreenMode> dataFromJson (jsonDecodedData){

    return List<LoginScreenMode>.from(jsonDecodedData.map((item)=>LoginScreenMode.fromJson(item)));
  }

  static Future <List<LoginScreenMode>?> getData()async {

    // fetch data
    final res=await GetService.getReq(getUrl);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<LoginScreenMode> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }

}
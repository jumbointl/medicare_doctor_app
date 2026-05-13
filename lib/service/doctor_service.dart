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
    // `doctor_id` se persiste en el login a partir de `data.doctor_id`
    // del backend. Antes se pasaba `uid` (user.id) que NO corresponde al
    // PK de `doctors` y devolvía 404. Fallback a uid si no está seteado
    // (instalación nueva pre-login con doctor_id key).
    final doctorId = preferences.getString(SharedPreferencesConstants.doctorId)
        ?? preferences.getString(SharedPreferencesConstants.uid)
        ?? "-1";
    final res=await GetService.getReq("$getUrl/$doctorId");
    if(res==null) {
      return null;
    } else {
      DoctorsModel dataModel = DoctorsModel.fromJson(res);
      return dataModel;
    }
  }
}
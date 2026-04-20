
import '../helper/get_req_helper.dart';
import '../model/clinic_model.dart';
import '../utilities/api_content.dart';


class ClinicService{


  static const  getClinicByIdUrl=   ApiContents.getClinicByIdUrl;



  static Future <ClinicModel?> getDataById({required String? clinicId})async {
    final res=await GetService.getReq("$getClinicByIdUrl/${clinicId??""}");
    if(res==null) {
      return null;
    } else {
      ClinicModel dataModel = ClinicModel.fromJson(res);
      return dataModel;
    }
  }

}
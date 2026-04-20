import '../helper/get_req_helper.dart';
import '../model/medicine_model.dart';
import '../utilities/api_content.dart';

class MedicationService{

  static const  getUrl=   ApiContents.getPrescribeMedicineUrl;

  static List<MedicineModel> dataFromJson (jsonDecodedData){

    return List<MedicineModel>.from(jsonDecodedData.map((item)=>MedicineModel.fromJson(item)));
  }

  static Future <List<MedicineModel>?> getData(String clinicId)async {
    final body={
      "clinic_id":clinicId
    };
    // fetch data
    final res=await GetService.getReqWithBody(getUrl,body);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<MedicineModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }


}
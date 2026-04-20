import '../helper/get_req_helper.dart';
import '../model/patient_file_model.dart';
import '../utilities/api_content.dart';


class PatientFilesService{

  static const  getUrl=   ApiContents.getPatientFileUrl;
  static List<PatientFileModel> dataFromJson (jsonDecodedData){

    return List<PatientFileModel>.from(jsonDecodedData.map((item)=>PatientFileModel.fromJson(item)));
  }

  static Future <List<PatientFileModel>?> getData(String patientID,String searchQ)async {
    final body={
      "patient_id":patientID,
      "search":searchQ,
    };

    // fetch data
    final res=await GetService.getReqWithBody(getUrl,body);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<PatientFileModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }

}
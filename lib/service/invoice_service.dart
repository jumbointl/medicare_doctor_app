import '../helper/get_req_helper.dart';
import '../model/invoice_model.dart';
import '../utilities/api_content.dart';

class InvoiceService{

  static const  getUrl=   ApiContents.getInvoiceUrl;

  static List<InvoiceModel> dataFromJson (jsonDecodedData){

    return List<InvoiceModel>.from(jsonDecodedData.map((item)=>InvoiceModel.fromJson(item)));
  }

  static Future <List<InvoiceModel>?> getDataByAppId(appId)async {

    final body={
      "appointment_id":appId
    };
    final res=await GetService.getReqWithBody(getUrl,body);
    if(res==null) {
      return null;
    } else {
      List<InvoiceModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }
}
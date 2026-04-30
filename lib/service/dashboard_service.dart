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
  /// GET /get_dashboard_count/doctor/{uid}?clinic_id=&from=&to=
  ///
  /// All filters are optional. When [clinicId] is null the backend counts
  /// across every clinic the doctor belongs to. [from] and [to] are
  /// inclusive yyyy-MM-dd bounds on `appointments.date`.
  static Future <DashboardModel?> getData({
    int? clinicId,
    String? from,
    String? to,
  }) async {
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";

    final qs = <String>[];
    if (clinicId != null) qs.add('clinic_id=$clinicId');
    if (from != null && from.isNotEmpty) qs.add('from=$from');
    if (to != null && to.isNotEmpty) qs.add('to=$to');

    final url = qs.isEmpty ? "$getUrl/$uid" : "$getUrl/$uid?${qs.join('&')}";
    final res=await GetService.getReq(url);
    if(res==null) {
      return null;
    } else {
      DashboardModel dataModel = DashboardModel.fromJson(res);
      return dataModel;
    }
  }


}
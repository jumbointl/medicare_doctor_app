import '../model/dashboard_model.dart';
import '../service/dashboard_service.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <DashboardModel>[].obs; // list of all fetched data
  var dataModel = DashboardModel().obs; // list of all fetched data
  var isError = false.obs;


  void getData() async {
    isLoading(true);
    try {
      final getData = await DashboardService.getData();

      if (getData !=null) {
        isError(false);
        dataModel.value = getData;
      } else {
        isError(true);
      }
    } catch (e) {
      isError(true);
    } finally {
      isLoading(false);
    }
  }


}

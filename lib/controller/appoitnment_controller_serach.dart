import '../widget/toast_message.dart';
import 'package:get/get.dart';
import '../model/appointment_model.dart';
import '../service/appointment_Service.dart';

class AppointmentSearchController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <AppointmentModel>[].obs; // list of all fetched data
  var isError = false.obs;
  var isLoadingMoreData = false.obs;

  void getData([int start=0,int end=20,String search=""]) async {
    isLoading(true);
    try {
      final getDataList = await AppointmentService.getData(start: start,end: end,search: search);
      if (getDataList !=null) {
        isError(false);
        dataList.value = getDataList;
      } else {
        isError(true);
      }
    } catch (e) {
      isError(true);
    } finally {
      isLoading(false);
    }
  }

  void getMoreDataData(int start,int end,String search) async {
    isLoadingMoreData(true);
    try {
      final getDataList = await AppointmentService.getData(start: start,end: end,search: search);
      if (getDataList !=null) {
        if(dataList.length==getDataList.length){
         IToastMsg.showMessage("No more data available");
        }
        dataList.value = getDataList;
      }
    } finally {
      isLoadingMoreData(false);
    }
  }


}

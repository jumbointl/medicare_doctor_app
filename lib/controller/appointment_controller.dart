import 'package:get/get.dart';
import '../model/appointment_model.dart';
import '../service/appointment_Service.dart';

class AppointmentController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <AppointmentModel>[].obs; // list of all fetched data
  var isError = false.obs;


  Future<void> getData([
    int start = 0,
    int end = 20,
    String? clinicId,
    String? clinicIds,
  ]) async {
    isLoading(true);
    try {
      final getDataList = await AppointmentService.getData(
        start: start,
        end: end,
        clinicId: clinicId,
        clinicIds: clinicIds,
      );

      if (getDataList != null) {
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


}

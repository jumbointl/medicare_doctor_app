import 'package:get/get.dart';
import '../model/appointment_cancellation_model.dart';
import '../service/appointment_cancellation_service.dart';

class AppointmentCancellationController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <AppointmentCancellationRedModel>[].obs; // list of all fetched data
  var isError = false.obs;

  void getData({required String appointmentId}) async {
    isLoading(true);
    try {
      final getDataList = await AppointmentCancellationService.getData(appointmentId:appointmentId);
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


}

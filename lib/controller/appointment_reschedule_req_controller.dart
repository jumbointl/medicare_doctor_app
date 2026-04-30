import 'package:get/get.dart';
import '../model/appointment_reschedule_req_model.dart';
import '../service/appointment_reschedule_req_service.dart';

class AppointmentRescheduleReqController extends GetxController {
  var isLoading = false.obs;
  var dataList = <AppointmentRescheduleReqModel>[].obs;
  var isError = false.obs;

  void getByAppointmentId({required String appointmentId}) async {
    isLoading(true);
    try {
      final list = await AppointmentRescheduleReqService.getByAppointmentId(
        appointmentId: appointmentId,
      );
      if (list != null) {
        isError(false);
        dataList.value = list;
      } else {
        isError(true);
      }
    } catch (e) {
      isError(true);
    } finally {
      isLoading(false);
    }
  }

  Future<bool> approve({required String requestId}) async {
    try {
      final res = await AppointmentRescheduleReqService.approve(
        requestId: requestId,
      );
      return res != null && (res['response'] == 200);
    } catch (_) {
      return false;
    }
  }

  Future<bool> reject({required String requestId, String? notes}) async {
    try {
      final res = await AppointmentRescheduleReqService.reject(
        requestId: requestId,
        notes: notes,
      );
      return res != null && (res['response'] == 200);
    } catch (_) {
      return false;
    }
  }
}

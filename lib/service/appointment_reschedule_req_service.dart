import '../helper/get_req_helper.dart';
import '../helper/post_req_helper.dart';
import '../model/appointment_reschedule_req_model.dart';
import '../utilities/api_content.dart';

class AppointmentRescheduleReqService {
  static List<AppointmentRescheduleReqModel> dataFromJson(jsonDecodedData) {
    return List<AppointmentRescheduleReqModel>.from(
      jsonDecodedData.map((item) => AppointmentRescheduleReqModel.fromJson(item)),
    );
  }

  static Future<List<AppointmentRescheduleReqModel>?> getByAppointmentId({
    required String appointmentId,
  }) async {
    final res = await GetService.getReq(
      "${ApiContents.getRescheduleRequestsByAppIdUrl}/$appointmentId",
    );
    if (res == null) return null;
    return dataFromJson(res);
  }

  static Future<List<AppointmentRescheduleReqModel>?> getInitiatedList({
    String? clinicId,
    String? doctId,
  }) async {
    final params = <String, String>{};
    if (clinicId != null) params['clinic_id'] = clinicId;
    if (doctId != null) params['doct_id'] = doctId;
    final res = await GetService.getReqWithBody(
      ApiContents.getInitiatedRescheduleRequestsUrl,
      params,
    );
    if (res == null) return null;
    return dataFromJson(res);
  }

  static Future approve({required String requestId}) async {
    final body = {'id': requestId};
    return await PostService.postReq(
      ApiContents.rescheduleRequestApproveUrl,
      body,
    );
  }

  static Future reject({required String requestId, String? notes}) async {
    final body = {'id': requestId, if (notes != null) 'notes': notes};
    return await PostService.postReq(
      ApiContents.rescheduleRequestRejectUrl,
      body,
    );
  }

  static Future addRequest({
    required String appointmentId,
    required String requestedDate,
    required String requestedTimeSlots,
    String? notes,
  }) async {
    final body = {
      'appointment_id': appointmentId,
      'requested_date': requestedDate,
      'requested_time_slots': requestedTimeSlots,
      if (notes != null) 'notes': notes,
    };
    return await PostService.postReq(
      ApiContents.rescheduleRequestAddUrl,
      body,
    );
  }

  static Future deleteRequest({required String requestId}) async {
    final body = {'id': requestId};
    return await PostService.postReq(
      ApiContents.rescheduleRequestDeleteUrl,
      body,
    );
  }
}

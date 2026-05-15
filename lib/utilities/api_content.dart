import 'package:flutter/widgets.dart';

class ApiContents{

 // static const webApiUrl="http://192.168.1.38:8000";

  // Migrado a Node 2026-05-10. Laravel pay.solexpresspy.com queda
  // deprecado para doctor-app.
  static const webApiUrl="https://medicare.solexpresspy.com";
  //API_BASE_URLcd
  static const baseApiUrl="$webApiUrl/api/v1";
  static const imageUrl="$webApiUrl/public/storage";

  // Asset placeholder usado cuando un campo de imagen viene null/empty.
  // Declarado en pubspec.yaml. NO removerlo sin actualizar safeImage().
  static const noAvailableAsset = 'assets/icons/no-available.png';

  static bool _isFalsy(String? f) {
    if (f == null) return true;
    final t = f.trim();
    return t.isEmpty || t == 'null' || t == 'undefined';
  }

  /// URL completa hacia el storage backend, o cadena vacía si el campo es
  /// null/empty/literal "null"/"undefined". Usar para call sites que pasan
  /// el resultado a ImageBoxFillWidget (que detecta vacío y muestra placeholder).
  static String imgUrl(String? field) {
    if (_isFalsy(field)) return '';
    return '$imageUrl/${field!.trim()}';
  }

  /// ImageProvider listo para `DecorationImage(image: ...)`,
  /// `CircleAvatar(backgroundImage: ...)` o cualquier consumo de ImageProvider.
  /// Devuelve AssetImage local cuando el campo es null/empty/falsy.
  static ImageProvider safeImage(String? field) {
    if (_isFalsy(field)) return const AssetImage(noAvailableAsset);
    return NetworkImage('$imageUrl/${field!.trim()}');
  }

  static const prescriptionUrl="$baseApiUrl/prescription/generatePDF";
  static const invoiceUrl="$baseApiUrl/invoice/generatePDF";
  static const prescriptionSearchUrl="$baseApiUrl/get_prescription";
  static const uploadPrescriptionUrl="$baseApiUrl/upload_prescription";

  //Login
  static const loginUrl="$baseApiUrl/login";
  // Login para desarrollo + impersonate opcional por email. Solo
  // accesible cuando AppConstants.isProductionMode == true (gate UI).
  static const loginDevUrl="$baseApiUrl/login/dev";
  static const loginOutUrl="$baseApiUrl/logout";
  static const refreshDynamicKeyUrl="$baseApiUrl/refresh-dynamic-key";
  // Refresh-token Fase 2 (2026-05-13). POST con `refresh_token` en body;
  // server devuelve nuevo session-JWT (+ rota refresh_token + opcional
  // dynamic_key). Ver refresh_session.dart.
  static const refreshSessionUrl="$baseApiUrl/refresh";

  //Appointment
    static const getAppointmentUrl="$baseApiUrl/get_appointments";
  static const getAppByIDUrl="$baseApiUrl/get_appointment";
  static const updateAppointmentStatusUrl="$baseApiUrl/update_appointment_status";
  static const updateAppointmentStatusToReschUrl="$baseApiUrl/appointment_rescheduled";

  // Panel TV (Fase 2 medicare-node-api). Ver project_medicare_panel_tv_plan.md.
  // El doctor llama paciente: callNext (auto-pick menor token de hoy) o
  // callManual (elige appointment_id). Después puede recall/attend/noShow.
  static const callNextUrl = "$baseApiUrl/calls/next";
  static const callManualUrl = "$baseApiUrl/calls";
  static const patientCallsBase = "$baseApiUrl/patient-calls";
  static const clinicsBase = "$baseApiUrl/clinics"; // /{id}/active-calls
  //Invoice
  static const getInvoiceUrl="$baseApiUrl/get_invoice";

  //Prescription

  static const deletePrescriptionUrl="$baseApiUrl/delete_prescription";
  static const updatePrescriptionUrl="$baseApiUrl/update_prescription";
  static const addPrescriptionUrl="$baseApiUrl/add_prescription";
  static const getPrescriptionUrl="$baseApiUrl/get_prescription";


  //Appointment Cancellation
  static const getAppointmentCancellationUrlByAppId="$baseApiUrl/get_appointment_cancel_req/appointment";
  static const appointmentRejectUrl="$baseApiUrl/appointment_reject_and_refund";
  static const appointmentCancelUrl="$baseApiUrl/appointment_cancellation_and_refund";

  //Appointment Reschedule Request
  static const getRescheduleRequestsByAppIdUrl="$baseApiUrl/get_appointment_reschedule_requests";
  static const getInitiatedRescheduleRequestsUrl="$baseApiUrl/get_initiated_reschedule_requests";
  static const rescheduleRequestApproveUrl="$baseApiUrl/appointment_reschedule_request_approve";
  static const rescheduleRequestRejectUrl="$baseApiUrl/appointment_reschedule_request_reject";
  static const rescheduleRequestAddUrl="$baseApiUrl/appointment_reschedule_request";
  static const rescheduleRequestDeleteUrl="$baseApiUrl/delete_appointment_reschedule_request";


  //Time Slots — nested resource URLs are built dynamically in TimeSlotsService.
  // Pattern: $baseApiUrl/doctors/{doctorId}/clinics/{clinicId}/{time-slots|time-interval/{day}|video-time-slots|video-time-interval/{day}}
  //
  // NOTE: get_booked_time_slots stays on the legacy flat URL with `doct_id`
  // query param — backend ownership prevents renaming the column right now.
  static const getBookedTimeSlotsUrl="$baseApiUrl/get_booked_time_slots";

  //Dashboard
  static const getDashBoardCountUrl="$baseApiUrl/get_dashboard_count/doctor";

  //Medicine
  static const getPrescribeMedicineUrl="$baseApiUrl/get_prescribe_medicines";

  //Users
  static const getUserUrl="$baseApiUrl/get_user";
  static const updateUserUrl="$baseApiUrl/update_user";

  //Loginscreen
  static const getLoginImageUrl="$baseApiUrl/get_login_screen_images";


  //WebPage
  static const getwebApiUrll="$baseApiUrl/get_web_page/page";


  //configurations
  static const getConfigByIdNameApiUrl="$baseApiUrl/get_configurations/id_name";
  static const getConfigurationsAllURL="$baseApiUrl/get_configurations_all";
  static const getConfigUrl="$baseApiUrl/get_configurations";

  //SocialMedia
  static const getSocialMediaApiUrl="$baseApiUrl/get_social_media";

  //Doctors
  static const getDoctorsUrl="$baseApiUrl/get_doctor";
  static const updateDoctorUrl="$baseApiUrl/update_doctor";
  static const removeDoctorImageUrl="$baseApiUrl/remove_doctor_image";
  static const updateDoctorClinicStatusUrl="$baseApiUrl/update_doctor_clinic_status";

  //Notification
  static const getUserNotificationUrl="$baseApiUrl/get_doctor_notification/doctor";
  static const usersNotificationSeenStatusUrl="$baseApiUrl/doctor_notification_seen_status";

  //Patient File
  static const getPatientFileUrl="$baseApiUrl/get_patient_file";

  static const getClinicByIdUrl="$baseApiUrl/get_clinic";

  //Language
  //static const getLngTransUrl="$baseApiUrl/get_language_translations";
  //static const getLngUrl="$baseApiUrl/get_language";

  static const String loginGoogleDoctorUrl = "$baseApiUrl/login_google_doctor";
}
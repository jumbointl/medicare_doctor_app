class ApiContents{

 // static const webApiUrl="http://192.168.1.38:8000";

  static const webApiUrl="https://pay.solexpresspy.com";
  //API_BASE_URLcd
  static const baseApiUrl="$webApiUrl/api/v1";
  static const imageUrl="$webApiUrl/public/storage";
  static const prescriptionUrl="$baseApiUrl/prescription/generatePDF";
  static const invoiceUrl="$baseApiUrl/invoice/generatePDF";
  static const prescriptionSearchUrl="$baseApiUrl/get_prescription";
  static const uploadPrescriptionUrl="$baseApiUrl/upload_prescription";

  //Login
  static const loginUrl="$baseApiUrl/login";
  static const loginOutUrl="$baseApiUrl/logout";

  //Appointment
    static const getAppointmentUrl="$baseApiUrl/get_appointments";
  static const getAppByIDUrl="$baseApiUrl/get_appointment";
  static const updateAppointmentStatusUrl="$baseApiUrl/update_appointment_status";
  static const updateAppointmentStatusToReschUrl="$baseApiUrl/appointment_rescheduled";
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


  //Time Slots
  static const getTimeSlotsUrl="$baseApiUrl/get_doctor_time_interval";
  static const getVideoTimeSlotsUrl="$baseApiUrl/get_doctor_video_time_interval";
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
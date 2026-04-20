
import '../languages/language_page.dart';
import '../pages/patient_file_page.dart';

import '../pages/add_prescription_page.dart';
import '../pages/appointment_page.dart';
import '../pages/notification_page.dart';
import '../pages/prescription_page.dart';
import 'package:get/get.dart';
import '../pages/appointment_details_page.dart';
import '../pages/contact_us_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/share_page.dart';
import '../pages/web_pages/about_us_page.dart';
import '../pages/web_pages/privacy_page.dart';
import '../pages/web_pages/term_cond_page.dart';

class RouteHelper {
  //Auth pages
  static const String loginPage = '/LoginPage';
  //Home page
  static const String homePage = '/HomePage';
  static const String appointmentDetailsPagePage = '/AppointmentDetailsPage';
  static const String appointmentPagePage = '/AppointmentPage';
  static const String prescriptionPage = '/PrescriptionPage';
  static const String addPrescriptionPage = '/AddPrescriptionPage';
  static const String shareAppPage = '/ShareAppPage';
  static const String contactUsPage = '/ContactUsPage';
  static const String aboutUsPagePage = '/AboutUsPage';
  static const String privacyPage = '/PrivacyPage';
  static const String termCondPage = '/TermCondPage';
  static const String notificationPage = '/NotificationPage';
  static const String patientFilePage = '/PatientFilePage';
  static const String videoPage = '/VideoPage';


  //---------------------------------------------------------------//
  static String getLoginPageRoute() => loginPage;
  static String getHomePageRoute() => homePage;
  static String getAppointmentDetailsPageRoute({required String appId}) => "$appointmentDetailsPagePage?appId=$appId";
  static String getPatientFilePagePageRoute({required String patientId}) => "$patientFilePage?patientId=$patientId";
  static String getAppointmentPageRoute() => appointmentPagePage;
  static String getPrescriptionPageRoute() => prescriptionPage;
  static String getAddPrescriptionPageRoute({required String appId,required String prescriptionId}) => "$addPrescriptionPage?appId=$appId&prescriptionId=$prescriptionId";
  static String getAboutUsPageRoute() => aboutUsPagePage;
  static String getPrivacyPagePageRoute() => privacyPage;
  static String getTermCondPageRoute() => termCondPage;
  static String getShareAppPageRoute() => shareAppPage;
  static String getContactUsPageRoute() => contactUsPage;
  static String getNotificationPageRoute() => notificationPage;
  static String getVideoPageRoute() => notificationPage;


  //---------------------------------------------------------------//

  static List<GetPage> routes = [
    GetPage(name: loginPage, page: () => const  LoginPage()),
    //Home Page
    GetPage(name: homePage, page: () => const HomePage()),
  GetPage(name: appointmentDetailsPagePage, page: () =>  AppointmentDetailsPage(
    appId: Get.parameters['appId'],
  )),
    GetPage(name: appointmentPagePage, page: () => const AppointmentPage()),
    GetPage(name: prescriptionPage, page: () => const PrescriptionPage()),
    GetPage(name: addPrescriptionPage, page: () =>  AddPrescriptionPage(
      appId: Get.parameters['appId'],
      prescriptionId: Get.parameters['prescriptionId'],
    )),
    GetPage(name: contactUsPage, page: () => const ContactUsPage()),
    GetPage(name: shareAppPage, page: () => const ShareAppPage()),
    GetPage(name: aboutUsPagePage, page: () => const AboutUsPage()),
    GetPage(name: privacyPage, page: () => const PrivacyPage()),
    GetPage(name: termCondPage, page: () => const TermCondPage()),
    GetPage(name: notificationPage, page: () => const NotificationPage()),

    GetPage(name: patientFilePage, page: () =>  PatientFilePage(
      patientId: Get.parameters['patientId'],

    )),
    GetPage(
      name: getLanguagePageRoute(),
      page: () => const LanguagePage(),
    ),



  ];

  static String getLanguagePageRoute() => "/language-page";


}
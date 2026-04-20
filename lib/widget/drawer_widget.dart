import 'package:doctor_app/model/language_model.dart';

import '../helper/logout_helper.dart';
import '../helper/version_control.dart';
import '../languages/language_storage_helper.dart';
import '../model/user_model.dart';
import '../utilities/sharedpreference_constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../controller/notification_dot_controller.dart';
import '../helper/date_time_helper.dart';
import '../helper/route_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import '../utilities/image_constants.dart';
import 'image_box_widget.dart';

class IDrawerWidget{

   Drawer buildDrawerWidget(UserModel? userModel,NotificationDotController notificationDotController){
    return Drawer(

      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const SizedBox(height: 40),
          userModel==null?Container():_buildProfileSection(userModel),
          _buildLanguageButton(),
          const SizedBox(height: 20),
          Divider(),
          const SizedBox(height: 10),
          _buildCardBox("prescription".tr,Icons.support_agent,(){
            Get.back();
            Get.toNamed(RouteHelper.getPrescriptionPageRoute());

          }),
          _buildNotificationCardBox(notificationDotController,"notification".tr,Icons.notifications,()async{
            Get.back();
              Get.toNamed(RouteHelper.getNotificationPageRoute());

          }),
          const SizedBox(height: 10),
          _buildCardBox("contact_us".tr,Icons.support_agent,(){
            Get.back();
              Get.toNamed(RouteHelper.getContactUsPageRoute());

          }),
          _buildCardBox("share".tr,Icons.share,(){
            Get.back();
              Get.toNamed(RouteHelper.getShareAppPageRoute());
          }),
          const Divider(),
          _buildCardBox("about_us".tr,Icons.info,(){
            Get.back();
              Get.toNamed(RouteHelper.getAboutUsPageRoute());
          }),
          _buildCardBox("privacy_policy".tr,Icons.link,()async{
            Get.back();
            Get.toNamed(RouteHelper.getPrivacyPagePageRoute());
          }),
          _buildCardBox("terms_condition".tr,Icons.link,()async {
            Get.back();
            Get.toNamed(RouteHelper.getTermCondPageRoute());
          }),
          const Divider(),
          FutureBuilder<bool>(
            future: _isLoggedIn(),
            builder: (context, snapshot) {
              final bool loggedIn = snapshot.data ?? false;

              if (loggedIn) {
                return _buildCardBox("logout".tr, Icons.power_settings_new, () async {
                  await forceLogoutDoctorApp();
                });
              }

              return _buildCardBox("login".tr, Icons.login, () async {
                Get.back();
                Get.offAllNamed(RouteHelper.getLoginPageRoute());
              });
            },
          ),
          /*_buildCardBox("logout".tr,Icons.power_settings_new,()async{
            forceLogoutDoctorApp();
            final res= await UserService.logOutUser();
            if(res!=null){
              SharedPreferences prefs=await SharedPreferences.getInstance();
              prefs.clear();
              IToastMsg.showMessage("logout".tr);
              Get.offAllNamed(RouteHelper.getLoginPageRoute());
            }

          }),*/
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: FutureBuilder(
                future: VersionControl.getVersionName(),
                builder: (context, snapshot) {
                  return Text("app_version".trParams({'vnumber': "${snapshot.data}"}),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500
                    ),);
                }
            ),
          )
        ],
      ),
    );
  }

  static SizedBox _buildProfileSection(UserModel userModel) {
    return SizedBox(
      height: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 70,
                width: 70,
                child: ClipOval(
                    child:
                    userModel.imageUrl==null||userModel.imageUrl==""?
                    const Icon(Icons.person,
                      size: 50,):
                    ImageBoxFillWidget(imageUrl:"${ApiContents.imageUrl}/${userModel.imageUrl}") ),
              ),
              Row(
                  children:[
                    Image.asset(
                        ImageConstants.crownImage,
                        width: 40,
                        height: 20),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      color: ColorResources.containerBgColor,
                      child:  const Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Text("Member",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14
                          ),),
                      ),
                    )
                  ]

              )
            ],
          ),
          const SizedBox(height: 20),
          Text("${userModel.fName??" "} ${userModel.lName??""}",
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600
            ),),
     // Text("membership_since_date".trParams({"dates":DateTimeHelper.getDataFormat(userController.usersData.value.createdAt)}),

        Text("membership_since_date".trParams({
          "dates":DateTimeHelper.getDataFormat(userModel.createdAt),
        }) ,
            style:const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400
            ),),

        ],
      ),
    );
  }

  static GestureDetector _buildCardBox(String title,IconData icon,onPressed,[selected]) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration:  BoxDecoration(
          color:selected??false?ColorResources.primaryColor:null,
          borderRadius: const BorderRadius.all(
              Radius.circular(5.0) //                 <--- border radius here
          ),
        ),

        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
          child: Row(
            children: [
                Icon(icon,size: 20,
                color: selected??false?Colors.white:Colors.grey,),
              const SizedBox(width:20),
              Text(title,
              style:  TextStyle(
                color: selected??false?Colors.white:Colors.black,
                fontWeight: FontWeight.w400,
                fontSize: 14
              ),),
            ],
          ),
        ),
      ),
    );
  }
   static GestureDetector _buildNotificationCardBox(NotificationDotController notificationDotController,String title,IconData icon,onPressed,[selected]) {
     return GestureDetector(
       onTap: onPressed,
       child: Container(
         decoration:  BoxDecoration(
           color:selected??false?ColorResources.primaryColor:null,
           borderRadius: const BorderRadius.all(
               Radius.circular(5.0) //                 <--- border radius here
           ),
         ),

         child: Padding(
           padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
           child: Row(
             children: [
               Stack(
                 children: [
                   Icon(icon,size: 20,
                     color: selected??false?Colors.white:Colors.grey,),
                   Obx((){
                     return  notificationDotController.isShow.value?  const Icon(
                       Icons.circle,
                       size: 10,
                       color: Colors.red,
                     ):Container();
                   })
                 ],
               ),
               const SizedBox(width:20),
               Text(title,
                 style:  TextStyle(
                     color: selected??false?Colors.white:Colors.black,
                     fontWeight: FontWeight.w400,
                     fontSize: 14
                 ),),
             ],
           ),
         ),
       ),
     );
   }
   Widget _buildLanguageButton() {
     return FutureBuilder<List<LanguageModel>>(
       future: LanguageStorage.getLanguages(),
       builder: (context, snapshot) {
         if (!snapshot.hasData) {
           return Container();
         }

         final languages = snapshot.data!;
         final currentTag = Get.locale?.toLanguageTag();

         String currentTitle = 'Language';

         for (final lang in languages) {
           final code = lang.code ?? '';
           if (code.isNotEmpty &&
               currentTag == LocaleHelper.parse(code).toLanguageTag()) {
             currentTitle = lang.title ?? code;
             break;
           }
         }

         return _buildCardBox(
           'Language: $currentTitle',
           Icons.language,
               () {
             Get.back();
             Get.toNamed(RouteHelper.getLanguagePageRoute());
           },
         );
       },
     );
   }
   Future<bool> _isLoggedIn() async {
     final prefs = await SharedPreferences.getInstance();
     final bool loggedIn =
         prefs.getBool(SharedPreferencesConstants.login) ?? false;
     final String uid =
         prefs.getString(SharedPreferencesConstants.uid) ?? '';

     return loggedIn && uid.isNotEmpty;
   }

}
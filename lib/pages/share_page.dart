import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../service/configuration_service.dart';
import '../utilities/app_constans.dart';
import '../utilities/image_constants.dart';
import '../widget/app_bar_widget.dart';
import '../widget/bottom_button.dart';
import '../widget/loading_Indicator_widget.dart';
import 'package:share_plus/share_plus.dart';

class ShareAppPage extends StatefulWidget {
  const ShareAppPage({super.key});

  @override
  State<ShareAppPage> createState() => _ShareAppPageState();
}

class _ShareAppPageState extends State<ShareAppPage> {
  String appShareLink="";

  bool _isLoading=false;
  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: _isLoading?const ILoadingIndicatorWidget():IBottomNavBarWidget(onPressed: (){
          if(appShareLink!=""){
            Share.share(
                'Download ${AppConstants.appName} app $appShareLink',
                subject: AppConstants.appName);
          }
        },title: "Share"),
      ),
      appBar: IAppBar.commonAppBar(title: "share".tr),
      body: _buildBody(),
    );
  }

  ListView _buildBody() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height/2,
          child:
          //Container(color: Colors.red,)
          SvgPicture.asset(
              ImageConstants.appShareImage,
              semanticsLabel: 'Acme Logo'
          ),
        ),
         Text("knock_knock".tr,
          textAlign:  TextAlign.center,
          style:const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500
          ),
        ),

        const SizedBox(height: 10),
         Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:  [
            const Icon(Icons.star,color: Colors.amber,),
            const   SizedBox(width: 3),
            Text("share_app_with_friends".tr,
              textAlign: TextAlign.center,
              style:const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
              ),
            ),
            const   SizedBox(width: 3),
            const    Icon(Icons.star,color: Colors.amber,),
          ],
        ),
        const SizedBox(height: 20),
        FutureBuilder(
            future: ConfigurationService.getDataById(idName: "s_p_d_d_a"),
            builder: (context, snapshot) {
              return snapshot.hasData? Text("${snapshot.data?.value}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  letterSpacing: 1,
                  fontSize: 15,

                ),
              ):const Text("--");
            }
        ),
      ],
    );
  }

  void getAndSetData() async{
    setState(() {
      _isLoading=true;
    });
    final res=await ConfigurationService.getDataById(idName:Platform.isAndroid? "play_store_link_doctor_app":Platform.isIOS?"app_store_link_doctor_app":"");
    if(res!=null){
      appShareLink=res.value??"";
    }
    // print("------------------$appShareLink");
    setState(() {
      _isLoading=false;
    });
  }
}

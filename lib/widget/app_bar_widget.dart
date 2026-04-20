import 'package:flutter/material.dart';
import '../utilities/colors_constant.dart';

class IAppBar{
   static AppBar commonAppBar({ String? title}){
   return  AppBar(
     centerTitle: true,
     iconTheme: const IconThemeData(
       color: Colors.white, //change your color here
     ),
     elevation: 0,
     backgroundColor:ColorResources.appBarColor ,
       title: Text(title??"",
      style: const TextStyle(
        color: Colors.white,
         fontSize: 16,
         fontWeight: FontWeight.w400
       ),),
     );
   }

}
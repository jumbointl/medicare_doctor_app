import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utilities/image_constants.dart';

class IErrorWidget extends StatelessWidget {
  const IErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 250,
            width: 300,
            child:
            //Container(color: Colors.red,)
            SvgPicture.asset(ImageConstants.errorImage,
                semanticsLabel: 'Acme Logo'
            ),
          ),
          const SizedBox(height: 20),
          const Text("Sorry it's error!",style: TextStyle(
            fontFamily: 'OpenSans-SemiBold',
            fontSize: 14,
          )),
        ],
      ),
    );
  }
}
class NoInternetErrorWidget extends StatelessWidget {
  const NoInternetErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 250,
            width: 300,
            child:
            //Container(color: Colors.red,)
            SvgPicture.asset(
                "assets/icon/error.svg",
                semanticsLabel: 'Acme Logo'
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text("No internet, please check your internet connection and try again!",style: TextStyle(
              fontFamily: 'OpenSans-SemiBold',
              fontSize: 14,
            )),
          ),
        ],
      ),
    );
  }
}

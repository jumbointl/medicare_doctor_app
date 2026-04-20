import 'package:get/get.dart';
import 'es.dart';
import 'pt.dart';
import 'zh.dart';
import 'zh_tw.dart';

import 'en.dart';

class Translation extends Translations {
 static Map<String, Map<String, String>> get assetKeys => {
  ...enKeys,
  ...esKeys,
  ...ptKeys,
  ...zhKeys,
  ...zhTwKeys,
 };

 @override
 Map<String, Map<String, String>> get keys => assetKeys;
}
import '../model/patient_file_model.dart';
import 'package:get/get.dart';
import '../service/patient_files_service.dart';

class PatientFileController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <PatientFileModel>[].obs; // list of all fetched data
  var isError = false.obs;

  void getData(String patientId,String search) async {
    isLoading(true);
    try {
      final getDataList = await PatientFilesService.getData(patientId, search);

      if (getDataList !=null) {
        isError(false);
        dataList.value = getDataList;
      } else {
        isError(true);
      }
    } catch (e) {
      isError(true);
    } finally {
      isLoading(false);
    }
  }

}

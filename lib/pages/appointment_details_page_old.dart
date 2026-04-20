import 'dart:async';

import 'package:video_conference/video_conference.dart';

import '../model/patient_file_model.dart';
import '../model/prescription_pre_field_model.dart';
import '../pages/write_prescription_page.dart';
import '../service/patient_files_service.dart';
import '../helper/route_helper.dart';
import '../service/prescription_service.dart';
import '../widget/bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/appointment_cancel_req_controller.dart';
import '../controller/appointment_controller.dart';
import '../controller/boked_time_slot_controller.dart';
import '../controller/prescription_controller.dart';
import '../controller/time_slots_controller.dart';
import '../helper/date_time_helper.dart';
import '../model/appointment_cancellation_model.dart';
import '../model/appointment_model.dart';
import '../model/booked_time_slot_mdel.dart';
import '../model/invoice_model.dart';
import '../model/prescription_model.dart';
import '../model/time_slots_model.dart';
import '../service/appointment_Service.dart';
import '../service/invoice_service.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/app_bar_widget.dart';
import '../widget/button_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/toast_message.dart';
import 'package:get/get.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String? appId;
  const AppointmentDetailsPage({super.key, this.appId});

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  bool _isLoading = false;
  AppointmentModel? appointmentModel;
  List<PatientFileModel> patientFileMode = [];
  List<InvoiceModel> invoiceModelList = [];
  final AppointmentCancellationController _appointmentCancellationController =
  AppointmentCancellationController();
  final PrescriptionController _prescriptionController =
  Get.put(PrescriptionController());

  String selectedAppointmentStatus = "";
  final ScrollController _scrollController = ScrollController();
  TextEditingController textEditingController = TextEditingController();
  final TimeSlotsController _timeSlotsController =
  Get.put(TimeSlotsController());
  final BookedTimeSlotsController _bookedTimeSlotsController =
  Get.put(BookedTimeSlotsController());
  AppointmentController appointmentController =
  Get.find<AppointmentController>();
  String _selectedDate = "";
  String _setTime = "";

  Timer? _videoTimer;
  int _videoRemainingSeconds = 0;
  bool _videoLoading = false;
  @override
  void initState() {
    getAndSetData();
    _appointmentCancellationController.getData(
      appointmentId: widget.appId ?? "-1",
    );
    _prescriptionController.getData(appointmentId: widget.appId ?? "-1");
    super.initState();
  }

  @override
  void dispose() {
    _videoTimer?.cancel();
    _scrollController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: IBottomNavBarWidget(
        title: "add_prescription".tr,
        onPressed: () {
          _openBottomSheet();
        },
      ),
      backgroundColor: ColorResources.bgColor,
      appBar: IAppBar.commonAppBar(title: "appointment".tr),
      floatingActionButton: appointmentModel?.status == "Rejected" ||
          appointmentModel?.status == "Cancelled" ||
          appointmentModel?.status == "Visited" ||
          appointmentModel?.status == "Completed"
          ? null
          : _isLoading || appointmentModel == null
          ? null
          : FloatingActionButton(
        backgroundColor: ColorResources.btnColor,
        onPressed: () {
          selectedAppointmentStatus = appointmentModel?.status ?? "";
          _openBottomSheetAppointmentStatus();
        },
        shape: const CircleBorder(),
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
      body: _isLoading || appointmentModel == null
          ? const ILoadingIndicatorWidget()
          : _buildBody(),
    );
  }

  ListView _buildBody() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(5),
      children: [
        buildOpDetails(),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildPrescriptionListBox(),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildPatientFileListBox(),
        ),
        _buildPaymentCard(),
        const SizedBox(height: 10),
        _buildCancellationBox(),
        Obx(() {
          return _appointmentCancellationController.dataList.isNotEmpty
              ? _buildCancellationReqListBox()
              : Container();
        }),
      ],
    );
  }
  String _formatJoinCloseTime() {
    final int joinClosesAt = appointmentModel?.videoJoinClosesAt ?? 0;
    if (joinClosesAt <= 0) return '--:--';

    final date = DateTime.fromMillisecondsSinceEpoch(joinClosesAt * 1000);
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void getAndSetData() async {
    setState(() {
      _isLoading = true;
    });

    final appointmentData =
    await AppointmentService.getDataById(appId: widget.appId);
    appointmentModel = appointmentData;
    _syncVideoState();

    final invoiceData = await InvoiceService.getDataByAppId(widget.appId);
    invoiceModelList = invoiceData ?? [];
    appointmentController.getData();

    final resPatientFile = await PatientFilesService.getData(
      appointmentModel?.patientId.toString() ?? "",
      "",
    );
    if (resPatientFile != null && resPatientFile.isNotEmpty) {
      patientFileMode = resPatientFile;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _syncVideoState() {
    _videoTimer?.cancel();

    if (appointmentModel == null) return;
    if (!(appointmentModel?.isVideoConsult ?? false)) return;

    _videoRemainingSeconds =
        appointmentModel?.videoJoinSecondsRemaining ?? 0;

    if ((appointmentModel?.mustPayFirst ?? false) ||
        (appointmentModel?.paymentStatus != 'Paid')) {
      return;
    }

    if ((appointmentModel?.canJoinVideo ?? false) ||
        _videoRemainingSeconds <= 0) {
      _videoRemainingSeconds = 0;
      return;
    }

    _videoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_videoRemainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          _videoRemainingSeconds = 0;
        });
        return;
      }
      setState(() {
        _videoRemainingSeconds--;
      });
    });
  }

  String _formatVideoCountdown(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  Future<int> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(SharedPreferencesConstants.uid) ?? '0';
    return int.tryParse(uid) ?? 0;
  }

  Future<void> _handleAgoraJoin() async {
    if (appointmentModel == null) return;

    setState(() {
      _videoLoading = true;
    });

    try {
      await openAgoraCallWithCache(
        appointmentId: appointmentModel!.id ?? 0,
        isDoctor: true,
        title: 'Consulta por video',
      );
    } finally {
      if (mounted) {
        setState(() {
          _videoLoading = false;
        });
      }
    }
  }

  Widget _buildVideoConsultAction() {
    if (appointmentModel?.type != "Video Consultant") {
      return Container();
    }

    if (appointmentModel?.status == "Rejected" ||
        appointmentModel?.status == "Cancelled" ||
        appointmentModel?.status == "Visited" ||
        appointmentModel?.status == "Completed") {
      return Container();
    }

    if ((appointmentModel?.mustPayFirst ?? false) ||
        (appointmentModel?.paymentStatus != 'Paid')) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        onPressed: null,
        child: const Text(
          'Debe pagar primero',
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
    }

    final canJoinNow =
        (appointmentModel?.canJoinVideo ?? false) ||
            _videoRemainingSeconds <= 0;

    if (!canJoinNow) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        onPressed: null,
        child: Text(
          'Disponible en ${_formatVideoCountdown(_videoRemainingSeconds)}',
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
      ),
      onPressed: _videoLoading ? null : _handleAgoraJoin,
      child: Text(
        _videoLoading ? 'Conectando...' : 'Iniciar video',
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Card buildOpDetails() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "appointment_id".trParams({"id": widget.appId ?? "--"}),
                  style: const TextStyle(
                    color: ColorResources.secondaryFontColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: appointmentModel!.status == "Pending"
                          ? _statusIndicator(Colors.yellowAccent)
                          : appointmentModel!.status == "Rescheduled"
                          ? _statusIndicator(Colors.orangeAccent)
                          : appointmentModel!.status == "Rejected"
                          ? _statusIndicator(Colors.red)
                          : appointmentModel!.status == "Confirmed"
                          ? _statusIndicator(Colors.green)
                          : appointmentModel!.status == "Completed"
                          ? _statusIndicator(Colors.green)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                      child: Text(
                        (appointmentModel!.status ?? "--").tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "dear_patient_name".trParams({
                    "pName":
                    "${appointmentModel!.pFName ?? "--"} ${appointmentModel!.pLName ?? "--"}"
                  }),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  "#${appointmentModel?.id}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                )
              ],
            ),
            const SizedBox(height: 5),
            Text(
              "MRN #${appointmentModel?.patientMRN ?? "--"}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        appointmentModel!.type ?? "--".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildVideoConsultAction(),
                  ],
                ),
                if (appointmentModel?.type == "Video Consultant")
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Cierre automático: ${_formatJoinCloseTime()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorResources.secondaryFontColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "date".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                      Card(
                        color: ColorResources.cardBgColor,
                        elevation: .1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: ListTile(
                          title: Text(
                            DateTimeHelper.getDataFormat(
                              appointmentModel?.date ?? "",
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            color: Colors.black,
                            child: const Padding(
                              padding: EdgeInsets.all(3.0),
                              child: Icon(
                                Icons.calendar_month,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "time".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Card(
                          color: ColorResources.cardBgColor,
                          elevation: .1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: ListTile(
                            title: Text(
                              DateTimeHelper.convertTo12HourFormat(
                                appointmentModel?.timeSlot ?? "",
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              color: Colors.black,
                              child: const Padding(
                                padding: EdgeInsets.all(3.0),
                                child: Icon(
                                  Icons.watch_later,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _statusIndicator(Color color) {
    return CircleAvatar(radius: 4, backgroundColor: color);
  }

  Card _buildPaymentCard() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: invoiceModelList.length,
        itemBuilder: (context, index) {
          InvoiceModel? invoiceModel =
          invoiceModelList.isNotEmpty ? invoiceModelList[index] : null;
          return ListTile(
            onTap: () async {
              await launchUrl(
                Uri.parse("${ApiContents.invoiceUrl}/${invoiceModel?.id}"),
                mode: LaunchMode.externalApplication,
              );
            },
            title: Text(
              "invoice_id".trParams({
                "id": invoiceModel == null ? "--" : "${invoiceModel.id}"
              }),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            trailing: Text(
              invoiceModel == null
                  ? "--"
                  : (invoiceModel.status ?? "--").tr,
              style: const TextStyle(
                color: ColorResources.primaryColor,
                fontSize: 13,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Text(
                      "download_invoice",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.download,
                      color: Colors.green,
                      size: 16,
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Card _buildCancellationBox() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        onTap: appointmentModel?.currentCancelReqStatus == null ||
            appointmentModel?.currentCancelReqStatus == "Approved"
            ? null
            : () {
          selectedAppointmentStatus = "Cancelled";
          _openDialogBox();
        },
        trailing: const Icon(
          Icons.arrow_right,
          color: ColorResources.btnColor,
        ),
        title: Text(
          "appointment_cancellation_request".tr,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            appointmentModel?.currentCancelReqStatus == null
                ? Text(
              "no_cancellation_generated_by_user_desc".tr,
              style: const TextStyle(
                color: ColorResources.secondaryFontColor,
                fontSize: 13,
              ),
            )
                : appointmentModel?.currentCancelReqStatus == null
                ? Container()
                : Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                "current_status_value".trParams({
                  "value":
                  appointmentModel?.currentCancelReqStatus ?? "--"
                }),
                style: const TextStyle(
                  color: ColorResources.secondaryFontColor,
                  fontSize: 13,
                ),
              ),
            ),
            appointmentModel?.currentCancelReqStatus == null ||
                appointmentModel?.currentCancelReqStatus == "Approved"
                ? Container()
                : Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text(
                "click_here_to_cancel_this_appointment".tr,
                style: const TextStyle(
                  color: ColorResources.secondaryFontColor,
                  fontSize: 13,
                ),
              ),
            ),
            appointmentModel?.currentCancelReqStatus == "Approved"
                ? Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text(
                "canceled_appointment_status_desc".tr,
                style: const TextStyle(
                  color: ColorResources.secondaryFontColor,
                  fontSize: 13,
                ),
              ),
            )
                : Container()
          ],
        ),
      ),
    );
  }

  Card _buildCancellationReqListBox() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Obx(() {
        if (!_appointmentCancellationController.isError.value) {
          if (_appointmentCancellationController.isLoading.value) {
            return const ILoadingIndicatorWidget();
          } else {
            return _appointmentCancellationController.dataList.isEmpty
                ? Container()
                : ListTile(
              title: Text(
                "cancellation_request_history".tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount:
                _appointmentCancellationController.dataList.length,
                itemBuilder: (context, index) {
                  AppointmentCancellationRedModel
                  appointmentCancellationRedModel =
                  _appointmentCancellationController.dataList[index];
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      size: 10,
                      color: appointmentCancellationRedModel.status ==
                          "Initiated"
                          ? Colors.yellow
                          : appointmentCancellationRedModel.status ==
                          "Rejected"
                          ? Colors.red
                          : appointmentCancellationRedModel.status ==
                          "Approved"
                          ? Colors.green
                          : appointmentCancellationRedModel
                          .status ==
                          "Processing"
                          ? Colors.orange
                          : Colors.grey,
                    ),
                    title: Text(
                      appointmentCancellationRedModel.status ?? "--".tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        appointmentCancellationRedModel.notes == null
                            ? Container()
                            : Text(
                          appointmentCancellationRedModel.notes ??
                              "--",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          DateTimeHelper.getDataFormat(
                            appointmentCancellationRedModel.createdAt ??
                                "--",
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Divider(
                          color: Colors.grey.shade100,
                        )
                      ],
                    ),
                  );
                },
              ),
            );
          }
        } else {
          return Container();
        }
      }),
    );
  }

  Card _buildPrescriptionListBox() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        title: Text(
          "prescription".tr,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Obx(() {
          if (!_prescriptionController.isError.value) {
            if (_prescriptionController.isLoading.value) {
              return const ILoadingIndicatorWidget();
            } else {
              return _prescriptionController.dataList.isEmpty
                  ? Text(
                "no_prescription_found".tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: _prescriptionController.dataList.length,
                itemBuilder: (context, index) {
                  PrescriptionModel prescriptionModel =
                  _prescriptionController.dataList[index];
                  return ListTile(
                    title: Row(
                      children: [
                        Text(
                          "prescription_id".trParams(
                            {"id".tr: "${prescriptionModel.id ?? "--"}"},
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (prescriptionModel.pdfFile != null &&
                                prescriptionModel.pdfFile != "") {
                              await launchUrl(
                                Uri.parse(
                                  "${ApiContents.imageUrl}/${prescriptionModel.pdfFile}",
                                ),
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              await launchUrl(
                                Uri.parse(
                                  "${ApiContents.prescriptionUrl}/${prescriptionModel.id}",
                                ),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.download,
                            color: Colors.green,
                            size: 25,
                          ),
                        ),
                        prescriptionModel.pdfFile != null &&
                            prescriptionModel.pdfFile != ""
                            ? Container()
                            : IconButton(
                          onPressed: () {
                            Get.toNamed(
                              RouteHelper
                                  .getAddPrescriptionPageRoute(
                                appId: widget.appId ?? "",
                                prescriptionId:
                                prescriptionModel.id.toString(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.grey,
                            size: 25,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _openDialogDeletePrescriptionBox(
                              prescriptionModel.id.toString(),
                            );
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                            size: 25,
                          ),
                        )
                      ],
                    ),
                    subtitle: Text(
                      DateTimeHelper.getDataFormat(
                        prescriptionModel.createdAt.toString(),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              );
            }
          } else {
            return Container();
          }
        }),
      ),
    );
  }

  Card _buildPatientFileListBox() {
    return Card(
      color: ColorResources.cardBgColor,
      elevation: .1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
        onTap: patientFileMode.isEmpty
            ? null
            : () {
          Get.toNamed(
            RouteHelper.getPatientFilePagePageRoute(
              patientId: appointmentModel?.patientId.toString() ?? "",
            ),
          );
        },
        title: Text(
          "patient_files".tr,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: patientFileMode.isEmpty
            ? Text(
          "no_file_found".tr,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        )
            : Text(
          "click_the_patient_file".tr,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<dynamic> _openBottomSheetAppointmentStatus() {
    return showModalBottomSheet(
      backgroundColor: ColorResources.bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.0),
          topLeft: Radius.circular(20.0),
        ),
      ),
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'current_appointment_status_is'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: (appointmentModel?.status ?? "").tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    RadioListTile(
                      selectedTileColor: ColorResources.btnColor,
                      title: Text(
                        "Visited".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        "either_mark_text".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                      value: "Visited",
                      groupValue: selectedAppointmentStatus,
                      onChanged: appointmentModel?.type != "Video Consultant"
                          ? (value) {
                        setState(() {
                          selectedAppointmentStatus = "Visited";
                        });
                      }
                          : null,
                    ),
                    RadioListTile(
                      title: Text(
                        "Rescheduled".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      value: "Rescheduled",
                      groupValue: selectedAppointmentStatus,
                      onChanged: (value) {
                        setState(() {
                          selectedAppointmentStatus = "Rescheduled";
                        });
                      },
                    ),
                    RadioListTile(
                      subtitle: Text(
                        "can_marked_video_consultant".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                      title: Text(
                        "Completed".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      value: "Completed",
                      groupValue: selectedAppointmentStatus,
                      onChanged: appointmentModel?.type == "Video Consultant"
                          ? (value) {
                        setState(() {
                          selectedAppointmentStatus = "Completed";
                        });
                      }
                          : null,
                    ),
                    RadioListTile(
                      title: Text(
                        "Rejected".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      value: "Rejected",
                      groupValue: selectedAppointmentStatus,
                      onChanged: (value) {
                        setState(() {
                          selectedAppointmentStatus = "Rejected";
                        });
                      },
                    ),
                    RadioListTile(
                      title: Text(
                        "Pending".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      value: "Pending",
                      groupValue: selectedAppointmentStatus,
                      onChanged: (value) {
                        setState(() {
                          selectedAppointmentStatus = "Pending";
                        });
                      },
                    ),
                    RadioListTile(
                      title: Text(
                        "Confirmed".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      value: "Confirmed",
                      groupValue: selectedAppointmentStatus,
                      onChanged: (value) {
                        setState(() {
                          selectedAppointmentStatus = "Confirmed";
                        });
                      },
                    ),
                    SmallButtonsWidget(
                      title: "save".tr,
                      onPressed: selectedAppointmentStatus ==
                          appointmentModel?.status
                          ? null
                          : () {
                        Get.back();
                        if (selectedAppointmentStatus == "Rescheduled") {
                          _openBottomCalenderSheet();
                        } else {
                          _openDialogBox();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {});
  }

  void _handleUpdateStatus() async {
    setState(() {
      _isLoading = true;
    });
    final res = await AppointmentService.updateStatus(
      appointmentId: appointmentModel?.id.toString() ?? "",
      status: selectedAppointmentStatus,
    );
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      getAndSetData();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _handleUpdateStatusToCancel() async {
    setState(() {
      _isLoading = true;
    });
    final res = await AppointmentService.updateStatusToCancel(
      appointmentId: appointmentModel?.id.toString() ?? "",
    );
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      _appointmentCancellationController.getData(
        appointmentId: widget.appId ?? "-1",
      );
      getAndSetData();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _handleUpdateStatusToResch() async {
    setState(() {
      _isLoading = true;
    });
    final res = await AppointmentService.updateStatusToResch(
      appointmentId: appointmentModel?.id.toString() ?? "",
      date: _selectedDate,
      timeSlots: _setTime,
    );
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      getAndSetData();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _handleUpdateStatusReject() async {
    setState(() {
      _isLoading = true;
    });
    final res = await AppointmentService.updateStatusToReject(
      appointmentId: appointmentModel?.id.toString() ?? "",
    );
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      getAndSetData();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<dynamic> _openDialogBox() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            selectedAppointmentStatus.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedAppointmentStatus == "Rejected"
                    ? "appointmentStatusChangeWarning".trParams({
                  "currentStatus": appointmentModel?.status ?? "",
                  "newStatus": selectedAppointmentStatus
                })
                    : selectedAppointmentStatus == "Cancelled"
                    ? "appointmentStatusChangeWarning_2_value".trParams({
                  "currentStatus": appointmentModel?.status ?? "",
                  "selectedAppointmentStatus":
                  selectedAppointmentStatus
                })
                    : selectedAppointmentStatus == "Rescheduled"
                    ? "appointmentStatusChangeWarning_3_value".trParams({
                  "date": DateTimeHelper.getDataFormat(
                    appointmentModel?.date ?? "",
                  ),
                  "timeslot": appointmentModel?.timeSlot ?? "",
                  "to_date":
                  DateTimeHelper.getDataFormat(_selectedDate),
                  "to_time": _setTime
                })
                    : "appointmentStatusChangeWarning_4_value".trParams({
                  "currentStatus": appointmentModel?.status ?? "",
                  "newStatus": selectedAppointmentStatus
                }),
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResources.btnColorRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "no".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResources.btnColorGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "yes".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                switch (selectedAppointmentStatus) {
                  case "Rejected":
                    _handleUpdateStatusReject();
                    break;
                  case "Cancelled":
                    _handleUpdateStatusToCancel();
                    break;
                  case "Rescheduled":
                    _handleUpdateStatusToResch();
                    break;
                  default:
                    _handleUpdateStatus();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> _openDialogDeletePrescriptionBox(String id) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            "delete".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "delete_prescription_id".trParams({"id": id}),
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResources.btnColorRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "no".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResources.btnColorGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "yes".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _handleDeletePrescription(id);
              },
            ),
          ],
        );
      },
    );
  }

  void _handleDeletePrescription(String id) async {
    setState(() {
      _isLoading = true;
    });
    final res = await PrescriptionService.deleteData(id: id);
    if (res != null) {
      IToastMsg.showMessage("success".tr);
      _prescriptionController.getData(appointmentId: widget.appId ?? "");
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<dynamic> _openBottomCalenderSheet() {
    return showModalBottomSheet(
      backgroundColor: ColorResources.bgColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: ColorResources.bgColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20.0),
                  topLeft: Radius.circular(20.0),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    right: 20,
                    left: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "choose_dare_and_time".tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Get.back();
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 5,
                    right: 5,
                    bottom: 0,
                    child: ListView(
                      children: [
                        _buildCalendar(),
                        const Divider(),
                        Obx(() {
                          if (!_timeSlotsController.isError.value &&
                              !_bookedTimeSlotsController.isError.value) {
                            if (_timeSlotsController.isLoading.value ||
                                _bookedTimeSlotsController.isLoading.value) {
                              return const ILoadingIndicatorWidget();
                            } else if (_timeSlotsController.dataList.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  "no_available_time_slots".tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            } else {
                              return _slotsGridView(
                                setState,
                                _timeSlotsController.dataList,
                                _bookedTimeSlotsController.dataList,
                              );
                            }
                          } else {
                            return Text("something_went_wrong".tr);
                          }
                        })
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {});
  }

  Widget _buildCalendar() {
    return SizedBox(
      height: 100,
      child: DatePicker(
        DateTime.now(),
        initialSelectedDate: DateTime.now(),
        selectionColor: ColorResources.primaryColor,
        selectedTextColor: Colors.white,
        daysCount: 7,
        onDateChange: (date) {
          setState(() {
            final dateParse =
            DateFormat('yyyy-MM-dd').parse((date.toString()));
            _selectedDate = DateTimeHelper.getYYYMMDDFormatDate(
              date.toString(),
            );
            _timeSlotsController.getData(
              appointmentModel?.doctorId.toString() ?? "",
              DateTimeHelper.getDayName(dateParse.weekday),
              appointmentModel?.type == "Video Consultant" ? "2" : "1",
            );
            _bookedTimeSlotsController.getData(
              appointmentModel?.doctorId.toString() ?? "",
              _selectedDate,
              appointmentModel?.type ?? "",
            );
          });
        },
      ),
    );
  }

  Widget _slotsGridView(
      setStatem,
      List<TimeSlotsModel> timeSlots,
      List<BookedTimeSlotsModel> bookedTimeSlots,
      ) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: timeSlots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 2 / 1,
        crossAxisCount: 3,
      ),
      itemBuilder: (BuildContext context, int index) {
        return buildTimeSlots(
          timeSlots[index].timeStart ?? "--",
          timeSlots[index].timeEnd ?? "--",
          setState,
          bookedTimeSlots,
        );
      },
    );
  }

  Widget buildTimeSlots(
      String timeStart,
      String timeEnd,
      setState,
      bookedTimeSlots,
      ) {
    return GestureDetector(
      onTap: getCheckBookedTimeSlot(timeStart, bookedTimeSlots)
          ? null
          : () {
        if (_selectedDate == appointmentModel?.date) {
          String appointmentTime = appointmentModel?.timeSlot ?? "";
          final splitSelectedTime = timeStart;
          final splitAppointmentTime = appointmentTime.split(":");
          if (splitAppointmentTime[0] == splitSelectedTime[0]) {
            if (splitAppointmentTime[1] == splitSelectedTime[1]) {
              IToastMsg.showMessage("select_the_different_time".tr);
              return;
            }
          }
        }
        _setTime = timeStart;
        setState(() {});
        this.setState(() {});
        Get.back();
        _openDialogBox();
      },
      child: Card(
        color: getCheckBookedTimeSlot(timeStart, bookedTimeSlots)
            ? Colors.red
            : _setTime == timeStart
            ? ColorResources.primaryColor
            : Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              "$timeStart - $timeEnd",
              style: TextStyle(
                color: timeStart == _setTime ? Colors.white : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool getCheckBookedTimeSlot(
      String timeStart,
      List<BookedTimeSlotsModel> bookedTimeSlots,
      ) {
    bool retuenValue = false;
    for (var element in bookedTimeSlots) {
      if (element.timeSlots == timeStart) {
        retuenValue = true;
        break;
      }
    }
    return retuenValue;
  }

  Future _openBottomSheet() {
    return showModalBottomSheet(
      backgroundColor: ColorResources.bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.0),
          topLeft: Radius.circular(20.0),
        ),
      ),
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'choose_prescription_mode'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: ColorResources.cardBgColor,
                        elevation: .1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.edit,
                            color: ColorResources.btnColor,
                            size: 20,
                          ),
                          title: Text(
                            "hand_written_mode".tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            Get.back();
                            PrescriptionPreFieldModel
                            prescriptionPreFieldModel =
                            PrescriptionPreFieldModel(
                              patientId:
                              appointmentModel?.patientId.toString() ?? "",
                              doctorDept:
                              appointmentModel?.departmentTitle ?? "",
                              doctorName:
                              "${appointmentModel?.doctFName ?? ""} ${appointmentModel?.doctLName ?? ""}",
                              doctorSpec:
                              appointmentModel?.doctSpecialization ?? "",
                              patientAge: appointmentModel!.pDob == null
                                  ? ""
                                  : DateTimeHelper.calculateAge(
                                  appointmentModel!.pDob!)
                                  .toString(),
                              patientGender: appointmentModel?.pGender ?? "",
                              patientName:
                              "${appointmentModel?.pFName ?? ""} ${appointmentModel?.pLName ?? ""}",
                              patientPhone: appointmentModel?.pPhone ?? "",
                              appointmentID:
                              appointmentModel?.id.toString() ?? "",
                              clinicId:
                              appointmentModel?.clinicId.toString(),
                            );
                            Get.to(
                                  () => WritePrescriptionPage(
                                prescriptionPreFieldModel:
                                prescriptionPreFieldModel,
                                prescriptionModel: null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        color: ColorResources.cardBgColor,
                        elevation: .1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.pending_actions,
                            color: ColorResources.btnColor,
                            size: 20,
                          ),
                          title: Text(
                            "predefined_mode".tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            Get.back();
                            Get.toNamed(
                              RouteHelper.getAddPrescriptionPageRoute(
                                appId: widget.appId ?? "",
                                prescriptionId: "",
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {});
  }
}
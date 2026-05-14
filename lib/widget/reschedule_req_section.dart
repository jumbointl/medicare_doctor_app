import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/appointment_reschedule_req_controller.dart';
import '../model/appointment_reschedule_req_model.dart';

class RescheduleReqSection extends StatelessWidget {
  final String appointmentId;
  final VoidCallback? onChanged;
  const RescheduleReqSection({
    super.key,
    required this.appointmentId,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      AppointmentRescheduleReqController(),
      tag: 'resch_$appointmentId',
    );
    controller.getByAppointmentId(appointmentId: appointmentId);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final initiated = controller.dataList
          .where((r) => r.status == 'Initiated')
          .toList();
      if (initiated.isEmpty) return const SizedBox.shrink();

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pending reschedule requests',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...initiated.map((r) => _RescheduleReqRow(
                    request: r,
                    onApprove: () => _approve(controller, r),
                    onReject: () => _reject(context, controller, r),
                  )),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _approve(
    AppointmentRescheduleReqController controller,
    AppointmentRescheduleReqModel r,
  ) async {
    if (r.id == null) return;
    final ok = await controller.approve(requestId: r.id.toString());
    if (ok) {
      controller.getByAppointmentId(appointmentId: appointmentId);
      onChanged?.call();
      Get.snackbar('Approved', 'Reschedule request approved');
    } else {
      Get.snackbar('Error', 'Could not approve');
    }
  }

  Future<void> _reject(
    BuildContext context,
    AppointmentRescheduleReqController controller,
    AppointmentRescheduleReqModel r,
  ) async {
    if (r.id == null) return;
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('reject_reschedule_request'.tr),
        content: TextField(
          controller: notesCtrl,
          decoration: InputDecoration(labelText: 'reason_optional'.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('reject'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.reject(
      requestId: r.id.toString(),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );
    if (ok) {
      controller.getByAppointmentId(appointmentId: appointmentId);
      onChanged?.call();
      Get.snackbar('Rejected', 'Reschedule request rejected');
    } else {
      Get.snackbar('Error', 'Could not reject');
    }
  }
}

class _RescheduleReqRow extends StatelessWidget {
  final AppointmentRescheduleReqModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RescheduleReqRow({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${'to_label'.tr}${request.requestedDate ?? '-'}  ${request.requestedTimeSlots ?? '-'}'),
          if ((request.notes ?? '').isNotEmpty)
            Text('${'notes_label'.tr}${request.notes}', style: const TextStyle(fontSize: 12)),
          Row(
            children: [
              TextButton(onPressed: onApprove, child: Text('approve'.tr)),
              TextButton(onPressed: onReject, child: Text('reject'.tr)),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}

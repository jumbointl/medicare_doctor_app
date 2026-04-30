import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/my_clinics_controller.dart';
import '../model/doctor_clinic_model.dart';
import '../service/update_doctor_clinic_service.dart';
import '../utilities/colors_constant.dart';
import 'toast_message.dart';

/// Per-clinic editor under the Profile tab.
///
/// Lets the doctor pick one of their clinics from a local dropdown and edit
/// the row's `active`, `stop_booking`, `opd_clinic`, `video_clinic`,
/// `emergency_clinic` flags + per-clinic fees. Saves through
/// [UpdateDoctorClinicService.update].
class DoctorProfilePerClinicForm extends StatefulWidget {
  /// doctor_id (from doctors table) — needed by the backend even though the
  /// row lookup uses user_id. Coming from MyClinicsController rows.
  final int doctorId;

  /// user_id of the logged-in doctor. Used to re-fetch
  /// MyClinicsController.clinics after a successful save so the dropdown
  /// reflects the updated values.
  final String userId;

  const DoctorProfilePerClinicForm({
    super.key,
    required this.doctorId,
    required this.userId,
  });

  @override
  State<DoctorProfilePerClinicForm> createState() =>
      _DoctorProfilePerClinicFormState();
}

class _DoctorProfilePerClinicFormState
    extends State<DoctorProfilePerClinicForm> {
  final MyClinicsController _clinicsController = Get.find<MyClinicsController>();
  DoctorClinicModel? _selected;
  bool _saving = false;

  bool _active = false;
  bool _stopBooking = false;
  bool _opdClinic = false;
  bool _videoClinic = false;
  bool _emergencyClinic = false;
  bool _autoResch = false;
  bool _videoAutoResch = false;
  final TextEditingController _opdFeeCtrl = TextEditingController();
  final TextEditingController _videoFeeCtrl = TextEditingController();
  final TextEditingController _emergencyFeeCtrl = TextEditingController();
  final TextEditingController _autoReschMinCtrl = TextEditingController();
  final TextEditingController _videoAutoReschMinCtrl = TextEditingController();
  final TextEditingController _noAvailStartCtrl = TextEditingController();
  final TextEditingController _noAvailEndCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _active = false;
    _stopBooking = false;
    _opdClinic = false;
    _videoClinic = false;
    _emergencyClinic = false;
    _autoResch = false;
    _videoAutoResch = false;
  }

  @override
  void dispose() {
    _opdFeeCtrl.dispose();
    _videoFeeCtrl.dispose();
    _emergencyFeeCtrl.dispose();
    _autoReschMinCtrl.dispose();
    _videoAutoReschMinCtrl.dispose();
    _noAvailStartCtrl.dispose();
    _noAvailEndCtrl.dispose();
    super.dispose();
  }

  /// Strips the time portion from a "yyyy-MM-dd HH:mm:ss" so we only deal
  /// with calendar dates in the picker.
  String _toDateOnly(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.contains(' ') ? raw.split(' ').first : raw;
  }

  void _populateFromModel(DoctorClinicModel m) {
    setState(() {
      _selected = m;
      _active = (m.active ?? 1) == 1;
      _stopBooking = (m.stopBooking ?? 0) == 1;
      _opdClinic = (m.opdClinic ?? 1) == 1;
      _videoClinic = (m.videoClinic ?? 1) == 1;
      _emergencyClinic = (m.emergencyClinic ?? 1) == 1;
      _opdFeeCtrl.text = m.opdFee?.toString() ?? '';
      _videoFeeCtrl.text = m.videoCFee?.toString() ?? '';
      _emergencyFeeCtrl.text = m.emergencyFee?.toString() ?? '';
      _autoResch = (m.autoRescheduledAllowed ?? 0) == 1;
      _videoAutoResch = (m.videoAutoRescheduledAllowed ?? 0) == 1;
      _autoReschMinCtrl.text =
          (m.autoRescheduledAllowedBeforeMinutes ?? 0).toString();
      _videoAutoReschMinCtrl.text =
          (m.videoAutoRescheduledAllowedBeforeMinutes ?? 0).toString();
      _noAvailStartCtrl.text = _toDateOnly(m.noAvailableDateStart);
      _noAvailEndCtrl.text = _toDateOnly(m.noAvailableDateEnd);
    });
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() => ctrl.text = iso);
  }

  Future<void> _handleSave() async {
    final selected = _selected;
    if (selected == null || selected.clinicId == null) return;

    setState(() => _saving = true);
    final startTrimmed = _noAvailStartCtrl.text.trim();
    final endTrimmed = _noAvailEndCtrl.text.trim();
    final ok = await UpdateDoctorClinicService.update(
      doctorId: widget.doctorId,
      clinicId: selected.clinicId!,
      active: _active ? 1 : 0,
      stopBooking: _stopBooking ? 1 : 0,
      opdClinic: _opdClinic ? 1 : 0,
      videoClinic: _videoClinic ? 1 : 0,
      emergencyClinic: _emergencyClinic ? 1 : 0,
      opdFee: _opdClinic ? num.tryParse(_opdFeeCtrl.text.trim()) : null,
      videoCFee: _videoClinic ? num.tryParse(_videoFeeCtrl.text.trim()) : null,
      emergencyFee:
          _emergencyClinic ? num.tryParse(_emergencyFeeCtrl.text.trim()) : null,
      autoRescheduledAllowed: _autoResch ? 1 : 0,
      autoRescheduledAllowedBeforeMinutes:
          _autoResch ? int.tryParse(_autoReschMinCtrl.text.trim()) ?? 0 : 0,
      videoAutoRescheduledAllowed: _videoAutoResch ? 1 : 0,
      videoAutoRescheduledAllowedBeforeMinutes: _videoAutoResch
          ? int.tryParse(_videoAutoReschMinCtrl.text.trim()) ?? 0
          : 0,
      noAvailableDateStart: startTrimmed.isEmpty ? null : startTrimmed,
      noAvailableDateEnd: endTrimmed.isEmpty ? null : endTrimmed,
      clearNoAvailableDateStart: startTrimmed.isEmpty,
      clearNoAvailableDateEnd: endTrimmed.isEmpty,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    IToastMsg.showMessage(
      ok ? "saved_successfully".tr : "something_went_wrong".tr,
    );

    if (ok) {
      // Auto-refresh: re-fetch the clinic list so the dropdown reflects the
      // values just saved, and re-populate the form with the updated row.
      await _clinicsController.loadForUser(widget.userId);
      if (!mounted) return;
      final updated = _clinicsController.clinics
          .firstWhereOrNull((c) => c.clinicId == selected.clinicId);
      if (updated != null) {
        _populateFromModel(updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final clinics = _clinicsController.clinics;
      if (clinics.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "doctor_has_no_clinic_assigned".tr,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "select_a_clinic".tr,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DoctorClinicModel>(
                  isExpanded: true,
                  hint: Text("select_a_clinic".tr),
                  value: _selected != null
                      ? clinics.firstWhereOrNull(
                          (c) => c.clinicId == _selected!.clinicId)
                      : null,
                  items: clinics
                      .map((c) => DropdownMenuItem<DoctorClinicModel>(
                            value: c,
                            child: Text(
                              c.clinicTitle ?? '#${c.clinicId}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (m) {
                    if (m != null) _populateFromModel(m);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selected != null) ...[
              _buildSwitchTile(
                title: "clinic_active".tr,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              _buildSwitchTile(
                title: "stop_booking".tr,
                value: _stopBooking,
                onChanged: (v) => setState(() => _stopBooking = v),
              ),
              const Divider(height: 24),
              _buildAppointmentTypeRow(
                title: "opd_short".tr,
                enabled: _opdClinic,
                onEnabledChanged: (v) => setState(() => _opdClinic = v),
                feeController: _opdFeeCtrl,
              ),
              _buildAppointmentTypeRow(
                title: "video_short".tr,
                enabled: _videoClinic,
                onEnabledChanged: (v) => setState(() => _videoClinic = v),
                feeController: _videoFeeCtrl,
              ),
              _buildAppointmentTypeRow(
                title: "emergency_short".tr,
                enabled: _emergencyClinic,
                onEnabledChanged: (v) => setState(() => _emergencyClinic = v),
                feeController: _emergencyFeeCtrl,
              ),

              const Divider(height: 24),
              Text(
                "auto_reschedule".tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _buildAutoReschRow(
                title: "opd_short".tr,
                enabled: _autoResch,
                onEnabledChanged: (v) => setState(() => _autoResch = v),
                minutesController: _autoReschMinCtrl,
              ),
              _buildAutoReschRow(
                title: "video_short".tr,
                enabled: _videoAutoResch,
                onEnabledChanged: (v) => setState(() => _videoAutoResch = v),
                minutesController: _videoAutoReschMinCtrl,
              ),

              const Divider(height: 24),
              Text(
                "no_availability_range".tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      label: "from".tr,
                      controller: _noAvailStartCtrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dateField(
                      label: "to".tr,
                      controller: _noAvailEndCtrl,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: "clear".tr,
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _noAvailStartCtrl.clear();
                              _noAvailEndCtrl.clear();
                            }),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResources.appBarColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saving ? null : _handleSave,
                  child: Text(
                    _saving ? "loading_dots".tr : "save".tr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildAppointmentTypeRow({
    required String title,
    required bool enabled,
    required ValueChanged<bool> onEnabledChanged,
    required TextEditingController feeController,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Switch(value: enabled, onChanged: onEnabledChanged),
            ],
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: TextField(
                controller: feeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: "fee".tr,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Auto-reschedule policy row: switch + minutes input (1440 = 1 day).
  Widget _buildAutoReschRow({
    required String title,
    required bool enabled,
    required ValueChanged<bool> onEnabledChanged,
    required TextEditingController minutesController,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Switch(value: enabled, onChanged: onEnabledChanged),
            ],
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: "before_minutes".tr,
                  hintText: "1440",
                  helperText: "1440_one_day".tr,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Read-only field that opens a date picker on tap.
  Widget _dateField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: _saving ? null : () => _pickDate(controller),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
      ),
    );
  }
}

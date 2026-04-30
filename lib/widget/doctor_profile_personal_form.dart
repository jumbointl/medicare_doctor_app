import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../model/doctors_model.dart';
import '../model/user_model.dart';
import '../service/update_doctor_service.dart';
import '../utilities/api_content.dart';
import '../utilities/colors_constant.dart';
import 'image_box_widget.dart';
import 'toast_message.dart';

/// Personal-info editor under the Profile tab. Edits the user's name, email,
/// phone, address and avatar via [UpdateDoctorService.updatePersonal] /
/// [UpdateDoctorService.uploadImage] / [UpdateDoctorService.removeImage].
class DoctorProfilePersonalForm extends StatefulWidget {
  final UserModel? userModel;
  final DoctorsModel? doctorsModel;

  /// Notified after a successful save so the parent can re-fetch and update
  /// the cached models / avatars.
  final VoidCallback? onChanged;

  const DoctorProfilePersonalForm({
    super.key,
    required this.userModel,
    required this.doctorsModel,
    this.onChanged,
  });

  @override
  State<DoctorProfilePersonalForm> createState() =>
      _DoctorProfilePersonalFormState();
}

class _DoctorProfilePersonalFormState extends State<DoctorProfilePersonalForm> {
  // Plain `final` instead of `late final` so hot-reload re-creates the
  // controllers without the LateInitializationError that bites when fields
  // are added between reloads.
  final TextEditingController _fName = TextEditingController();
  final TextEditingController _lName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _isdCode = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _postalCode = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _specialization = TextEditingController();
  final TextEditingController _exYear = TextEditingController();

  String? _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fName.text = widget.userModel?.fName ?? '';
    _lName.text = widget.userModel?.lName ?? '';
    _email.text = widget.userModel?.email ?? '';
    _phone.text = widget.userModel?.phone ?? '';
    _isdCode.text = widget.userModel?.isdCode ?? '';
    _dob.text = widget.userModel?.dob ?? '';
    _address.text = widget.userModel?.address ?? '';
    _city.text = widget.userModel?.city ?? '';
    _state.text = widget.userModel?.state ?? '';
    _postalCode.text = widget.userModel?.postalCode ?? '';
    _description.text = widget.doctorsModel?.desc ?? '';
    _specialization.text = widget.doctorsModel?.specialization ?? '';
    _exYear.text = widget.doctorsModel?.exYear?.toString() ?? '';
    _gender = widget.userModel?.gender;
  }

  @override
  void didUpdateWidget(covariant DoctorProfilePersonalForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userModel != widget.userModel) {
      _fName.text = widget.userModel?.fName ?? '';
      _lName.text = widget.userModel?.lName ?? '';
      _email.text = widget.userModel?.email ?? '';
      _phone.text = widget.userModel?.phone ?? '';
      _isdCode.text = widget.userModel?.isdCode ?? '';
      _dob.text = widget.userModel?.dob ?? '';
      _address.text = widget.userModel?.address ?? '';
      _city.text = widget.userModel?.city ?? '';
      _state.text = widget.userModel?.state ?? '';
      _postalCode.text = widget.userModel?.postalCode ?? '';
      _gender = widget.userModel?.gender;
    }
    if (oldWidget.doctorsModel != widget.doctorsModel) {
      _description.text = widget.doctorsModel?.desc ?? '';
      _specialization.text = widget.doctorsModel?.specialization ?? '';
      _exYear.text = widget.doctorsModel?.exYear?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _fName,
      _lName,
      _email,
      _phone,
      _isdCode,
      _dob,
      _address,
      _city,
      _state,
      _postalCode,
      _description,
      _specialization,
      _exYear,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDob() async {
    final initial = DateTime.tryParse(_dob.text) ?? DateTime(1990);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      _dob.text = iso;
    });
  }

  Future<void> _handleSave() async {
    final userId = widget.userModel?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    final exYearInt = int.tryParse(_exYear.text.trim());
    final ok = await UpdateDoctorService.updatePersonal(
      userId: userId,
      fName: _fName.text.trim(),
      lName: _lName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      isdCode: _isdCode.text.trim(),
      dob: _dob.text.trim(),
      gender: _gender,
      address: _address.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      postalCode: _postalCode.text.trim(),
      description: _description.text.trim(),
      specialization: _specialization.text.trim(),
      exYear: exYearInt,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    IToastMsg.showMessage(
      ok ? "saved_successfully".tr : "something_went_wrong".tr,
    );
    if (ok) widget.onChanged?.call();
  }

  Future<void> _pickAndUploadImage() async {
    final userId = widget.userModel?.id;
    if (userId == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _saving = true);
    final ok = await UpdateDoctorService.uploadImage(
      userId: userId,
      image: File(picked.path),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    IToastMsg.showMessage(
      ok ? "saved_successfully".tr : "something_went_wrong".tr,
    );
    if (ok) widget.onChanged?.call();
  }

  Future<void> _removeImage() async {
    final userId = widget.userModel?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    final ok = await UpdateDoctorService.removeImage(userId: userId);
    if (!mounted) return;
    setState(() => _saving = false);
    IToastMsg.showMessage(
      ok ? "saved_successfully".tr : "something_went_wrong".tr,
    );
    if (ok) widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.userModel?.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar block.
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: ClipOval(
                  child: hasImage
                      ? ImageBoxFillWidget(
                          imageUrl: '${ApiContents.imageUrl}/$imageUrl',
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.person, size: 70),
                        ),
                ),
              ),
              if (hasImage)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    shape: const CircleBorder(),
                    color: Colors.red,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _saving ? null : _removeImage,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.delete,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _saving ? null : _pickAndUploadImage,
            icon: const Icon(Icons.upload),
            label: Text(hasImage ? "replace_image".tr : "upload_image".tr),
          ),
          const SizedBox(height: 12),

          _field("first_name".tr, _fName),
          _field("last_name".tr, _lName),
          _field("email".tr, _email,
              keyboardType: TextInputType.emailAddress),

          // Phone with country code (isd_code) on the left.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _isdCode,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "isd_code".tr,
                      hintText: "+595",
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "phone".tr,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Date of birth — opens a date picker, stores yyyy-MM-dd.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: TextField(
              controller: _dob,
              readOnly: true,
              onTap: _saving ? null : _pickDob,
              decoration: InputDecoration(
                labelText: "dob".tr,
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
              ),
            ),
          ),

          // Gender dropdown.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DropdownButtonFormField<String>(
              value: (_gender == 'Male' || _gender == 'Female') ? _gender : null,
              decoration: InputDecoration(
                labelText: "gender".tr,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'Male', child: Text("male".tr)),
                DropdownMenuItem(value: 'Female', child: Text("female".tr)),
              ],
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _gender = v),
            ),
          ),

          _field("specialization".tr, _specialization),
          _field("years_of_experience".tr, _exYear,
              keyboardType: TextInputType.number),
          _field("address".tr, _address),
          _field("city".tr, _city),
          _field("state".tr, _state),
          _field("postal_code".tr, _postalCode),
          _field("description".tr, _description, maxLines: 4),

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
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

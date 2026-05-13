import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/appointment_controller.dart';
import '../model/appointment_model.dart';
import 'loading_indicator_widget.dart';

/// Filter modes for the home appointments tabs. The list comes from a single
/// fetch in [AppointmentController]; we partition it client-side to avoid
/// extra server hits.
enum AppointmentMode { today, past, future }

class AppointmentTabView extends StatefulWidget {
  final AppointmentController controller;
  final AppointmentMode mode;
  final Widget Function(AppointmentModel) cardBuilder;
  final Future<void> Function() onRefresh;

  const AppointmentTabView({
    super.key,
    required this.controller,
    required this.mode,
    required this.cardBuilder,
    required this.onRefresh,
  });

  @override
  State<AppointmentTabView> createState() => _AppointmentTabViewState();
}

class _AppointmentTabViewState extends State<AppointmentTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static String _todayString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Backend returns DATE columns as full ISO ("2026-05-11T00:00:00.000Z"),
  // so a raw == against today ("2026-05-11") never matches.
  static String _dayOnly(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.split('T').first.split(' ').first;
  }

  static String _sortTimeKey(String? slot) {
    if (slot == null || slot.isEmpty) return '';
    return slot.split('-').first.trim();
  }

  static int _ascCompare(AppointmentModel a, AppointmentModel b) {
    final cd = _dayOnly(a.date).compareTo(_dayOnly(b.date));
    if (cd != 0) return cd;
    return _sortTimeKey(a.timeSlot).compareTo(_sortTimeKey(b.timeSlot));
  }

  static int _descCompare(AppointmentModel a, AppointmentModel b) =>
      _ascCompare(b, a);

  /// Parses HH:mm (or HH:mm:ss, HH:mm AM/PM) from the first chunk of a
  /// "HH:mm - HH:mm" range. Returns null when unparseable.
  static DateTime? _appointmentEnd(AppointmentModel a) {
    final dateStr = a.date;
    final slot = a.timeSlot;
    if (dateStr == null || dateStr.isEmpty || slot == null || slot.isEmpty) {
      return null;
    }
    final dayPart = DateTime.tryParse(dateStr);
    if (dayPart == null) return null;
    final firstChunk = slot.split('-').first.trim().toUpperCase();
    final isPm = firstChunk.endsWith('PM');
    final isAm = firstChunk.endsWith('AM');
    final cleaned = firstChunk
        .replaceAll('AM', '')
        .replaceAll('PM', '')
        .trim();
    final hm = cleaned.split(':');
    if (hm.length < 2) return null;
    int? h = int.tryParse(hm[0]);
    final m = int.tryParse(hm[1]);
    if (h == null || m == null) return null;
    if (isPm && h < 12) h += 12;
    if (isAm && h == 12) h = 0;
    final start = DateTime(
      dayPart.year,
      dayPart.month,
      dayPart.day,
      h,
      m,
    );
    final dur = a.durationMinutes ?? 30;
    return start.add(Duration(minutes: dur));
  }

  List<AppointmentModel> _filterAndSort(List<AppointmentModel> all) {
    final today = _todayString();
    final now = DateTime.now();
    switch (widget.mode) {
      case AppointmentMode.today:
        // Citas de hoy cuyo (start + duration) aún no pasó.
        final list = all.where((a) {
          if (_dayOnly(a.date) != today) return false;
          final end = _appointmentEnd(a);
          if (end == null) return true; // sin hora parseable: la mostramos
          return end.isAfter(now);
        }).toList();
        list.sort(_ascCompare);
        return list;
      case AppointmentMode.past:
        // Pasadas: fecha anterior O (hoy y end <= now).
        final list = all.where((a) {
          final d = _dayOnly(a.date);
          if (d.isEmpty) return false;
          if (d.compareTo(today) < 0) return true;
          if (d == today) {
            final end = _appointmentEnd(a);
            if (end == null) return false;
            return !end.isAfter(now);
          }
          return false;
        }).toList();
        list.sort(_descCompare);
        return list;
      case AppointmentMode.future:
        final list = all
            .where((a) => _dayOnly(a.date).compareTo(today) > 0)
            .toList();
        list.sort(_ascCompare);
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // RefreshIndicator just needs a Scrollable descendant; it tolerates the
    // intermediate Obx that SmartRefresher couldn't see through.
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Obx(() {
        if (widget.controller.isLoading.value) {
          return const IVerticalListLongLoadingWidget();
        }
        if (widget.controller.isError.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "something_went_wrong".tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }
        final filtered = _filterAndSort(widget.controller.dataList);
        if (filtered.isEmpty) {
          return ListView(
            // AlwaysScrollable so RefreshIndicator triggers even when the
            // list has no items and the viewport isn't filled.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(40),
            children: [
              Center(
                child: Text(
                  "no_appointment_found".tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );
        }
        // For Today, surface a small card with countdown to the next
        // appointment so the doctor sees how long they have to prepare.
        final showCountdown = widget.mode == AppointmentMode.today;
        final headerCount = showCountdown ? 1 : 0;
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          itemCount: filtered.length + headerCount,
          itemBuilder: (_, i) {
            if (showCountdown && i == 0) {
              return _buildNextAppointmentCard(filtered);
            }
            final a = filtered[i - headerCount];
            final color = _typeColor(a);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: color, width: 5),
                ),
              ),
              child: widget.cardBuilder(a),
            );
          },
        );
      }),
    );
  }

  Widget _buildNextAppointmentCard(List<AppointmentModel> sortedToday) {
    if (sortedToday.isEmpty) {
      return const SizedBox.shrink();
    }
    final next = sortedToday.first;
    final start = _appointmentStart(next);
    final now = DateTime.now();
    String message;
    Color tint;
    if (start == null) {
      message = "${"next".tr}: ${next.timeSlot ?? '-'}";
      tint = Colors.blue.shade50;
    } else if (start.isAfter(now)) {
      final diff = start.difference(now);
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      final formatted = h > 0
          ? "${h}h ${m}m"
          : "${m}m";
      message = "${"next_in".tr} $formatted";
      tint = Colors.blue.shade50;
    } else {
      message = "${"in_progress".tr}";
      tint = Colors.green.shade50;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${next.pFName ?? ''} ${next.pLName ?? ''}  ·  ${next.timeSlot ?? ''}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Same parser as _appointmentEnd but returns the start time.
  static DateTime? _appointmentStart(AppointmentModel a) {
    final dateStr = a.date;
    final slot = a.timeSlot;
    if (dateStr == null || dateStr.isEmpty || slot == null || slot.isEmpty) {
      return null;
    }
    final dayPart = DateTime.tryParse(dateStr);
    if (dayPart == null) return null;
    final firstChunk = slot.split('-').first.trim().toUpperCase();
    final isPm = firstChunk.endsWith('PM');
    final isAm = firstChunk.endsWith('AM');
    final cleaned = firstChunk
        .replaceAll('AM', '')
        .replaceAll('PM', '')
        .trim();
    final hm = cleaned.split(':');
    if (hm.length < 2) return null;
    int? h = int.tryParse(hm[0]);
    final m = int.tryParse(hm[1]);
    if (h == null || m == null) return null;
    if (isPm && h < 12) h += 12;
    if (isAm && h == 12) h = 0;
    return DateTime(dayPart.year, dayPart.month, dayPart.day, h, m);
  }

  /// Maps the appointment.type to a brand color used for the left border of
  /// each card. Falls back to grey for unknown types.
  static Color _typeColor(AppointmentModel a) {
    final t = (a.type ?? '').toLowerCase();
    if (t.contains('video')) return Colors.blue.shade600;
    if (t.contains('emergency') || t.contains('emerg')) {
      return Colors.purple.shade600;
    }
    if (t.contains('opd') || t.contains('clinic')) {
      return Colors.green.shade600;
    }
    if (a.isVideoConsult == true) return Colors.blue.shade600;
    return Colors.grey.shade400;
  }
}

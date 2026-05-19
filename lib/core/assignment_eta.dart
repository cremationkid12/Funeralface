import 'package:flutter/material.dart';

/// Parses API `eta_time` (UTC ISO) into local [TimeOfDay] for pickers and labels.
TimeOfDay? etaTimeFromAssignmentValue(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;

  final instant = parsed.toUtc();
  final local = instant.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final localDay = DateTime(local.year, local.month, local.day);
  final utcDay = DateTime.utc(instant.year, instant.month, instant.day);

  if (localDay == today) {
    return TimeOfDay(hour: local.hour, minute: local.minute);
  }
  if (utcDay == today || utcDay == today.subtract(const Duration(days: 1))) {
    return TimeOfDay(hour: instant.hour, minute: instant.minute);
  }
  return TimeOfDay(hour: local.hour, minute: local.minute);
}

DateTime? _etaLocalDateTimeFromTimeOfDay(TimeOfDay? time) {
  if (time == null) return null;
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, time.hour, time.minute);
}

/// UTC ISO (`...Z`) for API payloads.
String? etaTimeToApiValue(TimeOfDay? time) {
  final local = _etaLocalDateTimeFromTimeOfDay(time);
  return local?.toUtc().toIso8601String();
}
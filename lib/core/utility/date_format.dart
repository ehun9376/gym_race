import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";

class DateFormatter {
  static String getFormattedDate(
    DateTime? dateTime, [
    String formate = "yyyy-MM-dd",
  ]) {
    String formattedDate = DateFormat(
      formate,
    ).format(dateTime ?? DateTime.now());
    return formattedDate;
  }

  static String getFormatterTime(TimeOfDay? timeOfDay, BuildContext context) {
    if (timeOfDay == null) {
      return "";
    }
    String formattedTime = timeOfDay.format(context);
    return formattedTime;
  }

  static DateTime parseToDateDate(String dateTimeString) {
    return DateFormat("yyyy-MM-dd").parse(dateTimeString);
  }
}

extension StringDate on String {
  DateTime toDateTime() {
    return DateFormat("yyyy-MM-dd HH:mm").parse(this);
  }
}

extension DateString on DateTime {
  String toText({String formatter = "yyyy-MM-dd"}) {
    return DateFormat(formatter.tr()).format(this);
  }
}

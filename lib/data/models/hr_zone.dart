import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

enum HrZone { rest, fatBurn, aerobic, anaerobic, max }

extension HrZoneLabel on HrZone {
  String get label {
    switch (this) {
      case HrZone.rest:
        return 'Reposo';
      case HrZone.fatBurn:
        return 'Quema grasa';
      case HrZone.aerobic:
        return 'Aeróbica';
      case HrZone.anaerobic:
        return 'Anaeróbica';
      case HrZone.max:
        return 'Máxima';
    }
  }

  Color get color {
    switch (this) {
      case HrZone.rest:
        return AppColors.zoneRest;
      case HrZone.fatBurn:
        return AppColors.zoneFatBurn;
      case HrZone.aerobic:
        return AppColors.zoneAerobic;
      case HrZone.anaerobic:
        return AppColors.zoneAnaerobic;
      case HrZone.max:
        return AppColors.zoneMax;
    }
  }
}

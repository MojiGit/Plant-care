enum WaterNeed { dry, moist, wet }

enum LightCondition { low, indirect, direct }

enum SoilType { draining, normal, retaining }

enum CheckResult { watered, allGood, remindLater }

class CarePlanEngine {
  /// Calculates how many days until the next soil check reminder.
  static int checkInterval({
    required WaterNeed waterNeed,
    required LightCondition light,
    required SoilType soil,
  }) {
    final base = switch (waterNeed) {
      WaterNeed.dry   => 14,
      WaterNeed.moist =>  7,
      WaterNeed.wet   =>  4,
    };

    final lightAdjust = switch (light) {
      LightCondition.direct   => -2,
      LightCondition.indirect =>  0,
      LightCondition.low      =>  3,
    };

    final soilAdjust = switch (soil) {
      SoilType.draining  => -1,
      SoilType.normal    =>  0,
      SoilType.retaining =>  2,
    };

    return (base + lightAdjust + soilAdjust).clamp(2, 30);
  }

  /// Returns the next due date based on how the user responded to the reminder.
  static DateTime nextDueAt({
    required CheckResult result,
    required int interval,
    DateTime? from,
  }) {
    final base = from ?? DateTime.now();
    return switch (result) {
      CheckResult.watered     => base.add(Duration(days: interval)),
      CheckResult.allGood     => base.add(const Duration(days: 3)),
      CheckResult.remindLater => base.add(const Duration(days: 1)),
    };
  }

  /// Human-readable label for the watering need (from Plant.id value 1-3).
  static WaterNeed waterNeedFromInt(int value) => switch (value) {
        1 => WaterNeed.dry,
        3 => WaterNeed.wet,
        _ => WaterNeed.moist,
      };
}

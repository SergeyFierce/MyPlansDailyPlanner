import 'dart:math' as math;

class SunriseSunsetResult {
  const SunriseSunsetResult({
    this.sunriseUtc,
    this.sunsetUtc,
    this.solarNoonUtc,
  });

  final DateTime? sunriseUtc;
  final DateTime? sunsetUtc;
  final DateTime? solarNoonUtc;
}

class SunriseSunsetCalculator {
  const SunriseSunsetCalculator();

  SunriseSunsetResult calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final sunriseHour = _calculateUtcHour(
      day: day,
      latitude: latitude,
      longitude: longitude,
      isSunrise: true,
    );
    final sunsetHour = _calculateUtcHour(
      day: day,
      latitude: latitude,
      longitude: longitude,
      isSunrise: false,
    );

    DateTime? sunriseUtc;
    DateTime? sunsetUtc;

    if (sunriseHour != null) {
      sunriseUtc = day.add(Duration(milliseconds: (sunriseHour * 3600000).round()));
    }

    if (sunsetHour != null) {
      sunsetUtc = day.add(Duration(milliseconds: (sunsetHour * 3600000).round()));
    }

    DateTime? solarNoonUtc;
    if (sunriseUtc != null && sunsetUtc != null) {
      final diff = sunsetUtc.difference(sunriseUtc);
      solarNoonUtc = sunriseUtc.add(Duration(milliseconds: diff.inMilliseconds ~/ 2));
    } else {
      solarNoonUtc = day.add(const Duration(hours: 12));
    }

    return SunriseSunsetResult(
      sunriseUtc: sunriseUtc,
      sunsetUtc: sunsetUtc,
      solarNoonUtc: solarNoonUtc,
    );
  }

  double? _calculateUtcHour({
    required DateTime day,
    required double latitude,
    required double longitude,
    required bool isSunrise,
  }) {
    final zenith = 90.83333333333333;
    final lngHour = longitude / 15.0;
    final n = _dayOfYear(day);
    final t = n + ((isSunrise ? 6.0 : 18.0) - lngHour) / 24.0;

    final m = (0.9856 * t) - 3.289;

    var l = m + (1.916 * _sinDeg(m)) + (0.020 * _sinDeg(2 * m)) + 282.634;
    l = _normalizeDegrees(l);

    var ra = _radToDeg(math.atan(0.91764 * _tanDeg(l)));
    ra = _normalizeDegrees(ra);

    final lQuadrant = (l / 90.0).floor() * 90.0;
    final raQuadrant = (ra / 90.0).floor() * 90.0;
    ra = ra + (lQuadrant - raQuadrant);
    ra /= 15.0;

    final sinDec = 0.39782 * _sinDeg(l);
    final cosDec = math.cos(math.asin(sinDec));

    final cosH =
        (math.cos(_degToRad(zenith)) - (sinDec * _sinDeg(latitude))) /
            (cosDec * _cosDeg(latitude));

    if (cosH > 1 || cosH < -1) {
      return null;
    }

    var h = isSunrise ? 360.0 - _radToDeg(math.acos(cosH)) : _radToDeg(math.acos(cosH));
    h /= 15.0;

    final tLocal = h + ra - (0.06571 * t) - 6.622;
    var ut = tLocal - lngHour;
    while (ut < 0) {
      ut += 24;
    }
    while (ut >= 24) {
      ut -= 24;
    }

    return ut;
  }

  int _dayOfYear(DateTime date) {
    final startOfYear = DateTime.utc(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
  double _radToDeg(double rad) => rad * (180.0 / math.pi);
  double _sinDeg(double deg) => math.sin(_degToRad(deg));
  double _cosDeg(double deg) => math.cos(_degToRad(deg));
  double _tanDeg(double deg) => math.tan(_degToRad(deg));

  double _normalizeDegrees(double value) {
    var result = value % 360.0;
    if (result < 0) {
      result += 360.0;
    }
    return result;
  }
}

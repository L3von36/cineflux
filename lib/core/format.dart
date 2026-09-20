/// Formatting helpers for telemetry & UI.
class Fmt {
  static String clock(Duration d) {
    final h = d.inHours, m = d.inMinutes.remainder(60), s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }

  static String kbps(num v) {
    if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)} Gbps';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} kbps';
    return '${v.toStringAsFixed(0)} bps';
  }

  static String bytes(num bytesTotal) {
    if (bytesTotal >= 1 << 30) return '${(bytesTotal / (1 << 30)).toStringAsFixed(1)} GB';
    if (bytesTotal >= 1 << 20) return '${(bytesTotal / (1 << 20)).toStringAsFixed(1)} MB';
    if (bytesTotal >= 1 << 10) return '${(bytesTotal / (1 << 10)).toStringAsFixed(0)} KB';
    return '${bytesTotal.toStringAsFixed(0)} B';
  }

  static String ms(num micros) {
    final v = micros / 1000;
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)} s';
    return '${v.toStringAsFixed(0)} ms';
  }

  static String pct(num v) => '${(v * 100).toStringAsFixed(0)}%';
}

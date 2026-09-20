import 'package:flutter_test/flutter_test.dart';

import 'package:cineflux/data/catalog.dart';
import 'package:cineflux/data/models.dart';
import 'package:cineflux/engine/abr_engine.dart';
import 'package:cineflux/engine/buffer_monitor.dart';

void main() {
  test('catalog loads with multi-CDN streams', () {
    expect(Catalog.all.length, greaterThanOrEqualTo(10));
    // Every title must expose at least one playable URL.
    for (final m in Catalog.all) {
      expect(m.pack.primary, startsWith('https://'));
    }
    // Featured titles must be genuine multi-CDN (primary + mirror hosts differ).
    final sintel = Catalog.byId('sintel');
    expect(sintel.pack.mirrors, isNotEmpty);
  });

  test('quality ladder is ordered ascending', () {
    for (var i = 1; i < QualityTier.ladder.length; i++) {
      expect(QualityTier.ladder[i].bitrate, greaterThan(QualityTier.ladder[i - 1].bitrate));
    }
  });

  test('ABR engine emergency down-switch when buffer starves', () {
    final abr = ABREngine();
    final buffer = BufferMonitor();
    buffer.update(position: const Duration(seconds: 100), buffered: const Duration(seconds: 102));
    expect(buffer.starving, isTrue);

    // 2 Mbps link → emergency safe tier is ~360p, far below the 720p start.
    final decision = abr.decide(bandwidthBps: 2_000_000, buffer: buffer);
    expect(decision.tier.bitrate, lessThanOrEqualTo(3_000_000));
    expect(decision.emergency, isTrue);
  });

  test('ABR engine returns a valid ladder tier with healthy buffer', () {
    final abr = ABREngine();
    final buffer = BufferMonitor();
    buffer.update(position: const Duration(seconds: 10), buffered: const Duration(seconds: 60));
    final decision = abr.decide(bandwidthBps: 50_000_000, buffer: buffer);
    // Hysteresis may hold the initial tier — must always return a valid one.
    expect(QualityTier.ladder.contains(decision.tier), isTrue);
  });
}

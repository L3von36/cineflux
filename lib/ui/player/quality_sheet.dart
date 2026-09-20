import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../engine/stream_session.dart';
import '../../engine/telemetry.dart';

/// The quality ladder sheet v2 — Auto (ABR engine decides) or lock a tier.
/// Each tier carries a log-scaled bitrate bar, a "best for your link"
/// recommendation badge and a stall warning, exactly like premium players.
void showQualitySheet(
  BuildContext context, {
  required StreamSession session,
  required StreamTelemetry telemetry,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final usable = telemetry.currentMbps;
      final tiers = QualityTier.ladder.reversed.toList();

      // Highest tier your measured link can comfortably hold.
      int? bestIdx;
      for (var i = 0; i < tiers.length; i++) {
        if (usable > 0 && tiers[i].bitrate <= usable * 0.8 * 1e6) bestIdx = i;
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(colors: AppTheme.aurora),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.high_quality_rounded, color: AppTheme.cyan, size: 18),
                  const SizedBox(width: 9),
                  const Text('Playback quality', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -.2)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHi,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cyan.withOpacity(.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_rounded, size: 12, color: AppTheme.green),
                        const SizedBox(width: 5),
                        Text(
                          '${usable.toStringAsFixed(1)} Mbps',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Text(
                'Auto lets the ABR engine hop ladders to protect playback. Locking forces a rendition.',
                style: TextStyle(fontSize: 12, color: AppTheme.textDim, height: 1.45),
              ),
            ),
            _TierRow(
              selected: session.abr.locked == null,
              title: 'Auto (ABR engine)',
              subtitle: 'buffer + bandwidth hybrid · hysteresis protected',
              onTap: () {
                session.setLockedTier(null);
                Navigator.of(context).pop();
              },
            ),
            for (var i = 0; i < tiers.length; i++)
              _TierRow(
                selected: session.abr.locked == tiers[i],
                title: '${tiers[i].label} — ${tiers[i].resolution}',
                subtitle: '${(tiers[i].bitrate / 1_000_000).toStringAsFixed(1)} Mbps target bitrate',
                bitrate: tiers[i].bitrate,
                recommended: bestIdx == i,
                mayStall: usable > 0 && tiers[i].bitrate / 1e6 > usable * 0.85,
                locked: session.abr.locked == tiers[i],
                onTap: () {
                  session.setLockedTier(tiers[i]);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

class _TierRow extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final int? bitrate;
  final bool recommended;
  final bool mayStall;
  final bool locked;
  final VoidCallback onTap;
  const _TierRow({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.bitrate,
    this.recommended = false,
    this.mayStall = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    // Log-scaled bar fraction across the 400 kbps → 18 Mbps ladder.
    double? frac;
    if (bitrate != null) {
      final lo = math.log(400000.0);
      final hi = math.log(QualityTier.ladder.last.bitrate.toDouble());
      frac = ((math.log(bitrate!.toDouble()) - lo) / (hi - lo)).clamp(0.08, 1.0).toDouble();
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 20),
        child: Row(
          children: [
            // Selection indicator.
            Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected ? const LinearGradient(colors: AppTheme.aurora) : null,
                border: selected ? null : Border.all(color: AppTheme.textDim, width: 1.6),
                boxShadow: selected ? [BoxShadow(color: AppTheme.indigo.withOpacity(.45), blurRadius: 10)] : null,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                            fontSize: 14,
                            color: selected ? AppTheme.textHi : AppTheme.textMid,
                          ),
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.green.withOpacity(.14),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppTheme.green.withOpacity(.4)),
                          ),
                          child: const Text(
                            'BEST FOR YOUR LINK',
                            style: TextStyle(fontSize: 7.5, letterSpacing: 1, fontWeight: FontWeight.w900, color: AppTheme.green),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppTheme.textDim)),
                  if (mayStall)
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.amber),
                          SizedBox(width: 4),
                          Text('may stall on your link', style: TextStyle(fontSize: 10.5, color: AppTheme.amber, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (frac != null) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 76,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceHi,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: frac,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: const LinearGradient(colors: AppTheme.aurora),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(bitrate! / 1e6).toStringAsFixed(1)}M',
                      style: const TextStyle(fontSize: 9, color: AppTheme.textDim, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
            if (locked && bitrate != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock_rounded, size: 14, color: AppTheme.cyan),
            ],
          ],
        ),
      ),
    );
  }
}

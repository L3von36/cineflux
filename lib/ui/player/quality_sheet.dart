import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../engine/stream_session.dart';
import '../../engine/telemetry.dart';

/// The quality ladder sheet — Auto (ABR engine decides) or lock a tier.
/// Each tier shows whether your current bandwidth could sustain it,
/// exactly like the "auto/lock" UX on premium players.
void showQualitySheet(
  BuildContext context, {
  required StreamSession session,
  required StreamTelemetry telemetry,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) {
      final usable = telemetry.currentMbps;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.high_quality_rounded, color: AppTheme.cyan, size: 18),
                  const SizedBox(width: 8),
                  const Text('Quality', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const Spacer(),
                  Text(
                    '${usable.toStringAsFixed(1)} Mbps measured',
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textMid),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Auto lets the ABR engine hop ladders to protect playback. Locking forces a rendition.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMid, height: 1.4),
              ),
              const SizedBox(height: 12),
              _TierRow(
                selected: session.abr.locked == null,
                title: 'Auto (ABR engine)',
                subtitle: 'buffer + bandwidth hybrid · hysteresis protected',
                onTap: () {
                  session.setLockedTier(null);
                  Navigator.of(context).pop();
                },
              ),
              for (final t in QualityTier.ladder.reversed)
                _TierRow(
                  selected: session.abr.locked == t,
                  title: '${t.label} — ${t.resolution}',
                  subtitle: '${(t.bitrate / 1_000_000).toStringAsFixed(1)} Mbps'
                      '${usable > 0 && t.bitrate / 1e6 > usable * 0.85 ? " · ⚠ may stall on your link" : ""}',
                  onTap: () {
                    session.setLockedTier(t);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _TierRow extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _TierRow({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: selected ? AppTheme.cyan : AppTheme.textMid,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMid)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

# 🎬 CineFlux

A cinematic, multi-platform movie streaming app built with **Flutter**, engineered with the
same delivery techniques that power Netflix, YouTube and Disney+ — adaptive bitrate
streaming, multi-CDN failover, buffer-aware quality switching, preload pipelines and a
live telemetry overlay (**Stream Lab**).

One codebase → **Android · iOS · Web · Windows · macOS · Linux**, built automatically by
GitHub Actions on every push.

---

## ✨ The signature: Stream Lab

Press **Stream Lab** inside the player and watch the invisible machinery work in real time:

- **Throughput graph** — EWMA bandwidth estimate vs active rendition bitrate vs buffer level
- **Engine counters** — ABR switches, CDN failovers, retries, preloads, probes
- **Decision log** — every quality hop, probe, retry and failover with the *reason* it happened

---

## 🧪 The research: how the giants stream

| Question | What Netflix / YouTube do | Where CineFlux implements it |
|---|---|---|
| How do they serve millions of concurrent viewers? | Content lives on many independent CDNs (Netflix's own **Open Connect** boxes sit *inside* ISP data centers, serving ~15% of global downstream traffic). Requests are routed to the nearest healthy edge; caches absorb ~95%+ of hits so the origin almost never sees viewers. | `cdn_selector.dart` probes every mirror host, ranks by latency, routes playback to the fastest edge. |
| Why don't streams break? | Segments are tiny (2–6s) and individually retried with **exponential backoff + jitter**. If a whole CDN degrades, the player **fails over to another CDN mid-playback** and recovers at the exact playhead. | `retry_policy.dart` + `_selfHeal()` in `stream_session.dart` — on stream errors CineFlux reports the failure, picks a healthier mirror, and reopens at the current position. |
| How is it fast even on slow networks? | Video is encoded on a **bitrate ladder** (240p → 4K) and chopped into segments. An **ABR algorithm** (throughput + buffer hybrid: BOLA/BBA) picks the highest rendition that fits *bandwidth × safety factor*; a draining buffer forces an emergency down-switch **before** the frame can freeze. **AV1/per-title encoding** squeezes ~50% more quality per bit. | `abr_engine.dart` (hybrid decisioning + hysteresis + emergency switch), `bandwidth_meter.dart` (EWMA estimation, like hls.js), `buffer_monitor.dart` (health + trend + confidence). |
| Why does "next" feel instant? | **Preload pipelines**: manifests are warmed (DNS+TLS+CDN cache) before you press play; the next episode's manifest is prefetched at ~85% completion. | `preload_manager.dart` — warmup before open, prefetch at 85%, mirror insurance warm. |
| Data caps? | Players cap ladders for metered connections. | **Data Saver** setting hard-caps the ABR ceiling at 480p. |

### Key numbers from the research

- Netflix Open Connect: **~15% of all global downstream internet traffic** (30%+ in North America peaks)
- CDN cache-hit ratios routinely exceed **95%** with tiered caching / Origin Shield
- AV1 delivers the same quality as H.264 at **~48% lower bitrate**
- ABR segments are typically **2–6 seconds**; emergency buffer threshold ≈ **4s**

---

## 🏗 Architecture

```
lib/
├── core/            theme (Material 3 cinematic) · format · app state
├── data/
│   ├── models.dart       Movie · StreamPack · QualityTier (bitrate ladder)
│   ├── catalog.dart      real multi-CDN streams (Mux, Akamai, Apple, GCS)
│   └── library_repo.dart resume positions · my list · settings
├── engine/          ★ the streaming magic
│   ├── bandwidth_meter.dart   EWMA throughput estimation (ranged probes)
│   ├── buffer_monitor.dart    buffer health · trend · confidence
│   ├── abr_engine.dart        BOLA-style hybrid ABR + hysteresis
│   ├── cdn_selector.dart      multi-CDN probing · steering · failover
│   ├── retry_policy.dart      exponential backoff + full jitter
│   ├── preload_manager.dart   manifest warmup · next-episode prefetch
│   ├── telemetry.dart         event log + datapoints for Stream Lab
│   └── stream_session.dart    the conductor (player ↔ engine)
└── ui/
    ├── screens/     shell (adaptive rail/bar) · home · detail · search · my list
    ├── player/      player screen · quality sheet · Stream Lab overlay
    └── widgets/     generated poster art (zero image fetches) · cards · shimmer
```

**Design decisions**

- **media_kit (mpv)** under the hood → one player for all 6 platforms, native HLS ladder support.
- **All artwork is generated locally** (gradient meshes, bloom, film grain) — the poster paints
  as fast as a frame, even on 2G. Nothing blocks first paint on the network.
- **Material 3** with an adaptive shell: NavigationRail on wide screens, NavigationBar on phones.
- Catalog streams are real public multi-CDN endpoints (Mux edge, Akamai, Apple CDN,
  Unified Streaming, Google Cloud Storage) so CDN probing and failover are **genuine**, not simulated.

## 🚀 Run it

```bash
flutter pub get
flutter run                    # picks your connected device
flutter run -d chrome          # web
flutter run -d windows|macos|linux
```

## 🤖 CI/CD

`.github/workflows/build.yml` builds on every push:

| Job | Targets | Artifacts |
|---|---|---|
| `build-android-web-linux` | APK · AAB · Web (wasm) · Linux | `cineflux-android-apk`, `cineflux-web`, `cineflux-linux-x64` |
| `build-windows` | Windows x64 | `cineflux-windows-x64` |
| `build-apple` | iOS (unsigned) · macOS | `cineflux-ios-unsigned`, `cineflux-macos` |
| `deploy-web` | GitHub Pages | live web app on main-branch pushes |

Artifacts attach to each run under **Actions → (run) → Artifacts**.

## 📝 Notes

- Web playback depends on each stream host sending CORS headers (mobile/desktop are unrestricted).
- iOS builds are unsigned; add signing to distribute through TestFlight/App Store.
- The ABR engine enforces quality caps via mpv's `hls-bitrate` on desktop/mobile where supported;
  on builds where the property is unavailable it degrades gracefully to mpv's native ABR while
  telemetry keeps flowing.

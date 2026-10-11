import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:faceping/faceping.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Your sandbox key: run with `--dart-define=FACEPING_SANDBOX_KEY=fp_test_yourkey`.
/// Get a free one at https://app.faceping.ai/signup (Developers > Sandbox keys > Create sandbox key).
const String sandboxKey = String.fromEnvironment(
  'FACEPING_SANDBOX_KEY',
  defaultValue: 'fp_test_…',
);

/// Check-in device mode: a device token (fpd_…, from your practice list's Devices tab or POST /v1/lists/{listId}/devices)
/// and the person to verify (their personId):
/// `--dart-define=FACEPING_DEVICE_TOKEN=fpd_yourtoken --dart-define=FACEPING_PERSON_ID=ACME-000123`.
/// With a device token, the app downloads that list's people instead of enrolling on the phone, and the sandbox key
/// is ignored.
const String deviceToken = String.fromEnvironment('FACEPING_DEVICE_TOKEN');
const String personIdSetting = String.fromEnvironment(
  'FACEPING_PERSON_ID',
  defaultValue: 'me',
);

/// Who to enrol and verify: "me" in the sandbox; on a check-in device, the personId you enrolled on the server.
final String personId = personIdSetting.trim().isEmpty
    ? 'me'
    : personIdSetting.trim();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Starts loading the face models in the background, so the first check is quick.
  String? setupProblem;
  try {
    if (deviceToken.trim().isEmpty) {
      await FacePing.init(sandboxKey: sandboxKey);
    } else {
      await FacePing.init(deviceToken: deviceToken.trim());
    }
  } on FacePingException catch (e) {
    // A missing or malformed key or token: the screen shows the message.
    setupProblem = e.message;
  }
  runApp(FaceCheckApp(setupProblem: setupProblem));
}

/// The colours of the other FaceCheck starters (MAUI, Android, iOS).
abstract final class Palette {
  static const ink = Color(0xFF0F172A);
  static const slate = Color(0xFF475569);
  static const green = Color(0xFF047857);
  static const red = Color(0xFFB91C1C);
  static const amber = Color(0xFFB45309);
  static const pill = Color(0xFFEAECF0);
  static const pillOffline = Color(0xFFFFF4E5);
  static const brand = Color(0xFF2563EB);
  static const outline = Color(0xFFCBD5E1);
  static const cameraBackground = Color(0xFF0B1220);
}

class FaceCheckApp extends StatelessWidget {
  const FaceCheckApp({super.key, this.setupProblem});

  final String? setupProblem;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceCheck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Palette.brand,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: CheckScreen(setupProblem: setupProblem),
    );
  }
}

/// The same screen as the MAUI, Android and iOS FaceCheck: the camera with the result over its bottom edge, then
/// Enrol my face and Verify. The pill says whether the phone has a network (the checks never need one).
class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key, this.setupProblem});

  final String? setupProblem;

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  final FacePingCameraController _camera = FacePingCameraController();
  final FacePing? _faceping = FacePing.currentOrNull;
  StreamSubscription<List<ConnectivityResult>>? _network;
  StreamSubscription<SyncResult>? _syncs;

  String _title = 'Look at the camera';
  String _note = 'Tap Enrol my face to start.';
  Color _tone = Palette.ink;
  bool _enrolled = false;
  bool _busy = false;
  bool _offline = false;
  bool _canEnroll = true;

  @override
  void initState() {
    super.initState();
    _network = Connectivity().onConnectivityChanged.listen(_setNetwork);
    unawaited(Connectivity().checkConnectivity().then(_setNetwork));
    unawaited(_start());
  }

  @override
  void dispose() {
    _network?.cancel();
    _syncs?.cancel();
    super.dispose();
  }

  void _setNetwork(List<ConnectivityResult> results) {
    if (!mounted) return;
    setState(
      () => _offline = results.every((r) => r == ConnectivityResult.none),
    );
  }

  /// Activates the sandbox key (or, on a check-in device, downloads its list). A face enrolled earlier may still be on
  /// the phone (sandbox faces are deleted 24 hours after enrolment).
  Future<void> _start() async {
    final faceping = _faceping;
    if (faceping == null) {
      _show(
        deviceToken.isEmpty ? 'Sandbox key problem' : 'Device token problem',
        widget.setupProblem ??
            'Run with --dart-define=FACEPING_SANDBOX_KEY=fp_test_yourkey.',
        Palette.red,
      );
      setState(() => _canEnroll = false);
      return;
    }
    if (!faceping.isSandbox) {
      // A check-in device gets its people from the server: no enrolling here. Every sync (including the automatic
      // ones, every 5 minutes) updates the screen.
      setState(() => _canEnroll = false);
      _show('Syncing', "Downloading this list's people…", Palette.ink);
      _syncs = faceping.synced.listen(_synced);
    }
    try {
      final result = await faceping.sync();
      // Shown here too, in case this first sync finished before the listener above heard it.
      if (!faceping.isSandbox) await _synced(result);
    } on FacePingSetupException catch (e) {
      _show(
        faceping.isSandbox ? 'Sandbox key problem' : 'Device token problem',
        e.message,
        Palette.red,
      );
    } on FacePingModelException catch (e) {
      _show('Face check unavailable', e.message, Palette.red);
    } on Exception catch (e) {
      _show('Try again', _message(e), Palette.red);
    }
    await _refreshEnrolled();
  }

  /// On a check-in device: open Verify once the person is here, and say what the sync found.
  Future<void> _synced(SyncResult result) async {
    final faceping = _faceping;
    if (faceping == null || !mounted) return;
    final here = (await faceping.enrolledIds()).contains(personId);
    if (!mounted) return;
    setState(() => _enrolled = here);
    switch (result.status) {
      case SyncStatus.revoked:
        _show(
          'Device token not valid',
          'It was revoked or mistyped, or its list was deleted. Add the device again and use the new token.',
          Palette.red,
        );
      case SyncStatus.gone:
        _show(
          'List finished',
          "This list's faces have been deleted, so there's no one to check.",
          Palette.ink,
        );
      case SyncStatus.unavailable:
        _show(
          "Couldn't sync",
          'No connection to FacePing. The people synced before still work until the lease runs out.',
          Palette.ink,
        );
      case SyncStatus.ok:
        _show(
          '${result.enrolled} people synced',
          here
              ? '$personId is here: tap Verify.'
              : "$personId isn't on this list yet. Enrol them on your server, then reopen the app.",
          Palette.ink,
        );
    }
  }

  Future<void> _enroll() => _run((faceping) async {
    _show('Hold still', 'Taking the photo…', Palette.ink);
    await _camera.setGuideState(FaceGuideState.working);
    final photo = await _camera.capture();
    final result = await faceping.enroll(personId, photo);
    await _camera.setGuideState(FaceGuideState.ready);
    if (result.isEnrolled) {
      setState(() => _enrolled = true);
      _show(
        'Enrolled',
        _offline ? 'No network. Tap Verify.' : 'Now tap Verify.',
        Palette.ink,
      );
    } else {
      _show('Try again', _describe(result.outcome), Palette.red);
    }
  });

  Future<void> _verify() => _run((faceping) async {
    _show('Turn your head', 'Liveness check…', Palette.ink);
    // A live check: matches your face, asks you to turn your head (liveness), then matches again.
    final result = await faceping.verifyLive(personId, _camera);
    final time =
        '${(result.elapsed.inMilliseconds / 1000).toStringAsFixed(2)} s';
    if (result.isMatch) {
      _show(
        'Match',
        'Live face · $time · ${_offline ? 'no network used' : 'on the phone'}',
        Palette.green,
      );
    } else {
      _show(_titleFor(result.outcome), 'Tap Verify to try again.', Palette.red);
    }
  });

  Future<void> _run(Future<void> Function(FacePing faceping) action) async {
    final faceping = _faceping;
    if (_busy || faceping == null) return;
    setState(() => _busy = true);
    try {
      await action(faceping);
    } on FacePingSetupException catch (e) {
      // The sandbox key is missing or revoked, or the very first run had no connection.
      await _resetGuide();
      _show(
        faceping.isSandbox ? 'Sandbox key problem' : 'Device token problem',
        e.message,
        Palette.red,
      );
    } on FacePingModelException catch (e) {
      // The face models couldn't load on this phone: send people to your normal way in.
      await _resetGuide();
      _show('Face check unavailable', e.message, Palette.red);
    } on Exception catch (e) {
      // For example the camera didn't deliver a picture.
      await _resetGuide();
      _show('Try again', _message(e), Palette.red);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refreshEnrolled();
    }
  }

  Future<void> _resetGuide() async {
    if (_camera.isAttached) await _camera.setGuideState(FaceGuideState.ready);
  }

  Future<void> _refreshEnrolled() async {
    final faceping = _faceping;
    if (faceping == null || !mounted) return;
    try {
      final ids = await faceping.enrolledIds();
      if (mounted) setState(() => _enrolled = ids.contains(personId));
    } on Exception {
      // Shown already by the call that failed.
    }
  }

  void _show(String title, String note, Color tone) {
    if (!mounted) return;
    setState(() {
      _title = title;
      _note = note;
      _tone = tone;
    });
  }

  static String _message(Exception e) => switch (e) {
    FacePingException(:final message) => message,
    PlatformException(:final message, :final code) => message ?? code,
    _ => e.toString(),
  };

  static String _titleFor(VerifyOutcome outcome) => switch (outcome) {
    VerifyOutcome.noMatch => 'Not a match',
    VerifyOutcome.notEnrolled => 'Not enrolled',
    VerifyOutcome.noFace => 'No face seen',
    VerifyOutcome.livenessFailed => 'Not a live face',
    VerifyOutcome.challengeFailed => 'Head turn not seen',
    VerifyOutcome.expired => 'Enrolment expired',
    VerifyOutcome.leaseExpired => 'Sync needed',
    VerifyOutcome.match => 'Match',
  };

  static String _describe(EnrollOutcome outcome) => switch (outcome) {
    EnrollOutcome.noFace => 'No face seen. Look at the camera.',
    EnrollOutcome.multipleFaces => 'More than one face. Just you, please.',
    EnrollOutcome.faceTooSmall => 'Move a little closer.',
    EnrollOutcome.notLive => 'That looked like a photo or a screen.',
    EnrollOutcome.limitReached => 'The sandbox is full on this phone.',
    EnrollOutcome.enrolled => 'Enrolled.',
  };

  @override
  Widget build(BuildContext context) {
    final canEnroll = !_busy && _canEnroll;
    final canVerify = !_busy && _enrolled;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                child: Row(
                  children: [
                    const Text(
                      'FaceCheck',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Palette.ink,
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      label: _offline ? 'No network' : 'Network available',
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _offline ? Palette.pillOffline : Palette.pill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _offline ? 'Offline' : 'Online',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _offline ? Palette.amber : Palette.slate,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: ColoredBox(
                    color: Palette.cameraBackground,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FaceCamera(
                          controller: _camera,
                          onCameraFailed: (message) =>
                              _show('Camera unavailable', message, Palette.ink),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Semantics(
                            container: true,
                            liveRegion: true,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.96),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: _tone,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _note,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Palette.slate,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // On a check-in device people enrol on your server, so there's only Verify.
              if (_faceping?.isSandbox ?? true) ...[
                Opacity(
                  opacity: canEnroll ? 1 : 0.45,
                  child: OutlinedButton(
                    onPressed: canEnroll ? _enroll : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: Palette.ink,
                      disabledForegroundColor: Palette.ink,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Palette.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(_enrolled ? 'Enrol again' : 'Enrol my face'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Opacity(
                opacity: canVerify ? 1 : 0.45,
                child: FilledButton(
                  onPressed: canVerify ? _verify : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Palette.brand,
                    disabledBackgroundColor: Palette.brand,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Verify'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

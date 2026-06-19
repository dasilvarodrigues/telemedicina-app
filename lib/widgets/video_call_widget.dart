import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../config/server_config.dart';

class VideoCallWidget extends StatefulWidget {
  final Map<String, dynamic> accessData;
  final VoidCallback? onEnd;

  const VideoCallWidget({super.key, required this.accessData, this.onEnd});

  @override
  State<VideoCallWidget> createState() => _VideoCallWidgetState();
}

class _VideoCallWidgetState extends State<VideoCallWidget> {
  late Room _room;
  bool _connecting = true;
  bool _micEnabled = true;
  bool _camEnabled = true;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  Future<void> _initRoom() async {
    await LiveKitClient.initialize();
    _room = Room();

    _room.events.on<ParticipantConnectedEvent>((event) {
      debugPrint('[VideoCall] Participant connected: ${event.participant.identity} (sid: ${event.participant.sid})');
      if (mounted) setState(() {});
    });
    _room.events.on<ParticipantDisconnectedEvent>((event) {
      debugPrint('[VideoCall] Participant disconnected: ${event.participant.identity}');
      if (mounted) setState(() {});
    });
    _room.events.on<TrackSubscribedEvent>((event) {
      debugPrint('[VideoCall] Track subscribed: kind=${event.track.kind}, participant=${event.participant.identity}');
      if (event.track is VideoTrack) {
        debugPrint('[VideoCall]  => Video track source: ${event.publication.source}');
      }
      if (mounted) setState(() {});
    });
    _room.events.on<TrackUnsubscribedEvent>((event) {
      debugPrint('[VideoCall] Track unsubscribed: kind=${event.track.kind}');
      if (mounted) setState(() {});
    });
    _room.events.on<RoomRecordingStatusChanged>((_) {
      if (mounted) setState(() {});
    });
    _room.events.on<RoomConnectedEvent>((_) {
      debugPrint('[VideoCall] Room connected. Local participant: ${_room.localParticipant?.identity}');
    });
    _room.events.on<RoomDisconnectedEvent>((event) {
      debugPrint('[VideoCall] Room disconnected. Reason: ${event.reason}');
    });

    try {
      final wsUrl = _resolveWsUrl(widget.accessData['ws_url'] as String);
      debugPrint('[VideoCall] Connecting to LiveKit at $wsUrl');
      await _room.connect(
        wsUrl,
        widget.accessData['token'],
      );
      debugPrint('[VideoCall] Connected. Enabling camera...');
      final camResult = await _room.localParticipant?.setCameraEnabled(true);
      debugPrint('[VideoCall] Camera enabled: $camResult');
      debugPrint('[VideoCall] Enabling microphone...');
      final micResult = await _room.localParticipant?.setMicrophoneEnabled(true);
      debugPrint('[VideoCall] Microphone enabled: $micResult');

      final localPubs = _room.localParticipant?.trackPublications;
      if (localPubs != null) {
        debugPrint('[VideoCall] Local participant has ${localPubs.length} track(s):');
        for (final pub in localPubs.values) {
          debugPrint('[VideoCall]  - source=${pub.source}, kind=${pub.kind}, subscribed=${pub.subscribed}, track=${pub.track != null ? pub.track!.kind : "null"}');
        }
      }

      if (mounted) setState(() => _connecting = false);
    } catch (e) {
      debugPrint('[VideoCall] ERROR during init: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao conectar: $e')),
        );
      }
    }
  }

  String _resolveWsUrl(String wsUrl) {
    debugPrint('[VideoCall] Original WS URL: $wsUrl');
    if (!wsUrl.contains('localhost') && !wsUrl.contains('127.0.0.1')) {
      debugPrint('[VideoCall] Not localhost, using as-is: $wsUrl');
      return wsUrl;
    }
    final wsUri = Uri.parse(wsUrl);
    final wsPort = wsUri.port;
    final serverUrl = ServerConfig.baseUrl;
    final uri = Uri.parse(serverUrl);
    final host = uri.host;
    debugPrint('[VideoCall] Resolving to host=$host port=$wsPort from serverUrl=$serverUrl');
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final resolved = '$scheme://$host:$wsPort';
    debugPrint('[VideoCall] Resolved WS URL: $resolved');
    return resolved;
  }

  @override
  void dispose() {
    _room.disconnect();
    super.dispose();
  }

  VideoTrack? _getVideoTrack(Participant participant) {
    final pub = participant.getTrackPublicationBySource(TrackSource.camera);
    if (pub != null) {
      debugPrint('[VideoCall] getVideoTrack(${participant.identity}): pub found, track is VideoTrack? ${pub.track is VideoTrack}');
      if (pub.track is VideoTrack) {
        return pub.track as VideoTrack;
      }
    } else {
      debugPrint('[VideoCall] getVideoTrack(${participant.identity}): no camera publication found');
      for (final pub2 in participant.trackPublications.values) {
        debugPrint('[VideoCall]  - available: source=${pub2.source}, kind=${pub2.kind}, subscribed=${pub2.subscribed}');
      }
    }
    return null;
  }

  Widget _buildDoctorTile(Participant participant) {
    final videoTrack = _getVideoTrack(participant);
    final displayName = participant.name.isNotEmpty ? participant.name : participant.identity;

    Widget videoWidget;
    if (videoTrack != null) {
      videoWidget = ClipRect(
        child: VideoTrackRenderer(videoTrack),
      );
    } else {
      videoWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        videoWidget,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
            child: Text(
              displayName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_connecting) {
      return const Scaffold(
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Conectando à sala...'),
          ],
        )),
      );
    }

    final remoteParticipants = _room.remoteParticipants.values.toList();
    debugPrint('[VideoCall] build: ${remoteParticipants.length} remote participant(s)');
    for (final rp in remoteParticipants) {
      debugPrint('[VideoCall]  - remote: ${rp.identity}, ${rp.trackPublications.length} track(s)');
      final vt = _getVideoTrack(rp);
      debugPrint('[VideoCall]  => video track found: ${vt != null}');
    }

    final doctor = remoteParticipants.isNotEmpty ? remoteParticipants.first : null;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: doctor != null
                      ? _buildDoctorTile(doctor)
                      : const Center(child: Text('Aguardando médico...', style: TextStyle(color: Colors.grey, fontSize: 18))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.grey[900],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlButton(
                        icon: _micEnabled ? Icons.mic : Icons.mic_off,
                        onPressed: () async {
                          await _room.localParticipant?.setMicrophoneEnabled(!_micEnabled);
                          if (mounted) setState(() => _micEnabled = !_micEnabled);
                        },
                      ),
                      const SizedBox(width: 16),
                      _ControlButton(
                        icon: _camEnabled ? Icons.videocam : Icons.videocam_off,
                        onPressed: () async {
                          await _room.localParticipant?.setCameraEnabled(!_camEnabled);
                          if (mounted) setState(() => _camEnabled = !_camEnabled);
                        },
                      ),
                      const SizedBox(width: 16),
                      _ControlButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        onPressed: () {
                          _room.disconnect();
                          final cb = widget.onEnd;
                          if (cb != null) {
                            cb();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: color ?? Colors.grey[700],
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

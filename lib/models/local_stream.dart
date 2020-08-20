import 'package:flutter_webrtc/webrtc.dart';

class LocalStream {
  static Future<MediaStream> build() async {
    final stream = await navigator.getUserMedia({
      'audio': {
        'autoGainControl': true,
        'echoCancellation': true,
        'noiseSuppression': true,
      },
      'video': {
        'mandatory': {
          'minWidth': '1024',
          'minHeight': '1024',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    });

    stream.getAudioTracks().forEach((t) => t.enableSpeakerphone(true));

    return stream;
  }
}

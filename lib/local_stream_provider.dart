import 'package:flutter_webrtc/webrtc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final localStreamProvider = FutureProvider<MediaStream>((ref) {
  return navigator.getUserMedia({
    'audio': true,
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
});

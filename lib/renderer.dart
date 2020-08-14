import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_webrtc/webrtc.dart';

class Renderer extends HookWidget {
  final MediaStream mediaStream;

  const Renderer({Key key, @required this.mediaStream}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rendererState = useState(RTCVideoRenderer());
    final rendererDidInitializeState = useState(false);

    useEffect(() {
      () async {
        await rendererState.value.initialize();
        rendererDidInitializeState.value = true;
      }();

      return null;
    }, []);

    useEffect(() {
      if (!rendererDidInitializeState.value) {
        return;
      }

      rendererState.value.srcObject = mediaStream;

      return null;
    }, [rendererDidInitializeState.value, mediaStream]);

    return AspectRatio(
      aspectRatio: 16.0 / 9.0,
      child: RTCVideoView(rendererState.value),
    );
  }
}

import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_webrtc/webrtc.dart';

class Renderer extends HookWidget {
  final MediaStream mediaStream;

  const Renderer({ Key key, @required this.mediaStream }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rendererState = useState(RTCVideoRenderer());
    final rendererDidInitializeState = useState(false);

    useEffect(() {
      () async {
        await rendererState.value.initialize();
        rendererDidInitializeState.value = true;
      }();
    }, []);

    useEffect(() {
      if (!rendererDidInitializeState.value) {
        return;
      }

      rendererState.value.srcObject = mediaStream;
    }, [rendererDidInitializeState.value, mediaStream]);

    return RTCVideoView(rendererState.value);
  }
}

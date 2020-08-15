import 'package:equatable/equatable.dart';

class WebRtcIceCandidate extends Equatable {
  final String id;
  final String sdp;
  final String sdpMid;
  final int sdpMlineIndex;
  const WebRtcIceCandidate({ this.id, this.sdp, this.sdpMid, this.sdpMlineIndex });
  WebRtcIceCandidate.fromAttributes(Map<String, dynamic> attributes) : this(
    id: attributes['id'],
    sdp: attributes['sdp'],
    sdpMid: attributes['sdp_mid'],
    sdpMlineIndex: attributes['sdp_mline_index']
  );

  @override
  List<Object> get props => [id, sdp, sdpMid, sdpMlineIndex];
}

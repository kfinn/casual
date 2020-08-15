class WebRtcAnswer {
  final String id;
  final String sdp;
  const WebRtcAnswer({ this.id, this.sdp });
  WebRtcAnswer.fromAttributes(Map<String, dynamic> attributes) : this(
    id: attributes['id'],
    sdp: attributes['sdp']
  );
}

class WebRtcOffer {
  final String id;
  final String sdp;
  const WebRtcOffer({ this.id, this.sdp });
  WebRtcOffer.fromAttributes(Map<String, dynamic> attributes) : this(
    id: attributes['id'],
    sdp: attributes['sdp']
  );
}

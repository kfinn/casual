import 'web_rtc_answer.dart';
import 'web_rtc_ice_candidate.dart';
import 'web_rtc_offer.dart';

class MembershipPair {
  final WebRtcOffer webRtcOffer;
  final WebRtcAnswer webRtcAnswer;
  final List <WebRtcIceCandidate> webRtcIceCandidates;

  const MembershipPair({ this.webRtcOffer, this.webRtcAnswer, this.webRtcIceCandidates });

  MembershipPair.fromAttributes(Map<String, dynamic> data) : this(
    webRtcOffer: WebRtcOffer.fromAttributes(data['web_rtc_offer']),
    webRtcAnswer: WebRtcAnswer.fromAttributes(data['web_rtc_answer']),
    webRtcIceCandidates: (data['web_rtc_ice_candidates'] as List<Map<String, dynamic>>).map(
      (webRtcOfferAttributes) => WebRtcIceCandidate.fromAttributes(webRtcOfferAttributes)
    )
  );

  MembershipPair.empty() : this(
    webRtcOffer: null,
    webRtcAnswer: null,
    webRtcIceCandidates: []
  );

  MembershipPair copyWith({
    WebRtcOffer webRtcOffer,
    WebRtcAnswer webRtcAnswer,
    List<WebRtcIceCandidate> webRtcIceCandidates
  }) {
    return MembershipPair(
      webRtcOffer: webRtcOffer ?? this.webRtcOffer,
      webRtcAnswer: webRtcAnswer ?? this.webRtcAnswer,
      webRtcIceCandidates: webRtcIceCandidates ?? this.webRtcIceCandidates
    );
  }
}

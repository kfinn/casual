import 'package:casual/models/web_rtc_answer.dart';
import 'package:casual/models/web_rtc_ice_candidate.dart';
import 'package:casual/models/web_rtc_offer.dart';

class MembershipPair {
  final WebRtcOffer webRtcOffer;
  final WebRtcAnswer webRtcAnswer;
  final List<WebRtcIceCandidate> webRtcIceCandidates;

  const MembershipPair({
    this.webRtcOffer,
    this.webRtcAnswer,
    this.webRtcIceCandidates,
  });

  MembershipPair.fromAttributes(Map<String, dynamic> data)
      : this(
            webRtcOffer: data['web_rtc_offer'] != null
                ? WebRtcOffer.fromAttributes(data['web_rtc_offer'])
                : null,
            webRtcAnswer: data['web_rtc_answer'] != null
                ? WebRtcAnswer.fromAttributes(data['web_rtc_answer'])
                : null,
            webRtcIceCandidates: data['web_rtc_ice_candidates']
                .map<WebRtcIceCandidate>((webRtcOfferAttributes) =>
                    WebRtcIceCandidate.fromAttributes(webRtcOfferAttributes))
                .toList());

  MembershipPair.empty()
      : this(webRtcOffer: null, webRtcAnswer: null, webRtcIceCandidates: []);

  MembershipPair copyWith({
    WebRtcOffer webRtcOffer,
    WebRtcAnswer webRtcAnswer,
    List<WebRtcIceCandidate> webRtcIceCandidates,
  }) {
    return MembershipPair(
      webRtcOffer: webRtcOffer ?? this.webRtcOffer,
      webRtcAnswer: webRtcAnswer ?? this.webRtcAnswer,
      webRtcIceCandidates: webRtcIceCandidates ?? this.webRtcIceCandidates,
    );
  }
}

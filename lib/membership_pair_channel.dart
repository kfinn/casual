import 'package:action_cable/action_cable.dart';

import 'membership_pair.dart';
import 'web_rtc_answer.dart';
import 'web_rtc_ice_candidate.dart';
import 'web_rtc_offer.dart';

class MembershipPairChannel {
  final ActionCable cable;
  final String id;
  final void Function(MembershipPair) onConnected;
  final void Function(WebRtcOffer) onWebRtcOfferCreated;
  final void Function(WebRtcAnswer) onWebRtcAnswerCreated;
  final void Function(WebRtcIceCandidate) onWebRtcIceCandidateCreated;

  const MembershipPairChannel({
    this.cable,
    this.id,
    this.onConnected,
    this.onWebRtcOfferCreated,
    this.onWebRtcAnswerCreated,
    this.onWebRtcIceCandidateCreated
  });

  void unsubscribe() {
    cable.unsubscribe('MembershipPair', channelParams: _channelParams);
  }

  void subscribe() {
    cable.subscribe(
      'MembershipPair',
      channelParams: _channelParams,
      onSubscribed: () => print('subscribed to membership pair $id'),
      onDisconnected: () => print('disconnected from membership pair $id'),
      onMessage: (message) async {
        final payload = message['payload'];
        switch (message['event']) {
          case 'connected':
            onConnected(MembershipPair.fromAttributes(payload));
            break;
          case 'web_rtc_offer_created':
            onWebRtcOfferCreated(WebRtcOffer.fromAttributes(payload));
            break;
          case 'web_rtc_answer_created':
            onWebRtcAnswerCreated(WebRtcAnswer.fromAttributes(payload));
            break;
          case 'web_rtc_ice_candidate_created':
            onWebRtcIceCandidateCreated(WebRtcIceCandidate.fromAttributes(payload));
            break;
        }
      },
    );
  }

  Map<String, dynamic> get _channelParams {
    return { 'id': id };
  }


  void createWebRtcOffer({ String sdp }) {
    _performAction('create_web_rtc_offer', { 'web_rtc_offer': { 'sdp': sdp } });
  }

  void createWebRtcAnswer({ String sdp }) {
    _performAction('create_web_rtc_answer', { 'web_rtc_answer': { 'sdp': sdp } });
  }

  void createWebRtcIceCandidate({ String sdp, String sdpMid, int sdpMlineIndex }) {
    _performAction(
      'create_web_rtc_ice_candidate',
      {
        'web_rtc_ice_candidate': {
          'sdp': sdp,
          'sdp_mid': sdpMid,
          'sdp_mline_index': sdpMlineIndex
        }
      }
    );
  }

  void _performAction(action, params) {
    cable.performAction(
      'MembershipPair',
      channelParams: _channelParams,
      action: action,
      actionParams: params
    );
  }
}

import 'package:action_cable/action_cable.dart';

class RoomChannel {
  final ActionCable cable;
  final String id;
  final void Function({ String membershipPairId, bool older }) onMembershipPairEntryCreated;

  const RoomChannel({ this.cable, this.id, this.onMembershipPairEntryCreated });

  void unsubscribe() {
    cable.unsubscribe('Room', channelParams: _channelParams);
  }

  void subscribe() {
    cable.subscribe(
      'Room',
      channelParams: _channelParams,
      onSubscribed: () => print('subscribed to room $id'),
      onDisconnected: () => print('disconnected from room $id'),
      onMessage: (message) async {
        switch (message['event']) {
          case 'membership_pair_entry_created':
            onMembershipPairEntryCreated(
              membershipPairId: message['payload']['membership_pair_id'],
              older: message['payload']['older']
            );
            break;
        }
      },
    );
  }

  Map<String, dynamic> get _channelParams {
    return { 'id': id };
  }
}

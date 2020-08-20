import 'package:action_cable/action_cable.dart';
import 'package:casual/models/membership_pair_entry.dart';

class RoomChannel {
  final ActionCable cable;
  final String id;
  final void Function(Iterable<MembershipPairEntry>) onConnected;
  final void Function(MembershipPairEntry) onMembershipPairEntryCreated;
  final void Function(MembershipPairEntry) onMembershipPairEntryDestroyed;

  const RoomChannel(
      {this.cable,
      this.id,
      this.onConnected,
      this.onMembershipPairEntryCreated,
      this.onMembershipPairEntryDestroyed});

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
        final payload = message['payload'];
        switch (message['event']) {
          case 'connected':
            final membershipPairEntries = payload['membership_pair_entries']
                .map<MembershipPairEntry>((attributes) {
              return MembershipPairEntry.fromAttributes(attributes);
            });
            onConnected(membershipPairEntries);
            break;
          case 'membership_pair_entry_created':
            onMembershipPairEntryCreated(
                MembershipPairEntry.fromAttributes(payload));
            break;
          case 'membership_pair_entry_destroyed':
            onMembershipPairEntryDestroyed(
                MembershipPairEntry.fromAttributes(payload));
            break;
        }
      },
    );
  }

  Map<String, dynamic> get _channelParams {
    return {'id': id};
  }
}

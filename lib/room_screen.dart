import 'package:casual/local_stream_provider.dart';
import 'package:casual/renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'cable_provider.dart';
import 'membership_pair_entry.dart';
import 'membership_pair_widget.dart';
import 'room_channel.dart';

class RoomScreen extends HookWidget {
  final String id;

  const RoomScreen({ Key key, @required this.id }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cable = useProvider(cableProvider);
    final membershipPairEntriesState = useState<Set<MembershipPairEntry>>(Set.identity());
    final roomChannel = useState(
      RoomChannel(
        cable: cable,
        id: id,
        onConnected: (connectedMembershipPairEntries) {
          membershipPairEntriesState.value = membershipPairEntriesState.value.union(Set.from(connectedMembershipPairEntries));
        },
        onMembershipPairEntryCreated: (membershipPairEntry) {
          membershipPairEntriesState.value = membershipPairEntriesState.value.union(Set.from([membershipPairEntry]));
        }
      )
    );

    print("RoomScreen#build ${membershipPairEntriesState.value}");

    useEffect(() {
      roomChannel.value.subscribe();
      return () => roomChannel.value.unsubscribe();
    }, [roomChannel.value]);

    final localStreamAsyncState = useProvider(localStreamProvider);

    return Column(
        children: [
          Container(
            width: 250,
            height: 250,
            child: localStreamAsyncState.when(
              data: (localStream) => Renderer(mediaStream: localStream),
              loading: () => Text('loading'),
              error: (_error, _stackTrace) => Text('error')
            ),
          ),
          for (final membershipPairEntry in membershipPairEntriesState.value)
            Container(
              height: 250,
              width: 250,
              child: MembershipPairWidget(membershipPairEntry: membershipPairEntry),
            ),
        ],
      );
  }
}

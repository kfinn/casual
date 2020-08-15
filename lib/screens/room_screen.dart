import 'package:casual/components/logout_button.dart';
import 'package:casual/components/renderer.dart';
import 'package:casual/models/local_stream_provider.dart';
import 'package:casual/models/membership_pair_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../components/membership_pair_widget.dart';
import '../models/cable_provider.dart';
import '../models/room_channel.dart';

class RoomScreen extends HookWidget {
  final String id;

  const RoomScreen({Key key, @required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cable = useProvider(cableProvider);
    final membershipPairEntriesState =
        useState<Set<MembershipPairEntry>>(Set.identity());
    final roomChannel = useState(
      RoomChannel(
          cable: cable,
          id: id,
          onConnected: (connectedMembershipPairEntries) {
            membershipPairEntriesState.value = membershipPairEntriesState.value
                .union(Set.from(connectedMembershipPairEntries));
          },
          onMembershipPairEntryCreated: (membershipPairEntry) {
            membershipPairEntriesState.value = membershipPairEntriesState.value
                .union(Set.from([membershipPairEntry]));
          },
          onMembershipPairEntryDestroyed: (membershipPairEntry) {
            membershipPairEntriesState.value = membershipPairEntriesState.value
                .difference(Set.from([membershipPairEntry]));
          }),
    );

    print("RoomScreen#build ${membershipPairEntriesState.value}");

    useEffect(() {
      roomChannel.value.subscribe();
      return () => roomChannel.value.unsubscribe();
    }, [roomChannel.value]);

    final localStreamAsyncState = useProvider(localStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('casual'),
        actions: [
          LogoutButton(),
        ],
      ),
      body: GridView.count(
        scrollDirection: Axis.horizontal,
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: [
          localStreamAsyncState.when(
            data: (localStream) => Renderer(mediaStream: localStream),
            loading: () => Text('loading'),
            error: (_error, _stackTrace) => Text('error'),
          ),
          for (final membershipPairEntry in membershipPairEntriesState.value)
            MembershipPairWidget(
              membershipPairEntry: membershipPairEntry,
            ),
        ],
      ),
    );
  }
}

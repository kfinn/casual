import 'package:casual/components/logout_button.dart';
import 'package:casual/components/renderer.dart';
import 'package:casual/models/is_muted.dart';
import 'package:casual/models/local_stream.dart';
import 'package:casual/models/membership_pair_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_webrtc/webrtc.dart';
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
        },
      ),
    );

    useEffect(() {
      roomChannel.value.subscribe();
      return () => roomChannel.value.unsubscribe();
    }, [roomChannel.value]);

    final localStreamAsyncState = useState(AsyncValue<MediaStream>.loading());
    useEffect(() {
      () async {
        localStreamAsyncState.value = await AsyncValue.guard(LocalStream.build);
      }();

      return null;
    }, []);

    final isMutedState = useProvider(isMutedProvider);
    useEffect(() {
      localStreamAsyncState.value.whenData((value) {
        value.getAudioTracks().forEach((t) {
          t.enabled = !isMutedState.state;
        });
      });

      return null;
    }, [localStreamAsyncState.value, isMutedState.state]);

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
          localStreamAsyncState.value.when(
            data: (localStream) => Renderer(
              mediaStream: localStream,
              mirror: true,
            ),
            loading: () => Text('loading'),
            error: (_error, _stackTrace) => Text('error'),
          ),
          for (final membershipPairEntry in membershipPairEntriesState.value)
            MembershipPairWidget(
              membershipPairEntry: membershipPairEntry,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: isMutedState.state ? Icon(Icons.mic_off) : Icon(Icons.mic),
        onPressed: () => isMutedState.state = !isMutedState.state,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'cable_provider.dart';
import 'membership_pair_entry.dart';
import 'membership_pair_widget.dart';
import 'room_channel.dart';

class RoomScreen extends HookWidget {
  final RTCVideoRenderer localRenderer;
  final String id;

  const RoomScreen({ Key key, @required this.localRenderer, @required this.id }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cable = useProvider(cableProvider);
    final membershipPairEntries = useState<List<MembershipPairEntry>>([]);
    final roomChannel = useState(
      RoomChannel(
        cable: cable,
        id: id,
        onMembershipPairEntryCreated: ({ membershipPairId, older }) {
          membershipPairEntries.value = [
            ...membershipPairEntries.value,
            MembershipPairEntry(membershipPairId: membershipPairId, older: older)
          ];
        }
      )
    );

    useEffect(() {
      roomChannel.value.subscribe();
      return () => roomChannel.value.unsubscribe();
    }, [roomChannel.value]);

    return Column(
        children: [
          Container(
            width: 250,
            height: 250,
            child: RTCVideoView(localRenderer),
          ),
          for (final membershipPairEntry in membershipPairEntries.value)
            Container(
              height: 250,
              width: 250,
              child: MembershipPairWidget(membershipPairEntry: membershipPairEntry),
            ),
        ],
      );
  }
}

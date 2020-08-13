import 'package:equatable/equatable.dart';

class MembershipPairEntry extends Equatable {
  final String membershipPairId;
  final bool older;

  const MembershipPairEntry({ this.membershipPairId, this.older });

  MembershipPairEntry.fromAttributes(Map<String, dynamic> attributes) : this(
    membershipPairId: attributes['membership_pair_id'],
    older: attributes['older'],
  );

  @override
  List<Object> get props => [membershipPairId, older];
}

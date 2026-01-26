import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';
part 'group.g.dart';

@freezed
abstract class Group with _$Group {
  const factory Group({
    required String id,
    required String name,
    required String currencyCode,
    required DateTime createdAt,
    DateTime? archivedAt,
  }) = _Group;

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
}

@freezed
abstract class GroupWithMemberCount with _$GroupWithMemberCount {
  const factory GroupWithMemberCount({
    required Group group,
    required int memberCount,
  }) = _GroupWithMemberCount;

  factory GroupWithMemberCount.fromJson(Map<String, dynamic> json) =>
      _$GroupWithMemberCountFromJson(json);
}

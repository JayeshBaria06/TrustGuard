import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/providers.dart';

/// Provider for the self-member ID in a specific group.
/// Persisted in SharedPreferences.
final groupSelfMemberProvider =
    StateNotifierProvider.family<GroupSelfMemberNotifier, String?, String>((
      ref,
      groupId,
    ) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return GroupSelfMemberNotifier(prefs, groupId);
    });

class GroupSelfMemberNotifier extends StateNotifier<String?> {
  final SharedPreferences _prefs;
  final String _groupId;
  static const _keyPrefix = 'self_member_';

  GroupSelfMemberNotifier(this._prefs, this._groupId)
    : super(_prefs.getString('$_keyPrefix$_groupId'));

  Future<void> setSelfMember(String? memberId) async {
    state = memberId;
    if (memberId == null) {
      await _prefs.remove('$_keyPrefix$_groupId');
    } else {
      await _prefs.setString('$_keyPrefix$_groupId', memberId);
    }
  }
}

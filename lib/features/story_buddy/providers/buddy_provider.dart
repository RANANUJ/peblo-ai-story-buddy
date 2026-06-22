import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BuddyState { idle, loading, speaking, pointing, celebrating, sympathetic }

class BuddyNotifier extends StateNotifier<BuddyState> {
  BuddyNotifier() : super(BuddyState.idle);

  void setIdle() => state = BuddyState.idle;
  void setLoading() => state = BuddyState.loading;
  void setSpeaking() => state = BuddyState.speaking;
  void setPointing() => state = BuddyState.pointing;
  void setCelebrating() => state = BuddyState.celebrating;
  void setSympathetic() => state = BuddyState.sympathetic;
}

final buddyStateProvider = StateNotifierProvider<BuddyNotifier, BuddyState>((ref) {
  return BuddyNotifier();
});

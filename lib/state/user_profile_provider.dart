import 'package:flutter/foundation.dart';

import '../data/models/user_profile.dart';

/// In-memory user profile state. The form populates it; the dashboard and
/// recommendation engine read it. Persistence to disk is intentionally out
/// of scope — the academic deliverable does not require it.
class UserProfileProvider extends ChangeNotifier {
  UserProfile? _profile;

  UserProfile? get profile => _profile;
  bool get hasProfile => _profile != null;

  void save(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void clear() {
    _profile = null;
    notifyListeners();
  }
}

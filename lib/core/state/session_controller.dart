import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_role.dart';

class SessionState {
  const SessionState({
    this.isLoggedIn = false,
    this.role = UserRole.customer,
    this.userName = 'Rehnee',
  });

  final bool isLoggedIn;
  final UserRole role;
  final String userName;

  SessionState copyWith({bool? isLoggedIn, UserRole? role, String? userName}) {
    return SessionState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      role: role ?? this.role,
      userName: userName ?? this.userName,
    );
  }
}

final sessionProvider = StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController();
});

class SessionController extends StateNotifier<SessionState> {
  SessionController() : super(const SessionState());

  void loginAs(UserRole role, {String userName = 'Rehnee'}) {
    state = state.copyWith(isLoggedIn: true, role: role, userName: userName);
  }

  void logout() {
    state = const SessionState(isLoggedIn: false, role: UserRole.customer, userName: 'Rehnee');
  }
}

import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/signup_screen.dart';

final List<RouteBase> authSignupRoutes = [
  GoRoute(
    path: '/signup',
    builder: (context, state) => const SignupScreen(),
  ),
];

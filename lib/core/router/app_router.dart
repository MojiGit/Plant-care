import 'package:go_router/go_router.dart';
import '../../features/plants/presentation/screens/plant_collection_screen.dart';
import '../../features/identification/presentation/screens/identification_screen.dart';
import '../../features/care/presentation/screens/care_screen.dart';
import '../../features/gamification/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const PlantCollectionScreen()),
      GoRoute(path: '/identify', builder: (context, state) => const IdentificationScreen()),
      GoRoute(path: '/care/:plantId', builder: (context, state) => CareScreen(plantId: state.pathParameters['plantId']!)),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ],
  );
}

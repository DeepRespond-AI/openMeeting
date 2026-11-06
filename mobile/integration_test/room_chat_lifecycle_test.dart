import 'package:integration_test/integration_test.dart';

import '../test/features/live_meeting/room_chat_lifecycle_test.dart' as regression;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  regression.main();
}

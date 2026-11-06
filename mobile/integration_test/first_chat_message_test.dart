// Isolated Android app; real Flutter page, SDK MessageList and SQLite, explicit
// catch-up/identity fixtures. No personal account or external IM data is used.
import 'package:integration_test/integration_test.dart';

import '../test/core/im/first_chat_message_test.dart' as regression;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  regression.main();
}

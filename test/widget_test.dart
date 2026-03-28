import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neznakomets/features/home/home_provider.dart';
import 'package:neznakomets/main.dart';

void main() {
  testWidgets('App shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          counterProvider.overrideWith((ref) => Stream<int>.value(2841)),
        ],
        child: const NeznakometsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('незнакомец'), findsOneWidget);
    expect(find.text('2 841'), findsOneWidget);
  });
}

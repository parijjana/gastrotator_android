import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:android_app/services/rate_limit_dispatcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RateLimitDispatcher (Gatekeeper) Tests', () {
    late RateLimitDispatcher dispatcher;

    setUp(() {
      dispatcher = RateLimitDispatcher();
    });

    test('Dispatch should execute task immediately on first call', () async {
      bool executed = false;
      await dispatcher.dispatch(
        type: ApiType.youtube,
        description: "Test",
        task: () async {
          executed = true;
          return true;
        },
      );
      expect(executed, true);
    });

    test('Consecutive calls should be paced by the cooldown timer', () async {
      // Note: We use a small mock cooldown or just observe the timing.
      // Since Dispatcher loads from assets, in tests it might use defaults (2000ms for YT).
      
      final stopwatch = Stopwatch()..start();
      
      // First call (immediate)
      await dispatcher.dispatch(
        type: ApiType.youtube,
        description: "Call 1",
        task: () async => true,
      );
      
      final time1 = stopwatch.elapsedMilliseconds;
      
      // Second call (should wait ~2000ms)
      await dispatcher.dispatch(
        type: ApiType.youtube,
        description: "Call 2",
        task: () async => true,
      );
      
      final time2 = stopwatch.elapsedMilliseconds;
      final gap = time2 - time1;

      // Expect at least 1900ms gap (allowing for slight timer variance)
      expect(gap, greaterThanOrEqualTo(1900));
    });

    test('Concurrent dispatches should be serialized (strictly one after another)', () async {
      List<int> order = [];
      
      // Fire 3 calls "simultaneously"
      final f1 = dispatcher.dispatch(
        type: ApiType.gemini,
        description: "Task 1",
        task: () async {
          order.add(1);
          return 1;
        },
      );

      final f2 = dispatcher.dispatch(
        type: ApiType.gemini,
        description: "Task 2",
        task: () async {
          order.add(2);
          return 2;
        },
      );

      final f3 = dispatcher.dispatch(
        type: ApiType.gemini,
        description: "Task 3",
        task: () async {
          order.add(3);
          return 3;
        },
      );

      await Future.wait([f1, f2, f3]);
      
      // They MUST execute in the order they were dispatched
      expect(order, [1, 2, 3]);
    });
  });
}

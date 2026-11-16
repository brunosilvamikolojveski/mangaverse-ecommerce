import 'package:flutter/widgets.dart';

import 'store_session.dart';

class StoreScope extends InheritedNotifier<StoreSession> {
  const StoreScope({
    super.key,
    required StoreSession session,
    required super.child,
  }) : super(notifier: session);

  static StoreSession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

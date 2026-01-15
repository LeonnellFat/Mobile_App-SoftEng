import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

/// Wrapper widget that handles app lifecycle events (pause/resume)
/// to refresh product and category data when the app comes back to foreground
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({super.key, required this.child});

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  late AdminProvider _adminProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _adminProvider = context.read<AdminProvider>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - refresh data
        debugPrint('📱 App resumed - refreshing data...');
        _adminProvider.refreshProducts();
        _adminProvider.refreshCategories();
        _adminProvider.refreshOrders();
        break;
      case AppLifecycleState.paused:
        debugPrint('📱 App paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('📱 App hidden');
        break;
      case AppLifecycleState.inactive:
        debugPrint('📱 App inactive');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

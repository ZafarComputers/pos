import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/pos_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String pos = '/pos';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      dashboard: (context) => const DashboardPage(),
      pos: (context) => const PosPage(),
    };
  }
}

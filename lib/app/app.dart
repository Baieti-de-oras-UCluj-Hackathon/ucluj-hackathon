import 'package:flutter/material.dart';

import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/color_tokens.dart';

class UmbraRoApp extends StatelessWidget {
  const UmbraRoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UmbraRo',
      theme: AppTheme.themeData,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.root,
      builder: (context, child) {
        return ColoredBox(
          color: ColorTokens.surface,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

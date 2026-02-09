import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';

class VaktApp extends StatelessWidget {
  const VaktApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VAKT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: Center(
          child: Text(
            'VAKT',
            style: AppTextStyles.headline.copyWith(
              color: AppColors.gold,
            ),
          ),
        ),
      ),
    );
  }
}

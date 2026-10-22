import 'package:flutter/cupertino.dart';
import '../constants.dart';

/// السمات البصرية الموحّدة لتطبيق جيرود بنمط Apple Cupertino.
class JeroodTheme {
  JeroodTheme._();

  static const CupertinoThemeData lightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppConstants.cupertinoBlue,
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    barBackgroundColor: CupertinoColors.systemBackground,
  );

  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppConstants.cupertinoBlue,
    scaffoldBackgroundColor: CupertinoColors.black,
    barBackgroundColor: CupertinoColors.black,
  );
}

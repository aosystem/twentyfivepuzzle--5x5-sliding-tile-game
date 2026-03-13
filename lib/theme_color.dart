import 'package:flutter/material.dart';

class ThemeColor {
  final int? themeNumber;
  final BuildContext context;

  ThemeColor({this.themeNumber, required this.context});

  Brightness get _effectiveBrightness {
    switch (themeNumber) {
      case 1:
        return Brightness.light;
      case 2:
        return Brightness.dark;
      default:
        return Theme.of(context).brightness;
    }
  }

  bool get _isLight => _effectiveBrightness == Brightness.light;

  //main page
  Color get mainHeaderFore => _isLight ? Color.fromRGBO(68, 68, 68, 1.0) : Color.fromRGBO(221, 221, 221, 1.0);
  Color get mainBackColor => _isLight ? Color.fromRGBO(255, 255, 255, 1) : Color.fromRGBO(0, 0, 0, 1.0);
  Color get mainBack2Color => _isLight ? Color.fromRGBO(137, 157, 255, 1.0) : Color.fromRGBO(80, 80, 80, 1.0);
  Color get mainStageColor => _isLight ? Color.fromRGBO(0, 29, 124, 1.0) : Color.fromRGBO(0, 29, 124, 1.0);
  //setting page
  Color get backColor => _isLight ? Colors.grey[300]! : Colors.grey[900]!;
  Color get cardColor => _isLight ? Colors.white : Colors.grey[800]!;
  Color get appBarForegroundColor => _isLight ? Colors.grey[700]! : Colors.white70;
  Color get dropdownColor => cardColor;
  Color get borderColor => _isLight ? Colors.grey[300]! : Colors.grey[700]!;
  Color get inputFillColor => _isLight ? Colors.grey[50]! : Colors.grey[900]!;

}

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:twentyfivepuzzle/l10n/app_localizations.dart';
import 'package:twentyfivepuzzle/parse_locale_tag.dart';
import 'package:twentyfivepuzzle/setting_page.dart';
import 'package:twentyfivepuzzle/puzzle_board.dart';
import 'package:twentyfivepuzzle/theme_color.dart';
import 'package:twentyfivepuzzle/ad_banner_widget.dart';
import 'package:twentyfivepuzzle/ad_manager.dart';
import 'package:twentyfivepuzzle/theme_mode_number.dart';
import 'package:twentyfivepuzzle/main.dart';
import 'package:twentyfivepuzzle/model.dart';
import 'package:twentyfivepuzzle/loading_screen.dart';
import 'package:twentyfivepuzzle/audio_play.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  late AdManager _adManager;
  late ThemeColor _themeColor;
  bool _isReady = false;
  bool _isFirst = true;
  //
  final PuzzleBoardController _puzzleController = PuzzleBoardController();
  late AudioPlay _audioPlay;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _adManager = AdManager();
    _audioPlay = AudioPlay();
    _audioPlay.setVolume(Model.soundVolume);
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    _adManager.dispose();
    _audioPlay.dispose();
    super.dispose();
  }

  Future<void> _openSetting() async {
    final bool? updatedSettings = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SettingPage()),
    );
    if (updatedSettings != true || !mounted) {
      return;
    }
    _audioPlay.setVolume(Model.soundVolume);
    final mainState = context.findAncestorStateOfType<MainAppState>();
    if (mainState != null) {
      mainState
        ..locale = parseLocaleTag(Model.languageCode)
        ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
        ..setState(() {});
    }
    setState(() {
      _isFirst = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady == false) {
      return const LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(context: context);
    }
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _themeColor.mainBack2Color,
      body: Stack(children:[
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_themeColor.mainBack2Color, _themeColor.mainBack2Color, _themeColor.mainBackColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            image: DecorationImage(
              image: AssetImage('assets/image/tile.png'),
              repeat: ImageRepeat.repeat,
              opacity: 0.1,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _menuBar(l),
              Expanded(
                child: Column(
                  children: [
                    const Spacer(),
                    Card(
                      margin: const EdgeInsets.all(10),
                      color: _themeColor.mainStageColor,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: PuzzleBoard(controller: _puzzleController, audioPlay: _audioPlay),
                      )
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: _themeColor.mainBackColor),
        child: AdBannerWidget(adManager: _adManager),
      ),
    );
  }

  Widget _menuBar(AppLocalizations l) {
    return Container(
      height: 56.0,
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        children: <Widget>[
          ElevatedButton(
            onPressed: () => _puzzleController.showGame(),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.0),
              ),
              side: BorderSide(width: 0.5, color: _themeColor.mainHeaderFore),
              padding: const EdgeInsets.all(8.0),
            ),
            child: Text(
              l.start,
              style: TextStyle(color: _themeColor.mainHeaderFore),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.settings, color: _themeColor.mainHeaderFore),
            tooltip: l.setting,
            onPressed: _openSetting,
          ),
        ],
      ),
    );
  }
}

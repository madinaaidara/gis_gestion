import 'package:flutter/material.dart';

import 'gis_palette.dart';

/// Accès aux couleurs de surface — suit la palette active (clair par défaut).
class AppSurface {
  AppSurface._();

  static GisPalette _active = GisPalette.light;

  static void sync(GisPalette palette) => _active = palette;

  static Color get bg => _active.bg;
  static Color get scaffold => _active.scaffold;
  static Color get surface => _active.surface;
  static Color get surfaceHi => _active.surfaceHi;
  static Color get surfaceMuted => _active.surfaceMuted;
  static Color get border => _active.border;
  static Color get borderStrong => _active.borderStrong;
  static Color get text => _active.text;
  static Color get textMute => _active.textMute;
  static Color get textDim => _active.textDim;
  static Color get accent => _active.accent;
  static Color get accentSoft => _active.accentSoft;
  static Color get success => _active.success;
  static Color get danger => _active.danger;
  static Color get warning => _active.warning;
  static Color get info => _active.info;
  static Color get gold => _active.gold;
  static Color get sidebarBg => _active.sidebarBg;
  static Color get sidebarHover => _active.sidebarHover;
  static Color get sidebarActive => _active.sidebarActive;
  static Color get sidebarText => _active.sidebarText;
  static Color get sidebarTextSelected => _active.sidebarTextSelected;
  static Color get sidebarBorder => _active.sidebarBorder;
  static Color get topBarBg => _active.topBarBg;
}

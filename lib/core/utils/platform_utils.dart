import 'dart:io';

abstract final class PlatformUtils {
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;
  static bool get isDesktop => isWindows || isMacOS || isLinux;
}

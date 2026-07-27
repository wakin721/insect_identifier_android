import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LauncherIconService {
  const LauncherIconService._();

  static const MethodChannel _channel = MethodChannel(
    'top.myneri.insectidentifier/launcher_icon',
  );

  static const Map<int, String> _manualAliases = <int, String>{
    0xff386a20: 'green',
    0xff006b5f: 'teal',
    0xff00639b: 'blue',
    0xff6750a4: 'purple',
    0xff984061: 'rose',
    0xff9a4520: 'orange',
    0xff006874: 'cyan',
    0xff7a5900: 'gold',
  };

  static Future<void> synchronize({
    required bool useDynamicColor,
    required Color seedColor,
  }) async {
    final alias = useDynamicColor
        ? 'dynamic'
        : _manualAliases[seedColor.toARGB32()] ?? 'rose';

    try {
      await _channel.invokeMethod<void>(
        'setLauncherIcon',
        <String, Object>{'alias': alias},
      );
    } on MissingPluginException {
      // Unit tests and non-Android hosts do not register the platform channel.
    } on PlatformException catch (error) {
      debugPrint('Unable to synchronize launcher icon: $error');
    }
  }
}

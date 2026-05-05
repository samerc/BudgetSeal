import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'text_scale_factor';

/// Available text scale options.
final textScaleOptions = <double, String>{
  0.85: 'Small',
  1.0: 'Default',
  1.15: 'Large',
  1.3: 'Extra Large',
};

final textScaleProvider =
    NotifierProvider<TextScaleNotifier, double>(TextScaleNotifier.new);

class TextScaleNotifier extends Notifier<double> {
  @override
  double build() {
    _load();
    return 1.0;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getDouble(_key);
    if (val != null) state = val;
  }

  Future<void> setScale(double scale) async {
    state = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, scale);
  }
}

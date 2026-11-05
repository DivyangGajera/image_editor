import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Picks the canvas background color: preset swatches or a custom color
/// (hue, saturation, brightness or a hex code). Returns ARGB, or null.
class BackgroundColorSheet extends StatefulWidget {
  const BackgroundColorSheet({super.key, required this.initialColor});

  final int initialColor;

  /// Poster-friendly presets: neutrals, then saturated and soft tones.
  static const List<int> presets = <int>[
    0xFFFFFFFF, 0xFFF5F5F4, 0xFF9CA3AF, 0xFF374151, 0xFF000000,
    0xFFEF4444, 0xFFF97316, 0xFFFACC15, 0xFF22C55E, 0xFF14B8A6,
    0xFF3B82F6, 0xFF4F46E5, 0xFF8B5CF6, 0xFFEC4899, 0xFF7C2D12,
    0xFFFEE2E2, 0xFFFFEDD5, 0xFFFEF9C3, 0xFFDCFCE7, 0xFFDBEAFE,
  ];

  static Future<int?> show(BuildContext context, {required int initialColor}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BackgroundColorSheet(initialColor: initialColor),
    );
  }

  /// `RRGGBB` hex of [color] (alpha ignored).
  static String hexOf(int color) =>
      (color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  /// Parses `RRGGBB` (optional `#`) into opaque ARGB, or null if invalid.
  static int? parseHex(String input) {
    final hex = input.trim().replaceFirst('#', '');
    if (hex.length != 6) return null;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? null : 0xFF000000 | value;
  }

  @override
  State<BackgroundColorSheet> createState() => _BackgroundColorSheetState();
}

class _BackgroundColorSheetState extends State<BackgroundColorSheet> {
  late HSVColor _hsv = HSVColor.fromColor(Color(widget.initialColor));
  late final TextEditingController _hex =
      TextEditingController(text: BackgroundColorSheet.hexOf(widget.initialColor));
  bool _custom = false;

  int get _value => _hsv.toColor().toARGB32();

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      _hex.text = BackgroundColorSheet.hexOf(_value);
    });
  }

  Widget _slider(String key, String label, double value, double max, ValueChanged<double> onChanged,
      List<Color> track) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Container(
          height: 10.0,
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.0),
            gradient: LinearGradient(colors: track),
          ),
        ),
        Slider(key: ValueKey(key), value: value, max: max, onChanged: onChanged),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
            children: [
              Text('Background', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16.0),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: [
                  for (final color in BackgroundColorSheet.presets)
                    Semantics(
                      button: true,
                      label: 'Background color #${BackgroundColorSheet.hexOf(color)}',
                      child: GestureDetector(
                        key: ValueKey('bg_preset_${BackgroundColorSheet.hexOf(color)}'),
                        onTap: () => Navigator.of(context).pop(color),
                        child: Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color == widget.initialColor ? colors.primary : colors.outlineVariant,
                              width: color == widget.initialColor ? 3.0 : 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12.0),
              if (!_custom)
                OutlinedButton.icon(
                  key: const ValueKey('bg_custom_toggle'),
                  onPressed: () => setState(() => _custom = true),
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('Custom color'),
                )
              else ...[
                Container(
                  key: const ValueKey('bg_custom_preview'),
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: _hsv.toColor(),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                ),
                const SizedBox(height: 12.0),
                _slider('bg_hue', 'Hue', _hsv.hue, 360.0, (v) => _setHsv(_hsv.withHue(v)), [
                  for (var h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
                ]),
                _slider('bg_saturation', 'Saturation', _hsv.saturation, 1.0,
                    (v) => _setHsv(_hsv.withSaturation(v)), [
                  _hsv.withSaturation(0).toColor(),
                  _hsv.withSaturation(1).toColor(),
                ]),
                _slider('bg_brightness', 'Brightness', _hsv.value, 1.0, (v) => _setHsv(_hsv.withValue(v)), [
                  _hsv.withValue(0).toColor(),
                  _hsv.withValue(1).toColor(),
                ]),
                TextField(
                  key: const ValueKey('bg_hex'),
                  controller: _hex,
                  maxLength: 7,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]'))],
                  decoration: const InputDecoration(labelText: 'Hex', prefixText: '#'),
                  onChanged: (value) {
                    final parsed = BackgroundColorSheet.parseHex(value);
                    if (parsed != null) setState(() => _hsv = HSVColor.fromColor(Color(parsed)));
                  },
                ),
                FilledButton(
                  key: const ValueKey('bg_custom_apply'),
                  onPressed: () => Navigator.of(context).pop(_value),
                  child: const Text('Use this color'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/features/onboarding/data/onboarding_repository.dart';

/// One page of the welcome.
class WelcomePage {
  const WelcomePage({required this.title, required this.body, required this.art});
  final String title;
  final String body;
  final Widget art;
}

/// First-run welcome: three short pages on what makes Chitred useful, then
/// [onDone]. Skip or Get started both remember that it was seen.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, required this.onDone});

  /// Called after the welcome is finished or skipped (e.g. to open Home).
  final VoidCallback onDone;

  static const List<WelcomePage> pages = [
    WelcomePage(
      title: 'Posts for your shop, in minutes',
      body: 'Make offers, banners, stories and collages with your photos, text and stickers.',
      art: _PostArt(),
    ),
    WelcomePage(
      title: 'Hindi, Gujarati and English fonts',
      body: 'Download beautiful fonts once and use them anytime. Your designs work without internet.',
      art: _FontsArt(),
    ),
    WelcomePage(
      title: 'Remove backgrounds in one tap',
      body: 'Cut out products, people and pets right on your phone. Your photos never leave it.',
      art: _CutoutArt(),
    ),
  ];

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  bool get _isLast => _page == WelcomeScreen.pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await ref.read(onboardingRepositoryProvider).markWelcomeSeen();
    if (mounted) widget.onDone();
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 8.0, 0.0),
              // Fixed height: the header must not jump when Skip disappears.
              child: SizedBox(
                height: 48.0,
                child: Row(
                  children: [
                    Text(AppConstants.appShortName, style: theme.textTheme.titleLarge?.copyWith(color: colors.primary)),
                    const Spacer(),
                    if (!_isLast)
                      TextButton(key: const ValueKey('welcome_skip'), onPressed: _finish, child: const Text('Skip')),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: const ValueKey('welcome_pages'),
                controller: _controller,
                itemCount: WelcomeScreen.pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) {
                  final page = WelcomeScreen.pages[index];
                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Scales down on small screens or with large system text.
                            SizedBox(
                              height: 220.0,
                              child: FittedBox(fit: BoxFit.scaleDown, child: page.art),
                            ),
                            const SizedBox(height: 36.0),
                            Text(page.title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                            const SizedBox(height: 12.0),
                            Text(
                              page.body,
                              style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < WelcomeScreen.pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: i == _page ? 22.0 : 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            color: i == _page ? colors.primary : colors.outlineVariant,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('welcome_next'),
                      onPressed: _next,
                      child: Text(_isLast ? 'Get started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A design card with a headline, a product and an offer badge.
class _PostArt extends StatelessWidget {
  const _PostArt();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: -0.05,
        child: Container(
          width: 168.0,
          height: 210.0,
          decoration: BoxDecoration(
            color: const Color(0xFFFDE68A),
            borderRadius: BorderRadius.circular(18.0),
            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 18.0, offset: Offset(0, 8))],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 18.0,
                child: Text(
                  'BIG SALE',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF9A3412),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                top: 64.0,
                child: Container(
                  width: 70.0,
                  height: 100.0,
                  decoration: BoxDecoration(color: colors.secondary, borderRadius: BorderRadius.circular(12.0)),
                  child: Icon(Icons.shopping_bag_outlined, color: colors.onSecondary, size: 34.0),
                ),
              ),
              Positioned(
                right: 12.0,
                bottom: 18.0,
                child: CircleAvatar(
                  radius: 28.0,
                  backgroundColor: colors.primary,
                  child: Text(
                    '30%\nOFF',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(color: colors.onPrimary, height: 1.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three script samples on stacked chips.
class _FontsArt extends StatelessWidget {
  const _FontsArt();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget chip(String text, Color background, Color foreground, double angle) => Transform.rotate(
      angle: angle,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 10.0, offset: Offset(0, 4))],
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.w700, color: foreground),
        ),
      ),
    );
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip('दिवाली सेल', colors.primary, colors.onPrimary, -0.04),
          chip('દિવાળી સેલ', colors.surfaceContainerLowest, colors.onSurface, 0.03),
          chip('Festive Sale', colors.secondary, colors.onSecondary, -0.02),
        ],
      ),
    );
  }
}

/// A photo with its background fading into a checkerboard cut-out.
class _CutoutArt extends StatelessWidget {
  const _CutoutArt();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110.0,
            height: 150.0,
            decoration: BoxDecoration(color: const Color(0xFF93C5FD), borderRadius: BorderRadius.circular(16.0)),
            child: Icon(Icons.local_drink_outlined, size: 64.0, color: colors.onSurface),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Icon(Icons.arrow_forward_rounded, color: colors.primary),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: SizedBox(
              width: 110.0,
              height: 150.0,
              child: CustomPaint(
                painter: const _CheckerPainter(),
                child: Icon(Icons.local_drink_outlined, size: 64.0, color: colors.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final dark = Paint()..color = const Color(0xFFEFE7DD);
    const cell = 12.0;
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        if (((x / cell).floor() + (y / cell).floor()).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), dark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:localangel/l10n/app_localizations.dart';
import 'package:localangel/auth/ui/auth_landing_screen.dart';

enum PreAuthOnboardingStep { welcome, slides, auth }

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  PreAuthOnboardingStep _step = PreAuthOnboardingStep.welcome;
  int _currentSlide = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startJourney() {
    setState(() => _step = PreAuthOnboardingStep.slides);
  }

  void _nextSlideOrStep() {
    if (_step != PreAuthOnboardingStep.slides) return;
    if (_currentSlide < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      setState(() => _step = PreAuthOnboardingStep.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == PreAuthOnboardingStep.auth) {
      return const AuthLandingScreen();
    }

    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF9F5FF), Color(0xFFF5EEFF)],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _ProgressBar(current: _step.index, total: PreAuthOnboardingStep.values.length),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InCardNav(
                            canBack: _step != PreAuthOnboardingStep.welcome,
                            onBack: () {
                              setState(() {
                                switch (_step) {
                                  case PreAuthOnboardingStep.welcome:
                                    break;
                                  case PreAuthOnboardingStep.slides:
                                    if (_currentSlide == 0) {
                                      _step = PreAuthOnboardingStep.welcome;
                                    } else {
                                      _pageController.previousPage(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                    break;
                                  case PreAuthOnboardingStep.auth:
                                    _step = PreAuthOnboardingStep.slides;
                                    break;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildStepContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case PreAuthOnboardingStep.welcome:
        return _WelcomeStep(onStart: _startJourney);
      case PreAuthOnboardingStep.slides:
        return _SlidesStep(
          controller: _pageController,
          currentIndex: _currentSlide,
          onPageChanged: (i) => setState(() => _currentSlide = i),
          onDotTap: (i) {
            _pageController.animateToPage(i, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
          },
          onNext: _nextSlideOrStep,
        );
      case PreAuthOnboardingStep.auth:
        return const SizedBox.shrink(); // Should not be reached due to check in build
    }
  }
}

class _InCardNav extends StatelessWidget {
  const _InCardNav({required this.canBack, required this.onBack});

  final bool canBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            if (canBack) {
              onBack();
            } else {
              Navigator.maybePop(context);
            }
          },
          icon: const Icon(Icons.arrow_back),
          tooltip: 'חזרה',
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Image.asset('assets/logo.png', height: 72, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context)!.welcome_title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(AppLocalizations.of(context)!.welcome_subtitle),
        const SizedBox(height: 24),
        FilledButton(onPressed: onStart, child: Text(AppLocalizations.of(context)!.welcome_start)),
      ],
    );
  }
}

class _SlidesStep extends StatelessWidget {
  const _SlidesStep({
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onDotTap,
    required this.onNext,
  });

  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onDotTap;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final slides = const [
      ('people', 'הקהילה במרכז', 'מלאך שומר מחברת בין אנשים עם צרכים מיוחדים למתנדבים מהקהילה, ומספקת תמיכה יומיומית.'),
      ('shield', 'אמון ובטיחות', 'כל פעולה מתועדת. כל מסייע מאומת. האמון שלכם הוא מעל הכל.'),
      ('award', 'צברו נקודות על עזרה', 'שומרים צוברים נקודות, תגים והכרה על פעולתם.'),
      ('case', 'התפקיד שלך משנה', 'בחרו להיות שומר/ת או מנהל/ת. לכל תפקיד אחריות שונה.'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final s = slides[index];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconTile(kind: s.$1),
                  const SizedBox(height: 16),
                  Text(s.$2, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      s.$3,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (i) {
            final selected = i == currentIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => onDotTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: selected ? 12 : 8,
                  height: selected ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? const Color(0xFF7C3AED) : Colors.grey.shade400,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onNext, child: Text(currentIndex < slides.length - 1 ? 'הבא' : 'בואו נתחיל')),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.kind});

  final String kind; // people|shield|award|case

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (kind) {
      case 'shield':
        icon = Icons.verified_user_outlined;
        break;
      case 'award':
        icon = Icons.emoji_events_outlined;
        break;
      case 'case':
        icon = Icons.work_outline;
        break;
      case 'people':
      default:
        icon = Icons.people_outline;
    }
    return Container(
      height: 96,
      width: 96,
      decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(24)),
      child: Icon(icon, color: const Color(0xFF7C3AED), size: 48),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = (current + 1) / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LinearProgressIndicator(value: value, minHeight: 6, borderRadius: const BorderRadius.all(Radius.circular(4))),
    );
  }
}

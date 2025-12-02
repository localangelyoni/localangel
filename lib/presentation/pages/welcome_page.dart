import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localangel/presentation/widgets/legal_consent_modal.dart';
import 'package:localangel/l10n/app_localizations.dart';
import 'package:localangel/auth/ui/login_signup_page.dart';

enum OnboardingStep {
  welcome,
  slides,
  login,
  role,
  terms,
  location,
  profilePicture,
  completed,
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  OnboardingStep _step = OnboardingStep.welcome;
  int _currentSlide = 0;
  bool _onboardingCompleted = false;
  String? _selectedRole; // 'guardian' | 'angel' | 'manager'
  bool _termsAccepted = false;
  bool _locationEnabled = false;
  bool _photoSelected = false;
  bool _isSubmitting = false;
  String? _locationError;
  String? _uploadedAvatarUrl;

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _maybeShowLegalConsent();
  }

  Future<void> _maybeShowLegalConsent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userSnap.data() ?? {};
      final legal = (userData['legal'] as Map?) ?? {};
      final accepted = legal['accepted'] == true;
      String currentVersion = 'v1';
      try {
        final settings = await FirebaseFirestore.instance
            .collection('settings')
            .doc('app_settings')
            .get();
        final sData = settings.data() ?? {};
        currentVersion =
            ((sData['legal'] as Map?)?['version'] as String?) ?? 'v1';
      } catch (_) {}
      final versionMatches = (legal['version'] as String?) == currentVersion;
      if (!accepted || !versionMatches) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const LegalConsentModal(),
        );
      }
    } catch (_) {
      // ignore – if load fails we avoid blocking the user
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  void _nextSlideOrStep() {
    if (_step != OnboardingStep.slides) return;
    if (_currentSlide < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      setState(() => _step = OnboardingStep.login);
    }
  }

  void _startJourney() {
    setState(() => _step = OnboardingStep.slides);
  }

  void _continueFromLogin() {
    _maybeShowLegalConsent().then((_) {
      if (mounted) setState(() => _step = OnboardingStep.role);
    });
  }

  void _continueFromRole() {
    if (_selectedRole == null) return;
    setState(() => _step = OnboardingStep.terms);
  }

  void _continueFromTerms() {
    if (!_termsAccepted) return;
    setState(() => _step = OnboardingStep.location);
  }

  void _enableLocation() {
    _requestLocation();
  }

  void _continueFromLocation() {
    setState(() => _step = OnboardingStep.profilePicture);
  }

  void _completeSetup() {
    _saveOnboarding();
  }

  Future<void> _requestLocation() async {
    setState(() {
      _locationError = null;
      _isSubmitting = true;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _locationEnabled = false;
          _locationError = 'הרשאת מיקום נדחתה';
        });
      } else {
        await Geolocator.getCurrentPosition();
        setState(() => _locationEnabled = true);
      }
    } catch (e) {
      setState(() => _locationError = 'שגיאה בקבלת מיקום');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _isSubmitting = true);
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'avatars/${user.uid}.jpg',
      );
      await ref.putData(
        await file.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      setState(() {
        _photoSelected = true;
        _uploadedAvatarUrl = url;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('שגיאה בהעלאת התמונה')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSubmitting = true);
    try {
      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email,
        'avatar_url': _uploadedAvatarUrl,
        'needs_support': _selectedRole == 'angel',
        'is_guardian':
            _selectedRole == 'guardian' || _selectedRole == 'manager',
        'is_angel_manager': _selectedRole == 'manager',
        'requested_role': _selectedRole == 'manager' ? 'manager' : null,
        'manager_status': _selectedRole == 'manager' ? 'pending' : null,
        'onboarding_completed': true,
        'guardian_preferences': {'is_available': true},
        'legal': {
          'accepted': _termsAccepted,
          'acceptedAt': FieldValue.serverTimestamp(),
          'version': 1,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
      // If manager role was requested, send the user to verification waiting page
      if (_selectedRole == 'manager') {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/verification');
        return;
      }
      setState(() {
        _onboardingCompleted = true;
        _step = OnboardingStep.completed;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('שגיאה בשמירת הפרופיל')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _ProgressBar(
                  current: _step.index,
                  total: OnboardingStep.values.length,
                ),
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
                            canBack:
                                _step != OnboardingStep.welcome &&
                                _step != OnboardingStep.completed,
                            onBack: () {
                              setState(() {
                                switch (_step) {
                                  case OnboardingStep.welcome:
                                    break;
                                  case OnboardingStep.slides:
                                    if (_currentSlide == 0) {
                                      _step = OnboardingStep.welcome;
                                    } else {
                                      _pageController.previousPage(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                    break;
                                  case OnboardingStep.login:
                                    _step = OnboardingStep.slides;
                                    break;
                                  case OnboardingStep.role:
                                    _step = OnboardingStep.login;
                                    break;
                                  case OnboardingStep.terms:
                                    _step = OnboardingStep.role;
                                    break;
                                  case OnboardingStep.location:
                                    _step = OnboardingStep.terms;
                                    break;
                                  case OnboardingStep.profilePicture:
                                    _step = OnboardingStep.location;
                                    break;
                                  case OnboardingStep.completed:
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
      case OnboardingStep.welcome:
        return _WelcomeStep(
          onboardingCompleted: _onboardingCompleted,
          onStart: _startJourney,
          onGoHome: _goToDashboard,
        );
      case OnboardingStep.slides:
        return _SlidesStep(
          controller: _pageController,
          currentIndex: _currentSlide,
          onPageChanged: (i) => setState(() => _currentSlide = i),
          onDotTap: (i) {
            _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          },
          onNext: _nextSlideOrStep,
        );
      case OnboardingStep.login:
        return _LoginStep(onContinue: _continueFromLogin);
      case OnboardingStep.role:
        return _RoleStep(
          selectedRole: _selectedRole,
          onSelect: (r) {
            setState(() => _selectedRole = r);
            if (r == 'manager') {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('תפקיד מנהל/ת'),
                  content: const Text(
                    'ב‑MVP, שליחת בקשה תיפתח בהמשך. כרגע מדובר במידע בלבד.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('סגירה'),
                    ),
                  ],
                ),
              );
            }
          },
          onContinue: _continueFromRole,
        );
      case OnboardingStep.terms:
        return _TermsStep(
          accepted: _termsAccepted,
          onToggle: (v) => setState(() => _termsAccepted = v),
          onContinue: _continueFromTerms,
        );
      case OnboardingStep.location:
        return _LocationStep(
          enabled: _locationEnabled,
          errorText: _locationError,
          submitting: _isSubmitting,
          onEnable: _enableLocation,
          onContinue: _continueFromLocation,
        );
      case OnboardingStep.profilePicture:
        return _ProfilePictureStep(
          selected: _photoSelected,
          onSelect: _pickAndUploadPhoto,
          onSkip: _completeSetup,
          onComplete: _completeSetup,
        );
      case OnboardingStep.completed:
        return _CompletedStep(onGoHome: _goToDashboard);
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
  const _WelcomeStep({
    required this.onStart,
    required this.onGoHome,
    required this.onboardingCompleted,
  });

  final VoidCallback onStart;
  final VoidCallback onGoHome;
  final bool onboardingCompleted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Image.asset(
            'assets/logo.png',
            height: 72,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.welcome_title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(AppLocalizations.of(context)!.welcome_subtitle),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onStart,
          child: Text(AppLocalizations.of(context)!.welcome_start),
        ),
        if (onboardingCompleted) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onGoHome,
            child: Text(AppLocalizations.of(context)!.welcome_go_home),
          ),
        ],
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
      (
        'people',
        'הקהילה במרכז',
        'מלאך שומר מחברת בין אנשים עם צרכים מיוחדים למתנדבים מהקהילה, ומספקת תמיכה יומיומית.',
      ),
      (
        'shield',
        'אמון ובטיחות',
        'כל פעולה מתועדת. כל מסייע מאומת. האמון שלכם הוא מעל הכל.',
      ),
      (
        'award',
        'צברו נקודות על עזרה',
        'שומרים צוברים נקודות, תגים והכרה על פעולתם.',
      ),
      (
        'case',
        'התפקיד שלך משנה',
        'בחרו להיות שומר/ת או מנהל/ת. לכל תפקיד אחריות שונה.',
      ),
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
                  Text(
                    s.$2,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
                    color: selected
                        ? const Color(0xFF7C3AED)
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onNext,
          child: Text(currentIndex < slides.length - 1 ? 'הבא' : 'בואו נתחיל'),
        ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, color: const Color(0xFF7C3AED), size: 48),
    );
  }
}

class _LoginStep extends StatelessWidget {
  const _LoginStep({required this.onContinue});

  final VoidCallback onContinue;

  Future<void> _navigateToLogin(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginSignupPage()));

    // After returning from login page, check if user is authenticated
    if (context.mounted && FirebaseAuth.instance.currentUser != null) {
      onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'התחברות',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => _navigateToLogin(context),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: const Text('התחברות / הרשמה'),
        ),
      ],
    );
  }
}

class _RoleStep extends StatelessWidget {
  const _RoleStep({
    required this.selectedRole,
    required this.onSelect,
    required this.onContinue,
  });

  final String? selectedRole;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    Widget roleTile(String value, String title, IconData icon) {
      final selected = selectedRole == value;
      return InkWell(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFF7C3AED) : Colors.grey.shade300,
            ),
            color: selected ? const Color(0xFFF3E8FF) : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? const Color(0xFF7C3AED) : Colors.grey,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'בחירת תפקיד',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        roleTile('guardian', 'אני שומר/ת', Icons.volunteer_activism_outlined),
        const SizedBox(height: 8),
        roleTile('angel', 'אני מלאכ/ית', Icons.auto_awesome),
        const SizedBox(height: 8),
        roleTile('manager', 'אני מנהל/ת', Icons.admin_panel_settings_outlined),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: selectedRole == null ? null : onContinue,
          child: const Text('המשך'),
        ),
      ],
    );
  }
}

class _TermsStep extends StatefulWidget {
  const _TermsStep({
    required this.accepted,
    required this.onToggle,
    required this.onContinue,
  });

  final bool accepted;
  final ValueChanged<bool> onToggle;
  final VoidCallback onContinue;

  @override
  State<_TermsStep> createState() => _TermsStepState();
}

class _TermsStepState extends State<_TermsStep> {
  bool _termsRead = false;
  bool _privacyRead = false;
  final ScrollController _termsScrollController = ScrollController();
  final ScrollController _privacyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _termsScrollController.addListener(_onTermsScroll);
    _privacyScrollController.addListener(_onPrivacyScroll);
  }

  @override
  void dispose() {
    _termsScrollController.removeListener(_onTermsScroll);
    _privacyScrollController.removeListener(_onPrivacyScroll);
    _termsScrollController.dispose();
    _privacyScrollController.dispose();
    super.dispose();
  }

  void _onTermsScroll() {
    if (!_termsScrollController.hasClients) return;
    final max = _termsScrollController.position.maxScrollExtent;
    final atBottom = _termsScrollController.offset >= max - 2;
    if (atBottom && !_termsRead) {
      setState(() => _termsRead = true);
    }
  }

  void _onPrivacyScroll() {
    if (!_privacyScrollController.hasClients) return;
    final max = _privacyScrollController.position.maxScrollExtent;
    final atBottom = _privacyScrollController.offset >= max - 2;
    if (atBottom && !_privacyRead) {
      setState(() => _privacyRead = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAccept = _termsRead && _privacyRead;
    final canContinue = canAccept && widget.accepted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'תנאי השימוש ומדיניות הפרטיות',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'אנא קרא/י את כל התנאים והמדיניות עד הסוף',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        Container(
          height: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Terms section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'תנאי השימוש',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (_termsRead)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          )
                        else
                          Text(
                            'קרא/י עד הסוף',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Scrollbar(
                        controller: _termsScrollController,
                        child: SingleChildScrollView(
                          controller: _termsScrollController,
                          child: const Text(
                            'ברוכים הבאים ל‑מלאך שומר – אפליקציה קהילתית חכמה המחברת בין אנשים עם צרכים מיוחדים למתנדבים מהקהילה.\n\nעל ידי השימוש באפליקציה, אתם מסכימים לתנאי השימוש ומדיניות הפרטיות.\n\nהאפליקציה אינה תחליף לשירותי חירום. במקרי חירום, יש להתקשר לרשויות (100, 101, 102).\n\nאנו מצפים מכל המשתמשים לנהוג בכבוד זה כלפי זה. הטרדה, תוכן פוגעני או שימוש לרעה יובילו להפסקת השימוש.\n\nהשירות מסופק "כפי שהוא". Local Angel אינה אחראית לנזקים עקיפים או לבעיות טכניות שמחוץ לשליטתה.',
                            style: TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              // Privacy section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'מדיניות הפרטיות',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (_privacyRead)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          )
                        else
                          Text(
                            'קרא/י עד הסוף',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Scrollbar(
                        controller: _privacyScrollController,
                        child: SingleChildScrollView(
                          controller: _privacyScrollController,
                          child: const Text(
                            'הפרטיות שלכם חשובה לנו. אנו אוספים מידע אישי (שם, טלפון, אימייל), מידע רפואי בסיסי בהסכמה, נתוני מיקום במהלך בקשות עזרה, ונתונים טכניים.\n\nהמידע משמש להפעלת השירות, שיפור חווית המשתמש, הבטחת בטיחות, ומחקר אנונימי.\n\nנתונים משותפים רק במהלך בקשות עזרה או מקרי חירום. הם לעולם לא נמכרים או משותפים עם מפרסמים.\n\nאנו מיישמים הצפנה מקצה לקצה, אחסון ענן מאובטח ובקרות גישה קפדניות.\n\nמשתמשים יכולים לבחור אם לשתף מיקום באופן רציף או רק במהלך בקשות עזרה.',
                            style: TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/terms_of_use');
              },
              child: const Text('תנאי שימוש מלאים'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/privacy_policy');
              },
              child: const Text('מדיניות פרטיות מלאה'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: widget.accepted,
              onChanged: canAccept ? (v) => widget.onToggle(v ?? false) : null,
            ),
            Expanded(
              child: Text(
                'אני מסכים/ה לתנאי השימוש ומדיניות הפרטיות',
                style: TextStyle(
                  color: canAccept ? Colors.black87 : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
        if (!canAccept)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'אנא קרא/י את כל התנאים והמדיניות עד הסוף',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: canContinue ? widget.onContinue : null,
          child: const Text('המשך'),
        ),
      ],
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.enabled,
    required this.onEnable,
    required this.onContinue,
    this.errorText,
    this.submitting = false,
  });

  final bool enabled;
  final VoidCallback onEnable;
  final VoidCallback onContinue;
  final String? errorText;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'הפעלת שירותי מיקום',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'כדי לחבר אותך עם עזרה בקרבת מקום, אנחנו צריכים גישה למיקום שלך.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'למה אנחנו צריכים מיקום?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                '• חיבור עם שומרים קרובים\n• הערכת זמן הגעה לעזרה\n• התראות חירום מדויקות',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: enabled || submitting ? null : onEnable,
          child: submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('הפעל שירותי מיקום'),
        ),
        const SizedBox(height: 8),
        if (errorText != null) ...[
          Text(errorText!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
        ],
        OutlinedButton(onPressed: onContinue, child: const Text('המשך')),
      ],
    );
  }
}

class _ProfilePictureStep extends StatelessWidget {
  const _ProfilePictureStep({
    required this.selected,
    required this.onSelect,
    required this.onSkip,
    required this.onComplete,
  });

  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onSkip;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'הוספת תמונת פרופיל',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'זה עוזר לקהילה שלך לזהות אותך.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_outline
                    : Icons.camera_alt_outlined,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(selected ? 'תמונה נבחרה' : 'הוספת תמונה (אופציונלי)'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSkip,
                child: const Text('דלג/י לעת עתה'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: selected ? onComplete : onSelect,
                child: Text(selected ? 'השלם הגדרה' : 'בחר/י תמונה'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompletedStep extends StatelessWidget {
  const _CompletedStep({required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 72),
        const SizedBox(height: 16),
        const Text(
          'ברוך הבא לקהילה!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'הגדרת החשבון הושלמה בהצלחה. אתה יכול כעת להתחיל להשתמש באפליקציה.',
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onGoHome, child: const Text('מעבר לדף הבית')),
      ],
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
      child: LinearProgressIndicator(
        value: value,
        minHeight: 6,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
    );
  }
}

// Dashboard is defined in its own file and route

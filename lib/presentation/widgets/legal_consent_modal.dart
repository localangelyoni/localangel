import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LegalConsentModal extends StatefulWidget {
  const LegalConsentModal({super.key});

  @override
  State<LegalConsentModal> createState() => _LegalConsentModalState();
}

// (helper wrapper was removed; dialog used directly)

class _LegalConsentModalState extends State<LegalConsentModal> {
  bool _termsRead = false;
  bool _privacyRead = false;
  bool _agree = false;
  bool _loading = true;
  bool _submitting = false;
  String _termsHtml = 'תנאי השימוש לא נטענו. אנא נסו שוב מאוחר יותר.';
  String _privacyHtml = 'מדיניות הפרטיות לא נטענה. אנא נסו שוב מאוחר יותר.';
  String _version = 'v1';

  final ScrollController _termsScrollController = ScrollController();
  final ScrollController _privacyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _termsScrollController.addListener(_onTermsScroll);
    _privacyScrollController.addListener(_onPrivacyScroll);
    _loadSettings();
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

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('app_settings').get();
      final data = doc.data() ?? {};
      final legal = (data['legal'] as Map?) ?? {};
      setState(() {
        // Use default content if not found in Firestore
        _termsHtml = (legal['termsHtml'] as String?) ?? _getDefaultTermsContent();
        _privacyHtml = (legal['privacyHtml'] as String?) ?? _getDefaultPrivacyContent();
        _version = (legal['version'] as String?) ?? 'v1';
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _termsHtml = _getDefaultTermsContent();
        _privacyHtml = _getDefaultPrivacyContent();
        _version = 'v1';
        _loading = false;
      });
    }
  }

  String _getDefaultTermsContent() {
    return '''ברוכים הבאים ל-Local Angel – אפליקציה חכמה מבוססת קהילה המחברת בין אנשים עם צרכים מיוחדים ("משתמשים מוגנים") לבין מתנדבים מהקהילה ("שומרים"). על ידי שימוש באפליקציה זו, הנכם מסכימים לתנאי שירות אלה.

1. הסכמה לתנאים
על ידי הרשמה ושימוש באפליקציה, הנכם מאשרים שקראתם, הבנתם והסכמתם לתנאים אלה. אם אינכם מסכימים, אנא הימנעו משימוש באפליקציה.

2. השירותים שלנו
האפליקציה מספקת את השירותים הבאים:
• חיבור בזמן אמת בין משתמשים מוגנים ושומרים.
• התראות חירום באמצעות טכנולוגיה לבישה, GPS ו-Bluetooth.
• תמיכה יומיומית, סיוע במשימות ומעורבות קהילתית.
• מערכת נקודות ותגמולים למתנדבים.

3. בטיחות ומגבלות
האפליקציה אינה תחליף לשירותי חירום. במקרי חירום, יש להתקשר לרשויות (100, 101, 102).

4. התנהגות בקהילה
אנו מצפים מכל המשתמשים לנהוג בכבוד זה כלפי זה. הטרדה, תוכן פוגעני או שימוש לרעה יובילו להפסקת השימוש.

5. הגבלת אחריות
השירות מסופק "כפי שהוא". Local Angel אינה אחראית לנזקים עקיפים או לבעיות טכניות שמחוץ לשליטתה.

6. יצירת קשר
לשאלות או הערות, אנא צרו קשר בכתובת: localangel@yoni.com''';
  }

  String _getDefaultPrivacyContent() {
    return '''הפרטיות שלכם חשובה לנו ב-Local Angel. יצרנו את מדיניות הפרטיות הזו כדי להסביר בבירור כיצד אנו אוספים, משתמשים, שומרים ומשתפים מידע, תוך שמירה על בטיחות ואמון.

1. איזה מידע אנו אוספים
אנו אוספים את המידע הבא:
• מידע אישי: שם, טלפון, אימייל
• מידע רפואי בסיסי (בהסכמה): מצבי חירום (למשל, אלרגיות, התקפים)
• נתוני מיקום (GPS): נאספים רק במהלך בקשות עזרה או מקרי חירום, אלא אם הופעל שיתוף רציף
• נתונים טכניים: שימוש באפליקציה, חיבור לאינטרנט
• נתוני שומרים: אימות זהות והעדפות התנדבות

2. כיצד אנו משתמשים בנתונים
המידע שנאסף משמש:
• כדי להפעיל את השירות
• לשפר את חווית המשתמש
• להבטיח בטיחות
• ולספק נתונים סטטיסטיים אנונימיים למחקר

3. שיתוף נתונים
נתוני מיקום ומידע אישי משותפים רק במהלך בקשות עזרה או מקרי חירום. הם לעולם לא נמכרים או משותפים עם מפרסמים.

4. אבטחת מידע
אנו מיישמים הצפנה מקצה לקצה, אחסון ענן מאובטח ובקרות גישה קפדניות.

5. שליטה על שיתוף מיקום
משתמשים יכולים לבחור אם לשתף מיקום באופן רציף או רק במהלך בקשות עזרה. כברירת מחדל, שיתוף המיקום מוגבל למקרי חירום.

6. יצירת קשר
אימייל: localangel@yoni.com''';
  }

  Future<void> _accept() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'legal': {
          'accepted': true,
          'acceptedAt': FieldValue.serverTimestamp(),
          'version': _version,
        }
      }, SetOptions(merge: true));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('אירעה שגיאה, אנא נסו שוב.')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('תנאי שימוש ומדיניות פרטיות', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('אנא עברו על תנאי השימוש ומדיניות הפרטיות. כדי להמשיך, סמנו שקראתם והסכמתם.'),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Terms section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('תנאי השימוש', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                      const Spacer(),
                                      if (_termsRead)
                                        Icon(Icons.check_circle, color: Colors.green, size: 20)
                                      else
                                        Text(
                                          'קרא/י עד הסוף',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Scrollbar(
                                      controller: _termsScrollController,
                                      child: SingleChildScrollView(
                                        controller: _termsScrollController,
                                        child: Text(_termsHtml, style: const TextStyle(fontSize: 14, height: 1.6)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 24),
                            // Privacy section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('מדיניות הפרטיות', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                      const Spacer(),
                                      if (_privacyRead)
                                        Icon(Icons.check_circle, color: Colors.green, size: 20)
                                      else
                                        Text(
                                          'קרא/י עד הסוף',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Scrollbar(
                                      controller: _privacyScrollController,
                                      child: SingleChildScrollView(
                                        controller: _privacyScrollController,
                                        child: Text(_privacyHtml, style: const TextStyle(fontSize: 14, height: 1.6)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                          value: _agree,
                          onChanged: (_termsRead && _privacyRead) ? (v) => setState(() => _agree = v ?? false) : null,
                        ),
                        Expanded(
                          child: Text(
                            'קראתי ואני מסכימ/ה לתנאי השימוש ומדיניות הפרטיות',
                            style: TextStyle(
                              color: (_termsRead && _privacyRead) ? Colors.black87 : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                        ),
                        onPressed: (_termsRead && _privacyRead && _agree && !_submitting) ? _accept : null,
                        child: _submitting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('המשך'),
                      ),
                    ),
                    if (!_termsRead || !_privacyRead)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'אנא קרא/י את כל התנאים והמדיניות עד הסוף כדי להמשיך',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}



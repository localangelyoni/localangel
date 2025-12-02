import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'תנאי שימוש',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'עדכון אחרון: 19/08/2025',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            const Text(
              'ברוכים הבאים ל-Local Angel – אפליקציה חכמה מבוססת קהילה המחברת בין אנשים עם צרכים מיוחדים ("משתמשים מוגנים") לבין מתנדבים מהקהילה ("שומרים"). על ידי שימוש באפליקציה זו, הנכם מסכימים לתנאי שירות אלה.',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. הסכמה לתנאים',
              'על ידי הרשמה ושימוש באפליקציה, הנכם מאשרים שקראתם, הבנתם והסכמתם לתנאים אלה. אם אינכם מסכימים, אנא הימנעו משימוש באפליקציה.',
            ),
            _buildSection(
              '2. השירותים שלנו',
              'האפליקציה מספקת את השירותים הבאים:\n\n'
                  '• חיבור בזמן אמת בין משתמשים מוגנים ושומרים.\n'
                  '• התראות חירום באמצעות טכנולוגיה לבישה, GPS ו-Bluetooth.\n'
                  '• תמיכה יומיומית, סיוע במשימות ומעורבות קהילתית.\n'
                  '• מערכת נקודות ותגמולים למתנדבים.',
            ),
            _buildSection(
              '3. בטיחות ומגבלות',
              'האפליקציה אינה תחליף לשירותי חירום. במקרי חירום, יש להתקשר לרשויות (100, 101, 102).',
            ),
            _buildSection(
              '4. התנהגות בקהילה',
              'אנו מצפים מכל המשתמשים לנהוג בכבוד זה כלפי זה. הטרדה, תוכן פוגעני או שימוש לרעה יובילו להפסקת השימוש.',
            ),
            _buildSection(
              '5. הגבלת אחריות',
              'השירות מסופק "כפי שהוא". Local Angel אינה אחראית לנזקים עקיפים או לבעיות טכניות שמחוץ לשליטתה.',
            ),
            _buildSection(
              '6. יצירת קשר',
              'לשאלות או הערות, אנא צרו קשר בכתובת: localangel@yoni.com',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.6)),
        ],
      ),
    );
  }
}

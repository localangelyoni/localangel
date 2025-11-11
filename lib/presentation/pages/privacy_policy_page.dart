import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'מדיניות פרטיות',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'הפרטיות שלכם חשובה לנו ב-Local Angel. יצרנו את מדיניות הפרטיות הזו כדי להסביר בבירור כיצד אנו אוספים, משתמשים, שומרים ומשתפים מידע, תוך שמירה על בטיחות ואמון.',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. איזה מידע אנו אוספים',
              'אנו אוספים את המידע הבא:\n\n'
              '• מידע אישי: שם, טלפון, אימייל\n'
              '• מידע רפואי בסיסי (בהסכמה): מצבי חירום (למשל, אלרגיות, התקפים)\n'
              '• נתוני מיקום (GPS): נאספים רק במהלך בקשות עזרה או מקרי חירום, אלא אם הופעל שיתוף רציף\n'
              '• נתונים טכניים: שימוש באפליקציה, חיבור לאינטרנט\n'
              '• נתוני שומרים: אימות זהות והעדפות התנדבות',
            ),
            _buildSection(
              '2. כיצד אנו משתמשים בנתונים',
              'המידע שנאסף משמש:\n\n'
              '• כדי להפעיל את השירות\n'
              '• לשפר את חווית המשתמש\n'
              '• להבטיח בטיחות\n'
              '• ולספק נתונים סטטיסטיים אנונימיים למחקר',
            ),
            _buildSection(
              '3. שיתוף נתונים',
              'נתוני מיקום ומידע אישי משותפים רק במהלך בקשות עזרה או מקרי חירום. הם לעולם לא נמכרים או משותפים עם מפרסמים.',
            ),
            _buildSection(
              '4. אבטחת מידע',
              'אנו מיישמים הצפנה מקצה לקצה, אחסון ענן מאובטח ובקרות גישה קפדניות.',
            ),
            _buildSection(
              '5. שליטה על שיתוף מיקום',
              'משתמשים יכולים לבחור אם לשתף מיקום באופן רציף או רק במהלך בקשות עזרה. כברירת מחדל, שיתוף המיקום מוגבל למקרי חירום.',
            ),
            _buildSection(
              '6. יצירת קשר',
              'אימייל: localangel@yoni.com',
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        ],
      ),
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/accessibility/accessibility_cubit.dart';
import '../../auth/providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool _available = true;
  bool _hideCommunityProfile = false;
  String? _avatarUrl;
  String? _selectedRole; // 'angel', 'guardian', 'manager'
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? {};
      _fullName.text = (data['full_name'] as String?) ?? '';
      _email.text =
          (data['email'] as String?) ??
          FirebaseAuth.instance.currentUser?.email ??
          '';
      _phone.text = (data['phone_number'] as String?) ?? '';
      _available =
          ((data['guardian_preferences'] as Map?)?['is_available'] as bool?) ??
          true;
      _hideCommunityProfile =
          ((data['guardian_preferences'] as Map?)?['hide_community_profile']
              as bool?) ??
          false;
      _avatarUrl = data['avatar_url'] as String?;

      // Determine selected role
      if ((data['is_angel_manager'] as bool?) == true) {
        _selectedRole = 'manager';
      } else if ((data['is_guardian'] as bool?) == true) {
        _selectedRole = 'guardian';
      } else if ((data['needs_support'] as bool?) == true) {
        _selectedRole = 'angel';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _uploadPhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _saving = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('avatars/$uid.jpg');
      await ref.putData(
        await file.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'avatar_url': url,
      }, SetOptions(merge: true));
      if (mounted) setState(() => _avatarUrl = url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('העלאת תמונה נכשלה')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final updateData = <String, dynamic>{
        'full_name': _fullName.text.trim(),
        'email': _email.text.trim(),
        'phone_number': _phone.text.trim(),
        'guardian_preferences': {
          'is_available': _available,
          'hide_community_profile': _hideCommunityProfile,
        },
      };

      // Update role if changed
      if (_selectedRole != null) {
        updateData['needs_support'] = _selectedRole == 'angel';
        updateData['is_guardian'] =
            _selectedRole == 'guardian' || _selectedRole == 'manager';
        updateData['is_angel_manager'] = _selectedRole == 'manager';
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(updateData, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('נשמר בהצלחה')));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('שמירה נכשלה')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('התנתקות מהחשבון'),
        content: const Text('האם אתה בטוח שברצונך להתנתק?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('התנתק'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Use the auth repository to sign out
      // Firebase authStateChanges stream will emit automatically
      // and _AuthGate will rebuild to show OnboardingFlow
      final authRepo = ref.read(firebaseAuthRepositoryProvider);
      await authRepo.signOut();

      // Navigate to root - _AuthGate will automatically show onboarding
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'הגדרות',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      'נהל/י את הפרופיל וההעדפות שלך',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Profile Picture Card
                  _ProfilePictureCard(
                    avatarUrl: _avatarUrl,
                    onUpload: _uploadPhoto,
                    uploading: _saving,
                  ),
                  const SizedBox(height: 12),
                  // Profile Details Card
                  _ProfileDetailsCard(
                    fullNameController: _fullName,
                    emailController: _email,
                    phoneController: _phone,
                  ),
                  const SizedBox(height: 12),
                  // Role Preferences Card
                  _RolePreferencesCard(
                    selectedRole: _selectedRole,
                    onRoleSelected: (role) =>
                        setState(() => _selectedRole = role),
                  ),
                  const SizedBox(height: 12),
                  // Guardian Status Card
                  _GuardianStatusCard(
                    isAvailable: _available,
                    onChanged: (value) => setState(() => _available = value),
                  ),
                  const SizedBox(height: 12),
                  // Privacy Settings Card
                  _PrivacySettingsCard(
                    hideCommunityProfile: _hideCommunityProfile,
                    onChanged: (value) =>
                        setState(() => _hideCommunityProfile = value),
                  ),
                  const SizedBox(height: 12),
                  // Accessibility Card
                  const _AccessibilityCard(),
                  const SizedBox(height: 12),
                  // Information and Legal Card
                  const _InformationLegalCard(),
                  const SizedBox(height: 16),
                  // Save and Cancel Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('ביטול'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1F1F23),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('שמור שינויים'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Logout Card
                  _LogoutCard(onLogout: _logout),
                  const SizedBox(height: 80), // Space for bottom nav
                ],
              ),
            ),
    );
  }
}

// Profile Picture Card
class _ProfilePictureCard extends StatelessWidget {
  const _ProfilePictureCard({
    required this.avatarUrl,
    required this.onUpload,
    required this.uploading,
  });

  final String? avatarUrl;
  final VoidCallback onUpload;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'תמונת פרופיל',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'עדכן תמונת פרופיל',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'הוסף או שנה את תמונת הפרופיל שלך',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilledButton.icon(
                        onPressed: uploading ? null : onUpload,
                        icon: const Icon(Icons.upload, size: 18),
                        label: const Text('העלה תמונה'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey.shade600,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Details Card
class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
  });

  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'פרטי פרופיל',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: 'שם מלא',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'אימייל',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'מספר טלפון',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}

// Role Preferences Card
class _RolePreferencesCard extends StatelessWidget {
  const _RolePreferencesCard({
    required this.selectedRole,
    required this.onRoleSelected,
  });

  final String? selectedRole;
  final ValueChanged<String> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'העדפות תפקיד',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              role: 'angel',
              title: 'אני מלאכ/ית',
              description: 'אני עשוי/ה להזדקק לתמיכה מהקהילה',
              icon: Icons.person_outline,
              isSelected: selectedRole == 'angel',
              onTap: () => onRoleSelected('angel'),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              role: 'guardian',
              title: 'אני שומר/ת',
              description: 'אני רוצה לעזור לאחרים בקהילה שלי',
              icon: Icons.shield_outlined,
              isSelected: selectedRole == 'guardian',
              onTap: () => onRoleSelected('guardian'),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              role: 'manager',
              title: 'אני מנהל/ת מלאכים',
              description: 'נהל/י בקשות עבור מלאך אחד או יותר',
              icon: Icons.work_outline,
              isSelected: selectedRole == 'manager',
              onTap: () => onRoleSelected('manager'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String role;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// Guardian Status Card
class _GuardianStatusCard extends StatelessWidget {
  const _GuardianStatusCard({
    required this.isAvailable,
    required this.onChanged,
  });

  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'סטטוס שומר/ת',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAvailable ? 'זמינ/ה לעזור' : 'לא זמינ/ה',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isAvailable
                              ? Colors.green
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'מוכנ/ה לקבל התראות קהילה חדשות.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isAvailable,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Privacy Settings Card
class _PrivacySettingsCard extends StatelessWidget {
  const _PrivacySettingsCard({
    required this.hideCommunityProfile,
    required this.onChanged,
  });

  final bool hideCommunityProfile;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'הגדרות פרטיות',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'הסתר את הפרופיל הקהילתי שלי',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'הפרופיל שלך לא יופיע ברשימות ציבוריות של שומרים קרובים.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: hideCommunityProfile,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF7C3AED),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Accessibility Card
class _AccessibilityCard extends ConsumerStatefulWidget {
  const _AccessibilityCard();

  @override
  ConsumerState<_AccessibilityCard> createState() => _AccessibilityCardState();
}

class _AccessibilityCardState extends ConsumerState<_AccessibilityCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accessibilityCubitProvider);
    final cubit = ref.read(accessibilityCubitProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.accessibility_new,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'נגישות',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.chevron_left,
                      color: Colors.grey.shade400,
                    ),
                    const Text(
                      'אפשרויות נגישות',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'הגדרות תצוגה וקול',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1F23),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _AccessibilityToggle(
                          title: 'מצב ניגודיות גבוהה',
                          value: state.highContrastMode,
                          onChanged: (value) =>
                              cubit.updateHighContrastMode(value),
                        ),
                        const SizedBox(height: 16),
                        _AccessibilityToggle(
                          title: 'טקסט גדול',
                          value: state.largeText,
                          onChanged: (value) => cubit.updateLargeText(value),
                        ),
                        const SizedBox(height: 16),
                        _AccessibilityToggle(
                          title: 'מצב פשוט',
                          value: state.simpleMode,
                          onChanged: (value) => cubit.updateSimpleMode(value),
                        ),
                        const SizedBox(height: 16),
                        _AccessibilityToggle(
                          title: 'הפעל Voice Over',
                          value: state.voiceOverEnabled,
                          onChanged: (value) =>
                              cubit.updateVoiceOverEnabled(value),
                        ),
                        const SizedBox(height: 20),
                        // Reset button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => cubit.resetToDefaults(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'איפוס לברירת המחדל',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessibilityToggle extends StatelessWidget {
  const _AccessibilityToggle({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF7C3AED),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF1F1F23),
            ),
          ),
        ),
      ],
    );
  }
}

// Information and Legal Card
class _InformationLegalCard extends StatelessWidget {
  const _InformationLegalCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'מידע ומשפטי',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('תנאי שימוש'),
              trailing: Icon(Icons.chevron_left, color: Colors.grey.shade400),
              onTap: () {
                Navigator.of(context).pushNamed('/terms_of_use');
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('מדיניות פרטיות'),
              trailing: Icon(Icons.chevron_left, color: Colors.grey.shade400),
              onTap: () {
                Navigator.of(context).pushNamed('/privacy_policy');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Logout Card
class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.logout, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'התנתקות מהחשבון',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'פעולה זו תנתק אותך מהחשבון שלך במכשיר זה ותחזיר אותך למסך הכניסה.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('התנתק'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

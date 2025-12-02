import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:localangel/application/calendar/google_calendar_service.dart';

class CreatePingPage extends StatefulWidget {
  const CreatePingPage({super.key});

  @override
  State<CreatePingPage> createState() => _CreatePingPageState();
}

class _CreatePingPageState extends State<CreatePingPage> {
  int _currentStep = 0;
  String? _selectedUserId; // For managers: which user to create request for
  String _pingType = 'routine';
  String? _category;
  final TextEditingController _title = TextEditingController();
  final TextEditingController _message = TextEditingController();
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  String? _selectedGuardianId;
  bool _broadcastToCommunity = false;
  bool _submitting = false;
  bool _loadingManagedUsers = false;
  bool _loadingGuardians = false;
  List<Map<String, dynamic>> _managedUsers = [];
  List<Map<String, dynamic>> _availableGuardians = [];
  Position? _currentLocation;
  bool _addToGoogleCalendar = false;
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  bool _checkingCalendarAuth = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _getCurrentLocation();
    _checkCalendarAuth();
  }

  Future<void> _checkCalendarAuth() async {
    setState(() => _checkingCalendarAuth = true);
    final isSignedIn = await _calendarService.isSignedIn();
    if (mounted) {
      setState(() {
        _addToGoogleCalendar = isSignedIn;
        _checkingCalendarAuth = false;
      });
    }
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if user is manager
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final isManager = (userData['is_angel_manager'] as bool?) ?? false;
      final managerStatus = userData['manager_status'] as String?;
      final isApprovedManager = isManager && managerStatus == 'approved';

      if (isApprovedManager) {
        _loadManagedUsers(user.uid);
      } else {
        // Regular user - set themselves as selected
        _selectedUserId = user.uid;
      }

      _loadAvailableGuardians();
    } catch (_) {}
  }

  Future<void> _loadManagedUsers(String managerId) async {
    setState(() => _loadingManagedUsers = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('manager_id', isEqualTo: managerId)
          .get();

      _managedUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'full_name': data['full_name'] ?? 'ללא שם',
          'avatar_url': data['avatar_url'],
        };
      }).toList();

      // If manager has managed users, default to first one
      if (_managedUsers.isNotEmpty) {
        _selectedUserId = _managedUsers.first['id'];
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingManagedUsers = false);
  }

  Future<void> _loadAvailableGuardians() async {
    setState(() => _loadingGuardians = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('is_guardian', isEqualTo: true)
          .where('guardian_preferences.is_available', isEqualTo: true)
          .limit(50)
          .get();

      _availableGuardians = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'full_name': data['full_name'] ?? 'ללא שם',
          'avatar_url': data['avatar_url'],
        };
      }).toList();
    } catch (_) {}
    if (mounted) setState(() => _loadingGuardians = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentLocation = position);
    } catch (_) {
      // Location permission denied or unavailable
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _submit() async {
    if (_category == null || _title.text.trim().isEmpty) return;
    if (_selectedUserId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      final pingData = <String, dynamic>{
        'requester_id': _selectedUserId!,
        'created_by_manager_id': user.uid != _selectedUserId ? user.uid : null,
        'title': _title.text.trim(),
        'message': _message.text.trim().isEmpty ? null : _message.text.trim(),
        'ping_type': _pingType,
        'help_category': _category,
        'status': _scheduledDate != null ? 'scheduled' : 'open',
        'guardian_id': _broadcastToCommunity ? null : _selectedGuardianId,
        'broadcast_to_community': _broadcastToCommunity,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add scheduling if provided
      if (_scheduledDate != null && _scheduledTime != null) {
        final scheduledDateTime = DateTime(
          _scheduledDate!.year,
          _scheduledDate!.month,
          _scheduledDate!.day,
          _scheduledTime!.hour,
          _scheduledTime!.minute,
        );
        pingData['scheduledAt'] = Timestamp.fromDate(scheduledDateTime);
      }

      // Add location if available
      if (_currentLocation != null) {
        pingData['location'] = GeoPoint(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        );
      }

      final pingRef = await FirebaseFirestore.instance
          .collection('pings')
          .add(pingData);

      // Add to Google Calendar if requested and scheduled
      if (_addToGoogleCalendar &&
          _scheduledDate != null &&
          _scheduledTime != null) {
        final scheduledDateTime = DateTime(
          _scheduledDate!.year,
          _scheduledDate!.month,
          _scheduledDate!.day,
          _scheduledTime!.hour,
          _scheduledTime!.minute,
        );

        final success = await _calendarService.createEvent(
          title: _title.text.trim(),
          description: _message.text.trim().isEmpty
              ? 'בקשה מסוג $_category'
              : _message.text.trim(),
          startDateTime: scheduledDateTime,
          location: _currentLocation != null
              ? '${_currentLocation!.latitude}, ${_currentLocation!.longitude}'
              : null,
        );

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('הבקשה נוצרה, אך לא נוספה ליומן Google Calendar'),
            ),
          );
        }
      }

      // Create chat placeholder for the ping
      await FirebaseFirestore.instance.collection('chats').add({
        'ping_id': pingRef.id,
        'participants': [_selectedUserId!],
        'messages': [
          {
            'sender_id': user.uid,
            'message': 'בקשה נוצרה',
            'timestamp': FieldValue.serverTimestamp(),
            'message_type': 'system',
          },
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('הבקשה נוצרה בהצלחה')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('שמירה נכשלה')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('יצירת קריאה חדשה'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          // Validate current step before proceeding
          if (_currentStep == 0) {
            if (_category == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('אנא בחר/י קטגוריית עזרה')),
              );
              return;
            }
          } else if (_currentStep == 1) {
            if (_title.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('אנא הזן/י כותרת לבקשה')),
              );
              return;
            }
          }

          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _submit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.of(context).pop();
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                if (details.stepIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('חזור'),
                    ),
                  ),
                if (details.stepIndex > 0) const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : details.onStepContinue,
                    child: _submitting && details.stepIndex == 2
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(details.stepIndex == 2 ? 'שלח קריאה' : 'המשך'),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [_buildStep1(), _buildStep2(), _buildStep3()],
      ),
    );
  }

  Step _buildStep1() {
    return Step(
      title: const Text('סוג וקטגוריה'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Managed user selection (for managers)
          if (_loadingManagedUsers)
            const Center(child: CircularProgressIndicator())
          else if (_managedUsers.isNotEmpty) ...[
            const Text(
              'יצירת בקשה עבור',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'בחר/י את האדם עבורו נוצרת הבקשה.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedUserId,
                  isExpanded: true,
                  items: _managedUsers.map((user) {
                    return DropdownMenuItem<String>(
                      value: user['id'] as String,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: user['avatar_url'] != null
                                ? NetworkImage(user['avatar_url'])
                                : null,
                            child: user['avatar_url'] == null
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(user['full_name'])),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'משתמש מנוהל',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedUserId = value),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Request type
          const Text(
            'סוג הבקשה',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...['emergency', 'urgent', 'routine'].map((type) {
            final isSelected = _pingType == type;
            final typeData = {
              'emergency': {
                'title': 'חירום',
                'description': 'מצבים מיידיים ומסכני חיים.',
                'icon': Icons.warning_amber_rounded,
              },
              'urgent': {
                'title': 'דחוף',
                'description': 'דורש טיפול מהיר, אך לא קריטי.',
                'icon': Icons.notifications_active,
              },
              'routine': {
                'title': 'שגרה',
                'description': 'עזרה מתוזמנת או לא דחופה.',
                'icon': Icons.schedule,
              },
            }[type]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _pingType = type),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : Colors.grey.shade300,
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
                              typeData['title'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              typeData['description'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          typeData['icon'] as IconData,
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          // Help category
          const Text(
            'קטגוריית עזרה',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                [
                  'medical',
                  'mobility',
                  'communication',
                  'daily_tasks',
                  'social',
                  'safety',
                ].map((cat) {
                  final catData = {
                    'medical': {
                      'title': 'רפואי',
                      'icon': Icons.medical_services_outlined,
                    },
                    'mobility': {
                      'title': 'ניידות',
                      'icon': Icons.directions_car_outlined,
                    },
                    'communication': {
                      'title': 'תקשורת',
                      'icon': Icons.people_outline,
                    },
                    'daily_tasks': {
                      'title': 'משימות יומיומיות',
                      'icon': Icons.home_outlined,
                    },
                    'social': {
                      'title': 'חברתי',
                      'icon': Icons.favorite_outline,
                    },
                    'safety': {
                      'title': 'בטיחות',
                      'icon': Icons.shield_outlined,
                    },
                  }[cat]!;

                  final isSelected = _category == cat;
                  return InkWell(
                    onTap: () => setState(() => _category = cat),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 64) / 2,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            catData['icon'] as IconData,
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              catData['title'] as String,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text('פרטים ותזמון'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Request details
          const Text(
            'פרטי הבקשה',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'כותרת / סיכום קצר',
              hintText: 'לדוגמה: "צריך הסעה לרופא"',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _message,
            decoration: const InputDecoration(
              labelText: 'הודעה (אופציונלי)',
              hintText: 'הוסף/י פרטים נוספים כאן, כמו שעת תור, כתובת, וכו\'.',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          // Scheduling
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              const Text(
                'תזמון בקשה (אופציונלי)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'קבע/י תאריך ושעה לביצוע הבקשה',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _scheduledDate != null
                              ? DateFormat(
                                  'dd/MM/yyyy',
                                  'he',
                                ).format(_scheduledDate!)
                              : 'בחר/י תאריך',
                          style: TextStyle(
                            color: _scheduledDate != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _scheduledTime != null
                              ? _scheduledTime!.format(context)
                              : 'בחר/י שעה',
                          style: TextStyle(
                            color: _scheduledTime != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        const Icon(Icons.access_time, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Google Calendar integration option
          if (_scheduledDate != null && _scheduledTime != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'הוסף ליומן Google Calendar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_checkingCalendarAuth)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Switch(
                          value: _addToGoogleCalendar,
                          onChanged: (value) async {
                            if (value) {
                              // Sign in to Google if not already signed in
                              final account = await _calendarService.signIn();
                              if (account != null) {
                                setState(() => _addToGoogleCalendar = true);
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'לא ניתן להתחבר ל-Google Calendar',
                                      ),
                                    ),
                                  );
                                }
                              }
                            } else {
                              setState(() => _addToGoogleCalendar = false);
                            }
                          },
                        ),
                    ],
                  ),
                  if (!_addToGoogleCalendar && !_checkingCalendarAuth) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final account = await _calendarService.signIn();
                        if (account != null) {
                          setState(() => _addToGoogleCalendar = true);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'לא ניתן להתחבר ל-Google Calendar',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('התחבר/י ל-Google Calendar'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text('הקצאת שומר/ת'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              const Text(
                'הקצאת שומר/ת',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'בחר/י שומר/ת ספציפי/ת או שדר/י לכל השומרים הזמינים ברשת.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Broadcast option
          InkWell(
            onTap: () => setState(() {
              _broadcastToCommunity = true;
              _selectedGuardianId = null;
            }),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _broadcastToCommunity
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _broadcastToCommunity
                      ? const Color(0xFF7C3AED)
                      : Colors.grey.shade300,
                  width: _broadcastToCommunity ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'שידור לקהילה',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _broadcastToCommunity
                                ? const Color(0xFF7C3AED)
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ישלח הודעה לכל השומרים הזמינים.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.people,
                    color: _broadcastToCommunity
                        ? const Color(0xFF7C3AED)
                        : Colors.grey.shade700,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Specific guardian selection
          if (!_broadcastToCommunity) ...[
            if (_loadingGuardians)
              const Center(child: CircularProgressIndicator())
            else if (_availableGuardians.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'לא נמצאו שומרים',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'הוסף/י שומרים לרשת שלך מדף הקשרים.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/my_chats');
                      },
                      child: const Text('הוסף שומר/ת'),
                    ),
                  ],
                ),
              )
            else
              ..._availableGuardians.map((guardian) {
                final isSelected = _selectedGuardianId == guardian['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedGuardianId = guardian['id'];
                      _broadcastToCommunity = false;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: guardian['avatar_url'] != null
                                ? NetworkImage(guardian['avatar_url'])
                                : null,
                            child: guardian['avatar_url'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              guardian['full_name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF7C3AED),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
          // Location sharing notice
          if (_currentLocation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'המיקום הנוכחי שלך ישותף עם הקריאה.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

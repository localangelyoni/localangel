import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
// Note: googleapis and googleapis_auth packages need to be properly configured
// For now, we'll use a simplified implementation
import 'package:http/http.dart' as http;

/// Service for integrating with Google Calendar
///
/// This service handles authentication and event creation in Google Calendar.
/// Note: Full implementation requires proper OAuth2 setup with Google Cloud Console.
class GoogleCalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  /// Check if user is signed in to Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Sign in to Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Create a calendar event
  ///
  /// [title] - Event title
  /// [description] - Event description
  /// [startDateTime] - Event start date and time
  /// [endDateTime] - Event end date and time (optional, defaults to 1 hour after start)
  /// [location] - Event location (optional)
  ///
  /// Note: This is a simplified implementation. For full Google Calendar API integration,
  /// you need to properly configure OAuth2 credentials in Google Cloud Console.
  Future<bool> createEvent({
    required String title,
    String? description,
    required DateTime startDateTime,
    DateTime? endDateTime,
    String? location,
  }) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      // Get authentication headers
      final authHeaders = await account.authHeaders;
      if (authHeaders.isEmpty) return false;

      // Format dates for Google Calendar API
      final startDate =
          '${startDateTime.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z';
      final endDate =
          '${(endDateTime ?? startDateTime.add(const Duration(hours: 1))).toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z';

      // Create event JSON
      final eventJson = {
        'summary': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (location != null && location.isNotEmpty) 'location': location,
        'start': {'dateTime': startDate, 'timeZone': 'Asia/Jerusalem'},
        'end': {'dateTime': endDate, 'timeZone': 'Asia/Jerusalem'},
      };

      // Create authenticated HTTP client
      final authenticatedClient = GoogleAuthClient(authHeaders);

      // Insert event using Google Calendar API
      final response = await authenticatedClient.post(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/primary/events',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(eventJson),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// HTTP client that adds Google authentication headers
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    _headers.forEach((key, value) {
      request.headers[key] = value;
    });
    return _client.send(request);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    final request = http.Request('POST', url);
    _headers.forEach((key, value) {
      request.headers[key] = value;
    });
    if (headers != null) {
      headers.forEach((key, value) {
        request.headers[key] = value;
      });
    }
    if (body != null) {
      request.body = body.toString();
    }
    if (encoding != null) {
      request.encoding = encoding;
    }
    return _client
        .send(request)
        .then((response) => http.Response.fromStream(response));
  }
}

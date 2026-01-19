import 'dart:convert'; // ADD THIS IMPORT
import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../shared/widgets/document_upload_tile.dart';
import '../../../core/network/api_client.dart';
import 'token_store.dart';

class LoginOutcome {
  const LoginOutcome._({
    required this.ok,
    required this.nextRoute,
    this.message,
  });

  final bool ok;

  /// Where the app should navigate when [ok] is true.
  final String nextRoute;

  /// Error message from API / logic when [ok] is false.
  final String? message;

  factory LoginOutcome.ok(String nextRoute) => LoginOutcome._(
        ok: true,
        nextRoute: nextRoute,
      );

  factory LoginOutcome.fail(String message) => LoginOutcome._(
        ok: false,
        nextRoute: '',
        message: message,
      );
}

class AuthRepository {
  AuthRepository(this._api, this._tokenStore);
  final ApiClient _api;
  final TokenStore _tokenStore;

  /// Login outcome used by UI to decide where to navigate.
  ///
  /// Rules:
  /// 1) If token is missing -> [ok]=false and return API message.
  /// 2) role=customer and verified -> /c/home
  /// 3) role=vendor and verified and approval_status=approved -> /v/home
  /// 4) role=vendor OR customer and NOT verified -> /otp/{userId}
  /// 5) role=vendor and verified and approval_status=pending -> /v/pending
  ///
  /// Notes:
  /// - We read role/verification/approval from `auth` first (if present),
  ///   otherwise fall back to `user` / `vendor`.
  /// - We still save session (token + role + vendor status/id) when token exists.
  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.dio.post(
      '/api/v1/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (s) => true, // handle errors ourselves
      ),
    );

    // Parse response safely.
    final Map<String, dynamic> data;
    if (res.data is Map) {
      data = (res.data as Map).cast<String, dynamic>();
    } else if (res.data is String) {
      final s = (res.data as String).trim();
      data = s.isEmpty ? <String, dynamic>{} : (jsonDecode(s) as Map).cast<String, dynamic>();
    } else {
      data = <String, dynamic>{};
    }

    final token = (data['token'] ?? '').toString().trim();
    if (token.isEmpty) {
      // 1) Token missing -> stop and show API message.
      final msg = (data['message'] ?? 'Login failed').toString();
      return LoginOutcome.fail(msg);
    }

    final user = data['user'] is Map ? (data['user'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    final auth = data['auth'] is Map ? (data['auth'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    final vendor = data['vendor'] is Map ? (data['vendor'] as Map).cast<String, dynamic>() : <String, dynamic>{};

    final userId = (user['id'] ?? auth['user_id'] ?? '').toString();

    final role = (auth['role'] ?? user['role'] ?? user['user_type'] ?? user['type'] ?? '').toString().trim();

    final verified = _toBool(auth['is_verified'] ?? user['is_verified']);

    final approval = (auth['vendor_approval_status'] ?? vendor['approval_status'] ?? '').toString().trim();
    final vendorId = (vendor['id'] ?? auth['vendor_id'])?.toString();

    // Save session when token exists.
    await _tokenStore.saveSession(
      token: token,
      userType: role.isEmpty ? 'customer' : role,
      vendorApprovalStatus: approval.isEmpty ? null : approval,
      vendorId: vendorId,
    );

    // Decide next route based on your rules.
    final next = _resolveNextRoute(
      role: role,
      verified: verified,
      userId: userId,
      vendorApprovalStatus: approval,
    );

    return LoginOutcome.ok(next);
  }

  // ---------- helpers ----------

  bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = (v ?? '').toString().trim().toLowerCase();
    if (s == '1' || s == 'true' || s == 'yes') return true;
    if (s == '0' || s == 'false' || s == 'no' || s.isEmpty) return false;
    return false;
  }

  String _resolveNextRoute({
    required String role,
    required bool verified,
    required String userId,
    required String? vendorApprovalStatus,
  }) {
    final r = role.trim().toLowerCase();
    final approval = (vendorApprovalStatus ?? '').trim().toLowerCase();

    // 4) vendor OR customer and not verified -> otp
    if ((r == 'vendor' || r == 'customer') && !verified) {
      final id = userId.trim();
      return id.isEmpty ? '/otp' : '/otp/$id';
    }

    // 2) customer and verified -> /c/home
    if ((r == 'customer'||r=='admin') && verified) {
      return '/c/home';
    }

    // vendor verified -> depends on approval
    if (r == 'vendor' && verified) {
      // 3) approved -> /v/home
      if (approval == 'approved') return '/v/home';

      // 5) pending -> /v/pending
      if (approval == 'pending') return '/v/pending';

      // fallback: keep vendors out of home if status unknown
      return '/v/pending';
    }

    // fallback (admin/unknown)
    return '/';
  }



  MultipartFile _toMultipart(DocumentAttachment doc) {
  // ✅ Web: use bytes
  if (doc.bytes != null && doc.bytes!.isNotEmpty) {
    return MultipartFile.fromBytes(
      doc.bytes!,
      filename: doc.fileName ?? 'upload.bin',
    );
  }

  // ✅ Mobile/Desktop: use file path
  final p = doc.path;
  if (p == null || p.isEmpty) {
    throw Exception('File path is missing (non-web).');
  }

  return MultipartFile.fromFileSync(
    p,
    filename: doc.fileName,
  );
}


  Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? countryISO,
    double? latitude,
    double? longitude,
  }) async {
     
    try {
      // Prepare the request data
      final requestData = {
        'name': name,
        'email': email,
        'password': password,
        'role': 'customer',
        if (phone != null && phone.isNotEmpty) 'contact_number': phone,
        if (addressLine1 != null && addressLine1.isNotEmpty)
          'address_line1': addressLine1,
        if (addressLine2 != null && addressLine2.isNotEmpty)
          'address_line2': addressLine2,
        if (countryISO != null && countryISO.isNotEmpty) 'country_ISO': countryISO,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      }; 

      final res = await _api.dio.post(
        '/api/v1/auth/register',
        data: requestData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          // Important: Don't throw on any status
          validateStatus: (status) => true,
          responseType: ResponseType.plain, // Try plain first to see raw response
        ),
      ); 
      
      // Handle 201 Created
      if (res.statusCode == 201) {
        print('✅ Server returned 201 (Created)');
        
        Map<String, dynamic> responseData;
        
        // Try to parse the response
        try {
          if (res.data is String) {
            final stringData = res.data as String;
            print('  Response is String, trying to parse as JSON...');
            
            if (stringData.trim().isEmpty) {
              print('  Response is empty string');
              responseData = {'message': 'Registration successful'};
            } else if (stringData.trim().startsWith('{') && stringData.trim().endsWith('}')) {
              // It's JSON
              responseData = jsonDecode(stringData) as Map<String, dynamic>;
              print('  Successfully parsed JSON: $responseData');
            } else {
              // Not JSON
              print('  Response is not JSON: $stringData');
              responseData = {'raw_response': stringData};
            }
          } else if (res.data is Map) {
            // Already a Map
            responseData = Map<String, dynamic>.from(res.data as Map);
            print('  Response is already Map: $responseData');
          } else {
            // Unknown type
            print('  Unknown response type: ${res.data.runtimeType}');
            responseData = {'data': res.data.toString()};
          }
        } catch (parseError) {
          print('  ❌ Failed to parse response: $parseError');
          responseData = {
            'message': 'Registration successful',
            'raw_data': res.data.toString(),
            'parse_error': parseError.toString(),
          };
        }
        
        // Try to extract token from various locations
        String? token;
        
        // Check common token locations
        token = responseData['token'] as String?;
          
        print('  Token found: ${token != null ? "YES" : "NO"}');
        if (token != null) {
          print('  Token: ${token.length > 30 ? "${token.substring(0, 30)}..." : token}');
          await _tokenStore.saveSession(token: token, userType: 'customer');
          print('  ✅ Session saved with token');
        } else {
          print('  ⚠️ No token in response. Checking response structure:');
          print('  Response keys: ${responseData.keys}');
          
          // Maybe token is in a different format or not needed
          // Some APIs don't return token on registration, require email verification first
          print('  ℹ️ No token returned. User may need to verify email first.');
        }
        
        return responseData;
      }
      // Handle other success statuses
      else if (res.statusCode! >= 200 && res.statusCode! < 300) {
        print('✅ Server returned ${res.statusCode} (Success)');
        
        // Similar parsing as above...
        Map<String, dynamic> responseData;
        try {
          responseData = _parseResponse(res.data);
        } catch (e) {
          responseData = {'status': 'success', 'code': res.statusCode};
        }
        
        // Try to get token
        final token = _extractToken(responseData, res.headers);
        if (token != null) {
          await _tokenStore.saveSession(token: token, userType: 'customer');
        }
        
        return responseData;
      }
      // Handle error statuses
      else {
        print('❌ Server returned error ${res.statusCode}');
        
        // Try to parse error response
        Map<String, dynamic> errorData;
        try {
          errorData = _parseResponse(res.data);
        } catch (e) {
          errorData = {
            'message': 'Request failed with status ${res.statusCode}',
            'raw_response': res.data.toString(),
          };
        }
        
        // Throw DioException with the parsed error
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
          error: errorData['message'] ?? 'Registration failed',
        );
      }
    } 
    catch (e, stackTrace) {
          
      rethrow;
    }
  }

  // Helper method to parse response
  Map<String, dynamic> _parseResponse(dynamic data) {
    try {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      } else if (data is String) {
        final trimmed = data.trim();
        if (trimmed.isEmpty) {
          return {'message': 'Empty response'};
        } else if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          return jsonDecode(trimmed) as Map<String, dynamic>;
        } else if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          return {'data': jsonDecode(trimmed)};
        } else {
          return {'raw_response': trimmed};
        }
      } else {
        return {'data': data.toString()};
      }
    } catch (e) {
      return {
        'parse_error': e.toString(),
        'raw_data': data.toString(),
      };
    }
  }

  // Helper method to extract token
  String? _extractToken(Map<String, dynamic> data, Headers headers) {
    // Check data map
    String? token;
    token = data['token'] as String?;
    token ??= data['access_token'] as String?;
    token ??= data['data']?['token'] as String?;
    token ??= data['auth_token'] as String?;
    token ??= data['accessToken'] as String?;
    token ??= data['authToken'] as String?;
    token ??= data['user']?['token'] as String?;
    token ??= data['auth']?['token'] as String?;
    
    // Check headers
    token ??= headers.value('authorization')?.replaceFirst('Bearer ', '');
    token ??= headers.value('Authorization')?.replaceFirst('Bearer ', '');
    token ??= headers.value('X-Auth-Token') as String?;
    token ??= headers.value('x-auth-token') as String?;
    
    return token;
  }

  /// Returns vendor id if present (used for /v/pending/:id routing).
  Future<Map<String, dynamic>> registerVendorMultipart({
  required String name,
  required String email,
  required String password,
  required String businessName,
  required double latitude,
  required double longitude,
  required DocumentAttachment businessRegistration,
  required DocumentAttachment governmentId,
  List<DocumentAttachment> supportingDocs = const [],
  String? phone,
  String? addressLine1,
  String? addressLine2,
  String? countryISO,
}) async {
  // ✅ Web must have bytes
  if (kIsWeb) {
    if (businessRegistration.bytes == null || businessRegistration.bytes!.isEmpty) {
      throw Exception('Business registration bytes missing (web).');
    }
    if (governmentId.bytes == null || governmentId.bytes!.isEmpty) {
      throw Exception('Government ID bytes missing (web).');
    }
  }

  final form = FormData.fromMap({
    'name': name,
    'email': email,
    'password': password,
    'role': 'vendor', // change to 'user_type' if your API expects that instead
    'business_name': businessName,
    'latitude': latitude,
    'longitude': longitude,

    if (phone != null && phone.isNotEmpty) 'contact_number': phone,
    if (addressLine1 != null && addressLine1.isNotEmpty) 'address_line1': addressLine1,
    if (addressLine2 != null && addressLine2.isNotEmpty) 'address_line2': addressLine2,
    if (countryISO != null && countryISO.isNotEmpty) 'country_ISO': countryISO,

    // ✅ file fields
    'business_registration': _toMultipart(businessRegistration),
    'government_id': _toMultipart(governmentId),

    // ✅ optional multiple supporting docs
    if (supportingDocs.isNotEmpty)
      'supporting_documents[]': [
        for (final d in supportingDocs) _toMultipart(d),
      ],
  });

  final res = await _api.dio.post(
    '/api/v1/auth/register',
    data: form,
    options: Options(
      headers: {
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
           validateStatus: (status) => true,
    ),
  );

    // Handle 201 Created
    if (res.statusCode == 200|| res.statusCode == 201) {
      print('✅ Server returned 201 (Created)');
      
      Map<String, dynamic> responseData;
      
      // Try to parse the response
      try {
        if (res.data is String) {
          final stringData = res.data as String;
          print('  Response is String, trying to parse as JSON...');
          
          if (stringData.trim().isEmpty) {
            print('  Response is empty string');
            responseData = {'message': 'Registration successful'};
          } else if (stringData.trim().startsWith('{') && stringData.trim().endsWith('}')) {
            // It's JSON
            responseData = jsonDecode(stringData) as Map<String, dynamic>;
            print('  Successfully parsed JSON: $responseData');
          } else {
            // Not JSON
            print('  Response is not JSON: $stringData');
            responseData = {'raw_response': stringData};
          }
        } else if (res.data is Map) {
          // Already a Map
          responseData = Map<String, dynamic>.from(res.data as Map);
          print('  Response is already Map: $responseData');
        } else {
          // Unknown type
          print('  Unknown response type: ${res.data.runtimeType}');
          responseData = {'data': res.data.toString()};
        }
      } catch (parseError) {
        print('  ❌ Failed to parse response: $parseError');
        responseData = {
          'message': 'Registration successful',
          'raw_data': res.data.toString(),
          'parse_error': parseError.toString(),
        };
      }
      
      // Try to extract token from various locations
      String? token;  

      final dynamic rawVendorId = responseData['user']?['vendor_id'];
      final String? vendorId = rawVendorId?.toString();

      // Check common token locations
      token = responseData['token'] as String?;   
      if (token != null) {
        print('  Token: ${token.length > 30 ? "${token.substring(0, 30)}..." : token}');
        await _tokenStore.saveSession(token: token, userType: 'vendor', vendorApprovalStatus: 'pending',vendorId: vendorId); 
        print('  ✅ Session saved with token');
      } else {
        print('  ⚠️ No token in response. Checking response structure:');
        print('  Response keys: ${responseData.keys}');
        
        // Maybe token is in a different format or not needed
        // Some APIs don't return token on registration, require email verification first
        print('  ℹ️ No token returned. User may need to verify email first.');
      }
      
      return responseData;
    }
    // Handle other success statuses
    else if (res.statusCode! >= 200 && res.statusCode! < 300) {
      print('✅ Server returned ${res.statusCode} (Success)');
      
      // Similar parsing as above...
      Map<String, dynamic> responseData;
      try {
        responseData = _parseResponse(res.data);
      } catch (e) {
        responseData = {'status': 'success', 'code': res.statusCode};
      }
      
      // Try to get token
      final token = _extractToken(responseData, res.headers);
      if (token != null) {
        await _tokenStore.saveSession(token: token, userType: 'vendor');
      }
      
      return responseData;
    }
    // Handle error statuses
    else {
      print('❌ Server returned error ${res.statusCode}');
      
      // Try to parse error response
      Map<String, dynamic> errorData;
      try {
        errorData = _parseResponse(res.data);
      } catch (e) {
        errorData = {
          'message': 'Request failed with status ${res.statusCode}',
          'raw_response': res.data.toString(),
        };
      }
      
      // Throw DioException with the parsed error
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        error: errorData['message'] ?? 'Registration failed',
      );
    }
}


  /// Poll current user's vendor approval status using /auth/me.
  Future<String?> refreshMe() async {
    final res = await _api.dio.get('/api/v1/auth/me');
    final data = (res.data as Map).cast<String, dynamic>();
    
    final vendor = data['vendor'];
    final approval = (res.data['data']?['vendor']?['approval_status'])?.toString();
    final userType = (res.data['data']?['user']?['user_type'])?.toString() ?? '';

    final vendorId = vendor is Map ? (vendor['id']?.toString()) : null;

    // Keep existing token, only refresh metadata.
    final token = await _tokenStore.readToken() ?? '';
    if (token.isNotEmpty && userType.isNotEmpty) {
      await _tokenStore.saveSession(
        token: token,
        userType: userType,
        vendorApprovalStatus: approval,
        vendorId: vendorId,
      );
      
    }
    return approval;
  }

  /// ✅ LOGOUT
  Future<void> logout() async {
    try {
      // Optional: call backend logout if available
      await _api.dio.post('/api/v1/auth/logout');
    } catch (_) {
      // ignore API logout errors
    }

    // Always clear local session
    await _tokenStore.clear();
  }

  Future<void> requestOtp({required String email}) async {
    await _api.dio.post('/api/v1/auth/send-email-otp', data: {'email': email});
  }

  Future<void> verifyOtp({required String email, required String code, required String role}) async {
    //await _api.dio.post('/api/v1/auth/verify-email-otp', data: {'email': email, 'code': code});

    final requestData = {
        'otp': code,
        'email': email,
        'role': role,
      
      };
       
      final res = await _api.dio.post(
        '/api/v1/auth/verify-email-otp',
        data: requestData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          // Important: Don't throw on any status
          validateStatus: (status) => true,
          responseType: ResponseType.json, // Try plain first to see raw response
        ),
      );
 
      final Map<String, dynamic> body = _asJsonMap(res.data);

      // ✅ If success: read data.user_type (example)  

      if (res.statusCode != null && res.statusCode! >= 400) {
        print('❌ Server returned error ${res.statusCode}');

        // Parse error as JSON (best effort)
        final Map<String, dynamic> errorData = _asJsonMap(res.data);

        // Try common Laravel error shapes:
        final String message =
            (errorData['message'] is String && (errorData['message'] as String).isNotEmpty)
                ? errorData['message'] as String
                : 'Request failed with status ${res.statusCode}';

        // (Optional) If API also includes data.user_type even on error:
        final dynamic errorUserType = errorData['data']?['user_type'];

        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
          error: {
            'message': message,
            'status': res.statusCode,
            'errors': errorData['errors'], // Laravel validation errors usually here
            'user_type': errorUserType,
            'raw_response': res.data,
          },
        );
      }
      
  }


  // Helper: always return a Map<String, dynamic> JSON object
  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data == null) return <String, dynamic>{};

    if (data is Map<String, dynamic>) return data;

    // Dio may give Map<dynamic, dynamic>
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }

    // If it's a string, try decode JSON
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    }

    // Anything else -> fallback
    return <String, dynamic>{};
  }
}
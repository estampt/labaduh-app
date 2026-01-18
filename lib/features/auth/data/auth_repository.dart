import 'dart:convert'; // ADD THIS IMPORT
import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../shared/widgets/document_upload_tile.dart';
import '../../../core/network/api_client.dart';
import 'token_store.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokenStore);
  final ApiClient _api;
  final TokenStore _tokenStore;

  /// ✅ LOGIN (Laravel)
  /// Expected response: { token, user: { user_type }, vendor?: { id, approval_status } }
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.dio.post(
      '/api/v1/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = (res.data as Map).cast<String, dynamic>();
    final token = (data['token'] ?? '').toString();

    final user = data['user'] is Map ? (data['user'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    final userType = (user['user_type'] ?? user['type'] ?? '').toString();

    final vendor = data['vendor'];
    final vendorId = vendor is Map ? (vendor['id']?.toString()) : null;
    final approval = vendor is Map ? (vendor['approval_status']?.toString()) : null;

    if (token.isNotEmpty) {
      await _tokenStore.saveSession(
        token: token,
        userType: userType.isEmpty ? 'customer' : userType,
        vendorApprovalStatus: approval,
        vendorId: vendorId,
      );
    }
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
      print('🔥 CRITICAL ERROR in registerCustomer:');
      print('  Type: ${e.runtimeType}');
      print('  Error: $e');
      print('  Stack trace: $stackTrace');
      
      // Check if it's a DioException with more details
      if (e is DioException) {
        print('  DioError details:');
        print('    Type: ${e.type}');
        print('    Message: ${e.message}');
        print('    Error: ${e.error}');
        print('    Response status: ${e.response?.statusCode}');
        print('    Response data: ${e.response?.data}');
        print('    Response headers: ${e.response?.headers}');
      }
      
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
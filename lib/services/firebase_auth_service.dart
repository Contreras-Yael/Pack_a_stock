import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class FirebaseAuthService {
  final StorageService _storage = StorageService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Inicia sesión con Google y luego intercambia el token con el backend Django.
  /// Retorna {success, user?, message?, needs_company_code?, firebase_token?, full_name?, email?}
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // 1. Popup de Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Inicio de sesión cancelado'};
      }

      // 2. Obtener credenciales de Firebase
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Autenticar en Firebase
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseToken = await userCredential.user!.getIdToken();

      // 4. Intercambiar con Django
      return await _exchangeFirebaseToken(firebaseToken!);
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _firebaseErrorMsg(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Error al iniciar sesión con Google'};
    }
  }

  /// Registra un empleado nuevo vía Google usando el código de empresa.
  Future<Map<String, dynamic>> registerWithGoogle({
    required String companyCode,
  }) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Registro cancelado'};
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseToken = await userCredential.user!.getIdToken();

      return await _exchangeFirebaseToken(
        firebaseToken!,
        userType: 'employee',
        companyCode: companyCode,
      );
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _firebaseErrorMsg(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Error al registrarse con Google'};
    }
  }

  /// Envía el Firebase ID token a Django y recibe los tokens JWT propios.
  Future<Map<String, dynamic>> _exchangeFirebaseToken(
    String firebaseToken, {
    String? userType,
    String? companyCode,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/firebase/');
    final body = <String, dynamic>{'firebase_token': firebaseToken};
    if (userType != null) body['user_type'] = userType;
    if (companyCode != null) body['company_code'] = companyCode;

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );

      final data = json.decode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        final tokens = data['data']['tokens'];
        final userJson = data['data']['user'];
        await _storage.saveToken(tokens['access']);
        await _storage.saveRefreshToken(tokens['refresh']);
        final user = User.fromJson(userJson);
        await _storage.saveUserId(user.id.toString());
        return {'success': true, 'user': user};
      }

      // Usuario no encontrado — app debe pedir company_code
      if (response.statusCode == 404 || data['code'] == 'USER_NOT_FOUND') {
        return {
          'success': false,
          'needs_company_code': true,
          'firebase_token': firebaseToken,
          'email': data['email'] ?? '',
          'full_name': data['full_name'] ?? '',
          'message': data['message'] ?? 'Completa tu registro',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Error al autenticar',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión. Verifica tu red.'};
    }
  }

  /// Cierra sesión en Google y Firebase.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }

  String _firebaseErrorMsg(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con ese email usando otro método';
      case 'network-request-failed':
        return 'Sin conexión a internet';
      default:
        return 'Error de autenticación ($code)';
    }
  }
}

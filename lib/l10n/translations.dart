import 'package:flutter/material.dart';

class L10n {
  static final translations = {
    'en': {
      // General
      'cancel': 'Cancel',
      'save': 'Save',
      'ok': 'OK',
      'error': 'Error',
      'success': 'Success',
      'add': 'Add',
      
      // Bottom Nav
      'nav_chats': 'Chats',
      'nav_contacts': 'Contacts',
      'nav_calls': 'Calls',
      'nav_vault': 'Vault',
      'nav_settings': 'Settings',

      // Settings
      'settings': 'Settings',
      'account': 'ACCOUNT',
      'profile_info': 'Profile Information',
      'privacy_security': 'Privacy & Security',
      'two_factor': 'Two-Factor Authentication',
      'preferences': 'PREFERENCES',
      'notifications': 'Notifications',
      'appearance': 'Appearance',
      'language': 'Language',
      'danger_zone': 'DANGER ZONE',
      'logout': 'Log Out',
      'dark': 'DARK',
      'light': 'LIGHT',
      'english': 'English',
      'spanish': 'Spanish',
      'on': 'ON',
      'off': 'OFF',
      'mfa_required': 'MFA setup required in backend',
      'chat_notifications': 'Chat Notifications',
      'call_notifications': 'Call Notifications',

      // Login / Auth
      'email': 'Email',
      'password': 'Password',
      'login_btn': 'INITIALIZE SECURE LINK',
      'login_title': 'AUTHENTICATE',
      'signup_q': 'Don\'t have a clearance?',
      'signup_link': ' Create secure identity',
      
      // Verification
      'verification_title': 'Verification',
      'verify_title': 'Verify Phone',
      'verify_code_prompt': 'Enter Authentication Code',
      'verify_resend': 'Didn\'t receive a code? Resend',
      'verify_action': 'Verify Account',
      'verify_btn': 'VERIFY',
      'enter_code': 'Enter code',

      // Chat List
      'chats_title': 'Active Protocols',
      'start_chat': 'Initialize new communication protocol',

      // Chat Detail
      'chat_input_hint': 'Secure message...',
      'message_hint': 'Secure message...',
      'active_protocol': 'ACTIVE PROTOCOL',
      'redact_message': 'Redact Message',
      'no_messages': 'No secure messages yet.',

      // Contacts
      'contacts_title': 'Known Entities',
      'add_contact': 'Add Contact',
      'enter_cipher_id': 'Enter Cipher ID (Email)',

      // Calls
      'calls_title': 'Comms Log',
      'no_calls': 'No secure comms established yet',

      // Vault
      'vault_title': 'Encrypted Storage',
      'add_item': 'Add Item',
      'no_items': 'Storage empty',
      
      // Profile
      'profile_title': 'Identity Configuration',
      'display_name': 'Display Name',
      
      // Privacy
      'privacy_title': 'Privacy & Security Configuration',
      'read_receipts': 'Read Receipts',
      'typing_indicators': 'Typing Indicators',
      
      // System
      'biometrics_prompts': 'Authenticate to access Cipher',
    },
    'es': {
      // General
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'ok': 'OK',
      'error': 'Error',
      'success': 'Éxito',
      'add': 'Añadir',
      
      // Bottom Nav
      'nav_chats': 'Chats',
      'nav_contacts': 'Contactos',
      'nav_calls': 'Llamadas',
      'nav_vault': 'Bóveda',
      'nav_settings': 'Ajustes',

      // Settings
      'settings': 'Ajustes',
      'account': 'CUENTA',
      'profile_info': 'Información del Perfil',
      'privacy_security': 'Privacidad y Seguridad',
      'two_factor': 'Autenticación de Dos Pasos',
      'preferences': 'PREFERENCIAS',
      'notifications': 'Notificaciones',
      'appearance': 'Apariencia',
      'language': 'Idioma',
      'danger_zone': 'ZONA DE PELIGRO',
      'logout': 'Cerrar Sesión',
      'dark': 'OSCURO',
      'light': 'CLARO',
      'english': 'Inglés',
      'spanish': 'Español',
      'on': 'ACTIVO',
      'off': 'DESACTIVADO',
      'mfa_required': 'MFA requiere configuración en backend',
      'chat_notifications': 'Notificaciones de Chat',
      'call_notifications': 'Notificaciones de Llamadas',

      // Login / Auth
      'email': 'Correo electrónico',
      'password': 'Contraseña',
      'login_btn': 'INICIAR ENLACE SEGURO',
      'login_title': 'AUTENTICAR',
      'signup_q': '¿No tienes autorización?',
      'signup_link': ' Crear identidad segura',
      
      // Verification
      'verification_title': 'Verificación',
      'verify_title': 'Verificar Teléfono',
      'verify_code_prompt': 'Ingresa el Código de Autenticación',
      'verify_resend': '¿No recibiste un código? Reenviar',
      'verify_action': 'Verificar Cuenta',
      'verify_btn': 'VERIFICAR',
      'enter_code': 'Ingresa el código',

      // Chat List
      'chats_title': 'Protocolos Activos',
      'start_chat': 'Inicializar nuevo protocolo de comunicación',

      // Chat Detail
      'chat_input_hint': 'Mensaje seguro...',
      'message_hint': 'Mensaje seguro...',
      'active_protocol': 'PROTOCOLO ACTIVO',
      'redact_message': 'Eliminar Mensaje',
      'no_messages': 'Aún no hay mensajes seguros.',

      // Contacts
      'contacts_title': 'Entidades Conocidas',
      'add_contact': 'Añadir Contacto',
      'enter_cipher_id': 'Introduce el Cipher ID (Email)',

      // Calls
      'calls_title': 'Registro de Coms',
      'no_calls': 'Aún no se han establecido comunicaciones seguras',

      // Vault
      'vault_title': 'Almacenamiento Cifrado',
      'add_item': 'Añadir Elemento',
      'no_items': 'Almacenamiento vacío',
      
      // Profile
      'profile_title': 'Configuración de Identidad',
      'display_name': 'Nombre a mostrar',
      
      // Privacy
      'privacy_title': 'Configuración de Privacidad',
      'read_receipts': 'Confirmaciones de Lectura',
      'typing_indicators': 'Indicadores de Escritura',
      
      // System
      'biometrics_prompts': 'Autentíquese para acceder a Cipher',
    },
  };

  static String t(BuildContext context, String key) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return translations[languageCode]?[key] ?? translations['en']![key] ?? key;
  }
}

extension AppLocalizations on BuildContext {
  String tr(String key) => L10n.t(this, key);
}

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String _t(String spanish, String english) {
    return locale.languageCode == 'es' ? spanish : english;
  }

  // Generales
  String get appTitle => _t('Un día sin beber', 'A Day Without Drinking');
  String get login => _t('Iniciar sesión', 'Login');
  String get register => _t('Registrarse', 'Sign Up');
  String get email => _t('Correo electrónico', 'Email');
  String get password => _t('Contraseña', 'Password');
  String get confirmPassword => _t('Confirmar contraseña', 'Confirm password');

  // Login
  String get fillCredentials => _t(
    'Por favor, introduzca correo y contraseña',
    'Please enter email and password',
  );
  String get loginError => _t('Error al iniciar sesión', 'Login error');
  String get userNotFound =>
      _t('No existe usuario con este correo', 'User not found');
  String get wrongPassword => _t('Contraseña incorrecta', 'Wrong password');
  String get invalidEmail => _t('Correo electrónico inválido', 'Invalid email');
  String get userDisabled => _t('Usuario deshabilitado', 'User disabled');
  String get unexpectedError => _t('Error inesperado', 'Unexpected error');
  String get welcomeBack => _t('Bienvenido de nuevo', 'Welcome back');
  String get loginToContinue =>
      _t('Inicia sesión para continuar', 'Login to continue');
  String get emailHint => _t('ejemplo@correo.com', 'example@email.com');
  String get loginButton => _t('Iniciar Sesión', 'Login');
  String get noAccount => _t('¿No tienes cuenta? ', 'Don\'t have an account? ');
  String get signUpLink => _t('Regístrate', 'Sign Up');

  // Register
  String get createAccount => _t('Crear cuenta', 'Create account');
  String get startYourJourney => _t('Comienza tu viaje', 'Start your journey');
  String get registerButton => _t('Registrarse', 'Sign Up');
  String get alreadyHaveAccount =>
      _t('¿Ya tienes cuenta? ', 'Already have an account? ');
  String get loginLink => _t('Inicia sesión', 'Login');
  String get startDate => _t('Fecha de inicio', 'Start date');
  String get birthDate => _t('Fecha de nacimiento', 'Birth date');
  String get weight => _t('Peso (kg)', 'Weight (kg)');
  String get weightHint => _t('Ej: 70.5', 'Ex: 70.5');
  String get gender => _t('Sexo', 'Gender');
  String get male => _t('Masculino', 'Male');
  String get female => _t('Femenino', 'Female');
  String get nonBinary => _t('No binario', 'Non-binary');
  String get preferNotToSay => _t('Prefiero no decirlo', 'Prefer not to say');
  String get other => _t('Otro', 'Other');
  String get selectDate => _t('Seleccionar', 'Select');
  String get yearsOld => _t('años', 'years old');

  // Home
  String get myProgress => _t('Mi Progreso', 'My Progress');
  String get daysWithoutDrinking =>
      _t('Días sin beber', 'Days without drinking');
  String get dayWithoutDrinking => _t('Día sin beber', 'Day without drinking');
  String get age => _t('Edad', 'Age');
  String get years => _t('años', 'years');
  String get initialWeight => _t('Peso inicial', 'Initial weight');
  String get currentWeight => _t('Peso actual', 'Current weight');
  String get weightChange => _t('Cambio', 'Change');
  String get gained => _t('subidos', 'gained');
  String get lost => _t('bajados', 'lost');
  String get viewDetailedEvolution =>
      _t('Ver evolución detallada', 'View detailed evolution');
  String get since => _t('Desde el', 'Since');
  String get born => _t('Nacido', 'Born');

  // Peso Page
  String get weightEvolution => _t('Evolución del Peso', 'Weight Evolution');
  String get monthlyView => _t('Vista mensual', 'Monthly view');
  String get totalView => _t('Vista total', 'Total view');
  String get improved => _t('Mejoró', 'Improved');
  String get worsened => _t('Empeoró', 'Worsened');
  String get stable => _t('Estable', 'Stable');
  String get start => _t('Inicio', 'Start');
  String get current => _t('Actual', 'Current');
  String get change => _t('Cambio', 'Change');
  String get average => _t('Promedio', 'Average');
  String get maximum => _t('Máximo', 'Maximum');
  String get minimum => _t('Mínimo', 'Minimum');
  String get records => _t('Registros', 'Records');
  String get pending => _t('Pendiente de registrar', 'Pending');
  String get delete => _t('Eliminar', 'Delete');
  String get edit => _t('Editar', 'Edit');
  String get cancel => _t('Cancelar', 'Cancel');
  String get save => _t('Guardar', 'Save');
  String get noData => _t('No hay datos disponibles', 'No data available');
  String get noRecordsThisMonth =>
      _t('No hay registros de peso este mes', 'No weight records this month');
  String get firstMonthAvailable =>
      _t('El primer mes disponible es', 'The first available month is');

  // Update Checker
  String get updateAvailable =>
      _t('¡Nueva versión disponible!', 'New version available!');
  String get mandatoryUpdate =>
      _t('Actualización requerida', 'Mandatory update');
  String get download => _t('Descargar', 'Download');
  String get later => _t('Más tarde', 'Later');
  String get releaseNotes => _t('Novedades', "What's new");
  String get error => _t('Error', 'Error');
  String get ok => _t('Aceptar', 'OK');
  String get downloadInfo => _t(
    'La descarga se abrirá en el navegador externo. Después de instalar el APK, vuelve a abrir la app.',
    'The download will open in an external browser. After installing the APK, reopen the app.',
  );
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

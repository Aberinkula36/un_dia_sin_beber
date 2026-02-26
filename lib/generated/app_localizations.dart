import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Un día sin beber'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get login;

  /// No description provided for @register.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get register;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get dontHaveAccount;

  /// No description provided for @startDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de inicio'**
  String get startDate;

  /// No description provided for @birthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get birthDate;

  /// No description provided for @weight.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get weight;

  /// No description provided for @gender.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get male;

  /// No description provided for @female.
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get female;

  /// No description provided for @nonBinary.
  ///
  /// In es, this message translates to:
  /// **'No binario'**
  String get nonBinary;

  /// No description provided for @preferNotToSay.
  ///
  /// In es, this message translates to:
  /// **'Prefiero no decirlo'**
  String get preferNotToSay;

  /// No description provided for @other.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get other;

  /// No description provided for @myProgress.
  ///
  /// In es, this message translates to:
  /// **'Mi Progreso'**
  String get myProgress;

  /// No description provided for @daysWithoutDrinking.
  ///
  /// In es, this message translates to:
  /// **'Días sin beber'**
  String get daysWithoutDrinking;

  /// No description provided for @dayWithoutDrinking.
  ///
  /// In es, this message translates to:
  /// **'Día sin beber'**
  String get dayWithoutDrinking;

  /// No description provided for @age.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get age;

  /// No description provided for @years.
  ///
  /// In es, this message translates to:
  /// **'años'**
  String get years;

  /// No description provided for @initialWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso inicial'**
  String get initialWeight;

  /// No description provided for @currentWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso actual'**
  String get currentWeight;

  /// No description provided for @weightChange.
  ///
  /// In es, this message translates to:
  /// **'Cambio'**
  String get weightChange;

  /// No description provided for @gained.
  ///
  /// In es, this message translates to:
  /// **'subidos'**
  String get gained;

  /// No description provided for @lost.
  ///
  /// In es, this message translates to:
  /// **'bajados'**
  String get lost;

  /// No description provided for @viewDetailedEvolution.
  ///
  /// In es, this message translates to:
  /// **'Ver evolución detallada'**
  String get viewDetailedEvolution;

  /// No description provided for @since.
  ///
  /// In es, this message translates to:
  /// **'Desde el'**
  String get since;

  /// No description provided for @weightEvolution.
  ///
  /// In es, this message translates to:
  /// **'Evolución del Peso'**
  String get weightEvolution;

  /// No description provided for @monthlyView.
  ///
  /// In es, this message translates to:
  /// **'Vista mensual'**
  String get monthlyView;

  /// No description provided for @totalView.
  ///
  /// In es, this message translates to:
  /// **'Vista total'**
  String get totalView;

  /// No description provided for @improved.
  ///
  /// In es, this message translates to:
  /// **'Mejoró'**
  String get improved;

  /// No description provided for @worsened.
  ///
  /// In es, this message translates to:
  /// **'Empeoró'**
  String get worsened;

  /// No description provided for @stable.
  ///
  /// In es, this message translates to:
  /// **'Estable'**
  String get stable;

  /// No description provided for @start.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get start;

  /// No description provided for @current.
  ///
  /// In es, this message translates to:
  /// **'Actual'**
  String get current;

  /// No description provided for @change.
  ///
  /// In es, this message translates to:
  /// **'Cambio'**
  String get change;

  /// No description provided for @average.
  ///
  /// In es, this message translates to:
  /// **'Promedio'**
  String get average;

  /// No description provided for @maximum.
  ///
  /// In es, this message translates to:
  /// **'Máximo'**
  String get maximum;

  /// No description provided for @minimum.
  ///
  /// In es, this message translates to:
  /// **'Mínimo'**
  String get minimum;

  /// No description provided for @records.
  ///
  /// In es, this message translates to:
  /// **'Registros'**
  String get records;

  /// No description provided for @pending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de registrar'**
  String get pending;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @updateAvailable.
  ///
  /// In es, this message translates to:
  /// **'¡Nueva versión disponible!'**
  String get updateAvailable;

  /// No description provided for @mandatoryUpdate.
  ///
  /// In es, this message translates to:
  /// **'Actualización requerida'**
  String get mandatoryUpdate;

  /// No description provided for @download.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get download;

  /// No description provided for @later.
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get later;

  /// No description provided for @releaseNotes.
  ///
  /// In es, this message translates to:
  /// **'Novedades'**
  String get releaseNotes;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @ok.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get ok;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// Application title
  ///
  /// In es, this message translates to:
  /// **'HospitalTriaje'**
  String get appTitle;

  /// No description provided for @triageTitle.
  ///
  /// In es, this message translates to:
  /// **'Evaluación de Triaje'**
  String get triageTitle;

  /// No description provided for @triageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Responda las siguientes preguntas para determinar su nivel de urgencia'**
  String get triageSubtitle;

  /// No description provided for @nextQuestion.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get nextQuestion;

  /// No description provided for @startTriage.
  ///
  /// In es, this message translates to:
  /// **'Iniciar evaluación'**
  String get startTriage;

  /// No description provided for @triageResult.
  ///
  /// In es, this message translates to:
  /// **'Resultado del triaje'**
  String get triageResult;

  /// No description provided for @triageLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel {level}'**
  String triageLevel(int level);

  /// No description provided for @triageLabel.
  ///
  /// In es, this message translates to:
  /// **'{label}'**
  String triageLabel(String label);

  /// No description provided for @maxWaitTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo máximo de espera: {minutes} min'**
  String maxWaitTime(int minutes);

  /// No description provided for @complaintCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría: {category}'**
  String complaintCategory(String category);

  /// No description provided for @emergencyTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Atención Inmediata Requerida!'**
  String get emergencyTitle;

  /// No description provided for @emergencySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Siga estas instrucciones mientras espera ayuda'**
  String get emergencySubtitle;

  /// No description provided for @emergencyDoTitle.
  ///
  /// In es, this message translates to:
  /// **'Qué HACER'**
  String get emergencyDoTitle;

  /// No description provided for @emergencyDontTitle.
  ///
  /// In es, this message translates to:
  /// **'Qué NO HACER'**
  String get emergencyDontTitle;

  /// No description provided for @callEmergency.
  ///
  /// In es, this message translates to:
  /// **'Llamar al 911'**
  String get callEmergency;

  /// No description provided for @hospitalsNearby.
  ///
  /// In es, this message translates to:
  /// **'Hospitales cercanos'**
  String get hospitalsNearby;

  /// No description provided for @hospitalsLoading.
  ///
  /// In es, this message translates to:
  /// **'Buscando hospitales...'**
  String get hospitalsLoading;

  /// No description provided for @hospitalsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron hospitales disponibles en su área'**
  String get hospitalsEmpty;

  /// No description provided for @waitTime.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min de espera'**
  String waitTime(int minutes);

  /// No description provided for @availableBeds.
  ///
  /// In es, this message translates to:
  /// **'{count} camas disponibles'**
  String availableBeds(int count);

  /// No description provided for @distanceKm.
  ///
  /// In es, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @refer.
  ///
  /// In es, this message translates to:
  /// **'Derivar a este hospital'**
  String get refer;

  /// No description provided for @referSuccess.
  ///
  /// In es, this message translates to:
  /// **'Ha sido derivado exitosamente'**
  String get referSuccess;

  /// No description provided for @hospitalDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle del hospital'**
  String get hospitalDetail;

  /// No description provided for @specialties.
  ///
  /// In es, this message translates to:
  /// **'Especialidades disponibles'**
  String get specialties;

  /// No description provided for @availableNow.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get availableNow;

  /// No description provided for @unavailableNow.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get unavailableNow;

  /// No description provided for @mapTitle.
  ///
  /// In es, this message translates to:
  /// **'Mapa de hospitales'**
  String get mapTitle;

  /// No description provided for @authTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicie sesión para guardar sus evaluaciones'**
  String get authSubtitle;

  /// No description provided for @continueAnonymous.
  ///
  /// In es, this message translates to:
  /// **'Continuar sin cuenta'**
  String get continueAnonymous;

  /// No description provided for @loginWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get loginWithGoogle;

  /// No description provided for @loginWithEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo y contraseña'**
  String get loginWithEmail;

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

  /// No description provided for @register.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get register;

  /// No description provided for @login.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get profileTitle;

  /// No description provided for @myEvaluations.
  ///
  /// In es, this message translates to:
  /// **'Mis evaluaciones'**
  String get myEvaluations;

  /// No description provided for @deleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccount;

  /// No description provided for @offlineBanner.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión — mostrando datos en caché'**
  String get offlineBanner;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error. Intente de nuevo.'**
  String get errorGeneric;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @noData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos disponibles'**
  String get noData;

  /// No description provided for @fcmPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get fcmPermissionTitle;

  /// No description provided for @fcmPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'¿Desea recibir notificaciones sobre su triaje y estado del hospital?'**
  String get fcmPermissionBody;

  /// No description provided for @allow.
  ///
  /// In es, this message translates to:
  /// **'Permitir'**
  String get allow;

  /// No description provided for @deny.
  ///
  /// In es, this message translates to:
  /// **'Denegar'**
  String get deny;

  /// No description provided for @levelImmediate.
  ///
  /// In es, this message translates to:
  /// **'Inmediato'**
  String get levelImmediate;

  /// No description provided for @levelVeryUrgent.
  ///
  /// In es, this message translates to:
  /// **'Muy urgente'**
  String get levelVeryUrgent;

  /// No description provided for @levelUrgent.
  ///
  /// In es, this message translates to:
  /// **'Urgente'**
  String get levelUrgent;

  /// No description provided for @levelLessUrgent.
  ///
  /// In es, this message translates to:
  /// **'Menos urgente'**
  String get levelLessUrgent;

  /// No description provided for @levelNotUrgent.
  ///
  /// In es, this message translates to:
  /// **'No urgente'**
  String get levelNotUrgent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

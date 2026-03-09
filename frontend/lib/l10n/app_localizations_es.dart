// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'HospitalTriaje';

  @override
  String get triageTitle => 'Evaluación de Triaje';

  @override
  String get triageSubtitle =>
      'Responda las siguientes preguntas para determinar su nivel de urgencia';

  @override
  String get nextQuestion => 'Siguiente';

  @override
  String get startTriage => 'Iniciar evaluación';

  @override
  String get triageResult => 'Resultado del triaje';

  @override
  String triageLevel(int level) {
    return 'Nivel $level';
  }

  @override
  String triageLabel(String label) {
    return '$label';
  }

  @override
  String maxWaitTime(int minutes) {
    return 'Tiempo máximo de espera: $minutes min';
  }

  @override
  String complaintCategory(String category) {
    return 'Categoría: $category';
  }

  @override
  String get emergencyTitle => '¡Atención Inmediata Requerida!';

  @override
  String get emergencySubtitle =>
      'Siga estas instrucciones mientras espera ayuda';

  @override
  String get emergencyDoTitle => 'Qué HACER';

  @override
  String get emergencyDontTitle => 'Qué NO HACER';

  @override
  String get callEmergency => 'Llamar al 911';

  @override
  String get hospitalsNearby => 'Hospitales cercanos';

  @override
  String get hospitalsLoading => 'Buscando hospitales...';

  @override
  String get hospitalsEmpty =>
      'No se encontraron hospitales disponibles en su área';

  @override
  String waitTime(int minutes) {
    return '$minutes min de espera';
  }

  @override
  String availableBeds(int count) {
    return '$count camas disponibles';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String get refer => 'Derivar a este hospital';

  @override
  String get referSuccess => 'Ha sido derivado exitosamente';

  @override
  String get hospitalDetail => 'Detalle del hospital';

  @override
  String get specialties => 'Especialidades disponibles';

  @override
  String get availableNow => 'Disponible';

  @override
  String get unavailableNow => 'No disponible';

  @override
  String get mapTitle => 'Mapa de hospitales';

  @override
  String get authTitle => 'Iniciar sesión';

  @override
  String get authSubtitle => 'Inicie sesión para guardar sus evaluaciones';

  @override
  String get continueAnonymous => 'Continuar sin cuenta';

  @override
  String get loginWithGoogle => 'Continuar con Google';

  @override
  String get loginWithEmail => 'Correo y contraseña';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get register => 'Registrarse';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get profileTitle => 'Mi perfil';

  @override
  String get myEvaluations => 'Mis evaluaciones';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get offlineBanner => 'Sin conexión — mostrando datos en caché';

  @override
  String get loading => 'Cargando...';

  @override
  String get errorGeneric => 'Ocurrió un error. Intente de nuevo.';

  @override
  String get retry => 'Reintentar';

  @override
  String get noData => 'Sin datos disponibles';

  @override
  String get fcmPermissionTitle => 'Notificaciones';

  @override
  String get fcmPermissionBody =>
      '¿Desea recibir notificaciones sobre su triaje y estado del hospital?';

  @override
  String get allow => 'Permitir';

  @override
  String get deny => 'Denegar';

  @override
  String get levelImmediate => 'Inmediato';

  @override
  String get levelVeryUrgent => 'Muy urgente';

  @override
  String get levelUrgent => 'Urgente';

  @override
  String get levelLessUrgent => 'Menos urgente';

  @override
  String get levelNotUrgent => 'No urgente';
}

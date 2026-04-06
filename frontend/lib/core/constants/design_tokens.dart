/// Design tokens for HospitalTriaje.
///
/// All spacing, radius, elevation, and sizing constants are derived from
/// values observed across the codebase. Import this file instead of writing
/// hardcoded doubles.
///
/// DO NOT edit [TriageColors] here — those hex values are clinically mandated
/// and live in `core/theme/app_theme.dart`.

/// Spacing scale (padding, margins, gaps).
class AppSpacing {
  const AppSpacing._();

  /// 4 dp — extra-small gap (e.g. tight chip rows).
  static const double xs = 4.0;

  /// 6 dp — compact vertical banner padding.
  static const double xxs = 6.0;

  /// 8 dp — small gap between inline elements.
  static const double sm = 8.0;

  /// 10 dp — medium-small (e.g. between fields, inner avatar spacing).
  static const double ms = 10.0;

  /// 12 dp — comfortable gap between stacked fields / list items.
  static const double md = 12.0;

  /// 14 dp — input vertical content padding.
  static const double inputV = 14.0;

  /// 16 dp — standard section / screen padding.
  static const double lg = 16.0;

  /// 20 dp — option button horizontal padding.
  static const double xl = 20.0;

  /// 24 dp — large section padding, card inner padding.
  static const double xxl = 24.0;

  /// 32 dp — screen-level outer padding on focused forms.
  static const double xxxl = 32.0;
}

/// Border-radius tokens.
class AppRadius {
  const AppRadius._();

  /// 8 dp — small containers (e.g. inline error banners).
  static const double sm = 8.0;

  /// 10 dp — buttons and input fields.
  static const double button = 10.0;

  /// 10 dp — input fields (alias of [button]).
  static const double input = 10.0;

  /// 12 dp — cards and option chips.
  static const double card = 12.0;

  /// 16 dp — modal bottom sheet top corners.
  static const double bottomSheet = 16.0;
}

/// Elevation tokens.
class AppElevation {
  const AppElevation._();

  /// 2 dp — standard card surface.
  static const double card = 2.0;

  /// 8 dp — modal / overlay card (e.g. LoadingOverlay card).
  static const double modal = 8.0;
}

/// Sizing tokens.
class AppSizing {
  const AppSizing._();

  /// 52 dp — minimum height for ElevatedButton (full-width CTAs).
  static const double buttonHeight = 52.0;

  /// 48 dp — minimum tappable area (WCAG / Material guideline).
  static const double minTapTarget = 48.0;

  /// 40 dp — large circle avatar radius (result screen level badge).
  static const double avatarRadiusLg = 40.0;

  /// 14 dp — small circle avatar radius (urgency banner badge).
  static const double avatarRadiusSm = 14.0;
}

class PrefKeys {
  PrefKeys._();

  // ─── Salman ───────────────────────────────────────────────────────────────
  static const String userSessionToken = 'user_session_token';
  static const String userRole = 'user_role'; // 'admin' | 'customer'
  static const String selectedApp = 'selected_app'; // 'express' | 'farm'
  static const String lastPaymentMethod = 'last_payment_method';

  // ─── Ega ──────────────────────────────────────────────────────────────────
  static const String isOnboardingDone = 'is_onboarding_done';
  static const String selectedTableId = 'selected_table_id';
  static const String reservationDatePref = 'reservation_date_pref';

  // ─── Vemas ────────────────────────────────────────────────────────────────
  static const String isDarkMode = 'is_dark_mode';
  static const String selectedFarmType = 'selected_farm_type';
  static const String financeFilterPeriod = 'finance_filter_period';
}

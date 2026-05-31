class AppRoutes {
  AppRoutes._();

  // ─── Public / Onboarding ──────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String appSelector = '/app-selector';

  // ─── Express Auth ─────────────────────────────────────────────────────────
  static const String expressLogin = '/express/login';
  static const String expressRegister = '/express/register';

  // ─── Farm Auth ────────────────────────────────────────────────────────────
  static const String farmLogin = '/farm/login';
  static const String farmRegister = '/farm/register';

  // ─── Express Customer ─────────────────────────────────────────────────────
  static const String expressCustomerHome = '/express/home';
  static const String menuList = '/express/menu';
  static const String menuDetail = '/express/menu/detail';

  static const String cart = '/express/cart';
  static const String checkout = '/express/checkout';
  static const String qrisPayment = '/express/payment/qris';
  static const String orderConfirmation = '/express/order/confirm';
  static const String orderHistory = '/express/order/history';
  static const String orderDetail = '/express/order/detail';

  static const String reservation = '/express/reservation';
  static const String reservationConfirmation = '/express/reservation/confirm';
  static const String reservationHistory = '/express/reservation/history';
  static const String reservationDetail = '/express/reservation/detail';

  // ─── Express Admin ────────────────────────────────────────────────────────
  static const String expressAdminDashboard = '/express/admin';
  static const String menuManagement = '/express/admin/menu/manage';
  static const String tableManagement = '/express/admin/table/manage';

  // ─── Farm Customer ────────────────────────────────────────────────────────
  static const String farmCustomerHome = '/farm/home';
  static const String farmPackageDetail = '/farm/package/detail';
  static const String farmFinanceHistory = '/farm/finance/history';
  static const String farmFinanceInput = '/farm/finance/input';
  static const String farmFinanceDetail = '/farm/finance/detail';

  // ─── Farm Admin ───────────────────────────────────────────────────────────
  static const String farmAdminDashboard = '/farm/admin';
  static const String farmManagement = '/farm/admin/package/manage';

  // ─── Shared Profile ───────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  // ─── Legacy aliases (kept for backward compat) ────────────────────────────
  static const String login = expressLogin;
  static const String register = expressRegister;
  static const String home = expressCustomerHome;
  static const String expressHome = expressCustomerHome;
  static const String farmHome = farmCustomerHome;
}

import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/profile_screen.dart';
import '../../features/home/screens/edit_profile_screen.dart';
import '../../features/home/screens/settings_screen.dart';
import '../../features/express/express_home/screens/express_home_screen.dart';
import '../../features/express/menu/screens/menu_list_screen.dart';
import '../../features/express/menu/screens/menu_detail_screen.dart';
import '../../features/express/menu/screens/menu_management_screen.dart';
import '../../features/express/menu/models/menu_item_model.dart';
import '../../features/express/order/screens/cart_screen.dart';
import '../../features/express/order/screens/checkout_screen.dart';
import '../../features/express/order/screens/qris_payment_screen.dart';
import '../../features/express/order/screens/order_confirmation_screen.dart';
import '../../features/express/order/screens/order_history_screen.dart';
import '../../features/express/order/screens/order_detail_screen.dart';
import '../../features/express/order/models/order_model.dart';
import '../../features/express/reservation/screens/reservation_screen.dart';
import '../../features/express/reservation/screens/reservation_history_screen.dart';
import '../../features/express/table/screens/table_management_screen.dart';
import '../../features/farm/package/screens/farm_home_screen.dart';
import '../../features/farm/finance/screens/finance_history_screen.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.splash:
        return _slide(const SplashScreen());
      case AppRoutes.onboarding:
        return _slide(const OnboardingScreen());
      case AppRoutes.login:
        return _slide(const LoginScreen());
      case AppRoutes.register:
        return _slide(const RegisterScreen());

      case AppRoutes.home:
        return _slide(const HomeScreen());
      case AppRoutes.profile:
        return _slide(const ProfileScreen());
      case AppRoutes.editProfile:
        return _slide(const EditProfileScreen());
      case AppRoutes.settings:
        return _slide(const SettingsScreen());

      case AppRoutes.expressHome:
        return _slide(const ExpressHomeScreen());
      case AppRoutes.menuList:
        return _slide(const MenuListScreen());
      case AppRoutes.menuDetail:
        final item = args as MenuItemModel;
        return _slide(MenuDetailScreen(item: item));
      case AppRoutes.menuManagement:
        return _slide(const MenuManagementScreen());

      case AppRoutes.cart:
        return _slide(const CartScreen());
      case AppRoutes.checkout:
        return _slide(const CheckoutScreen());
      case AppRoutes.qrisPayment:
        return _slide(QrisPaymentScreen(orderCode: args as String));
      case AppRoutes.orderConfirmation:
        return _slide(OrderConfirmationScreen(orderCode: args as String));
      case AppRoutes.orderHistory:
        return _slide(const OrderHistoryScreen());
      case AppRoutes.orderDetail:
        final order = args as OrderModel;
        return _slide(OrderDetailScreen(order: order));

      case AppRoutes.reservation:
        return _slide(const ReservationScreen());
      case AppRoutes.reservationHistory:
        return _slide(const ReservationHistoryScreen());
      case AppRoutes.tableManagement:
        return _slide(const TableManagementScreen());

      case AppRoutes.farmHome:
        return _slide(const FarmHomeScreen());
      case AppRoutes.farmFinanceHistory:
        return _slide(const FinanceHistoryScreen());

      default:
        return _slide(const Scaffold(
          body: Center(child: Text('Halaman tidak ditemukan')),
        ));
    }
  }

  static PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

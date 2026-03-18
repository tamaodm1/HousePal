import 'package:flutter/material.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/chores/chores_screen.dart';
import '../screens/chores/chores_detail_screen.dart';
import '../screens/chores/add_chore_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/expenses/expenses_detail_screen.dart';
import '../screens/expenses/add_expense_screen.dart';
import '../screens/expenses/settle_debt_screen.dart';
import '../screens/expenses/balance_sheet_screen.dart';
import '../screens/expenses/expense_split_screen.dart';
import '../screens/bulletin/bulletin_screen.dart';
import '../screens/bulletin/bulletin_detail_screen.dart';
import '../screens/bulletin/add_note_screen.dart';
import '../screens/bulletin/add_shopping_item_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_info_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String chores = '/chores';
  static const String choresDetail = '/chores-detail';
  static const String addChore = '/add-chore';
  static const String leaderboard = '/leaderboard';
  static const String expenses = '/expenses';
  static const String expensesDetail = '/expenses-detail';
  static const String addExpense = '/add-expense';
  static const String settleDebt = '/settle-debt';
  static const String balanceSheet = '/balance-sheet';
  static const String expenseSplit = '/expense-split';
  static const String bulletin = '/bulletin';
  static const String bulletinDetail = '/bulletin-detail';
  static const String addNote = '/add-note';
  static const String addShoppingItem = '/add-shopping-item';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String profileInfo = '/profile-info';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    chores: (context) => const ChoresScreen(),
    choresDetail: (context) => const ChoresDetailScreen(),
    addChore: (context) => const AddChoreScreen(),
    leaderboard: (context) => const LeaderboardScreen(),
    expenses: (context) => const ExpensesScreen(),
    expensesDetail: (context) => const ExpensesDetailScreen(),
    addExpense: (context) => const AddExpenseScreen(),
    settleDebt: (context) => const SettleDebtScreen(),
    balanceSheet: (context) => const BalanceSheetScreen(),
    expenseSplit: (context) => const ExpenseSplitScreen(),
    bulletin: (context) => const BulletinScreen(),
    bulletinDetail: (context) => const BulletinDetailScreen(),
    addNote: (context) => const AddNoteScreen(),
    addShoppingItem: (context) => const AddShoppingItemScreen(),
    notifications: (context) => const NotificationsScreen(),
    settings: (context) => const SettingsScreen(),
    profileInfo: (context) => const ProfileInfoScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return null;
  }
}

import 'package:apexo/features/dashboard/dashboard_screen.dart';
import 'package:apexo/features/expenses/expenses_screen.dart';
import 'package:apexo/features/labwork/labworks_screen.dart';
import 'package:apexo/features/patients/patients_screen.dart';
import 'package:apexo/features/stats/screen_stats.dart';
import 'package:apexo/services/admins.dart';
import 'package:apexo/services/backups.dart';
import 'package:apexo/features/stats/charts_controller.dart';
import 'package:apexo/services/permissions.dart';
import 'package:apexo/services/login.dart';
import 'package:apexo/features/appointments/appointment_model.dart';
import 'package:apexo/features/expenses/expense_model.dart';
import 'package:apexo/features/expenses/expenses_store.dart';
import 'package:apexo/features/labwork/labwork_model.dart';
import 'package:apexo/features/labwork/labworks_store.dart';
import 'package:apexo/features/patients/patient_model.dart';
import 'package:apexo/features/patients/patients_store.dart';
import 'package:apexo/features/doctors/doctor_model.dart';
import 'package:apexo/features/doctors/doctors_store.dart';
import 'package:apexo/services/users.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../services/localization/locale.dart';
import 'package:apexo/features/appointments/calendar_screen.dart';
import 'package:apexo/features/doctors/doctors_screen.dart';
import 'package:apexo/features/settings/settings_screen.dart';
import '../core/observable.dart';
import "../features/appointments/appointments_store.dart";
import "../features/settings/settings_stores.dart";

class Route {
  IconData icon;
  String title;
  String identifier;
  Widget Function() screen;

  /// show in the navigation pane and thus being activated
  bool accessible;

  /// show in the footer of the navigation pane
  bool onFooter;

  /// callback to be called when the route is selected
  void Function()? onSelect;

  Route({
    required this.title,
    required this.identifier,
    required this.icon,
    required this.screen,
    this.accessible = true,
    this.onFooter = false,
    this.onSelect,
  });
}

class Routes extends ObservableObject {
  List<Route> genAllRoutes() => [
        Route(
          title: txt("dashboard"),
          identifier: "dashboard",
          icon: FluentIcons.home,
          screen: DashboardScreen.new,
          accessible: true,
          onSelect: () {
            chartsCtrl.resetSelected();
            patients.synchronize();
            appointments.synchronize();
          },
        ),
        Route(
          title: txt("doctors"),
          identifier: "doctors",
          icon: FluentIcons.medical,
          screen: DoctorsScreen.new,
          accessible: permissions.list[0] || login.isAdmin,
          onSelect: () {
            doctors.synchronize();
          },
        ),
        Route(
          title: txt("patients"),
          identifier: "patients",
          icon: FluentIcons.medication_admin,
          screen: PatientsScreen.new,
          accessible: permissions.list[1] || login.isAdmin,
          onSelect: () {
            patients.synchronize();
          },
        ),
        Route(
          title: txt("appointments"),
          identifier: "calendar",
          icon: FluentIcons.calendar,
          screen: CalendarScreen.new,
          accessible: permissions.list[2] || login.isAdmin,
          onSelect: () {
            appointments.synchronize();
          },
        ),
        Route(
          title: txt("labworks"),
          identifier: "labworks",
          icon: FluentIcons.manufacturing,
          screen: LabworksScreen.new,
          accessible: permissions.list[3] || login.isAdmin,
          onSelect: () {
            labworks.synchronize();
          },
        ),
        Route(
          title: txt("expenses"),
          identifier: "expenses",
          icon: FluentIcons.receipt_processing,
          screen: ExpensesScreen.new,
          accessible: permissions.list[4] || login.isAdmin,
          onSelect: () {
            expenses.synchronize();
          },
        ),
        Route(
          title: txt("statistics"),
          identifier: "statistics",
          icon: FluentIcons.chart,
          screen: StatsScreen.new,
          accessible: permissions.list[5] || login.isAdmin,
          onSelect: () {
            chartsCtrl.resetSelected();
            patients.synchronize();
            appointments.synchronize();
          },
        ),
        Route(
          title: txt("settings"),
          identifier: "settings",
          icon: FluentIcons.settings,
          screen: SettingsScreen.new,
          accessible: true,
          onFooter: false,
          onSelect: () {
            globalSettings.synchronize();
            admins.reloadFromRemote();
            backups.reloadFromRemote();
            permissions.reloadFromRemote();
            users.reloadFromRemote();
          },
        ),
      ];

  late List<Route> allRoutes = genAllRoutes();

  int currentRouteIndex = 0;
  List<int> history = [];

  // bottom sheets
  Patient openPatient = Patient.fromJson({});
  Appointment openAppointment = Appointment.fromJson({});
  Doctor openMember = Doctor.fromJson({});
  Labwork openLabwork = Labwork.fromJson({});
  Expense openExpense = Expense.fromJson({});

  int selectedTabInSheet = 0;

  Route get currentRoute {
    if (currentRouteIndex < 0 || currentRouteIndex >= allRoutes.length) {
      return allRoutes.first;
    }
    return allRoutes[currentRouteIndex];
  }

  goBack() {
    if (history.isNotEmpty) {
      currentRouteIndex = history.removeLast();
      if (currentRoute.onSelect != null) {
        currentRoute.onSelect!();
      }
    }
    notify();
  }

  navigate(Route route) {
    if (currentRouteIndex == allRoutes.indexOf(route)) return;
    history.add(currentRouteIndex);
    currentRouteIndex = allRoutes.indexOf(route);
    if (currentRoute.onSelect != null) {
      currentRoute.onSelect!();
    }
    notify();
  }

  Route? getByIdentifier(String identifier) {
    var target = allRoutes.where((element) => element.identifier == identifier);
    if (target.isEmpty) return null;
    return target.first;
  }
}

final Routes routes = Routes();

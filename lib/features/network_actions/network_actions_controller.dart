import 'package:apexo/features/login/login_controller.dart';
import 'package:apexo/services/launch.dart';
import 'package:apexo/services/network.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../services/login.dart';
import '../../core/observable.dart';

class NetworkAction {
  String tooltip;
  IconData iconData;
  void Function()? onPressed;
  Color activeColor;
  bool? hidden;
  bool? disabled;
  bool? processing;
  bool? animate;
  String? badge;
  NetworkAction({
    required this.tooltip,
    required this.iconData,
    required this.onPressed,
    required this.activeColor,
    this.hidden,
    this.disabled,
    this.processing,
    this.animate,
    this.badge,
  });
}

class _NetworkActions extends ObservableObject {
  final isSyncing = ObservableState(0);

  Map<String, void Function()> syncCallbacks = {};
  Map<String, void Function()> reconnectCallbacks = {};

  resync() async {
    await login.activate(login.url, [login.token], true);

    for (var callback in syncCallbacks.values) {
      callback();
    }
  }

  List<NetworkAction> get actions {
    return [
      NetworkAction(
        tooltip: "Synchronize",
        iconData: FluentIcons.sync,
        onPressed: () async {
          if (launch.isDemo()) return;
          await resync();
        },
        badge: isSyncing() > 0 ? "${isSyncing()}" : syncCallbacks.length.toString(),
        disabled: (network.isOnline() == false || isSyncing() > 0 || loginCtrl.proceededOffline()),
        processing: isSyncing() > 0 || loginCtrl.loadingIndicator().isNotEmpty,
        animate: true,
        activeColor: Colors.blue,
      ),
      NetworkAction(
        tooltip: "Reconnect",
        iconData:
            (network.isOnline() && !loginCtrl.proceededOffline()) ? FluentIcons.streaming : FluentIcons.streaming_off,
        onPressed: () async {
          if (launch.isDemo()) return;
          await login.activate(login.url, [login.token], true);
          for (var callback in reconnectCallbacks.values) {
            callback();
          }
        },
        disabled: (network.isOnline() && !loginCtrl.proceededOffline()),
        processing: (network.isOnline() && !loginCtrl.proceededOffline()),
        animate: false,
        activeColor: Colors.teal,
      ),
    ];
  }
}

final networkActions = _NetworkActions();

import 'package:apexo/services/localization/locale.dart';
import 'package:fluent_ui/fluent_ui.dart';

class CloseButtonInDialog extends StatelessWidget {
  final String buttonText;
  const CloseButtonInDialog({
    this.buttonText = "cancel",
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.black)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [const Icon(FluentIcons.cancel), const SizedBox(width: 10), Txt(txt(buttonText))],
      ),
      onPressed: () => Navigator.pop(context),
    );
  }
}
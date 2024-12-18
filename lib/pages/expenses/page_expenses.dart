import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/expenses/modal_expenses.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/pages/shared/datatable.dart';
import 'package:apexo/state/stores/expenses/expenses_model.dart';
import 'package:apexo/state/stores/expenses/expenses_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ExpensesPage extends ObservingWidget {
  const ExpensesPage({super.key});

  @override
  getObservableState() {
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.expensesPage,
      padding: EdgeInsets.zero,
      content: Column(
        children: [
          Expanded(
            child: DataTable<Expense>(
              compact: true,
              items: expenses.present.values.toList(),
              actions: [
                DataTableAction(
                  callback: (_) {
                    openSingleReceipt(
                        context: context, json: {}, title: txt("newReceipt"), onSave: expenses.set, editing: false);
                  },
                  icon: FluentIcons.manufacturing,
                  title: txt("add"),
                ),
                DataTableAction(
                  callback: (ids) {
                    for (var id in ids) {
                      expenses.archive(id);
                    }
                  },
                  icon: FluentIcons.archive,
                  title: txt("archiveSelected"),
                )
              ],
              furtherActions: [const SizedBox(width: 5), ArchiveToggle(notifier: expenses.notify)],
              onSelect: (item) => {
                openSingleReceipt(
                    context: context, json: item.toJson(), title: txt("receipt"), onSave: expenses.set, editing: true)
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math';

import 'package:apexo/backend/utils/color_based_on_payment.dart';
import 'package:apexo/backend/utils/colors_without_yellow.dart';
import 'package:apexo/backend/utils/get_deterministic_item.dart';
import 'package:apexo/pages/page_calendar.dart';
import 'package:apexo/pages/page_patients.dart';
import 'package:apexo/pages/page_staff.dart';
import 'package:apexo/pages/widgets/acrylic_title.dart';
import 'package:apexo/pages/widgets/grid_gallery.dart';
import 'package:apexo/state/stores/appointments/appointment_model.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';

enum AppointmentSections { patient, staff, photos, preNotes, postNotes, prescriptions, pay }

// ignore: must_be_immutable
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final List<AppointmentSections> hide;
  final String? difference;
  late Color color;
  AppointmentCard({super.key, required this.appointment, this.difference, this.hide = const []}) {
    color = appointment.archived == true
        ? Colors.grey
        : (appointment.isMissed)
            ? Colors.red
            : getDeterministicItem(colorsWithoutYellow, appointment.id).light;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 15, 15, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _doneCheckBox(),
                  if (appointment.archived == true) ...[
                    _verticalSpacing(10),
                    const Icon(FluentIcons.archive),
                  ] else if (appointment.isMissed == true) ...[
                    _verticalSpacing(10),
                    Icon(FluentIcons.event_date_missed12, color: color),
                  ] else if (!appointment.fullPaid) ...[
                    _verticalSpacing(10),
                    Icon(FluentIcons.money, color: color),
                  ],
                ],
              ),
              _horizontalSpacing(4),
              Expanded(
                child: Acrylic(
                  elevation: 100,
                  blurAmount: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  child: Container(
                    decoration: _coloredHandleDecoration(),
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        if (appointment.patient != null && !hide.contains(AppointmentSections.patient)) ...[
                          ..._betweenSections,
                          _buildSection(
                            "Patient",
                            GestureDetector(
                                onTap: () {
                                  openSinglePatient(
                                      context: context,
                                      json: appointment.patient!.toJson(),
                                      title: "Patient",
                                      onSave: patients.modify,
                                      editing: true);
                                },
                                child: AcrylicTitle(item: appointment.patient!)),
                            FluentIcons.medical,
                          ),
                        ],
                        if (appointment.operators.isNotEmpty && !hide.contains(AppointmentSections.staff)) ...[
                          ..._betweenSections,
                          _buildSection(
                            "Operators",
                            Column(
                              children: appointment.operators
                                  .map((e) => GestureDetector(
                                      onTap: () {
                                        openSingleMember(
                                          context: context,
                                          json: e.toJson(),
                                          title: "Operator",
                                          onSave: staff.modify,
                                          editing: true,
                                        );
                                      },
                                      child: AcrylicTitle(item: e, maxWidth: 115)))
                                  .toList(),
                            ),
                            FluentIcons.medical,
                          ),
                        ],
                        if (appointment.imgs.isNotEmpty && !hide.contains(AppointmentSections.photos)) ...[
                          ..._betweenSections,
                          _buildSection(
                            "photos",
                            GridGallery(
                              imgs: appointment.imgs,
                              countPerLine: 4,
                              clipCount: 4,
                              rowWidth: 200,
                              size: 43,
                            ),
                            FluentIcons.camera,
                          ),
                        ],
                        if (appointment.preOpNotes.isNotEmpty && !hide.contains(AppointmentSections.preNotes)) ...[
                          ..._betweenSections,
                          _buildSection(
                              "Pre-op notes",
                              Text(
                                appointment.preOpNotes,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              FluentIcons.quick_note),
                        ],
                        if (appointment.postOpNotes.isNotEmpty && !hide.contains(AppointmentSections.postNotes)) ...[
                          ..._betweenSections,
                          _buildSection(
                              "Post-op notes",
                              Text(
                                appointment.postOpNotes,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              FluentIcons.quick_note),
                        ],
                        if (appointment.prescriptions.isNotEmpty &&
                            !hide.contains(AppointmentSections.prescriptions)) ...[
                          ..._betweenSections,
                          _buildSection(
                            "prescription",
                            Text(
                              appointment.prescriptions.join("\n"),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            FluentIcons.pill,
                          ),
                        ],
                        if (appointment.price != 0 && !hide.contains(AppointmentSections.pay)) ...[
                          ..._betweenSections,
                          _buildSection(
                            "Pay",
                            _paymentPills(),
                            FluentIcons.money,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          _verticalSpacing(),
          if (difference != null) _buildTimeDifference()
        ],
      ),
    );
  }

  Padding _doneCheckBox() {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Checkbox(
        checked: appointment.isDone(),
        onChanged: (checked) {
          appointment.isDone(checked);
          appointments.modify(appointment);
        },
        style: CheckboxThemeData(
          checkedDecoration: WidgetStatePropertyAll(
            BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }

  Center _buildTimeDifference() {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _spacerIcon(1),
        _horizontalSpacing(),
        Text(
          difference!,
          style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.5), fontWeight: FontWeight.bold),
        ),
        _horizontalSpacing(),
        _spacerIcon(-1),
      ],
    ));
  }

  Column _paymentPills() {
    final color = colorBasedOnPayments(appointment.paid, appointment.price);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _paymentPill("price", appointment.price.toString(), null, color),
            _horizontalSpacing(),
            _paymentPill("paid", appointment.paid.toString(), null, color),
          ],
        ),
        _verticalSpacing(),
        if (appointment.paid != appointment.price)
          _paymentPill(
            appointment.overPaid ? "Overpaid" : "Underpaid",
            appointment.paid.toString(),
            colorBasedOnPayments(appointment.paid, appointment.price),
          ),
      ],
    );
  }

  Acrylic _paymentPill(String title, String amount, [Color? color, Color? textColor]) {
    final Color finalTextColor = textColor ?? (color == null ? Colors.grey : Colors.white);
    return Acrylic(
      luminosityAlpha: 1,
      tintAlpha: 1,
      blurAmount: 100,
      elevation: 20,
      tint: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
        child: Wrap(
          children: [
            Text(
              title,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                color: finalTextColor,
              ),
            ),
            const SizedBox(width: 5),
            const Divider(direction: Axis.vertical, size: 10),
            const SizedBox(width: 5),
            Text(
              amount,
              style: TextStyle(color: finalTextColor),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> get _betweenSections {
    return [_verticalSpacing(), _divider(), _verticalSpacing()];
  }

  Divider _divider() => const Divider(size: 300);

  Transform _spacerIcon([flip = 1]) {
    return Transform.flip(
      flipX: flip == 1 ? true : false,
      flipY: false,
      child: Transform.translate(
        offset: Offset(0, flip < 1 ? 2.0 * flip : 5.0 * flip),
        child: Transform.rotate(
          angle: (pi / (flip == 1 ? 2 : 1)) * flip,
          child: Icon(
            color: Colors.grey.withOpacity(0.3),
            FluentIcons.turn_right,
            size: 14,
          ),
        ),
      ),
    );
  }

  Row _buildSection(String title, Widget child, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                icon,
                size: 13,
                color: color.withOpacity(0.5),
              ),
            ),
            Acrylic(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              elevation: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
        _horizontalSpacing(),
        Expanded(child: child),
      ],
    );
  }

  SizedBox _horizontalSpacing([double n = 5]) => SizedBox(width: n);

  SizedBox _verticalSpacing([double n = 10.0]) => SizedBox(height: n);

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "appointment",
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
            _verticalSpacing(3),
            Row(
              children: [
                Icon(FluentIcons.clock, color: color),
                _horizontalSpacing(),
                _buildFormattedDate(color),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(FluentIcons.edit, size: 17),
          onPressed: () {
            openSingleAppointment(
              context: context,
              json: appointment.toJson(),
              title: "Editing appointment",
              onSave: appointments.modify,
              editing: true,
            );
          },
          iconButtonMode: IconButtonMode.large,
        )
      ],
    );
  }

  Text _buildFormattedDate(Color color) {
    return Text(
      DateFormat("E d/MM yyyy - hh:mm a").format(appointment.date()),
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
    );
  }

  BoxDecoration _coloredHandleDecoration() {
    return BoxDecoration(
      border: Border(
        left: BorderSide(
          color: color,
          width: 5,
        ),
      ),
    );
  }
}
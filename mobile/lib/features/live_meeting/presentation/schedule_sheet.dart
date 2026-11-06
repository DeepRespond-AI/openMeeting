import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/app_switch_list_tile.dart';
import '../../../core/widgets/text_limit.dart';
import '../domain/live_models.dart';
import 'live_feedback.dart';
import 'schedules_controller.dart';

class ScheduleSheet extends ConsumerStatefulWidget {
  const ScheduleSheet({this.item, super.key});
  final LiveSchedule? item;
  @override
  ConsumerState<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends ConsumerState<ScheduleSheet> {
  final title = TextEditingController(), password = TextEditingController();
  late DateTime start;
  late int duration;
  bool wait = false, pwd = false, remind = true, busy = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    final config = ref.read(appConfigProvider).live;
    final item = widget.item;
    title.text = item?.title ?? '';
    password.text = item?.pwd ?? '';
    start =
        item?.startAt.toLocal() ?? DateTime.now().add(Duration(minutes: config.defaultDurationMin));
    duration = item?.durationMin ?? config.defaultDurationMin;
    wait = item?.waitRoom ?? false;
    pwd = item?.pwdEnabled ?? false;
    remind = item?.remind ?? true;
  }

  @override
  void dispose() {
    title.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final l = context.l10n;
    if (busy) return;
    if (title.text.trim().isEmpty) {
      setState(() => error = l.liveTitleRequired);
      return;
    }
    if (pwd && !RegExp(r'^[0-9]{4,6}$').hasMatch(password.text)) {
      setState(() => error = l.livePasswordInvalid);
      return;
    }
    if (!start.isAfter(DateTime.now()) && start.toUtc() != widget.item?.startAt.toUtc()) {
      setState(() => error = l.liveFutureTime);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(liveSchedulesProvider.notifier).save({
        'title': title.text.trim(),
        'startAt': start.toUtc().toIso8601String(),
        'durationMin': duration,
        'pwdEnabled': pwd,
        'pwd': pwd ? password.text : null,
        'waitRoom': wait,
        'remind': remind,
      }, id: widget.item?.id);
      if (mounted) Navigator.pop(context);
    } on Object catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, config = ref.watch(appConfigProvider).live;
    return PopScope(
      canPop: !busy,
      child: Padding(
        padding: context.spacing.page.add(
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.item == null ? l.liveSchedule : l.liveEditSchedule,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              context.spacing.gapLg,
              TextField(
                controller: title,
                maxLength: config.titleMax,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                inputFormatters: [CodePointLengthFormatter(config.titleMax)],
                buildCounter: codePointCounter(title, config.titleMax),
                enabled: !busy,
                decoration: InputDecoration(labelText: l.liveTitle),
              ),
              ListTile(
                key: const ValueKey('schedule-date'),
                title: Text(l.liveScheduleDate),
                subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(start)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: busy
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: start.isBefore(DateTime.now()) ? DateTime.now() : start,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: config.scheduleMaxDays)),
                        );
                        if (date == null || !context.mounted) return;
                        setState(
                          () => start = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            start.hour,
                            start.minute,
                          ),
                        );
                      },
              ),
              ListTile(
                key: const ValueKey('schedule-time'),
                title: Text(l.liveStartTime),
                subtitle: Text(TimeOfDay.fromDateTime(start).format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: busy
                    ? null
                    : () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(start),
                          initialEntryMode: TimePickerEntryMode.input,
                        );
                        if (time != null && mounted) {
                          setState(
                            () => start = DateTime(
                              start.year,
                              start.month,
                              start.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        }
                      },
              ),
              DropdownButtonFormField<int>(
                initialValue: duration,
                decoration: InputDecoration(labelText: l.liveDuration),
                items:
                    ({
                          ...{
                            config.minDurationMin,
                            config.defaultDurationMin,
                            60,
                            90,
                            120,
                            config.maxDurationMin,
                          },
                          duration,
                        }.toList()..sort())
                        .map((v) => DropdownMenuItem(value: v, child: Text(l.liveMinutes(v))))
                        .toList(),
                onChanged: busy ? null : (v) => setState(() => duration = v!),
              ),
              AppSwitchListTile(
                title: Text(l.liveRequirePassword),
                value: pwd,
                onChanged: busy ? null : (v) => setState(() => pwd = v),
              ),
              if (pwd)
                TextField(
                  controller: password,
                  enabled: !busy,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(labelText: l.livePassword),
                ),
              AppSwitchListTile(
                title: Text(l.liveWaitingRoom),
                value: wait,
                onChanged: busy ? null : (v) => setState(() => wait = v),
              ),
              AppSwitchListTile(
                title: Text(l.liveReminder(config.reminderLeadMin)),
                value: remind,
                onChanged: busy ? null : (v) => setState(() => remind = v),
              ),
              if (error != null) LiveError(error!),
              context.spacing.gapLg,
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(busy ? l.liveSaving : l.liveSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

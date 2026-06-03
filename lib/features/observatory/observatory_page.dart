import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/observatory/data/observations_repository.dart';
import 'package:sima_movil_froned/features/observatory/models/observation.dart';

const _wideBreakpoint = 760.0;
const _allOption = 'Todos';

class ObservatoryPage extends StatefulWidget {
  const ObservatoryPage({
    super.key,
    this.repository = const BackendObservationsRepository(),
  });

  final ObservationsRepository repository;

  @override
  State<ObservatoryPage> createState() => _ObservatoryPageState();
}

class _ObservatoryPageState extends State<ObservatoryPage> {
  late Future<ObservationDashboard> _dashboardFuture;
  String _selectedType = _allOption;
  String _selectedSeverity = _allOption;
  String _selectedStatus = _allOption;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = widget.repository.fetchCurrentApprenticeObservations();
  }

  void _reload() {
    setState(() {
      _dashboardFuture = widget.repository.fetchCurrentApprenticeObservations();
    });
  }

  List<Observation> _filterObservations(List<Observation> observations) {
    return observations
        .where((observation) {
          final observationDate = _dateOnly(observation.date);
          final matchesType =
              _selectedType == _allOption ||
              observation.typeLabel == _selectedType;
          final matchesSeverity =
              _selectedSeverity == _allOption ||
              _severityLabel(observation.severity) == _selectedSeverity;
          final matchesStatus =
              _selectedStatus == _allOption ||
              observation.statusLabel == _selectedStatus;
          final matchesFrom =
              _fromDate == null ||
              !observationDate.isBefore(_dateOnly(_fromDate!));
          final matchesTo =
              _toDate == null || !observationDate.isAfter(_dateOnly(_toDate!));

          return matchesType &&
              matchesSeverity &&
              matchesStatus &&
              matchesFrom &&
              matchesTo;
        })
        .toList(growable: false);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_fromDate ?? DateTime.now())
          : (_toDate ?? _fromDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      if (isFrom) {
        _fromDate = selected;
        if (_toDate != null && _toDate!.isBefore(selected)) {
          _toDate = selected;
        }
      } else {
        _toDate = selected;
        if (_fromDate != null && selected.isBefore(_fromDate!)) {
          _fromDate = selected;
        }
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedType = _allOption;
      _selectedSeverity = _allOption;
      _selectedStatus = _allOption;
      _fromDate = null;
      _toDate = null;
    });
  }

  void _applyFilters() {
    _showMessage('Filtros aplicados.');
  }

  Future<void> _handleObservationAction(Observation observation) async {
    try {
      await widget.repository.registerObservationAction(
        observationId: observation.id,
        actionType: observation.actionType,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_cleanErrorMessage(error));
    }

    switch (observation.actionType) {
      case ObservationActionType.uploadSupport:
        _showMessage('Modulo de soportes listo para conectar.');
      case ObservationActionType.viewDetail:
        _showObservationDetail(observation);
      case ObservationActionType.contactSupport:
        _showMessage('Solicitud enviada al equipo de bienestar.');
      case ObservationActionType.none:
        _showObservationDetail(observation);
    }
  }

  void _showObservationDetail(Observation observation) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => _ObservationDetailSheet(
        observation: observation,
        onActionPressed: () {
          Navigator.of(context).pop();
          _handleObservationAction(observation);
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ObservationColors.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _ObservationColors.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _wideBreakpoint;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 20,
                22,
                isWide ? 32 : 20,
                isWide ? 32 : 112,
              ),
              child: FutureBuilder<ObservationDashboard>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _ObservationLoading();
                  }

                  if (snapshot.hasError) {
                    final message = _cleanErrorMessage(snapshot.error);
                    return _ObservationError(
                      message: message,
                      isAccessDenied: _isAccessDeniedMessage(message),
                      onRetry: _reload,
                    );
                  }

                  final dashboard = snapshot.data;
                  if (dashboard == null) {
                    return _ObservationError(
                      message:
                          'No se recibieron datos de observaciones desde el backend.',
                      onRetry: _reload,
                    );
                  }

                  return _ObservationContent(
                    dashboard: dashboard,
                    observations: _filterObservations(dashboard.observations),
                    selectedType: _selectedType,
                    selectedSeverity: _selectedSeverity,
                    selectedStatus: _selectedStatus,
                    fromDate: _fromDate,
                    toDate: _toDate,
                    onTypeChanged: (value) {
                      setState(() => _selectedType = value);
                    },
                    onSeverityChanged: (value) {
                      setState(() => _selectedSeverity = value);
                    },
                    onStatusChanged: (value) {
                      setState(() => _selectedStatus = value);
                    },
                    onPickFromDate: () => _pickDate(isFrom: true),
                    onPickToDate: () => _pickDate(isFrom: false),
                    onApplyFilters: _applyFilters,
                    onClearFilters: _clearFilters,
                    onObservationTap: _showObservationDetail,
                    onActionPressed: _handleObservationAction,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ObservationContent extends StatelessWidget {
  const _ObservationContent({
    required this.dashboard,
    required this.observations,
    required this.selectedType,
    required this.selectedSeverity,
    required this.selectedStatus,
    required this.fromDate,
    required this.toDate,
    required this.onTypeChanged,
    required this.onSeverityChanged,
    required this.onStatusChanged,
    required this.onPickFromDate,
    required this.onPickToDate,
    required this.onApplyFilters,
    required this.onClearFilters,
    required this.onObservationTap,
    required this.onActionPressed,
  });

  final ObservationDashboard dashboard;
  final List<Observation> observations;
  final String selectedType;
  final String selectedSeverity;
  final String selectedStatus;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onPickFromDate;
  final VoidCallback onPickToDate;
  final VoidCallback onApplyFilters;
  final VoidCallback onClearFilters;
  final ValueChanged<Observation> onObservationTap;
  final ValueChanged<Observation> onActionPressed;

  @override
  Widget build(BuildContext context) {
    final total = dashboard.observations.length;
    final open = dashboard.observations.where(_isOpenObservation).length;
    final typeOptions = _optionList(
      dashboard.observations.map((observation) => observation.typeLabel),
    );
    final severityOptions = _optionList(
      dashboard.observations.map(
        (observation) => _severityLabel(observation.severity),
      ),
    );
    final statusOptions = _optionList(
      dashboard.observations.map((observation) => observation.statusLabel),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ObservationHeader(apprenticeName: dashboard.apprenticeName),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _CountPill(label: 'Total', value: total.toString()),
            _CountPill(
              label: 'Abiertas',
              value: open.toString(),
              highlight: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ObservationFilterCard(
          typeOptions: typeOptions,
          severityOptions: severityOptions,
          statusOptions: statusOptions,
          selectedType: _safeSelected(selectedType, typeOptions),
          selectedSeverity: _safeSelected(selectedSeverity, severityOptions),
          selectedStatus: _safeSelected(selectedStatus, statusOptions),
          fromDate: fromDate,
          toDate: toDate,
          onTypeChanged: onTypeChanged,
          onSeverityChanged: onSeverityChanged,
          onStatusChanged: onStatusChanged,
          onPickFromDate: onPickFromDate,
          onPickToDate: onPickToDate,
          onApplyFilters: onApplyFilters,
          onClearFilters: onClearFilters,
        ),
        const SizedBox(height: 16),
        _ObservationListPanel(
          total: total,
          observations: observations,
          onObservationTap: onObservationTap,
          onActionPressed: onActionPressed,
        ),
      ],
    );
  }
}

class _ObservationHeader extends StatelessWidget {
  const _ObservationHeader({required this.apprenticeName});

  final String apprenticeName;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis observaciones',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _ObservationColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Seguimiento registrado para $apprenticeName',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _ObservationColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const _HeaderBadge(label: 'Aprendiz'),
      ],
    );
  }
}

class _ObservationFilterCard extends StatelessWidget {
  const _ObservationFilterCard({
    required this.typeOptions,
    required this.severityOptions,
    required this.statusOptions,
    required this.selectedType,
    required this.selectedSeverity,
    required this.selectedStatus,
    required this.fromDate,
    required this.toDate,
    required this.onTypeChanged,
    required this.onSeverityChanged,
    required this.onStatusChanged,
    required this.onPickFromDate,
    required this.onPickToDate,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  final List<String> typeOptions;
  final List<String> severityOptions;
  final List<String> statusOptions;
  final String selectedType;
  final String selectedSeverity;
  final String selectedStatus;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onPickFromDate;
  final VoidCallback onPickToDate;
  final VoidCallback onApplyFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Filtros de consulta',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final maxWidth = constraints.maxWidth;
              late final double fieldWidth;
              late final double buttonWidth;

              if (maxWidth >= 1040) {
                fieldWidth = (maxWidth - spacing * 6) / 7;
                buttonWidth = fieldWidth;
              } else if (maxWidth >= 720) {
                fieldWidth = (maxWidth - spacing * 2) / 3;
                buttonWidth = (maxWidth - spacing) / 2;
              } else if (maxWidth >= 480) {
                fieldWidth = (maxWidth - spacing) / 2;
                buttonWidth = fieldWidth;
              } else {
                fieldWidth = maxWidth;
                buttonWidth = maxWidth;
              }

              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: _DropdownFilterField(
                      label: 'Tipo',
                      value: selectedType,
                      options: typeOptions,
                      onChanged: onTypeChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _DropdownFilterField(
                      label: 'Severidad',
                      value: selectedSeverity,
                      options: severityOptions,
                      onChanged: onSeverityChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _DropdownFilterField(
                      label: 'Estado',
                      value: selectedStatus,
                      options: statusOptions,
                      onChanged: onStatusChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _DateFilterField(
                      label: 'Desde',
                      value: fromDate,
                      onTap: onPickFromDate,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _DateFilterField(
                      label: 'Hasta',
                      value: toDate,
                      onTap: onPickToDate,
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: FilledButton.icon(
                      onPressed: onApplyFilters,
                      icon: const Icon(Icons.search_rounded, size: 17),
                      label: const Text('Buscar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _ObservationColors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(42),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: OutlinedButton(
                      onPressed: onClearFilters,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ObservationColors.navy,
                        minimumSize: const Size.fromHeight(42),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        side: const BorderSide(color: _ObservationColors.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Limpiar'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ObservationListPanel extends StatelessWidget {
  const _ObservationListPanel({
    required this.total,
    required this.observations,
    required this.onObservationTap,
    required this.onActionPressed,
  });

  final int total;
  final List<Observation> observations;
  final ValueChanged<Observation> onObservationTap;
  final ValueChanged<Observation> onActionPressed;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Observaciones registradas',
                  style: TextStyle(
                    color: _ObservationColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Mostrando ${observations.length} de $total observaciones',
                  style: const TextStyle(
                    color: _ObservationColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _ObservationColors.line),
          if (observations.isEmpty)
            const _EmptyObservationList()
          else if (isWide)
            _ObservationDataTable(
              observations: observations,
              onObservationTap: onObservationTap,
              onActionPressed: onActionPressed,
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var index = 0; index < observations.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == observations.length - 1 ? 0 : 12,
                      ),
                      child: _ObservationCard(
                        observation: observations[index],
                        onTap: () => onObservationTap(observations[index]),
                        onActionPressed: () =>
                            onActionPressed(observations[index]),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ObservationDataTable extends StatelessWidget {
  const _ObservationDataTable({
    required this.observations,
    required this.onObservationTap,
    required this.onActionPressed,
  });

  final List<Observation> observations;
  final ValueChanged<Observation> onObservationTap;
  final ValueChanged<Observation> onActionPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(_ObservationColors.tableHead),
        columnSpacing: 28,
        dataRowMinHeight: 64,
        dataRowMaxHeight: 84,
        columns: const [
          DataColumn(label: Text('Tipo')),
          DataColumn(label: Text('Severidad')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Descripcion')),
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Autor')),
          DataColumn(label: Text('Seguimiento')),
        ],
        rows: observations
            .map((observation) {
              return DataRow(
                onSelectChanged: (_) => onObservationTap(observation),
                cells: [
                  DataCell(Text(observation.typeLabel)),
                  DataCell(
                    _StatusBadge(
                      label: _severityLabel(observation.severity),
                      color: _severityColor(observation.severity),
                    ),
                  ),
                  DataCell(Text(observation.statusLabel)),
                  DataCell(
                    SizedBox(
                      width: 260,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            observation.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ObservationColors.navy,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            observation.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text(_formatDate(observation.date))),
                  DataCell(Text(observation.authorName)),
                  DataCell(
                    TextButton.icon(
                      onPressed: () => onActionPressed(observation),
                      icon: Icon(_actionIcon(observation.actionType), size: 17),
                      label: Text(observation.actionLabel),
                    ),
                  ),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({
    required this.observation,
    required this.onTap,
    required this.onActionPressed,
  });

  final Observation observation;
  final VoidCallback onTap;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(observation.severity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _ObservationColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ObservationIcon(
                    icon: _severityIcon(observation.severity),
                    color: severityColor,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          observation.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ObservationColors.navy,
                            fontSize: 15,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          observation.typeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ObservationColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                observation.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ObservationColors.muted,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusBadge(
                    label: _severityLabel(observation.severity),
                    color: severityColor,
                  ),
                  _MutedBadge(
                    icon: Icons.flag_outlined,
                    label: observation.statusLabel,
                  ),
                  _MutedBadge(
                    icon: Icons.calendar_today_outlined,
                    label: _formatDate(observation.date),
                  ),
                  _MutedBadge(
                    icon: Icons.person_outline_rounded,
                    label: observation.authorName,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onActionPressed,
                  icon: Icon(_actionIcon(observation.actionType), size: 17),
                  label: Text(observation.actionLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: _ObservationColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownFilterField extends StatelessWidget {
  const _DropdownFilterField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      style: const TextStyle(
        color: _ObservationColors.navy,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
      decoration: _inputDecoration(label),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: InputDecorator(
        decoration: _inputDecoration(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'dd/mm/aaaa' : _formatNumericDate(value!),
                style: TextStyle(
                  color: value == null
                      ? _ObservationColors.muted
                      : _ObservationColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              color: _ObservationColors.navy,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservationDetailSheet extends StatelessWidget {
  const _ObservationDetailSheet({
    required this.observation,
    required this.onActionPressed,
  });

  final Observation observation;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          2,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ObservationIcon(
                    icon: _severityIcon(observation.severity),
                    color: _severityColor(observation.severity),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          observation.title,
                          style: const TextStyle(
                            color: _ObservationColors.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${observation.typeLabel} - ${observation.area}',
                          style: const TextStyle(
                            color: _ObservationColors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        observation.description,
                        style: const TextStyle(
                          color: _ObservationColors.muted,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusBadge(
                            label: _severityLabel(observation.severity),
                            color: _severityColor(observation.severity),
                          ),
                          _MutedBadge(
                            icon: Icons.flag_outlined,
                            label: observation.statusLabel,
                          ),
                          _MutedBadge(
                            icon: Icons.calendar_today_outlined,
                            label: _formatDate(observation.date),
                          ),
                          _MutedBadge(
                            icon: Icons.person_outline_rounded,
                            label: observation.authorName,
                          ),
                          if (observation.dueDate != null)
                            _MutedBadge(
                              icon: Icons.schedule_outlined,
                              label:
                                  'Vence ${_formatDate(observation.dueDate!)}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (observation.actionType ==
                      ObservationActionType.uploadSupport ||
                  observation.actionType ==
                      ObservationActionType.contactSupport) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onActionPressed,
                    icon: Icon(_actionIcon(observation.actionType), size: 18),
                    label: Text(observation.actionLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: _ObservationColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlight
            ? _ObservationColors.green.withValues(alpha: 0.10)
            : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight
              ? _ObservationColors.green.withValues(alpha: 0.12)
              : _ObservationColors.line,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        child: Text(
          '$label: $value',
          style: TextStyle(
            color: highlight
                ? _ObservationColors.green
                : _ObservationColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ObservationColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _ObservationColors.navy, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ObservationColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ObservationIcon extends StatelessWidget {
  const _ObservationIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MutedBadge extends StatelessWidget {
  const _MutedBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ObservationColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _ObservationColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _ObservationColors.muted, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: _ObservationColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ObservationColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: _ObservationColors.green,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EmptyObservationList extends StatelessWidget {
  const _EmptyObservationList();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Text(
        'No hay observaciones registradas para este filtro.',
        style: TextStyle(
          color: _ObservationColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ObservationLoading extends StatelessWidget {
  const _ObservationLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBox(width: 230, height: 30),
        SizedBox(height: 10),
        _SkeletonBox(width: 300, height: 14),
        SizedBox(height: 18),
        _SkeletonBox(width: 190, height: 32),
        SizedBox(height: 16),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 170, height: 18),
              SizedBox(height: 16),
              _SkeletonBox(width: double.infinity, height: 48),
              SizedBox(height: 12),
              _SkeletonBox(width: double.infinity, height: 48),
            ],
          ),
        ),
      ],
    );
  }
}

class _ObservationError extends StatelessWidget {
  const _ObservationError({
    required this.onRetry,
    this.message = 'Revisa la conexion o intenta nuevamente.',
    this.isAccessDenied = false,
  });

  final VoidCallback onRetry;
  final String message;
  final bool isAccessDenied;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: isAccessDenied
          ? Icons.lock_outline_rounded
          : Icons.cloud_off_outlined,
      title: isAccessDenied
          ? 'Observaciones no disponibles'
          : 'No se pudieron cargar tus observaciones',
      message: message,
      actionLabel: 'Reintentar',
      onAction: onRetry,
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _ObservationColors.green, size: 32),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: _ObservationColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: _ObservationColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _ObservationColors.line,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    isDense: true,
    labelStyle: const TextStyle(
      color: _ObservationColors.navy,
      fontSize: 11,
      fontWeight: FontWeight.w800,
    ),
    floatingLabelStyle: const TextStyle(
      color: _ObservationColors.navy,
      fontSize: 11,
      fontWeight: FontWeight.w900,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    constraints: const BoxConstraints(minHeight: 42),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _ObservationColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _ObservationColors.green, width: 1.4),
    ),
  );
}

List<String> _optionList(Iterable<String> values) {
  final options =
      values
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  return [_allOption, ...options];
}

String _safeSelected(String selected, List<String> options) {
  return options.contains(selected) ? selected : _allOption;
}

bool _isOpenObservation(Observation observation) {
  return observation.severity != ObservationSeverity.closed;
}

Color _severityColor(ObservationSeverity severity) {
  return switch (severity) {
    ObservationSeverity.actionRequired => _ObservationColors.danger,
    ObservationSeverity.inProgress => _ObservationColors.amber,
    ObservationSeverity.informative => _ObservationColors.green,
    ObservationSeverity.closed => _ObservationColors.muted,
  };
}

IconData _severityIcon(ObservationSeverity severity) {
  return switch (severity) {
    ObservationSeverity.actionRequired => Icons.event_busy_outlined,
    ObservationSeverity.inProgress => Icons.assignment_outlined,
    ObservationSeverity.informative => Icons.health_and_safety_outlined,
    ObservationSeverity.closed => Icons.task_alt_rounded,
  };
}

String _severityLabel(ObservationSeverity severity) {
  return switch (severity) {
    ObservationSeverity.actionRequired => 'Alta',
    ObservationSeverity.inProgress => 'Media',
    ObservationSeverity.informative => 'Baja',
    ObservationSeverity.closed => 'Cerrada',
  };
}

IconData _actionIcon(ObservationActionType actionType) {
  return switch (actionType) {
    ObservationActionType.uploadSupport => Icons.upload_file_rounded,
    ObservationActionType.viewDetail => Icons.visibility_outlined,
    ObservationActionType.contactSupport => Icons.support_agent_rounded,
    ObservationActionType.none => Icons.arrow_forward_rounded,
  };
}

String _formatDate(DateTime date) {
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatNumericDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String _cleanErrorMessage(Object? error) {
  if (error == null) {
    return 'Revisa la conexion o intenta nuevamente.';
  }

  final rawMessage = error.toString();
  final message = rawMessage.startsWith('Exception: ')
      ? rawMessage.replaceFirst('Exception: ', '')
      : rawMessage;

  return message.trim().isEmpty
      ? 'Revisa la conexion o intenta nuevamente.'
      : message;
}

bool _isAccessDeniedMessage(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('acceso denegado') ||
      normalized.contains('no tienes permisos') ||
      normalized.contains('no autorizado') ||
      normalized.contains('forbidden');
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

abstract final class _ObservationColors {
  static const background = Color(0xFFF6F8FB);
  static const tableHead = Color(0xFFF3F6FA);
  static const navy = Color(0xFF062E4F);
  static const green = Color(0xFF39A900);
  static const muted = Color(0xFF6F7C8E);
  static const line = Color(0xFFE1E7EF);
  static const amber = Color(0xFFF5B400);
  static const danger = Color(0xFFE04444);
}

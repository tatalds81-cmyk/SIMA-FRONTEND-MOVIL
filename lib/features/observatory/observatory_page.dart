import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/observatory/data/observations_repository.dart';
import 'package:sima_movil_froned/features/observatory/models/observation.dart';

const _allOption = 'Todos';
const _wideBreakpoint = 760.0;

class ObservatoryPage extends StatefulWidget {
  const ObservatoryPage({
    super.key,
    this.repository = const BackendObservatoryRepository(),
  });

  final ObservatoryRepository repository;

  @override
  State<ObservatoryPage> createState() => _ObservatoryPageState();
}

class _ObservatoryPageState extends State<ObservatoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  ObservatoryFilters _observationFilters = const ObservatoryFilters();
  ObservatoryFilters _alertFilters = const ObservatoryFilters();

  late Future<ObservatoryObservationResponse> _observationsFuture;
  late Future<ObservatoryAlertResponse> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _observationsFuture = widget.repository.fetchObservations(
      _observationFilters,
    );
    _alertsFuture = widget.repository.fetchAlerts(_alertFilters);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reloadObservations() {
    setState(() {
      _observationsFuture = widget.repository.fetchObservations(
        _observationFilters,
      );
    });
  }

  void _reloadAlerts() {
    setState(() {
      _alertsFuture = widget.repository.fetchAlerts(_alertFilters);
    });
  }

  void _setObservationFilters(
    ObservatoryFilters filters, {
    bool reload = false,
  }) {
    setState(() {
      _observationFilters = filters;
      if (reload) {
        _observationsFuture = widget.repository.fetchObservations(
          _observationFilters,
        );
      }
    });
  }

  void _setAlertFilters(ObservatoryFilters filters, {bool reload = false}) {
    setState(() {
      _alertFilters = filters;
      if (reload) {
        _alertsFuture = widget.repository.fetchAlerts(_alertFilters);
      }
    });
  }

  Future<DateTime?> _pickDate(DateTime? current, DateTime? minimum) {
    return showDatePicker(
      context: context,
      initialDate: current ?? minimum ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _ObservatoryColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: _ObservatoryHeader(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TabSurface(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Observaciones'),
                  Tab(text: 'Alertas'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ObservationsTab(
                    future: _observationsFuture,
                    filters: _observationFilters,
                    onRetry: _reloadObservations,
                    onFiltersChanged: _setObservationFilters,
                    onPickDate: _pickDate,
                  ),
                  _AlertsTab(
                    future: _alertsFuture,
                    filters: _alertFilters,
                    onRetry: _reloadAlerts,
                    onFiltersChanged: _setAlertFilters,
                    onPickDate: _pickDate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservatoryHeader extends StatelessWidget {
  const _ObservatoryHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Observatorio',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ObservatoryColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Consulta tus observaciones y alertas de seguimiento.',
          style: TextStyle(
            color: _ObservatoryColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ObservationsTab extends StatelessWidget {
  const _ObservationsTab({
    required this.future,
    required this.filters,
    required this.onRetry,
    required this.onFiltersChanged,
    required this.onPickDate,
  });

  final Future<ObservatoryObservationResponse> future;
  final ObservatoryFilters filters;
  final VoidCallback onRetry;
  final void Function(ObservatoryFilters filters, {bool reload})
  onFiltersChanged;
  final Future<DateTime?> Function(DateTime? current, DateTime? minimum)
  onPickDate;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ObservatoryObservationResponse>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ObservatoryLoading();
        }
        if (snapshot.hasError) {
          return _ErrorPanel(
            message: _cleanErrorMessage(snapshot.error),
            onRetry: onRetry,
          );
        }

        final data =
            snapshot.data ??
            const ObservatoryObservationResponse(
              metrics: ObservatoryMetrics(
                total: 0,
                abiertas: 0,
                cerradas: 0,
                alta: 0,
                media: 0,
                baja: 0,
              ),
              items: [],
              message: 'No tienes observaciones por el momento',
            );

        return _ScrollableTabBody(
          children: [
            _MetricsGrid(
              title: 'Metricas de observaciones',
              totalLabel: 'Total de observaciones',
              metrics: data.metrics,
            ),
            const SizedBox(height: 14),
            _FilterableSectionCard(
              title: 'Observaciones registradas',
              subtitle: 'Mostrando ${data.items.length} observaciones',
              emptyMessage: 'No tienes observaciones por el momento.',
              isEmpty: data.items.isEmpty,
              filters: filters,
              onFiltersChanged: onFiltersChanged,
              onPickDate: onPickDate,
              child: Column(
                children: data.items
                    .map(
                      (item) => _RecordTile(
                        icon: Icons.assignment_outlined,
                        title: item.tipo,
                        subtitle: _shortText(item.descripcion),
                        date: _formatDate(item.fecha),
                        severity: item.severidad,
                        status: item.estado,
                        responsible: item.responsableNombre,
                        onTap: () => _showObservationDetail(context, item),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab({
    required this.future,
    required this.filters,
    required this.onRetry,
    required this.onFiltersChanged,
    required this.onPickDate,
  });

  final Future<ObservatoryAlertResponse> future;
  final ObservatoryFilters filters;
  final VoidCallback onRetry;
  final void Function(ObservatoryFilters filters, {bool reload})
  onFiltersChanged;
  final Future<DateTime?> Function(DateTime? current, DateTime? minimum)
  onPickDate;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ObservatoryAlertResponse>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ObservatoryLoading();
        }
        if (snapshot.hasError) {
          return _ErrorPanel(
            message: _cleanErrorMessage(snapshot.error),
            onRetry: onRetry,
          );
        }

        final data =
            snapshot.data ??
            const ObservatoryAlertResponse(
              metrics: ObservatoryMetrics(
                total: 0,
                abiertas: 0,
                cerradas: 0,
                alta: 0,
                media: 0,
                baja: 0,
              ),
              items: [],
              message: 'No tienes alertas por el momento',
            );

        return _ScrollableTabBody(
          children: [
            _MetricsGrid(
              title: 'Metricas de alertas',
              totalLabel: 'Total de alertas',
              metrics: data.metrics,
            ),
            const SizedBox(height: 14),
            _FilterableSectionCard(
              title: 'Alertas registradas',
              subtitle: 'Mostrando ${data.items.length} alertas',
              emptyMessage: 'No tienes alertas por el momento.',
              isEmpty: data.items.isEmpty,
              filters: filters,
              onFiltersChanged: onFiltersChanged,
              onPickDate: onPickDate,
              child: Column(
                children: data.items
                    .map(
                      (item) => _RecordTile(
                        icon: Icons.warning_amber_rounded,
                        title: item.tipo,
                        subtitle: _shortText(item.descripcion),
                        date: _formatDate(item.fechaAlerta),
                        severity: item.severidad,
                        status: item.estado,
                        responsible: item.responsableNombre,
                        onTap: () => _showAlertDetail(context, item),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScrollableTabBody extends StatelessWidget {
  const _ScrollableTabBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isWide ? 32 : 20, 6, isWide ? 32 : 20, 128),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TabSurface extends StatelessWidget {
  const _TabSurface({required this.controller, required this.tabs});

  final TabController controller;
  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        tabs: tabs,
        indicatorColor: _ObservatoryColors.green,
        labelColor: _ObservatoryColors.green,
        unselectedLabelColor: _ObservatoryColors.muted,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.title,
    required this.totalLabel,
    required this.metrics,
  });

  final String title;
  final String totalLabel;
  final ObservatoryMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.insights_rounded, title: title),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _MetricPill(label: totalLabel, value: metrics.total),
              _MetricPill(label: 'Abiertas', value: metrics.abiertas),
              _MetricPill(label: 'Cerradas', value: metrics.cerradas),
              _MetricPill(label: 'Alta', value: metrics.alta),
              _MetricPill(label: 'Media', value: metrics.media),
              _MetricPill(label: 'Baja', value: metrics.baja),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ObservatoryColors.green.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _ObservatoryColors.green.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Text(
          '$label: $value',
          style: const TextStyle(
            color: _ObservatoryColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FilterableSectionCard extends StatefulWidget {
  const _FilterableSectionCard({
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
    required this.isEmpty,
    required this.filters,
    required this.onFiltersChanged,
    required this.onPickDate,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String emptyMessage;
  final bool isEmpty;
  final ObservatoryFilters filters;
  final void Function(ObservatoryFilters filters, {bool reload})
  onFiltersChanged;
  final Future<DateTime?> Function(DateTime? current, DateTime? minimum)
  onPickDate;
  final Widget child;

  @override
  State<_FilterableSectionCard> createState() => _FilterableSectionCardState();
}

class _FilterableSectionCardState extends State<_FilterableSectionCard> {
  late final TextEditingController _typeController;
  bool _isExpanded = false;
  _FilterSection _activeSection = _FilterSection.dates;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.filters.tipo ?? '');
  }

  @override
  void didUpdateWidget(covariant _FilterableSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.filters.tipo ?? '';
    if (_typeController.text != value) {
      _typeController.text = value;
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toggleButton = _FilterToggleButton(
      activeCount: _activeFilterCount(widget.filters),
      isExpanded: _isExpanded,
      onPressed: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
    );

    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: _ObservatoryColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: _ObservatoryColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                toggleButton,
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _buildFilterPanel(),
            ),
          const Divider(height: 1, color: _ObservatoryColors.line),
          if (widget.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                widget.emptyMessage,
                style: const TextStyle(
                  color: _ObservatoryColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Padding(padding: const EdgeInsets.all(12), child: widget.child),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _ObservatoryColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ObservatoryColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterOptionButton(
                icon: Icons.date_range_rounded,
                label: 'Fecha',
                value: _dateFilterLabel(widget.filters),
                isSelected: _activeSection == _FilterSection.dates,
                onTap: () {
                  setState(() {
                    _activeSection = _FilterSection.dates;
                  });
                },
              ),
              _FilterOptionButton(
                icon: Icons.priority_high_rounded,
                label: 'Severidad',
                value: widget.filters.severidad ?? _allOption,
                isSelected: _activeSection == _FilterSection.severity,
                onTap: () {
                  setState(() {
                    _activeSection = _FilterSection.severity;
                  });
                },
              ),
              _FilterOptionButton(
                icon: Icons.task_alt_rounded,
                label: 'Estado',
                value: widget.filters.estado ?? _allOption,
                isSelected: _activeSection == _FilterSection.status,
                onTap: () {
                  setState(() {
                    _activeSection = _FilterSection.status;
                  });
                },
              ),
              _FilterOptionButton(
                icon: Icons.category_outlined,
                label: 'Tipo',
                value: _hasFilterText(widget.filters.tipo)
                    ? widget.filters.tipo!.trim()
                    : _allOption,
                isSelected: _activeSection == _FilterSection.type,
                onTap: () {
                  setState(() {
                    _activeSection = _FilterSection.type;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActiveFilterControl(),
          const SizedBox(height: 12),
          _FilterActions(
            onSearch: () => widget.onFiltersChanged(
              _typeController.text.trim().isEmpty
                  ? widget.filters.copyWith(clearTipo: true)
                  : widget.filters.copyWith(tipo: _typeController.text),
              reload: true,
            ),
            onClear: () {
              _typeController.clear();
              widget.onFiltersChanged(const ObservatoryFilters(), reload: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterControl() {
    return switch (_activeSection) {
      _FilterSection.dates => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _FilterChipButton(
            label: 'Desde',
            value: widget.filters.fechaDesde == null
                ? _allOption
                : _formatDate(widget.filters.fechaDesde!),
            onTap: () async {
              final date = await widget.onPickDate(
                widget.filters.fechaDesde,
                null,
              );
              if (date != null) {
                widget.onFiltersChanged(
                  widget.filters.copyWith(fechaDesde: date),
                );
              }
            },
          ),
          _FilterChipButton(
            label: 'Hasta',
            value: widget.filters.fechaHasta == null
                ? _allOption
                : _formatDate(widget.filters.fechaHasta!),
            onTap: () async {
              final date = await widget.onPickDate(
                widget.filters.fechaHasta,
                widget.filters.fechaDesde,
              );
              if (date != null) {
                final from = widget.filters.fechaDesde;
                widget.onFiltersChanged(
                  widget.filters.copyWith(
                    fechaHasta: from != null && date.isBefore(from)
                        ? from
                        : date,
                  ),
                );
              }
            },
          ),
        ],
      ),
      _FilterSection.severity => _DropdownFilter(
        label: 'Severidad',
        value: widget.filters.severidad ?? _allOption,
        width: 220,
        options: const [_allOption, 'LEVE', 'MODERADA', 'GRAVE', 'CRITICA'],
        onChanged: (value) {
          widget.onFiltersChanged(
            value == _allOption
                ? widget.filters.copyWith(clearSeveridad: true)
                : widget.filters.copyWith(severidad: value),
          );
        },
      ),
      _FilterSection.status => _DropdownFilter(
        label: 'Estado',
        value: widget.filters.estado ?? _allOption,
        width: 220,
        options: const [_allOption, 'ABIERTA', 'CERRADA'],
        onChanged: (value) {
          widget.onFiltersChanged(
            value == _allOption
                ? widget.filters.copyWith(clearEstado: true)
                : widget.filters.copyWith(estado: value),
          );
        },
      ),
      _FilterSection.type => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: TextField(
          controller: _typeController,
          decoration: _inputDecoration('Tipo'),
          onChanged: (value) {
            widget.onFiltersChanged(
              value.trim().isEmpty
                  ? widget.filters.copyWith(clearTipo: true)
                  : widget.filters.copyWith(tipo: value),
            );
          },
        ),
      ),
    };
  }
}

enum _FilterSection { dates, severity, status, type }

class _FilterToggleButton extends StatelessWidget {
  const _FilterToggleButton({
    required this.activeCount,
    required this.isExpanded,
    required this.onPressed,
  });

  final int activeCount;
  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isExpanded ? 'Ocultar filtros' : 'Mostrar filtros',
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: isExpanded
              ? _ObservatoryColors.green.withValues(alpha: 0.11)
              : _ObservatoryColors.background,
          foregroundColor: isExpanded
              ? _ObservatoryColors.green
              : _ObservatoryColors.navy,
          side: const BorderSide(color: _ObservatoryColors.line),
          fixedSize: const Size.square(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isExpanded
                  ? Icons.filter_alt_off_rounded
                  : Icons.filter_alt_rounded,
              size: 22,
            ),
            if (activeCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: _FilterCountBadge(count: activeCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterCountBadge extends StatelessWidget {
  const _FilterCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _ObservatoryColors.green,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FilterOptionButton extends StatelessWidget {
  const _FilterOptionButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? _ObservatoryColors.green.withValues(alpha: 0.09)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? _ObservatoryColors.green
                : _ObservatoryColors.line,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? _ObservatoryColors.green
                  : _ObservatoryColors.navy,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ObservatoryColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? _ObservatoryColors.green
                          : _ObservatoryColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterActions extends StatelessWidget {
  const _FilterActions({required this.onSearch, required this.onClear});

  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchButton(),
              const SizedBox(height: 8),
              _buildClearButton(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildSearchButton()),
            const SizedBox(width: 10),
            Expanded(child: _buildClearButton()),
          ],
        );
      },
    );
  }

  Widget _buildSearchButton() {
    return FilledButton.icon(
      onPressed: onSearch,
      icon: const Icon(Icons.search_rounded, size: 18),
      label: const Text('Buscar'),
      style: FilledButton.styleFrom(
        backgroundColor: _ObservatoryColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildClearButton() {
    return OutlinedButton(
      onPressed: onClear,
      style: OutlinedButton.styleFrom(
        foregroundColor: _ObservatoryColors.navy,
        minimumSize: const Size.fromHeight(44),
        side: const BorderSide(color: _ObservatoryColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Limpiar'),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: _ObservatoryColors.line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _ObservatoryColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ObservatoryColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              size: 17,
              color: _ObservatoryColors.navy,
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.width = 150,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(value) ? value : _allOption,
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
        decoration: _inputDecoration(label),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.severity,
    required this.status,
    required this.responsible,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String date;
  final String severity;
  final String status;
  final String responsible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _ObservatoryColors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ObservatoryColors.navy,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _Badge(label: status, color: _statusColor(status)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ObservatoryColors.muted,
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MutedBadge(icon: Icons.calendar_today, label: date),
                          _Badge(label: severity, color: color),
                          _MutedBadge(
                            icon: Icons.person_outline,
                            label: responsible,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showObservationDetail(BuildContext context, ObservatoryObservation item) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _DetailSheet(
      title: item.tipo,
      subtitle: 'Observacion',
      rows: [
        _DetailRow('Fecha', _formatDate(item.fecha)),
        _DetailRow('Tipo', item.tipo),
        _DetailRow('Severidad', item.severidad),
        _DetailRow('Estado', item.estado),
        _DetailRow('Responsable', item.responsableNombre),
        _DetailRow('Rol responsable', item.responsableRol),
        _DetailRow('Descripcion', item.descripcion),
      ],
    ),
  );
}

void _showAlertDetail(BuildContext context, ObservatoryAlert item) {
  final rows = [
    _DetailRow('Fecha de alerta', _formatDate(item.fechaAlerta)),
    _DetailRow('Tipo', item.tipo),
    _DetailRow('Severidad', item.severidad),
    _DetailRow('Estado', item.estado),
    _DetailRow('Origen', item.origen),
    _DetailRow('Regla de disparo', item.reglaDisparo),
    _DetailRow('Responsable creador', item.responsableNombre),
    _DetailRow('Rol responsable', item.responsableRol),
    _DetailRow('Descripcion', item.descripcion),
  ];

  if (item.fechaCierre != null || item.justificacionCierre.isNotEmpty) {
    rows.add(
      _DetailRow('Fecha de cierre', _formatOptionalDate(item.fechaCierre)),
    );
    rows.add(_DetailRow('Justificacion de cierre', item.justificacionCierre));
    rows.add(_DetailRow('Responsable cierre', item.responsableCierreNombre));
    rows.add(_DetailRow('Rol cierre', item.responsableCierreRol));
  }

  if (item.fechaReapertura != null || item.justificacionReapertura.isNotEmpty) {
    rows.add(
      _DetailRow(
        'Fecha de reapertura',
        _formatOptionalDate(item.fechaReapertura),
      ),
    );
    rows.add(
      _DetailRow('Justificacion de reapertura', item.justificacionReapertura),
    );
    rows.add(
      _DetailRow('Responsable reapertura', item.responsableReaperturaNombre),
    );
    rows.add(_DetailRow('Rol reapertura', item.responsableReaperturaRol));
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) =>
        _DetailSheet(title: item.tipo, subtitle: 'Alerta', rows: rows),
  );
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          0,
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _ObservatoryColors.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$subtitle - Solo lectura',
                          style: const TextStyle(
                            color: _ObservatoryColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: rows
                        .where((row) => row.value.trim().isNotEmpty)
                        .map(
                          (row) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReadOnlyField(
                              label: row.label,
                              value: row.value,
                            ),
                          ),
                        )
                        .toList(growable: false),
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

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _ObservatoryColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _ObservatoryColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _ObservatoryColors.line),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: _ObservatoryColors.navy,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
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
        border: Border.all(color: _ObservatoryColors.line),
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
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _ObservatoryColors.navy, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ObservatoryColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
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
        color: _ObservatoryColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _ObservatoryColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _ObservatoryColors.muted, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: _ObservatoryColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservatoryLoading extends StatelessWidget {
  const _ObservatoryLoading();

  @override
  Widget build(BuildContext context) {
    return const _ScrollableTabBody(
      children: [
        _SkeletonBox(width: 210, height: 26),
        SizedBox(height: 12),
        _SkeletonBox(width: double.infinity, height: 110),
        SizedBox(height: 14),
        _SkeletonBox(width: double.infinity, height: 150),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ScrollableTabBody(
      children: [
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: _ObservatoryColors.green,
                size: 32,
              ),
              const SizedBox(height: 12),
              const Text(
                'No se pudo cargar el observatorio',
                style: TextStyle(
                  color: _ObservatoryColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: const TextStyle(
                  color: _ObservatoryColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ],
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
        color: _ObservatoryColors.line,
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
      color: _ObservatoryColors.navy,
      fontSize: 11,
      fontWeight: FontWeight.w800,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _ObservatoryColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _ObservatoryColors.green, width: 1.4),
    ),
  );
}

Color _severityColor(String severity) {
  return switch (severity.toUpperCase()) {
    'CRITICA' || 'GRAVE' => _ObservatoryColors.danger,
    'MODERADA' => _ObservatoryColors.amber,
    'LEVE' => _ObservatoryColors.green,
    _ => _ObservatoryColors.muted,
  };
}

Color _statusColor(String status) {
  return status.toUpperCase() == 'CERRADA'
      ? _ObservatoryColors.muted
      : _ObservatoryColors.green;
}

String _shortText(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return 'Sin descripcion registrada';
  }
  return text;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatOptionalDate(DateTime? date) {
  return date == null ? '' : _formatDate(date);
}

int _activeFilterCount(ObservatoryFilters filters) {
  var count = 0;
  if (filters.fechaDesde != null) count++;
  if (filters.fechaHasta != null) count++;
  if (_hasFilterText(filters.severidad)) count++;
  if (_hasFilterText(filters.estado)) count++;
  if (_hasFilterText(filters.tipo)) count++;
  return count;
}

bool _hasFilterText(String? value) {
  return value != null && value.trim().isNotEmpty;
}

String _dateFilterLabel(ObservatoryFilters filters) {
  final from = filters.fechaDesde;
  final to = filters.fechaHasta;

  if (from == null && to == null) {
    return _allOption;
  }
  if (from != null && to != null) {
    return '${_formatDate(from)} - ${_formatDate(to)}';
  }
  if (from != null) {
    return 'Desde ${_formatDate(from)}';
  }
  return 'Hasta ${_formatDate(to!)}';
}

String _cleanErrorMessage(Object? error) {
  if (error == null) {
    return 'Revisa la conexion o intenta nuevamente.';
  }
  final raw = error.toString();
  final message = raw.startsWith('Exception: ')
      ? raw.replaceFirst('Exception: ', '')
      : raw;
  return message.trim().isEmpty
      ? 'Revisa la conexion o intenta nuevamente.'
      : message;
}

abstract final class _ObservatoryColors {
  static const background = Color(0xFFF6F8FB);
  static const navy = Color(0xFF062E4F);
  static const green = Color(0xFF39A900);
  static const muted = Color(0xFF6F7C8E);
  static const line = Color(0xFFE1E7EF);
  static const amber = Color(0xFFF5B400);
  static const danger = Color(0xFFE04444);
}

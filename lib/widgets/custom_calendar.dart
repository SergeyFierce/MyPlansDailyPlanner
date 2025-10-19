import 'package:flutter/material.dart';

class CustomCalendar extends StatefulWidget {
  const CustomCalendar({
    super.key,
    required this.selected,
    required this.today,
    required this.onSelect,
    required this.importantDates,
  });

  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;
  final List<DateTime> importantDates;

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar>
    with TickerProviderStateMixin {
  static const int _baseYear = 2000;
  static const int _lastYear = 2100;
  static const double _yearItemExtent = 44.0;

  late DateTime _currentMonth;
  late final PageController _pageController;
  late final ScrollController _yearScrollController;

  final List<String> _weekDays = const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  bool _showMonthSelection = false;
  bool _showYearSelection = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.today.year, widget.today.month);
    _pageController = PageController(initialPage: _monthToPage(_currentMonth));
    _yearScrollController = ScrollController(
      initialScrollOffset: _yearToOffset(_currentMonth.year),
    );
  }

  @override
  void didUpdateWidget(CustomCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected.month != widget.selected.month ||
        oldWidget.selected.year != widget.selected.year) {
      final newMonth = DateTime(widget.selected.year, widget.selected.month);
      if (!_isSameMonth(newMonth, _currentMonth)) {
        _animateToMonth(newMonth);
      } else {
        _currentMonth = newMonth;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _yearScrollController.dispose();
    super.dispose();
  }

  int _monthToPage(DateTime month) {
    return (month.year - _baseYear) * 12 + (month.month - 1);
  }

  double _yearToOffset(int year) {
    return (year - _baseYear) * _yearItemExtent;
  }

  DateTime _pageToMonth(int page) {
    final year = _baseYear + page ~/ 12;
    final month = page % 12 + 1;
    return DateTime(year, month);
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  List<DateTime> _getMonthDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final days = <DateTime>[];
    for (var i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }

    final firstWeekday = (firstDay.weekday + 6) % 7;
    for (var i = 0; i < firstWeekday; i++) {
      days.insert(0, firstDay.subtract(Duration(days: i + 1)));
    }

    while (days.length % 7 != 0) {
      days.add(days.last.add(const Duration(days: 1)));
    }

    return days;
  }

  void _previousMonth() {
    final previousMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    _animateToMonth(previousMonth);
  }

  void _nextMonth() {
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    _animateToMonth(nextMonth);
  }

  bool _isImportantDate(DateTime date) {
    return widget.importantDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _animateToMonth(DateTime month) {
    if (month.year < _baseYear || month.year > _lastYear) {
      return;
    }

    final targetPage = _monthToPage(month);
    setState(() {
      _currentMonth = DateTime(month.year, month.month);
      _showMonthSelection = false;
      _showYearSelection = false;
    });

    if ((_pageController.hasClients)) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _isToday(DateTime date) {
    return date.year == widget.today.year &&
        date.month == widget.today.month &&
        date.day == widget.today.day;
  }

  void _toggleMonthSelection() {
    setState(() {
      if (_showMonthSelection) {
        _showMonthSelection = false;
      } else {
        _showMonthSelection = true;
        _showYearSelection = false;
      }
    });
  }

  void _toggleYearSelection() {
    setState(() {
      if (_showYearSelection) {
        _showYearSelection = false;
      } else {
        _showYearSelection = true;
        _showMonthSelection = false;
      }
    });

    if (_showYearSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _yearToOffset(_currentMonth.year);
        if (_yearScrollController.hasClients) {
          final min = _yearScrollController.position.minScrollExtent;
          final max = _yearScrollController.position.maxScrollExtent;
          final offset = target.clamp(min, max);
          _yearScrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _selectMonth(int month) {
    _animateToMonth(DateTime(_currentMonth.year, month));
  }

  void _selectYear(int year) {
    _animateToMonth(DateTime(year, _currentMonth.month));
  }

  Widget _buildSelectorChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final Color activeColor = const Color(0xFF4F46E5);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEEF2FF) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? activeColor : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isActive ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: isActive ? activeColor : Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelection() {
    const monthLabels = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь'
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = (constraints.maxWidth - 16) / 3;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выбор месяца',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (index) {
                  final month = index + 1;
                  final isSelected = month == _currentMonth.month;
                  final isTodayMonth =
                      month == widget.today.month && _currentMonth.year == widget.today.year;

                  return SizedBox(
                    width: itemWidth,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectMonth(month),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isTodayMonth
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent,
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              monthLabels[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF1D4ED8)
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildYearSelection() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выбор года',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 196,
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                controller: _yearScrollController,
                itemExtent: _yearItemExtent,
                itemCount: _lastYear - _baseYear + 1,
                itemBuilder: (context, index) {
                  final year = _baseYear + index;
                  final isSelected = year == _currentMonth.year;
                  final isTodayYear = year == widget.today.year;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectYear(year),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isTodayYear
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent,
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$year',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF1D4ED8)
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPanel() {
    if (_showMonthSelection) {
      return _buildMonthSelection();
    }
    if (_showYearSelection) {
      return _buildYearSelection();
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь'
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth / 7;
        final gridHeight = cellSize * 6 - 32;

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Выберите месяц или год',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSelectorChip(
                            label: monthNames[_currentMonth.month - 1],
                            isActive: _showMonthSelection,
                            onTap: _toggleMonthSelection,
                          ),
                          _buildSelectorChip(
                            label: '${_currentMonth.year}',
                            isActive: _showYearSelection,
                            onTap: _toggleYearSelection,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              vsync: this,
              child: _buildSelectionPanel(),
            ),
            const SizedBox(height: 12),
            Row(
              children: _weekDays
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: gridHeight,
              child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentMonth = _pageToMonth(index);
                    _showMonthSelection = false;
                    _showYearSelection = false;
                  });
                },
                itemBuilder: (context, index) {
                  final month = _pageToMonth(index);
                  final days = _getMonthDays(month);
                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1,
                    ),
                    itemCount: days.length,
                    itemBuilder: (context, dayIndex) {
                      final date = days[dayIndex];
                      final isCurrentMonth = date.month == month.month;
                      final isSelected = _isSameDay(date, widget.selected);
                      final isImportant = _isImportantDate(date);
                      final isToday = _isToday(date);

                      Color textColor = isCurrentMonth ? Colors.black : Colors.grey;
                      FontWeight fontWeight = FontWeight.normal;
                      if (isToday) {
                        textColor = const Color(0xFF1D4ED8);
                        fontWeight = FontWeight.w600;
                      } else if (isSelected) {
                        textColor = const Color(0xFF4F46E5);
                        fontWeight = FontWeight.w600;
                      } else if (isImportant) {
                        fontWeight = FontWeight.w600;
                      }

                      final BoxDecoration decoration;
                      if (isToday) {
                        decoration = BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(12),
                        );
                      } else if (isSelected) {
                        decoration = BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4F46E5)),
                        );
                      } else {
                        decoration = BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            widget.onSelect(date);
                            if (!isCurrentMonth) {
                              _animateToMonth(DateTime(date.year, date.month));
                            }
                          },
                          child: Container(
                            decoration: decoration,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '${date.day}',
                                  style: TextStyle(color: textColor, fontWeight: fontWeight),
                                ),
                                if (isImportant)
                                  Positioned(
                                    right: 6,
                                    bottom: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDC2626),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                itemCount: (_lastYear - _baseYear + 1) * 12,
              ),
            ),
          ],
        );
      },
    );
  }
}

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

class _CustomCalendarState extends State<CustomCalendar> {
  static const int _baseYear = 2000;
  static const int _lastYear = 2100;

  late DateTime _currentMonth;
  late final PageController _pageController;

  final List<String> _weekDays = const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.today.year, widget.today.month);
    _pageController = PageController(initialPage: _monthToPage(_currentMonth));
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
    super.dispose();
  }

  int _monthToPage(DateTime month) {
    return (month.year - _baseYear) * 12 + (month.month - 1);
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
    });

    if ((_pageController.hasClients)) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleMonthYearTap() async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        int tempYear = _currentMonth.year;
        return StatefulBuilder(
          builder: (context, setModalState) {
            const monthLabels = [
              'Янв',
              'Фев',
              'Мар',
              'Апр',
              'Май',
              'Июн',
              'Июл',
              'Авг',
              'Сен',
              'Окт',
              'Ноя',
              'Дек'
            ];

            return AlertDialog(
              title: const Text('Выберите месяц и год'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 180,
                      child: YearPicker(
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDate: DateTime(tempYear),
                        selectedDate: DateTime(tempYear),
                        onChanged: (date) {
                          setModalState(() => tempYear = date.year);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(monthLabels.length, (index) {
                        final month = index + 1;
                        final isSelected =
                            month == _currentMonth.month && tempYear == _currentMonth.year;
                        final isTodayMonth =
                            month == widget.today.month && tempYear == widget.today.year;
                        return ChoiceChip(
                          label: Text(monthLabels[index]),
                          selected: isSelected,
                          selectedColor: const Color(0xFFEEF2FF),
                          onSelected: (_) {
                            Navigator.of(context).pop(DateTime(tempYear, month));
                          },
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isTodayMonth ? const Color(0xFF4F46E5) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF1D4ED8) : null,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      _animateToMonth(selected);
    }
  }

  bool _isToday(DateTime date) {
    return date.year == widget.today.year &&
        date.month == widget.today.month &&
        date.day == widget.today.day;
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
        final gridHeight = cellSize * 6;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _handleMonthYearTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
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
                        padding: const EdgeInsets.all(4),
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

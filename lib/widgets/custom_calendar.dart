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
  late DateTime _currentMonth;
  final List<String> _weekDays = const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.today.year, widget.today.month);
  }

  @override
  void didUpdateWidget(CustomCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected.month != widget.selected.month ||
        oldWidget.selected.year != widget.selected.year) {
      _currentMonth = DateTime(widget.selected.year, widget.selected.month);
    }
  }

  List<DateTime> _getMonthDays() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    final days = <DateTime>[];
    for (var i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
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
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  bool _isImportantDate(DateTime date) {
    return widget.importantDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
                        return ChoiceChip(
                          label: Text(monthLabels[index]),
                          selected: isSelected,
                          onSelected: (_) {
                            Navigator.of(context).pop(DateTime(tempYear, month));
                          },
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
      setState(() {
        _currentMonth = DateTime(selected.year, selected.month);
      });

      final currentSelectedDay = widget.selected.day;
      final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;
      final newDay = currentSelectedDay.clamp(1, daysInMonth).toInt();
      widget.onSelect(DateTime(selected.year, selected.month, newDay));
    }
  }

  void _handleHorizontalDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 0) {
      _previousMonth();
    } else if (velocity < 0) {
      _nextMonth();
    }
  }

  bool _isToday(DateTime date) {
    return date.year == widget.today.year &&
        date.month == widget.today.month &&
        date.day == widget.today.day;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getMonthDays();
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

    return GestureDetector(
      onHorizontalDragEnd: _handleHorizontalDrag,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: _previousMonth, icon: const Icon(Icons.chevron_left)),
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
              IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
            ],
          ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: _weekDays.length,
          itemBuilder: (context, index) {
            return Center(
              child: Text(
                _weekDays[index],
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            );
          },
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final date = days[index];
            final isCurrentMonth = date.month == _currentMonth.month;
            final isSelected = _isSameDay(date, widget.selected);
            final isImportant = _isImportantDate(date);
            final isToday = _isToday(date);

            Color textColor = isCurrentMonth ? Colors.black : Colors.grey;
            FontWeight fontWeight = FontWeight.normal;
            if (isSelected) {
              textColor = Colors.white;
              fontWeight = FontWeight.bold;
            } else if (isImportant) {
              fontWeight = FontWeight.bold;
            } else if (isToday) {
              fontWeight = FontWeight.w600;
            }

            final decoration = isSelected
                ? BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(12),
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isToday
                        ? Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3))
                        : null,
                  );

            return Padding(
              padding: const EdgeInsets.all(4),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => widget.onSelect(date),
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
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xFFDC2626),
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
        ),
      ],
    );
  }
}

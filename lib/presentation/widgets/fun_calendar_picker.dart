import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FunCalendarPicker extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime) onDateSelected;
  final Function(DateTime, DateTime)? onRangeSelected;

  const FunCalendarPicker({
    super.key,
    this.selectedDate,
    this.startDate,
    this.endDate,
    required this.onDateSelected,
    this.onRangeSelected,
  });

  @override
  State<FunCalendarPicker> createState() => _FunCalendarPickerState();
}

class _FunCalendarPickerState extends State<FunCalendarPicker>
    with SingleTickerProviderStateMixin {
  late DateTime _currentMonth;
  late DateTime? _selectedDate;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isRangeMode = false;

  late AnimationController _headerAnimController;
  late Animation<double> _slideAnimation;

  late AnimationController _daysAnimController;

  static const Color primaryIndigo = Color(0xFF6366F1);

  final List<String> _weekDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  final List<String> _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _currentMonth = DateTime.now();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic),
    );
    _headerAnimController.forward();

    _daysAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _daysAnimController.forward();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _daysAnimController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    HapticFeedback.lightImpact();
    _headerAnimController.reset();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _headerAnimController.forward();
  }

  void _nextMonth() {
    HapticFeedback.lightImpact();
    _headerAnimController.reset();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _headerAnimController.forward();
  }

  void _selectDate(DateTime date) {
    HapticFeedback.mediumImpact();

    if (_isRangeMode) {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        setState(() {
          _rangeStart = date;
          _rangeEnd = null;
        });
      } else {
        if (date.isBefore(_rangeStart!)) {
          setState(() {
            _rangeEnd = _rangeStart;
            _rangeStart = date;
          });
        } else {
          setState(() {
            _rangeEnd = date;
          });
        }
        if (_rangeEnd != null && widget.onRangeSelected != null) {
          widget.onRangeSelected!(_rangeStart!, _rangeEnd!);
        }
      }
    } else {
      setState(() {
        _selectedDate = date;
      });
      widget.onDateSelected(date);
    }
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Adjust for Monday start (1 = Monday, 7 = Sunday)
    int startWeekday = firstDay.weekday;
    int daysFromPrevMonth = startWeekday - 1;

    List<DateTime> days = [];

    // Previous month days
    for (int i = daysFromPrevMonth; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }

    // Current month days
    for (int i = 0; i < lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i + 1));
    }

    // Next month days to complete 6 weeks
    int remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(lastDay.add(Duration(days: i)));
    }

    return days;
  }

  bool _isInRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    return !date.isBefore(_rangeStart!) && !date.isAfter(_rangeEnd!);
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header with navigation
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: FadeTransition(
              opacity: _slideAnimation,
              child: Row(
                children: [
                  // Previous month
                  _NavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: _previousMonth,
                  ),
                  const SizedBox(width: 12),

                  // Month & Year
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${_months[_currentMonth.month - 1]} ${_currentMonth.year}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Quick buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _QuickFilterChip(
                              label: 'Aujourd\'hui',
                              isSelected: _selectedDate?.day == today.day &&
                                  _selectedDate?.month == today.month &&
                                  _selectedDate?.year == today.year,
                              onTap: () {
                                setState(() {
                                  _currentMonth = today;
                                });
                                _selectDate(today);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Next month
                  _NavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _nextMonth,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Week days header
          Row(
            children: _weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Days grid with animation
          AnimatedBuilder(
            animation: _daysAnimController,
            builder: (context, child) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: 42,
                itemBuilder: (context, index) {
                  final date = days[index];
                  final isCurrentMonth = date.month == _currentMonth.month;
                  final isToday = date.day == today.day &&
                      date.month == today.month &&
                      date.year == today.year;
                  final isSelected = _selectedDate != null &&
                      date.day == _selectedDate!.day &&
                      date.month == _selectedDate!.month &&
                      date.year == _selectedDate!.year;
                  final isInRange = _isInRange(date);
                  final isRangeStart = _rangeStart != null &&
                      date.day == _rangeStart!.day &&
                      date.month == _rangeStart!.month &&
                      date.year == _rangeStart!.year;
                  final isRangeEnd = _rangeEnd != null &&
                      date.day == _rangeEnd!.day &&
                      date.month == _rangeEnd!.month &&
                      date.year == _rangeEnd!.year;

                  // Staggered animation
                  final delay = (index / 42) * 0.5;
                  final itemAnimation = Tween<double>(begin: 0.0, end: 1.0)
                      .animate(CurvedAnimation(
                        parent: AnimationController(
                          vsync: this,
                          duration: const Duration(milliseconds: 400),
                        )..forward(),
                        curve: Interval(delay, 1.0, curve: Curves.easeOutBack),
                      ));

                  return ScaleTransition(
                    scale: AlwaysStoppedAnimation(
                      0.5 + (itemAnimation.value * 0.5),
                    ),
                    child: FadeTransition(
                      opacity: itemAnimation,
                      child: _DayButton(
                        day: date.day,
                        isCurrentMonth: isCurrentMonth,
                        isToday: isToday,
                        isSelected: isSelected || isRangeStart || isRangeEnd,
                        isInRange: isInRange,
                        isRangeStart: isRangeStart,
                        isRangeEnd: isRangeEnd,
                        onTap: () => _selectDate(date),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Réinitialiser',
                  icon: Icons.refresh_rounded,
                  color: Colors.grey,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedDate = null;
                      _rangeStart = null;
                      _rangeEnd = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Confirmer',
                  icon: Icons.check_rounded,
                  color: primaryIndigo,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.icon,
            color: const Color(0xFF6366F1),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_QuickFilterChip> createState() => _QuickFilterChipState();
}

class _QuickFilterChipState extends State<_QuickFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                  )
                : null,
            color: widget.isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayButton extends StatefulWidget {
  final int day;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final bool isInRange;
  final bool isRangeStart;
  final bool isRangeEnd;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.isInRange,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.onTap,
  });

  @override
  State<_DayButton> createState() => _DayButtonState();
}

class _DayButtonState extends State<_DayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.transparent;
    Color textColor = widget.isCurrentMonth
        ? const Color(0xFF1E293B)
        : Colors.grey.shade300;

    if (widget.isSelected || widget.isRangeStart || widget.isRangeEnd) {
      backgroundColor = const Color(0xFF6366F1);
      textColor = Colors.white;
    } else if (widget.isInRange) {
      backgroundColor = const Color(0xFF6366F1).withOpacity(0.2);
    }

    if (widget.isToday && !widget.isSelected) {
      textColor = const Color(0xFF6366F1);
    }

    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: widget.isToday && !widget.isSelected && !widget.isRangeStart
                ? Border.all(color: const Color(0xFF6366F1), width: 2)
                : null,
            boxShadow: widget.isSelected || widget.isRangeStart || widget.isRangeEnd
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isToday && !widget.isSelected && !widget.isRangeStart
                ? ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF6366F1),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  )
                : Text(
                    '${widget.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.isSelected || widget.isRangeStart
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.color == const Color(0xFF6366F1)
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                  )
                : null,
            color: widget.color == const Color(0xFF6366F1)
                ? null
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.color == const Color(0xFF6366F1)
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.color == const Color(0xFF6366F1)
                    ? Colors.white
                    : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.color == const Color(0xFF6366F1)
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to show the calendar
Future<DateTime?> showFunCalendar({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  DateTime? selectedDate;

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => FunCalendarPicker(
      selectedDate: initialDate,
      startDate: firstDate,
      endDate: lastDate,
      onDateSelected: (date) {
        selectedDate = date;
      },
    ),
  );

  return selectedDate;
}

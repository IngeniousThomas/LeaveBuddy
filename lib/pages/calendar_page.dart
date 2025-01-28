import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/navigation_drawer.dart';
import '../theme/theme_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/footer.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final List<(DateTime, DateTime)> _selectedRanges = [];
  DateTime? _tempRangeStart;
  Map<DateTime, List<String>> _events = {};
  bool _isSelectingRange = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showDatePickerDialog() {
    showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    ).then((date) {
      if (date != null) {
        setState(() {
          _focusedDay = date;
          _selectedDay = date;
        });
      }
    });
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('calendar_events');
    if (eventsJson != null) {
      final decodedEvents = json.decode(eventsJson) as Map<String, dynamic>;
      setState(() {
        _events = decodedEvents.map((key, value) {
          return MapEntry(
            DateTime.parse(key),
            List<String>.from(value as List),
          );
        });
      });
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedEvents = json.encode(
      _events.map((key, value) {
        return MapEntry(key.toString(), value);
      }),
    );
    await prefs.setString('calendar_events', encodedEvents);
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  bool _isDateInRanges(DateTime date) {
    for (var range in _selectedRanges) {
      if (date.isAtSameMomentAs(range.$1) ||
          date.isAtSameMomentAs(range.$2) ||
          (date.isAfter(range.$1) && date.isBefore(range.$2))) {
        return true;
      }
    }
    return false;
  }

  // ignore: unused_element
  bool _isRangeStart(DateTime date) {
    return _selectedRanges.any((range) => date.isAtSameMomentAs(range.$1));
  }

  bool _isRangeEnd(DateTime date) {
    return _selectedRanges.any((range) => date.isAtSameMomentAs(range.$2));
  }

  bool _isRangeDuplicate(DateTime start, DateTime end) {
    return _selectedRanges.any((range) =>
        (start.isAtSameMomentAs(range.$1) && end.isAtSameMomentAs(range.$2)) ||
        (start.isAtSameMomentAs(range.$2) && end.isAtSameMomentAs(range.$1)));
  }

  void _toggleRangeSelection() {
    setState(() {
      _isSelectingRange = !_isSelectingRange;
      if (!_isSelectingRange) {
        _tempRangeStart = null;
        _selectedDay = null;
      } else {
        _selectedRanges.clear();
        _tempRangeStart = null;
        _selectedDay = null;
      }
    });
  }

  void _addEvent(String event) {
    if (_selectedDay != null) {
      setState(() {
        _events[_selectedDay!] = [...(_events[_selectedDay!] ?? []), event];
      });
      _saveEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date first to add an event.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _editEvent(String oldEvent, String newEvent) {
    if (_selectedDay != null) {
      setState(() {
        final events = _events[_selectedDay!] ?? [];
        final index = events.indexOf(oldEvent);
        if (index != -1) {
          events[index] = newEvent;
          _events[_selectedDay!] = events;
        }
      });
      _saveEvents();
    }
  }

  void _deleteEvent(DateTime day, String event) {
    setState(() {
      _events[day]?.remove(event);
      if (_events[day]?.isEmpty ?? false) {
        _events.remove(day);
      }
    });
    _saveEvents();
  }

  void _deleteEventsInRange((DateTime, DateTime) range) {
    for (var day = range.$1;
        day.isBefore(range.$2.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))) {
      _events.remove(day);
    }
    _saveEvents();
  }

  Map<String, (DateTime, DateTime, List<DateTime>)> _getGroupedRangeEvents(
      (DateTime, DateTime) range) {
    final Map<String, (DateTime, DateTime, List<DateTime>)> groupedEvents = {};

    for (var day = range.$1;
        day.isBefore(range.$2.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))) {
      final dayEvents = _events[day] ?? [];
      for (final event in dayEvents) {
        if (groupedEvents.containsKey(event)) {
          var (start, end, dates) = groupedEvents[event]!;
          dates.add(day);
          if (day.isBefore(start)) start = day;
          if (day.isAfter(end)) end = day;
          groupedEvents[event] = (start, end, dates);
        } else {
          groupedEvents[event] = (day, day, [day]);
        }
      }
    }

    return groupedEvents;
  }

  void _showAddEventDialog({bool isRange = false}) {
    if (!isRange && _selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date first to add an event.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final TextEditingController eventController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isRange
              ? 'Add Event for Selected Ranges'
              : 'Add Event for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
        ),
        content: TextField(
          controller: eventController,
          decoration: const InputDecoration(
            labelText: 'Event Description',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (eventController.text.isNotEmpty) {
                if (isRange) {
                  for (var range in _selectedRanges) {
                    for (var day = range.$1;
                        day.isBefore(range.$2.add(const Duration(days: 1)));
                        day = day.add(const Duration(days: 1))) {
                      setState(() {
                        _events[day] = [...(_events[day] ?? []), eventController.text];
                      });
                    }
                  }
                } else {
                  _addEvent(eventController.text);
                }
                _saveEvents();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(String oldEvent) {
    final TextEditingController eventController = TextEditingController(text: oldEvent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Event'),
        content: TextField(
          controller: eventController,
          decoration: const InputDecoration(
            labelText: 'Edit Event Description',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (eventController.text.isNotEmpty) {
                _editEvent(oldEvent, eventController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          drawer: const AppNavigationDrawer(),
          appBar: AppBar(
            title: const Text('Calendar'),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _showDatePickerDialog,
              ),
            ],
          ),
          body: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2022, 10, 31),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                selectedDayPredicate: (day) {
                  if (_isSelectingRange) {
                    return _isDateInRanges(day) ||
                        (_tempRangeStart != null &&
                            day.isAtSameMomentAs(_tempRangeStart!));
                  }
                  return _selectedDay != null && isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    if (_isSelectingRange) {
                      if (_tempRangeStart == null) {
                        _tempRangeStart = selectedDay;
                      } else {
                        final rangeStart = _tempRangeStart!.isBefore(selectedDay)
                            ? _tempRangeStart!
                            : selectedDay;
                        final rangeEnd = _tempRangeStart!.isBefore(selectedDay)
                            ? selectedDay
                            : _tempRangeStart!;

                        if (!_isRangeDuplicate(rangeStart, rangeEnd)) {
                          _selectedRanges.add((rangeStart, rangeEnd));
                        }
                        _tempRangeStart = null;
                      }
                    } else {
                      _selectedDay = selectedDay;
                    }
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: _getEventsForDay,
                headerStyle: HeaderStyle(
                  titleCentered: false,
                  formatButtonVisible: false,
                  leftChevronVisible: false,
                  rightChevronVisible: false,
                  titleTextStyle: TextStyle(
                    fontSize: 20,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  headerTitleBuilder: (context, day) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _getMonthName(day.month),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${day.year}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(
                                    _focusedDay.year,
                                    _focusedDay.month - 1,
                                  );
                                });
                              },
                            ),
                            TextButton(
                              onPressed: _goToToday,
                              child: Text(
                                'Today',
                                style: TextStyle(
                                  color: themeProvider.isDarkMode 
                                      ? Colors.deepPurpleAccent 
                                      : Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(
                                    _focusedDay.year,
                                    _focusedDay.month + 1,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  todayBuilder: (context, date, _) {
                    return Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: themeProvider.isDarkMode 
                              ? Colors.deepPurpleAccent 
                              : Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    );
                  },
                  selectedBuilder: (context, date, _) {
                    final isRangeEnd = _isRangeEnd(date);
                    final isInRange = _isDateInRanges(date);

                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: isRangeEnd ||
                                (!_isSelectingRange &&
                                    _selectedDay != null &&
                                    isSameDay(_selectedDay, date))
                            ? (themeProvider.isDarkMode
                                ? Colors.deepPurple
                                : Colors.deepPurple)
                            : isInRange
                                ? (themeProvider.isDarkMode
                                        ? Colors.deepPurpleAccent
                                        : Colors.deepPurple)
                                    .withOpacity(0.7)
                                : null,
                        border: Border.all(
                          color: themeProvider.isDarkMode
                              ? Colors.deepPurpleAccent
                              : Colors.deepPurpleAccent,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isRangeEnd ||
                                    (!_isSelectingRange &&
                                        _selectedDay != null &&
                                        isSameDay(_selectedDay, date))
                                ? Colors.white
                                : isInRange
                                    ? Colors.white
                                    : (themeProvider.isDarkMode
                                        ? Colors.deepPurpleAccent
                                        : Colors.deepPurple),
                          ),
                        ),
                      ),
                    );
                  },
                  dowBuilder: (context, day) {
                    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                    final text = weekDays[day.weekday % 7];
                    return Center(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: day.weekday == DateTime.sunday 
                              ? (themeProvider.isDarkMode ? Colors.red[200] : Colors.red)
                              : (themeProvider.isDarkMode ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    if (day.weekday == DateTime.sunday) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.red[200] : Colors.red,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                calendarStyle: CalendarStyle(
                  todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  todayDecoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.deepPurpleAccent
                        : Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.deepPurpleAccent
                        : Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  outsideTextStyle: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[600]
                        : Colors.grey[400],
                  ),
                  markersMaxCount: 4,
                  markersAlignment: Alignment.bottomCenter,
                  markerDecoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isSelectingRange && _selectedRanges.isNotEmpty
                          ? () => _showAddEventDialog(isRange: true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.isDarkMode
                            ? const Color.fromARGB(255, 255, 255, 255)
                            : const Color.fromARGB(255, 255, 255, 255),
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.add),
                    ),
                    ElevatedButton.icon(
                      onPressed: _toggleRangeSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFFF5F5F5),
                        foregroundColor: Colors.deepPurple,
                      ),
                      icon: Icon(
                        _isSelectingRange ? Icons.cancel : Icons.select_all,
                        color: _isSelectingRange ? Colors.deepPurple : Colors.deepPurple,
                      ),
                      label: Text(
                        _isSelectingRange ? 'Cancel' : 'Select Range',
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isSelectingRange && _selectedRanges.isNotEmpty
                          ? () {
                              setState(() {
                                for (var range in _selectedRanges) {
                                  _deleteEventsInRange(range);
                                }
                                _selectedRanges.clear();
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildEventList(),
              ),
              const Footer(),
            ],
          ),
          floatingActionButton: !_isSelectingRange
              ? FloatingActionButton(
                  onPressed: () => _showAddEventDialog(isRange: false),
                  backgroundColor: themeProvider.isDarkMode
                      ? Colors.deepPurpleAccent
                      : Colors.deepPurple,
                  tooltip: 'Add Event',
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEventList() {
    if (_isSelectingRange) {
      if (_selectedRanges.isEmpty) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => Center(
            child: Text(
              _tempRangeStart != null
                  ? 'Now select the end date'
                  : 'Select the first date',
              style: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ),
        );
      }
      return ListView.builder(
        itemCount: _selectedRanges.length,
        itemBuilder: (context, index) {
          final range = _selectedRanges[index];
          final groupedEvents = _getGroupedRangeEvents(range);

          return Card(
            margin: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 8,
            ),
            child: ListTile(
              title: Text(
                'Range ${index + 1}: ${range.$1.day}/${range.$1.month} - ${range.$2.day}/${range.$2.month}',
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...groupedEvents.entries.map((entry) {
                    final eventName = entry.key;
                    final (start, end, dates) = entry.value;

                    if (dates.length > 6) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$eventName (${start.day}/${start.month} - ${end.day}/${end.month})',
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${dates.map((d) => '${d.day}/${d.month}').join(', ')}: $eventName',
                        ),
                      );
                    }
                  }),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedRanges.removeAt(index);
                  });
                },
              ),
            ),
          );
        },
      );
    }

    if (_selectedDay == null) {
      return Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Center(
          child: Text(
            'Select a day to view events',
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return ListView(
      children: _getEventsForDay(_selectedDay!)
          .map((event) => Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
                child: ListTile(
                  title: Text(event),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditEventDialog(event),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteEvent(_selectedDay!, event),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
import 'package:flutter/material.dart';
import '../widgets/navigation_drawer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<(DateTime, DateTime)> _selectedRanges = [];
  DateTime? _tempRangeStart;
  Map<DateTime, List<String>> _events = {};
  bool _isSelectingRange = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _showDatePickerDialog() {
    showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2020),
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
        // Clear any existing ranges when entering range mode
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
    (DateTime, DateTime) range
  ) {
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
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            selectedDayPredicate: (day) {
              if (_isSelectingRange) {
                return _isDateInRanges(day) || 
                       (_tempRangeStart != null && day.isAtSameMomentAs(_tempRangeStart!));
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
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, date, _) {
                final isRangeStart = _isRangeStart(date);
                final isRangeEnd = _isRangeEnd(date);
                final isInRange = _isDateInRanges(date);
                
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: isRangeEnd || (!_isSelectingRange && _selectedDay != null && isSameDay(_selectedDay, date))
                        ? Theme.of(context).primaryColor
                        : isInRange
                            ? Theme.of(context).primaryColor.withOpacity(0.7)
                            : null,
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isRangeEnd || (!_isSelectingRange && _selectedDay != null && isSameDay(_selectedDay, date))
                            ? Colors.white
                            : isInRange
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                );
              },
              dowBuilder: (context, day) {
                if (day.weekday == DateTime.sunday) {
                  return Center(
                    child: Text(
                      'Sun',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                return null;
              },
              defaultBuilder: (context, day, focusedDay) {
                if (day.weekday == DateTime.sunday) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                return null;
              },
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
                  child: const Icon(Icons.add),
                ),
                ElevatedButton.icon(
                  onPressed: _toggleRangeSelection,
                  icon: const Icon(Icons.select_all),
                  label: Text(_isSelectingRange ? 'Cancel' : 'Range'),
                ),
                ElevatedButton(
                  onPressed: _isSelectingRange && _selectedRanges.isNotEmpty
                      ? () {
                          setState(() {
                            // Delete all events in all selected ranges
                            for (var range in _selectedRanges) {
                              _deleteEventsInRange(range);
                            }
                            _selectedRanges.clear();
                          });
                        }
                      : null,
                  child: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isSelectingRange
                ? (_selectedRanges.isEmpty
                    ? Center(
                        child: Text(
                          _tempRangeStart != null
                              ? 'Now select the end date'
                              : 'Select the first date',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
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
                                          dates.map((d) => '${d.day}/${d.month}').join(', ') +
                                          ': $eventName',
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
                      ))
                : (_selectedDay == null
                    ? const Center(
                        child: Text(
                          'Select a day to view events',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
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
                      )),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Made with ❤️ by Arun Thomas',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
      floatingActionButton: !_isSelectingRange
          ? FloatingActionButton(
              onPressed: _selectedDay != null 
                  ? () => _showAddEventDialog(isRange: false)
                  : null,
              tooltip: 'Add Event',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
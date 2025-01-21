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
  List<DateTime> _selectedDays = [];
  Map<DateTime, List<String>> _events = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
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

  void _toggleDaySelection(DateTime day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
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

  void _addEventToSelectedDays(String event) {
    setState(() {
      for (var day in _selectedDays) {
        _events[day] = [...(_events[day] ?? []), event];
      }
    });
    _saveEvents();
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

  void _bulkDeleteEvents() {
    setState(() {
      for (var day in _selectedDays) {
        _events.remove(day);
      }
      _selectedDays.clear();
    });
    _saveEvents();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (_isSelectionMode) {
        _selectedDay = null; // Clear highlighted date when entering bulk mode
      } else {
        _selectedDays.clear(); // Clear bulk selection when leaving bulk mode
      }
    });
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

  void _showAddEventDialog({bool isBulk = false}) {
    final TextEditingController eventController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBulk
            ? 'Add Event for Selected Days (${_selectedDays.length})'
            : _selectedDay != null
                ? 'Add Event for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                : 'Please select a date first'),
        content: isBulk || _selectedDay != null
            ? TextField(
                controller: eventController,
                decoration: const InputDecoration(
                  labelText: 'Event Description',
                ),
              )
            : null,
        actions: isBulk || _selectedDay != null
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (eventController.text.isNotEmpty) {
                      if (isBulk) {
                        _addEventToSelectedDays(eventController.text);
                      } else {
                        _addEvent(eventController.text);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
      ),
    );
  }

  void _showEditEventDialog(String oldEvent) {
    final TextEditingController eventController =
        TextEditingController(text: oldEvent);
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
        title: Text(
          'Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDatePickerDialog,
            tooltip: 'Jump to Date',
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
            selectedDayPredicate: (day) =>
                (!_isSelectionMode && isSameDay(_selectedDay, day)) ||
                (_isSelectionMode && _selectedDays.contains(day)),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                if (_isSelectionMode) {
                  _toggleDaySelection(selectedDay);
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
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                if (day.weekday == DateTime.sunday) {
                  return Center(
                    child: Text(
                      'Sun',
                      style: TextStyle(color: Colors.red),
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
                      style: TextStyle(color: Colors.red),
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
                  onPressed: _isSelectionMode
                      ? () => _showAddEventDialog(isBulk: true)
                      : null,
                  child: const Icon(Icons.add),
                ),
                ElevatedButton.icon(
                  onPressed: _toggleSelectionMode,
                  icon: Icon(
                    _isSelectionMode ? Icons.cancel : Icons.select_all,
                  ),
                  label: Text(
                    _isSelectionMode ? ' Cancel' : 'Multiple',
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSelectionMode ? _bulkDeleteEvents : null,
                  child: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isSelectionMode
                ? _selectedDays.isEmpty
                    ? const Center(
                        child: Text('No days selected'),
                      )
                    : ListView(
                        children: _selectedDays
                            .expand((day) => _getEventsForDay(day)
                                .map((event) => Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 8,
                                      ),
                                      child: ListTile(
                                        title: Text(
                                            '$event (${day.day}/${day.month}/${day.year})'),
                                      ),
                                    )))
                            .toList(),
                      )
                : _selectedDay == null
                    ? const Center(
                        child: Text('Select a day to view events'),
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
                                          onPressed: () =>
                                              _showEditEventDialog(event),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {
                                            setState(() {
                                              _events[_selectedDay!]
                                                  ?.remove(event);
                                              if (_events[_selectedDay!]
                                                      ?.isEmpty ??
                                                  false) {
                                                _events.remove(_selectedDay!);
                                              }
                                            });
                                            _saveEvents();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
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
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddEventDialog(isBulk: false),
              tooltip: 'Add Event',
              child: const Icon(Icons.add),
            ),
    );
  }
}

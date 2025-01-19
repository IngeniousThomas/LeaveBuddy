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
  Map<DateTime, List<String>> _events = {};

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

  void _showAddEventDialog() {
    final TextEditingController eventController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_selectedDay != null 
          ? 'Add Event for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
          : 'Please select a date first'),
        content: _selectedDay != null ? TextField(
          controller: eventController,
          decoration: const InputDecoration(
            labelText: 'Event Description',
            hintText: 'Enter event details',
          ),
          maxLines: 3,
        ) : null,
        actions: _selectedDay != null ? [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (eventController.text.isNotEmpty) {
                _addEvent(eventController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ] : [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(String event) {
    final TextEditingController eventController = TextEditingController(text: event);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Event'),
        content: TextField(
          controller: eventController,
          decoration: const InputDecoration(
            labelText: 'Event Description',
            hintText: 'Enter event details',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (eventController.text.isNotEmpty) {
                _editEvent(event, eventController.text);
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
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month, // Fixed to month view
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month'
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            headerStyle: HeaderStyle(
              titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronVisible: true,
              rightChevronVisible: true,
              titleTextFormatter: (date, locale) => 
                '${date.month}/${date.year}',
            ),
            onHeaderTapped: (_) => _showDatePickerDialog(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _showAddEventDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
            ),
          ),
          const Divider(),
          Expanded(
            child: _selectedDay == null
                ? const Center(
                    child: Text('Select a day to view events'),
                  )
                : ListView(
                    padding: const EdgeInsets.all(8),
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
                                      onPressed: () {
                                        setState(() {
                                          _events[_selectedDay!]?.remove(event);
                                          if (_events[_selectedDay!]?.isEmpty ?? false) {
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
    );
    
  }
}
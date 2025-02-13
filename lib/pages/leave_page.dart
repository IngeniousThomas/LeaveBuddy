import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/leave_type.dart';
import '../widgets/navigation_drawer.dart';
import '../widgets/footer.dart';
import '../theme/theme_provider.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  _LeavePageState createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  List<LeaveType> leaveTypes = [];
  final TextEditingController _leaveNameController = TextEditingController();
  final TextEditingController _leaveCountController = TextEditingController();
  bool isEditing = false;
  bool isModifying = false;

  final List<Color> leaveColors = [
    const Color(0xFF20C65F),
    const Color(0xFF3C82F6),
    const Color(0xFFA955F7),
    const Color(0xFFF43F5F),
    const Color(0xFFF69E0C),
    const Color(0xFF13B8A6),
    const Color(0xFF6366F1),
    const Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    _loadLeaveData();
  }

  Future<void> _loadLeaveData() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList('leaveNames');
    final counts = prefs.getStringList('leaveCounts');
    final colors = prefs.getStringList('leaveColors');

    setState(() {
      if (names != null && counts != null && colors != null) {
        leaveTypes = List.generate(
          names.length,
          (i) => LeaveType(
            name: names[i],
            count: double.parse(counts[i]),
            color: Color(int.parse(colors[i])),
          ),
        );
      }
    });
  }

  Future<void> _saveLeaveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('leaveNames', leaveTypes.map((leave) => leave.name).toList());
    await prefs.setStringList(
        'leaveCounts', leaveTypes.map((leave) => leave.count.toStringAsFixed(2)).toList());
    await prefs.setStringList(
        'leaveColors', leaveTypes.map((leave) => leave.color.value.toString()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          drawer: const AppNavigationDrawer(),
          appBar: AppBar(
            title: const Text('Leave Buddy'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(isEditing ? Icons.close : Icons.edit),
                onPressed: () {
                  setState(() {
                    isEditing = !isEditing;
                    isModifying = false;
                  });
                },
              ),
              if (isEditing)
                IconButton(
                  icon: Icon(isModifying ? Icons.save : Icons.delete,
                      color: isModifying ? Colors.deepPurple : Colors.red),
                  onPressed: () {
                    setState(() {
                      isModifying = !isModifying;
                      if (!isModifying) {
                        _saveLeaveData();
                      }
                    });
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: leaveTypes.isEmpty
                    ? const Center(
                        child: Text(
                          'No leave types added yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: leaveTypes.length,
                        itemBuilder: (context, index) {
                          final leave = leaveTypes[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              isEditing ? _showEditNameDialog(leave) : null,
                                          child: Text(
                                            leave.name,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              decoration: isEditing
                                                  ? TextDecoration.underline
                                                  : TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isModifying)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              leaveTypes.removeAt(index);
                                            });
                                            _saveLeaveData();
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: leave.color.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, color: Colors.white),
                                          onPressed: () {
                                            setState(() {
                                              if (leave.count >= 0.25) {
                                                leave.count = validateLeaveCount(leave.count - 1);
                                                _saveLeaveData();
                                              }
                                            });
                                          },
                                        ),
                                        GestureDetector(
                                          onTap: () => _showInputDialog(leave),
                                          child: Text(
                                            leave.count
                                                    .toString()
                                                    .replaceAll(RegExp(r'.\d+$'), '')
                                                    .length >
                                                10
                                                ? leave.count.toStringAsExponential(2)
                                                : leave.count.toStringAsFixed(2),
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, color: Colors.white),
                                          onPressed: () {
                                            setState(() {
                                              leave.count =
                                                  validateLeaveCount(leave.count + 0.5);
                                              _saveLeaveData();
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (isEditing)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add New Leave Type'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.isDarkMode
                          ? Colors.deepPurpleAccent
                          : Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: _showAddLeaveDialog,
                  ),
                ),
              const Footer(),
            ],
          ),
        );
      },
    );
  }

  double validateLeaveCount(double value) {
    return (value * 4).round() / 4;
  }

  void _showInputDialog(LeaveType leave) {
    _leaveCountController.text = leave.count.toString();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${leave.name}'),
          content: TextField(
            controller: _leaveCountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Leave Count',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newCount = double.tryParse(_leaveCountController.text);
                if (newCount != null) {
                  setState(() {
                    leave.count = validateLeaveCount(newCount);
                  });
                  _saveLeaveData();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddLeaveDialog() {
    _leaveNameController.clear();
    _leaveCountController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Leave Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _leaveNameController,
                decoration: const InputDecoration(
                  labelText: 'Leave Type Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _leaveCountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Leave Count',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_leaveNameController.text.isNotEmpty &&
                    _leaveCountController.text.isNotEmpty) {
                  final newCount = double.tryParse(_leaveCountController.text);
                  if (newCount != null) {
                    setState(() {
                      leaveTypes.add(
                        LeaveType(
                          name: _leaveNameController.text,
                          count: validateLeaveCount(newCount),
                          color: leaveColors[leaveTypes.length % leaveColors.length],
                        ),
                      );
                    });
                    _saveLeaveData();
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditNameDialog(LeaveType leave) {
    _leaveNameController.text = leave.name;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Leave Type Name'),
          content: TextField(
            controller: _leaveNameController,
            decoration: const InputDecoration(
              labelText: 'Leave Type Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_leaveNameController.text.isNotEmpty) {
                  setState(() {
                    leave.name = _leaveNameController.text;
                  });
                  _saveLeaveData();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
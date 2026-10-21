import 'package:flutter/material.dart';

class DebugLog {
  final String message;
  final DateTime timestamp;
  final String? error;

  DebugLog(this.message, {this.error}) : timestamp = DateTime.now();

  @override
  String toString() {
    final time = timestamp.toString().split('.')[0];
    return '$time | $message${error != null ? '\nError: $error' : ''}';
  }
}

class DebugConsole {
  static final DebugConsole _instance = DebugConsole._internal();
  final List<DebugLog> logs = [];
  final int maxLogs = 100;

  DebugConsole._internal();

  factory DebugConsole() => _instance;

  void log(String message) {
    logs.add(DebugLog(message));
    if (logs.length > maxLogs) {
      logs.removeAt(0);
    }
    print('[DEBUG] $message');
  }

  void error(String message, [dynamic error]) {
    logs.add(DebugLog(message, error: error?.toString()));
    if (logs.length > maxLogs) {
      logs.removeAt(0);
    }
    print('[ERROR] $message');
    if (error != null) print(error);
  }

  void clear() => logs.clear();

  List<String> getFormattedLogs() => logs.map((l) => l.toString()).toList();
}

class DebugConsoleOverlay extends StatefulWidget {
  final Widget child;

  const DebugConsoleOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<DebugConsoleOverlay> createState() => _DebugConsoleOverlayState();
}

class _DebugConsoleOverlayState extends State<DebugConsoleOverlay> {
  bool _showConsole = false;
  final _console = DebugConsole();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_showConsole)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 300,
                color: Colors.black87,
                child: Column(
                  children: [
                    Container(
                      color: Colors.black,
                      padding: EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Debug Console (${_console.logs.length})',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _console.clear()),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('Clear', style: TextStyle(color: Colors.yellow)),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _showConsole = false),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('Close', style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _console.logs.length,
                        itemBuilder: (context, index) {
                          final log = _console.logs[index];
                          final isError = log.error != null;
                          return Padding(
                            padding: EdgeInsets.all(4),
                            child: Text(
                              log.toString(),
                              style: TextStyle(
                                color: isError ? Colors.red : Colors.white70,
                                fontSize: 10,
                                fontFamily: 'Courier',
                              ),
                            ),
                          );
                        },
                        reverse: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: _showConsole ? Colors.red : Colors.blue,
              onPressed: () => setState(() => _showConsole = !_showConsole),
              child: Icon(_showConsole ? Icons.close : Icons.bug_report),
            ),
          ),
        ],
      ),
    );
  }
}

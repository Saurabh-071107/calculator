import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryPage extends StatefulWidget {
  final Function(String result) onItemTap;

  const HistoryPage({super.key, required this.onItemTap});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _historyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyList = prefs.getStringList('history') ?? [];
    
    setState(() {
      _historyData = historyList.map((item) {
        try {
          return jsonDecode(item) as Map<String, dynamic>;
        } catch (e) {
          return <String, dynamic>{};
        }
      }).where((item) => item.isNotEmpty).toList();
      _isLoading = false;
    });
  }

  Future<void> _deleteHistoryItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyList = prefs.getStringList('history') ?? [];
    
    historyList.removeWhere((item) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        return decoded['id'] == id;
      } catch (e) {
        return false;
      }
    });
    
    await prefs.setStringList('history', historyList);
    
    setState(() {
      _historyData.removeWhere((item) => item['id'] == id);
    });
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
    
    setState(() {
      _historyData.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
  
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: isDark
                    ? [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF121212),
                ]
                    : [
                  Colors.lightBlueAccent,
                  Colors.white,
                ],
              ),
            ),
          ),
       
          SafeArea(
            child: Column(
              children: [
              
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text("Calculation History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _historyData.isEmpty ? null : _clearAllHistory,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
             
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _historyData.isEmpty
                          ? const Center(
                              child: Text(
                                "No History Yet",
                                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _historyData.length,
                              itemBuilder: (context, index) {
                                var data = _historyData[index];
                                return Dismissible(
                                  key: Key(data['id']?.toString() ?? index.toString()),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    if (data['id'] != null) {
                                      _deleteHistoryItem(data['id']);
                                    }
                                  },
                                  background: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius:
                                      BorderRadius.circular(15),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding:
                                    const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 6),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2A2A2A)
                                          : Colors.white,
                                      borderRadius:
                                      BorderRadius.circular(15),
                                      boxShadow: isDark
                                          ? []
                                          : [
                                        BoxShadow(
                                          color: Colors.grey
                                              .withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: ListTile(
                                      onTap: () {
                                        widget.onItemTap(data['result'] ?? '');
                                        Navigator.pop(context);
                                      },
                                      title: Text(
                                        data['expression'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "= ${data['result'] ?? ''}",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
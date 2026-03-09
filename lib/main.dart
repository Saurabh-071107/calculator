import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'history_page.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.transparent, 
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
        ),
      ),
      home: MyHomePage(
        title: "Calcmaster Pro",
        toggleTheme: toggleTheme,
        isDarkMode: isDarkMode,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.toggleTheme,
    required this.isDarkMode,
  });
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String display = "0";
  String expression = "";
  
  Color getButtonColor(String title, bool isDark) {
    if (['AC', 'C', 'DEL'].contains(title)) {
      return isDark ? const Color(0xFFE57373) : Colors.redAccent.withValues(alpha: 0.8);
    } else if (['+', '-', 'X', '/', '=', '%'].contains(title)) {
      return isDark ? const Color(0xFF1E88E5) : Colors.blueAccent;
    } else if (['sin', 'cos', 'tan', 'log', 'ln', 'sqrt', '^', 'pi', 'asin', 'acos', 'atan', 'abs', 'e', '(', ')'].contains(title)) {
      return isDark ? const Color(0xFF424242) : Colors.grey.shade300;
    }
    return isDark ? const Color(0xFF2A2A2A) : Colors.white;
  }

  Color getTextColor(String title, bool isDark) {
    if (['AC', 'C', 'DEL', '+', '-', 'X', '/', '=', '%'].contains(title)) {
      return Colors.white;
    } else if (['sin', 'cos', 'tan', 'log', 'ln', 'sqrt', '^', 'pi', 'asin', 'acos', 'atan', 'abs', 'e', '(', ')'].contains(title)) {
      return isDark ? Colors.blueAccent.shade100 : Colors.blueAccent.shade700;
    }
    return isDark ? Colors.white : Colors.black87;
  }

  Future<void> saveHistory(String expr, String res) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyList = prefs.getStringList('history') ?? [];
    
    Map<String, dynamic> newEntry = {
      "expression": expr,
      "result": res,
      "timestamp": DateTime.now().toIso8601String(),
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
    };
    
    historyList.insert(0, jsonEncode(newEntry));
    await prefs.setStringList('history', historyList);
  }

  void onButtonPressed(String value) {
    setState(() {
      if (value == "AC") {
        display = "0";
        expression = "";
        return;
      }

      if (value == "C" || value == "DEL") {
        if (display.length > 1) {
          display = display.substring(0, display.length - 1);
        } else {
          display = "0";
        }
        return;
      }

      if (value == "." && display.contains(".")) {
        return;
      }

      // Percentage
      if (value == "%") {
        try {
          double current = double.parse(display);
          display = (current / 100).toString();
        } catch (e) {
          
        }
        return;
      }
      
      // Constants
      if (value == "pi") {
        if (display == "0") {
          display = "3.14159265";
        } else {
          display += "3.14159265";
        }
        return;
      }
      if (value == "e") {
        if (display == "0") {
          display = "2.71828182";
        } else {
          display += "2.71828182";
        }
        return;
      }
      
    
      if (['sin', 'cos', 'tan', 'log', 'ln', 'sqrt', 'asin', 'acos', 'atan', 'abs'].contains(value)) {
        String funcName = value == 'sqrt' ? 'sqrt' : value;
        if (display == "0") {
          display = "$funcName(";
        } else {
          display += "$funcName(";
        }
        return;
      }

      if (value == "+" || value == "-" || value == "X" || value == "/" || value == "^") {
    
        expression += display;

        if (expression.isNotEmpty &&
            "+-X/^".contains(expression[expression.length - 1])) {
          expression = expression.substring(0, expression.length - 1);
        }

        expression += value;
        display = "0";
        return;
      }

      if (value == "=") {
        try {
          String finalExpression = expression + display;
          String originalExpression = finalExpression;

          finalExpression = finalExpression.replaceAll("X", "*");
          finalExpression = finalExpression.replaceAll("asin(", "arcsin(");
          finalExpression = finalExpression.replaceAll("acos(", "arccos(");
          finalExpression = finalExpression.replaceAll("atan(", "arctan(");
          finalExpression = finalExpression.replaceAll("log(", "log(10,");
          
          Parser p = Parser();
          Expression exp = p.parse(finalExpression);
          ContextModel cm = ContextModel();
          double eval = exp.evaluate(EvaluationType.REAL, cm);

          String resultStr = eval % 1 == 0
              ? eval.toInt().toString()
              : eval.toStringAsFixed(8); 
             
          if (resultStr.contains('.')) {
             resultStr = resultStr.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
          }

          saveHistory(originalExpression, resultStr);
          display = resultStr;
          expression = "";

        } catch (e) {
          display = "Error";
          expression = "";
        }

        return;
      }

      if (display == "0" || display == "Error") {
        display = value;
      } else {
        display += value;
      }
    });
  }
  
  Widget _buildButton(String title) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: ElevatedButton(
        onPressed: () => onButtonPressed(title),
        style: ElevatedButton.styleFrom(
          elevation: 4,
          backgroundColor: getButtonColor(title, widget.isDarkMode),
          foregroundColor: getTextColor(title, widget.isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: ['sin', 'cos', 'tan', 'log', 'ln', 'sqrt', 'pi', 'asin', 'acos', 'atan', 'abs'].contains(title) ? 18 : 24, 
            fontWeight: FontWeight.w600
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double resultFont = (screenWidth * 0.12).clamp(32, 60);
    double expFont = (screenWidth * 0.05).clamp(16, 28);
    
    final List<String> buttons = [
      'sin', 'cos', 'tan', 'log', 'ln',
      '(', ')', 'sqrt', '^', 'pi',
      'AC', 'DEL', '%', '/', 'asin',
      '7', '8', '9', 'X', 'acos',
      '4', '5', '6', '-', 'atan',
      '1', '2', '3', '+', 'abs',
      '.', '0', '00', '=', 'e'
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: widget.isDarkMode 
            ? null 
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0F7FA), Color(0xFF81D4FA), Color(0xFF29B6F6)],
              ),
        ),
        child: SafeArea(
          child: Column(
          children: [
         
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.history, size: 30, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              HistoryPage(onItemTap: (value) {
                                setState(() {
                                  display = value;
                                });
                              }),
                          transitionsBuilder: (_, animation, __, child) {
                            return SlideTransition(
                              position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const Text(
                    'Calcmaster Pro',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      size: 30,
                    ),
                    onPressed: widget.toggleTheme,
                  ),
                ],
              ),
            ),
            
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        expression,
                        style: TextStyle(
                          fontSize: expFont,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        display,
                        style: TextStyle(
                          fontSize: resultFont,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / 5;
                    final itemHeight = constraints.maxHeight / 7;
                    final ratio = itemWidth / itemHeight;
                    
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: buttons.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: ratio,
                      ),
                      itemBuilder: (context, index) {
                        String btn = buttons[index];
                        if (btn.isEmpty) return const SizedBox.shrink();
                        
                        if (btn == '=') {
                          return Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: ElevatedButton(
                              onPressed: () => onButtonPressed(btn),
                              style: ElevatedButton.styleFrom(
                                elevation: 4,
                                backgroundColor: getButtonColor(btn, widget.isDarkMode),
                                foregroundColor: getTextColor(btn, widget.isDarkMode),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('=', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                            ),
                          );
                        }
                        
                        return _buildButton(btn);
                      },
                    );
                  }
                ),
              ),
            ),
          ],
        ),
      ),
      )
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'history_page.dart';
import 'package:math_expressions/math_expressions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
        ),
      ),
      home: MyHomePage(
        title: "Calcmaster",
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

  void onButtonPressed(String value) {
    setState(() {

      if (value == "AC") {
        display = "0";
        expression = "";
        return;
      }

      if (value == "C") {
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

      //percentage
      if (value == "%") {
        double current = double.parse(display);
        display = (current / 100).toString();
        return;
      }

      // Operators
      if (value == "+" || value == "-" || value == "X" || value == "/") {

        // Add current display to expression
        expression += display;

        // Prevent double operators
        if (expression.isNotEmpty &&
            "+-X/".contains(expression[expression.length - 1])) {
          expression = expression.substring(0, expression.length - 1);
        }

        expression += value;
        display = "0";
        return;
      }

      // Equals
      if (value == "=") {
        try {
          String finalExpression = expression + display;

          finalExpression = finalExpression.replaceAll("X", "*");

          Parser p = Parser();
          Expression exp = p.parse(finalExpression);
          ContextModel cm = ContextModel();
          double eval = exp.evaluate(EvaluationType.REAL, cm);

          display = eval % 1 == 0
              ? eval.toInt().toString()
              : eval.toString();

          expression = "";

          FirebaseFirestore.instance.collection("history").add({
            "expression": finalExpression,
            "result": display,
            "timestamp": FieldValue.serverTimestamp(),
          });

        } catch (e) {
          display = "Error";
          expression = "";
        }

        return;
      }

      // Numbers
      if (display == "0") {
        display = value;
      } else {
        display += value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double resultFont = (screenWidth * 0.12).clamp(32, 70);
    double expFont = (screenWidth * 0.05).clamp(16, 28);
    double bfont = (screenWidth * 0.056).clamp(16, 28);
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Stack(
          children: [
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: widget.isDarkMode
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 20
                            ),
                            child: Container(
                              child: Center(child: Text('Calcmaster',style: TextStyle(fontSize: 30,fontWeight: FontWeight.w500,color: Colors.blueAccent),)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 10,
                            right: 20,
                            left: 25
                          ),
                          child: Container(
                            width: 40,
                            height: double.infinity,
                            child: IconButton(
                              icon: const Icon(Icons.settings,size: 30,),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 40,
                                      ),
                                      child: ListTile(
                                        title: const Text("Dark Mode"),
                                        trailing: Switch(
                                          value: widget.isDarkMode,
                                          onChanged: (_) {
                                            widget.toggleTheme();
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    child: Row(
                      children: [
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsetsGeometry.only(left: 10,
                                top: 5,
                                right: 0),
                            child: Container(
                                height: 50,
                                width: 50,
                                color: Colors.transparent,
                                child: IconButton(
                                  icon: Align(
                                    alignment: Alignment(0, 1),
                                      child: const Icon(Icons.history, size: 40)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            HistoryPage(onItemTap: (value) {setState(() {
                                                display = value;
                                              });
                                            }),
                                        transitionsBuilder: (_, animation, __, child) {
                                          return SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero,).animate(animation),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                            ),
                          ),
                        ),
                        Expanded(
                            child: Container()
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsetsGeometry.only(left: 10,
                                top: 5,
                                right: 0,
                                bottom: 40),
                            child: Container(
                                height: 130,
                                width: 330,
                                color: Colors.transparent,
                                child:Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      reverse: true,
                                      child: Text(
                                        expression,
                                        style: TextStyle(
                                          fontSize: expFont,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        display,
                                        style:  TextStyle(
                                          fontSize: resultFont,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                )

                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Positioned(
              top: 360,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 552,
                decoration:  BoxDecoration(
                  color: widget.isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Container(
                  height: 512,
                  width: double.infinity,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 125,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: ()=> onButtonPressed("AC"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                backgroundColor: widget.isDarkMode
                                                    ? const Color(0xFF2A2A2A)
                                                    : Colors.lightBlueAccent,
                                                foregroundColor: widget.isDarkMode
                                                    ? Colors.white
                                                    : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('AC',
                                                  style: TextStyle( fontSize: bfont,fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("7"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                backgroundColor: widget.isDarkMode
                                                    ? const Color(0xFF2A2A2A)
                                                    : Colors.white,
                                                foregroundColor: widget.isDarkMode
                                                    ? Colors.white
                                                    : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('7',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("4"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                backgroundColor: widget.isDarkMode
                                                    ? const Color(0xFF2A2A2A)
                                                    : Colors.white,
                                                foregroundColor: widget.isDarkMode
                                                    ? Colors.white
                                                    : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('4',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("1"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                  backgroundColor: widget.isDarkMode
                                                      ? const Color(0xFF2A2A2A)
                                                      : Colors.white,
                                                  foregroundColor: widget.isDarkMode
                                                      ? Colors.white
                                                      : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('1',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("00"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                  backgroundColor: widget.isDarkMode
                                                      ? const Color(0xFF2A2A2A)
                                                      : Colors.white,
                                                  foregroundColor: widget.isDarkMode
                                                      ? Colors.white
                                                      : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('00',
                                                  style: TextStyle(fontSize: bfont, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("C"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                 backgroundColor: widget.isDarkMode
                                                   ? const Color(0xFF2A2A2A)
                                                      : Colors.lightBlueAccent,
                                                    foregroundColor: widget.isDarkMode
                                                   ? Colors.white
                                                       : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('C',
                                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("8"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                 backgroundColor: widget.isDarkMode
                                                ? const Color(0xFF2A2A2A)
                                                   : Colors.white,
                                                      foregroundColor: widget.isDarkMode
                                                    ? Colors.white
                                                        : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('8',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("5"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                backgroundColor: widget.isDarkMode
                                                  ? const Color(0xFF2A2A2A)
                                               : Colors.white,
                                              foregroundColor: widget.isDarkMode
                                                ? Colors.white
                                                     : Colors.black54,
                                                 shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('5',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("2"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                  backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white, foregroundColor: widget.isDarkMode ? Colors.white  : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('2',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("0"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                  backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white, foregroundColor: widget.isDarkMode ? Colors.white : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('0',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("%"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                 backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.lightBlueAccent, foregroundColor: widget.isDarkMode ? Colors.white : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('%',
                                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("9"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                               backgroundColor: widget.isDarkMode  ? const Color(0xFF2A2A2A) : Colors.white, foregroundColor: widget.isDarkMode ? Colors.white : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('9',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("6"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                   backgroundColor: widget.isDarkMode
                                                    ? const Color(0xFF2A2A2A) : Colors.white, foregroundColor: widget.isDarkMode ? Colors.white : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('6',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("3"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                 backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white, foregroundColor: widget.isDarkMode ? Colors.white : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('3',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: ()=> onButtonPressed("."),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6, backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white, foregroundColor: widget.isDarkMode ? Colors.white : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('.',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("/"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                   backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.lightBlueAccent, foregroundColor: widget.isDarkMode ? Colors.white : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('/',
                                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("X"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                               backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.lightBlueAccent, foregroundColor: widget.isDarkMode ? Colors.white : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('X',
                                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("-"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6, backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) :Colors.lightBlueAccent, foregroundColor: widget.isDarkMode ? Colors.white : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('-',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("+"),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                               backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.lightBlueAccent, foregroundColor: widget.isDarkMode ? Colors.white : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('+',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          child: SizedBox(
                                            width: 80,
                                            child: ElevatedButton(
                                              onPressed: () => onButtonPressed("="),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 6,
                                                  backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.lightBlueAccent, foregroundColor: widget.isDarkMode ? Colors.white : Colors.black54,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text('=',
                                                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:math_expressions/math_expressions.dart';

void main() {
  Parser p = Parser();
  try {
    print(p.parse("asin(1)").evaluate(EvaluationType.REAL, ContextModel()));
  } catch (e) { print("asin failed: $e"); }
  try {
    print(p.parse("arcsin(1)").evaluate(EvaluationType.REAL, ContextModel()));
  } catch (e) { print("arcsin failed: $e"); }
  try {
    print(p.parse("log(10)").evaluate(EvaluationType.REAL, ContextModel()));
  } catch (e) { print("log failed: $e"); }
  try {
    print(p.parse("log(10, 100)").evaluate(EvaluationType.REAL, ContextModel()));
  } catch (e) { print("log(10, 100) failed: $e"); }
  try {
    print(p.parse("ln(10)").evaluate(EvaluationType.REAL, ContextModel()));
  } catch (e) { print("ln failed: $e"); }
}

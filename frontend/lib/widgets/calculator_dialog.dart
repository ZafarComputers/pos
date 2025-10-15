import 'package:flutter/material.dart';

class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '0';
  String _expression = '';
  String _previousValue = '';
  String _operation = '';
  bool _isNewValue = true;

  void _onNumberPressed(String number) {
    setState(() {
      if (_isNewValue) {
        _display = number;
        _isNewValue = false;
      } else {
        if (_display == '0') {
          _display = number;
        } else {
          _display += number;
        }
      }
      _updateExpression();
    });
  }

  void _onOperationPressed(String operation) {
    setState(() {
      if (_previousValue.isNotEmpty && !_isNewValue) {
        _calculate();
      }
      _previousValue = _display;
      _operation = operation;
      _isNewValue = true;
      _updateExpression();
    });
  }

  void _updateExpression() {
    if (_previousValue.isNotEmpty && _operation.isNotEmpty && !_isNewValue) {
      // Show full expression: previous + operation + current
      _expression = '$_previousValue $_operation $_display';
    } else if (_previousValue.isNotEmpty &&
        _operation.isNotEmpty &&
        _isNewValue) {
      // Show operation waiting for next number: previous + operation
      _expression = '$_previousValue $_operation';
    } else {
      // Just show current display
      _expression = _display;
    }
  }

  void _calculate() {
    double result = 0;
    double prev = double.tryParse(_previousValue) ?? 0;
    double current = double.tryParse(_display) ?? 0;

    switch (_operation) {
      case '+':
        result = prev + current;
        break;
      case '-':
        result = prev - current;
        break;
      case '×':
        result = prev * current;
        break;
      case '÷':
        if (current != 0) {
          result = prev / current;
        } else {
          _display = 'Error';
          _expression = 'Error';
          return;
        }
        break;
    }

    _display = _formatResult(result);
    _expression = _display;
    _previousValue = '';
    _operation = '';
  }

  String _formatResult(double result) {
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result.toStringAsFixed(2);
    }
  }

  void _onEqualsPressed() {
    setState(() {
      if (_previousValue.isNotEmpty && _operation.isNotEmpty) {
        _calculate();
        _isNewValue = true;
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _expression = '';
      _previousValue = '';
      _operation = '';
      _isNewValue = true;
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
        _isNewValue = true;
      }
      _updateExpression();
    });
  }

  void _onDecimalPressed() {
    setState(() {
      if (_isNewValue) {
        _display = '0.';
        _isNewValue = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
      _updateExpression();
    });
  }

  Widget _buildButton(String text, {Color? color, VoidCallback? onPressed}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? const Color(0xFF0D1845),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.calculate, color: Color(0xFF0D1845)),
                const SizedBox(width: 8),
                const Text(
                  'Calculator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1845),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _expression.isNotEmpty ? _expression : _display,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1845),
                ),
                textAlign: TextAlign.right,
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Column(
              children: [
                // Row 1: Clear, Backspace, ÷
                Row(
                  children: [
                    _buildButton(
                      'C',
                      color: Colors.red,
                      onPressed: _onClearPressed,
                    ),
                    _buildButton(
                      '⌫',
                      color: Colors.orange,
                      onPressed: _onBackspacePressed,
                    ),
                    _buildButton(
                      '÷',
                      color: Colors.teal,
                      onPressed: () => _onOperationPressed('÷'),
                    ),
                  ],
                ),

                // Row 2: 7, 8, 9, ×
                Row(
                  children: [
                    _buildButton('7', onPressed: () => _onNumberPressed('7')),
                    _buildButton('8', onPressed: () => _onNumberPressed('8')),
                    _buildButton('9', onPressed: () => _onNumberPressed('9')),
                    _buildButton(
                      '×',
                      color: Colors.teal,
                      onPressed: () => _onOperationPressed('×'),
                    ),
                  ],
                ),

                // Row 3: 4, 5, 6, -
                Row(
                  children: [
                    _buildButton('4', onPressed: () => _onNumberPressed('4')),
                    _buildButton('5', onPressed: () => _onNumberPressed('5')),
                    _buildButton('6', onPressed: () => _onNumberPressed('6')),
                    _buildButton(
                      '-',
                      color: Colors.teal,
                      onPressed: () => _onOperationPressed('-'),
                    ),
                  ],
                ),

                // Row 4: 1, 2, 3, +
                Row(
                  children: [
                    _buildButton('1', onPressed: () => _onNumberPressed('1')),
                    _buildButton('2', onPressed: () => _onNumberPressed('2')),
                    _buildButton('3', onPressed: () => _onNumberPressed('3')),
                    _buildButton(
                      '+',
                      color: Colors.teal,
                      onPressed: () => _onOperationPressed('+'),
                    ),
                  ],
                ),

                // Row 5: 0, ., =
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        child: ElevatedButton(
                          onPressed: () => _onNumberPressed('0'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D1845),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text(
                            '0',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildButton('.', onPressed: _onDecimalPressed),
                    _buildButton(
                      '=',
                      color: Colors.green,
                      onPressed: _onEqualsPressed,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

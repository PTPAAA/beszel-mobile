import 'package:flutter/material.dart';
import 'package:beszel_pro/services/pin_service.dart';
import 'package:easy_localization/easy_localization.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;
  final void Function(BuildContext context)? onSuccess;

  const PinScreen({super.key, required this.isSetup, this.onSuccess});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _confirmedPin = '';
  bool _isConfirming = false;
  String _message = '';
  final PinService _pinService = PinService();

  @override
  void initState() {
    super.initState();
    _message = widget.isSetup ? 'Create PIN' : 'Enter PIN';
  }

  void _handleKeyPress(String value) {
    if (_pin.length < 4) {
      setState(() {
        _pin += value;
      });
      if (_pin.length == 4) {
        _submitPin();
      }
    }
  }

  void _handleDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _submitPin() async {
    if (widget.isSetup) {
      if (_isConfirming) {
        if (_pin == _confirmedPin) {
          await _pinService.setPin(_pin);
          if (mounted) {
             if (widget.onSuccess != null) {
               widget.onSuccess!(context);
             } else {
               Navigator.of(context).pop(true);
             }
          }
        } else {
          setState(() {
            _message = 'PINs do not match. Try again.';
            _pin = '';
            _confirmedPin = '';
            _isConfirming = false;
          });
        }
      } else {
        setState(() {
          _confirmedPin = _pin;
          _pin = '';
          _isConfirming = true;
          _message = 'Confirm PIN';
        });
      }
    } else {
      // Verify
      final isValid = await _pinService.verifyPin(_pin);
      if (isValid) {
        if (mounted) {
           if (widget.onSuccess != null) {
             widget.onSuccess!(context);
           } else {
             Navigator.of(context).pop(true);
           }
        }
      } else {
        setState(() {
          _message = 'Incorrect PIN';
          _pin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              _message,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            const Spacer(),
            // Numeric Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildKey('1'),
                      _buildKey('2'),
                      _buildKey('3'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildKey('4'),
                      _buildKey('5'),
                      _buildKey('6'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildKey('7'),
                      _buildKey('8'),
                      _buildKey('9'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 80), // Empty space for alignment
                      _buildKey('0'),
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: IconButton(
                          onPressed: _handleDelete,
                          icon: const Icon(Icons.backspace_outlined),
                          iconSize: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String value) {
    return SizedBox(
      width: 80,
      height: 80,
      child: TextButton(
        onPressed: () => _handleKeyPress(value),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.grey.withOpacity(0.1),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 32,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}

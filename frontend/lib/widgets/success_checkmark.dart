import 'package:flutter/material.dart';

class SuccessCheckmark extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;
  final bool showCloseButton;

  const SuccessCheckmark({
    Key? key,
    required this.message,
    this.onClose,
    this.showCloseButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 80,
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A5F),
              ),
            ),
          ),
          if (showCloseButton) ...[
            const SizedBox(height: 30),
            IconButton(
              onPressed: onClose ?? () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              iconSize: 30,
              color: const Color(0xFF1E3A5F),
            ),
          ],
        ],
      ),
    );
  }
}

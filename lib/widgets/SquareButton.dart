import 'package:flutter/material.dart';

class SquareButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  const SquareButton({
    super.key,
    required this.child,
    required this.onPressed,
  });

  @override
  State<SquareButton> createState() => _SquareButtonState();
}

class _SquareButtonState extends State<SquareButton> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 4, color: Colors.amber),
            borderRadius: BorderRadius.circular(0),
          ),
          foregroundColor: Colors.white),
      onPressed: widget.onPressed,
      child: widget.child,
    );
  }
}

import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String text;
  final String hintText;
  final TextInputType textInputType;
  final TextAlign textAlign;
  final Function(String) onSubmitted;
  final double fontSize;
  final Function(String) onChanged;

  const MyTextField({
    Key? key,
    required this.text,
    required this.hintText,
    required this.onSubmitted,
    required this.onChanged,
    this.textInputType = TextInputType.number,
    this.textAlign = TextAlign.start,
    this.fontSize = 16,
  }) : super(key: key);

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: widget.text),
      keyboardType: widget.textInputType,
      textAlign: widget.textAlign,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
      style: TextStyle(
        fontSize: widget.fontSize,
      ),
      onChanged: (newVal) => widget.onChanged(newVal),
      onSubmitted: (newVal) => widget.onSubmitted(newVal),
    );
  }
}

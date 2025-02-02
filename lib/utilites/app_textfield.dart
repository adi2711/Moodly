import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword; // To control if it si a password
  final IconData icon;
  final String hint;
  final VoidCallback? helpOnTap;
  final Widget? helpContent;

  const AppTextField({super.key, 
    required this.icon,
    required this.hint,
    required this.controller, // capturing user input is mandatory
    this.isPassword = false, // not must for all
    this.keyboardType = TextInputType.text, // default to register text input
    this.helpOnTap,
    this.helpContent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            prefixIcon: Icon(icon),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black12),
            ),
          ),
        ),
        if (helpContent != null && helpOnTap != null)
          SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: helpOnTap,
                child: helpContent,
              ),
            ),
          )
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:nn_clippers/nn_clippers.dart';

class TestClipper extends StatefulWidget {
  const TestClipper({super.key});

  @override
  State<TestClipper> createState() => _TestClipperState();
}

class _TestClipperState extends State<TestClipper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: ClipPath(
          clipper: const WaveClipperTwo(reverse: false),
          child: Container(
            color: Colors.amber,
            width: 500,
            height: 270,
            // your widget contents
          ),
        ),
      ),
    );
  }
}

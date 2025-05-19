import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:rxdart/rxdart.dart';

class SpinWheel extends StatefulWidget {
  const SpinWheel({Key? key}) : super(key: key);

  @override
  State<SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<SpinWheel> {
  final selected = BehaviorSubject<int>();
  String rewards = '';

  List<String> items = [
    'Travel Insurance',
    'Loyalty Points',
    'City Tour Voucher',
    'Free Booking',
    'Room Upgrade'
  ];

  List<Color> colors = [
    Colors.blue,
    const Color.fromARGB(255, 53, 192, 7),
    const Color.fromARGB(255, 255, 59, 219),
    const Color.fromARGB(255, 233, 30, 30),
    Colors.orange,
  ];

  @override
  void dispose() {
    selected.close();
    super.dispose();
  }

  void _showWinningDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("You won!"),
          content: Text("You just won " + rewards + "!"),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spin the Wheel'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add heading at the top of the page
            Text(
              "Spin the Wheel",
              style: TextStyle(
                fontSize: 50, // Font size
                fontWeight: FontWeight.bold, // Font weight
                color: Colors.black, // Font color
              ),
            ),
            SizedBox(height: 100), // Space between heading and wheel
            SizedBox(
              height: 350,
              child: FortuneWheel(
                selected: selected.stream,
                animateFirst: false,
                items: [
                  for (int i = 0; i < items.length; i++) ...<FortuneItem>{
                    FortuneItem(
                      child: Text(items[i]),
                      style: FortuneItemStyle(
                        color: colors[i], // Set the color for each item
                      ),
                    ),
                  },
                ],
                onAnimationEnd: () {
                  setState(() {
                    rewards = items[selected.value];
                  });
                  _showWinningDialog(); // Show dialog when animation ends
                },
              ),
            ),
            // Add a SizedBox to increase space between the wheel and the button
            SizedBox(height: 70), // Adjust this height as needed
            GestureDetector(
              onTap: () {
                setState(() {
                  selected.add(Fortune.randomInt(0, items.length));
                });
              },
              child: Container(
                height: 40,
                width: 120,
                color: Colors.redAccent,
                child: Center(
                  child: Text("SPIN"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
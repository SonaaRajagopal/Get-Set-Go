import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';

class ScratchCard extends StatefulWidget {
  const ScratchCard({Key? key}) : super(key: key);

  @override
  _ScratchCardState createState() => _ScratchCardState();
}

class _ScratchCardState extends State<ScratchCard> {
  final scratchKey = GlobalKey<ScratcherState>();
  double _opacity = 0.0;
  double _progress = 0.0; // Variable to track scratching progress

  void resetScratchCard() {
    setState(() {
      _opacity = 0.0; // Reset opacity
      _progress = 0.0; // Reset progress
      scratchKey.currentState?.reset(); // Reset the Scratcher state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scratch Card'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                scratchDialog(context);
              },
              child: Text(
                'Scratch the card to win a prize!',
                style: TextStyle(fontSize: 20), // Change the font size here
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> scratchDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          title: const Align(
            alignment: Alignment.center,
            child: Text(
              'Congratulations, You earned a reward..!',
              style: TextStyle(fontSize: 30),
            ),
          ),
          content: StatefulBuilder(
            builder: (context, StateSetter setState) {
              return Scratcher(
                key: scratchKey,
                accuracy: ScratchAccuracy.medium,
                threshold: 50, // The threshold to show reward fully
                onThreshold: () {
                  // When the scratching reaches the threshold
                  setState(() {
                    _opacity = 1.0; // Set opacity to 1
                  });
                },
                color: Colors.redAccent,
                onChange: (value) {
                  setState(() {
                    _progress = value; // Update scratching progress
                  });
                  print('Progress $value%');
                },
                brushSize: 20,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 1000),
                  opacity: _opacity,
                  child: Container(
                    width: 150,
                    height: 150,
                    child: const Image(
                      image: AssetImage(
                          'assets/Scratchcard.png'), // Your scratch card image
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Back',
                style: TextStyle(fontSize: 18), // Increase font size here
              ),
            ),
            TextButton(
              onPressed: () {
                // Check if the card has been scratched and allow claims under certain conditions
                if (_progress > 0 && _progress < 50) {
                  // Allow user to claim if they've partially scratched the card
                  showClaimDialog(context, 'You have claimed Rs. 50!');
                } else if (_progress >= 50) {
                  // Allow user to claim if they have scratched fully
                  showClaimDialog(context, 'You have claimed Rs. 50!');
                } else {
                  // Show alert if the card hasn't been scratched yet
                  showAlertDialog(
                      context, 'First scratch the card to know the surprise!');
                }
              },
              child: const Text(
                'Claim',
                style: TextStyle(fontSize: 18), // Increase font size here
              ),
            ),
            TextButton(
              onPressed: () {
                resetScratchCard(); // Call reset function to reset the scratch card
              },
              child: const Text(
                'Reset',
                style: TextStyle(fontSize: 18), // Increase font size here
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to show claim dialog
  void showClaimDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Claim'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the claim dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to show alert dialog
  void showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert!'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
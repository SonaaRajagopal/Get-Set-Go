import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'signup.dart';
import 'homepage.dart' as homepage;
import 'currencyconverter_material.dart';
import 'travel_chatbot_page.dart';
import 'main_vr.dart';
import 'consts.dart';
import 'camera_view.dart';
import 'login.dart';
import 'main_landmarkdetection.dart';
import 'expense_tracker_page.dart';
import 'scratch_card.dart';
import 'spin_wheel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Gemini.init(apiKey: GEMINI_API_KEY);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/home': (context) => homepage.HomePage(),
        '/currency-converter': (context) =>
            const CurrencyConverterMaterialPage(),
        '/travel-chatbot': (context) => TravelChatbotPage(),
        '/camera': (context) => const CameraView(),
        '/vr-tour': (context) => const TourismApp(),
        '/scratch-card': (context) => const ScratchCard(),
        '/spin-wheel': (context) => const SpinWheel(),
        '/expense-tracker': (context) => const ExpenseTrackerPage(),
        '/landmark-detection': (context) =>
            FutureBuilder<List<CameraDescription>>(
              future: availableCameras(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ImageClassificationPage(cameras: snapshot.data!);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginPage();
          }
          return const homepage.HomePage();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

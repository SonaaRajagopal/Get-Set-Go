import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_page.dart';
import 'currencyconverter_material.dart';
import 'travel_chatbot_page.dart';
import 'expense_tracker_page.dart';
import 'main_vr.dart';
import 'main_landmarkdetection.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.purple[100]!, Colors.purple[400]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _buildBody(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Travel Companion',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 40),
            Text(
              'Explore & Travel',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            _buildFeatureGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildFeatureCard(
          context,
          'Chat',
          Icons.chat_bubble_outline,
          () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => ChatPage())),
        ),
        _buildFeatureCard(
          context,
          'Currency',
          Icons.currency_exchange,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CurrencyConverterMaterialPage())),
        ),
        _buildFeatureCard(
          context,
          'Travel Guide',
          Icons.chat,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => TravelChatbotPage())),
        ),
        _buildFeatureCard(
          context,
          '       Scratch Card',
          Icons.card_giftcard,
          () => Navigator.pushNamed(context, '/scratch-card'),
        ),
        _buildFeatureCard(
          context,
          'Spin the Wheel',
          Icons.casino,
          () => Navigator.pushNamed(context, '/spin-wheel'),
        ),
        _buildFeatureCard(
          context,
          'Expenses',
          Icons.account_balance_wallet,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => ExpenseTrackerPage())),
        ),
        _buildFeatureCard(
          context,
          'VR Tours',
          Icons.vrpano,
          () async {
            final cameras = await availableCameras();
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => TourismApp()));
          },
        ),
        _buildFeatureCard(
          context,
          'Landmarks',
          Icons.camera_alt,
          () async {
            final cameras = await availableCameras();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ImageClassificationPage(cameras: cameras)));
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, String text, IconData icon,
      VoidCallback onPressed) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.purple[300]!, Colors.purple[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildMenuItem(context, 'Chat System', Icons.chat_bubble_outline,
                  () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ChatPage()));
              }),
              _buildMenuItem(
                  context, 'Currency Converter', Icons.currency_exchange, () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CurrencyConverterMaterialPage()));
              }),
              _buildMenuItem(context, 'Travel Guide', Icons.chat, () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TravelChatbotPage()));
              }),
              _buildMenuItem(
                  context, 'Expense Tracker', Icons.account_balance_wallet, () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ExpenseTrackerPage()));
              }),
              _buildMenuItem(context, 'VR World Tours', Icons.vrpano, () async {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => TourismApp()));
              }),
              _buildMenuItem(
                  context, 'Landmark Detection', Icons.camera_enhance,
                  () async {
                Navigator.pop(context);
                final cameras = await availableCameras();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ImageClassificationPage(cameras: cameras)),
                );
              }),
              _buildMenuItem(context, 'Logout', Icons.exit_to_app, () {
                Navigator.pop(context);
                _logout(context);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple[700]),
      title: Text(title, style: GoogleFonts.poppins()),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'vr_preview_page.dart';

void main() {
  runApp(const TourismApp());
}

class TourismApp extends StatelessWidget {
  const TourismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World Wonders VR Tour',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        cardTheme: const CardTheme(
          elevation: 4,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      home: const HomePages(),
    );
  }
}

class Wonder {
  final String name;
  final String videoUrl;
  final String description;
  final String imageAsset;

  const Wonder({
    required this.name,
    required this.videoUrl,
    required this.description,
    required this.imageAsset,
  });
}

class HomePages extends StatelessWidget {
  const HomePages({super.key});

  static const List<Wonder> wonders = [
    Wonder(
      name: 'Great Wall of China',
      videoUrl: 'https://www.youtube.com/watch?v=AOK-DaUXDSc',
      description:
          'An ancient wall spanning thousands of miles, built over centuries.',
      imageAsset: 'assets/gtchina.jpg',
    ),
    Wonder(
      name: 'Christ the Redeemer',
      videoUrl: 'https://www.youtube.com/watch?v=AcYPaVvNBAw',
      description:
          'A colossal statue of Jesus at the summit of Mount Corcovado.',
      imageAsset: 'assets/christ.jpg',
    ),
    Wonder(
      name: 'Machu Picchu',
      videoUrl: 'https://www.youtube.com/watch?v=77hJtIrMJ7g',
      description: 'A 15th-century Inca citadel located in the Peruvian Andes.',
      imageAsset: 'assets/machu.jpg',
    ),
    Wonder(
      name: 'Chichen Itza',
      videoUrl: 'https://www.youtube.com/watch?v=rDPAfbfPh_0',
      description:
          'A large pre-Columbian archaeological site built by the Maya civilization.',
      imageAsset: 'assets/itza.jpg',
    ),
    Wonder(
      name: 'Roman Colosseum',
      videoUrl: 'https://www.youtube.com/watch?v=tsP5ixLxl3M',
      description:
          'An ancient amphitheater in Rome, known for gladiatorial battles.',
      imageAsset: 'assets/colosseum.jpg',
    ),
    Wonder(
      name: 'Taj Mahal',
      videoUrl: 'https://www.youtube.com/watch?v=8HV1JVgqPM0',
      description:
          'A stunning marble mausoleum built in memory of Mumtaz Mahal.',
      imageAsset: 'assets/tj.jpg',
    ),
    Wonder(
      name: 'Petra',
      videoUrl: 'https://www.youtube.com/watch?v=SAUI1-D6tgs',
      description:
          'A historical and archaeological city famous for its rock-cut architecture.',
      imageAsset: 'assets/petra.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('7 Wonders of the World'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: wonders.length,
        itemBuilder: (context, index) {
          final wonder = wonders[index];
          return WonderCard(wonder: wonder);
        },
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About VR Tour'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Experience the Seven Wonders of the World in VR!'),
            SizedBox(height: 16),
            Text('• Tap any wonder to start the VR experience'),
            Text('• Toggle VR mode using the VR button'),
            Text('• Use landscape mode for best viewing'),
            Text('• Compatible with most VR headsets'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class WonderCard extends StatelessWidget {
  final Wonder wonder;

  const WonderCard({
    super.key,
    required this.wonder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _openVRPreview(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  wonder.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wonder.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wonder.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.vrpano),
                        label: const Text('Start VR Tour'),
                        onPressed: () => _openVRPreview(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVRPreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VRPreviewPage(videoUrl: wonder.videoUrl),
      ),
    );
  }
}

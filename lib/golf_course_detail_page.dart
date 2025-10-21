import 'package:flutter/material.dart';
import 'dart:convert';

class GolfCourseDetailPage extends StatelessWidget {
  final Map<String, dynamic> course;
  const GolfCourseDetailPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final name = course['name'] ?? 'Unknown';
    final tags = course['tags'] as Map<String, dynamic>?;
    final city = tags != null && tags['addr:city'] is String ? tags['addr:city'] as String : null;
    final address = tags != null && tags['addr:street'] is String ? tags['addr:street'] as String : null;
    final website = tags != null && tags['website'] is String ? tags['website'] as String : null;
    final phone = tags != null && tags['phone'] is String ? tags['phone'] as String : null;
    final lat = course['lat'];
    final lon = course['lon'];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(name, style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ],
              ),
              if (city != null) ...[
                const SizedBox(height: 8),
                Text('City: $city'),
              ],
              if (address != null) ...[
                const SizedBox(height: 8),
                Text('Address: $address'),
              ],
              if (phone != null) ...[
                const SizedBox(height: 8),
                Text('Phone: $phone'),
              ],
              if (website != null) ...[
                const SizedBox(height: 8),
                Text('Website: $website'),
              ],
              if (lat != null && lon != null) ...[
                const SizedBox(height: 8),
                Text('Location: ($lat, $lon)'),
              ],
              const SizedBox(height: 24),
              const Text('All course data:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  color: Colors.grey[200],
                  child: SingleChildScrollView(
                    child: Text(const JsonEncoder.withIndent('  ').convert(course)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

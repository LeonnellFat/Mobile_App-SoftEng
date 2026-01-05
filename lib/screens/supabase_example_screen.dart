import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SupabaseExampleScreen extends StatelessWidget {
  const SupabaseExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Products')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text('No products'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final title =
                  item['name'] ?? item['title'] ?? 'Item ${index + 1}';
              final price = item['price']?.toString() ?? '';
              return ListTile(
                title: Text(title.toString()),
                subtitle: price.isNotEmpty ? Text('Price: \$$price') : null,
              );
            },
          );
        },
      ),
    );
  }
}

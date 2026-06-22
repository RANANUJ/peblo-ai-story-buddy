import 'package:flutter/material.dart';
import '../core/theme/peblo_theme.dart';
import '../features/story_buddy/presentation/screens/story_buddy_screen.dart';

class PebloApp extends StatelessWidget {
  const PebloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peblo AI Story Buddy',
      theme: PebloTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const StoryBuddyScreen(),
      },
    );
  }
}

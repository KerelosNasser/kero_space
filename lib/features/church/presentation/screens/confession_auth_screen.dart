import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/confession_bloc.dart';

class ConfessionAuthScreen extends StatefulWidget {
  const ConfessionAuthScreen({super.key});

  @override
  State<ConfessionAuthScreen> createState() => _ConfessionAuthScreenState();
}

class _ConfessionAuthScreenState extends State<ConfessionAuthScreen> {
  final TextEditingController _passphraseController = TextEditingController();

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // --bg-primary
      appBar: AppBar(
        title: const Text('Unlock Confessions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<ConfessionBloc, ConfessionState>(
        listener: (context, state) {
          if (state is ConfessionUnlocked) {
            Navigator.of(context).pushReplacementNamed('/confessions_log');
          } else if (state is ConfessionUnlockFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to unlock. Wrong passphrase?')),
            );
          }
        },
        builder: (context, state) {
          if (state is ConfessionUnlocking) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFBF5AF2)));
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.white),
                const SizedBox(height: 32),
                const Text(
                  'Enter Passphrase',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your confessions are encrypted locally using AES-256-GCM. The key is never stored.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _passphraseController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Passphrase',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBF5AF2), // --accent-violet
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_passphraseController.text.isNotEmpty) {
                        context.read<ConfessionBloc>().add(UnlockConfessionSession(_passphraseController.text));
                      }
                    },
                    child: const Text('Unlock', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

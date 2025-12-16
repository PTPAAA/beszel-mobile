import 'package:flutter/material.dart';
import 'package:beszel_pro/services/pocketbase_service.dart';
import 'package:beszel_pro/screens/pin_screen.dart';
import 'package:beszel_pro/services/pin_service.dart';
import 'package:pocketbase/pocketbase.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final model = PocketBaseService().pb.authStore.model;
    if (model is RecordModel) {
      _email = model.data['email'] ?? model.id;
    } else {
      // Fallback for AdminModel or other types
      try {
        _email = (model as dynamic)?.email ?? '';
      } catch (_) {}
    }
    setState(() {});
  }

  Future<void> _handlePinParams() async {
    final isSet = await PinService().isPinSet();
    if (!mounted) return;

    if (isSet) {
      // Verify old PIN first
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PinScreen(isSetup: false)),
      );

      if (verified == true) {
        if (!mounted) return;
        // Proceed to set new PIN
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PinScreen(isSetup: true)),
        );
      }
    } else {
      // Set new PIN directly
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PinScreen(isSetup: true)),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Information'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 40),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _email,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('PIN Code'),
            subtitle: const Text('Set or change your app PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handlePinParams,
          ),

        ],
      ),
    );
  }
}

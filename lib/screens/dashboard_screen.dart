import 'package:beszel_pro/models/system.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:beszel_pro/screens/system_detail_screen.dart';
import 'package:beszel_pro/services/pocketbase_service.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:beszel_pro/screens/setup_screen.dart';
import 'package:beszel_pro/providers/app_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beszel_pro/screens/login_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:beszel_pro/services/notification_service.dart';
import 'package:beszel_pro/services/alert_manager.dart';
import 'package:beszel_pro/screens/alerts_screen.dart';
import 'package:beszel_pro/screens/user_info_screen.dart';
import 'package:beszel_pro/services/pin_service.dart';

enum SortOption { name, cpu, ram, disk }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<System> _systems = [];
  bool _isLoading = true;
  String? _error;
  SortOption _currentSort = SortOption.name; // Default sort
  Timer? _pollingTimer;

  void _sortSystems() {
    switch (_currentSort) {
      case SortOption.name:
        _systems.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.cpu:
        // Descending for metrics usually makes more sense
        _systems.sort((a, b) => b.cpuPercent.compareTo(a.cpuPercent));
        break;
      case SortOption.ram:
        _systems.sort((a, b) => b.memoryPercent.compareTo(a.memoryPercent));
        break;
      case SortOption.disk:
        _systems.sort((a, b) => b.diskPercent.compareTo(a.diskPercent));
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('Dashboard: initState');
    
    // Defer heavy services until after the first frame rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Dashboard: PostFrameCallback - Starting Services');
      NotificationService().initialize();
      AlertManager().loadAlerts();
      _fetchSystems();
      _subscribeToRealtime();
      
      // Polling fallback: every 5 seconds
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _pollSystems();
      });
    });
  }

  Future<void> _pollSystems() async {
    // Silent fetch
    try {
      final pb = PocketBaseService().pb;
      final records = await pb.collection('systems').getFullList(sort: '-updated');
      if (!mounted) return;
      
      final newSystems = records.map((r) => System.fromRecord(r)).toList();
      setState(() {
        for (var newSys in newSystems) {
           final index = _systems.indexWhere((s) => s.id == newSys.id);
           if (index != -1) {
             final oldSys = _systems[index];
             _checkAlerts(oldSys, newSys);
             _systems[index] = newSys;
           } else {
             _systems.add(newSys);
           }
        }
        _sortSystems();
      });
    } catch (_) {}
  }

  void _checkAlerts(System oldSystem, System newSystem) {
      // 1. Check for DOWN status
      if (oldSystem.status == 'up' && newSystem.status == 'down') {
        _triggerAlert(newSystem, tr('alert_system_down_title'), tr('alert_system_down_body', args: [newSystem.name]), 'error');
      }
      // 2. Check for High CPU (80%)
      if (newSystem.cpuPercent > 80 && oldSystem.cpuPercent <= 80) {
          _triggerAlert(newSystem, tr('alert_high_cpu_title'), tr('alert_high_cpu_body', args: [newSystem.name, newSystem.cpuPercent.toStringAsFixed(1)]), 'warning');
      }
      // 3. Check for High RAM (80%)
      if (newSystem.memoryPercent > 80 && oldSystem.memoryPercent <= 80) {
          _triggerAlert(newSystem, tr('alert_high_ram_title'), tr('alert_high_ram_body', args: [newSystem.name, newSystem.memoryPercent.toStringAsFixed(1)]), 'warning');
      }
      // 4. Check for High Disk (80%)
      if (newSystem.diskPercent > 80 && oldSystem.diskPercent <= 80) {
          _triggerAlert(newSystem, tr('alert_high_disk_title'), tr('alert_high_disk_body', args: [newSystem.name, newSystem.diskPercent.toStringAsFixed(1)]), 'warning');
      }
  }

  void _checkInitialAlerts() {
    for (final system in _systems) {
      // 1. Check for DOWN status
      if (system.status == 'down') {
         _triggerAlert(system, tr('alert_system_down_title'), tr('alert_system_down_body', args: [system.name]), 'error');
      }
      // 2. Check for High CPU (80%)
      if (system.cpuPercent > 80) {
          _triggerAlert(system, tr('alert_high_cpu_title'), tr('alert_high_cpu_body', args: [system.name, system.cpuPercent.toStringAsFixed(1)]), 'warning');
      }
      // 3. Check for High RAM (80%)
      if (system.memoryPercent > 80) {
          _triggerAlert(system, tr('alert_high_ram_title'), tr('alert_high_ram_body', args: [system.name, system.memoryPercent.toStringAsFixed(1)]), 'warning');
      }
      // 4. Check for High Disk (80%)
      if (system.diskPercent > 80) {
          _triggerAlert(system, tr('alert_high_disk_title'), tr('alert_high_disk_body', args: [system.name, system.diskPercent.toStringAsFixed(1)]), 'warning');
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _unsubscribeFromRealtime();
    super.dispose();
  }

  Future<void> _fetchSystems() async {
    try {
      final pb = PocketBaseService().pb;
      final records = await pb.collection('systems').getFullList(
            sort: '-updated',
          );

      if (records.isNotEmpty) {
        debugPrint('SYSTEM RECORD RAW DATA: ${records.first.data}');
      }

      if (mounted) {
        setState(() {
          _systems = records.map((r) => System.fromRecord(r)).toList();
          _sortSystems();
          _checkInitialAlerts();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load systems: $e';
          _isLoading = false;
        });
      }
    }
  }



  // ... 

  Future<void> _subscribeToRealtime() async {
    try {
      final pb = PocketBaseService().pb;
      pb.collection('systems').subscribe('*', (e) {
        if (!mounted) return;

        if (e.action == 'create') {
          setState(() {
            _systems.insert(0, System.fromRecord(e.record!));
          });
        } else if (e.action == 'update') {
          debugPrint('REALTIME EVENT: ${e.record!.data}');
          final updatedSystem = System.fromRecord(e.record!);
          debugPrint('UPDATED STATS: CPU=${updatedSystem.cpuPercent}, RAM=${updatedSystem.memoryPercent}');
          
          setState(() {
            final index = _systems.indexWhere((s) => s.id == e.record!.id);
            if (index != -1) {
              final oldSystem = _systems[index];
              _checkAlerts(oldSystem, updatedSystem);
              _systems[index] = updatedSystem;
              _sortSystems();
            }
          });

        } else if (e.action == 'delete') {
          setState(() {
            _systems.removeWhere((s) => s.id == e.record!.id);
          });
        }
      });
    } catch (e) {
      debugPrint('Realtime subscription failed: $e');
    }
  }

  void _triggerAlert(System system, String title, String body, String type) {
    // Show local notification
    NotificationService().showNotification(
      id: system.id.hashCode, 
      title: title, 
      body: body
    );
    
    // Save to history
    AlertManager().addAlert(title, body, type, system.name);
  }

  Future<void> _unsubscribeFromRealtime() async {
    try {
      final pb = PocketBaseService().pb;
      await pb.collection('systems').unsubscribe('*');
    } catch (_) {}
  }

  void _logout() async {
    final pb = PocketBaseService().pb;
    pb.authStore.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pb_url');
    await PinService().removePin();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SetupScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onPressed: () {
               showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       ListTile(
                         leading: const Icon(Icons.sort_by_alpha),
                         title: Text(tr('sort_name')),
                         trailing: _currentSort == SortOption.name ? const Icon(Icons.check) : null,
                         onTap: () {
                           setState(() {
                             _currentSort = SortOption.name;
                             _sortSystems();
                           });
                           Navigator.pop(context);
                         },
                       ),
                       ListTile(
                         leading: const Icon(Icons.memory),
                         title: Text(tr('sort_cpu')),
                         trailing: _currentSort == SortOption.cpu ? const Icon(Icons.check) : null,
                         onTap: () {
                           setState(() {
                             _currentSort = SortOption.cpu;
                             _sortSystems();
                           });
                           Navigator.pop(context);
                         },
                       ),
                       ListTile(
                         leading: const Icon(Icons.storage),
                         title: Text(tr('sort_ram')),
                         trailing: _currentSort == SortOption.ram ? const Icon(Icons.check) : null,
                         onTap: () {
                           setState(() {
                             _currentSort = SortOption.ram;
                             _sortSystems();
                           });
                           Navigator.pop(context);
                         },
                       ),
                       ListTile(
                         leading: const Icon(Icons.donut_large),
                         title: Text(tr('disk')), // reused translation or key 'disk'
                         trailing: _currentSort == SortOption.disk ? const Icon(Icons.check) : null,
                         onTap: () {
                           setState(() {
                             _currentSort = SortOption.disk;
                             _sortSystems();
                           });
                           Navigator.pop(context);
                         },
                       ),
                    ],
                  );
                },
               );
            }
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: 'User Menu',
            onSelected: (String value) {
              switch (value) {
                case 'user':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserInfoScreen()),
                  );
                  break;
                case 'theme':
                  final provider = Provider.of<AppProvider>(context, listen: false);
                  provider.toggleTheme(provider.themeMode != ThemeMode.dark);
                  break;
                case 'language':
                  // Show language selector
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        title: const Text('Select Language'),
                        children: [
                          SimpleDialogOption(
                            onPressed: () {
                              context.setLocale(const Locale('en'));
                              Navigator.pop(context);
                            },
                            child: const Text('🇺🇸 English'),
                          ),
                          SimpleDialogOption(
                            onPressed: () {
                              context.setLocale(const Locale('ru'));
                              Navigator.pop(context);
                            },
                            child: const Text('🇷🇺 Русский'),
                          ),
                        ],
                      );
                    },
                  );
                  break;
                case 'logout':
                  _logout();
                  break;
                case 'alerts':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AlertsScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'user',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('User'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'alerts',
                child: ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('Alerts'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'theme',
                child: ListTile(
                  leading: Icon(
                    Provider.of<AppProvider>(context, listen: false).themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  title: const Text('Theme'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'language',
                child: ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Language'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(tr('logout')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : CustomRefreshIndicator(
                  onRefresh: _fetchSystems,
                  builder: (context, child, controller) {
                    return Stack(
                      children: [

                         // For continuous spin during 'loading' state, we might need a separate animation or rely on the controller behavior if configured.
                         // Simple approach: Use logic to spin based on controller.
                         // Better: Use a dedicated SpinningWidget if controller.isLoading.
                         // For now, simple rotation based on pull is good for "pulling". 
                         // For "refreshing", we want it to spin.
                          Positioned(
                            top: 35.0 * controller.value, // Icon vertical pos
                            left: 0,
                            right: 0,
                             child: controller.isLoading
                                ?  const _SpinningIcon()
                                : AnimatedBuilder(
                                  animation: controller,
                                  builder: (context, _) => Transform.rotate(
                                    angle: controller.value * 2 * math.pi,
                                    child: Opacity(
                                      opacity: controller.value.clamp(0.0, 1.0),
                                      child: Image.asset('assets/icon.png', height: 30, width: 30)
                                    )
                                  ),
                                ),
                          ),
                        Transform.translate(
                          offset: Offset(0, 100.0 * controller.value),
                          child: child,
                        ),
                      ],
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _systems.length,
                    itemBuilder: (context, index) {
                      final system = _systems[index];
                      return _SystemCard(system: system);
                    },
                  ),
                ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  final System system;

  const _SystemCard({required this.system});

  Color _getStatusColor(double usage) {
    if (usage < 50) return Colors.green;
    if (usage < 80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SystemDetailScreen(system: system),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      system.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: system.status == 'up' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      system.status.toUpperCase(),
                      style: TextStyle(
                        color: system.status == 'up' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(system.host, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(tr('cpu'), system.cpuPercent, Icons.memory),
                  _buildStat(tr('ram'), system.memoryPercent, Icons.storage),
                  _buildStat(tr('disk'), system.diskPercent, Icons.donut_large),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, double value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _getStatusColor(value), size: 24),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon({super.key});

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Transform.rotate(
        angle: _controller.value * 2 * math.pi,
        child: Image.asset('assets/icon.png', height: 30, width: 30),
      ),
    );
  }
}

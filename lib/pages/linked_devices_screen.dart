import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/device.dart';
 
class LinkedDevicesScreen extends StatelessWidget {
  const LinkedDevicesScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final devices = context.watch<AppProvider>().devices;
 
    return Scaffold(
      appBar: AppBar(title: const Text('Linked Devices')),
      body: devices.isEmpty
          ? _EmptyState(onAdd: () => _showAddDeviceSheet(context))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _DeviceCard(device: devices[i]),
            ),
      floatingActionButton: devices.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddDeviceSheet(context),
              icon:  const Icon(Icons.add),
              label: const Text('Add Device'),
            ),
    );
  }
 
  void _showAddDeviceSheet(BuildContext context) {
    showModalBottomSheet(
      context:       context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddDeviceSheet(),
    );
  }
}
 
// ── Device card ────────────────────────────────────────────────────────────────
 
class _DeviceCard extends StatelessWidget {
  final Device device;
  const _DeviceCard({required this.device});
 
  @override
  Widget build(BuildContext context) {
    final lastSeen = device.lastSeen == null
        ? 'Never'
        : DateFormat('MMM d, h:mm a').format(device.lastSeen!);
 
    return Dismissible(
      key:       ValueKey(device.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color:        Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title:   const Text('Remove Device'),
            content: Text('Remove "${device.name}" from your account?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) {
        context.read<AppProvider>().removeDevice(device.id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color:     Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset:    const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Device icon
            Container(
              width:  52,
              height: 52,
              decoration: BoxDecoration(
                color:        Colors.blueGrey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(device.icon, size: 28, color: Colors.blueGrey.shade700),
            ),
            const SizedBox(width: 14),
 
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    device.type[0].toUpperCase() + device.type.substring(1),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text('Last seen: $lastSeen',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
 
            // Online badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: device.isOnline
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: device.isOnline ? Colors.green.shade300 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle,
                      size:  8,
                      color: device.isOnline ? Colors.green : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    device.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 11,
                      color: device.isOnline ? Colors.green.shade700 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Empty state ────────────────────────────────────────────────────────────────
 
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No devices linked',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add your watch, phone or tablet to get started.',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon:  const Icon(Icons.add),
            label: const Text('Add Device'),
          ),
        ],
      ),
    );
  }
}
 
// ── Add device bottom sheet ────────────────────────────────────────────────────
 
class _AddDeviceSheet extends StatefulWidget {
  const _AddDeviceSheet();
 
  @override
  State<_AddDeviceSheet> createState() => _AddDeviceSheetState();
}
 
class _AddDeviceSheetState extends State<_AddDeviceSheet> {
  final _nameCtrl = TextEditingController();
  String _type    = 'watch';
 
  static const _types = [
    ('watch',  'Watch',  Icons.watch),
    ('phone',  'Phone',  Icons.smartphone),
    ('tablet', 'Tablet', Icons.tablet),
  ];
 
  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await context.read<AppProvider>().addDevice(name: name, type: _type);
    if (mounted) Navigator.pop(context);
  }
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add Device',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
 
          TextField(
            controller:  _nameCtrl,
            autofocus:   true,
            decoration:  const InputDecoration(
              labelText:  'Device name',
              hintText:   'e.g. M11 Watch',
              prefixIcon: Icon(Icons.label_outline),
              border:     OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
 
          const Text('Device type', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
 
          Row(
            children: _types.map((entry) {
              final (value, label, icon) = entry;
              final selected = _type == value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _type = value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(icon,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey),
                          const SizedBox(height: 4),
                          Text(label,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
 
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Add Device', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

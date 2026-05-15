import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Shows `Version x.y.z (build)` from pubspec / platform metadata.
class AppVersionFooter extends StatefulWidget {
  const AppVersionFooter({super.key});

  @override
  State<AppVersionFooter> createState() => _AppVersionFooterState();
}

class _AppVersionFooterState extends State<AppVersionFooter> {
  String _label = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _label = 'Version ${p.version} (${p.buildNumber})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _label = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_label.isEmpty) {
      return const SizedBox(height: 12);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Center(
        child: Text(
          _label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

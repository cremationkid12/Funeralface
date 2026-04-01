import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/app/session/staff_auth.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _logoUrl = TextEditingController();
  final _defaultMessage = TextEditingController();

  var _loading = true;
  String? _error;
  var _saving = false;
  var _scheduledLoad = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _logoUrl.dispose();
    _defaultMessage.dispose();
    super.dispose();
  }

  String? _validateHttpUrl(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final u = Uri.tryParse(t);
    if (u == null || !u.hasScheme || (u.scheme != 'https' && u.scheme != 'http')) {
      return 'Enter a valid http(s) URL';
    }
    return null;
  }

  Future<void> _load() async {
    final token = staffBearerToken();
    if (token == null) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repos = context.read<AppRepositories>();
      final data = await repos.settings.getSettings(bearerToken: token);
      if (!mounted) return;
      setState(() {
        _name.text = data['funeral_home_name']?.toString() ?? '';
        _phone.text = data['funeral_home_phone']?.toString() ?? '';
        _address.text = data['funeral_home_address']?.toString() ?? '';
        _logoUrl.text = data['logo_url']?.toString() ?? '';
        _defaultMessage.text = data['default_message']?.toString() ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = staffBearerToken();
    if (token == null) return;
    setState(() => _saving = true);
    try {
      final repos = context.read<AppRepositories>();
      await repos.settings.updateSettings(
        {
          'funeral_home_name': _name.text.trim(),
          'funeral_home_phone': _phone.text.trim(),
          'funeral_home_address': _address.text.trim(),
          'logo_url': _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
          'default_message': _defaultMessage.text.trim().isEmpty ? null : _defaultMessage.text.trim(),
        },
        bearerToken: token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduledLoad) return;
    if (staffBearerToken() == null) {
      _scheduledLoad = true;
      setState(() => _loading = false);
      return;
    }
    _scheduledLoad = true;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final token = staffBearerToken();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (token != null)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: token == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Add DEV_AUTH_BEARER_TOKEN to load and edit funeral home settings.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.tonal(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Funeral home name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _address,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _logoUrl,
                            decoration: const InputDecoration(
                              labelText: 'Logo URL (optional)',
                              hintText: 'https://…',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.url,
                            validator: _validateHttpUrl,
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_logoUrl.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _LogoPreviewCard(url: _logoUrl.text.trim()),
                          ],
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _defaultMessage,
                            decoration: const InputDecoration(
                              labelText: 'Default family message (optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _LogoPreviewCard extends StatelessWidget {
  const _LogoPreviewCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Logo preview', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                height: 96,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.broken_image_outlined, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Could not load image')),
                    ],
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(height: 96, child: Center(child: CircularProgressIndicator()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

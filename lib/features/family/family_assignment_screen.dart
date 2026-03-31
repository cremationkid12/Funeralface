import 'package:flutter/material.dart';
import 'package:funeralface_mobile/app/app_repositories.dart';
import 'package:funeralface_mobile/features/family/family_assignment_repository.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Family-facing status screen (public token; no staff JWT.)
class FamilyAssignmentScreen extends StatefulWidget {
  const FamilyAssignmentScreen({super.key, required this.token});

  final String token;

  @override
  State<FamilyAssignmentScreen> createState() => _FamilyAssignmentScreenState();
}

class _FamilyAssignmentScreenState extends State<FamilyAssignmentScreen> {
  Future<FamilyAssignmentResult>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final repos = context.read<AppRepositories>();
    setState(() {
      _future = repos.familyAssignments.getByToken(widget.token.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service status'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: FutureBuilder<FamilyAssignmentResult>(
        future: _future,
        builder: (context, snapshot) {
          if (_future == null || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _FamilyMessage(
              title: 'Something went wrong',
              body: 'Please try again later or contact the funeral home.',
              onRetry: _load,
            );
          }
          final result = snapshot.data!;
          if (!result.isOk) {
            return _FamilyMessage(
              title: _failureTitle(result.failureCode),
              body: _failureBody(result),
              onRetry: _load,
            );
          }
          final v = result.view!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'We are here for your family.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          _formatStatus(v.status),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (v.decedentName.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Name', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text(v.decedentName, style: Theme.of(context).textTheme.bodyLarge),
                        ],
                        if (v.etaNote != null && v.etaNote!.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Note', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text(v.etaNote!, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (v.supportContactPhone.trim().isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: () => _call(v.supportContactPhone.trim()),
                    icon: const Icon(Icons.phone_outlined),
                    label: Text('Call ${v.supportContactPhone.trim()}'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatStatus(String raw) {
    return raw.replaceAll('_', ' ');
  }

  static String _failureTitle(FamilyAssignmentFailure? code) {
    switch (code) {
      case FamilyAssignmentFailure.notFound:
        return 'Link not available';
      case FamilyAssignmentFailure.expired:
        return 'Link has expired';
      case FamilyAssignmentFailure.rateLimited:
        return 'Please wait and try again';
      case FamilyAssignmentFailure.unknown:
      case null:
        return 'Unable to load';
    }
  }

  static String _failureBody(FamilyAssignmentResult result) {
    switch (result.failureCode) {
      case FamilyAssignmentFailure.notFound:
      case FamilyAssignmentFailure.expired:
        return 'If you need help, please contact the funeral home directly.';
      case FamilyAssignmentFailure.rateLimited:
        return 'Too many requests were made from this device.';
      default:
        return result.message ?? 'Something went wrong.';
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s'), ''));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _FamilyMessage extends StatelessWidget {
  const _FamilyMessage({
    required this.title,
    required this.body,
    required this.onRetry,
  });

  final String title;
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

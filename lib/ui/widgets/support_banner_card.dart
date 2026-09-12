import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Banner de patrocinio y apoyo comunitario (Ko-fi, PayPal, Twitch).
///
/// Diseñado para proyectos Open Source del ecosistema ApliArte siguiendo
/// las reglas de INBOX.md (Paso 3.5 y Paso 3.13).
class SupportBannerCard extends StatelessWidget {
  const SupportBannerCard({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF5E5B),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Apoya este proyecto Open Source',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Herramienta 100% gratuita y abierta. Si te ahorra tiempo o mejora tus directos, un café ayuda a mantener el desarrollo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade400,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _launch('https://ko-fi.com/C0C11TWR1K'),
                  icon: const Icon(Icons.coffee_rounded, size: 18, color: Color(0xFFFF5E5B)),
                  label: const Text('Ko-fi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2B36),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _launch('https://paypal.me/erbolamm'),
                  icon: const Icon(Icons.payment_rounded, size: 18, color: Color(0xFF5ECEF5)),
                  label: const Text('PayPal'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2B36),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _launch('https://streamelements.com/apliarte/tip'),
                  icon: const Icon(Icons.live_tv_rounded, size: 18, color: Color(0xFFB388FF)),
                  label: const Text('Twitch Tip'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2B36),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

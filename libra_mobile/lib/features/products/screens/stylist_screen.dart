import 'package:flutter/material.dart';
import '../../../core/theme/halo_theme.dart';
import '../models/product_model.dart';
import '../services/product_services.dart';
import 'product_detail_screen.dart';

class StylistScreen extends StatefulWidget {
  const StylistScreen({super.key});

  @override
  State<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends State<StylistScreen> {
  final _service = ProductServices();
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<_Message> _messages = [
    _Message(
      text: 'Hi, I\'m Mira — your Halo stylist. Describe a feeling or mood and I\'ll curate pieces for you.',
      isUser: false,
    ),
  ];

  bool _loading = false;

  static const _quickReplies = [
    'Quiet sunday dressing',
    'Linen, ivory, nothing loud',
    'Slow living essentials',
    'Minimal home objects',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final data = await _service.getProducts(search: text.split(' ').first, ordering: '-created_at');
      final products = (data['results'] as List<ProductModel>).take(3).toList();

      if (mounted) {
        setState(() {
          _messages.add(_Message(
            text: products.isEmpty
                ? 'I couldn\'t find exact matches, but let me know more about what you\'re looking for.'
                : 'I pulled ${products.length} piece${products.length == 1 ? '' : 's'} that match that feeling.',
            isUser: false,
            products: products,
          ));
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _messages.add(
          const _Message(text: 'Give me a moment — try again shortly.', isUser: false),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HaloBg(
      blobs: const [
        HaloBlob(color: Halo.rose,     dx: -0.70, dy: -0.80, r: 0.60),
        HaloBlob(color: Halo.lavender, dx:  0.70, dy: -0.65, r: 0.55),
        HaloBlob(color: Halo.mint,     dx:  0.50, dy:  0.60, r: 0.40),
      ],
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFD4909E), Color(0xFFBAAED4)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mira',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Halo.ink)),
                      Text('Halo stylist · always on',
                          style: TextStyle(fontSize: 11, color: Halo.inkMuted)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wb_sunny_outlined, size: 18, color: Halo.inkMuted),
                    ),
                  ),
                ],
              ),
            ),

            // ── Messages ────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) return _TypingIndicator();
                  return _MessageBubble(
                    msg: _messages[i],
                    onProductTap: (id) => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: id)),
                    ),
                  );
                },
              ),
            ),

            // ── Quick replies ────────────────────────────
            if (_messages.length <= 2) ...[
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickReplies.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _send(_quickReplies[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: Halo.pill,
                        border: Border.all(color: Halo.border),
                      ),
                      child: Text(_quickReplies[i],
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Halo.ink)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Input ────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: Halo.card,
                boxShadow: Halo.cardShadow,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.add, color: Halo.inkMuted, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(fontSize: 14, color: Halo.ink),
                      decoration: const InputDecoration(
                        hintText: 'Describe a feeling…',
                        hintStyle: TextStyle(color: Halo.inkFaint, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _send(_ctrl.text),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Halo.ink, shape: BoxShape.circle),
                      child: const Icon(Icons.mic_outlined, color: Colors.white, size: 18),
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

// ── Message model ─────────────────────────────────────────────
class _Message {
  final String text;
  final bool isUser;
  final List<ProductModel> products;
  const _Message({required this.text, required this.isUser, this.products = const []});
}

// ── Message bubble ────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _Message msg;
  final ValueChanged<int> onProductTap;
  const _MessageBubble({required this.msg, required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Text bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
            decoration: BoxDecoration(
              color: msg.isUser ? Halo.ink : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                bottomRight: Radius.circular(msg.isUser ? 4 : 18),
              ),
              boxShadow: Halo.cardShadow,
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                fontSize: 14, color: msg.isUser ? Colors.white : Halo.ink, height: 1.5,
              ),
            ),
          ),

          // Product recommendations
          if (msg.products.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: msg.products.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final p = msg.products[i];
                  return GestureDetector(
                    onTap: () => onProductTap(p.id),
                    child: Container(
                      width: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: Halo.card,
                        boxShadow: Halo.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(gradient: Halo.productGradient(p.id)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Halo.ink),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('\$${p.price.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Halo.ink)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: Halo.card, boxShadow: Halo.cardShadow,
        ),
        child: FadeTransition(
          opacity: _a,
          child: const Text('Mira is thinking…',
              style: TextStyle(fontSize: 13, color: Halo.inkMuted, fontStyle: FontStyle.italic)),
        ),
      ),
    );
  }
}

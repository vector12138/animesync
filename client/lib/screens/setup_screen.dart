
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _controller = TextEditingController(text: 'http://');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.connect(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_creation_rounded, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('AnimeSync', style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.primary, fontWeight: FontWeight.bold,
                )),
                Text('番剧进度同步系统', style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: '服务器地址',
                    hintText: 'http://192.168.1.x:8000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.dns),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (v) => (v == null || v.trim().isEmpty) ? '请输入服务器地址' : null,
                ),
                const SizedBox(height: 12),
                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(auth.error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: auth.isLoading ? null : _connect,
                    child: auth.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('连接服务器'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

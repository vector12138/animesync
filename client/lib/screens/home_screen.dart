import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/anime_card.dart';
import 'edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    ('全部', null),
    ('在看', 'watching'),
    ('已看完', 'completed'),
    ('想看', 'plan_to_watch'),
    ('搁置', 'on_hold'),
    ('弃番', 'dropped'),
  ];

  @override
  void initState() {
    super.initState();
    // 自动加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);
    final items = progress.filterStatus == null
        ? progress.items
        : progress.items.where((a) => a.status == progress.filterStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('追番进度'),
        actions: [
          // username + logout
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              onPressed: () => _showLogoutConfirm(context, auth),
              icon: const Icon(Icons.account_circle, size: 18),
              label: Text(auth.username ?? ''),
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: List.generate(_tabs.length, (i) {
                final (label, status) = _tabs[i];
                final isSelected = _tabIndex == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    label: Text(label, style: TextStyle(fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : null)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _tabIndex = i);
                      progress.setFilter(status);
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => progress.load(),
        child: progress.isLoading && items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_off, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('没有番剧记录', style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                        const SizedBox(height: 4),
                        Text('点击右下角 + 添加', style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        )),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final a = items[i];
                      return AnimeCard(
                        anime: a,
                        onIncrement: () => progress.watch(a.id, delta: 1),
                        onEdit: () async {
                          await showEditDialog(context, existing: a);
                        },
                        onDelete: () => _confirmDelete(context, progress, a),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, ProgressProvider p, AnimeProgress a) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${a.title}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () {
              p.delete(a.id);
              Navigator.pop(c);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext ctx, AuthProvider auth) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('退出登录'),
        content: Text('确定要退出「${auth.username}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')),
          FilledButton(onPressed: () { auth.logout(); Navigator.pop(c); }, child: const Text('退出')),
        ],
      ),
    );
  }
}

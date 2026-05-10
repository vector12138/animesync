
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/progress_provider.dart';

Future<AnimeProgress?> showEditDialog(BuildContext context, {AnimeProgress? existing}) async {
  return showDialog<AnimeProgress>(
    context: context,
    builder: (ctx) => _EditDialog(existing: existing),
  );
}

class _EditDialog extends StatefulWidget {
  final AnimeProgress? existing;
  const _EditDialog({this.existing});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _watchedCtrl;
  late final TextEditingController _notesCtrl;
  late String _status;
  double _rating = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _totalCtrl = TextEditingController(text: e?.totalEpisodes?.toString() ?? '');
    _watchedCtrl = TextEditingController(text: e?.watchedEpisodes.toString() ?? '0');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _status = e?.status ?? 'watching';
    _rating = (e?.rating ?? 0).toDouble();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _totalCtrl.dispose();
    _watchedCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      'title': _titleCtrl.text.trim(),
      'total_episodes': int.tryParse(_totalCtrl.text) ,
      'watched_episodes': int.tryParse(_watchedCtrl.text) ?? 0,
      'status': _status,
      'rating': _rating.round(),
      'notes': _notesCtrl.text.trim(),
    };

    final progress = context.read<ProgressProvider>();
    if (widget.existing != null) {
      progress.update(widget.existing!.id, body);
    } else {
      progress.create(body);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? '编辑番剧' : '添加番剧'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? '请输入标题' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalCtrl,
                      decoration: const InputDecoration(labelText: '总集数', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _watchedCtrl,
                      decoration: const InputDecoration(labelText: '已看', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Status dropdown
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: '状态', border: OutlineInputBorder()),
                items: AnimeProgress.allStatuses.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Row(children: [
                      Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: _statusColor(s), shape: BoxShape.circle)),
                      Text(AnimeProgress.statusLabel(s)),
                    ]),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 12),
              // Rating slider
              Row(
                children: [
                  Text('评分', style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 8),
                  Text('${_rating.round()}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Slider(
                      value: _rating,
                      min: 0, max: 10, divisions: 10,
                      label: _rating.round().toString(),
                      activeColor: theme.colorScheme.primary,
                      onChanged: (v) => setState(() => _rating = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: '备注', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(onPressed: _save, child: Text(isEdit ? '保存' : '添加')),
      ],
    );
  }

  Color _statusColor(String s) {
    const map = {
      'watching': Color(0xFF4CAF50),
      'completed': Color(0xFF2196F3),
      'plan_to_watch': Color(0xFFFFC107),
      'on_hold': Color(0xFFFF9800),
      'dropped': Color(0xFFF44336),
    };
    return map[s] ?? Colors.grey;
  }
}

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:gymboss/data/repositories/exercises_repository.dart';
import 'package:gymboss/data/repositories/workouts_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/workouts/workout.dart';
import 'package:gymboss/ui/core/theme/app_colors.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';
import 'package:gymboss/ui/core/ui/widgets/skeleton.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/subscription/pro_controller.dart';
import 'package:gymboss/ui/subscription/paywall_screen.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_editor.dart';
import 'package:gymboss/ui/menu_options_list/workouts/widgets/workout_detail.dart';

class Workouts extends StatefulWidget {
  const Workouts({super.key});

  @override
  State<Workouts> createState() => _WorkoutsState();
}

class _WorkoutsState extends State<Workouts> {
  late final WorkoutsRepository _repo;
  late final ExercisesRepository _exercises;

  int _tab = 0; // 0 = mine, 1 = public
  bool _loading = true;
  bool _loadingLibrary = false;
  bool _libraryLoaded = false;
  bool _foldersReady = false;
  String? _error;
  String? _libraryError;
  List<Workout> _mine = [];
  List<Workout> _public = [];
  List<WorkoutFolder> _folders = [];
  String? _folderId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final client = context.read<AuthenticatedClient>();
    _repo = WorkoutsRepository(client: client);
    _exercises = ExercisesRepository(client: client);
    _load();
  }

  Future<void> _load({bool spinner = true}) async {
    if (spinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final mine = await _repo.listOwned();
      if (mounted) {
        setState(() {
          _mine = mine;
          _loading = false;
        });
      }
      try {
        final folders = await _repo.listFolders();
        if (mounted) {
          setState(() {
            _folders = folders;
            _foldersReady = true;
          });
        }
      } catch (_) {
        // The default folder and cached workouts remain fully usable even when
        // the optional folder request cannot be completed.
        if (mounted) setState(() => _foldersReady = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (spinner) _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadLibrary({bool force = false}) async {
    if (_loadingLibrary || (_libraryLoaded && !force)) return;
    setState(() {
      _loadingLibrary = true;
      _libraryError = null;
    });
    try {
      final items = await _repo.listPublic();
      if (!mounted) return;
      setState(() {
        _public = items;
        _libraryLoaded = true;
      });
    } catch (error) {
      if (mounted) setState(() => _libraryError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingLibrary = false);
    }
  }

  void _selectTab(int value) {
    setState(() => _tab = value);
    if (value == 1) _loadLibrary();
  }

  Future<bool> _requirePro() async {
    final pro = context.read<ProController>();
    final known = pro.isKnown || await pro.load(force: true);
    if (!mounted) return false;
    if (!known) {
      await showAppDialog<void>(
        context,
        title: 'Couldn’t verify Pro access',
        message:
            'Check your connection and try again. Your current workouts are still available.',
        actions: [
          AppDialogAction('OK', onPressed: () => Navigator.pop(context)),
        ],
      );
      return false;
    }
    if (pro.isPro) return true;
    await _openPaywall();
    return false;
  }

  Future<void> _openDetail(Workout w) async {
    await Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder:
            (_) => WorkoutDetailScreen(
              id: w.id,
              repo: _repo,
              exercises: _exercises,
            ),
      ),
    );
    _load();
  }

  Future<void> _create() async {
    if (_mine.length >= 5 && !await _requirePro()) return;
    if (!mounted) return;
    final created = await Navigator.of(context, rootNavigator: true).push<bool>(
      CupertinoPageRoute(
        builder: (_) => WorkoutEditorScreen(repo: _repo, exercises: _exercises),
      ),
    );
    if (created == true) _load();
  }

  Future<void> _openPaywall() => Navigator.of(
    context,
    rootNavigator: true,
  ).push(CupertinoPageRoute(builder: (_) => const PaywallScreen()));

  Future<String?> _askName(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final value = await showCupertinoDialog<String>(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: Text(title),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CupertinoTextField(
                controller: controller,
                autofocus: true,
                placeholder: 'Folder name',
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed:
                    () => Navigator.pop(dialogContext, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    controller.dispose();
    return value?.isEmpty == true ? null : value;
  }

  Future<void> _createFolder() async {
    if (!await _requirePro()) return;
    final name = await _askName('New folder');
    if (name == null) return;
    try {
      await _repo.createFolder(name);
      await _load(spinner: false);
    } catch (error) {
      await _showActionError(error);
    }
  }

  Future<void> _manageFolder(WorkoutFolder folder) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder:
          (sheetContext) => CupertinoActionSheet(
            title: Text(folder.name),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  final name = await _askName(
                    'Rename folder',
                    initial: folder.name,
                  );
                  if (name == null) return;
                  try {
                    await _repo.renameFolder(folder.id, name);
                    await _load(spinner: false);
                  } catch (error) {
                    await _showActionError(error);
                  }
                },
                child: const Text('Rename'),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _deleteFolder(folder);
                },
                child: const Text('Delete folder'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  Future<void> _deleteFolder(WorkoutFolder folder) async {
    final count = _mine.where((w) => w.folderId == folder.id).length;
    final confirmed = await showAppDialog<bool>(
      context,
      title: 'Delete “${folder.name}”?',
      message:
          'This will permanently delete the folder and all $count workout${count == 1 ? '' : 's'} inside it. This cannot be undone.',
      actions: [
        AppDialogAction(
          'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          'Delete everything',
          isDestructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (confirmed != true) return;
    try {
      await _repo.deleteFolder(folder.id);
      if (_folderId == folder.id) _folderId = null;
      await _load(spinner: false);
    } catch (error) {
      await _showActionError(error);
    }
  }

  Future<void> _assignFolder(Workout workout) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder:
          (sheetContext) => CupertinoActionSheet(
            title: Text('Move “${workout.name}”'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await _moveWorkout(workout.id, null);
                },
                child: const Text('Default folder'),
              ),
              for (final folder in _folders)
                CupertinoActionSheetAction(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _moveWorkout(workout.id, folder.id);
                  },
                  child: Text(folder.name),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  Future<void> _moveWorkout(String workoutId, String? folderId) async {
    try {
      await _repo.assignFolder(workoutId, folderId);
      await _load(spinner: false);
    } catch (error) {
      await _showActionError(error);
    }
  }

  Future<void> _showActionError(Object error) => showAppDialog<void>(
    context,
    title: 'Couldn’t save changes',
    message: error.toString().replaceFirst('Exception: ', ''),
    actions: [AppDialogAction('OK', onPressed: () => Navigator.pop(context))],
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPage(
      title: 'Workouts',
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
          onPressed: _create,
          child: Icon(CupertinoIcons.add_circled, size: 24, color: c.accent),
        ),
      ],
      body:
          _loading
              ? const SkeletonList()
              : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _buildBody(c),
    );
  }

  Widget _buildBody(AppColors c) {
    final source =
        _tab == 0
            ? !_foldersReady
                ? _mine
                : _mine.where((w) => w.folderId == _folderId).toList()
            : _public;
    final query = _query.trim().toLowerCase();
    final list =
        query.isEmpty
            ? source
            : source
                .where(
                  (workout) =>
                      workout.name.toLowerCase().contains(query) ||
                      workout.comment.toLowerCase().contains(query) ||
                      workout.muscleGroups.any(
                        (muscle) => muscle.toLowerCase().contains(query),
                      ),
                )
                .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: _tab,
            backgroundColor: c.iconBg,
            thumbColor: c.card,
            onValueChanged: (v) => _selectTab(v ?? 0),
            children: {
              0: _seg('Mine (${_mine.length})', c),
              1: _seg(
                _libraryLoaded ? 'Library (${_public.length})' : 'Library',
                c,
              ),
            },
          ),
        ),
        if (_tab == 0)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FolderChip(
                  label: _foldersReady ? 'Default' : 'All workouts',
                  selected: _folderId == null,
                  onTap: () => setState(() => _folderId = null),
                ),
                for (final folder in _folders)
                  _FolderChip(
                    label: folder.name,
                    selected: _folderId == folder.id,
                    onTap: () => setState(() => _folderId = folder.id),
                    onLongPress: () => _manageFolder(folder),
                    onManage: () => _manageFolder(folder),
                  ),
                _FolderChip(
                  label: 'New folder',
                  icon: CupertinoIcons.add,
                  onTap: _createFolder,
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: CupertinoSearchTextField(
            placeholder: 'Search workouts or muscles',
            backgroundColor: c.card,
            style: TextStyle(color: c.textPrimary, fontFamily: 'Rubik'),
            placeholderStyle: TextStyle(
              color: c.textSecondary,
              fontFamily: 'Rubik',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child:
              _tab == 1 && _loadingLibrary
                  ? const SkeletonList()
                  : _tab == 1 && _libraryError != null
                  ? _ErrorView(
                    error: _libraryError!,
                    onRetry: () => _loadLibrary(force: true),
                  )
                  : CustomScrollView(
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh:
                            () =>
                                _tab == 0
                                    ? _load(spinner: false)
                                    : _loadLibrary(force: true),
                      ),
                      if (list.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child:
                              query.isNotEmpty
                                  ? _SearchEmpty(query: _query)
                                  : _EmptyView(
                                    mine: _tab == 0,
                                    onCreate: _create,
                                  ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          sliver: SliverList.separated(
                            itemCount: list.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 10),
                            itemBuilder:
                                (_, i) => _WorkoutCard(
                                  w: list[i],
                                  onTap: () => _openDetail(list[i]),
                                  onLongPress:
                                      _tab == 0
                                          ? () => _assignFolder(list[i])
                                          : null,
                                  onManage:
                                      _tab == 0
                                          ? () => _assignFolder(list[i])
                                          : null,
                                ),
                          ),
                        ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _seg(String label, AppColors c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
        fontFamily: 'Rubik',
      ),
    ),
  );
}

class _WorkoutCard extends StatelessWidget {
  final Workout w;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onManage;
  const _WorkoutCard({
    required this.w,
    required this.onTap,
    this.onLongPress,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Open ${w.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  c.isDark
                      ? const [
                        Color(0xFF252428),
                        Color(0xFF18181B),
                        Color(0xFF121214),
                      ]
                      : const [
                        Color(0xFFFFFDFC),
                        Color(0xFFFFF5F1),
                        Color(0xFFF5DEDA),
                      ],
              stops: const [0, 0.48, 1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  c.isDark ? const Color(0xFF343239) : const Color(0xFFE6C6BF),
            ),
            boxShadow: c.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      w.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ),
                  if (w.isPublic)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PUBLIC',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: c.accent,
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ),
                  if (onManage != null) ...[
                    const SizedBox(width: 6),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      onPressed: onManage,
                      child: Icon(
                        CupertinoIcons.ellipsis,
                        size: 18,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _CardTag(
                    icon:
                        w.type == 'aerobic'
                            ? CupertinoIcons.stopwatch
                            : CupertinoIcons.square_stack_3d_up_fill,
                    label:
                        w.type == 'aerobic'
                            ? 'Aerobic'
                            : '${w.exerciseCount} exercise${w.exerciseCount == 1 ? '' : 's'}',
                  ),
                  for (final muscle in w.muscleGroups.take(2))
                    _CardTag(label: muscle),
                ],
              ),
              if (w.comment.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  w.comment,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                    fontFamily: 'Rubik',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(CupertinoIcons.flame, size: 13, color: c.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    w.timesPerformed == 0
                        ? 'Not completed yet'
                        : '${w.timesPerformed} session${w.timesPerformed == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    CupertinoIcons.arrow_right,
                    size: 15,
                    color: c.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardTag extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _CardTag({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.iconBg.withValues(alpha: c.isDark ? 0.9 : 0.72),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c.accent),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c.textSecondary,
              fontFamily: 'Rubik',
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  final String query;

  const _SearchEmpty({required this.query});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.search, size: 34, color: c.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No workouts found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nothing matches “${query.trim()}”. Try a workout name or muscle group.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: c.textSecondary,
                fontFamily: 'Rubik',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onManage;

  const _FolderChip({
    required this.label,
    this.selected = false,
    this.icon,
    required this.onTap,
    this.onLongPress,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          margin: const EdgeInsets.only(right: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected ? colors.accent : colors.iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: colors.textSecondary),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? colors.textOnAccent : colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFamily: 'Rubik',
                ),
              ),
              if (onManage != null) ...[
                const SizedBox(width: 4),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: onManage,
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    size: 16,
                    color:
                        selected ? colors.textOnAccent : colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool mine;
  final VoidCallback onCreate;
  const _EmptyView({required this.mine, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mine ? CupertinoIcons.square_stack_3d_up : CupertinoIcons.compass,
              size: 40,
              color: c.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              mine ? 'No workouts yet' : 'Library is empty',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mine
                  ? 'Build your first workout from the\nexercise catalog, or import one by code.'
                  : 'Public, ready-made programs will\nshow up here to save a copy of.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
                height: 1.5,
                fontFamily: 'Rubik',
              ),
            ),
            if (mine) ...[
              const SizedBox(height: 16),
              CupertinoButton(
                color: c.accent,
                onPressed: onCreate,
                child: const Text('Create workout'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            'Could not load workouts',
            style: TextStyle(color: c.textPrimary, fontFamily: 'Rubik'),
          ),
          const SizedBox(height: 16),
          CupertinoButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

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
  String? _error;
  List<Workout> _mine = [];
  List<Workout> _public = [];

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
      final results = await Future.wait([
        _repo.listOwned(),
        _repo.listPublic(),
      ]);
      if (mounted) {
        setState(() {
          _mine = results[0];
          _public = results[1];
          _loading = false;
        });
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
    final created = await Navigator.of(context, rootNavigator: true).push<bool>(
      CupertinoPageRoute(
        builder: (_) => WorkoutEditorScreen(repo: _repo, exercises: _exercises),
      ),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPage(
      title: 'Workouts',
      actions: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _create,
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
    final list = _tab == 0 ? _mine : _public;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: _tab,
            backgroundColor: c.iconBg,
            thumbColor: c.card,
            onValueChanged: (v) => setState(() => _tab = v ?? 0),
            children: {
              0: _seg('Mine (${_mine.length})', c),
              1: _seg('Library (${_public.length})', c),
            },
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => _load(spinner: false),
              ),
              if (list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyView(mine: _tab == 0, onCreate: _create),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder:
                        (_, i) => _WorkoutCard(
                          w: list[i],
                          onTap: () => _openDetail(list[i]),
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
  const _WorkoutCard({required this.w, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
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
                      fontSize: 16,
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
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${w.exerciseCount} exercise${w.exerciseCount == 1 ? '' : 's'}'
              '${w.muscleGroups.isNotEmpty ? '  ·  ${w.muscleGroups.take(3).join(', ')}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
                fontFamily: 'Rubik',
              ),
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
                Icon(CupertinoIcons.heart_fill, size: 13, color: c.accent),
                const SizedBox(width: 4),
                Text(
                  '${w.loveScore}/10',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                    fontFamily: 'Rubik',
                  ),
                ),
                const SizedBox(width: 14),
                Icon(CupertinoIcons.flame, size: 13, color: c.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${w.timesPerformed}x',
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

import 'package:flutter/material.dart';
import '../../models/game_stage_model.dart';
import '../../models/library_game_model.dart';
import '../../storage/library_storage.dart';
import '../../widgets/game_cover.dart';
import 'widgets/progress_card.dart';
import 'widgets/stat_card.dart';
import 'widgets/timeline_item.dart';

Color _ratingScaleColor(double rating) {
  if (rating <= 0) return const Color(0xFF78716C);
  if (rating >= 8) return const Color(0xFF75EEFD);
  if (rating >= 6) return const Color(0xFFFACC15);
  if (rating >= 4) return const Color(0xFFF97316);

  return const Color(0xFFEF4444);
}

String _formatStageDate(DateTime date) {
  const months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  return '${date.day} ${months[date.month - 1]}, ${date.year}';
}

String _limitStageDescription(String value) {
  return value.trim();
}

class GameProgressScreen extends StatefulWidget {
  const GameProgressScreen({
    super.key,
    required this.gameId,
    required this.title,
    this.status = 'Играю',
    this.userHours = 42,
    this.userMinutes = 30,
    this.apiHours = 80,
    this.rating = 4.8,
    this.openReviewOnStart = false,
  });

  final int gameId;
  final String title;
  final String status;
  final int userHours;
  final int userMinutes;
  final int apiHours;
  final double rating;
  final bool openReviewOnStart;

  @override
  State<GameProgressScreen> createState() => _GameProgressScreenState();
}

class _GameProgressScreenState extends State<GameProgressScreen> {
  static const Color background = Color(0xFF0C0F0F);
  static const Color accent = Color(0xFF75EEFD);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  bool isFavorite = false;

  String? currentImageUrl;
  String? currentLocalImagePath;

  String currentGenre = '';
  List<String> currentPlatforms = const [];

  late String currentStatus = widget.status;
  int currentRating = 0;
  String currentReview = '';

  late int userHours = widget.userHours;
  late int userMinutes = widget.userMinutes;

  List<_GameStage> stages = const [
    _GameStage(
      title: 'Начало игры',
      subtitle: 'В процессе',
      type: TimelineItemType.current,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedGameDataAndMaybeOpenReview();
  }

  Future<void> _loadSavedGameDataAndMaybeOpenReview() async {
    await _loadSavedGameData();

    if (!mounted || !widget.openReviewOnStart) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openReviewScreen();
    });
  }

  double get progressValue {
    if (widget.apiHours <= 0) return 0;

    final played = userHours + userMinutes / 60;
    final calculated = played / widget.apiHours;

    if (calculated > 1) return 1;
    if (calculated < 0) return 0;

    return calculated;
  }

  int get progressPercent => (progressValue * 100).round();

  String get playedTimeText {
    return '$userHours ч.\n$userMinutes мин.';
  }

  String get ratingText {
    if (currentRating <= 0) return '— ★';

    return '$currentRating ★';
  }

  String _cleanBadgeText(String value) {
    return value.trim();
  }

  List<String> get gameInfoBadges {
    final result = <String>[];

    final genre = _cleanBadgeText(currentGenre);

    if (genre.isNotEmpty) {
      result.add(genre);
    }

    for (final platform in currentPlatforms) {
      final cleanPlatform = _cleanBadgeText(platform);

      if (cleanPlatform.isEmpty) {
        continue;
      }

      if (result.contains(cleanPlatform)) {
        continue;
      }

      result.add(cleanPlatform);
    }

    if (result.isEmpty) {
      return const ['Данные не указаны'];
    }

    return result;
  }

  Color get statusColor {
    if (currentStatus == 'Пройдено') return const Color(0xFFBBFFB3);
    if (currentStatus == 'Планирую') return const Color(0xFF61ACFE);
    return accent;
  }

  bool get isGameCompleted => currentStatus == 'Пройдено';

  int get lastStageIndex => stages.length - 1;

  _GameStage get currentStage {
    if (stages.isEmpty) {
      return const _GameStage(
        title: 'Начало игры',
        subtitle: 'В процессе',
        type: TimelineItemType.current,
      );
    }

    for (final stage in stages) {
      if (stage.type != TimelineItemType.done) {
        return stage;
      }
    }

    return stages.last;
  }

  String get currentStageStatusText {
    if (currentStage.type == TimelineItemType.done) {
      return 'Завершено';
    }

    return 'В процессе';
  }

  Color get currentStageStatusColor {
    if (currentStage.type == TimelineItemType.done) {
      return const Color(0xFFBBFFB3);
    }

    return const Color(0xFF61ACFE);
  }

  String get todayText {
    return _formatStageDate(DateTime.now());
  }

  void _showTemporaryMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF1A1D1D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _loadSavedGameData() async {
    final game = await LibraryStorage.getGameById(widget.gameId);

    if (!mounted || game == null) return;

    setState(() {
      currentStatus = game.status;
      userHours = game.userHours;
      userMinutes = game.userMinutes;
      isFavorite = game.isFavorite;
      currentImageUrl = game.imageUrl;
      currentLocalImagePath = game.localImagePath;
      currentGenre = game.genre;
      currentPlatforms = game.platforms;
      currentRating = game.userRating == null
          ? 0
          : game.userRating!.round().clamp(1, 10).toInt();
      currentReview = game.comment ?? '';

      if (game.stages.isNotEmpty) {
        stages = game.stages.map(_GameStage.fromModel).toList();
      }
    });

    if (game.stages.isEmpty) {
      await _saveStages(
        List<_GameStage>.from(stages),
        showErrorMessage: false,
      );
    }
  }

  Future<bool> _updateSavedGame({
    required LibraryGameModel Function(LibraryGameModel game) buildUpdatedGame,
    required String errorMessage,
    bool showErrorMessage = true,
  }) async {
    try {
      final game = await LibraryStorage.getGameById(widget.gameId);

      if (game == null) {
        if (mounted && showErrorMessage) {
          _showTemporaryMessage('Игра не найдена в библиотеке');
        }

        return false;
      }

      final updatedGame = buildUpdatedGame(game);

      await LibraryStorage.updateGame(updatedGame);

      return true;
    } catch (_) {
      if (mounted && showErrorMessage) {
        _showTemporaryMessage(errorMessage);
      }

      return false;
    }
  }

  Future<bool> _saveStages(
      List<_GameStage> nextStages, {
        bool showErrorMessage = true,
      }) {
    return _updateSavedGame(
      errorMessage: 'Не удалось сохранить этапы прохождения',
      showErrorMessage: showErrorMessage,
      buildUpdatedGame: (game) {
        return game.copyWith(
          stages: nextStages.map((stage) => stage.toModel()).toList(),
        );
      },
    );
  }

  Future<bool> _saveStatus(String newStatus) {
    return _updateSavedGame(
      errorMessage: 'Не удалось сохранить статус',
      buildUpdatedGame: (game) {
        return game.copyWith(
          status: newStatus,
        );
      },
    );
  }

  Future<bool> _saveTime({
    required int hours,
    required int minutes,
  }) {
    return _updateSavedGame(
      errorMessage: 'Не удалось сохранить время',
      buildUpdatedGame: (game) {
        return game.copyWith(
          userHours: hours,
          userMinutes: minutes,
        );
      },
    );
  }

  Future<bool> _saveReview({
    required int rating,
    required String review,
    bool deleteReview = false,
  }) {
    return _updateSavedGame(
      errorMessage: deleteReview
          ? 'Не удалось удалить отзыв'
          : 'Не удалось сохранить отзыв',
      buildUpdatedGame: (game) {
        if (deleteReview) {
          return game.copyWith(
            clearUserRating: true,
            clearComment: true,
            clearRatedAt: true,
          );
        }

        return game.copyWith(
          userRating: rating.toDouble(),
          comment: review.trim().isEmpty ? null : review.trim(),
          ratedAt: DateTime.now(),
        );
      },
    );
  }

  Future<bool> _saveFavorite(bool value) {
    return _updateSavedGame(
      errorMessage: 'Не удалось сохранить избранное',
      buildUpdatedGame: (game) {
        return game.copyWith(
          isFavorite: value,
        );
      },
    );
  }

  Future<void> _toggleFavorite() async {
    final oldFavoriteValue = isFavorite;
    final newFavoriteValue = !oldFavoriteValue;

    setState(() {
      isFavorite = newFavoriteValue;
    });

    final isSaved = await _saveFavorite(newFavoriteValue);

    if (!mounted) return;

    if (!isSaved) {
      setState(() {
        isFavorite = oldFavoriteValue;
      });
      return;
    }

    _showTemporaryMessage(
      newFavoriteValue ? 'Добавлено в избранное' : 'Удалено из избранного',
    );
  }


  Future<void> _deleteGame() async {
    final shouldDelete = await _showDeleteGameDialog();

    if (!shouldDelete) {
      return;
    }

    try {
      await LibraryStorage.deleteGame(widget.gameId);
    } catch (_) {
      if (!mounted) return;

      _showTemporaryMessage('Не удалось удалить игру');
      return;
    }

    if (!mounted) return;

    _showTemporaryMessage('Игра удалена из библиотеки');

    Navigator.pop(context, true);
  }

  Future<bool> _showDeleteGameDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(
              color: Color(0x5532B8C6),
              width: 1.2,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0x1AFF716C),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x99FF716C),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF716C).withOpacity(0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFF716C),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Удалить игру?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Игра будет удалена из библиотеки вместе с прогрессом, оценкой и этапами прохождения.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF081F23),
                          side: const BorderSide(
                            color: Color(0x6632B8C6),
                            width: 1.1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Отмена',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5484D),
                          shadowColor: const Color(0xFFFF716C).withOpacity(0.24),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Удалить',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  Future<void> _changeStatus(String newStatus) async {
    final oldStatus = currentStatus;

    setState(() {
      currentStatus = newStatus;
    });

    final isSaved = await _saveStatus(newStatus);

    if (!mounted) return;

    if (!isSaved) {
      setState(() {
        currentStatus = oldStatus;
      });
      return;
    }

    _showTemporaryMessage('Статус изменён: $newStatus');
  }

  Future<void> _changeTime({
    required int hours,
    required int minutes,
  }) async {
    final oldHours = userHours;
    final oldMinutes = userMinutes;

    setState(() {
      userHours = hours;
      userMinutes = minutes;
    });

    final isSaved = await _saveTime(
      hours: hours,
      minutes: minutes,
    );

    if (!mounted) return;

    if (!isSaved) {
      setState(() {
        userHours = oldHours;
        userMinutes = oldMinutes;
      });
      return;
    }

    _showTemporaryMessage('Время сохранено');
  }

  Future<void> _openReviewScreen() async {
    final result = await Navigator.push<_ReviewResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _ReviewScreen(
          title: widget.title,
          rating: currentRating,
          review: currentReview,
          localImagePath: currentLocalImagePath,
          imageUrl: currentImageUrl,
        ),
      ),
    );

    if (result == null) return;

    final oldRating = currentRating;
    final oldReview = currentReview;

    if (result.deleteReview) {
      setState(() {
        currentRating = 0;
        currentReview = '';
      });

      final isSaved = await _saveReview(
        rating: 0,
        review: '',
        deleteReview: true,
      );

      if (!mounted) return;

      if (!isSaved) {
        setState(() {
          currentRating = oldRating;
          currentReview = oldReview;
        });
        return;
      }

      _showTemporaryMessage('Отзыв удалён');
      return;
    }

    setState(() {
      currentRating = result.rating;
      currentReview = result.review;
    });

    final isSaved = await _saveReview(
      rating: result.rating,
      review: result.review,
    );

    if (!mounted) return;

    if (!isSaved) {
      setState(() {
        currentRating = oldRating;
        currentReview = oldReview;
      });
      return;
    }

    _showTemporaryMessage('Отзыв сохранён');
  }

  Future<void> _completeGame() async {
    await _changeStatus('Пройдено');
  }

  Future<void> _resumeGame() async {
    await _changeStatus('Играю');
  }

  Future<void> _completeStage(int index) async {
    if (index < 0 || index >= stages.length) return;

    final oldStages = List<_GameStage>.from(stages);
    final nextStages = List<_GameStage>.from(stages);
    final stage = nextStages[index];

    nextStages[index] = stage.copyWith(
      type: TimelineItemType.done,
      subtitle: todayText,
      completedAt: DateTime.now(),
    );

    setState(() {
      stages = nextStages;
    });

    final isSaved = await _saveStages(nextStages);

    if (!mounted) return;

    if (!isSaved) {
      setState(() {
        stages = oldStages;
      });
      return;
    }

    _showTemporaryMessage('Этап завершён');
  }

  Future<void> _resumeStage(int index) async {
    if (index < 0 || index >= stages.length) return;

    if (index != stages.length - 1) {
      _showTemporaryMessage('Можно возобновить только последний этап');
      return;
    }

    final oldStages = List<_GameStage>.from(stages);
    final nextStages = List<_GameStage>.from(stages);
    final stage = nextStages[index];

    nextStages[index] = stage.copyWith(
      type: TimelineItemType.current,
      subtitle: 'В процессе',
      clearCompletedAt: true,
    );

    setState(() {
      stages = nextStages;
    });

    final isSaved = await _saveStages(nextStages);

    if (!mounted) return;

    if (!isSaved) {
      setState(() {
        stages = oldStages;
      });
      return;
    }

    _showTemporaryMessage('Этап возобновлён');
  }

  Future<void> _deleteStage(int index) async {
    if (index == 0) {
      _showTemporaryMessage('Начальный этап нельзя удалить');
      return;
    }

    if (stages.length <= 1) {
      _showTemporaryMessage('Нельзя удалить последний этап');
      return;
    }

    if (index < 0 || index >= stages.length) return;

    final stage = stages[index];
    final shouldDelete = await _showDeleteStageDialog(stage);

    if (!shouldDelete) {
      return;
    }

    final oldStages = List<_GameStage>.from(stages);
    final nextStages = List<_GameStage>.from(stages)..removeAt(index);

    if (nextStages.length == 1 && nextStages.first.title == 'Начало игры') {
      nextStages[0] = nextStages.first.copyWith(
        type: TimelineItemType.current,
        subtitle: 'В процессе',
        clearCompletedAt: true,
      );
    }

    setState(() {
      stages = nextStages;
    });

    final isSaved = await _saveStages(nextStages);

    if (!mounted) return;

    if (!isSaved) {
      setState(() {
        stages = oldStages;
      });
      return;
    }

    _showTemporaryMessage('Этап удалён');
  }

  Future<bool> _showDeleteStageDialog(_GameStage stage) async {
    final cleanTitle = stage.title.trim();
    final stageTitle = cleanTitle.isEmpty ? 'выбранный этап' : cleanTitle;

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(
              color: Color(0x5532B8C6),
              width: 1.2,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0x1AFF716C),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x99FF716C),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF716C).withOpacity(0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFF716C),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Удалить этап?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Этап «$stageTitle» будет удалён из истории прохождения.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF081F23),
                          side: const BorderSide(
                            color: Color(0x6632B8C6),
                            width: 1.1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Отмена',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5484D),
                          shadowColor: const Color(0xFFFF716C).withOpacity(0.24),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Удалить',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  Future<void> _saveEditedStage({
    required int index,
    required String title,
    required String description,
  }) async {
    if (index <= 0) {
      return;
    }

    if (index >= stages.length) {
      return;
    }

    final cleanTitle = title.trim();
    final cleanDescription = _limitStageDescription(description);

    if (cleanTitle.isEmpty) {
      _showTemporaryMessage('Название этапа не может быть пустым');
      return;
    }

    final oldStages = List<_GameStage>.from(stages);
    final nextStages = List<_GameStage>.from(stages);
    final stage = nextStages[index];

    nextStages[index] = stage.copyWith(
      title: cleanTitle,
      description: cleanDescription,
      subtitle: stage.type == TimelineItemType.done
          ? stage.completedAt == null
          ? stage.subtitle
          : _formatStageDate(stage.completedAt!)
          : 'В процессе',
    );

    setState(() {
      stages = nextStages;
    });

    final isSaved = await _saveStages(nextStages);

    if (!mounted) return;

    if (!isSaved) {
      setState(() {
        stages = oldStages;
      });
      return;
    }

    _showTemporaryMessage('Этап сохранён');
  }

  void _openStageNameEditor({
    required int index,
    required String title,
    required String description,
  }) {
    if (index <= 0) {
      return;
    }

    final titleController = TextEditingController(text: title);
    final descriptionController = TextEditingController(text: description);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0x5532B8C6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.32),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: accent.withOpacity(0.075),
                  blurRadius: 22,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BottomSheetHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Переименовать этап',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Измените название. Описание необязательно',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _StageNameInput(
                    controller: titleController,
                  ),
                  const SizedBox(height: 12),
                  _StageDescriptionInput(
                    controller: descriptionController,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF75EEFD),
                            Color(0xFF25B0BE),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final newTitle = titleController.text.trim();

                          if (newTitle.isEmpty) {
                            _showTemporaryMessage(
                              'Название этапа не может быть пустым',
                            );
                            return;
                          }

                          Navigator.pop(bottomSheetContext);

                          await _saveEditedStage(
                            index: index,
                            title: newTitle,
                            description: descriptionController.text,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(
                            color: Color(0xFF00575F),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _createStageWithTitle({
    required String title,
    required String description,
  }) async {
    final cleanTitle = title.trim();
    final cleanDescription = _limitStageDescription(description);

    if (cleanTitle.isEmpty) {
      _showTemporaryMessage('Название этапа не может быть пустым');
      return;
    }

    final oldStages = List<_GameStage>.from(stages);
    late final List<_GameStage> nextStages;

    if (stages.isEmpty) {
      nextStages = [
        _GameStage(
          title: 'Начало игры',
          subtitle: todayText,
          type: TimelineItemType.done,
          completedAt: DateTime.now(),
        ),
        _GameStage(
          title: cleanTitle,
          subtitle: 'В процессе',
          description: cleanDescription,
          type: TimelineItemType.current,
        ),
      ];
    } else {
      final updatedStages = List<_GameStage>.from(stages);
      updatedStages[lastStageIndex] = stages.last.copyWith(
        type: TimelineItemType.done,
        subtitle: todayText,
        completedAt: DateTime.now(),
      );

      nextStages = [
        ...updatedStages,
        _GameStage(
          title: cleanTitle,
          subtitle: 'В процессе',
          description: cleanDescription,
          type: TimelineItemType.current,
        ),
      ];
    }

    setState(() {
      stages = nextStages;
    });

    final isSaved = await _saveStages(nextStages);

    if (!mounted) return;

    if (!isSaved) {
      setState(() {
        stages = oldStages;
      });
      return;
    }

    _showTemporaryMessage('Новый этап добавлен');
  }

  void _openNewStageNameEditor() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0x5532B8C6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.32),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: accent.withOpacity(0.075),
                  blurRadius: 22,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BottomSheetHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Новый этап',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Введите название этапа. Описание необязательно',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _StageNameInput(
                    controller: titleController,
                  ),
                  const SizedBox(height: 12),
                  _StageDescriptionInput(
                    controller: descriptionController,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF75EEFD),
                            Color(0xFF25B0BE),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final newTitle = titleController.text.trim();

                          if (newTitle.isEmpty) {
                            _showTemporaryMessage(
                              'Название этапа не может быть пустым',
                            );
                            return;
                          }

                          Navigator.pop(bottomSheetContext);

                          await _createStageWithTitle(
                            title: newTitle,
                            description: descriptionController.text,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Создать этап',
                          style: TextStyle(
                            color: Color(0xFF00575F),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addStage() async {
    _openNewStageNameEditor();
  }

  void _openStatusSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0x5532B8C6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.32),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: accent.withOpacity(0.075),
                  blurRadius: 22,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BottomSheetHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Выберите статус',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Статус прохождения игры',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _StatusMenuItem(
                    icon: Icons.sports_esports_rounded,
                    title: 'Играю',
                    subtitle: 'Игра сейчас в процессе',
                    color: accent,
                    isSelected: currentStatus == 'Играю',
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      await _changeStatus('Играю');
                    },
                  ),
                  const SizedBox(height: 12),
                  _StatusMenuItem(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Пройдено',
                    subtitle: 'Игра полностью завершена',
                    color: const Color(0xFFBBFFB3),
                    isSelected: currentStatus == 'Пройдено',
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      await _changeStatus('Пройдено');
                    },
                  ),
                  const SizedBox(height: 12),
                  _StatusMenuItem(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Планирую',
                    subtitle: 'Игра добавлена в планы',
                    color: const Color(0xFF61ACFE),
                    isSelected: currentStatus == 'Планирую',
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      await _changeStatus('Планирую');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openTimeEditor() {
    final hoursController = TextEditingController(text: userHours.toString());
    final minutesController =
    TextEditingController(text: userMinutes.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0x5532B8C6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.32),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: accent.withOpacity(0.075),
                  blurRadius: 22,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BottomSheetHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    'Изменить время',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Укажите, сколько вы уже играли',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeInputField(
                          controller: hoursController,
                          label: 'Часы',
                          suffix: 'ч.',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeInputField(
                          controller: minutesController,
                          label: 'Минуты',
                          suffix: 'мин.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF75EEFD),
                            Color(0xFF25B0BE),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final newHours =
                              int.tryParse(hoursController.text.trim()) ?? 0;
                          final rawMinutes =
                              int.tryParse(minutesController.text.trim()) ?? 0;
                          final newMinutes = rawMinutes.clamp(0, 59).toInt();

                          Navigator.pop(bottomSheetContext);

                          await _changeTime(
                            hours: newHours < 0 ? 0 : newHours,
                            minutes: newMinutes,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(
                            color: Color(0xFF00575F),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openStageActions(int index) {
    if (index <= 0 || index >= stages.length) {
      return;
    }

    final stage = stages[index];
    final isStageDone = stage.type == TimelineItemType.done;
    final isLastStage = index == stages.length - 1;
    final canResumeStage = isStageDone && isLastStage;
    final canCompleteStage = !isStageDone;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.86,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0x5532B8C6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.32),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: accent.withOpacity(0.075),
                    blurRadius: 22,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _BottomSheetHandle(),
                      const SizedBox(height: 20),
                      _StageTitlePreview(
                        title: stage.title,
                      ),
                      if (stage.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _StageDescriptionPreview(
                          description: stage.description,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _StageMenuItem(
                        icon: Icons.edit_rounded,
                        title: 'Переименовать',
                        onTap: () {
                          Navigator.pop(bottomSheetContext);

                          _openStageNameEditor(
                            index: index,
                            title: stage.title,
                            description: stage.description,
                          );
                        },
                      ),
                      if (canCompleteStage || canResumeStage) ...[
                        const SizedBox(height: 8),
                        _StageMenuItem(
                          icon: canResumeStage
                              ? Icons.restart_alt_rounded
                              : Icons.check_circle_outline_rounded,
                          title: canResumeStage ? 'Возобновить' : 'Завершить',
                          onTap: () async {
                            Navigator.pop(bottomSheetContext);

                            if (canResumeStage) {
                              await _resumeStage(index);
                              return;
                            }

                            await _completeStage(index);
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      _StageMenuItem(
                        icon: Icons.delete_outline_rounded,
                        title: 'Удалить',
                        danger: true,
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          await _deleteStage(index);
                        },
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 115, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GameHeroImage(
                  localImagePath: currentLocalImagePath,
                  imageUrl: currentImageUrl,
                ),
                const SizedBox(height: 24),
                _GameInfoBadges(
                  badges: gameInfoBadges,
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GameStatCard(
                        title: 'Статус',
                        value: currentStatus,
                        valueColor: statusColor,
                        compactValue: true,
                        onTap: _openStatusSelector,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GameStatCard(
                        title: 'Время',
                        value: playedTimeText,
                        onTap: _openTimeEditor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GameStatCard(
                        title: 'Оценка',
                        value: ratingText,
                        valueColor: _ratingScaleColor(
                          currentRating.toDouble(),
                        ),
                        compactValue: true,
                        onTap: _openReviewScreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                GameProgressCard(
                  title: currentStage.title,
                  statusText: currentStageStatusText,
                  statusColor: currentStageStatusColor,
                ),
                const SizedBox(height: 48),
                const Text(
                  'История прохождения',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 32),
                for (int i = 0; i < stages.length; i++)
                  TimelineItem(
                    title: stages[i].title,
                    subtitle: stages[i].subtitle,
                    type: stages[i].type,
                    isLast: i == stages.length - 1,
                    onTap: i == 0 ? null : () => _openStageActions(i),
                  ),
                const SizedBox(height: 4),
                _AddStageButton(onTap: _addStage),
                const SizedBox(height: 28),
                if (isGameCompleted) ...[
                  const _CompletedGameButton(),
                  const SizedBox(height: 14),
                  _ResumeGameButton(
                    onTap: _resumeGame,
                  ),
                ] else
                  _FinishGameButton(
                    onTap: _completeGame,
                  ),
              ],
            ),
          ),
          _TopBar(
            title: widget.title,
            isFavorite: isFavorite,
            onDeleteTap: _deleteGame,
            onFavoriteTap: _toggleFavorite,
          ),
        ],
      ),
    );
  }
}

class _ReviewResult {
  const _ReviewResult({
    required this.rating,
    required this.review,
    this.deleteReview = false,
  });

  final int rating;
  final String review;
  final bool deleteReview;
}

class _ReviewScreen extends StatefulWidget {
  const _ReviewScreen({
    required this.title,
    required this.rating,
    required this.review,
    required this.localImagePath,
    required this.imageUrl,
  });

  final String title;
  final int rating;
  final String review;
  final String? localImagePath;
  final String? imageUrl;

  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {
  static const Color background = Color(0xFF0C0F0F);
  static const Color surface = Color(0xFF111414);
  static const Color surfaceLight = Color(0xFF232626);
  static const Color accent = Color(0xFF75EEFD);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  late int selectedRating = widget.rating;
  late final TextEditingController reviewController =
  TextEditingController(text: widget.review);

  @override
  void initState() {
    super.initState();

    reviewController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  String get ratingText {
    if (selectedRating <= 0) return '—/10';

    return '$selectedRating/10';
  }

  Color get selectedRatingColor {
    return _ratingScaleColor(selectedRating.toDouble());
  }

  void _saveReview() {
    if (selectedRating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Сначала выберите оценку',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF1A1D1D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      _ReviewResult(
        rating: selectedRating,
        review: reviewController.text,
      ),
    );
  }

  bool get hasSavedReview {
    return widget.rating > 0 || widget.review.trim().isNotEmpty;
  }

  void _deleteReview() {
    if (!hasSavedReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Отзыв ещё не добавлен',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF1A1D1D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      const _ReviewResult(
        rating: 0,
        review: '',
        deleteReview: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 115, 16, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewHeroImage(
                  localImagePath: widget.localImagePath,
                  imageUrl: widget.imageUrl,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 36,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.9,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081F23),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0x6632B8C6),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF75EEFD).withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Ваша оценка',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 24,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            ratingText,
                            style: TextStyle(
                              color: selectedRatingColor,
                              fontSize: 30,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _ReviewRatingGrid(
                        selectedRating: selectedRating,
                        onRatingSelected: (rating) {
                          setState(() {
                            selectedRating = rating;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    'Отзыв',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 240,
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      TextField(
                        controller: reviewController,
                        maxLines: null,
                        cursorColor: accent,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Поделитесь своими впечатлениями...',
                          hintStyle: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                _SaveReviewButton(
                  onTap: _saveReview,
                ),
                if (hasSavedReview) ...[
                  const SizedBox(height: 14),
                  _DeleteReviewButton(
                    onTap: _deleteReview,
                  ),
                ],
              ],
            ),
          ),
          const _ReviewTopBar(),
        ],
      ),
    );
  }
}

class _ReviewTopBar extends StatelessWidget {
  const _ReviewTopBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: const Color(0xCC0C0F0F),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x6675EEFD),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF75EEFD),
                  size: 23,
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'Оценить игру',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(width: 38),
          ],
        ),
      ),
    );
  }
}

class _ReviewHeroImage extends StatelessWidget {
  const _ReviewHeroImage({
    required this.localImagePath,
    required this.imageUrl,
  });

  final String? localImagePath;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 358,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 50,
            offset: const Offset(0, 25),
          ),
        ],
      ),
      child: GameCover(
        width: double.infinity,
        height: 358,
        localImagePath: localImagePath,
        imageUrl: imageUrl,
        borderRadius: 12,
        iconSize: 120,
        gradientOpacity: 0.20,
      ),
    );
  }
}

class _ReviewRatingGrid extends StatelessWidget {
  const _ReviewRatingGrid({
    required this.selectedRating,
    required this.onRatingSelected,
  });

  final int selectedRating;
  final ValueChanged<int> onRatingSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final rating = index + 1;

            return _ReviewRatingCircle(
              rating: rating,
              isSelected: selectedRating == rating,
              onTap: () => onRatingSelected(rating),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final rating = index + 6;

            return _ReviewRatingCircle(
              rating: rating,
              isSelected: selectedRating == rating,
              onTap: () => onRatingSelected(rating),
            );
          }),
        ),
      ],
    );
  }
}

class _ReviewRatingCircle extends StatelessWidget {
  const _ReviewRatingCircle({
    required this.rating,
    required this.isSelected,
    required this.onTap,
  });

  final int rating;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = _ratingScaleColor(rating.toDouble());
    final color = isSelected ? selectedColor : const Color(0xFFAAABAB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withOpacity(0.15)
                : const Color(0xFF1D2020),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? selectedColor : const Color(0x1A464848),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? selectedColor.withOpacity(0.22)
                    : Colors.black.withOpacity(0.20),
                blurRadius: isSelected ? 18 : 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$rating',
            style: TextStyle(
              color: color,
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveReviewButton extends StatelessWidget {
  const _SaveReviewButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF75EEFD),
              Color(0xFF25B0BE),
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF75EEFD).withOpacity(0.15),
              blurRadius: 40,
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(
            Icons.save_rounded,
            color: Color(0xFF00575F),
            size: 22,
          ),
          label: const Text(
            'Сохранить отзыв',
            style: TextStyle(
              color: Color(0xFF00575F),
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteReviewButton extends StatelessWidget {
  const _DeleteReviewButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFFF716C),
          size: 22,
        ),
        label: const Text(
          'Удалить отзыв',
          style: TextStyle(
            color: Color(0xFFFF716C),
            fontSize: 17,
            height: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0x99FF716C),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          backgroundColor: const Color(0x1AFF716C),
        ),
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF75EEFD).withOpacity(0.28),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _FinishGameButton extends StatelessWidget {
  const _FinishGameButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF75EEFD),
              Color(0xFF25B0BE),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF75EEFD).withOpacity(0.20),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF00575F),
            size: 24,
          ),
          label: const Text(
            'Закончить прохождение',
            style: TextStyle(
              color: Color(0xFF00575F),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletedGameButton extends StatelessWidget {
  const _CompletedGameButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2B2F2F),
              Color(0xFF1D2020),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Color(0x1AFFFFFF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFFAAABAB),
            size: 24,
          ),
          label: const Text(
            'Прохождение завершено',
            style: TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: const Color(0xFFAAABAB),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumeGameButton extends StatelessWidget {
  const _ResumeGameButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF081F23),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0x6632B8C6),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF75EEFD).withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(
            Icons.restart_alt_rounded,
            color: Color(0xFF75EEFD),
            size: 24,
          ),
          label: const Text(
            'Возобновить прохождение',
            style: TextStyle(
              color: Color(0xFF75EEFD),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeInputField extends StatelessWidget {
  const _TimeInputField({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x5532B8C6),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        cursorColor: const Color(0xFF75EEFD),
        style: const TextStyle(
          color: Color(0xFFF4F3F3),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: InputBorder.none,
          labelStyle: const TextStyle(
            color: Color(0xFFAAABAB),
            fontSize: 13,
          ),
          suffixStyle: const TextStyle(
            color: Color(0xFF75EEFD),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatusMenuItem extends StatelessWidget {
  const _StatusMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF081F23),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0x2275EEFD),
        highlightColor: const Color(0x1275EEFD),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.42)
                  : const Color(0x5532B8C6),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF75EEFD).withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? color : const Color(0xFFF4F3F3),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFAAABAB),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? color : const Color(0xFF747675),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageMenuItem extends StatelessWidget {
  const _StageMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF716C) : const Color(0xFF75EEFD);

    return Material(
      color: const Color(0xFF081F23),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: const Color(0x2275EEFD),
        highlightColor: const Color(0x1275EEFD),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: danger
                  ? const Color(0x66FF716C)
                  : const Color(0x5532B8C6),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF75EEFD).withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: danger ? color : const Color(0xFFF4F3F3),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageNameInput extends StatelessWidget {
  const _StageNameInput({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x5532B8C6),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        cursorColor: const Color(0xFF75EEFD),
        style: const TextStyle(
          color: Color(0xFFF4F3F3),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        decoration: const InputDecoration(
          labelText: 'Название этапа',
          border: InputBorder.none,
          labelStyle: TextStyle(
            color: Color(0xFFAAABAB),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}


class _StageDescriptionInput extends StatelessWidget {
  const _StageDescriptionInput({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x5532B8C6),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        cursorColor: const Color(0xFF75EEFD),
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        scrollPadding: const EdgeInsets.only(bottom: 90),
        style: const TextStyle(
          color: Color(0xFFF4F3F3),
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          labelText: 'Описание (необязательно)',
          border: InputBorder.none,
          alignLabelWithHint: true,
          contentPadding: EdgeInsets.only(
            top: 8,
            bottom: 8,
          ),
          labelStyle: TextStyle(
            color: Color(0xFFAAABAB),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StageTitlePreview extends StatefulWidget {
  const _StageTitlePreview({
    required this.title,
  });

  final String title;

  @override
  State<_StageTitlePreview> createState() => _StageTitlePreviewState();
}

class _StageTitlePreviewState extends State<_StageTitlePreview> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cleanTitle = widget.title.trim();

    if (cleanTitle.isEmpty) {
      return const SizedBox.shrink();
    }

    final lineBreaksCount = '\n'.allMatches(cleanTitle).length;
    final shouldShowExpandButton = cleanTitle.length > 44 || lineBreaksCount >= 1;

    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: isExpanded ? 156 : 60,
          ),
          child: SingleChildScrollView(
            physics: isExpanded
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                cleanTitle,
                textAlign: TextAlign.center,
                maxLines: isExpanded ? null : 2,
                overflow: isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _GameProgressScreenState.textPrimary,
                  fontSize: 22,
                  height: 1.18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        if (shouldShowExpandButton) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Text(
              isExpanded ? 'Свернуть' : 'Раскрыть',
              style: const TextStyle(
                color: _GameProgressScreenState.accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StageDescriptionPreview extends StatefulWidget {
  const _StageDescriptionPreview({
    required this.description,
  });

  final String description;

  @override
  State<_StageDescriptionPreview> createState() =>
      _StageDescriptionPreviewState();
}

class _StageDescriptionPreviewState extends State<_StageDescriptionPreview> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cleanDescription = widget.description.trim();

    if (cleanDescription.isEmpty) {
      return const SizedBox.shrink();
    }

    final lineBreaksCount = '\n'.allMatches(cleanDescription).length;
    final shouldShowExpandButton =
        cleanDescription.length > 70 || lineBreaksCount >= 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isExpanded ? 170 : 62,
            ),
            child: SingleChildScrollView(
              physics: isExpanded
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  cleanDescription,
                  maxLines: isExpanded ? null : 3,
                  overflow: isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD6D3D1),
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          if (shouldShowExpandButton) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Text(
                isExpanded ? 'Свернуть' : 'Раскрыть',
                style: const TextStyle(
                  color: Color(0xFF75EEFD),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GameStage {
  const _GameStage({
    required this.title,
    required this.subtitle,
    required this.type,
    this.description = '',
    this.completedAt,
  });

  final String title;
  final String subtitle;
  final TimelineItemType type;
  final String description;
  final DateTime? completedAt;

  static _GameStage fromModel(GameStageModel model) {
    final type = model.isDone ? TimelineItemType.done : TimelineItemType.current;

    return _GameStage(
      title: model.title,
      subtitle: model.isDone
          ? model.completedAt == null
          ? model.subtitle
          : _formatStageDate(model.completedAt!)
          : 'В процессе',
      type: type,
      description: model.description,
      completedAt: model.completedAt,
    );
  }

  GameStageModel toModel() {
    return GameStageModel(
      title: title,
      subtitle: subtitle,
      isDone: type == TimelineItemType.done,
      description: description,
      completedAt: completedAt,
    );
  }

  _GameStage copyWith({
    String? title,
    String? subtitle,
    TimelineItemType? type,
    String? description,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return _GameStage(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      description: description ?? this.description,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }
}

class _AddStageButton extends StatelessWidget {
  const _AddStageButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF75EEFD),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF75EEFD).withOpacity(0.18),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF75EEFD),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Добавить этап прохождения',
                  style: TextStyle(
                    color: Color(0xFF75EEFD),
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.isFavorite,
    required this.onDeleteTap,
    required this.onFavoriteTap,
  });

  final String title;
  final bool isFavorite;
  final VoidCallback onDeleteTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: const Color(0xCC0C0F0F),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x6675EEFD),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF75EEFD),
                  size: 23,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDeleteTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x1AFF716C),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x99FF716C),
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFF716C),
                  size: 23,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onFavoriteTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x6675EEFD),
                  ),
                ),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: const Color(0xFF75EEFD),
                  size: 23,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameHeroImage extends StatelessWidget {
  const _GameHeroImage({
    required this.localImagePath,
    required this.imageUrl,
  });

  final String? localImagePath;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 358,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 50,
            offset: const Offset(0, 25),
          ),
        ],
      ),
      child: GameCover(
        width: double.infinity,
        height: 358,
        localImagePath: localImagePath,
        imageUrl: imageUrl,
        borderRadius: 12,
        iconSize: 120,
        gradientOpacity: 0.20,
      ),
    );
  }
}

class _GameInfoBadges extends StatelessWidget {
  const _GameInfoBadges({
    required this.badges,
  });

  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < badges.length; i++) ...[
                    _GenreBadge(text: badges[i]),
                    if (i != badges.length - 1) const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GenreBadge extends StatelessWidget {
  const _GenreBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          color: Color(0xFF75EEFD),
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

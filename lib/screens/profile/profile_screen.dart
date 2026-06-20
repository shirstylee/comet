import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/library_game_model.dart';
import '../../models/user_profile_model.dart';
import '../../storage/library_storage.dart';
import '../../storage/library_change_notifier.dart';
import '../../storage/profile_storage.dart';
import '../../widgets/game_cover.dart';
import '../game_progress/game_progress_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';

String _formatRating(double rating) {
  final roundedRating = double.parse(rating.toStringAsFixed(1));

  if (roundedRating == roundedRating.roundToDouble()) {
    return roundedRating.toInt().toString();
  }

  return roundedRating.toStringAsFixed(1);
}

Color _ratingScaleColor(double rating) {
  if (rating <= 0) return const Color(0xFF78716C);
  if (rating >= 8) return const Color(0xFF75EEFD);
  if (rating >= 6) return const Color(0xFFFACC15);
  if (rating >= 4) return const Color(0xFFF97316);

  return const Color(0xFFEF4444);
}

String _ratingVerdictText(double rating) {
  if (rating >= 9) return 'ШЕДЕВР';
  if (rating >= 8) return 'ОТЛИЧНО';
  if (rating >= 6) return 'ХОРОШО';
  if (rating >= 4) return 'СРЕДНЕ';

  return 'СЛАБО';
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color background = Color(0xFF0C0F0F);
  static const Color accent = Color(0xFF22D3EE);

  UserProfileModel profile = const UserProfileModel(
    name: '',
    status: '',
    favoritePlatforms: [],
    avatarPath: null,
  );

  List<LibraryGameModel> games = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadProfileData();
    LibraryChangeNotifier.version.addListener(_onLibraryChanged);
  }

  void _onLibraryChanged() {
    if (!mounted) return;

    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final loadedProfile = await ProfileStorage.getProfile();
    final loadedGames = await LibraryStorage.getAllGames();

    loadedGames.sort((a, b) {
      return b.addedAt.compareTo(a.addedAt);
    });

    if (!mounted) return;

    setState(() {
      profile = loadedProfile;
      games = loadedGames;
      isLoading = false;
    });
  }

  List<LibraryGameModel> get ratedGames {
    final result = games.where((game) {
      return game.userRating != null && game.userRating! > 0;
    }).toList();

    result.sort((a, b) {
      return _ratingDate(b).compareTo(_ratingDate(a));
    });

    return result;
  }

  List<LibraryGameModel> get completedGames {
    return games.where((game) {
      return game.status.toLowerCase() == 'пройдено';
    }).toList();
  }

  LibraryGameModel? get featuredGame {
    if (ratedGames.isEmpty) return null;

    final sorted = [...ratedGames];

    sorted.sort((a, b) {
      final ratingA = _ratingOutOfTen(a.userRating);
      final ratingB = _ratingOutOfTen(b.userRating);

      final ratingCompare = ratingB.compareTo(ratingA);

      if (ratingCompare != 0) {
        return ratingCompare;
      }

      return _ratingDate(b).compareTo(_ratingDate(a));
    });

    return sorted.first;
  }

  List<LibraryGameModel> get otherRatedGames {
    final featured = featuredGame;

    if (featured == null) return [];

    return ratedGames.where((game) {
      return game.id != featured.id;
    }).take(2).toList();
  }

  String get favoriteGenre {
    if (ratedGames.isEmpty) return '—';

    final Map<String, int> genreCounts = {};

    for (final game in ratedGames) {
      final genre = game.genre.trim();

      if (genre.isEmpty) continue;

      genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
    }

    if (genreCounts.isEmpty) return '—';

    final entries = genreCounts.entries.toList();

    entries.sort((a, b) {
      return b.value.compareTo(a.value);
    });

    return entries.first.key;
  }

  double _ratingOutOfTen(double? rating) {
    if (rating == null || rating <= 0) return 0;
    if (rating > 10) return 10;
    if (rating < 1) return 1;

    return rating;
  }

  DateTime _ratingDate(LibraryGameModel game) {
    return game.ratedAt ?? game.addedAt;
  }

  Color _statusColor(String status) {
    final lowerStatus = status.toLowerCase();

    if (lowerStatus == 'пройдено') return const Color(0xFFBBFFB3);
    if (lowerStatus == 'играю') return const Color(0xFF61ACFE);

    return accent;
  }

  String _statusText(String status) {
    return status.toUpperCase();
  }

  String _commentPreview(String? comment) {
    final value = comment?.trim();

    if (value == null || value.isEmpty) {
      return 'Комментарий пока не добавлен...';
    }

    return value;
  }

  String _formattedDate(DateTime date) {
    const months = [
      'ЯНВАРЯ',
      'ФЕВРАЛЯ',
      'МАРТА',
      'АПРЕЛЯ',
      'МАЯ',
      'ИЮНЯ',
      'ИЮЛЯ',
      'АВГУСТА',
      'СЕНТЯБРЯ',
      'ОКТЯБРЯ',
      'НОЯБРЯ',
      'ДЕКАБРЯ',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _releaseYearText(int? year) {
    if (year == null || year <= 0) {
      return 'ГОД НЕИЗВЕСТЕН';
    }

    return '$year';
  }

  String _timeText(LibraryGameModel game) {
    if (game.userHours <= 0 && game.userMinutes <= 0) return '0ч.';
    if (game.userMinutes <= 0) return '${game.userHours}ч.';

    return '${game.userHours}ч. ${game.userMinutes}м.';
  }

  Future<void> _openGame(LibraryGameModel game) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameProgressScreen(
          gameId: game.id,
          title: game.title,
          status: game.status,
          userHours: game.userHours,
          userMinutes: game.userMinutes,
          apiHours: game.apiHours,
          rating: game.userRating ?? game.apiRating ?? 0,
        ),
      ),
    );

    await _loadProfileData();
  }

  Future<void> _openEditProfileScreen() async {
    final isUpdated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: profile,
        ),
      ),
    );

    if (isUpdated == true) {
      await _loadProfileData();
    }
  }

  Future<void> _openNotificationsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  Future<void> _openSettingsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  @override
  void dispose() {
    LibraryChangeNotifier.version.removeListener(_onLibraryChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featured = featuredGame;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: accent,
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileTopHeader(
                onEditTap: _openEditProfileScreen,
                onNotificationsTap: _openNotificationsScreen,
                onSettingsTap: _openSettingsScreen,
              ),
              const SizedBox(height: 36),
              _ProfileHero(
                profile: profile,
                gamesCount: games.length,
                completedCount: completedGames.length,
                favoriteGenre: favoriteGenre,
                platforms: profile.favoritePlatforms,
              ),
              const SizedBox(height: 48),
              const _SectionHeader(title: 'Оценки'),
              const SizedBox(height: 24),
              if (ratedGames.isEmpty)
                const _EmptyProfileRatings()
              else ...[
                if (featured != null)
                  _FeaturedReviewCard(
                    game: featured,
                    rating: _ratingOutOfTen(featured.userRating),
                    genre: featured.genre.trim().isEmpty
                        ? 'Жанр не указан'
                        : featured.genre.trim(),
                    releaseText: _releaseYearText(featured.year),
                    reviewDateText: _formattedDate(_ratingDate(featured)),
                    statusColor: _statusColor(featured.status),
                    statusText: _statusText(featured.status),
                    comment: _commentPreview(featured.comment),
                    timeText: _timeText(featured),
                    onTap: () => _openGame(featured),
                  ),
                if (otherRatedGames.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Column(
                    children: otherRatedGames.map((game) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _SmallReviewCard(
                          game: game,
                          rating: _ratingOutOfTen(game.userRating),
                          statusText: _statusText(game.status),
                          comment: _commentPreview(game.comment),
                          genre: game.genre.trim().isEmpty
                              ? 'Жанр не указан'
                              : game.genre.trim(),
                          timeText: _timeText(game),
                          onTap: () => _openGame(game),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTopHeader extends StatelessWidget {
  const _ProfileTopHeader({
    required this.onEditTap,
    required this.onNotificationsTap,
    required this.onSettingsTap,
  });

  final VoidCallback onEditTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettingsTap;

  static const Color accent = Color(0xFF22D3EE);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(
              Icons.person_rounded,
              color: accent,
              size: 30,
            ),
            SizedBox(width: 12),
            Text(
              'Профиль',
              style: TextStyle(
                color: accent,
                fontSize: 24,
                height: 1.33,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderIconButton(
              icon: Icons.edit_rounded,
              onTap: onEditTap,
            ),
            const SizedBox(width: 10),
            _HeaderIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: onNotificationsTap,
            ),
            const SizedBox(width: 10),
            _HeaderIconButton(
              icon: Icons.settings_rounded,
              onTap: onSettingsTap,
            ),
          ],
        ),
      ],
    );
  }
}


class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          icon,
          color: const Color(0xFF75EEFD),
          size: 23,
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.gamesCount,
    required this.completedCount,
    required this.favoriteGenre,
    required this.platforms,
  });

  final UserProfileModel profile;
  final int gamesCount;
  final int completedCount;
  final String favoriteGenre;
  final List<String> platforms;

  @override
  Widget build(BuildContext context) {
    final statusText = profile.status.trim().isEmpty
        ? 'СТАТУС НЕ УКАЗАН'
        : profile.status.trim().toUpperCase();

    final avatarPath = profile.avatarPath;
    final hasAvatar = avatarPath != null && File(avatarPath).existsSync();

    return Column(
      children: [
        Center(
          child: Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF111414),
              border: Border.all(
                color: const Color(0xFF232626),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF164E63).withOpacity(0.2),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                ),
              ],
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.file(
                File(avatarPath),
                fit: BoxFit.cover,
              )
                  : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF12343A),
                      Color(0xFF071010),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.sports_esports_rounded,
                    color: Color(0xFF22D3EE),
                    size: 58,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          profile.name.trim().isEmpty ? 'Имя не указано' : profile.name.trim(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF4F3F3),
            fontSize: 36,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 12),
        _ProfileScrollingInfoBlock(
          platforms: platforms,
          statusText: '$statusText • $gamesCount ИГР ОТСЛЕЖИВАЕТСЯ',
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _ProfileBadge(
                text: '$completedCount ИГР ПРОЙДЕНО',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileBadge(
                text: 'ЛЮБИМЫЙ ЖАНР - $favoriteGenre',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileScrollingInfoBlock extends StatefulWidget {
  const _ProfileScrollingInfoBlock({
    required this.platforms,
    required this.statusText,
  });

  final List<String> platforms;
  final String statusText;

  @override
  State<_ProfileScrollingInfoBlock> createState() =>
      _ProfileScrollingInfoBlockState();
}

class _ProfileScrollingInfoBlockState extends State<_ProfileScrollingInfoBlock> {
  final ScrollController _platformsController = ScrollController();
  final ScrollController _statusController = ScrollController();

  int _animationRunId = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSynchronizedAutoScroll();
    });
  }

  @override
  void didUpdateWidget(covariant _ProfileScrollingInfoBlock oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldPlatforms = oldWidget.platforms.join('|');
    final newPlatforms = widget.platforms.join('|');

    if (oldPlatforms != newPlatforms || oldWidget.statusText != widget.statusText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startSynchronizedAutoScroll();
      });
    }
  }

  Future<void> _startSynchronizedAutoScroll() async {
    final int runId = ++_animationRunId;

    if (!_platformsController.hasClients || !_statusController.hasClients) {
      return;
    }

    final double platformsMaxScroll =
        _platformsController.position.maxScrollExtent;
    final double statusMaxScroll = _statusController.position.maxScrollExtent;

    if (platformsMaxScroll <= 0 && statusMaxScroll <= 0) {
      _jumpToStart();
      return;
    }

    _jumpToStart();

    while (mounted && runId == _animationRunId) {
      await Future.delayed(const Duration(milliseconds: 700));

      if (!_canContinue(runId)) return;

      await Future.wait([
        _animateControllerTo(
          controller: _platformsController,
          offset: platformsMaxScroll,
        ),
        _animateControllerTo(
          controller: _statusController,
          offset: statusMaxScroll,
        ),
      ]);

      if (!_canContinue(runId)) return;

      await Future.delayed(const Duration(milliseconds: 700));

      if (!_canContinue(runId)) return;

      await Future.wait([
        _animateControllerTo(
          controller: _platformsController,
          offset: 0,
        ),
        _animateControllerTo(
          controller: _statusController,
          offset: 0,
        ),
      ]);
    }
  }

  bool _canContinue(int runId) {
    return mounted &&
        runId == _animationRunId &&
        _platformsController.hasClients &&
        _statusController.hasClients;
  }

  void _jumpToStart() {
    if (_platformsController.hasClients) {
      _platformsController.jumpTo(0);
    }

    if (_statusController.hasClients) {
      _statusController.jumpTo(0);
    }
  }

  Future<void> _animateControllerTo({
    required ScrollController controller,
    required double offset,
  }) async {
    if (!controller.hasClients) {
      return;
    }

    final double maxScroll = controller.position.maxScrollExtent;
    final double safeOffset = offset.clamp(0.0, maxScroll).toDouble();

    await controller.animateTo(
      safeOffset,
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationRunId++;
    _platformsController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.platforms.isNotEmpty) ...[
          _SynchronizedPlatformsRow(
            platforms: widget.platforms,
            controller: _platformsController,
          ),
          const SizedBox(height: 14),
        ],
        _SynchronizedStatusText(
          text: widget.statusText,
          controller: _statusController,
        ),
      ],
    );
  }
}

class _SynchronizedPlatformsRow extends StatelessWidget {
  const _SynchronizedPlatformsRow({
    required this.platforms,
    required this.controller,
  });

  final List<String> platforms;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < platforms.length; i++) ...[
                    _ProfilePlatformBadge(text: platforms[i]),
                    if (i != platforms.length - 1) const SizedBox(width: 8),
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

class _SynchronizedStatusText extends StatelessWidget {
  const _SynchronizedStatusText({
    required this.text,
    required this.controller,
  });

  final String text;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: Center(
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF22D3EE),
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfilePlatformBadge extends StatelessWidget {
  const _ProfilePlatformBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 13),
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

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141818),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF2A2E2E),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFAAABAB),
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFF4F3F3),
        fontSize: 26,
        height: 1.25,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.6,
      ),
    );
  }
}

class _FeaturedReviewCard extends StatelessWidget {
  const _FeaturedReviewCard({
    required this.game,
    required this.rating,
    required this.genre,
    required this.releaseText,
    required this.reviewDateText,
    required this.statusColor,
    required this.statusText,
    required this.comment,
    required this.timeText,
    required this.onTap,
  });

  final LibraryGameModel game;
  final double rating;
  final String genre;
  final String releaseText;
  final String reviewDateText;
  final Color statusColor;
  final String statusText;
  final String comment;
  final String timeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111414),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF111414),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF232626),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FeaturedCover(
                localImagePath: game.localImagePath,
                imageUrl: game.imageUrl,
                statusText: statusText,
                statusColor: statusColor,
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 30,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _FeaturedGameInfoBadges(
                      genreText: genre,
                      yearText: releaseText,
                    ),
                    const SizedBox(height: 24),
                    _ReviewRatingBadge(
                      rating: rating,
                      height: 54,
                      width: double.infinity,
                      horizontalPadding: 18,
                      borderRadius: 12,
                      fontSize: 30,
                      starSize: 25,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111414),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0x6632B8C6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF75EEFD).withOpacity(0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                color: Color(0xFF75EEFD),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Мой комментарий',
                                style: TextStyle(
                                  color: Color(0xFF75EEFD),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ExpandableFeaturedComment(
                            comment: comment,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: const Color(0xFF232626),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _FeaturedTimePill(
                          timeText: timeText,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FeaturedReviewDatePill(
                            dateText: reviewDateText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ExpandableFeaturedComment extends StatefulWidget {
  const _ExpandableFeaturedComment({
    required this.comment,
  });

  final String comment;

  @override
  State<_ExpandableFeaturedComment> createState() =>
      _ExpandableFeaturedCommentState();
}

class _ExpandableFeaturedCommentState extends State<_ExpandableFeaturedComment> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    const commentStyle = TextStyle(
      color: Color(0xFFAAABAB),
      fontSize: 14,
      height: 1.65,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
    );

    final commentText = widget.comment;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: commentText,
            style: commentStyle,
          ),
          maxLines: 4,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final canExpand = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              commentText,
              maxLines: isExpanded ? null : 4,
              overflow: isExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: commentStyle,
            ),
            if (canExpand) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded ? 'СВЕРНУТЬ' : 'РАСКРЫТЬ',
                      style: const TextStyle(
                        color: Color(0xFF75EEFD),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF75EEFD),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FeaturedGameInfoBadges extends StatelessWidget {
  const _FeaturedGameInfoBadges({
    required this.genreText,
    required this.yearText,
  });

  final String genreText;
  final String yearText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _FeaturedGameInfoBadge(text: genreText),
            const SizedBox(width: 8),
            _FeaturedGameInfoBadge(text: yearText),
          ],
        ),
      ),
    );
  }
}

class _FeaturedGameInfoBadge extends StatelessWidget {
  const _FeaturedGameInfoBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 13),
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
        overflow: TextOverflow.ellipsis,
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

class _FeaturedReviewDatePill extends StatelessWidget {
  const _FeaturedReviewDatePill({
    required this.dateText,
  });

  final String dateText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF082326),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x6632B8C6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            color: Color(0xFF22D3EE),
            size: 15,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ОЦЕНЕНО:',
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: Color(0xFFA8A29E),
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.45,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: double.infinity,
                  height: 14,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      dateText,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Color(0xFF22D3EE),
                        fontSize: 12,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedTimePill extends StatelessWidget {
  const _FeaturedTimePill({
    required this.timeText,
  });

  final String timeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF082326),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x6632B8C6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: Color(0xFF22D3EE),
            size: 15,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 78,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ВРЕМЯ В ИГРЕ:',
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: Color(0xFFA8A29E),
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.45,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: double.infinity,
                  height: 14,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      timeText,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Color(0xFF22D3EE),
                        fontSize: 12,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCover extends StatelessWidget {
  const _FeaturedCover({
    required this.localImagePath,
    required this.imageUrl,
    required this.statusText,
    required this.statusColor,
  });

  final String? localImagePath;
  final String? imageUrl;
  final String statusText;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 256,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GameCover(
              width: double.infinity,
              height: 256,
              localImagePath: localImagePath,
              imageUrl: imageUrl,
              borderRadius: 0,
              iconSize: 82,
              gradientOpacity: 0.18,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.32),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: _StatusPill(
              text: statusText,
              color: statusColor,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallReviewCard extends StatelessWidget {
  const _SmallReviewCard({
    required this.game,
    required this.rating,
    required this.statusText,
    required this.comment,
    required this.genre,
    required this.timeText,
    required this.onTap,
  });

  final LibraryGameModel game;
  final double rating;
  final String statusText;
  final String comment;
  final String genre;
  final String timeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 122,
          decoration: BoxDecoration(
            color: const Color(0xFF141818),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF262A2A),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 14,
                top: 14,
                bottom: 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 94,
                    child: GameCover(
                      width: 94,
                      height: 94,
                      localImagePath: game.localImagePath,
                      imageUrl: game.imageUrl,
                      borderRadius: 0,
                      iconSize: 34,
                      gradientOpacity: 0.12,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(124, 15, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            game.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 18,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CompactRatingBadge(rating: rating),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          flex: 11,
                          child: _SmallMetaPill(
                            text: statusText,
                            color: const Color(0xFF22D3EE),
                            maxWidth: 64,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          flex: 10,
                          child: _SmallMetaPill(
                            text: genre.toUpperCase(),
                            color: const Color(0xFF22D3EE),
                            maxWidth: 64,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          flex: 8,
                          child: _SmallMetaPill(
                            text: timeText,
                            color: const Color(0xFF22D3EE),
                            maxWidth: 56,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      comment,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8C8985),
                        fontSize: 13,
                        height: 1.25,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallMetaPill extends StatelessWidget {
  const _SmallMetaPill({
    required this.text,
    required this.color,
    required this.maxWidth,
  });

  final String text;
  final Color color;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
      ),
      child: Container(
        height: 19,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10262B),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0x5532B8C6),
            width: 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: color,
              fontSize: 8.5,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.color,
    this.filled = false,
  });

  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final textColor = filled
        ? color == const Color(0xFFBBFFB3)
        ? const Color(0xFF00671A)
        : const Color(0xFF00272B)
        : color;

    return Container(
      height: filled ? 24 : 22,
      padding: EdgeInsets.symmetric(horizontal: filled ? 14 : 10),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: filled
            ? null
            : Border.all(
          color: color.withOpacity(0.24),
        ),
        boxShadow: filled
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: filled ? 10 : 9,
          height: 1.2,
          fontWeight: FontWeight.w900,
          letterSpacing: filled ? 1 : 0.8,
        ),
      ),
    );
  }
}

class _ReviewRatingBadge extends StatelessWidget {
  const _ReviewRatingBadge({
    required this.rating,
    required this.height,
    required this.horizontalPadding,
    required this.borderRadius,
    required this.fontSize,
    required this.starSize,
    this.width,
  });

  final double rating;
  final double height;
  final double horizontalPadding;
  final double borderRadius;
  final double fontSize;
  final double starSize;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final color = _ratingScaleColor(rating);
    final verdictText = _ratingVerdictText(rating);

    final ratingContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatRating(rating),
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.star_rounded,
          color: color,
          size: starSize,
        ),
      ],
    );

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.centerLeft,
      child: width == null
          ? ratingContent
          : Row(
        children: [
          ratingContent,
          const SizedBox(width: 14),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                height: 30,
                constraints: const BoxConstraints(
                  maxWidth: 132,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: color.withOpacity(0.38),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    verdictText,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactRatingBadge extends StatelessWidget {
  const _CompactRatingBadge({
    required this.rating,
  });

  final double rating;

  @override
  Widget build(BuildContext context) {
    final color = _ratingScaleColor(rating);

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatRating(rating),
            style: TextStyle(
              color: color,
              fontSize: 15,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.star_rounded,
            color: color,
            size: 15,
          ),
        ],
      ),
    );
  }
}

class _EmptyProfileRatings extends StatelessWidget {
  const _EmptyProfileRatings();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 44,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: Color(0xFF57534E),
            size: 56,
          ),
          SizedBox(height: 16),
          Text(
            'Оценок пока нет',
            style: TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Поставьте оценку игре, чтобы она появилась в профиле',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/library_game_model.dart';
import '../../models/user_profile_model.dart';
import '../../storage/library_storage.dart';
import '../../storage/profile_storage.dart';
import '../game_progress/game_progress_screen.dart';

String _formatRating(double rating) {
  final roundedRating = double.parse(rating.toStringAsFixed(1));

  if (roundedRating == roundedRating.roundToDouble()) {
    return roundedRating.toInt().toString();
  }

  return roundedRating.toStringAsFixed(1);
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
    name: 'GamerOne',
    status: 'Master Explorer',
    favoriteGenres: [],
    avatarPath: null,
  );

  List<LibraryGameModel> games = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
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
      return b.addedAt.compareTo(a.addedAt);
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

      return b.addedAt.compareTo(a.addedAt);
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
      final genre = game.genre.trim().isEmpty ? 'Action' : game.genre.trim();
      genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
    }

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
              const _ProfileTopHeader(),
              const SizedBox(height: 36),
              _ProfileHero(
                profile: profile,
                gamesCount: games.length,
                completedCount: completedGames.length,
                favoriteGenre: favoriteGenre,
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
                        ? 'Action'
                        : featured.genre.trim(),
                    dateText: _formattedDate(featured.addedAt),
                    statusColor: _statusColor(featured.status),
                    statusText: _statusText(featured.status),
                    comment: _commentPreview(featured.comment),
                    onTap: () => _openGame(featured),
                  ),
                if (otherRatedGames.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Column(
                    children: otherRatedGames.map((game) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _SmallReviewCard(
                          game: game,
                          rating: _ratingOutOfTen(game.userRating),
                          statusColor: _statusColor(game.status),
                          statusText: _statusText(game.status),
                          comment: _commentPreview(game.comment),
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
  const _ProfileTopHeader();

  static const Color accent = Color(0xFF22D3EE);
  static const Color muted = Color(0xFFA8A29E);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF111414),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0x3375EEFD),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
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
            IconButton(
              onPressed: () {},
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 34,
                minHeight: 34,
              ),
              icon: const Icon(
                Icons.edit_rounded,
                color: muted,
                size: 22,
              ),
            ),
            IconButton(
              onPressed: () {},
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 34,
                minHeight: 34,
              ),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: muted,
                size: 24,
              ),
            ),
            IconButton(
              onPressed: () {},
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 34,
                minHeight: 34,
              ),
              icon: const Icon(
                Icons.settings_rounded,
                color: muted,
                size: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.gamesCount,
    required this.completedCount,
    required this.favoriteGenre,
  });

  final UserProfileModel profile;
  final int gamesCount;
  final int completedCount;
  final String favoriteGenre;

  @override
  Widget build(BuildContext context) {
    final statusText = profile.status.trim().isEmpty
        ? 'MASTER EXPLORER'
        : profile.status.trim().toUpperCase();

    final avatarPath = profile.avatarPath;
    final hasAvatar = avatarPath != null && File(avatarPath).existsSync();

    return Column(
      children: [
        Center(
          child: Container(
            width: 128,
            height: 128,
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
                    size: 52,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          profile.name.trim().isEmpty ? 'GamerOne' : profile.name.trim(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF4F3F3),
            fontSize: 36,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$statusText • $gamesCount ИГР ОТСЛЕЖИВАЕТСЯ',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF22D3EE),
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
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

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF232626),
        borderRadius: BorderRadius.circular(999),
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
            color: Color(0xFFD6D3D1),
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w800,
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
    required this.dateText,
    required this.statusColor,
    required this.statusText,
    required this.comment,
    required this.onTap,
  });

  final LibraryGameModel game;
  final double rating;
  final String genre;
  final String dateText;
  final Color statusColor;
  final String statusText;
  final String comment;
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
                padding: const EdgeInsets.all(32),
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
                    const SizedBox(height: 6),
                    Text(
                      '$genre • $dateText',
                      style: const TextStyle(
                        color: Color(0xFF78716C),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 54,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C0A09),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0x3322D3EE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _formatRating(rating),
                            style: const TextStyle(
                              color: Color(0xFF22D3EE),
                              fontSize: 30,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFF22D3EE),
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'МОЙ КОММЕНТАРИЙ',
                      style: TextStyle(
                        color: Color(0xFFA8A29E),
                        fontSize: 10,
                        height: 1.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(left: 20),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Color(0xFF22D3EE),
                            width: 4,
                          ),
                        ),
                      ),
                      child: Text(
                        '«$comment»',
                        style: const TextStyle(
                          color: Color(0xFFE7E5E4),
                          fontSize: 18,
                          height: 1.62,
                          fontStyle: FontStyle.italic,
                        ),
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
                        const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFF22D3EE),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ВРЕМЯ\nВ ИГРЕ:',
                          style: TextStyle(
                            color: Color(0xFFA8A29E),
                            fontSize: 11,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${game.userHours}ч',
                          style: const TextStyle(
                            color: Color(0xFF22D3EE),
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'ОЦЕНЕНО:\n$dateText',
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Color(0xFF57534E),
                            fontSize: 10,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.7,
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
            child: _GameCoverArt(
              localImagePath: localImagePath,
              imageUrl: imageUrl,
              iconSize: 82,
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor == const Color(0xFFBBFFB3)
                      ? const Color(0xFF00671A)
                      : const Color(0xFF00272B),
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
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
    required this.statusColor,
    required this.statusText,
    required this.comment,
    required this.onTap,
  });

  final LibraryGameModel game;
  final double rating;
  final Color statusColor;
  final String statusText;
  final String comment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1D2020),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 128,
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _GameCoverArt(
                    localImagePath: game.localImagePath,
                    imageUrl: game.imageUrl,
                    iconSize: 34,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            game.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatRating(rating),
                          style: const TextStyle(
                            color: Color(0xFF22D3EE),
                            fontSize: 18,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF78716C),
                        fontSize: 12,
                        height: 1.3,
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

class _GameCoverArt extends StatelessWidget {
  const _GameCoverArt({
    required this.localImagePath,
    required this.imageUrl,
    required this.iconSize,
  });

  final String? localImagePath;
  final String? imageUrl;
  final double iconSize;

  bool get _hasLocalImage {
    final path = localImagePath;

    if (path == null || path.trim().isEmpty) {
      return false;
    }

    return File(path).existsSync();
  }

  bool get _hasNetworkImage {
    final url = imageUrl;

    return url != null && url.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCover(),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF111414).withOpacity(0.92),
                  const Color(0xFF111414).withOpacity(0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.52, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCover() {
    if (_hasLocalImage) {
      return Image.file(
        File(localImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildNetworkOrFallback();
        },
      );
    }

    return _buildNetworkOrFallback();
  }

  Widget _buildNetworkOrFallback() {
    if (!_hasNetworkImage) {
      return _GameCoverFallback(
        iconSize: iconSize,
      );
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return _GameCoverFallback(
          iconSize: iconSize,
          showLoader: true,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _GameCoverFallback(
          iconSize: iconSize,
        );
      },
    );
  }
}

class _GameCoverFallback extends StatelessWidget {
  const _GameCoverFallback({
    required this.iconSize,
    this.showLoader = false,
  });

  final double iconSize;
  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    if (showLoader) {
      return const ColoredBox(
        color: Color(0xFF172026),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF22D3EE),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF172026),
            Color(0xFF263A3A),
            Color(0xFF111414),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: Colors.white54,
          size: iconSize,
        ),
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
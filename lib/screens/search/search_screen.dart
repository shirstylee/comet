import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/game_model.dart';
import '../../services/rawg_api_service.dart';
import '../../widgets/game_search_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Color background = Color(0xFF0C0F0F);

  final TextEditingController searchController = TextEditingController();
  final RawgApiService rawgApiService = RawgApiService();

  Timer? searchDebounce;

  List<GameModel> results = [];
  bool isLoading = false;
  String? errorMessage;

  int searchRequestId = 0;

  String lastSearchedQuery = '';
  int resultsListVersion = 0;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_searchGames);
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    searchController.removeListener(_searchGames);
    searchController.dispose();
    super.dispose();
  }

  void _searchGames({
    bool force = false,
  }) {
    final query = searchController.text.trim();

    searchDebounce?.cancel();

    if (query.isEmpty) {
      searchRequestId++;
      lastSearchedQuery = '';
      resultsListVersion++;

      setState(() {
        results = [];
        isLoading = false;
        errorMessage = null;
      });

      return;
    }

    if (!force && query == lastSearchedQuery) {
      return;
    }

    searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      final currentQuery = searchController.text.trim();

      if (currentQuery.isEmpty) {
        return;
      }

      if (!force && currentQuery == lastSearchedQuery) {
        return;
      }

      lastSearchedQuery = currentQuery;
      resultsListVersion++;

      final currentRequestId = ++searchRequestId;

      setState(() {
        isLoading = true;
        errorMessage = null;
        results = [];
      });

      try {
        final foundGames = await rawgApiService.searchGames(currentQuery);

        if (!mounted || currentRequestId != searchRequestId) return;

        setState(() {
          results = foundGames;
          isLoading = false;
        });
      } catch (_) {
        if (!mounted || currentRequestId != searchRequestId) return;

        setState(() {
          isLoading = false;
          errorMessage = 'Не удалось загрузить игры. Проверьте интернет.';
        });
      }
    });
  }

  void _clearSearch() {
    searchController.clear();
  }

  bool get _isInitialState => searchController.text.trim().isEmpty;

  bool get _isNoResultsState =>
      searchController.text.trim().isNotEmpty &&
          !isLoading &&
          errorMessage == null &&
          results.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          _SearchHeader(
            controller: searchController,
            onBack: () => Navigator.pop(context),
            onClear: _clearSearch,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialState) {
      return const _InitialSearchState(
        key: ValueKey('initial-search-state'),
      );
    }

    if (isLoading) {
      return const _LoadingSearchState(
        key: ValueKey('loading-search-state'),
      );
    }

    if (errorMessage != null) {
      return _SearchErrorState(
        key: const ValueKey('error-search-state'),
        message: errorMessage!,
        onRetry: () => _searchGames(force: true),
      );
    }

    if (_isNoResultsState) {
      return _NoResultsState(
        key: const ValueKey('no-results-state'),
        query: searchController.text.trim(),
      );
    }

    return _ResultsState(
      key: ValueKey('results-state-$resultsListVersion'),
      results: results,
      listKey: 'search-results-list-$resultsListVersion',
    );
  }
}

class _SearchHeader extends StatefulWidget {
  const _SearchHeader({
    required this.controller,
    required this.onBack,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  State<_SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<_SearchHeader> {
  final FocusNode focusNode = FocusNode();

  static const Color headerColor = Color(0xCC0C0F0F);
  static const Color borderColor = Color(0xFF232626);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  @override
  void initState() {
    super.initState();

    focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _SearchHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  void _onFocusChanged() {
    if (!mounted) return;

    setState(() {});
  }

  void _onTextChanged() {
    if (!mounted) return;

    setState(() {});
  }

  void _focusSearch() {
    focusNode.requestFocus();
  }

  void _clearSearch() {
    widget.onClear();
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;

    return SafeArea(
      bottom: false,
      child: Container(
        height: 67,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: headerColor,
          border: Border(
            bottom: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onBack,
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
            const SizedBox(width: 12),
            Expanded(
              child: TextFieldTapRegion(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: 42,
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isFocused
                          ? const [
                        Color(0xFF111C1D),
                        Color(0xFF1B2424),
                        Color(0xFF102B2F),
                      ]
                          : const [
                        Color(0xFF151A1A),
                        Color(0xFF202424),
                        Color(0xFF141A1A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isFocused
                          ? const Color(0x8875EEFD)
                          : const Color(0x5532B8C6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: const Color(0xFF75EEFD).withOpacity(
                          isFocused ? 0.12 : 0.055,
                        ),
                        blurRadius: isFocused ? 22 : 16,
                        spreadRadius: isFocused ? 0.4 : 0,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _focusSearch,
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isFocused
                                ? const Color(0x2275EEFD)
                                : const Color(0x1022D3EE),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isFocused
                                  ? const Color(0x7775EEFD)
                                  : const Color(0x4432B8C6),
                            ),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: isFocused
                                ? const Color(0xFF75EEFD)
                                : const Color(0xFFAAABAB),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          focusNode: focusNode,
                          controller: widget.controller,
                          autofocus: true,
                          cursorColor: const Color(0xFF75EEFD),
                          textInputAction: TextInputAction.search,
                          onTapOutside: (_) {
                            focusNode.unfocus();
                          },
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Начните вводить название',
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintStyle: TextStyle(
                              color: textSecondary.withOpacity(0.72),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: hasText
                            ? Padding(
                          key: const ValueKey('clear_search_screen_button'),
                          padding: const EdgeInsets.only(left: 8),
                          child: GestureDetector(
                            onTap: _clearSearch,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0x1A75EEFD),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0x5575EEFD),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF75EEFD)
                                        .withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF75EEFD),
                                size: 17,
                              ),
                            ),
                          ),
                        )
                            : const SizedBox.shrink(
                          key: ValueKey('empty_clear_search_screen_button'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialSearchState extends StatelessWidget {
  const _InitialSearchState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SearchStateIcon(
              icon: Icons.explore_rounded,
              color: Color(0xFF75EEFD),
              backgroundColor: Color(0x1A75EEFD),
              size: 96,
              iconSize: 42,
            ),
            SizedBox(height: 24),
            Text(
              'Поиск новых миров',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF75EEFD),
                fontSize: 30,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.75,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Найдите любой тайтл среди тысяч\nигр и добавьте на свою орбиту',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFAAABAB),
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSearchState extends StatelessWidget {
  const _LoadingSearchState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF75EEFD),
          ),
          SizedBox(height: 24),
          Text(
            'Ловим сигнал...',
            style: TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Сканируем игровую вселенную',
            style: TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({
    super.key,
    required this.query,
  });

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          const _ResultsTitle(
            count: 0,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.manage_search_rounded,
                      color: const Color(0xFFAAABAB).withOpacity(0.3),
                      size: 76,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Ничего не найдено',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFF4F3F3),
                        fontSize: 24,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'По запросу "$query" ничего не найдено.\n'
                          'Попробуйте изменить название игры.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFAAABAB),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchErrorState extends StatelessWidget {
  const _SearchErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: const Color(0xFFAAABAB).withOpacity(0.35),
              size: 76,
            ),
            const SizedBox(height: 28),
            const Text(
              'Ошибка загрузки',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF4F3F3),
                fontSize: 24,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFAAABAB),
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF75EEFD),
                ),
                label: const Text(
                  'Повторить',
                  style: TextStyle(
                    color: Color(0xFF75EEFD),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF75EEFD),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsState extends StatelessWidget {
  const _ResultsState({
    super.key,
    required this.results,
    required this.listKey,
  });

  final List<GameModel> results;
  final String listKey;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: PageStorageKey<String>(listKey),
      cacheExtent: 2400,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      itemCount: results.length + 1,
      separatorBuilder: (_, index) {
        if (index == 0) return const SizedBox(height: 24);
        return const SizedBox(height: 16);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return _ResultsTitle(
            count: results.length,
          );
        }

        final gameIndex = index - 1;
        final game = results[gameIndex];

        return GameSearchCard(
          key: ValueKey('search-game-${game.id}'),
          game: game,
          index: gameIndex,
        );
      },
    );
  }
}

class _ResultsTitle extends StatelessWidget {
  const _ResultsTitle({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Результаты',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _ResultsCountBadge(
          count: count,
        ),
      ],
    );
  }
}

class _ResultsCountBadge extends StatelessWidget {
  const _ResultsCountBadge({
    required this.count,
  });

  final int count;

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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'Найдено: $count',
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

class _SearchStateIcon extends StatelessWidget {
  const _SearchStateIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: iconSize,
      ),
    );
  }
}

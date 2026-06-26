import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile_model.dart';
import '../../services/avatar_storage_service.dart';
import '../../storage/profile_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  final UserProfileModel profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color background = Color(0xFF0C0F0F);
  static const Color accent = Color(0xFF75EEFD);
  static const Color accentDark = Color(0xFF00575F);
  static const Color fieldColor = Color(0xFF232626);

  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController statusController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  File? avatarFile;
  String? currentAvatarPath;
  bool isSaving = false;

  final List<String> platforms = const [
    'PC',
    'PlayStation',
    'Xbox',
    'Nintendo',
    'Mobile',
  ];

  final Set<String> selectedPlatforms = {};

  @override
  void initState() {
    super.initState();

    nicknameController.text = widget.profile.name;
    statusController.text = widget.profile.status;
    currentAvatarPath = widget.profile.avatarPath;
    selectedPlatforms.addAll(widget.profile.favoritePlatforms);
  }

  @override
  void dispose() {
    nicknameController.dispose();
    statusController.dispose();
    super.dispose();
  }

  Future<void> pickAvatar() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      avatarFile = File(image.path);
      currentAvatarPath = image.path;
    });
  }

  void togglePlatform(String platform) {
    setState(() {
      if (selectedPlatforms.contains(platform)) {
        selectedPlatforms.remove(platform);
      } else {
        selectedPlatforms.add(platform);
      }
    });
  }

  void showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFFE57373),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> saveProfile() async {
    final nickname = nicknameController.text.trim();
    final status = statusController.text.trim();

    if (nickname.isEmpty) {
      showError('Введите никнейм');
      return;
    }

    if (status.isEmpty) {
      showError('Введите статус');
      return;
    }

    if (selectedPlatforms.isEmpty) {
      showError('Выберите хотя бы одну платформу');
      return;
    }

    final hasAvatar = avatarFile != null ||
        (currentAvatarPath != null &&
            currentAvatarPath!.trim().isNotEmpty &&
            File(currentAvatarPath!).existsSync());

    if (!hasAvatar) {
      showError('Загрузите аватар');
      return;
    }

    setState(() {
      isSaving = true;
    });

    String? copiedAvatarPath;

    try {
      String? avatarPathToSave = currentAvatarPath;

      if (avatarFile != null) {
        copiedAvatarPath = await AvatarStorageService.saveAvatar(avatarFile!);
        avatarPathToSave = copiedAvatarPath;
      } else if (currentAvatarPath != null &&
          currentAvatarPath!.trim().isNotEmpty &&
          File(currentAvatarPath!).existsSync() &&
          !(await AvatarStorageService.isManagedAvatarPath(currentAvatarPath))) {
        copiedAvatarPath = await AvatarStorageService.saveAvatar(
          File(currentAvatarPath!),
        );
        avatarPathToSave = copiedAvatarPath;
      }

      await ProfileStorage.saveProfile(
        UserProfileModel(
          name: nickname,
          status: status,
          favoritePlatforms: selectedPlatforms.toList(),
          avatarPath: avatarPathToSave,
        ),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (copiedAvatarPath != null) {
        await AvatarStorageService.deleteAvatar(copiedAvatarPath);
      }

      if (!mounted) return;

      showError('Не удалось сохранить профиль');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final int statusLength = statusController.text.length;

    final bool hasCurrentAvatar = currentAvatarPath != null &&
        currentAvatarPath!.trim().isNotEmpty &&
        File(currentAvatarPath!).existsSync();

    ImageProvider? avatarImage;

    if (avatarFile != null) {
      avatarImage = FileImage(avatarFile!);
    } else if (hasCurrentAvatar) {
      avatarImage = FileImage(File(currentAvatarPath!));
    }

    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: GestureDetector(
          onTap: closeKeyboard,
          child: Column(
            children: [
              _EditProfileHeader(
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: pickAvatar,
                        child: CircleAvatar(
                          radius: 64,
                          backgroundColor: fieldColor,
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? Icon(
                            Icons.add_photo_alternate_rounded,
                            color: accent.withOpacity(0.7),
                            size: 34,
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: pickAvatar,
                        child: const Text(
                          'ИЗМЕНИТЬ АВАТАР',
                          style: TextStyle(
                            color: accent,
                            fontSize: 14,
                            height: 1.43,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _LabeledInput(
                        label: 'НИКНЕЙМ',
                        controller: nicknameController,
                        hint: 'Введите ваш никнейм',
                        maxLength: 20,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      _LabeledInput(
                        label: 'СТАТУС',
                        controller: statusController,
                        hint: 'Коротко о себе',
                        maxLength: 20,
                        showCounter: true,
                        counterText: '$statusLength/20',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 28),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ВЫБОР ПЛАТФОРМЫ',
                            style: TextStyle(
                              color: Color(0xFFAAABAB),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Выберите основные',
                            style: TextStyle(
                              color: Color(0xCCAAABAB),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: platforms.map((platform) {
                            final bool isSelected =
                            selectedPlatforms.contains(platform);

                            return GestureDetector(
                              onTap: () => togglePlatform(platform),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0x0D22D3EE)
                                      : const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0x8022D3EE)
                                        : Colors.white.withOpacity(0.05),
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                    BoxShadow(
                                      color: const Color(0xFF22D3EE)
                                          .withOpacity(0.1),
                                      blurRadius: 10,
                                    ),
                                  ]
                                      : [],
                                ),
                                child: Text(
                                  platform,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF22D3EE)
                                        : const Color(0xCCAAABAB),
                                    fontSize: 14,
                                    height: 1.43,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF75EEFD),
                                Color(0xFF25B0BE),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isSaving ? null : saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Сохранить',
                              style: TextStyle(
                                color: accentDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _EditProfileHeader extends StatelessWidget {
  const _EditProfileHeader({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F0F).withOpacity(0.80),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
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
          ),
          const Text(
            'Профиль',
            style: TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCounterPill extends StatelessWidget {
  const _InputCounterPill({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      constraints: const BoxConstraints(
        minWidth: 54,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x5532B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          color: Color(0xFF75EEFD),
          fontSize: 12,
          height: 1.1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _LabeledInput extends StatefulWidget {
  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.maxLength,
    this.showCounter = false,
    this.counterText,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final int? maxLength;
  final bool showCounter;
  final String? counterText;

  @override
  State<_LabeledInput> createState() => _LabeledInputState();
}

class _LabeledInputState extends State<_LabeledInput> {
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _LabeledInput oldWidget) {
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

  void _clearText() {
    widget.controller.clear();
    widget.onChanged('');
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 12,
              height: 1.33,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFieldTapRegion(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 55,
            padding: const EdgeInsets.fromLTRB(18, 0, 8, 0),
            decoration: BoxDecoration(
              color: isFocused
                  ? const Color(0xFF111C1D)
                  : const Color(0xFF151A1A),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isFocused
                    ? const Color(0x8875EEFD)
                    : const Color(0x5532B8C6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.34),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF75EEFD).withOpacity(
                    isFocused ? 0.12 : 0.055,
                  ),
                  blurRadius: isFocused ? 26 : 18,
                  spreadRadius: isFocused ? 0.6 : 0,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
                    controller: widget.controller,
                    maxLength: widget.maxLength,
                    onChanged: widget.onChanged,
                    onTapOutside: (_) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    cursorColor: const Color(0xFF75EEFD),
                    scrollPadding: EdgeInsets.zero,
                    style: const TextStyle(
                      color: Color(0xFFF4F3F3),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      counterText: '',
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintStyle: TextStyle(
                        color: const Color(0xFFAAABAB).withOpacity(0.72),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
                if (widget.showCounter) ...[
                  const SizedBox(width: 8),
                  _InputCounterPill(
                    text: widget.counterText ?? '',
                  ),
                ],
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
                    key: const ValueKey('clear_profile_input_button'),
                    padding: const EdgeInsets.only(left: 10),
                    child: GestureDetector(
                      onTap: _clearText,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 36,
                        height: 36,
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
                          size: 19,
                        ),
                      ),
                    ),
                  )
                      : const SizedBox.shrink(
                    key: ValueKey('empty_clear_profile_input_button'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

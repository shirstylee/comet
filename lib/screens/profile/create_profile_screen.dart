import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile_model.dart';
import '../../storage/profile_storage.dart';
import '../main/main_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  static const Color background = Color(0xFF0C0F0F);
  static const Color accent = Color(0xFF75EEFD);
  static const Color fieldColor = Color(0xFF232626);

  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController statusController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  File? avatarFile;

  final List<String> platforms = [
    'PC',
    'PlayStation',
    'Xbox',
    'Nintendo',
    'Mobile',
  ];

  final Set<String> selectedPlatforms = {};

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
    ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> goToMainScreen() async {
    if (avatarFile == null) {
      showError('Загрузите аватар');
      return;
    }

    if (nicknameController.text.trim().isEmpty) {
      showError('Введите никнейм');
      return;
    }

    if (statusController.text.trim().isEmpty) {
      showError('Введите статус');
      return;
    }

    if (selectedPlatforms.isEmpty) {
      showError('Выберите хотя бы одну платформу');
      return;
    }

    await ProfileStorage.saveProfile(
      UserProfileModel(
        name: nicknameController.text.trim(),
        status: statusController.text.trim(),
        favoriteGenres: selectedPlatforms.toList(),
        avatarPath: avatarFile?.path,
      ),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int statusLength = statusController.text.length;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 40),
          child: Column(
            children: [
              const Text(
                'Создание профиля',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 36,
                  height: 1.11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Добро пожаловать. Настройте свой\nидентификатор для входа в Comet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFAAABAB),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: pickAvatar,
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: fieldColor,
                  backgroundImage:
                  avatarFile != null ? FileImage(avatarFile!) : null,
                  child: avatarFile == null
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
                  'ЗАГРУЗИТЬ АВАТАР',
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _LabeledInput(
                label: 'НИКНЕЙМ',
                controller: nicknameController,
                hint: 'Введите ваш никнейм',
                maxLength: 20,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              _LabeledInput(
                label: 'СТАТУС',
                controller: statusController,
                hint: 'Коротко о себе',
                maxLength: 20,
                showCounter: true,
                counterText: '$statusLength/20',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),
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
                      color: Color(0xB3AAABAB),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
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
                    final bool isSelected = selectedPlatforms.contains(platform);

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
              const SizedBox(height: 64),
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
                    onPressed: goToMainScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Начать путешествие',
                          style: TextStyle(
                            color: Color(0xFF00575F),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF00575F),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Назад',
                  style: TextStyle(
                    color: accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _LabeledInput extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
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
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF232626),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: maxLength,
                  onChanged: onChanged,
                  cursorColor: const Color(0xFF75EEFD),
                  style: const TextStyle(
                    color: Color(0xFFF4F3F3),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    counterText: '',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: const Color(0xFFAAABAB).withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (showCounter)
                Text(
                  counterText ?? '',
                  style: TextStyle(
                    color: const Color(0xFFAAABAB).withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
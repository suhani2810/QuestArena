import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../widgets/character_avatar.dart';

// ─── Character Selection Screen ─────────────────────────────────────────────
// Shown during onboarding after username is set.
// Animated reveal of 6 character cards, selection glow + confirm button.

class CharacterSelectScreen extends StatefulWidget {
  final String username;
  final void Function(CharacterData selected) onConfirm;

  const CharacterSelectScreen({
    super.key,
    required this.username,
    required this.onConfirm,
  });

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen>
    with TickerProviderStateMixin {
  CharacterData? _selected;
  late AnimationController _headerAnim;
  late AnimationController _confirmAnim;
  final List<AnimationController> _cardAnims = [];
  final List<Animation<double>> _cardFades = [];
  final List<Animation<Offset>> _cardSlides = [];

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _confirmAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    for (int i = 0; i < kCharacters.length; i++) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));
      _cardAnims.add(ctrl);
      _cardFades.add(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
      _cardSlides.add(Tween<Offset>(
          begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)));
    }

    _startStaggeredEntrance();
  }

  Future<void> _startStaggeredEntrance() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerAnim.forward();
    for (int i = 0; i < _cardAnims.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      _cardAnims[i].forward();
    }
  }

  void _selectCharacter(CharacterData c) {
    HapticFeedback.selectionClick();
    setState(() => _selected = c);
    _confirmAnim.forward();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _confirmAnim.dispose();
    for (final c in _cardAnims) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _buildCharacterGroup(List<CharacterData> characters,
      {required bool isFemale}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 180,
      ),
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];
        // Find global index for animation
        final globalIndex = kCharacters.indexOf(character);

        return FadeTransition(
          opacity: _cardFades[globalIndex],
          child: SlideTransition(
            position: _cardSlides[globalIndex],
            child: _CharacterCard(
              character: character,
              isSelected: _selected?.id == character.id,
              onTap: () => _selectCharacter(character),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header ──────────────────────────────────────────────────────
                FadeTransition(
                  opacity: _headerAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.neonCyan, AppColors.neonViolet],
                          ).createShader(bounds),
                          child: const Text(
                            'CHOOSE YOUR\nCHAMPION',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              height: 1.1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your identity in the arena, ${widget.username}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        // ── Gender section dividers ──────────────────────────────
                        const SizedBox(height: 20),
                        const _SectionLabel(
                            label: 'FEMALE FIGHTERS',
                            color: AppColors.neonViolet),
                      ],
                    ),
                  ),
                ),

                // ── Character grid ───────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Female group
                        _buildCharacterGroup(
                          kCharacters
                              .where(
                                  (c) => c.gender == CharacterGender.female)
                              .toList(),
                          isFemale: true,
                        ),
                        const SizedBox(height: 16),
                        const _SectionLabel(
                            label: 'MALE WARRIORS', color: AppColors.neonCyan),
                        const SizedBox(height: 8),
                        // Male group
                        _buildCharacterGroup(
                          kCharacters
                              .where((c) => c.gender == CharacterGender.male)
                              .toList(),
                          isFemale: false,
                        ),

                        // ── Selected character detail ────────────────────────────
                        if (_selected != null) ...[
                          const SizedBox(height: 20),
                          _SelectedCharacterBanner(character: _selected!),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Confirm button ───────────────────────────────────────────────
                if (_selected != null)
                  AnimatedBuilder(
                    animation: _confirmAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, 60 * (1 - _confirmAnim.value)),
                      child: Opacity(opacity: _confirmAnim.value, child: child),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: _NeonButton(
                        label: 'ENTER THE ARENA',
                        color: AppColors.neonCyan,
                        onTap: () => widget.onConfirm(_selected!),
                      ),
                    ),
                  ),
              ],
            ),
            if (Navigator.canPop(context))
              Positioned(
                top: 16,
                left: 16,
                child: FadeTransition(
                  opacity: _headerAnim,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Character card ──────────────────────────────────────────────────────────

class _CharacterCard extends StatefulWidget {
  final CharacterData character;
  final bool isSelected;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? c.accentColor.withValues(alpha: 0.08)
                : AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? c.accentColor.withValues(alpha: 0.7)
                  : const Color(0xFF1E1E30),
              width: widget.isSelected ? 1.5 : 0.5,
            ),
            boxShadow: widget.isSelected
                ? [
              BoxShadow(
                  color: c.accentColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2),
              BoxShadow(
                  color: c.accentColor.withValues(alpha: 0.08),
                  blurRadius: 32),
            ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CharacterAvatar(
                character: c,
                size: 72,
                showGlow: widget.isSelected,
                showBorder: true,
              ),
              const SizedBox(height: 8),
              Text(
                c.name,
                style: TextStyle(
                  color: widget.isSelected
                      ? c.accentColor
                      : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                c.gender == CharacterGender.female ? 'FIGHTER' : 'WARRIOR',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Selected character banner ───────────────────────────────────────────────

class _SelectedCharacterBanner extends StatelessWidget {
  final CharacterData character;
  const _SelectedCharacterBanner({required this.character});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: character.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: character.accentColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          CharacterAvatar(
              character: character, size: 48, showGlow: true),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                character.name.toUpperCase(),
                style: TextStyle(
                  color: character.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                character.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: character.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: character.accentColor.withValues(alpha: 0.4), width: 0.5),
            ),
            child: Text(
              'SELECTED',
              style: TextStyle(
                color: character.accentColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        )),
      ],
    );
  }
}

class _NeonButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NeonButton({required this.label, required this.color, required this.onTap});

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { _ctrl.forward(); HapticFeedback.mediumImpact(); },
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withValues(alpha: 0.8), width: 1),
            boxShadow: [
              BoxShadow(color: widget.color.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 1),
              BoxShadow(color: widget.color.withValues(alpha: 0.1), blurRadius: 32),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}
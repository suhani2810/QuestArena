import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class LifelineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool isUsed;
  final bool isDisabled;
  final VoidCallback onTap;

  const LifelineButton({
    super.key,
    required this.label,
    required this.icon,
    required this.count,
    required this.isUsed,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool effectivelyDisabled = isDisabled || isUsed || count <= 0;
    
    return GestureDetector(
      onTap: effectivelyDisabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: effectivelyDisabled ? 0.45 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUsed ? AppColors.surface : AppColors.purple,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUsed ? Icons.check_circle_rounded : icon,
                    color: isUsed ? AppColors.textMuted : AppColors.purple,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUsed ? 'USED' : label,
                    style: AppTextStyles.label.copyWith(
                      color: isUsed ? AppColors.textMuted : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (!isUsed) ...[
                const SizedBox(height: 2),
                Text(
                  'Owned: $count',
                  style: TextStyle(
                    color: AppColors.gold.withValues(alpha: 0.8),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
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

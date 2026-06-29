import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/quiz_category.dart';

class CategoryPickerSheet extends StatelessWidget {
  final QuizCategory selectedCategory;

  const CategoryPickerSheet({super.key, required this.selectedCategory});

  static Future<QuizCategory?> show(
    BuildContext context, {
    QuizCategory selectedCategory = QuizCategory.mixed,
  }) {
    return showModalBottomSheet<QuizCategory>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CategoryPickerSheet(selectedCategory: selectedCategory),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 560),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('CHOOSE YOUR TOPIC', style: AppTextStyles.headline),
            const SizedBox(height: 6),
            Text('You will only face players who selected this topic.',
                style: AppTextStyles.label),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: QuizCategory.all.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final category = QuizCategory.all[index];
                  final selected = category.id == selectedCategory.id;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: selected ? AppColors.gold : AppColors.surface,
                      ),
                    ),
                    tileColor: selected
                        ? AppColors.gold.withValues(alpha: 0.10)
                        : AppColors.primaryBg,
                    title: Text(category.name),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.gold)
                        : null,
                    onTap: () => Navigator.pop(context, category),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

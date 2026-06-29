import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/models/quiz_category.dart';
import '../models/practice_models.dart';
import 'practice_game_screen.dart';

class PracticeSetupScreen extends StatefulWidget {
  const PracticeSetupScreen({super.key});

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  QuizCategory _selectedCategory = QuizCategory.all.first;
  PracticeDifficulty _selectedDifficulty = PracticeDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PRACTICE SETUP', style: AppTextStyles.display.copyWith(fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHOOSE TOPIC', style: AppTextStyles.label),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: QuizCategory.all.length,
              itemBuilder: (context, index) {
                final category = QuizCategory.all[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.purple : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.white : AppColors.surface),
                    ),
                    alignment: Alignment.center,
                    child: Text(category.name, 
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        )),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            Text('CHOOSE DIFFICULTY', style: AppTextStyles.label),
            const SizedBox(height: 16),
            Row(
              children: PracticeDifficulty.values.map((d) {
                final isSelected = _selectedDifficulty == d;
                Color dColor = AppColors.teal;
                if (d == PracticeDifficulty.medium) dColor = AppColors.gold;
                if (d == PracticeDifficulty.hard) dColor = AppColors.red;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDifficulty = d),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? dColor : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.white : AppColors.surface),
                      ),
                      alignment: Alignment.center,
                      child: Text(d.label, 
                          style: AppTextStyles.bodyMd.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 60),

            ElevatedButton(
              onPressed: () {
                final session = PracticeSession(
                  category: _selectedCategory,
                  difficulty: _selectedDifficulty,
                  bot: BotProfile.random(),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => PracticeGameScreen(session: session)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('START PRACTICE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

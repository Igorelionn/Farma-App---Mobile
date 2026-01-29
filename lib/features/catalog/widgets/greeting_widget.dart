import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class GreetingWidget extends StatelessWidget {
  final String? userName;
  
  const GreetingWidget({
    super.key,
    this.userName,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour >= 0 && hour < 12) {
      return 'Bom dia';
    } else if (hour >= 12 && hour < 18) {
      return 'Boa tarde';
    } else {
      return 'Boa noite';
    }
  }

  String _getFirstName(String fullName) {
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final displayName = userName != null ? _getFirstName(userName!) : null;
    
    if (displayName == null) {
      return const SizedBox.shrink(); // Não mostra se não estiver logado
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            greeting,
            style: AppTextStyles.h5.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            displayName,
            style: AppTextStyles.h5.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '👋',
            style: TextStyle(fontSize: 22),
          ),
        ],
      ),
    );
  }
}



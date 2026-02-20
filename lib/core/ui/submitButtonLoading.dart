import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SubmitButtonLoading {
  SubmitButtonLoading._();

  /// 🔥 SHOW LOADING
  static Future<void> show(
    BuildContext context, {
    String message = 'Processing...',
    bool barrierDismissible = false,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(.25),
      builder: (_) => _SubmitButtonLoadingDialog(
        message: message,
      ),
    );
  }

  /// 🔥 HIDE LOADING
  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

class _SubmitButtonLoadingDialog extends StatelessWidget {
  const _SubmitButtonLoadingDialog({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 26,
          horizontal: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 🔥 LABADUH LOTTIE
            SizedBox(
              width: 72,
              height: 72,
              child: Lottie.asset(
                'assets/branding/labaduh_loading.json',
                repeat: true,
              ),
            ),

            const SizedBox(height: 18),

            /// MESSAGE
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
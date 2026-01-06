import 'package:flutter/material.dart';
import '../widgets/success_checkmark.dart';

class DoctorRemoveConfirmation extends StatelessWidget {
  const DoctorRemoveConfirmation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SuccessCheckmark(
        message: 'Removed from your registered patient\'s list',
        onClose: () {
          Navigator.pop(context);
        },
        showCloseButton: false,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class Details extends StatelessWidget {
  const Details({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Details',
        variant: AppBarVariant.standard,
      ),
      body: Center(child: Text('Details')),
    );
  }
}

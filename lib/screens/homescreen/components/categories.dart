import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/screens/search/search_screen.dart';

class Category extends StatefulWidget {
  //final cata = const Postedjob();
  const Category({
    super.key,
  });

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  final List<String> fields = [
    "RECENT JOBS",
    "GRAPHICS DESIGN",
    "UI/UX",
    "WEB DEVELOPMENT",
    "PROJECT MANAGMENT",
    "GRAPHICS DESIGN",
    "UI/UX",
  ];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fields.length,
        itemBuilder: (BuildContext context, int index) {
          final category = fields[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Search(initialCategory: category),
                ),
              );
            },
            child: Container(
              height: 2,
              margin: AppDesignSystem.paddingS,
              child: Padding(
                padding: AppDesignSystem.paddingOnly(
                  top: AppDesignSystem.spaceM,
                  left: AppDesignSystem.spaceL,
                  right: 5,
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

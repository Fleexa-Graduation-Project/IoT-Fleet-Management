import 'package:flutter/material.dart';

class OnBoardingModel {
  final String image;
  final String title;
  final String description;
  final PageController controller;
  OnBoardingModel({
    required this.image,
    required this.title,
    required this.description,
    required this.controller,
  });
}

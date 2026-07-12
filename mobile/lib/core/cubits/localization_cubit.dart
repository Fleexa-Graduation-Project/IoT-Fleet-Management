import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class LocalizationCubit extends HydratedCubit<Locale> {
  // Default to English if no saved state is found
  LocalizationCubit() : super(const Locale('en'));

  // Method to change language
  void changeLanguage(String languageCode) {
    emit(Locale(languageCode));
  }

  // Save the state (Take the Locale -> Convert to JSON Map)
  @override
  Map<String, dynamic>? toJson(Locale state) {
    return {'language_code': state.languageCode};
  }

  // Load the state (Take JSON Map -> Convert to Locale)
  @override
  Locale? fromJson(Map<String, dynamic> json) {
    return Locale(json['language_code']);
  }
}

import 'package:flutter/material.dart';

enum ExamDifficulty { easy, medium, hard, veryHard }

class Exam {
  final String id;
  final String title;
  final DateTime date;
  final TimeOfDay time;
  final int duration;
  final String subject;
  final List<String> chapters;
  final ExamDifficulty difficulty;
  bool isCompleted;
  double studyHours;
  double completedStudyHours;

  Exam({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.duration,
    required this.subject,
    required this.chapters,
    required this.difficulty,
    this.isCompleted = false,
    this.studyHours = 0,
    this.completedStudyHours = 0,
  });

  double get progress => studyHours > 0 ? completedStudyHours / studyHours : 0;
}
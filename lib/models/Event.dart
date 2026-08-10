import 'package:flutter/material.dart';

class Event {
  final String title;
  final String meta;
  final String tag;
  final Color tagColor;
  final Color tagTextColor;
  final bool isDone;


  Event({
    required this.title,
    required this.meta,
    required this.tag,
    required this.tagColor,
    required this.tagTextColor,
    this.isDone = false,
  });
}
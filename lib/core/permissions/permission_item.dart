import 'package:flutter/material.dart';

class PermissionItem {
  final String title;
  final String description;
  final IconData icon;
  final Future<bool> Function() check;
  final Future<void> Function() request;

  PermissionItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.check,
    required this.request,
  });
}

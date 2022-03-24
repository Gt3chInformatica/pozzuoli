import 'package:flutter/material.dart';

/// Class that stores list item info:
/// [id] - unique identifier, number.
/// [icon] - icon to display in UI.
/// [title] - text title of the item.
/// [description] - text description of the item.
class ItemModel {
  // class constructor
  ItemModel(this.id, this.icon, this.title, this.description);

  // class fields
  final int id;
  final IconData icon;
  final String title;
  final String description;
}
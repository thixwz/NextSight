import 'package:flutter/material.dart';

class PlayerProvider with ChangeNotifier {
  String? _selectedVideoId; // Should default to null
  // TODO: Add other state variables like title, channel, thumbnail, playback state etc.

  String? get selectedVideoId => _selectedVideoId;
  bool get isVideoSelected => _selectedVideoId != null;

  void selectVideo(String videoId) {
    // TODO: Fetch video details if needed
    _selectedVideoId = videoId;
    print('Selected Video ID: $_selectedVideoId'); 
    notifyListeners(); 
    print('notifyListeners() called in PlayerProvider'); 
  }

  void clearVideo() {
    _selectedVideoId = null;
    print('Cleared Video Selection'); // For debugging
    // TODO: Reset other state variables
    notifyListeners();
    print('notifyListeners() called in PlayerProvider after clear'); // Add print here too
  }

  // TODO: Add methods to control playback (play, pause, seek)
}
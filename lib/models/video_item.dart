class VideoItem {
  final String videoId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? channelTitle;
  final int? durationInSeconds; // Existing field
  final double? score; // <-- ADD THIS LINE

  VideoItem({
    required this.videoId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.channelTitle,
    this.durationInSeconds,
    this.score, // <-- ADD THIS LINE
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      channelTitle: json['channelTitle'] as String?,
      durationInSeconds: json['durationInSeconds'] as int?,
      score: (json['score'] as num?)?.toDouble(), // <-- ADD THIS LINE (handle if score is int or double)
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'channelTitle': channelTitle,
      'durationInSeconds': durationInSeconds,
      'score': score, // <-- ADD THIS LINE
    };
  }
}